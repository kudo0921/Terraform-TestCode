variable "region" {}
variable "access_key"{}
variable "secret_key"{}
variable "name" {}
variable "instance_type"{}
variable "vpc_cidr" {}
variable "azs" {}
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "db_name" {}
variable "db_username" {}
variable "engine"{}
variable "engine_version"{}
variable "db_instance"{}

#--------------------------------------------------------------
# プロバイダー情報
#--------------------------------------------------------------
provider "aws"{
    version = "~> 4.0"
    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

#--------------------------------------------------------------
# VPCモジュール呼び出し
#--------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  name      = "${var.name}"
  vpc_cidr  = "${var.vpc_cidr}"
  azs       = "${var.azs}"
  pub_cidrs = "${var.public_subnet_cidrs}"
  pri_cidrs = "${var.private_subnet_cidrs}"
}

#--------------------------------------------------------------
# EC2モジュール呼び出し
#--------------------------------------------------------------
module "ec2" {
  source = "./modules/ec2"

  instance_type             = "${var.instance_type}"
  app_name                  = "${var.name}"
  vpc_id                    = "${module.vpc.vpc_id}"
  pub_subnet_ids            = "${module.vpc.pub_subnet_ids}"
  iam_instance_profile_name = "${module.iam.iam_instance_profile_name}"
}

#--------------------------------------------------------------
# IAMモジュール呼び出し
#--------------------------------------------------------------
module "iam" {
  source = "./modules/iam"

  name = "${var.name}"
}

#--------------------------------------------------------------
# シークレットマネージャモジュール呼び出し
#--------------------------------------------------------------
module "secrets" {
  source = "./modules/secrets"

  name = "${var.name}"
}

#--------------------------------------------------------------
# RDSモジュール呼び出し
#--------------------------------------------------------------
module "rds" {
  source = "./modules/rds"

  app_name       = "${var.name}"
  db_name        = "${var.db_name}"
  db_username    = "${var.db_username}"
  db_password    = "${module.secrets.db_password}"
  vpc_id         = "${module.vpc.vpc_id}"
  pri_subnet_ids = "${module.vpc.pri_subnet_ids}"
  engine         = "${var.engine}"
  engine_version = "${var.engine_version}"
  db_instance    = "${var.db_instance}"
}