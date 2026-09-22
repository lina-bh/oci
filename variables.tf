variable "compartment_ocid" {
  type = string
}

variable "subnet" {
  type = string
}

variable "vm_tcp_out" {
  type = set(number)
}

variable "vm_udp_out" {
  type = set(number)
}

variable "node_tcp_out" {
  type = set(number)
}

variable "node_udp_out" {
  type = set(number)
}
