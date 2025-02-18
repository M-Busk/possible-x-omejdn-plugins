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

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 CLIENT_ID"
    exit 1
fi

CLIENT_ID=$1
CLIENT_NAME=$(yq -r '.[] | select(.client_id == "'"${CLIENT_ID}"'") | .client_name' config/clients.yml)

echo "Removing ${CLIENT_NAME} from clients.yml"
# remove entry from yaml
yq -i -y 'del(.[] | select(.client_id == "'"${CLIENT_ID}"'"))' config/clients.yml
# if no entries are left, remove the empty list as well
sed -i '/^\[\]/d' config/clients.yml

# remove corresponding key and certificate files
echo "Removing ${CLIENT_NAME} keys and certificates"
rm keys/${CLIENT_NAME}.key keys/${CLIENT_NAME}.cert keys/clients/${CLIENT_ID}.cert