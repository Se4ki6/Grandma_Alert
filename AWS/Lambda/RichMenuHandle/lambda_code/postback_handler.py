"""
LINEリッチメニューのPostbackを受け取り、LINE Messaging APIで通知を送信するLambda関数。

環境変数:
- LINE_CHANNEL_ACCESS_TOKEN: LINEチャネルアクセストークン
- GROUP_ID: 送信先のグループID
- REPORT_NAME: 通報テンプレートの氏名
- REPORT_ADDRESS: 通報テンプレートの住所
- REPORT_DISEASE: 通報テンプレートの既往症

※過去の表記ゆれに対応するため、REPORT_DISEASE と REPORT_DISSEASE の両方に対応。
"""

import json
import logging
import os
import urllib.request
from typing import Optional
from urllib.parse import parse_qs

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def _get_report_message():
    name = os.getenv("REPORT_NAME", "未設定")
    address = os.getenv("REPORT_ADDRESS", "未設定")
    disease = os.getenv("REPORT_DISEASE") or os.getenv("REPORT_DISSEASE") or "未設定"

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

    with urllib.request.urlopen(req) as res:
        body = res.read().decode("utf-8")
        logger.info("LINE API response status: %s", res.status)
        logger.info("LINE API response body: %s", body)


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
            result = "stop_sent"
        else:
            logger.info("Unknown action: %s", action)
            result = "unknown_action"

        return {"statusCode": 200, "body": json.dumps({"result": result})}
    except Exception as exc:
        logger.error("Failed to handle postback: %s", str(exc), exc_info=True)
        return {"statusCode": 500, "body": json.dumps({"result": "error"})}
