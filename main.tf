variable "custom_tags" {
  default = {
    "TerraformManaged" = "true"
  }
}

module "vpc" {
  source       = "./modules/vpc"
  region       = "ap-northeast-2"
  product_name = "jisu"
  cidr_block   = "172.17.0.0/16"
  stage        = "${terraform.workspace}"
  subnet_pub_info = [
    {
      "cidr" = "172.17.10.0/24",
      "az"   = "a",
      "task" = "common"
    },
    {
      "cidr" = "172.17.11.0/24",
      "az"   = "c",
      "task" = "common"
    },
  ]
  subnet_pri_info = [
    {
      "cidr" = "172.17.20.0/24",
      "az"   = "a",
      "task" = "app"
    },
    {
      "cidr" = "172.17.21.0/24",
      "az"   = "c",
      "task" = "app"
    },
  ]
  subnet_data_info = [
    {
      "cidr" = "172.17.30.0/24",
      "az"   = "a",
      "task" = "data"
    },
    {
      "cidr" = "172.17.31.0/24",
      "az"   = "c",
      "task" = "data"
    },
  ]
  data_subnet_route_nat = true
  nat_azs               = ["a", "c"]
  custom_tags           = "${var.custom_tags}"
}


module "log_set" {
  source       = "./modules/log_set"
  stage        = "${terraform.workspace}"
  nginx_subnet = module.vpc.public_subnet_ids[0]
  vpc_id       = module.vpc.vpc_id
  lambda_localstack_s3_endpoint = "http://localhost:4572"
  nginx_admin_cidrs = ["0.0.0.0/0"]
  nginx_instance_type = "t3.medium"
  nginx_admin_instance_key = "jisu-tttt"

}
