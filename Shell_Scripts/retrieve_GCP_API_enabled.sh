#!/bin/bash
# Script to retrieve list of GCP API/Services enabled

echo "Process started to retrieve GCP API enabled"

if [ -f EnabledAPIList.csv ]
then
        rm -f EnabledAPIList.csv
fi

if [ -f EnabledAPIList ]
then
        rm -f EnabledAPIList
fi

echo "Project List:-"
echo "`gcloud projects list --format="value(projectId)"`"

for project in $(gcloud projects list --format="value(projectId)")
do
       gcloud services list --enabled --project $project --format="csv(project, NAME, TITLE)" --sort-by=TITLE|uniq|sed "2,$ s/^/${project}/" >> EnabledAPIList
done

sed '/project,name,title/{2,$d}' EnabledAPIList|sed "2,$ s/$/,$(date '+%Y-%m-%d %H:%M:%S')/"|sed "1 s/project,name,title/project,name,title,loading_time/" > EnabledAPIList.csv

record_count=`cat EnabledAPIList.csv| wc -l`
echo "Total record to be inserted: `expr ${record_count} - 1`"

#Loading into bigquery table
gcloud config set project my-project

date=$(date '+%Y-%m-%d')
BQ_TABLE='my-project.security_audit.enabled_api_list'

DELETE_QUERY="DELETE FROM "${BQ_TABLE}" WHERE EXTRACT(date from loading_time)='"${date}"'"
SELECT_QUERY="SELECT count(1) FROM "${BQ_TABLE}" WHERE EXTRACT(date from loading_time)='"${date}"'"

QUERY_RESULT=`bq query --use_legacy_sql=false ${SELECT_QUERY}`
COUNT=`echo $QUERY_RESULT|awk -F"|" '{print $4}'`

if [ "${COUNT}" -gt "0" ]
then
        QUERY_RESULT=`bq query --use_legacy_sql=false ${DELETE_QUERY}`
        echo "Deleted record count: ${QUERY_RESULT}"
fi

BQ_TABLE='security_audit.enabled_api_list'
QUERY_RESULT=`bq load --source_format=CSV --skip_leading_rows=1 ${BQ_TABLE} ./EnabledAPIList.csv project:string,name:string,title:string,loading_time:datetime`

if [ "${QUERY_RESULT}" == "" ] ; then QUERY_RESULT="Success"; fi
echo "Loading Status: ${QUERY_RESULT}"

echo "***********Process completed to retrieve GCP API enabled***************"
