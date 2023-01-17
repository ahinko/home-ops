
output "user_name" {
  value = minio_iam_user.user.name
}

output "secret_key" {
  value     = minio_iam_user.user.secret
  sensitive = true
}
