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