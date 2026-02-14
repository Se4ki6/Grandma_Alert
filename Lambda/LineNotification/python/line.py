"""
LINE Messaging APIを使ってFlex Messageを送信するLambda関数
安否確認システム用の3ボタンメニューをFlex Messageで送信します。
環境変数:
- LINE_CHANNEL_ACCESS_TOKEN: LINEチャネルアクセストークン
- USER_ID: 送信先のユーザーID（グループに送る場合はGROUP_IDを使用）
- GROUP_ID: 送信先のグループID（ユーザーに送る場合はUSER_IDを使用）
- IMAGE_GALLERY_URL: 画像一覧ページのURL
ローカル検証時:
- isLocalをTrueに設定し、.envファイルに環境変数を記載してください。
"""
import json
import urllib.request
import os
import logging

# ロギング設定（CloudWatch Logsに出力）
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# ローカル検証用設定
# Trueにすると、.envファイルから環境変数を読み込みます
isLocal = False
if isLocal:
        # rich_menuをcwdとすることで、同階層の.envを読み込む
        from dotenv import load_dotenv
        load_dotenv()

def lambda_handler(event, context):    
    logger.info("Lambda関数が開始されました")
    
    # 1. 環境変数から設定を読み込む
    url = "https://api.line.me/v2/bot/message/push"
    token = os.environ['LINE_CHANNEL_ACCESS_TOKEN']
    # 送信先のID
    # ユーザーに送る場合
    # id = os.environ['USER_ID'] 
    # グループに送る場合(Gから始まるID)
    id = os.environ['GROUP_ID']
    logger.info(f"送信先ID: {id}")
    
    # 2. 画像一覧URL
    image_gallery_url = os.environ['IMAGE_GALLERY_URL']

    # 3. Flex Messageの構築（リッチメニュー相当の3ボタンメニュー）
    flex_message = {
        "type": "flex",
        "altText": "安否確認メニュー",
        "contents": {
            "type": "bubble",
            "body": {
                "type": "box",
                "layout": "vertical",
                "spacing": "md",
                "contents": [
                    {
                        "type": "text",
                        "text": "安否確認メニュー",
                        "weight": "bold",
                        "size": "lg",
                        "align": "center"
                    }
                ]
            },
            "footer": {
                "type": "box",
                "layout": "vertical",
                "spacing": "sm",
                "contents": [
                    {
                        "type": "button",
                        "style": "primary",
                        "color": "#FF4444",
                        "action": {
                            "type": "postback",
                            "label": "通報する",
                            "data": "action=report&value=report",
                            "displayText": "通報しました"
                        }
                    },
                    {
                        "type": "button",
                        "style": "primary",
                        "color": "#4488FF",
                        "action": {
                            "type": "uri",
                            "label": "画像一覧",
                            "uri": image_gallery_url
                        }
                    },
                    {
                        "type": "button",
                        "style": "primary",
                        "color": "#44AA44",
                        "action": {
                            "type": "postback",
                            "label": "大丈夫/停止する",
                            "data": "action=stop&value=stop",
                            "displayText": "大丈夫/停止しました"
                        }
                    }
                ]
            }
        }
    }

    message = {
        "to": id,
        "messages": [flex_message]
    }
    logger.info("Flex Messageを構築しました")
    
    # 3. リクエストの構築
    req = urllib.request.Request(
        url, 
        data=json.dumps(message).encode("utf-8"),
        method="POST"
    )
    req.add_header("Content-Type", "application/json")
    req.add_header("Authorization", f"Bearer {token}")
    logger.info("リクエストを構築しました")

    # 4. 実行
    try:
        logger.info("LINE APIへリクエストを送信します")
        with urllib.request.urlopen(req) as res:
            _body = res.read().decode("utf-8")
            logger.info(f"レスポンスステータスコード: {res.status}")
            logger.info("メッセージ送信成功")
            return {
                'statusCode': 200,
                'body': json.dumps('Success')
            }
    except Exception as e:
        logger.error(f"エラーが発生しました: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps('Failed')
        }

# ローカル検証用
# 直接メソッドを呼び出す
if isLocal:
    lambda_handler(None, None)