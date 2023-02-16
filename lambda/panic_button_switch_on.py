import logging
import os
import boto3
from botocore.exceptions import ClientError

logging.basicConfig(format='%(asctime)s - %(levelname)s - %(message)s', level=os.environ.get('LOG_LEVEL', 'info'))

logger = logging.getLogger(__name__)


def handler(event, context):
    asg = boto3.client('autoscaling')

    auto_scaling_group_name = os.environ['AUTO_SCALING_GROUP_NAME']

    try:
        # set min/max/desired
        asg.update_auto_scaling_group(AutoScalingGroupName=auto_scaling_group_name,
                                      MinSize=int(os.environ['AUTO_SCALING_GROUP_MIN_SIZE']),
                                      MaxSize=int(os.environ['AUTO_SCALING_GROUP_MAX_SIZE']),
                                      DesiredCapacity=int(os.environ['AUTO_SCALING_GROUP_DESIRED_CAPACITY']))

        # remove all schedules
        response = asg.describe_scheduled_actions(AutoScalingGroupName=auto_scaling_group_name);

        schedule_names = []

        for schedule in response['ScheduledUpdateGroupActions']:
            schedule_names.append(schedule['ScheduledActionName'])

        if schedule_names:
            asg.batch_delete_scheduled_action(AutoScalingGroupName=auto_scaling_group_name,
                                              ScheduledActionNames=schedule_names)
    except ClientError as e:
        logger.error('Failed to update the ASG %s', auto_scaling_group_name, exc_info=e)

        raise

    logger.info("Bastion host(s) switched on")
