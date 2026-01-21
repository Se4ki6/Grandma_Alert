import json

def lambda_handler(event, context):
    # LINEから来たデータをそのままCloudWatch Logsに表示する
    print("Received Event: " + json.dumps(event))
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }