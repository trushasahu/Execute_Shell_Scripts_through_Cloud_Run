#!/bin/bash
# Script to retrieve GCP IAM members

echo "Process started to retrieve GCP IAM members"

if [ -f iamMemberList.csv ]
then
        rm -f iamMemberList.csv
fi

if [ -f iamMemberList ]
then
        rm -f iamMemberList
fi

echo "Project List:-"
echo "`gcloud projects list --format="value(projectId)"`"

for project in $(gcloud projects list --format="value(projectId)")
do
        gcloud projects get-iam-policy $project --flatten="bindings[].members" --format="csv(bindings.members.split(':').flatten(),bindings.role.split('roles/').slice(1:).flatten())"|uniq|sed 's/"//g'|sed "2,$ s/^/${project},/" >> iamMemberList
done

sed '/members,role/{2,$d}' iamMemberList|sed "2,$ s/$/,$(date '+%Y-%m-%d %H:%M:%S')/"|sed "1 s/members,role/project,member_type,member_id,role,loading_time/" > iamMemberList.csv

#echo "----Printing iamMemberList.csv data-----"
#chmod 755 iamMemberList.csv
#while read -r line; do
#    echo -e "$line\n"
#done <iamMemberList.csv
#echo "----Ending printing of iamMemberList.csv data-----"
record_count=`cat iamMemberList.csv| wc -l`
echo "Total record to be inserted: `expr ${record_count} - 1`"

#Loading into bigquery table
gcloud config set project my-project

date=$(date '+%Y-%m-%d')
BQ_TABLE='my-project.security_audit.iam_member_list'

DELETE_QUERY="DELETE FROM "${BQ_TABLE}" WHERE EXTRACT(date from loading_time)='"${date}"'"
SELECT_QUERY="SELECT count(1) FROM "${BQ_TABLE}" WHERE EXTRACT(date from loading_time)='"${date}"'"

QUERY_RESULT=`bq query --use_legacy_sql=false ${SELECT_QUERY}`
COUNT=`echo $QUERY_RESULT|awk -F"|" '{print $4}'`

if [ "${COUNT}" -gt "0" ]
then
        QUERY_RESULT=`bq query --use_legacy_sql=false ${DELETE_QUERY}`
        echo "Deleted record count: ${QUERY_RESULT}"
fi

BQ_TABLE='security_audit.iam_member_list'
QUERY_RESULT=`bq load --source_format=CSV --skip_leading_rows=1 ${BQ_TABLE} ./iamMemberList.csv project:string,member_type:string,member_id:string,role:string,loading_time:datetime`

if [ "${QUERY_RESULT}" == "" ] ; then QUERY_RESULT="Success"; fi
echo "Loading Status: ${QUERY_RESULT}"

echo "***********Process completed to retrieve GCP IAM members***************"
