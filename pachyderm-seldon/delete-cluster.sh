#!/bin/bash

PROJECT="hpe-labs-ai"
NAME="det-pach-seldon-gke"
GPU_TYPE="nvidia-tesla-k80"
GPUS_PER_NODE="4"
MAX_NODES="4"

# Other constants

CLUSTER="cluster"
ZONE="us-central1-a"
BUCKET="checkpoint"
CLUSTER_NAME="${NAME}-${CLUSTER}"
BUCKET_NAME="${NAME}-${BUCKET}"
CLUSTER_VERSION="1.24.5-gke.600"


# Remove DaemonSet that enables the GPUs.
kubectl delete -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/nvidia-driver-installer/cos/daemonset-preloaded.yaml

# Delete node pool. This will not launch any nodes immediately but will
# scale up and down as needed. If you change the GPU type or the number of
# GPUs per node, you may need to change the machine-type.

echo "Deleting nodepool"

gcloud container node-pools delete ${NAME}-gpu-node-pool \
  --cluster ${CLUSTER_NAME} \
  --zone ${ZONE} 
# Create the GKE cluster that will contain only a single non-GPU node.

echo "Deleting cluster : ${CLUSTER_NAME}"

gcloud container clusters delete ${CLUSTER_NAME} \
	--project ${PROJECT} \
	--zone ${ZONE}


# Remove GCS buckets to store checkpoints.
gsutil rm -r gs://${BUCKET_NAME}
# Remove Bucket for Pachyderm data
gsutil rm -r gs://${NAME}-data
#Create Bucket for Seldon Drift/Outlier Data 
gsutil rm -r gs://${NAME}-detector

