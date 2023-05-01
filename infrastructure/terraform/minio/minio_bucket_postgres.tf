module "minio_bucket_postgres" {
  source      = "./modules/minio_bucket"
  bucket_name = "postgres"
  providers = {
    minio = minio.nas
  }
  user_name = "postgres"
}

resource "kubernetes_secret" "minio_secret_postgres" {
  metadata {
    name      = "cnpg-backup-secrets"
    namespace = "databases"
  }

  data = {
    "S3_ACCESS_KEY" = module.minio_bucket_postgres.user_name
    "S3_SECRET_KEY" = module.minio_bucket_postgres.secret_key
  }
}
