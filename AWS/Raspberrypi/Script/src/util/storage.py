import os
import boto3
from util.config import config

class StorageManager:
    def __init__(self):
        self.s3 = boto3.client('s3', region_name=config.region)
        self.bucket = config.bucket_name

    def upload(self, local_path, filename, folder_name):
        s3_key = f"{folder_name}/{filename}"
        try:
            self.s3.upload_file(local_path, self.bucket, s3_key)
            print(f"☁️ Uploaded: {s3_key}")
            return True
        except Exception as e:
            print(f"❌ S3 Error: {e}")
            return False
        finally:
            if os.path.exists(local_path):
                os.remove(local_path)