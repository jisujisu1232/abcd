resource "aws_vpc" "this" {
  cidr_block           = "${var.cidr_block}"
  enable_dns_hostnames = true
  tags = "${
    merge(
      map(
        "Name", "${var.product_name}-${var.stage}-vpc",
        "prefix", "${var.product_name}-${var.stage}-"
      ),
      var.custom_tags
    )
  }"

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "aws_subnet" "pub" {
  vpc_id            = "${aws_vpc.this.id}"
  count             = "${length(var.subnet_pub_info)}"
  cidr_block        = "${var.subnet_pub_info[count.index]["cidr"]}"
  availability_zone = "${var.region}${var.subnet_pub_info[count.index]["az"]}"
  tags = "${
    merge(
      map(
        "Name", "${var.product_name}-${var.stage}-${var.subnet_pub_info[count.index]["task"]}-pub-${var.subnet_pub_info[count.index]["az"]}",
        "prefix", "${var.product_name}-${var.stage}-${var.subnet_pub_info[count.index]["task"]}-",
        "suffix", "-pub-${var.subnet_pub_info[count.index]["az"]}"
      ),
      var.custom_tags
    )
  }"
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "aws_subnet" "pri" {
  vpc_id            = "${aws_vpc.this.id}"
  count             = "${length(var.subnet_pri_info)}"
  cidr_block        = "${var.subnet_pri_info[count.index]["cidr"]}"
  availability_zone = "${var.region}${var.subnet_pri_info[count.index]["az"]}"
  tags = "${
    merge(
      map(
        "Name", "${var.product_name}-${var.stage}-${var.subnet_pri_info[count.index]["task"]}-pri-${var.subnet_pri_info[count.index]["az"]}",
        "prefix", "${var.product_name}-${var.stage}-${var.subnet_pri_info[count.index]["task"]}-",
        "suffix", "-pub-${var.subnet_pri_info[count.index]["az"]}",
        "azs", "${var.subnet_pri_info[count.index]["az"]}"
      ),
      var.custom_tags
    )
  }"
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "aws_subnet" "data" {
  vpc_id            = "${aws_vpc.this.id}"
  count             = "${length(var.subnet_data_info)}"
  cidr_block        = "${var.subnet_data_info[count.index]["cidr"]}"
  availability_zone = "${var.region}${var.subnet_data_info[count.index]["az"]}"
  tags = "${
    merge(
      map(
        "Name", "${var.product_name}-${var.stage}-${var.subnet_data_info[count.index]["task"]}-data-pri-${var.subnet_data_info[count.index]["az"]}",
        "prefix", "${var.product_name}-${var.stage}-${var.subnet_data_info[count.index]["task"]}-",
        "suffix", "-pub-${var.subnet_data_info[count.index]["az"]}",
        "azs", "${var.subnet_pri_info[count.index]["az"]}"
      ),
      var.custom_tags
    )
  }"
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = "${aws_vpc.this.id}"
  tags = "${
    merge(
      map(
        "Name", "${var.product_name}-${var.stage}-igw"
      ),
      var.custom_tags
    )
  }"
}

resource "aws_route_table" "pub" {
  vpc_id = "${aws_vpc.this.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.this.id}"
  }

  tags = "${
    merge(
      map(
        "Name", "${var.product_name}-${var.stage}-pub-rt"
      ),
      var.custom_tags
    )
  }"
}

resource "aws_route_table_association" "pub" {
  count          = "${length(aws_subnet.pub)}"
  subnet_id      = "${aws_subnet.pub[count.index].id}"
  route_table_id = "${aws_route_table.pub.id}"
}

resource "aws_eip" "nat" {
  count = "${length(var.nat_azs)}"
  vpc   = true
  tags = "${
    merge(
      map(
        "Name", "${var.product_name}-${var.stage}-nat-${var.nat_azs[count.index]}-eip"
      ),
      var.custom_tags
    )
  }"
}

resource "aws_nat_gateway" "this" {
  count         = "${length(var.nat_azs)}"
  allocation_id = "${aws_eip.nat[count.index].id}"
  subnet_id     = "${aws_subnet.pub[0].id}"
  tags = "${
    merge(
      map(
        "Name", "${var.product_name}-${var.stage}-nat-${var.nat_azs[count.index]}"
      ),
      var.custom_tags
    )
  }"
}

resource "aws_route_table" "pri" {
  count  = "${length(var.nat_azs)}"
  vpc_id = "${aws_vpc.this.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.this[count.index].id}"
  }

  tags = "${
    merge(
      map(
        "Name", "${var.product_name}-${var.stage}-pri${length(var.nat_azs) == 1 ? "" : "-${var.nat_azs[count.index]}"}-rt"
      ),
      var.custom_tags
    )
  }"
}

resource "aws_route_table_association" "pri" {
  count          = "${length(aws_subnet.pri)}"
  subnet_id      = "${aws_subnet.pri[count.index].id}"
  route_table_id = "${aws_route_table.pri[index(var.nat_azs, aws_subnet.pri[count.index].tags["azs"]) < 0 ? 0 : index(var.nat_azs, aws_subnet.pri[count.index].tags["azs"])].id}"
}

resource "aws_route_table" "data" {
  count  = "${length(var.nat_azs)}"
  vpc_id = "${aws_vpc.this.id}"

  tags = "${
    merge(
      map(
        "Name", "${var.product_name}-${var.stage}-data${length(var.nat_azs) == 1 ? "" : "-${var.nat_azs[count.index]}"}-rt"
      ),
      var.custom_tags
    )
  }"
}

resource "aws_route" "data" {
  count                  = "${length(aws_route_table.data)}"
  route_table_id         = "${aws_route_table.data[count.index].id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.this[count.index].id}"
  depends_on             = ["aws_route_table.data"]
}

resource "aws_route_table_association" "data" {
  count          = "${var.data_subnet_route_nat ? length(aws_subnet.data) : 0}"
  subnet_id      = "${aws_subnet.data[count.index].id}"
  route_table_id = "${aws_route_table.data[index(var.nat_azs, aws_subnet.data[count.index].tags["azs"]) < 0 ? 0 : index(var.nat_azs, aws_subnet.data[count.index].tags["azs"])].id}"
}
