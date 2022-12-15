#!/bin/bash
# Script to retrieve list of GCP assets

echo "Process started to retrieve GCP assets"

if [ -f AssetsList.csv ]
then
        rm -f AssetsList.csv
fi

if [ -f AssetsList ]
then
        rm -f AssetsList
fi

echo "Project List:-"
echo "`gcloud projects list --format="value(projectId)"`"

for project in $(gcloud projects list --format="value(projectId)")
do
           gcloud asset list --project $project --flatten="ancestors[]" --format="csv(assetType.flatten(),name.flatten(),updateTime.flatten().date(%Y-%m-%d %H:%M:%S))"|uniq|sed "2,$ s/^/$project,/" >> AssetsList
done

sed '/asset_type,name,update_time/{2,$d}' AssetsList|sed "2,$ s/$/,$(date '+%Y-%m-%d %H:%M:%S')/"|sed "1 s/asset_type,name,update_time/project,asset_type,asset_name,update_time,loading_time/" > AssetsList.csv

record_count=`cat AssetsList.csv| wc -l`
echo "Total record to be inserted: `expr ${record_count} - 1`"

#Loading into bigquery table
gcloud config set project my-project

date=$(date '+%Y-%m-%d')
BQ_TABLE='my-project.security_audit.assets_list'

DELETE_QUERY="DELETE FROM "${BQ_TABLE}" WHERE EXTRACT(date from loading_time)='"${date}"'"
SELECT_QUERY="SELECT count(1) FROM "${BQ_TABLE}" WHERE EXTRACT(date from loading_time)='"${date}"'"

QUERY_RESULT=`bq query --use_legacy_sql=false ${SELECT_QUERY}`
COUNT=`echo $QUERY_RESULT|awk -F"|" '{print $4}'`

if [ "${COUNT}" -gt "0" ]
then
        QUERY_RESULT=`bq query --use_legacy_sql=false ${DELETE_QUERY}`
        echo "Deleted record count: ${QUERY_RESULT}"
fi

BQ_TABLE='security_audit.assets_list'
QUERY_RESULT=`bq load --source_format=CSV --skip_leading_rows=1 ${BQ_TABLE} ./AssetsList.csv project:string,asset_type:string,asset_name:string,update_time:datetime,loading_time:datetime`

if [ "${QUERY_RESULT}" == "" ] ; then QUERY_RESULT="Success"; fi
echo "Loading Status: ${QUERY_RESULT}"

echo "***********Process completed to retrieve GCP assets***************"
