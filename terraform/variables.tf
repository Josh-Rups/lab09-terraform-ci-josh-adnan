variable "region" { type = string }
variable "name_prefix" { type = string }
variable "cidr_vpc" { type = string }
variable "cidr_public_subnet" { type = string }
variable "instance_type" {
  type    = string
  default = "t2.micro"
}

