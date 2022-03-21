#!/bin/bash

#
# Reads the access key and secret access key for the Bastion user from Keepass.
# The AWS credentials are exported and can be used by the AWS CLI.
#
# Variables:
#   - KEEPASS_FILE: points to the Keepass database containing the AWS credentials
#   - BASTION_USER_TITLE: the title of the entry in Keepass holding the AWS credentials
#
# Requirements:
#   - Keepass installed (https://keepass.info/download.html)
#   - KPScript plugin installed (https://keepass.info/extensions/v2/kpscript/KPScript-2.50.zip)
#   - KPScript plugin must be available in the PATH
#

KEEPASS_FILE="/path/to/keepass/database.kdbx"
BASTION_USER_TITLE="Bastion User"

# get AWS credentials for user who is allowed to connect to the bastion
read -rsp 'Keepass Password: ' keepass_password

access_key=$(KPScript.exe -c:GetEntryString "${KEEPASS_FILE}" -Field:UserName -ref-Title:"${BASTION_USER_TITLE}" -FailIfNoEntry -pw:"${keepass_password}" | head -n1)
export AWS_ACCESS_KEY_ID=${access_key}

secret_access_key=$(KPScript.exe -c:GetEntryString "${KEEPASS_FILE}" -Field:Password -ref-Title:"${BASTION_USER_TITLE}" -FailIfNoEntry -pw:"${keepass_password}" | head -n1)
export AWS_SECRET_ACCESS_KEY=${secret_access_key}

export AWS_SESSION_TOKEN=""
