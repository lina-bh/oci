variable "ssh_public_key" {
  type = string
}

variable "compartment_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "availability_domain" {
  type = string
}

variable "nsg_id" {
  type = string
}

variable "subnet_router" {
  type = list(string)
}

variable "ipv4" {
  type = string
}
