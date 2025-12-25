#!/usr/bin/env -S just --justfile

set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

mod k8s "kubernetes"
mod talos "kubernetes/talos"

[private]
default:
    just -l

[private]
log lvl msg *args:
    gum log -t rfc3339 -s -l "{{ lvl }}" "{{ msg }}" {{ args }}

[private]
template file *args:
  minijinja-cli --config-file "{{ justfile_dir() }}/.minijinja.toml" "{{ file }}" {{ args }} | op inject

[doc('Install Homebrew packages from Brewfile')]
brew:
  brew bundle --file "{{ justfile_dir() }}/Brewfile"

[doc('Install kubectl krew plugins')]
krew:
  kubectl krew install cnpg rook-ceph browse-pvc view-secret node-shell
