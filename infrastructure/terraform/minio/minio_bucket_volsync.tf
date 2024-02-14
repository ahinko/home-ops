module "minio_bucket_volsync" {
  source      = "./modules/minio_bucket"
  bucket_name = "volsync"
  providers = {
    minio = minio.nas
  }
  user_name = "volsync"
}

resource "kubernetes_secret" "minio_volsync_creds" {
  metadata {
    name      = "volsync-secrets"
    namespace = "storage"
  }

  data = {
    "MINIO_HOST"       = "http://minio.storage:9000"
    "MINIO_BUCKET"     = module.minio_bucket_volsync.bucket_name
    "MINIO_ACCESS_KEY" = module.minio_bucket_volsync.user_name
    "MINIO_SECRET_KEY" = module.minio_bucket_volsync.secret_key
  }
}
