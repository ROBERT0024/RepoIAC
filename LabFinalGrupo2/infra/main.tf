data "aws_caller_identity" "current" {}

locals {
  bucket_name = "grupo2-sitio-${data.aws_caller_identity.current.account_id}-roberto-final"

  tags = {
    Grupo       = "grupo2"
    Proyecto    = "sitesimple"
    Environment = var.environment
  }
}

resource "aws_s3_bucket" "sitio" {
  bucket = local.bucket_name
  tags   = local.tags
}

resource "aws_s3_bucket_public_access_block" "acceso_publico" {
  bucket = aws_s3_bucket.sitio.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.sitio.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.sitio.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "politica_publica" {
  bucket = aws_s3_bucket.sitio.id

  depends_on = [
    aws_s3_bucket_public_access_block.acceso_publico
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.sitio.arn}/*"
      }
    ]
  })
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.sitio.id
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html"
  source_hash  = filemd5("${path.module}/index.html")

  tags = local.tags
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.sitio.id
  key          = "error.html"
  source       = "${path.module}/error.html"
  content_type = "text/html"
  source_hash  = filemd5("${path.module}/error.html")

  tags = local.tags
}

output "bucket_name" {
  value = aws_s3_bucket.sitio.bucket
}

output "website_url" {
  value = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
}
