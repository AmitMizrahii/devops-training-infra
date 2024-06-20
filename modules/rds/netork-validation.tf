locals {
  private_subnets = [for subnet in
  data.aws_subnet.input : subnet.map_public_ip_on_launch == false ? true : false]
}

#######################
# SUBNET VALIDATION
#######################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "input" {
  for_each = toset(var.subnet_ids)
  id       = each.value


  lifecycle {
    postcondition {
      condition     = self.vpc_id != data.aws_vpc.default.id
      error_message = <<-EOT
        The folowing subnet is part of the default VPC
        Id = ${self.id}

        please do int deploy RDS insttaces in the default VPC
        EOT
    }
  }
}

data "aws_route_table" "subnet_route_tables" {
  count     = length(var.subnet_ids)
  subnet_id = var.subnet_ids[count.index]
}


resource "null_resource" "validate_subnets" {
  count = alltrue(local.private_subnets) ? 0 : 1

  provisioner "local-exec" {
    command = "echo 'Error: All provided subnets must be private.'; exit 1"
  }
}


#######################
# SECURITY GROUPS RULES
#######################
data "aws_vpc_security_group_rules" "input" {
  filter {
    name   = "group-id"
    values = var.security_group_ids
  }
}

data "aws_vpc_security_group_rule" "input" {
  for_each = toset(data.aws_vpc_security_group_rules.input.ids)

  security_group_rule_id = each.value

  lifecycle {
    postcondition {
      condition = (
        self.is_egress
        ? true
        : self.cidr_ipv4 == null
        && self.cidr_ipv6 == null
        && self.referenced_security_group_id != null
      )
      error_message = <<-EOT
        The Folowing security group conteain an invalid inbound rule:

        ID = ${self.security_group_id}

        Please ensure that the following conditions are met:
        1. Rules must not allow inbound traffic from IP CIDR blocks, only from other security groups
     EOT
    }
  }
}
