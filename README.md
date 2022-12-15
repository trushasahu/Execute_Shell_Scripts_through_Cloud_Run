# Execute_Shell_Scripts_through_Cloud_Run
Execute the shell scripts through cloud run and schedule the same through Cloud Scheduler


# GCP Security Audit

This project is about auditing the GCP security i.e. iam-policy access , unnecessary enabled services, assets list etc.

## Setup

- Create shell scripts for each category to pull the data.
```
    - retrieve_GCP_IAM_members.sh  :- Retrieve the list of IAM members with access of each project
    - retrieve_GCP_API_enabled.sh  :- Retrieve the list of GCP API enabled in each project
    - retrieve_GCP_Assets.sh       :- Retrieve the list of GCP assets created in each project
    - retrieve_GCP_Assets_IAM.sh   :- Retrieve the list of GCP assets created having IAM policy in each project
```
- Create another shell scripts to execute the above all shell scripts.
```
    - security_audit_script.sh  :- Executing all the above security audit scripts
```
- Create a **Dockerfile** to build one image to execute the above scripts through **CLOUD RUN**.
```
    - Dockerfile  :- Steps to install dependency, copy the scripts to image and execute the scripts inside the image
```
- Enable Cloud Build and Cloud Run in **my-project** project.
```
    gcloud services enable --project ${PROJECT_ID} \
        cloudbuild.googleapis.com \
        run.googleapis.com

    i.e. gcloud services enable --project my-project \
            cloudbuild.googleapis.com \
            run.googleapis.com
```
- Build the container (All the scripts and Dockerfile will be placed in same path before executing below command)
```
    gcloud beta builds submit \
        --project=${PROJECT_ID} \
        --region={REGION} \
        --tag=gcr.io/${PROJECT_ID}/{Any Name}

    i.e. gcloud beta builds submit \
            --project=my-project \
            --region=europe-west2 \
            --tag=gcr.io/my-project/sec-audit
```
- Create one Service account (my-project@gserviceaccount.com) which will having below access to each project to list down all the details
```
    - roles/viewer
    - roles/cloudasset.viewer
```
- Deploy the container in Cloud Run
    - Note: User who will execute this command should have owner access in that project 
```
    gcloud beta run deploy {service name} \
        --project=${PROJECT_ID} \
        --platform=managed \
        --region={Region} \
        --image={image name created as tag in above build step} \
        --service-account={service account name}
        --allow-unauthenticated

    i.e. gcloud beta run deploy security-audit \
            --project=my-project \
            --platform=managed \
            --region=europe-west2  \
            --image=gcr.io/my-project/sec-audit:latest \
            --service-account=my-project@gserviceaccount.com \
            --allow-unauthenticated
```
- Schedule the created above cloud run service by Cloud Scheduler

- The data will be load into the **BigQuery** table post executed the above process. Please find the below details.
```
Dataset : my-project.security_audit
Tables  : - iam_member_list
          - enabled_api_list
          - assets_list
          - assets_iam_list
```
