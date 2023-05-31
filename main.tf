resource "aws_vpc" "main"{
  cidr_block = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(var.tags,{Name = "${var.env}-vpc"} )
}

module "subnets"{
  source = "./subnets"
  for_each = var.subnets
  vpc_id =aws_vpc.main.id
  cidr_block = each.value["cidr_block"]
  name = each.value["name"]
  azs= each.value["azs"]
  env=var.env
  tags = var.tags
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags,{Name = "${var.env}-igw"} )
  }

resource "aws_eip" "eip" {
  count= length(lookup(lookup(var.subnets, "public",null ), "cidr_block" ,0))
  #count = length(var.subnets["public"].cidr_block)
  vpc = true
  tags = merge(var.tags,{Name = "${var.env}-eip-${count.index+1}"} )

}

resource "aws_nat_gateway" "ngw" {
  count= length(lookup(lookup(var.subnets, "public",null ), "cidr_block" ,0))
  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = module.subnets["public"].subnet_ids[count.index]

  tags = merge(var.tags,{Name = "${var.env}-ngw-${count.index+1}"} )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  #depends_on = [aws_internet_gateway.example]
}