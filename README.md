# tf-bucket-starter

OpenTofu configuration for my personal infrastructure on AWS, bunny.net and GitHub.

| Folder | What it manages |
|---|---|
| `master-state-buckets/` | The S3 bucket (versioned) that holds the state of every folder, including its own |
| `cloud-infrastructure/` | bunny.net DNS zones (`bogolyandras.com`, `cestlavie.ovh`) and the storage zones for bogolyandras.com; an S3 bucket for certificates and an IAM user with an access key for it; the GitHub repository of this code |
| `modules/` | Shared modules (`s3_bucket`, `s3_object_single_file_user_access`) |

## Running

Secrets live outside the repo in a SOPS file encrypted with age (`~/.secrets/infra.enc.env`), and every command runs through it:

```powershell
sops exec-env "$HOME\.secrets\infra.enc.env" "tofu plan"
```

The file provides `BUNNYNET_API_KEY`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `GITHUB_TOKEN` and `TF_ENCRYPTION`.

## State

State is stored in S3 and encrypted client-side with OpenTofu state encryption (PBKDF2 + AES-GCM).
The encryption config is not in the code: it comes from `TF_ENCRYPTION` in the SOPS file.
Without it, tofu fails with "state file is encrypted". Losing the passphrase makes the state unreadable.
