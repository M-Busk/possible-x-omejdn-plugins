#!/bin/sh

#  Copyright 2024 Dataport. All rights reserved. Developed as part of the MERLOT project.
#  Copyright 2024-2025 Dataport. All rights reserved. Extended as part of the POSSIBLE project.
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
    echo "Usage: $0 NAME DID"
    exit 1
fi

CLIENT_NAME=$1
ATTESTED_DID=$2

CLIENT_SECURITY_PROFILE="idsc:BASE_SECURITY_PROFILE"

CLIENT_CERT="keys/${CLIENT_NAME}.cert"

# if no cert exists yet, generate a new key and cert
if [ ! -f ${CLIENT_CERT} ]; then
    openssl req -newkey rsa:2048 -new -batch -nodes -x509 -days 3650 -text -keyout "keys/${CLIENT_NAME}.key" -out "${CLIENT_CERT}"
fi

# load subject/authority key identifiers from certificate and build client ID from it
SKI="$(grep -A1 "Subject Key Identifier"  "${CLIENT_CERT}" | tail -n 1 | tr -d ' ')"
AKI="$(grep -A1 "Authority Key Identifier"  "${CLIENT_CERT}" | tail -n 1 | tr -d ' ')"
CLIENT_ID="$SKI:$AKI"

# calculate sha256 fingerprint of client certificate
CLIENT_CERT_SHA="$(openssl x509 -in "${CLIENT_CERT}" -noout -sha256 -fingerprint | tr '[:upper:]' '[:lower:]' | tr -d : | sed 's/.*=//')"

# remove entry from yaml if it already exists
yq -i -y 'del(.[] | select(.client_id == "'"${CLIENT_ID}"'"))' config/clients.yml
# if no entries are left, remove the empty list as well
sed -i '/^\[\]/d' config/clients.yml

# build client entry
cat >> config/clients.yml <<EOF
- client_id: ${CLIENT_ID}
  client_name: ${CLIENT_NAME}
  grant_types: client_credentials
  token_endpoint_auth_method: private_key_jwt
  scope: idsc:IDS_CONNECTOR_ATTRIBUTES_ALL
  attributes:
  - key: idsc
    value: IDS_CONNECTOR_ATTRIBUTES_ALL
  - key: did
    value: ${ATTESTED_DID}
  - key: securityProfile
    value: ${CLIENT_SECURITY_PROFILE}
  - key: referringConnector
    value: http://${CLIENT_NAME}.demo
  - key: "@type"
    value: ids:DatPayload
  - key: "@context"
    value: https://w3id.org/idsa/contexts/context.jsonld
  - key: transportCertsSha256
    value: ${CLIENT_CERT_SHA}
EOF

# create clients dir if it does not exist yet and store certificate at the correct location
mkdir -p keys/clients
cp "${CLIENT_CERT}" keys/clients/${CLIENT_ID}.cert

# echo client id for use with plugin
echo ${CLIENT_ID}
