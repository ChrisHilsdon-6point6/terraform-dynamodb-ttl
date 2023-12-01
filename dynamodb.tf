resource "aws_dynamodb_table" "dynamodb_pending_actions" {
  name           = "PendingActions"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "ActionId"
  stream_enabled = true
  stream_view_type = "OLD_IMAGE"

  attribute {
    name = "ActionId"
    type = "S"
  }

  attribute {
    name = "Data"
    type = "S"
  }

  attribute {
    name = "TimeToExist"
    type = "N"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = true
  }

  global_secondary_index {
    name               = "DataIndex"
    hash_key           = "Data"
    range_key          = "TimeToExist"
    projection_type    = "INCLUDE"
    non_key_attributes = ["ActionId"]
  }

  tags = {
    Name = "PendingActions"
  }
}