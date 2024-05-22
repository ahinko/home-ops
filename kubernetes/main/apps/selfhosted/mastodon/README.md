# Mastodon

## Tootctl
Exec into your `mastodon-web-*` container. Run the following before trying to use `tootctl`:

```shell
$ set -o errexit && set -o nounset && set -o pipefail && . /opt/bitnami/scripts/liblog.sh && . /opt/bitnami/scripts/libos.sh && . /opt/bitnami/scripts/libvalidations.sh && . /opt/bitnami/scripts/libmastodon.sh && . /opt/bitnami/scripts/mastodon-env.sh
```

And then

```shell
$ tootctl media refresh --days 10
$ tootctl accounts refresh --all --verbose
```
