#!/bin/bash
# Script to retrieve list of GCP assets having IAM policy

echo "Process started to retrieve GCP assets having IAM policy"

if [ -f AssetsIAMList.csv ]
then
        rm -f AssetsIAMList.csv
fi

if [ -f AssetsIAMList ]
then
        rm -f AssetsIAMList
fi

echo "Project List:-"
echo "`gcloud projects list --format="value(projectId)"`"

for project in $(gcloud projects list --format="value(projectId)")
do
           gcloud asset list --project $project --content-type='iam-policy' --flatten="iamPolicy.bindings[].members" --format="csv(assetType.flatten(),name.flatten(),updateTime.flatten().date(%Y-%m-%d %H:%M:%S),iamPolicy.bindings.members.split(':').flatten(),iamPolicy.bindings.role.split('roles/').slice(1:).flatten())"|uniq|sed 's/"//g'|sed "2,$ s/^/${project},/" >> AssetsIAMList
done

sed '/asset_type,name,update_time,members,role/{2,$d}' AssetsIAMList|sed "2,$ s/$/,$(date '+%Y-%m-%d %H:%M:%S')/"|sed "1 s/asset_type,name,update_time,members,role/project,asset_type,asset_name,update_time,member,member_name,role,loading_time/" |awk -F, -v OFS=, '{ if(NF==7) $5=$5","; print}' > AssetsIAMList.csv

record_count=`cat AssetsIAMList.csv| wc -l`
echo "Total record to be inserted: `expr ${record_count} - 1`"

#Loading into bigquery table
gcloud config set project my-project

date=$(date '+%Y-%m-%d')
BQ_TABLE='my-project.security_audit.assets_iam_list'

DELETE_QUERY="DELETE FROM "${BQ_TABLE}" WHERE EXTRACT(date from loading_time)='"${date}"'"
SELECT_QUERY="SELECT count(1) FROM "${BQ_TABLE}" WHERE EXTRACT(date from loading_time)='"${date}"'"

QUERY_RESULT=`bq query --use_legacy_sql=false ${SELECT_QUERY}`
COUNT=`echo $QUERY_RESULT|awk -F"|" '{print $4}'`

if [ "${COUNT}" -gt "0" ]
then
        QUERY_RESULT=`bq query --use_legacy_sql=false ${DELETE_QUERY}`
        echo "Deleted record count: ${QUERY_RESULT}"
fi

BQ_TABLE='security_audit.assets_iam_list'
QUERY_RESULT=`bq load --source_format=CSV --skip_leading_rows=1 ${BQ_TABLE} ./AssetsIAMList.csv project:string,asset_type:string,asset_name:string,update_time:datetime,member:string,member_name:string,role:string,loading_time:datetime`

if [ "${QUERY_RESULT}" == "" ] ; then QUERY_RESULT="Success"; fi
echo "Loading Status: ${QUERY_RESULT}"

echo "***********Process completed to retrieve GCP assets having IAM policy***************
