resource "aws_vpc" "vpc" {
  cidr_block       = "${var.vpc_cidr}"
  instance_tenancy = "${var.vpc_instance_tenancy}"
  enable_dns_support = "${var.enable_dns_support}"
  enable_dns_hostnames = "${var.enable_dns_hostnames}"

  tags {
    Name       = "${var.vpc_name}"
    created_by = "terraform"
    protected  = true
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_vpn_gateway" "vgw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name                        = "${var.vpc_name}-vgw"
    created_by                  = "terraform"
    protected                   = true
    "transitvpc:preferred-path" = "none"
    "transitvpc:spoke"          = "${var.connect_to_transit_vpc == 1 ? true : false}"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_subnet" "public" {
  count             = "${length(compact(split(",", var.vpc_public_subnets)))}"
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${element(split(",", var.vpc_public_subnets), count.index)}"
  availability_zone = "${var.region}${element(split(",", var.azs), count.index)}"

  tags {
    Name       = "${var.vpc_name}-${element(split(",", var.azs), count.index)}-public"
    created_by = "terraform"
    protected  = true
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_subnet" "private" {
  count             = "${length(compact(split(",", var.vpc_private_subnets)))}"
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${element(split(",", var.vpc_private_subnets), count.index)}"
  availability_zone = "${var.region}${element(split(",", var.azs), count.index)}"

  tags {
    Name       = "${var.vpc_name}-${element(split(",", var.azs), count.index)}-private"
    created_by = "terraform"
    protected  = true
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name       = "${var.vpc_name}-igw"
    created_by = "terraform"
    protected  = true
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_eip" "nat" {
  vpc = true

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_nat_gateway" "nat" {
  subnet_id     = "${aws_subnet.public.0.id}"
  allocation_id = "${aws_eip.nat.id}"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name       = "${var.vpc_name}-public"
    created_by = "terraform"
    protected  = true
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name       = "${var.vpc_name}-private"
    created_by = "terraform"
    protected  = true
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_route_table_association" "public" {
  count          = "${length(compact(split(",", var.vpc_public_subnets)))}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "private" {
  count          = "${length(compact(split(",", var.vpc_private_subnets)))}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route" "public_route" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
}

resource "aws_route" "nat_private_route" {
  route_table_id         = "${aws_route_table.private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.nat.id}"
}

resource "aws_route" "vpg_public_route" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "172.0.0.0/8"
  gateway_id             = "${aws_vpn_gateway.vgw.id}"
}

resource "aws_route" "vpg_private_route" {
  route_table_id         = "${aws_route_table.private.id}"
  destination_cidr_block = "172.0.0.0/8"
  gateway_id             = "${aws_vpn_gateway.vgw.id}"
}

resource "aws_vpc_dhcp_options" "dhcp" {
  count                = "${var.set_dhcp_option}"
  domain_name          = "${var.active_directory_domain_name}"
  domain_name_servers  = ["${element(split(",", var.active_directory_dc_private_ips), 0)}", "${element(split(",", var.active_directory_dc_private_ips), 1)}"]
  netbios_name_servers = ["${element(split(",", var.active_directory_dc_private_ips), 0)}", "${element(split(",", var.active_directory_dc_private_ips), 1)}"]

  tags {
    Name       = "${var.vpc_name}-DHCP-options"
    created_by = "terraform"
    protected  = true
  }
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  count           = "${var.set_dhcp_option}"
  vpc_id          = "${aws_vpc.vpc.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.dhcp.id}"
}
