# terraform-aws-bastion-host-ssm

This Terraform module installs a bastion host accessible via SSM only. The underlying EC2 instance
has no ports opened. All data is encrypted and a `resource_prefix` can be specified to integrate into
your naming schema.

The implemented connection method allows port forwarding for one port only. Multiple port forwardings
can be realized by the user by creating multiple connections to the bastion host.

Check the `examples` directory for the module usage.

## Cost Estimation (1.7.0)

```
 Name                                                   Monthly Qty  Unit   Monthly Cost

 module.bastion_host.aws_autoscaling_group.this
 └─ module.bastion_host.aws_launch_configuration.this
    ├─ Instance usage (Linux/UNIX, on-demand, t3.nano)          730  hours         $4.38
    └─ root_block_device
       └─ Storage (general purpose SSD, gp3)                      8  GB            $0.76

 OVERALL TOTAL                                                                     $5.14
```

## Features

- use autoscaling groups to replace dead instances
- have a schedule to shutdown the instance at night
- Keepass support for AWS credentials
- (planned) use spot instances to save some money
- provide IAM role for easy access
- provide a script to connect to the bastion from your local machine

### Keepass Support For IAM User Credentials

In case you are not using SSO or similar techniques you have to store the credentials for the user able to
connect to the bastion host somewhere. We provide a little helper script to handle this scenario in a secure way.

Create a [Keepass](https://keepass.info/download.html) database and add the [KPScript plugin](https://keepass.info/extensions/v2/kpscript/KPScript-2.50.zip).
The `scripts/export_aws_credentials_from_keypass.sh` will read and export the credentials from the Keepass database.

### Schedules

Schedules allow to start and shutdown the instance at certain times. If your work hours are from 9 till 5 in Berlin, add

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

The bastion host will automatically start at 9 and shuts down at 17 from monday to friday (Berlin time). Depending on the `instance_type` you will save
more or less money. Do not forget to adjust the timezone.

In case you have to start a bastin host outside the working hours use the launch template provided by the module and launch the
new instance from the AWS CLI or Console. Don't forget to shut it down if you are done.

## Connect To The Bastion Host

The Session Manager Plugin is needed to connect via SSM to the bastion host. Download it at https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

### AWS-Gate
AWS-Gate is available at https://github.com/xen0l/aws-gate

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

aws ec2-instance-connect send-ssh-public-key --instance-id "${instance_id}" --availability-zone "${az}" --instance-os-user ec2-user --ssh-public-key "${ssh_public_key}"

ssh "ec2-user@${instance_id}" -i bastion_key -N -L "12345:my.cloud.http:80" -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -o ProxyCommand="aws ssm start-session --target %h --document AWS-StartSSHSession --parameters portNumber=%p"

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
| <a name="module_instance_profile_role"></a> [instance\_profile\_role](#module\_instance\_profile\_role) | terraform-aws-modules/iam/aws//modules/iam-assumable-role | 4.15.1 |

## Resources

| Name | Type |
|------|------|
| [aws_ami_copy.latest_amazon_linux](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ami_copy) | resource |
| [aws_autoscaling_group.on_demand](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_group.on_spot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_schedule.on_demand_down](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_schedule) | resource |
| [aws_autoscaling_schedule.on_demand_up](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_schedule) | resource |
| [aws_autoscaling_schedule.on_spot_down](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_schedule) | resource |
| [aws_autoscaling_schedule.on_spot_up](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_schedule) | resource |
| [aws_iam_policy.access_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.access_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.access_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_configuration) | resource |
| [aws_launch_template.manual_start](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.egress_open_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.egress_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ami.latest_amazon_linux](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_iam_policy_document.access_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bastion_access_tag_value"></a> [bastion\_access\_tag\_value](#input\_bastion\_access\_tag\_value) | Value added as tag 'bastion-access' of the launched EC2 instance to be used to restrict access to the machine vie IAM. | `string` | `"developer"` | no |
| <a name="input_egress_open_tcp_ports"></a> [egress\_open\_tcp\_ports](#input\_egress\_open\_tcp\_ports) | The list of TCP ports to open for outgoing traffic. | `list(number)` | n/a | yes |
| <a name="input_iam_role_path"></a> [iam\_role\_path](#input\_iam\_role\_path) | Role path for the created bastion instance profile. Must end with '/' | `string` | `"/"` | no |
| <a name="input_iam_user_arn"></a> [iam\_user\_arn](#input\_iam\_user\_arn) | ARN of the user who is allowed to assume the role giving access to the bastion host. | `string` | n/a | yes |
| <a name="input_instance"></a> [instance](#input\_instance) | Defines the basic parameters for the EC2 instance used as Bastion host | <pre>object({<br>    type              = string # EC2 instance type<br>    desired_capacity  = number # number of EC2 instances to run<br>    root_volume_size  = number # in GB<br>    enable_monitoring = bool<br><br>    enable_spot = bool<br>  })</pre> | <pre>{<br>  "desired_capacity": 1,<br>  "enable_monitoring": false,<br>  "enable_spot": false,<br>  "root_volume_size": 8,<br>  "type": "t3.nano"<br>}</pre> | no |
| <a name="input_resource_names"></a> [resource\_names](#input\_resource\_names) | Settings for generating resource names. Set the prefix and the separator according to your company style guide. | <pre>object({<br>    prefix    = string<br>    separator = string<br>  })</pre> | <pre>{<br>  "prefix": "bastion",<br>  "separator": "-"<br>}</pre> | no |
| <a name="input_schedule"></a> [schedule](#input\_schedule) | Defines when to start and stop the instances. Use 'start' and 'stop' with a cron expression and add the 'time\_zone'. | <pre>object({<br>    start     = string<br>    stop      = string<br>    time_zone = string<br>  })</pre> | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | The subnets to place the bastion in. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A list of tags to add to all resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The bastion host resides in this VPC. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the security group assigned to the bastion host. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
