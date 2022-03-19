# terraform-aws-bastion-host-ssm
This Terraform module installs a bastion host accessible via SSM only. The underlying EC2 instance
has no ports opened.

The implemented connection method allows port forwarding for one port only. Multiple port forwardings
can be realized by the user by creating multiple connections.

## Features
- (planned) use autoscaling groups to replace dead instances
- (planned) have a schedule to shutdown the instance at night
- (planned) use spot instances to save some money
- (planned) provide IAM roles for easy access
- (planned) provide a script to connect to the bastion from your local machine

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
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.61.0 |

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
