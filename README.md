# terraform-aws-bastion-host-ssm

This Terraform module installs a bastion host accessible via SSM only. The underlying EC2 instance
has no ports opened. All data is encrypted and a `resource_prefix` can be specified to integrate into
your naming schema.

The implemented connection method allows port forwarding for one port only. Multiple port forwardings
can be realized by the user by creating multiple connections to the bastion host.

Check the `examples` directory for the module usage.

## Features

- use autoscaling groups to replace dead instances
- have a schedule to shutdown the instance at night
- Keepass support for AWS credentials
- (planned) use spot instances to save some money
- (planned) provide IAM roles for easy access
- provide a script to connect to the bastion from your local machine

### Keepass Support For IAM User Credentials

In case you are not using SSO or similar techniques you have to store the credentials for the user able to
connect to the bastion host somewhere. We provide a little helper script to handle this scenario in a secure way.

Create a [Keepass](https://keepass.info/download.html) database and add the [KPScript plugin](https://keepass.info/extensions/v2/kpscript/KPScript-2.50.zip).
The `scripts/export_aws_credentials_from_keypass.sh` will read and export the credentials from the Keepass database.

### Schedules

Schedules allow to start and shutdown the instance at certain times. If your work hours are from 9 till 5 UTC, add

```hcl
module "bastion" {
  ...
  schedule {
    start = "0 9 * * MON-FRI"
    stop = "0 17 * * MON-FRI"

    time_zone = "Europe/Berlin"
  }
}
```

The bastion host will automatically start at 9 UTC and shuts down at 17 UTC every day. Depending on the `instance_type` you will save
more or less money.

## Connect To The Bastion Host

   1. Export the AWS credentials for the user able to connect to the bastion host.
   2. Execute `scripts/connect_bastion.sh`. Make sure to add the port forwarding and change the role ARN and bastion instance name.
   3. Access the forwarded service through the local port.

Direct access to the bastion host is not granted but the specified port is forwarded. This
way you can access the database, Redis cluster, ...

## A Bastion Host

- allows access to the infrastructure which is not exposed to the internet
- designed to withstand attacks
- also known as jump host

[Wikipedia](https://en.wikipedia.org/wiki/Bastion_host)

# Module Documentation

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.53.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_instance_profile_role"></a> [instance\_profile\_role](#module\_instance\_profile\_role) | terraform-aws-modules/iam/aws//modules/iam-assumable-role | 4.14.0 |

## Resources

| Name | Type |
|------|------|
| [aws_ami_copy.latest_amazon_linux](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ami_copy) | resource |
| [aws_autoscaling_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_schedule.down](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_schedule) | resource |
| [aws_autoscaling_schedule.up](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_schedule) | resource |
| [aws_launch_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_configuration) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.egress_open_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.egress_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ami.latest_amazon_linux](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_region.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bastion_access_tag_value"></a> [bastion\_access\_tag\_value](#input\_bastion\_access\_tag\_value) | Value added as tag 'bastion-access' of the launched EC2 instance to be used to restrict access to the machine vie IAM. | `string` | `"developer"` | no |
| <a name="input_egress_open_tcp_ports"></a> [egress\_open\_tcp\_ports](#input\_egress\_open\_tcp\_ports) | The list of TCP ports to open for outgoing traffic. | `list(number)` | n/a | yes |
| <a name="input_iam_role_path"></a> [iam\_role\_path](#input\_iam\_role\_path) | Role path for the created bastion instance profile. Must end with '/' | `string` | `"/"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type of the bastion | `string` | `"t3.nano"` | no |
| <a name="input_resource_names"></a> [resource\_names](#input\_resource\_names) | Settings for generating resource names. Set the prefix and the separator according to your company style guide. | <pre>object({<br>    prefix    = string<br>    separator = string<br>  })</pre> | <pre>{<br>  "prefix": "bastion",<br>  "separator": "-"<br>}</pre> | no |
| <a name="input_root_volume_size"></a> [root\_volume\_size](#input\_root\_volume\_size) | Size of the root volume in GB | `number` | `8` | no |
| <a name="input_schedule"></a> [schedule](#input\_schedule) | Defines when to start and stop the instances. Use 'start' and 'stop' with a cron expression and add the 'time\_zone'. | <pre>object({<br>    start     = string<br>    stop      = string<br>    time_zone = string<br>  })</pre> | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | The subnets to place the bastion in. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A list of tags to add to all resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The bastion host resides in this VPC. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the security group assigned to the bastion host. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
