"""set_default_rich_menu.py

作成したリッチメニューを全ユーザーのデフォルトとして設定するスクリプト。

機能:
- LINE Messaging APIを使用してデフォルトリッチメニューを設定
- すべてのユーザー（既存・新規）に対して自動的にリッチメニューを表示

前提条件:
- リッチメニューが作成済みであること（create_rich_menu.py実行済み）
- .envファイルにRICH_MENU_IDが設定されていること

使用方法:
  python set_default_rich_menu.py
  
環境変数:
  - LINE_CHANNEL_ACCESS_TOKEN: LINEチャネルアクセストークン
  - RICH_MENU_ID: 設定するリッチメニューのID
"""

import requests
import os
from typing import Tuple
from dotenv import load_dotenv

# rich_menuをcwdとすることで、同階層の.envを読み込む
load_dotenv()


def set_default_rich_menu(
    channel_access_token: str,
    rich_menu_id: str
) -> Tuple[bool, str]:
    """
    LINE Messaging APIを使用してすべてのユーザーのデフォルトリッチメニューを設定します
    
    Args:
        channel_access_token: LINEのチャネルアクセストークン
        rich_menu_id: リッチメニューID
        
    Returns:
        (成功フラグ, メッセージ)のタプル
    """
    
    # APIエンドポイント
    url = f"https://api.line.me/v2/bot/user/all/richmenu/{rich_menu_id}"
    
    # ヘッダー設定
    headers = {
        "Authorization": f"Bearer {channel_access_token}"
    }
    
    try:
        # POSTリクエストを送信
        response = requests.post(url, headers=headers)
        
        # ステータスコードをチェック
        if response.status_code == 200:
            return True, f"Default rich menu set successfully to {rich_menu_id}"
        else:
            error_message = f"Failed to set default rich menu. Status code: {response.status_code}, Response: {response.text}"
            return False, error_message
            
    except Exception as e:
        return False, f"Error setting default rich menu: {str(e)}"


if __name__ == "__main__":
    # 環境変数から取得
    channel_access_token = os.getenv("LINE_CHANNEL_ACCESS_TOKEN")
    rich_menu_id = os.getenv("RICH_MENU_ID")
    
    if not channel_access_token:
        print("Error: LINE_CHANNEL_ACCESS_TOKEN is not set in environment variables")
        exit(1)
    
    if not rich_menu_id:
        print("Error: RICH_MENU_ID is not set in environment variables")
        exit(1)
    
    success, message = set_default_rich_menu(
        channel_access_token,
        rich_menu_id
    )
    
    if success:
        print(f"✓ {message}")
    else:
        print(f"✗ {message}")
