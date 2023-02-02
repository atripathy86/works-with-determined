#!/bin/bash

PROJECT_ID="hpe-labs-ai"
NAME="det-pach-seldon"
GPU_TYPE="nvidia-tesla-k80"
GPUS_PER_NODE="4"
MAX_NODES="4"

# Other constants

CLUSTER="cluster"
ZONE="us-central1-a"
REGION="us-central1"
BUCKET="checkpoint"
CLUSTER_NAME="${NAME}-${CLUSTER}"
BUCKET_NAME="${NAME}-${BUCKET}"
CLUSTER_VERSION="1.24.5-gke.600"


gcloud config set project ${PROJECT_ID}
GCP_ZONE="us-central1-a"
gcloud config set compute/zone ${GCP_ZONE}
gcloud config set container/cluster ${CLUSTER_NAME}
MACHINE_TYPE="n1-standard-16"
NUM_NODES=3

GSA_NAME="${NAME}-sa"
#Cloud SQL Instance DB
INSTANCE_NAME="${NAME}-db"
INSTANCE_ROOT_PASSWORD="Pachyderm1!"



echo "Removing Bucket ${BUCKET_NAME}"

# Remove GCS buckets to store checkpoints.
gsutil rm -r gs://${BUCKET_NAME}
# Remove Bucket for Pachyderm data
#gsutil rm -r gs://${NAME}-data
#Create Bucket for Seldon Drift/Outlier Data
#gsutil rm -r gs://${NAME}-detector

echo "Removing service-accounts ${GSA_NAME}"
SERVICE_ACCOUNT="${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
gcloud iam service-accounts delete ${SERVICE_ACCOUNT}

echo "Removing CloudSQL instance ${INSTANCE_NAME}"
gcloud sql instances delete ${INSTANCE_NAME}

echo "Deleting cluster : ${CLUSTER_NAME}"

gcloud container clusters delete ${CLUSTER_NAME} \
	        --project ${PROJECT_ID} \
	        --zone ${GCP_ZONE}
