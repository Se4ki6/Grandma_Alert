"""main.py

安否確認システムのLINEリッチメニューをセットアップするメインスクリプト。

以下の4つの処理を順序通り実行します：
1. 縦に3等分した画像を生成（各メニュー用）
2. LINE Messaging APIでリッチメニューを作成
3. リッチメニューに画像をアップロード
4. 作成したリッチメニューをデフォルトとして設定

前提条件:
- .envファイルが設定されていること
- 環境変数: LINE_CHANNEL_ACCESS_TOKEN, IMAGE_GALLERY_URL
"""

import os
import sys
from PIL import Image
from dotenv import load_dotenv
from create_simple_image import create_image_with_text
from create_rich_menu import create_rich_menu
from upload_image_to_richmenu import upload_image_to_richmenu
from set_default_rich_menu import set_default_rich_menu

# 環境変数を読み込む
load_dotenv()


def main():
    """リッチメニューのセットアップを実行"""
    
    # 環境変数の確認
    channel_access_token = os.getenv("LINE_CHANNEL_ACCESS_TOKEN")
    image_gallery_url = os.getenv("IMAGE_GALLERY_URL")
    
    if not channel_access_token:
        print("❌ Error: LINE_CHANNEL_ACCESS_TOKEN is not set in environment variables")
        sys.exit(1)
    
    if not image_gallery_url:
        print("❌ Error: IMAGE_GALLERY_URL is not set in environment variables")
        sys.exit(1)
    
    print("🚀 Starting LINE Rich Menu Setup...")
    
    # ステップ1: 画像を生成（縦に3等分）
    print("\n📸 Step 1: Creating menu images...")
    try:
        # リッチメニューサイズ: 2500px × 1686px を3等分（各562px）
        width = 2500
        height = 562
        
        # 通報するメニュー画像
        report_path = create_image_with_text(
            text="通報する",
            background_color="white",
            height=height,
            width=width,
            text_color="black",
            filename="report.png"
        )
        print(f"✓ Report image created: {report_path}")
        
        # 画像一覧メニュー画像
        gallery_path = create_image_with_text(
            text="画像一覧",
            background_color="white",
            height=height,
            width=width,
            text_color="black",
            filename="image_gallery.png"
        )
        print(f"✓ Gallery image created: {gallery_path}")
        
        # 大丈夫/停止するメニュー画像
        stop_path = create_image_with_text(
            text="大丈夫/停止する",
            background_color="white",
            height=height,
            width=width,
            text_color="black",
            filename="stop.png"
        )
        print(f"✓ Stop image created: {stop_path}")
        
    except Exception as e:
        print(f"❌ Error creating images: {str(e)}")
        sys.exit(1)
    
    # ステップ2: リッチメニューを作成
    print("\n🎨 Step 2: Creating rich menu...")
    try:
        response = create_rich_menu(channel_access_token, image_gallery_url)
        
        if "richMenuId" in response:
            rich_menu_id = response["richMenuId"]
            print(f"✓ Rich menu created: {rich_menu_id}")
            
            # 環境変数として保存（後続のスクリプトで使用）
            os.environ["RICH_MENU_ID"] = rich_menu_id
        else:
            print(f"❌ Failed to create rich menu: {response}")
            sys.exit(1)
            
    except Exception as e:
        print(f"❌ Error creating rich menu: {str(e)}")
        sys.exit(1)
    
    # ステップ3: リッチメニューに画像をアップロード
    print("\n📤 Step 3: Uploading image to rich menu...")
    try:
        # 3つの画像を1つの背景画像として結合してアップロード
        images_dir = os.path.dirname(report_path)
        combined_path = os.path.join(images_dir, "rich_menu.png")

        combined_image = Image.new("RGB", (width, height * 3), "white")
        combined_image.paste(Image.open(report_path), (0, 0))
        combined_image.paste(Image.open(gallery_path), (0, height))
        combined_image.paste(Image.open(stop_path), (0, height * 2))
        combined_image.save(combined_path)

        # アップロードする画像パス（環境変数から取得、なければ結合画像）
        image_path = os.getenv("IMAGE_PATH", combined_path)
        
        success, message = upload_image_to_richmenu(
            channel_access_token,
            rich_menu_id,
            image_path
        )
        
        if success:
            print(f"✓ {message}")
        else:
            print(f"❌ {message}")
            # 注: 画像アップロード失敗でもメニューは作成されているため、警告のみ
            
    except Exception as e:
        print(f"❌ Error uploading image: {str(e)}")
    
    # ステップ4: デフォルトリッチメニューに設定
    print("\n⚙️  Step 4: Setting as default rich menu...")
    try:
        success, message = set_default_rich_menu(
            channel_access_token,
            rich_menu_id
        )
        
        if success:
            print(f"✓ {message}")
        else:
            print(f"❌ {message}")
            sys.exit(1)
            
    except Exception as e:
        print(f"❌ Error setting default rich menu: {str(e)}")
        sys.exit(1)
    
    print("\n✅ All steps completed successfully!")
    print(f"📋 Rich Menu ID: {rich_menu_id}")


if __name__ == "__main__":
    main()