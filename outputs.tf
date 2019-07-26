output "private_subnet_ids" {
  value = "${join(",", aws_subnet.private.*.id)}"
}

output "public_subnet_ids" {
  value = "${join(",", aws_subnet.public.*.id)}"
}

output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "vpc_cidr" {
  value = "${aws_vpc.vpc.cidr_block}"
}

output "default_network_acl_id" {
  value = "${aws_vpc.vpc.default_network_acl_id}"
}

output "public_route_table_ids" {
  value = "${join(",", aws_route_table.public.*.id)}"
}

output "private_route_table_ids" {
  value = "${join(",", aws_route_table.private.*.id)}"
}

output "private_route_table_count" {
  value = "${length(aws_route_table.private.*.id)}"
}