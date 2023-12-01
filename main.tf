locals {
  lambda_message_send = "message_send"
  lambda_message_process = "message_process"
}

data "archive_file" "python_lambda_send" {
  type             = "zip"
  output_file_mode = "0666"
  source_file      = "${path.module}/lambda/${local.lambda_message_send}.py"
  output_path      = "${path.module}/lambda/${local.lambda_message_send}.zip"
}

data "archive_file" "python_lambda_process" {
  type             = "zip"
  output_file_mode = "0666"
  source_file      = "${path.module}/lambda/${local.lambda_message_process}.py"
  output_path      = "${path.module}/lambda/${local.lambda_message_process}.zip"
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "dynamodb_policy" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "dynamodb_policy" {
  name        = "lambda_dynamodb"
  description = "Give access to lambda to access dynamodb"
  policy      = data.aws_iam_policy_document.dynamodb_policy.json
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "dynamodb_attach" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_role_basic" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_role_sqs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_role_dynamodb" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole"
}

resource "aws_cloudwatch_log_group" "lambda_sqs_log" {
  name = "/aws/lambda/${aws_lambda_function.lambda_send.function_name}"
}

resource "aws_lambda_function" "lambda_send" {
  function_name    = local.lambda_message_send
  filename         = "${path.module}/lambda/${local.lambda_message_send}.zip"
  source_code_hash = data.archive_file.python_lambda_send.output_base64sha256
  role             = aws_iam_role.iam_for_lambda.arn
  runtime          = "python3.11"
  handler          = "${local.lambda_message_send}.lambda_handler"
  timeout          = 10
}

resource "aws_lambda_function" "lambda_process" {
  function_name    = local.lambda_message_process
  filename         = "${path.module}/lambda/${local.lambda_message_process}.zip"
  source_code_hash = data.archive_file.python_lambda_process.output_base64sha256
  role             = aws_iam_role.iam_for_lambda.arn
  runtime          = "python3.11"
  handler          = "${local.lambda_message_process}.lambda_handler"
  timeout          = 10
}

resource "aws_lambda_event_source_mapping" "lambda_dynamodb" {
  event_source_arn  = aws_dynamodb_table.dynamodb_pending_actions.stream_arn
  function_name     = aws_lambda_function.lambda_process.arn
  starting_position = "LATEST"
}