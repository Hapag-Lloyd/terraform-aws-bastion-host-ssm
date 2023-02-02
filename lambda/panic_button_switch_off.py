import os

import boto3

def handler(event, context):
  # change the ASG to min=0, max=0, desired=0
  disable_asg()

  # find the EC2 instances and kill them
  kill_running_bastion_hosts(os.environ['BASTION_HOST_NAME'])

def disable_asg():
    pass

def kill_running_bastion_hosts(name):
    ec2 = boto3.resource('ec2',"us-west-1")

    instances = ec2.describe_instances(Filters=[{'Name': 'tag:Name', 'Values': [f'{name}']},
                                              {'Name': 'instance-state-name', 'Values': ['pending', 'running']}])
    instance_ids = [instance.InstanceId for instance in instances.Reservations.Instances]

    ec2.stop_instances(InstanceIds=instance_ids)
