# Azure OpenVPN

A very simple Terraform module to quickly setup and provision an OpenVPN virtual machine on Microsoft Azure.

**Important**: Create an SSH key pair in this directory and name it `vpn_ssh` using `ssh-keygen`

### Usage

```
terraform apply -var-file .tfvars
```