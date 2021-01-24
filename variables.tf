variable "resource_group_name" {
  type    = string
  default = "vpn_resource_group"
}

variable "resource_group_location" {
  type = string
}

variable "vpn_network_name" {
  type    = string
  default = "vpn_network"

}

variable "vpn_subnet_name" {
  type    = string
  default = "vpn_subnet"

}

variable "vpn_nic_name" {
  type    = string
  default = "vpn_nic"

}

variable "vpn_public_ip_name" {
  type    = string
  default = "vpn_public_ip"

}

variable "vpn_server_name" {
  type = string
}

variable "vpn_server_size" {
  type = string

}

variable "vpn_server_username" {
  type = string
}


variable "vpn_server_priority" {
  type = string
}
