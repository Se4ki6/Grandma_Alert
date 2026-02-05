"""create_rich_menu.py

LINE Messaging APIを使用してリッチメニューを作成するスクリプト。

機能:
- 安否確認システム用のリッチメニュー構造を定義
- サイズ: 2500px × 1686px（縦3等分のレイアウト）
- 3つのアクションエリア:
  1. 通報する（上部562px）- Postbackアクション
  2. 画像一覧（中部562px）- URIアクション（S3画像ページへ遷移）
  3. 大丈夫/停止する（下部562px）- Postbackアクション

使用方法:
  python create_rich_menu.py
  
出力:
  作成されたリッチメニューIDを返します。
  このIDを.envファイルのRICH_MENU_IDに設定してください。
"""

import requests
import os
from typing import Dict, Any
from dotenv import load_dotenv

# rich_menuをcwdとすることで、同階層の.envを読み込む
load_dotenv()

# リッチメニュー
# 横幅2500px、高さ1686px
# 単純に縦に3等分してメニューを3つに分割
# それぞれ、2500px x 562px
# - 上：　通報する
#   - Postbackにより、LAMBDA関数に通知
# - 中：  画像一覧
#   - URIにより、画像一覧ページへ遷移(s3でホストしているページ)
# - 下：  大丈夫/停止する
#   - Postbackにより、LAMBDA関数に通知

# リッチメニュー画面での設定
# lambda関数のURLをポストバックURLとして設定する必要あり


def create_rich_menu(channel_access_token: str, image_gallery_url: str) -> Dict[str, Any]:
    """
    LINE Messaging APIを使用してリッチメニューを作成します
    
    Args:
        channel_access_token: LINEのチャネルアクセストークン
        lambda_url: 通報や停止の通知を受け取るLAMBDA関数のURL
        image_gallery_url: 画像一覧ページのURL
    Returns:
        APIレスポンスのJSON
    """
    
    url = "https://api.line.me/v2/bot/richmenu"
    
    headers = {
        "Authorization": f"Bearer {channel_access_token}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "size": {
            "width": 2500,
            "height": 1686
        },
        "selected": False,
        "name": "安否確認リッチメニュー",
        "chatBarText": "Tap to open",
        "areas": [
            {
                "bounds": {
                    "x": 0,
                    "y": 0,
                    "width": 2500,
                    "height": 562
                },
                "action": {
                    "type": "postback",
                    "label": "通報する",
                    "data": "action=report&value=report",
                    "displayText": "通報しました"
                }
            },
            {
                "bounds": {
                    "x": 0,
                    "y": 562,
                    "width": 2500,
                    "height": 562
                },
                "action": {
                    "type": "uri",
                    "label": "画像一覧",
                    "uri": image_gallery_url
                }
            },
            {
                "bounds": {
                    "x": 0,
                    "y": 1124,
                    "width": 2500,
                    "height": 562
                },
                "action": {
                    "type": "postback",
                    "label": "大丈夫/停止する",
                    "data": "action=stop&value=stop",
                    "displayText": "大丈夫/停止しました"
                }
            }
        ]
    }
    
    response = requests.post(url, headers=headers, json=payload)
    response.raise_for_status()
    
    return response.json()


if __name__ == "__main__":
    # 環境変数からチャネルアクセストークン・LAMBDA関数URL・画像一覧URLを取得
    channel_access_token = os.getenv("LINE_CHANNEL_ACCESS_TOKEN")
    image_gallery_url = os.getenv("IMAGE_GALLERY_URL")
    
    if not channel_access_token or not image_gallery_url:
        raise ValueError("Required environment variables are not set")
    
    result = create_rich_menu(channel_access_token, image_gallery_url)
    rich_menu_id = result.get("richMenuId")     
    print(f"Rich Menu created with ID: {rich_menu_id}")
