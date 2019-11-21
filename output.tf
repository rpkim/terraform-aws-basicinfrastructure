output "id" {
  value       = "${aws_vpc.vpc.id}"
  description = "vpc id"
}

output "cidr_block" {
  value       = "${aws_vpc.vpc.cidr_block}"
  description = "vpc cidr block"
}

output "db_route_tables" {
  value       = ["${aws_route_table.db.*.id}"]
  description = "db route table ids"
}

output "db_subnets" {
  value       = ["${aws_subnet.db.*.id}"]
  description = "db subnets id"
}

output "private_route_tables" {
  value       = ["${aws_route_table.private.*.id}"]
  description = "private subnet route table ids"
}

output "private_subnets" {
  value       = ["${aws_subnet.private.*.id}"]
  description = "private subnets id"
}

output "public_route_table" {
  value      = "${aws_route_table.public.id}"
  descrtpion = "public route table id"
}

output "public_subnets" {
  value       = ["${aws_subnet.public.*.id}"]
  description = "public subnets id"
}

output "nat_eips" {
  value       = ["${aws_eip.nat_eips.*.public_ip}"]
  description = "nat eips"
}

output "igw_id" {
  value       = "${aws_internet_gateway.igw.id}"
  description = "internet gateway id"
}
