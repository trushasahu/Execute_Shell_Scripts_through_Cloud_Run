#!/bin/bash
# execute list of security audit scripts

echo "=================Started executing all security audit scripts===================="

./retrieve_GCP_IAM_members.sh

./retrieve_GCP_API_enabled.sh

./retrieve_GCP_Assets.sh

./retrieve_GCP_Assets_IAM.sh

PORT="${PORT:-8080}"
echo "Listening on ${PORT}..."
nc -l "${PORT}" > log.txt

echo "==================Completed executing all security audit scripts===================="
