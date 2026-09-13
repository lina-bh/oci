variable "network_security_group_id" {
  type = string
}

variable "tcp_out" {
  type = map(number)
}

variable "udp_out" {
  type = map(number)
}

variable "local_subnet6" {
  type    = string
  default = ""
}

variable "tailscale" {
  type    = bool
  default = true
}

variable "services" {
  type    = string
  default = null
}
