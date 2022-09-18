terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.26.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.0.1"
    }
  }
  required_version = ">= 1.1.0"

  cloud {
    organization = "Tydragon"

    workspaces {
      name = "gh-actions-demo"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

#
# IAM Role for Lambda function
#
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

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



resource "aws_s3_bucket" "s3-bucket-lambda" {
  bucket = "library-manga-bucket"

  tags = {
    Name        = "library-manga-bucket"
    Environment = "Dev"
  }
}

# Lambda Basics Policy (Cloudwatch logs)
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
#Lambda Cloudwatch
resource "aws_cloudwatch_log_group" "library-manga-lambda-cloudwatch" {
  name = "/aws/lambda/library-manga-lambda"
}


resource "aws_lambda_function" "library-manga-lambda" {
  s3_bucket     = "library-manga-bucket"
  s3_key        = "aws-library-manga-lambda-main.zip"
  function_name = "library-manga-lambda"
  handler       = "src/index.handler"
  runtime       = "nodejs12.x"
  timeout       = 180
  role          = aws_iam_role.iam_for_lambda.arn
  depends_on = [
    "aws_s3_bucket.s3-bucket-lambda",
  ]
}

#
# DynamoDB Table to store manga in library-manga
#
resource "aws_dynamodb_table" "library-manga" {
  name         = "library-manga-db"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Name"
  range_key    = "Publisher"

  attribute {
    name = "Name"
    type = "S"
  }
  attribute {
    name = "Publisher"
    type = "S"
  }


}
