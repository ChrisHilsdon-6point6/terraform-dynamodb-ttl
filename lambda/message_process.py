
def lambda_handler(event, context):

    print(event, context)
    return

if __name__ == "__main__":
    lambda_handler({}, {})