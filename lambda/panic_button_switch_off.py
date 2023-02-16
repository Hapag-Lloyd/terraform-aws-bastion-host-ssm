import logging
import os
import boto3
from botocore.exceptions import ClientError

logging.basicConfig(format='%(asctime)s - %(levelname)s - %(message)s', level=os.environ.get('LOG_LEVEL', 'info'))

logger = logging.getLogger(__name__)


def handler(event, context):
    # change the ASG to disable automatic restart
    disable_asg(os.environ['AUTO_SCALING_GROUP_NAME'])

    # find the EC2 instances and kill them
    kill_running_bastion_hosts(os.environ['BASTION_HOST_NAME'])


def disable_asg(autoscalingGroupName):
    asg = boto3.resource('autoscaling')

    try:
        asg.update_auto_scaling_group(AutoScalingGroupName=autoscalingGroupName, MinSize=0, MaxSize=0,
                                      DesiredCapacity=0)
    except ClientError as e:
        logger.error('Failed to update the ASG %s', autoscalingGroupName, exc_info=e)

        raise


def kill_running_bastion_hosts(name):
    ec2 = boto3.resource('ec2')

    try:
        instances = ec2.describe_instances(Filters=[{'Name': 'tag:Name', 'Values': [f'{name}']},
                                                    {'Name': 'instance-state-name', 'Values': ['pending', 'running']}])
        instance_ids = [instance.InstanceId for instance in instances.Reservations.Instances]

        ec2.stop_instances(InstanceIds=instance_ids)
    except ClientError as e:
        logger.error('Failed to kill the bastion EC2 instance(s): %s', name, exc_info=e)

        raise
