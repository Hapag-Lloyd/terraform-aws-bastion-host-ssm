# terraform-aws-bastion-host-ssm

[![Terraform registry](https://img.shields.io/github/v/release/Hapag-Lloyd/terraform-aws-bastion-host-ssm?label=Terraform%20Registry)](https://registry.terraform.io/modules/Hapag-Lloyd/bastion-host-ssm/aws/)
[![Actions](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/workflows/Release/badge.svg)](https://github.com/Hapag-Lloyd/terraform-aws-bastion-host-ssm/actions)

This Terraform module installs a bastion host accessible via SSM only. The underlying EC2 instance
has no ports opened. All data is encrypted and a `resource_prefix` can be specified to integrate into
your naming schema.

The implemented connection method allows port forwarding for one port only. Multiple port forwardings
can be realized by the user by creating multiple connections to the bastion host.

Check the `examples` directory for the module usage.

## Cost Estimation (for version 2.4.0)

```text
Name                                                                    Monthly Qty  Unit                   Monthly Cost
module.bastion_host.aws_autoscaling_group.on_spot[0]
 └─ module.bastion_host.aws_launch_template.manual_start
    ├─ Instance usage (Linux/UNIX, on-demand, t3.nano)                          730  hours                         $4.38
      └─ root_block_device
         └─ Storage (general purpose SSD, gp3)                                   16  GB                            $1.52
    └─ Instance usage (Linux/UNIX, spot, t3.nano)                               730  hours                         $1.31
      └─ root_block_device
         └─ Storage (general purpose SSD, gp3)                                   16  GB                            $1.52

 module.bastion_host.aws_cloudwatch_log_group.panic_button_off
 ├─ Data ingested                                               Monthly cost depends on usage: $0.63 per GB
 ├─ Archival Storage                                            Monthly cost depends on usage: $0.0324 per GB
 └─ Insights queries data scanned                               Monthly cost depends on usage: $0.0063 per GB

 module.bastion_host.aws_cloudwatch_log_group.panic_button_on
 ├─ Data ingested                                               Monthly cost depends on usage: $0.63 per GB
 ├─ Archival Storage                                            Monthly cost depends on usage: $0.0324 per GB
 └─ Insights queries data scanned                               Monthly cost depends on usage: $0.0063 per GB

 module.bastion_host.aws_lambda_function.panic_button_off
 ├─ Requests                                                    Monthly cost depends on usage: $0.20 per 1M requests
 └─ Duration                                                    Monthly cost depends on usage: $0.0000166667 per GB-seconds

 module.bastion_host.aws_lambda_function.panic_button_on
 ├─ Requests                                                    Monthly cost depends on usage: $0.20 per 1M requests
 └─ Duration                                                    Monthly cost depends on usage: $0.0000166667 per GB-seconds

 OVERALL TOTAL                                                                                                     $8.73
```

## Features

- use autoscaling groups to replace dead instances
- have a schedule to shut down the instance at night
- Keepass support for AWS credentials
- use spot instances to save some money
- provide IAM role for easy access
- provide a script to connect to the bastion from your local machine
- panic switch to enable the bastions or disable them immediately

### Panic Switch

Two lambda functions are provided. One to enable the bastion host, e.g. if you have to work at night and the bastion
hosts are deactivated. The second lambda function disables the bastion host immediately no matter what.

As both functions are destructive (they modify the autoscaling group), you have to re-apply this module as soon as
possible to restore the auto scaling setting (especially the schedules).

If your bastion host runs 24/7, you can disable the panic switch by setting `enable_panic_switches = false`.

### Keepass Support For IAM User Credentials

In case you are not using SSO or similar techniques you have to store the credentials for the user able to
connect to the bastion host somewhere. We provide a little helper script to handle this scenario in a secure way.

Create a [Keepass](https://keepass.info/download.html) database and add the [KPScript plugin](https://keepass.info/extensions/v2/kpscript/KPScript-2.50.zip).
The `scripts/export_aws_credentials_from_keepass.sh` will read and export the credentials from the Keepass database.

### Schedules

Schedules allow to start and shutdown the instance at certain times. If your work hours are from 9 till 5 in Berlin, add

```hcl
module "bastion" {
  # ...
  schedule {
    start = "0 9 * * MON-FRI"
    stop = "0 17 * * MON-FRI"

    time_zone = "Europe/Berlin"
  }
}
```

The bastion host will automatically start at 9 and shuts down at 17 from monday to friday (Berlin time). Depending on
the `instance_type` you will save more or less money. Do not forget to adjust the timezone.

In case you have to start a bastion host outside the working hours use the launch template provided by the module and launch the
new instance from the AWS CLI or Console. Don't forget to shut it down if you are done.

### Encryption

In case you are using spot instances don't forget to allow `AWSServiceRoleForAutoScaling` to access your keys.

```hcl
data "aws_iam_policy_document" "key_policy" {
    # ...

    statement {
    sid    = "AdminKMSManagement"
    effect = "Allow"

    principals {
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
      type = "AWS"
    }

    actions = [
      "kms:*"
    ]
    resources = ["*"]
    }

    statement {
    sid    = "Allow spot instances use of the customer managed key"
    effect = "Allow"

    principals {
      identifiers = ["arn:aws:iam::${var.aws_account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
      type        = "AWS"
    }

    actions = ["kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Allow attachment of persistent resources"
    effect = "Allow"

    principals {
      identifiers = ["arn:aws:iam::${var.aws_account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
      type        = "AWS"
    }

    actions   = ["kms:CreateGrant"]
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}
```

## Connect To The Bastion Host

The [Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
is needed to connect via SSM to the bastion host.

### AWS-Gate

[AWS-Gate](https://github.com/xen0l/aws-gate).

### AWS CLI

```bash
instance_id="my-bastion-instance-id"
az="az-of-the-bastion"

export AWS_ACCESS_KEY_ID="xxxxx"
export AWS_SECRET_ACCESS_KEY="yyyyy"
export AWS_SESSION_TOKEN=""

aws sts assume-role --role-arn the-bastion-role-arn --role-session-profile bastion
echo "export the credentials from above!"

echo -e 'y\n' | ssh-keygen -t rsa -f bastion_key -N '' >/dev/null 2>&1
ssh_public_key=$(cat bastion_key.pub)

aws ec2-instance-connect send-ssh-public-key --instance-id "${instance_id}" --availability-zone "${az}" \
      --instance-os-user ec2-user --ssh-public-key "${ssh_public_key}"

ssh "ec2-user@${instance_id}" -i bastion_key -N -L "12345:my.cloud.http:80" -o "UserKnownHostsFile=/dev/null" \
    -o "StrictHostKeyChecking=no" -o ProxyCommand="aws ssm start-session --target %h --document AWS-StartSSHSession \
      --parameters portNumber=%p"

curl http://localhost:12345/
```

### AWS CLI With Menu

   1. Export the AWS credentials for the user able to connect to the bastion host.
   2. Execute `scripts/connect_bastion.sh`. Make sure to add the port forwarding and change the role ARN and bastion instance name.
   3. Access the forwarded service through the local port.

Direct access to the bastion host is not granted but the specified port is forwarded. This
way you can access the database, Redis cluster, ... directly from your localhost.

## A Bastion Host

- allows access to the infrastructure which is not exposed to the internet
- designed to withstand attacks
- also known as jump host

[Wikipedia](https://en.wikipedia.org/wiki/Bastion_host)

<!-- the following placeholder is filled by terraform-docs and the generated headings have level 2. -->
<!-- markdownlint-disable MD025 -->
# Module Documentation

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | >= 2.0.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_instance_profile_role"></a> [instance\_profile\_role](#module\_instance\_profile\_role) | terraform-aws-modules/iam/aws//modules/iam-assumable-role | 5.39.0 |

## Resources

| Name | Type |
|------|------|
| [aws_ami_copy.latest_amazon_linux](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ami_copy) | resource |
| [aws_autoscaling_group.on_demand](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_group.on_spot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_schedule.down](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_schedule) | resource |
| [aws_autoscaling_schedule.up](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_schedule) | resource |
| [aws_cloudwatch_log_group.panic_button_off](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.panic_button_on](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.access_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.panic_button_off](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.panic_button_on](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.access_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.panic_button_off_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.panic_button_on_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.access_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.panic_button_off](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.panic_button_off_basic_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.panic_button_off_x_ray](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.panic_button_on](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.panic_button_on_basic_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.panic_button_on_x_ray](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.panic_button_off](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.panic_button_on](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_launch_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_configuration) | resource |
| [aws_launch_template.manual_start](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.egress_open_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.egress_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [archive_file.panic_button_off_package](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.panic_button_on_package](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_ami.deprecated_latest_amazon_linux](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.access_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.panic_button_off](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.panic_button_off_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.panic_button_on](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.panic_button_on_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | The AMI ID to use for the bastion host. If not set, the latest AMI matching the ami\_name\_filter will be used. | `string` | `null` | no |
| <a name="input_ami_name_filter"></a> [ami\_name\_filter](#input\_ami\_name\_filter) | (Deprecated; set var.ami\_id instead; will be removed in v3.0.0) The search filter string for the bastion AMI. | `string` | `"amzn2-ami-hvm-*-x86_64-ebs"` | no |
| <a name="input_bastion_access_tag_value"></a> [bastion\_access\_tag\_value](#input\_bastion\_access\_tag\_value) | Value added as tag 'bastion-access' of the launched EC2 instance to be used to restrict access to the machine vie IAM. | `string` | `"developer"` | no |
| <a name="input_egress_open_tcp_ports"></a> [egress\_open\_tcp\_ports](#input\_egress\_open\_tcp\_ports) | The list of TCP ports to open for outgoing traffic. | `list(number)` | n/a | yes |
| <a name="input_iam_role_path"></a> [iam\_role\_path](#input\_iam\_role\_path) | Role path for the created bastion instance profile. Must end with '/'. Not used if instance["profile\_name"] is set. | `string` | `"/"` | no |
| <a name="input_iam_user_arns"></a> [iam\_user\_arns](#input\_iam\_user\_arns) | ARNs of the user who are allowed to assume the role giving access to the bastion host. Not used if instance["profile\_name"] is set. | `list(string)` | n/a | yes |
| <a name="input_instance"></a> [instance](#input\_instance) | Defines the basic parameters for the EC2 instance used as Bastion host | <pre>object({<br>    type              = string # EC2 instance type<br>    desired_capacity  = number # number of EC2 instances to run<br>    root_volume_size  = number # in GB<br>    enable_monitoring = bool<br>    enable_spot       = bool<br>    profile_name      = string<br>  })</pre> | <pre>{<br>  "desired_capacity": 1,<br>  "enable_monitoring": false,<br>  "enable_spot": false,<br>  "profile_name": "",<br>  "root_volume_size": 8,<br>  "type": "t3.nano"<br>}</pre> | no |
| <a name="input_instances_distribution"></a> [instances\_distribution](#input\_instances\_distribution) | Defines the parameters for mixed instances policy auto scaling | <pre>object({<br>    on_demand_base_capacity                  = number # absolute minimum amount of on_demand instances<br>    on_demand_percentage_above_base_capacity = number # percentage split between on-demand and Spot instances<br>    spot_allocation_strategy                 = string<br>  })</pre> | <pre>{<br>  "on_demand_base_capacity": 0,<br>  "on_demand_percentage_above_base_capacity": 0,<br>  "spot_allocation_strategy": "lowest-price"<br>}</pre> | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | The ARN of the KMS key used to encrypt the resources. | `string` | `null` | no |
| <a name="input_resource_names"></a> [resource\_names](#input\_resource\_names) | Settings for generating resource names. Set the prefix and the separator according to your company style guide. | <pre>object({<br>    prefix    = string<br>    separator = string<br>  })</pre> | <pre>{<br>  "prefix": "bastion",<br>  "separator": "-"<br>}</pre> | no |
| <a name="input_schedule"></a> [schedule](#input\_schedule) | Defines when to start and stop the instances. Use 'start' and 'stop' with a cron expression and add the 'time\_zone'. | <pre>object({<br>    start     = string<br>    stop      = string<br>    time_zone = string<br>  })</pre> | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | The subnets to place the bastion in. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A list of tags to add to all resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The bastion host resides in this VPC. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the security group assigned to the bastion host. |
<!-- END_TF_DOCS -->
