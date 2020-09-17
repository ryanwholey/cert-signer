variable "cidr" {
  type = string
}

variable "azs" {
  type = set(string)
}

variable "prefix" {
  type = string
}