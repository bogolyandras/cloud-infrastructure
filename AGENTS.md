# AGENTS.md

OpenTofu (not Terraform) configuration for AWS, bunny.net and GitHub. See `README.md` for the folder layout.

- Each top-level folder is a separate root module with its own S3 backend key; run commands inside the folder.
- Run tofu through SOPS so credentials and state encryption are present:
  `sops exec-env "$HOME/.secrets/infra.enc.env" "tofu plan"`. Never print or commit decrypted secrets.
- State is encrypted via the `TF_ENCRYPTION` env var from the SOPS file; do not add `encryption` blocks to the code.
- `tofu validate` and `tofu init -backend=false` work without secrets; `plan`/`apply`/`output`/`state` need them.
- The AWS CLI is not installed; inspect deployed resources through `tofu state show` or `tofu output`.
- Only run `plan` unless asked; never `apply` or `destroy` without explicit approval.
- Mark secret outputs `sensitive = true`; never use `nonsensitive()`.
- Provider versions use `~>` constraints; each folder's `.terraform.lock.hcl` is committed and pins the exact versions.
  Upgrade with `tofu init -upgrade -backend=false`, then commit the updated lock files.
- Files use LF line endings (`core.autocrlf` is off); don't let edits convert them to CRLF.

## Lambda

- Source lives in `<folder>/lambda/<function>/` and is zipped by `archive_file` into `.build/` (gitignored).
- Node functions have no `package.json` or dependencies: use Node built-ins and the AWS SDK v3 bundled in the runtime.
  Pin only the major runtime (e.g. `nodejs24.x`); AWS applies patch updates automatically.
- Don't set `reserved_concurrent_executions`: the account's concurrency limit is 10, so any reservation is rejected.
- Test endpoints from PowerShell 7 with plain single-quoted JSON (`-d '{"a":1}'`); `\"` escaping is passed literally.
