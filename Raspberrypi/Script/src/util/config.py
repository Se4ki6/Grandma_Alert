import os
from dataclasses import dataclass
from dotenv import load_dotenv

# .envをロード
load_dotenv()

# ホームディレクトリを先に取得
_HOME = os.path.expanduser('~')


@dataclass(frozen=True)
class Config:
    """アプリケーション設定クラス（シングルトンとして使用）"""
    
    # AWS IoT Core設定
    endpoint: str = os.getenv("IOT_ENDPOINT", "")
    thing_name: str = os.getenv("THING_NAME", "")
    
    # 証明書パス
    cert_path: str = f"{_HOME}/certs/certificate.pem.crt"
    key_path: str = f"{_HOME}/certs/private.pem.key"
    root_path: str = f"{_HOME}/certs/AmazonRootCA1.pem"

    # S3設定
    bucket_name: str = os.getenv("S3_BUCKET", "")
    region: str = "ap-northeast-1"

    # アプリ設定
    image_interval: int = 5  # 撮影間隔(秒)

    @property
    def client_id(self) -> str:
        """CLIENT_IDはTHING_NAMEと同じ"""
        return self.thing_name


# シングルトンインスタンス
config = Config()