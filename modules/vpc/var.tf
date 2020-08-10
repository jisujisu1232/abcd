variable "cidr_block" {
  description = "vpc cidr_blocks"
  type        = string
}

variable "product_name" {
  description = "product name"
  type        = string
}

variable "stage" {
  description = "Stage"
  type        = string
}

variable "custom_tags" {
  description = "custom tags"
  type        = map
}

variable "region" {
  description = "region"
  type        = string
  default     = "ap-northeast-2"
}

variable "subnet_pub_info" {
  description = "subnet_pub_info"
  type        = list
  default     = []
}

variable "subnet_pri_info" {
  description = "subnet_pub_info"
  type        = list
  default     = []
}

variable "subnet_data_info" {
  description = "subnet_pub_info"
  type        = list
  default     = []
}

variable "nat_azs" {
  description = "nat_azs"
  type        = list
  default     = []
}

variable "data_subnet_route_nat" {
  description = "data subnet routing to nat."
  default     = false
}

variable "log_bucket_name" {
  description = "Flow Log Bucket"
  type        = string
  default     = ""
}

variable "log_expiration_days" {
  description = "log expiration days"
  default     = 90
}
