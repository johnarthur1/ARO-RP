#!/bin/bash -e

# ssh-agent.sh is intended to behave very similarly to ssh: specify the master or
# worker hostname that you want to connect to, along with any other ssh options
# you want to pass in

usage() {
    echo "usage: $0 hostname_pattern" >&2
    echo "       Examples: $0 master1" >&2
    echo "                 $0 bootstrap" >&2
    exit 1
}


if [[ "$#" -ne 1 ]]; then
   usage
fi

cleanup() {
    rm -rf id_rsa
}

trap cleanup EXIT

eval "$(ssh-agent | grep -v '^echo ')"

if [[ -z "$RESOURCEID" ]]; then
    RESOURCEID="/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RESOURCEGROUP}/providers/Microsoft.RedHatOpenShift/openShiftClusters/${CLUSTER}"
fi

CLUSTER_RESOURCEGROUP=$(go run ./hack/db "$RESOURCEID" | jq -r .openShiftCluster.properties.clusterProfile.resourceGroupId | cut -d/ -f5)

go run ./hack/db "$RESOURCEID" | jq -r .openShiftCluster.properties.sshKey | base64 -d | openssl rsa -inform der -outform pem >id_rsa 2>/dev/null
chmod 0600 id_rsa

IP=$(az network nic list -g "$CLUSTER_RESOURCEGROUP" --query "[? contains(name, '$1')].ipConfigurations[0].privateIpAddress" -o tsv)

if [[ $(grep -c . <<<"$IP") -ne 1 ]]; then
     echo -e "VM with pattern $1 not found in resourceGroup $CLUSTER_RESOURCEGROUP\n"
     usage
fi

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i id_rsa -l core "$IP"
