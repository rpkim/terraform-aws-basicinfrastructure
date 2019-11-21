variable name {
  type        = "string"
  description = "service name"
}

variable cidr_block {
  type        = "string"
  description = "vpc cidr block"
}

variable zones {
  type        = "list"
  description = "zones"
}

variable public_subnets {
  type        = "list"
  description = "public subnets"
}

variable private_subnets {
  type        = "list"
  description = "private subnets"
}

variable db_subnets {
  type        = "list"
  description = "db subnets"
}

variable region {
  type        = "string"
  description = "region"
}
