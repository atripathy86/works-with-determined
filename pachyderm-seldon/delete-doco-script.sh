#!/bin/bash


# PLEASE CHANGE THESE NEXT 3 VARIABLES AT A MINIMUM
PROJECT_ID="hpe-labs-ai"
NAME="det-pach-seldon-doco"
SQL_ADMIN_PASSWORD="Pachyderm1!"

# This group of variables can be changed, but are sane defaults
GCP_REGION="us-central1"
GCP_ZONE="us-central1-a"
K8S_NAMESPACE="default"
CLUSTER_MACHINE_TYPE="n1-standard-4"
SQL_CPU="2"
SQL_MEM="7680MB"

# The following variables probably shouldn't be changed
CLUSTER_NAME="${NAME}-gke"
BUCKET_NAME="${NAME}-gcs"
LOKI_BUCKET_NAME="${NAME}-logs-gcs"
CLOUDSQL_INSTANCE_NAME="${NAME}-sql"
GSA_NAME="${NAME}-gsa"
LOKI_GSA_NAME="${NAME}-loki-gsa"
STATIC_IP_NAME="${NAME}-ip"

ROLE1="roles/cloudsql.client"
ROLE2="roles/storage.admin"

SERVICE_ACCOUNT="${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
LOKI_SERVICE_ACCOUNT="${LOKI_GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
PACH_WI="serviceAccount:${PROJECT_ID}.svc.id.goog[${K8S_NAMESPACE}/pachyderm]"
SIDECAR_WI="serviceAccount:${PROJECT_ID}.svc.id.goog[${K8S_NAMESPACE}/pachyderm-worker]"
CLOUDSQLAUTHPROXY_WI="serviceAccount:${PROJECT_ID}.svc.id.goog[${K8S_NAMESPACE}/k8s-cloudsql-auth-proxy]"


#GPU_TYPE="nvidia-tesla-k80"
#GPUS_PER_NODE="4"
#MAX_NODES="4"
#CLUSTER_VERSION="1.24.5-gke.600"

echo "Removing Bucket ${BUCKET_NAME}, ${LOKI_BUCKET_NAME}, ${NAME}-data, ${NAME}-detector"

# Remove GCS buckets to store checkpoints.
gsutil -q rm -r gs://${BUCKET_NAME}
gsutil -q rm -r gs://${LOKI_BUCKET_NAME}
gsutil -q rm -r gs://${NAME}-data
gsutil -q rm -r gs://${NAME}-detector
# Remove Bucket for Pachyderm data
#gsutil rm -r gs://${NAME}-data
#Create Bucket for Seldon Drift/Outlier Data
#gsutil rm -r gs://${NAME}-detector

echo "Removing service-accounts ${GSA_NAME}"
gcloud iam service-accounts delete ${SERVICE_ACCOUNT} -q

echo "Removing Loki service-accounts ${LOKI_GSA_NAME}"
gcloud iam service-accounts delete ${LOKI_SERVICE_ACCOUNT} -q

echo "Removing CloudSQL instance ${CLOUDSQL_INSTANCE_NAME}"
gcloud sql instances delete ${CLOUDSQL_INSTANCE_NAME} -q

echo "Removing Static IP Name ${STATIC_IP_NAME} in $GCP_REGION"
gcloud compute addresses delete ${STATIC_IP_NAME} --region=${GCP_REGION} -q

#echo "Removing Nodepool: ${NAME}-gpu-node-pool"
#gcloud container node-pools delete ${NAME}-gpu-node-pool \
#  --cluster ${CLUSTER_NAME} \
#  -- zone ${GCP_ZONE}

echo "Deleting cluster : ${CLUSTER_NAME}"

gcloud container clusters delete -q ${CLUSTER_NAME} \
	        --project ${PROJECT_ID} \
	        --zone ${GCP_ZONE}
