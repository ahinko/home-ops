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
    name      = "thanos-objstore-secret"
    namespace = "monitoring"
  }

  data = {
    "objstore.yml" = yamlencode({
      type = "s3"
      config = {
        access_key = module.minio_bucket_thanos.user_name
        bucket     = module.minio_bucket_thanos.bucket_name
        endpoint   = "minio.storage:9000"
        insecure   = true
        secret_key = module.minio_bucket_thanos.secret_key
      }
    })
  }
}
