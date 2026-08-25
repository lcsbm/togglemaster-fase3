resource "aws_sqs_queue" "events" {
  name                       = "togglemaster-events"
  message_retention_seconds  = 86400  # 1 dia
  visibility_timeout_seconds = 30

  tags = local.common_tags
}

resource "aws_dynamodb_table" "analytics" {
  name         = "analytics-events"
  billing_mode = "PAY_PER_REQUEST"  # on-demand — sem custo fixo

  hash_key = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }

  # TTL para limpeza automática de eventos antigos
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = local.common_tags
}
