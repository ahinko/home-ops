#!/bin/sh

AUTHORIZED_KEYS=/root/.ssh/authorized_keys

KEYS_RC=-1
COUNT=0
while [ ${KEYS_RC} -ne 0 ] && [ ${COUNT} -lt 60 ]
do
    KEYS_DATA=$(podman exec unifi-os mongo --port 27117 --eval 'db.setting.find({key: {$eq: "mgmt"}}, {x_ssh_keys: 1, _id: 0});' --quiet ace)
    KEYS_RC=$?
    COUNT=$(( COUNT+1 ))
    [ ${KEYS_RC} -ne 0 ] && [ ${COUNT} -lt 60 ] && sleep 10
done

if [ ${KEYS_RC} -ne 0 ]
then
    echo "Failed to load keys from config"
else
    echo "${KEYS_DATA}" \
        | sed 's/\"date\" : ISODate\(.*\),//' \
        | jq -r '.x_ssh_keys | map([.type, .key, .comment] | join(" ")) | join("\n")' \
        | while IFS= read -r KEY
    do
        if ! grep -Fxq "${KEY}" "${AUTHORIZED_KEYS}"
        then
            echo "${KEY}" >> "${AUTHORIZED_KEYS}"
        fi
    done
fi
