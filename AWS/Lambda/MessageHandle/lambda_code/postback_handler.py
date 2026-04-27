"""
LINEリッチメニューのPostbackを受け取り、LINE Messaging APIで通知を送信するLambda関数。

環境変数:
- LINE_CHANNEL_ACCESS_TOKEN: LINEチャネルアクセストークン
- LINE_CHANNEL_SECRET: LINEチャネルシークレット（署名検証用）
- GROUP_ID: 送信先のグループID
- SECRET_ID: Secrets ManagerのシークレットID（通報情報: name, address, disease）
- THING_NAME: IoT CoreのThing名
"""

import base64
import hashlib
import hmac
import json
import logging
import os
import urllib.request
import urllib.error
import boto3
from typing import Optional
from urllib.parse import parse_qs

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Secrets Managerから取得した通報情報のキャッシュ（Lambda実行間で再利用）
_emergency_info_cache: Optional[dict] = None


def _verify_signature(body: str, signature: str) -> bool:
    """LINE Webhookの署名を検証する（HMAC-SHA256）。"""
    channel_secret = os.environ["LINE_CHANNEL_SECRET"]
    hash_value = hmac.new(
        channel_secret.encode("utf-8"),
        body.encode("utf-8"),
        hashlib.sha256,
    ).digest()
    expected = base64.b64encode(hash_value).decode("utf-8")
    return hmac.compare_digest(signature, expected)


def _get_emergency_info() -> dict:
    """Secrets Managerから通報情報(name, address, disease)を取得する。結果はキャッシュする。"""
    global _emergency_info_cache
    if _emergency_info_cache is not None:
        return _emergency_info_cache

    secret_id = os.environ["SECRET_ID"]
    client = boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=secret_id)
    _emergency_info_cache = json.loads(response["SecretString"])
    logger.info("Loaded emergency info from Secrets Manager")
    return _emergency_info_cache


def _get_report_message() -> str:
    info = _get_emergency_info()
    name = info.get("name", "未設定")
    address = info.get("address", "未設定")
    disease = info.get("disease", "未設定")

    return (
        "119番する際は、次の内容を伝えてください。\n"
        "===========================\n"
        "救急です\n"
        f"名前は{name}で住所は{address}です。\n"
        f"既往症は{disease}です"
    )


def _send_line_message(text: str):
    token = os.environ["LINE_CHANNEL_ACCESS_TOKEN"]
    group_id = os.environ["GROUP_ID"]

    message = {
        "to": group_id,
        "messages": [
            {
                "type": "text",
                "text": text,
            }
        ],
    }

    req = urllib.request.Request(
        "https://api.line.me/v2/bot/message/push",
        data=json.dumps(message).encode("utf-8"),
        method="POST",
    )
    req.add_header("Content-Type", "application/json")
    req.add_header("Authorization", f"Bearer {token}")

    try:
        with urllib.request.urlopen(req) as res:
            body = res.read().decode("utf-8")
            logger.info("LINE API response status: %s", res.status)
            logger.info("LINE API response body: %s", body)
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8")
        logger.error("LINE API error: status=%s, body=%s", e.code, error_body)
        raise

def _update_device_shadow(status: str):
    """IoT CoreのDevice Shadowを更新する"""
    iot = boto3.client("iot-data")

    payload = {
        "state": {
            "desired": {
                "status": status
            }
        }
    }
    iot.update_thing_shadow(
        thingName=os.environ["THING_NAME"],
        payload=json.dumps(payload)
    )
    logger.info("Shadow updated to: %s", status)

def _extract_action(event: dict) -> Optional[str]:
    body = event.get("body")
    if not body:
        return None

    try:
        payload = json.loads(body)
    except json.JSONDecodeError:
        logger.warning("Invalid JSON body")
        return None

    events = payload.get("events") or []
    if not events:
        return None

    postback = events[0].get("postback") or {}
    data = postback.get("data")
    if not data:
        return None

    parsed = parse_qs(data)
    action_values = parsed.get("action")
    if not action_values:
        return None

    return action_values[0]


def lambda_handler(event, context):
    logger.info("Received event: %s", json.dumps(event))

    # --- LINE署名検証 ---
    headers = {k.lower(): v for k, v in (event.get("headers") or {}).items()}
    signature = headers.get("x-line-signature")
    body = event.get("body", "")

    if not signature or not _verify_signature(body, signature):
        logger.warning("Invalid or missing LINE signature")
        return {"statusCode": 400, "body": json.dumps({"result": "invalid_signature"})}

    action = _extract_action(event)
    if not action:
        logger.info("No postback action found")
        return {"statusCode": 200, "body": json.dumps({"result": "no_action"})}

    try:
        if action == "report":
            message = _get_report_message()
            _send_line_message(message)
            result = "report_sent"
        elif action == "stop":
            _send_line_message("通報を停止しました")
            _update_device_shadow("monitoring")  # Device Shadowを"monitoring"に更新
            result = "stop_sent"
        else:
            logger.info("Unknown action: %s", action)
            result = "unknown_action"

        return {"statusCode": 200, "body": json.dumps({"result": result})}
    except Exception as exc:
        logger.error("Failed to handle postback: %s", str(exc), exc_info=True)
        return {"statusCode": 500, "body": json.dumps({"result": "error"})}
