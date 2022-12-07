#!/bin/bash


echo "Adding Collection to Metabase"

collection_response=$(curl -s -w "%{http_code}" -X POST \
    -H "Content-type: application/json" \
    -H "X-Metabase-Session: ${MB_TOKEN}" \
    http://${MB_HOST}:${MB_PORT}/api/collection \
    -d '{
        "name": "Bahmni Analytics",
        "color": "#DDDDDD"
}')

echo "Bahmni Collection added to Metabase"

STATUS=${collection_response: -3}

if [ $STATUS == 200 ]
then
    COLLECTION_ID=$(jq -s '.[0].id' <<< ${collection_response})
    echo "Adding Registerd Patient Report to Metabase "

    curl -s -X POST \
    -H "Content-type: application/json" \
    -H "X-Metabase-Session: ${MB_TOKEN}" \
    http://${MB_HOST}:${MB_PORT}/api/card \
    -d '{
        "name": "Registered Patients Report",
        "collection_id": '${COLLECTION_ID}',
        "dataset_query":{"type": "native","database": '${DATABASE_ID}',"native":{
        "query":"SELECT DISTINCT (@rownum := @rownum + 1) AS \"Sr. No.\", IF(extraIdentifier.identifier IS NULL OR extraIdentifier.identifier = \"\", primaryIdentifier.identifier, extraIdentifier.identifier) AS \"Patient Id\", concat(pn.given_name, \" \", ifnull(pn.family_name, \"\")) AS \"Patient Name\", floor(DATEDIFF(NOW(), p.birthdate) / 365) AS \"Age\",  p.gender AS \"Gender\", DATE_FORMAT(CONVERT_TZ(pt.date_created,\"+00:00\",\"+5:30\"), \"%d-%b-%Y\") AS \"Registration Date\"FROM patient pt JOIN person p ON p.person_id = pt.patient_id AND p.voided is FALSE JOIN person_name pn ON pn.person_id = p.person_id AND pn.voided is FALSE JOIN (SELECT pri.patient_id, pri.identifier FROM patient_identifier pri JOIN patient_identifier_type pit ON pri.identifier_type = pit.patient_identifier_type_id AND pit.retired is FALSE JOIN global_property gp ON gp.property=\"bahmni.primaryIdentifierType\" AND INSTR (gp.property_value, pit.uuid)) primaryIdentifier ON pt.patient_id = primaryIdentifier.patient_id LEFT OUTER JOIN (SELECT ei.patient_id, ei.identifier FROM patient_identifier ei JOIN patient_identifier_type pit ON ei.identifier_type = pit.patient_identifier_type_id AND pit.retired is FALSE JOIN global_property gp ON gp.property=\"bahmni.extraPatientIdentifierTypes\" AND INSTR (gp.property_value, pit.uuid)) extraIdentifier ON pt.patient_id = extraIdentifier.patient_id CROSS JOIN (SELECT @rownum := 0) AS dummy WHERE pt.voided is FALSE AND cast(CONVERT_TZ(pt.date_created,\"+00:00\",\"+5:30\") AS DATE) BETWEEN STR_TO_DATE(\"04-05-2017\", \"%d-%m-%Y\") AND STR_TO_DATE(\"30-06-2017\", \"%d-%m-%Y\");"
        }},
        "display":"TABLE",
        "visualization_settings":{"table.pivot_column": "Gender", "table.cell_column": "Sr. No."}
    }'

    echo "Registerd Patient Report Added to Metabase "

    echo "Adding Clinic Visit Report to Metabase "

    curl -s -X POST \
    -H "Content-type: application/json" \
    -H "X-Metabase-Session: ${MB_TOKEN}" \
    http://${MB_HOST}:${MB_PORT}/api/card \
    -d '{
        "name": "Clinic Visit Report",
        "collection_id": '${COLLECTION_ID}',
        "dataset_query":{"type": "native","database": '${DATABASE_ID}',"native":{
        "query":"SELECT DISTINCT(pi.identifier) AS \"Patient Identifier\",  concat(pn.given_name, \" \", ifnull(pn.family_name, \"\")) AS \"Patient Name\",  floor(DATEDIFF(DATE(v.date_started), p.birthdate) / 365)  AS \"Age\",  DATE_FORMAT(p.birthdate, \"%d-%b-%Y\") AS \"Birthdate\", p.gender AS \"Gender\",  DATE_FORMAT(CONVERT_TZ(p.date_created,\"+00:00\",\"+5:30\"), \"%d-%b-%Y\") AS \"Patient Created Date\",  vt.name AS \"Visit type\",  DATE_FORMAT(CONVERT_TZ(v.date_started,\"+00:00\",\"+5:30\"), \"%d-%b-%Y\") AS \"Date started\", DATE_FORMAT(CONVERT_TZ(v.date_stopped,\"+00:00\",\"+5:30\"), \"%d-%b-%Y\") AS \"Date stopped\", GROUP_CONCAT(DISTINCT(IF(pat.name = \"phoneNumber\",pa.value, NULL))) AS \"Phone number\", paddress.city_village AS \"City/Village\",  paddress.state_province AS \"State\", CASE WHEN v.date_stopped IS NULL THEN \"Active\"  ELSE \"Inactive\"  END AS \"Visit Status\"FROM visit v  JOIN visit_type vt ON v.visit_type_id = vt.visit_type_id  JOIN person p ON p.person_id = v.patient_id AND p.voided is FALSE JOIN patient_identifier pi ON p.person_id = pi.patient_id AND pi.voided is FALSE  JOIN patient_identifier_type pit ON pi.identifier_type = pit.patient_identifier_type_id AND pit.retired is FALSE\n  JOIN person_name pn ON pn.person_id = p.person_id AND pn.voided is FALSE\n  LEFT OUTER JOIN person_address paddress ON p.person_id = paddress.person_id AND paddress.voided is FALSE\n  LEFT OUTER JOIN person_attribute pa ON pa.person_id = p.person_id AND pa.voided is FALSE\n  LEFT OUTER JOIN person_attribute_type pat ON pat.person_attribute_type_id = pa.person_attribute_type_id AND pat.retired is FALSE  WHERE v.voided is FALSE  AND cast(CONVERT_TZ(v.date_started,\"+00:00\",\"+5:30\") AS DATE) BETWEEN STR_TO_DATE(\"04-05-2017\", \"%d-%m-%Y\") AND STR_TO_DATE(\"30-06-2017\", \"%d-%m-%Y\")GROUP BY v.visit_id;"
        }},
        "display":"TABLE",
        "visualization_settings":{"table.pivot_column": "Visit type", "table.cell_column": "Age"}
    }'

    echo "Clinic Visit Report Added to Metabase "

else
    echo $collection_response
fi


echo "Bahmni Reports added to Metabase"
