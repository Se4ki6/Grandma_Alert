"""upload_image_to_richmenu.py

作成したリッチメニューに画像をアップロードするスクリプト。

機能:
- LINE Messaging APIを使用してリッチメニューに画像を紐付け
- PNG形式の画像をアップロード
- 画像サイズは2500px × 1686pxである必要があります

前提条件:
- リッチメニューが作成済みであること（create_rich_menu.py実行済み）
- アップロードする画像ファイルが存在すること
- .envファイルにRICH_MENU_IDが設定されていること

使用方法:
  python upload_image_to_richmenu.py
  
環境変数:
  - LINE_CHANNEL_ACCESS_TOKEN: LINEチャネルアクセストークン
  - RICH_MENU_ID: 画像をアップロードするリッチメニューのID
  - IMAGE_PATH: アップロードする画像ファイルのパス（デフォルト: ./images/red-562-2500.png）
"""

import requests
import os
from typing import Tuple
from dotenv import load_dotenv

# rich_menuをcwdとすることで、同階層の.envを読み込む
load_dotenv()


def upload_image_to_richmenu(
    channel_access_token: str,
    rich_menu_id: str,
    image_path: str
) -> Tuple[bool, str]:
    """
    LINE Messaging APIを使用してリッチメニューに画像をアップロードします
    
    Args:
        channel_access_token: LINEのチャネルアクセストークン
        rich_menu_id: リッチメニューID
        image_path: アップロードする画像ファイルのパス
        
    Returns:
        (成功フラグ, メッセージ)のタプル
    """
    
    # APIエンドポイント
    url = f"https://api-data.line.me/v2/bot/richmenu/{rich_menu_id}/content"
    
    # ヘッダー設定
    headers = {
        "Authorization": f"Bearer {channel_access_token}",
        "Content-Type": "image/png"
    }
    
    try:
        # 画像ファイルを開く
        with open(image_path, "rb") as image_file:
            # POSTリクエストを送信
            response = requests.post(
                url,
                headers=headers,
                data=image_file
            )
        
        # ステータスコードをチェック
        if response.status_code == 200:
            return True, f"Image uploaded successfully to richmenu {rich_menu_id}"
        else:
            error_message = f"Failed to upload image. Status code: {response.status_code}, Response: {response.text}"
            return False, error_message
            
    except FileNotFoundError:
        return False, f"Image file not found: {image_path}"
    except Exception as e:
        return False, f"Error uploading image: {str(e)}"


if __name__ == "__main__":
    # 環境変数から取得
    channel_access_token = os.getenv("LINE_CHANNEL_ACCESS_TOKEN")
    rich_menu_id = os.getenv("RICH_MENU_ID")
    image_path = os.getenv("IMAGE_PATH", "./images/red-562-2500.png")
    
    if not channel_access_token:
        print("Error: LINE_CHANNEL_ACCESS_TOKEN is not set in environment variables")
        exit(1)
    
    if not rich_menu_id:
        print("Error: RICH_MENU_ID is not set in environment variables")
        exit(1)
    
    success, message = upload_image_to_richmenu(
        channel_access_token,
        rich_menu_id,
        image_path
    )
    
    if success:
        print(f"✓ {message}")
    else:
        print(f"✗ {message}")