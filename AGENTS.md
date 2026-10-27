# AGENTS.md

OpenTofu (not Terraform) configuration for AWS, bunny.net and GitHub. See `README.md` for the folder layout.

- Each top-level folder is a separate root module with its own S3 backend key; run commands inside the folder.
- Run tofu through SOPS so credentials and state encryption are present:
  `sops exec-env "$HOME/.secrets/infra.enc.env" "tofu plan"`. Never print or commit decrypted secrets.
- State is encrypted via the `TF_ENCRYPTION` env var from the SOPS file; do not add `encryption` blocks to the code.
- `tofu validate` and `tofu init -backend=false` work without secrets; `plan`/`apply` need them.
- Only run `plan` unless asked; never `apply` or `destroy` without explicit approval.
- Mark secret outputs `sensitive = true`; never use `nonsensitive()`.
- Provider versions use `~>` constraints; each folder's `.terraform.lock.hcl` is committed and pins the exact versions.
  Upgrade with `tofu init -upgrade -backend=false`, then commit the updated lock files.
