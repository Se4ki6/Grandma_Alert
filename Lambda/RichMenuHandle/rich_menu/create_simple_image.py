"""

リッチメニュー用の単色画像を背景としたテキスト画像を生成するユーティリティスクリプト。

機能:
- 指定した色とサイズで単色画像を生成
- 画像をimages/フォルダに自動保存
- 色指定方法（複数対応）:
  1. 色名（PIL標準色名）: "red", "blue" など
  2. 16進数カラーコード: "#FF0000" など
  3. RGBタプル: (255, 0, 0) など
- テキストを単色背景に埋め込む機能
- ファイル命名規則: 「色-高さPX-幅PX.png」（例: red-562-2500.png）

前提条件:
- PIL（Pillow）ライブラリがインストール済み

出力例:
  images/HELLO_red-562-2500.png, images/#3366FF-150-250.png など
"""

from PIL import Image, ImageDraw, ImageFont
from pathlib import Path


def create_image_with_text(
    text: str,
    background_color: str,
    height: int,
    width: int,
    text_color: str = "white",
    font_size: int = None,
    output_dir: str = None,
    position: tuple = None,
    filename: str = None
) -> str:
    """
    テキストが埋め込まれた単色画像を生成して保存します。
    
    Args:
        text: 埋め込むテキスト
        background_color: 背景色（色名、16進数コード、またはRGBタプル）
        height: 画像の高さ（ピクセル）
        width: 画像の幅（ピクセル）
        text_color: テキスト色（デフォルト："white"）
        font_size: フォントサイズ（デフォルト：高さの25%）
        output_dir: 出力ディレクトリ（デフォルト：スクリプト同階層のimages/）
        position: テキスト位置（x, y）タプル（デフォルト：中央）
        filename: 保存するファイル名（デフォルト：「テキスト_背景色-高さ-幅.png」）
    
    Returns:
        保存されたファイルのパス
    """
    
    # 出力ディレクトリの設定
    if output_dir is None:
        script_dir = Path(__file__).parent
        output_dir = script_dir / "images"
    else:
        output_dir = Path(output_dir)
    
    # images フォルダが存在しなければ作成
    output_dir.mkdir(exist_ok=True)
    
    # RGB値への変換処理（背景色）
    bg_rgb = _convert_color_to_rgb(background_color)
    
    # RGB値への変換処理（テキスト色）
    text_rgb = _convert_color_to_rgb(text_color)
    
    # 画像の生成
    image = Image.new("RGB", (width, height), bg_rgb)
    draw = ImageDraw.Draw(image)
    
    # フォントサイズの決定
    if font_size is None:
        font_size = max(int(height * 0.25), 20)  # 高さの25%か最小20px
    
    # フォントの取得（日本語対応フォント優先）
    font = None
    font_candidates = [
        "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc",
        "/System/Library/Fonts/ヒラギノ角ゴシック W4.ttc",
        "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc",
        "/System/Library/Fonts/Hiragino Sans W3.ttc",
        "/System/Library/Fonts/Hiragino Sans W6.ttc",
        "/System/Library/Fonts/AppleGothic.ttf",
        "/System/Library/Fonts/STHeiti Medium.ttc",
        "/System/Library/Fonts/Helvetica.ttc",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
    ]

    for font_path in font_candidates:
        try:
            font = ImageFont.truetype(font_path, font_size)
            break
        except (OSError, IOError):
            continue

    if font is None:
        # デフォルトフォント
        font = ImageFont.load_default()
    
    # テキストの幅と高さを取得（中央配置の計算に使用）
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    # 位置の決定
    if position is None:
        # テキストを中央に配置
        x = (width - text_width) // 2
        y = (height - text_height) // 2
    else:
        x, y = position
    
    # テキストの描画
    draw.text((x, y), text, fill=text_rgb, font=font)
    
    # ファイル名の決定
    if filename is None:
        filename = f"{text}_{background_color}-{height}-{width}.png"
    
    output_path = output_dir / filename
    
    # 画像の保存
    image.save(str(output_path))
    
    return str(output_path)


def _convert_color_to_rgb(color):
    """
    色（色名、16進数コード、RGBタプル）をRGBタプルに変換します。
    
    Args:
        color: 色名（"red"）、16進数コード（"#FF0000"）、またはRGBタプル（(255, 0, 0)）
    
    Returns:
        RGBタプル
    """
    if isinstance(color, str):
        if color.startswith("#"):
            # 16進数カラーコードの場合
            hex_color = color.lstrip("#")
            return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))
        else:
            # 色名の場合（PIL の標準色名）
            return color
    else:
        # すでに RGB タプルの場合
        return color


if __name__ == "__main__":    
    # テキスト埋め込み画像の生成例
    result_with_text = create_image_with_text(
        text="Hello",
        background_color="blue",
        height=300,
        width=400,
        text_color="white",
        font_size=60
    )
    print(f"テキスト付き画像が生成されました: {result_with_text}")