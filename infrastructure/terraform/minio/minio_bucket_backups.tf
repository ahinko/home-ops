module "minio_bucket_backups" {
  source      = "./modules/minio_bucket"
  bucket_name = "backups"
  providers = {
    minio = minio.nas
  }
  user_name = "backups"
}

resource "kubernetes_secret" "minio_secret_backups_databases" {
  metadata {
    name      = "backups-secrets"
    namespace = "databases"
  }

  data = {
    "MINIO_HOST"       = "http://minio.storage:9000"
    "MINIO_BUCKET"     = module.minio_bucket_backups.bucket_name
    "MINIO_ACCESS_KEY" = module.minio_bucket_backups.user_name
    "MINIO_SECRET_KEY" = module.minio_bucket_backups.secret_key
  }
}

resource "kubernetes_secret" "minio_secret_backups_games" {
  metadata {
    name      = "backups-secrets"
    namespace = "games"
  }

  data = {
    "MINIO_HOST"       = "http://minio.storage:9000"
    "MINIO_BUCKET"     = module.minio_bucket_backups.bucket_name
    "MINIO_ACCESS_KEY" = module.minio_bucket_backups.user_name
    "MINIO_SECRET_KEY" = module.minio_bucket_backups.secret_key
  }
}

resource "kubernetes_secret" "minio_secret_backups_home-automation" {
  metadata {
    name      = "backups-secrets"
    namespace = "home-automation"
  }

  data = {
    "MINIO_HOST"       = "http://minio.storage:9000"
    "MINIO_BUCKET"     = module.minio_bucket_backups.bucket_name
    "MINIO_ACCESS_KEY" = module.minio_bucket_backups.user_name
    "MINIO_SECRET_KEY" = module.minio_bucket_backups.secret_key
  }
}

resource "kubernetes_secret" "minio_secret_backups_downloads" {
  metadata {
    name      = "backups-secrets"
    namespace = "downloads"
  }

  data = {
    "MINIO_HOST"       = "http://minio.storage:9000"
    "MINIO_BUCKET"     = module.minio_bucket_backups.bucket_name
    "MINIO_ACCESS_KEY" = module.minio_bucket_backups.user_name
    "MINIO_SECRET_KEY" = module.minio_bucket_backups.secret_key
  }
}

resource "kubernetes_secret" "minio_secret_backups_media" {
  metadata {
    name      = "backups-secrets"
    namespace = "media"
  }

  data = {
    "MINIO_HOST"       = "http://minio.storage:9000"
    "MINIO_BUCKET"     = module.minio_bucket_backups.bucket_name
    "MINIO_ACCESS_KEY" = module.minio_bucket_backups.user_name
    "MINIO_SECRET_KEY" = module.minio_bucket_backups.secret_key
  }
}

resource "kubernetes_secret" "minio_secret_backups_selfhosted" {
  metadata {
    name      = "backups-secrets"
    namespace = "selfhosted"
  }

  data = {
    "MINIO_HOST"       = "http://minio.storage:9000"
    "MINIO_BUCKET"     = module.minio_bucket_backups.bucket_name
    "MINIO_ACCESS_KEY" = module.minio_bucket_backups.user_name
    "MINIO_SECRET_KEY" = module.minio_bucket_backups.secret_key
  }
}

resource "kubernetes_secret" "minio_secret_backups_monitoring" {
  metadata {
    name      = "backups-secrets"
    namespace = "monitoring"
  }

  data = {
    "MINIO_HOST"       = "http://minio.storage:9000"
    "MINIO_BUCKET"     = module.minio_bucket_backups.bucket_name
    "MINIO_ACCESS_KEY" = module.minio_bucket_backups.user_name
    "MINIO_SECRET_KEY" = module.minio_bucket_backups.secret_key
  }
}
