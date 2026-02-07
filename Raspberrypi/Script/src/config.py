import os
from dotenv import load_dotenv

# .envをロード
load_dotenv()

class Config:
    # AWS IoT Core設定
    ENDPOINT = os.getenv("IOT_ENDPOINT")
    THING_NAME = os.getenv("THING_NAME")
    CLIENT_ID = THING_NAME
    
    # 証明書パス (ホームディレクトリ展開)
    HOME = os.path.expanduser('~')
    CERT_PATH = f"{HOME}/certs/certificate.pem.crt"
    KEY_PATH = f"{HOME}/certs/private.pem.key"
    ROOT_PATH = f"{HOME}/certs/AmazonRootCA1.pem"

    # S3設定
    BUCKET_NAME = os.getenv("S3_BUCKET")
    REGION = "ap-northeast-1"

    # アプリ設定
    IMAGE_INTERVAL = 5 # 撮影間隔(秒)