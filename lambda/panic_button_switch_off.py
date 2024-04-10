import logging
import os
import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)
logger.setLevel(os.environ.get('LOG_LEVEL', 'info').upper())

def handler(event, context):
    # change the ASG to disable automatic restart
    disable_asg(os.environ['AUTO_SCALING_GROUP_NAME'])

    # find the EC2 instances and kill them
    kill_running_bastion_hosts(os.environ['BASTION_HOST_NAME'])

    logger.info("Bastion host(s) switched off")

def disable_asg(autoscaling_group_name):
    asg = boto3.client('autoscaling')

    try:
        asg.update_auto_scaling_group(AutoScalingGroupName=autoscaling_group_name, MinSize=0, MaxSize=0,
                                      DesiredCapacity=0)
    except ClientError as e:
        logger.error('Failed to update the ASG %s', autoscaling_group_name, exc_info=e)

        raise


def kill_running_bastion_hosts(name):
    ec2 = boto3.client('ec2')

    try:
        instances = ec2.describe_instances(Filters=[{'Name': 'tag:Name', 'Values': [f'{name}']},
                                                    {'Name': 'instance-state-name', 'Values': ['pending', 'running']}])

        if 'Reservations' in instances:
            instance_ids = []

            for r in instances['Reservations']:
                for i in r['Instances']:
                    instance_ids.append(i['InstanceId'])

            if instance_ids:
                ec2.terminate_instances(InstanceIds=instance_ids)

                logger.info("Bastion killed: %s", instance_ids)
    except ClientError as e:
        logger.error('Failed to kill the bastion EC2 instance(s): %s', name, exc_info=e)

        raise
