import boto3
import json
import os
import datetime
import uuid

def lambda_handler(event, context):

    # Get timestamp 5 mins from now
    current_time = datetime.datetime.now(datetime.timezone.utc)
    future = int(current_time.timestamp() + (2 * 60))

    item = {
        'ActionId': str(uuid.uuid4()),
        'Data': json.dumps({'a': '1', 'b': '2'}),
        'TimeToExist': future
    }
    
    print(item)

    client = boto3.resource('dynamodb')

    # this will search for dynamoDB table 
    # your table name may be different
    table = client.Table("PendingActions")
    print(table.table_status)

    table.put_item(Item=item)
    return