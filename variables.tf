variable "vpc_name" {}
variable "vpc_cidr" {}
variable "vpc_public_subnets" {}
variable "vpc_private_subnets" {}
variable "region" {}
variable "azs" {}
variable "vpc_instance_tenancy" {}

variable "connect_to_transit_vpc" {
  default = 1
}

variable "set_dhcp_option" {
  default = 0
}

variable "active_directory_domain_name" {
  default = "contoso.com"
}

variable "active_directory_dc_private_ips" {
  default = "10.0.0.1, 10.0.0.2"
}

variable "connect_to_transit_vpc_test" {
  default = 0
}
variable "enable_dns_support" {
  default = true
}
variable "enable_dns_hostnames" {
  default = true
}
