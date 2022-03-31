#!/usr/bin/env bash

#
# Allows the user to select the product, service and environment to connect to.
#
# Finds the bastion host in the cloud account, sends the temporary SSH key and
# establishes the port forwarding.
#
# Requirements:
#   - install the Session Manager Plugin before
#   - AWS CLI credentials of the user able to connect to the bastion must be
#     made available before (export AWS_ACCESS_KEY_ID, ...)
#   - "jq" is used to parse JSON
#
# Variables:
#   - BASTION_USER_ROLE_ARN: The ARN of the role which authorizes the user to
#                            find the bastion host.
#   - BASTION_HOST_NAME: The name of the bastion host.

export AWS_DEFAULT_REGION="eu-central-1"

CWD=$(dirname $0)
BASTION_SERVICES_FILE="$CWD/bastion_services.json"


PS3='Product to connect to: '
mapfile -t options < <(jq -r 'keys[]' "$BASTION_SERVICES_FILE")
select opt in "${options[@]}"
do
  product=$(tr -dc '[:print:]' <<< "$opt")
  break
done
echo

PS3='Environment to connect to: '
mapfile -t options < <(jq -r --arg product "${product}" '.[$product] | keys[]' "$BASTION_SERVICES_FILE")
select opt in "${options[@]}"
do
  environment=$(tr -dc '[:print:]' <<< "$opt")
  aws_account_id=$(jq -r --arg product "${product}" --arg environment "${environment}"  '.[$product] | .[$environment].aws_account_id' "$BASTION_SERVICES_FILE")
  bastion_host_name=$(jq -r --arg product "${product}" --arg environment "${environment}"  '.[$product] | .[$environment].bastion_host_name' "$BASTION_SERVICES_FILE")
  connection_role_name=$(jq -r --arg product "${product}" --arg environment "${environment}"  '.[$product] | .[$environment].connection_role_name' "$BASTION_SERVICES_FILE")
  break
done
echo

PS3='Service to connect to: '
mapfile -t options < <(jq -r --arg product "${product}" --arg environment "${environment}"  '.[$product] | .[$environment].services[].name' "$BASTION_SERVICES_FILE")
select opt in "${options[@]}"
do
  service=$(tr -dc '[:print:]' <<< "$opt")
  port_forwarding=$(jq -r --arg product "${product}" --arg environment "${environment}" --arg service "${service}" '.[$product] | .[$environment].services[] | select(.name==$service).forwarding' "$BASTION_SERVICES_FILE")
  region=$(jq -r --arg product "${product}" --arg environment "${environment}" --arg service "${service}" '.[$product] | .[$environment].services[] | select(.name==$service).region' "$BASTION_SERVICES_FILE")
  break
done
echo


# create the temporary SSH key
TEMP_DIRECTORY=$(mktemp -d)

echo -e 'y\n' | ssh-keygen -t rsa -f "${TEMP_DIRECTORY}/bastion_key" -N '' >/dev/null 2>&1
ssh_public_key=$(cat "${TEMP_DIRECTORY}/bastion_key.pub")


# find the bastion in the cloud: instance-id and availability zone
BASTION_USER_ROLE_ARN="arn:aws:iam::${aws_account_id}:role/$connection_role_name"

temp_credentials=$(aws sts assume-role --role-arn "${BASTION_USER_ROLE_ARN}" --role-session-name connect-bastion --output json)
AWS_ACCESS_KEY_ID=$(echo "${temp_credentials}" | jq -r .Credentials.AccessKeyId)
export AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$(echo "${temp_credentials}" | jq -r .Credentials.SecretAccessKey)
export AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN=$(echo "${temp_credentials}" | jq -r .Credentials.SessionToken)
export AWS_SESSION_TOKEN

# find all running Bastion hosts
instances=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=${bastion_host_name}" --region ${region} | jq '[.Reservations[].Instances[] | {instanceId: .InstanceId, availabilityZone: .Placement.AvailabilityZone}]')
total_instances=$(echo "$instances" | jq -r '. | length')
selected_instance=$(( RANDOM % total_instances ))

instance_id=$(echo "$instances" | jq -r .[${selected_instance}].instanceId)
az=$(echo "$instances" | jq -r .[${selected_instance}].availabilityZone)

# send public key: you have to established the connection within the next 60 seconds. Otherwise the key is automatically removed by AWS.
aws ec2-instance-connect send-ssh-public-key --instance-id "${instance_id}" --availability-zone "${az}" --instance-os-user ec2-user --ssh-public-key "${ssh_public_key}"

echo "Connection becomes ready in a couple of seconds ..."


# connect via SSH and establish the port forwarding
ssh "ec2-user@${instance_id}" -i "${TEMP_DIRECTORY}/bastion_key" -N -L "${port_forwarding}" -o "ServerAliveInterval=180" -o "ServerAliveCountMax=2" -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -o ProxyCommand="aws ssm start-session --target %h --document AWS-StartSSHSession --parameters portNumber=%p"
