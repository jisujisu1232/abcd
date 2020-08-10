data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"
  source_dir = "${path.module}/templates/lambda"
}

resource "aws_kinesis_stream" "stream" {
  name             = "stream"
  shard_count      = "1"
  retention_period = "24"
}

resource "aws_s3_bucket" "logs" {
  bucket        = "nginx-access-log-store-${var.stage}"
  acl    = "private"
  force_destroy = true
}


resource "aws_cloudwatch_log_group" "logs" {
  name = "/aws/lambda/parsing_lambda"

  retention_in_days = 30
}

resource "aws_lambda_function" "parsing_lambda" {
  filename         = "${path.module}/lambda_function.zip"
  function_name    = "parsing_lambda"
  role             = "${aws_iam_role.lambda_role.arn}"
  handler          = "main.handler"
  #source_code_hash = filebase64sha256("${path.module}/lambda_function.zip")
  runtime          = "python3.7"
  timeout       = 300


  environment {
    variables = {
      TZ                      = "Asia/Seoul"
      LOG_S3_BUCKET           = aws_s3_bucket.logs.id
      LOG_S3_PREFIX           = var.s3_log_prefix
      TEST_S3_ENDPOINT        = var.lambda_localstack_s3_endpoint
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "template_file" "lambda_policy" {
  template = "${file("${path.module}/templates/policies/lambda_policy.json")}"

  vars = {
    aws_s3_bucket_arn = "${aws_s3_bucket.logs.arn}"
    kinesis_stream_arn = aws_kinesis_stream.stream.arn
  }
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "parsing-lambda-policy"
  role   = "${aws_iam_role.lambda_role.id}"
  policy = "${data.template_file.lambda_policy.rendered}"
}

resource "aws_lambda_event_source_mapping" "kinesis_mapping" {
  event_source_arn  = aws_kinesis_stream.stream.arn
  enabled           = true
  function_name     = aws_lambda_function.parsing_lambda.arn
  starting_position = var.starting_position
}
