import boto3
from src.config import Config

class StorageManager:
    def __init__(self):
        self.s3 = boto3.client('s3', region_name=Config.REGION)
        self.bucket = Config.BUCKET_NAME

    def upload(self, local_path, filename, folder_name):
        """S3へアップロード"""
        s3_key = f"{folder_name}/{filename}"
        try:
            self.s3.upload_file(local_path, self.bucket, s3_key)
            print(f"☁️ Uploaded to S3: {s3_key}")
            return True
        except Exception as e:
            print(f"❌ S3 Error: {e}")
            return False