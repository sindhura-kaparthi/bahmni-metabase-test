#!/bin/bash

echo "Creating admin user"

SETUP_TOKEN=$(curl -s -m 5 -X GET \
    -H "Content-Type: application/json" \
    http://${MB_HOST}:${MB_PORT}/api/session/properties \
    | jq -r '.["setup-token"]'
)

if [ ! -z $SETUP_TOKEN ]
then
    create_admin_response=$(curl -s -w "%{http_code}" -X POST \
        -H "Content-type: application/json" \
        http://${MB_HOST}:${MB_PORT}/api/setup \
        -d '{
        "token": "'${SETUP_TOKEN}'",
        "user": {
            "email": "'${MB_ADMIN_EMAIL}'",
            "first_name": "'${MB_ADMIN_FIRST_NAME}'",
            "password": "'${MB_ADMIN_PASSWORD}'"
        },
        "prefs": {
            "allow_tracking": false,
            "site_name": "Bahmni Metabase"
        }
    }')

    STATUS=${create_admin_response: -3}
    if [ $STATUS == 200 ]
    then
        echo "\n Admin user created!"
        MB_TOKEN=$(jq -s -r '.[0].id' <<< ${create_admin_response})
        source /app/scripts/database/add_openmrs_db.sh
    fi
else
    echo 'SETUP_TOKEN not available , Admin user cannot be created'
fi