variable "user_name" {
  description = "Name of the IAM user to create"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket the user should access"
  type        = string
}

variable "object_key" {
  description = "Exact key (path/filename) of the S3 object the user can access"
  type        = string
}

variable "tags" {
  description = "Optional tags to apply to created resources"
  type        = map(string)
  default     = {}
}
