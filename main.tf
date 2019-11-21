# TODO too much? consider moving peering into its own module

variable name {
  type = "string"
}

variable cidr_block {
  type = "string"
}

variable zones {
  type = "list"
}

variable public_subnets {
  type = "list"
}

variable private_subnets {
  type = "list"
}

variable db_subnets {
  type = "list"
}

variable region {
  type = "string"
}

resource "aws_vpc" "vpc" {
  cidr_block           = "${var.cidr_block}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = "${var.name}"
    terraform = "true"
  }
}

resource "aws_subnet" "public" {
  count                   = "${length(var.public_subnets)}"
  map_public_ip_on_launch = true
  vpc_id                  = "${aws_vpc.vpc.id}"
  availability_zone       = "${element(var.zones, count.index)}"
  cidr_block              = "${element(var.public_subnets, count.index)}"

  tags = {
    Name               = "${format("pub-%s-%s-%d", var.name, element(var.zones, count.index), count.index / length(var.zones))}"
    immutable_metadata = "{ \"purpose\": \"public-${var.name}\" }"
    terraform          = "true"
  }
}

resource "aws_subnet" "private" {
  count                   = "${length(var.private_subnets)}"
  map_public_ip_on_launch = false
  vpc_id                  = "${aws_vpc.vpc.id}"
  availability_zone       = "${element(var.zones, count.index)}"
  cidr_block              = "${element(var.private_subnets, count.index)}"

  tags = {
    Name               = "${format("priv-%s-%s-%d", var.name, element(var.zones, count.index), count.index / length(var.zones))}"
    immutable_metadata = "{ \"purpose\": \"private-${var.name}\" }"
    terraform          = "true"
  }
}

resource "aws_subnet" "db" {
  count                   = "${length(var.db_subnets)}"
  map_public_ip_on_launch = false
  vpc_id                  = "${aws_vpc.vpc.id}"
  availability_zone       = "${element(var.zones, count.index)}"
  cidr_block              = "${element(var.db_subnets, count.index)}"

  tags = {
    Name      = "${format("db-%s-%s-%d", var.name, element(var.zones, count.index), count.index / length(var.zones))}"
    terraform = "true"
  }
}

# Create gateways
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name      = "igw-${var.name}"
    terraform = "true"
  }
}

resource "aws_eip" "nat_eips" {
  count = "${length(var.zones)}"
  vpc   = "true"
}

resource "aws_nat_gateway" "nats" {
  count         = "${length(var.zones)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
  allocation_id = "${element(aws_eip.nat_eips.*.id, count.index)}"
  depends_on    = ["aws_internet_gateway.igw"]
}

# Create route tables
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name      = "rt-${var.name}-public"
    terraform = "true"
  }
}

resource "aws_route_table" "private" {
  count  = "${length(var.zones)}"
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name      = "${format("rt-%s-private-%s-%d", var.name, element(var.zones, count.index), count.index / length(var.zones))}"
    terraform = "true"
  }
}

resource "aws_route_table" "db" {
  count  = "${length(var.zones)}"
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name      = "${format("rt-%s-db-%s-%d", var.name, element(var.zones, count.index), count.index / length(var.zones))}"
    terraform = "true"
  }
}

# Associate gateways to route tables as default routes
resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
  route_table_id         = "${aws_route_table.public.id}"
}

resource "aws_route" "private" {
  count                  = "${length(var.zones)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.nats.*.id, count.index)}"
  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_route" "db" {
  count                  = "${length(var.zones)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.nats.*.id, count.index)}"
  route_table_id         = "${element(aws_route_table.db.*.id, count.index)}"
}

# Associate subnets to route tables
resource "aws_route_table_association" "public" {
  count          = "${length(var.public_subnets)}"
  route_table_id = "${aws_route_table.public.id}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
}

resource "aws_route_table_association" "private" {
  count          = "${length(var.private_subnets)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
}

resource "aws_route_table_association" "db" {
  count          = "${length(var.db_subnets)}"
  route_table_id = "${element(aws_route_table.db.*.id, count.index)}"
  subnet_id      = "${element(aws_subnet.db.*.id, count.index)}"
}

# Outputs needed by other resources
output "id" {
  value = "${aws_vpc.vpc.id}"
}

output "cidr_block" {
  value = "${aws_vpc.vpc.cidr_block}"
}

output "db_route_tables" {
  value = ["${aws_route_table.db.*.id}"]
}

output "db_subnets" {
  value = ["${aws_subnet.db.*.id}"]
}

output "private_route_tables" {
  value = ["${aws_route_table.private.*.id}"]
}

output "private_subnets" {
  value = ["${aws_subnet.private.*.id}"]
}

output "public_route_table" {
  value = "${aws_route_table.public.id}"
}

output "public_subnets" {
  value = ["${aws_subnet.public.*.id}"]
}

output "nat_eips" {
  value = ["${aws_eip.nat_eips.*.public_ip}"]
}

output "igw_id" {
  value = "${aws_internet_gateway.igw.id}"
}

