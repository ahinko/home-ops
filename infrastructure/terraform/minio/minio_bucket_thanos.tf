module "minio_bucket_thanos" {
  source      = "./modules/minio_bucket"
  bucket_name = "thanos"
  providers = {
    minio = minio.nas
  }
  user_name = "thanos"
}

resource "kubernetes_secret" "minio_secret_thanos" {
  metadata {
    name      = "thanos"
    namespace = "monitoring"
  }

  data = {
    "S3_ACCESS_KEY"    = module.minio_bucket_thanos.user_name
    "S3_SECRET_KEY"    = module.minio_bucket_thanos.secret_key
    "S3_BUCKET_HOST"   = "minio.selfhosted:9000"
    "S3_BUCKET_NAME"   = "thanos"
    "S3_BUCKET_REGION" = ""
  }
}
