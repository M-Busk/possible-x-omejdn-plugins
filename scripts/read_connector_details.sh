#!/bin/sh

#  Copyright 2024-2025 Dataport. All rights reserved. Developed as part of the POSSIBLE project.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 (name or id) ID"
    exit 1
fi

ID_TYPE=$1
if [ "$ID_TYPE" != "name" ] && [ "$ID_TYPE" != "id" ]; then
    echo "ID type must be either name or id"
    exit 1
fi

if [ "$ID_TYPE" = "name" ]; then
    CLIENT_NAME=$2
    # load certificate file to get client ID from name
    CLIENT_CERT="keys/${CLIENT_NAME}.cert"
    if [ ! -f ${CLIENT_CERT} ]; then
        echo "Client ${CLIENT_NAME} does not exist"
        exit 1
    fi
    SKI="$(grep -A1 "Subject Key Identifier"  "${CLIENT_CERT}" | tail -n 1 | tr -d ' ')"
    AKI="$(grep -A1 "Authority Key Identifier"  "${CLIENT_CERT}" | tail -n 1 | tr -d ' ')"
    CLIENT_ID="$SKI:$AKI"
elif [ "$ID_TYPE" = "id" ]; then
    CLIENT_ID=$2
fi

yq -j '.[] | select(.client_id == "'"${CLIENT_ID}"'")' config/clients.yml