# Simple Example

The easiest way to use this module, simple and straight forward.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.26.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.26.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bastion_host"></a> [bastion\_host](#module\_bastion\_host) | ../../ | n/a |
| <a name="module_bastion_user"></a> [bastion\_user](#module\_bastion\_user) | terraform-aws-modules/iam/aws//modules/iam-user | 5.32.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.2 |

## Resources

| Name | Type |
|------|------|
| [aws_security_group.endpoint](https://registry.terraform.io/providers/hashicorp/aws/5.26.0/docs/resources/security_group) | resource |
| [aws_security_group_rule.ingress_ssm](https://registry.terraform.io/providers/hashicorp/aws/5.26.0/docs/resources/security_group_rule) | resource |
| [aws_vpc_endpoint.endpoints](https://registry.terraform.io/providers/hashicorp/aws/5.26.0/docs/resources/vpc_endpoint) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/5.26.0/docs/data-sources/availability_zones) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/5.26.0/docs/data-sources/region) | data source |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->