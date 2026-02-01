Lmabdaでのシークレットの取得方法
参考URL：https://qiita.com/ma2kazu/items/2a2c69743963f06cdacf

import ast
import boto3
import base64
from botocore.exceptions import ClientError


def lambda_handler(event, context):

    secret_name = "secret" # SecretsManagerで作成したシークレットの名前。必要なら変える
    region_name = "ap-northeast-1"

    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
        
    except ClientError as e:
            raise e
    else:
        if 'SecretString' in get_secret_value_response:
            secret_data = get_secret_value_response['SecretString']
            secret = ast.literal_eval(secret_data)
            id = secret['id']
            address = secret['address']
            name = secret['name']
            # print(f'name:{name},pw:{pw}')
        else:
            decoded_binary_secret = base64.b64decode(get_secret_value_response['SecretBinary'])
            

