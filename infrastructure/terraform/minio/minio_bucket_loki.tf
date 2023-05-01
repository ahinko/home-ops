module "minio_bucket_loki" {
  source      = "./modules/minio_bucket"
  bucket_name = "loki"
  providers = {
    minio = minio.nas
  }
  user_name = "loki"
}

resource "kubernetes_secret" "minio_secret_loki" {
  metadata {
    name      = "loki-secrets"
    namespace = "monitoring"
  }

  data = {
    "S3_ACCESS_KEY"  = module.minio_bucket_loki.user_name
    "S3_SECRET_KEY"  = module.minio_bucket_loki.secret_key
    "S3_BUCKET_HOST" = "minio.selfhosted:9000"
    "S3_BUCKET_NAME" = "loki"
  }
}
