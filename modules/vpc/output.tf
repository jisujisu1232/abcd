# VPC
output "vpc_id" {
  description = "VPC ID"
  value       = "${aws_vpc.this.id}"
}

output "vpc_cidr_block" {
  description = "VPC에 할당한 CIDR block"
  value       = "${aws_vpc.this.cidr_block}"
}

output "default_network_acl_id" {
  description = "VPC default network ACL ID"
  value       = "${aws_vpc.this.default_network_acl_id}"
}

# internet gateway
output "igw_id" {
  description = "Interget Gateway ID"
  value       = "${aws_internet_gateway.this.id}"
}

# subnets
output "private_subnet_ids" {
  description = "Private Subnet IDs"
  value       = "${aws_subnet.pri.*.id}"
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = "${aws_subnet.pub.*.id}"
}

output "database_subnet_ids" {
  description = "Database Subnet IDs"
  value       = "${aws_subnet.data.*.id}"
}

output "subnet_pub_info" {
  description = "Public Subnet Infomations"
  value       = "${var.subnet_pub_info}"
}

output "subnet_pri_info" {
  description = "Private Subnet Infomations"
  value       = "${var.subnet_pri_info}"
}

output "subnet_data_info" {
  description = "Database Subnet Infomations"
  value       = "${var.subnet_data_info}"
}


# route tables
output "public_route_table_ids" {
  description = "Public Route Table IDs"
  value       = "${aws_route_table.pub.*.id}"
}

output "private_route_table_ids" {
  description = "Private Route Table IDs"
  value       = "${aws_route_table.pri.*.id}"
}

output "database_route_table_ids" {
  description = "Private Route Table IDs"
  value       = "${aws_route_table.data.*.id}"
}

# NAT gateway
output "nat_eip_ids" {
  description = "NAT Gateway EIP IDs"
  value       = "${aws_eip.nat.*.id}"
}

output "nat_public_ips" {
  description = "NAT Gateway EIPs"
  value       = "${aws_eip.nat.*.public_ip}"
}

output "natgw_ids" {
  description = "NAT Gateway IDs"
  value       = "${aws_nat_gateway.this.*.id}"
}

output "region" {
  description = "region"
  value       = "${var.region}"
}
