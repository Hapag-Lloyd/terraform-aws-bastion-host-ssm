# Simple Example

The easiest way to use this module, simple and straight forward.

<!-- the following placeholder is filled by terraform-docs and the generated headings have level 2. -->
<!-- markdownlint-disable MD025 -->
# Module Documentation

<!-- markdownlint-disable -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.44.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.44.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bastion_host"></a> [bastion\_host](#module\_bastion\_host) | ../../ | n/a |
| <a name="module_bastion_user"></a> [bastion\_user](#module\_bastion\_user) | terraform-aws-modules/iam/aws//modules/iam-user | 5.39.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.7 |

## Resources

| Name | Type |
|------|------|
| [aws_security_group.endpoint](https://registry.terraform.io/providers/hashicorp/aws/5.44.0/docs/resources/security_group) | resource |
| [aws_security_group_rule.ingress_ssm](https://registry.terraform.io/providers/hashicorp/aws/5.44.0/docs/resources/security_group_rule) | resource |
| [aws_vpc_endpoint.endpoints](https://registry.terraform.io/providers/hashicorp/aws/5.44.0/docs/resources/vpc_endpoint) | resource |
| [aws_ami.latest_amazon_linux](https://registry.terraform.io/providers/hashicorp/aws/5.44.0/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/5.44.0/docs/data-sources/availability_zones) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/5.44.0/docs/data-sources/region) | data source |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->
