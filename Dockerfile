# Image containing Cloud SDK and GCP deps
FROM gcr.io/cloud-builders/gcloud

RUN apt-get update && apt-get install -y netcat

COPY ./retrieve_GCP_IAM_members.sh ./
COPY ./retrieve_GCP_API_enabled.sh ./
COPY ./retrieve_GCP_Assets.sh ./
COPY ./retrieve_GCP_Assets_IAM.sh ./
COPY ./security_audit_script.sh ./

ENTRYPOINT [ "/security_audit_script.sh" ]
