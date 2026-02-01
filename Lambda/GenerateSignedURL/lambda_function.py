import json
import boto3
import os
from datetime import datetime, timedelta
from botocore.signers import CloudFrontSigner
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization, hashes
from cryptography.hazmat.primitives.asymmetric import padding
import base64

# 環境変数から設定を取得
CLOUDFRONT_DOMAIN = os.environ.get('CLOUDFRONT_DOMAIN')
CLOUDFRONT_KEY_PAIR_ID = os.environ.get('CLOUDFRONT_KEY_PAIR_ID')
PRIVATE_KEY_SSM_PARAM = os.environ.get('PRIVATE_KEY_SSM_PARAM', '/cloudfront/private-key')
URL_EXPIRATION_MINUTES = int(os.environ.get('URL_EXPIRATION_MINUTES', '60'))

ssm = boto3.client('ssm')


def rsa_signer(message):
    """CloudFront用のRSA署名関数"""
    # SSMパラメータストアから秘密鍵を取得（初回のみ）
    if not hasattr(rsa_signer, 'private_key'):
        response = ssm.get_parameter(Name=PRIVATE_KEY_SSM_PARAM, WithDecryption=True)
        private_key_pem = response['Parameter']['Value']
        
        rsa_signer.private_key = serialization.load_pem_private_key(
            private_key_pem.encode('utf-8'),
            password=None,
            backend=default_backend()
        )
    
    # メッセージに署名
    signature = rsa_signer.private_key.sign(
        message,
        padding.PKCS1v15(),
        hashes.SHA1()
    )
    return signature


def lambda_handler(event, context):
    """
    署名付きCloudFront URLを生成するLambda関数
    
    Parameters:
    - event['path']: CloudFrontで配信するリソースのパス（例: "/index.html", "/*"）
    - event['expiration_minutes']: URL有効期限（分）。指定がなければ環境変数のデフォルト値
    
    Returns:
    - 署名付きURL（単一ファイルまたはワイルドカード）
    """
    
    try:
        # リクエストボディから取得
        if 'body' in event:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            body = event
        
        # リソースパスを取得（デフォルト: ダッシュボードのindex.html）
        resource_path = body.get('path', '/index.html')
        expiration_minutes = body.get('expiration_minutes', URL_EXPIRATION_MINUTES)
        
        # CloudFront URLを構築
        url = f"https://{CLOUDFRONT_DOMAIN}{resource_path}"
        
        # 有効期限を設定
        expire_date = datetime.utcnow() + timedelta(minutes=expiration_minutes)
        
        # CloudFrontSignerを使用して署名付きURLを生成
        cloudfront_signer = CloudFrontSigner(CLOUDFRONT_KEY_PAIR_ID, rsa_signer)
        
        # ワイルドカード（/*）の場合はカスタムポリシーを使用
        if '*' in resource_path:
            signed_url = cloudfront_signer.generate_presigned_url(
                url,
                date_less_than=expire_date
            )
        else:
            signed_url = cloudfront_signer.generate_presigned_url(
                url,
                date_less_than=expire_date
            )
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'signed_url': signed_url,
                'expires_at': expire_date.isoformat(),
                'expires_in_minutes': expiration_minutes
            })
        }
    
    except Exception as e:
        print(f"Error generating signed URL: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Failed to generate signed URL',
                'message': str(e)
            })
        }
