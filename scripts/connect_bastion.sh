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
#     made available before.
#   - "jq" is used to parse JSON
#
# Variables:
#   - BASTION_USER_ROLE_ARN: The ARN of the role which authorizes the user to
#                            find the bastion host.
#   - BASTION_HOST_NAME: The name of the bastion host.

export AWS_DEFAULT_REGION="eu-central-1"

# add your service to the "services" array. "forwarding" mentions the local port,
# IP or DNS name of the remote cloud service and the remote port separated by ':'
#
# we separated all remote services by
# a) products
# b) environments
# c) service name
#
# feel free to change this
service_json='{
   "product-a":{
      "deve":{
         "aws_account_id":1234,
         "services":[
            {
               "name":"service-a_10000",
               "forwarding":"10000:some.service.in.the.cloud.com:3306"
            },
            {
               "name":"service-b_10001",
               "forwarding":"10001:some.other.service.in.the.cloud.com:5432"
            }
         ]
      },
      "qa":{
         "aws_account_id":1235,
         "services":[
           {
              "name":"service-a_10100",
              "forwarding":"10100:some.service.in.the.cloud.com:3306"
           },
           {
              "name":"service-b_10101",
              "forwarding":"10001:some.other.service.in.the.cloud.com:5432"
           }
         ]
      },
      "prod":{
         "aws_account_id":1236,
         "services":[
           {
              "name":"service-a_10200",
              "forwarding":"10200:some.service.in.the.cloud.com:3306"
           },
           {
              "name":"service-b_10201",
              "forwarding":"10201:some.other.service.in.the.cloud.com:5432"
           }
         ]
      }
   },
   "product-b":{
      "deve":{
         "aws_account_id":2345,
         "services":[
            {
               "name":"service-c_20001",
               "forwarding":"20001:some.service.c.in.the.cloud.com:5432"
            }
         ]
      },
      "qa":{
         "aws_account_id":2346,
         "services":[
           {
              "name":"service-c_20101",
              "forwarding":"20101:some.service.c.in.the.cloud.com:5432"
           }
        ]
      },
      "prod":{
         "aws_account_id":2347,
         "services":[
           {
              "name":"service-c_20201",
              "forwarding":"20201:some.service.c.in.the.cloud.com:5432"
           }
         ]
      }
   }
}'

products=$(echo "${service_json}" | jq -r 'keys[]')

PS3='Product to connect to: '
options=($products)
select opt in "${options[@]}"
do
  product=$(tr -dc '[[:print:]]' <<< "$opt")
  break
done
echo

environments=$(echo "${service_json}" | jq -r --arg product "${product}" '.[$product] | keys[]')

PS3='Environment to connect to: '
options=($environments)
select opt in "${options[@]}"
do
  environment=$(tr -dc '[[:print:]]' <<< "$opt")
  aws_account_id=$(echo "${service_json}" | jq -r --arg product "${product}" --arg environment "${environment}"  '.[$product] | .[$environment].aws_account_id')
  break
done
echo

services=$(echo "${service_json}" | jq -r --arg product "${product}" --arg environment "${environment}"  '.[$product] | .[$environment].services[].name')

PS3='Service to connect to: '
options=($services)
select opt in "${options[@]}"
do
  service=$(`tr -dc '[[:print:]]' <<< "$opt")
  port_forwarding=$(echo "${service_json}" | jq -r --arg product "${product}" --arg environment "${environment}" --arg service "${service}" '.[$product] | .[$environment].services[] | select(.name==$service).forwarding')
  break
done
echo


# create the temporary SSH key
TEMP_DIRECTORY=$(mktemp -d)

echo -e 'y\n' | ssh-keygen -t rsa -f ${TEMP_DIRECTORY}/bastion_key -N '' >/dev/null 2>&1
ssh_public_key=$(cat "${TEMP_DIRECTORY}/bastion_key.pub")


# find the bastion in the cloud: instance-id and availability zone
BASTION_USER_ROLE="arn:aws:iam::${aws_account_id}:role/find-bastion"

temp_credentials=$(`aws sts assume-role --role-arn "${BASTION_USER_ROLE_ARN}" --role-session-name find-bastion --output json)
export AWS_ACCESS_KEY_ID=$(echo ${temp_credentials} | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo ${temp_credentials} | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo ${temp_credentials} | jq -r .Credentials.SessionToken)

# make sure to match your naming schema here to be able to find the bastion host
BASTION_HOST_NAME="${environment}-bastion-bastion"
json=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${BASTION_HOST_NAME}")

instance_id=$(echo "${json}"" | jq -r .Reservations[0].Instances[0].InstanceId)
az=$(echo "${json}" | jq -r .Reservations[0].Instances[0].Placement.AvailabilityZone)


# send public key: you have to established the connection within the next 60 seconds. Otherwise the key is automatically removed by AWS.
aws ec2-instance-connect send-ssh-public-key --instance-id $instance_id --availability-zone $az --instance-os-user ec2-user --ssh-public-key "$ssh_public_key"

echo "Connection becomes ready in a couple of seconds ..."


# connect via SSH and establish the port forwarding
ssh ec2-user@${instance_id} -i ${TEMP_DIRECTORY}/bastion_key -N -L "${port_forwarding}" -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -o ProxyCommand="aws ssm start-session --target %h --document AWS-StartSSHSession --parameters portNumber=%p"
