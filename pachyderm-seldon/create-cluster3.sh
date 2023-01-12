#!/bin/bash

PROJECT_ID="hpe-labs-ai"
NAME="det-pach-seldon2"
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


# Create the GKE cluster that will contain only a single non-GPU node.

echo "Creating cluster : ${CLUSTER_NAME}"

# By default the following command spins up a 3-node cluster. You can change the default with `--num-nodes VAL`.
gcloud container clusters create ${CLUSTER_NAME} \
 --machine-type=${MACHINE_TYPE} \
 --workload-pool=${PROJECT_ID}.svc.id.goog \
 --enable-ip-alias \
 --create-subnetwork="" \
 --enable-stackdriver-kubernetes \
 --enable-dataplane-v2 \
 --enable-shielded-nodes \
 --release-channel="regular" \
 --workload-metadata="GKE_METADATA" \
 --enable-autorepair \
 --enable-autoupgrade \
 --disk-type="pd-ssd" \
 --image-type="COS_CONTAINERD" 

#--scopes storage-rw

#gcloud container clusters create ${CLUSTER_NAME} \
#	--project ${PROJECT} \
#	--zone ${ZONE} \
#	--node-locations ${ZONE} \
#	--num-nodes "1" \
#	--no-enable-basic-auth \
#	--cluster-version ${CLUSTER_VERSION} \
#	--release-channel "regular" \
#	--machine-type "n1-standard-16" \
#	--image-type "COS_CONTAINERD" \
#	--disk-type "pd-standard" \
#	--disk-size "100" \
#	--metadata disable-legacy-endpoints=true \
#	--scopes "https://www.googleapis.com/auth/devstorage.full_control",\
#"https://www.googleapis.com/auth/logging.write",\
#"https://www.googleapis.com/auth/monitoring",\
#"https://www.googleapis.com/auth/servicecontrol",\
#"https://www.googleapis.com/auth/service.management.readonly",\
#"https://www.googleapis.com/auth/trace.append" \
	#--max-pods-per-node "110" \
	#--logging=SYSTEM,WORKLOAD \
#	--monitoring=SYSTEM \
	#--enable-ip-alias \
	#--network "projects/${PROJECT}/global/networks/default" \
	#--subnetwork "projects/${PROJECT}/regions/us-central1/subnetworks/default" \
	#--enable-intra-node-visibility \
#	--default-max-pods-per-node "110" \
#	--enable-dataplane-v2 \
	#--enable-master-authorized-networks \
	#--addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver \
#	--enable-autoupgrade \
#	--enable-autorepair \
#	--max-surge-upgrade 1 \
#	--max-unavailable-upgrade 0 \
#	--maintenance-window-start "2022-02-12T23:00:00Z" \
#	--maintenance-window-end "2022-02-13T07:00:00Z" \
#	--maintenance-window-recurrence "FREQ=WEEKLY;BYDAY=SA,SU" \
	#--enable-shielded-nodes \
	#--enable-private-nodes \
	#--enable-private-endpoint \
	#--master-ipv4-cidr "10.100.1.0/28" \
	#--enable-master-global-access \
	#--tags ${NAME}

# Create a node pool. This will not launch any nodes immediately but will
# scale up and down as needed. If you change the GPU type or the number of
# GPUs per node, you may need to change the machine-type.

#echo "Creating nodepool"

#gcloud container node-pools create ${NAME}-gpu-node-pool \
#  --cluster ${CLUSTER_NAME} \
#  --accelerator "type=${GPU_TYPE},count=${GPUS_PER_NODE}" \
#  --zone ${ZONE} \
#  --num-nodes=0 \
#  --enable-autoscaling \
#  --min-nodes=0 \
#  --max-nodes=${MAX_NODES} \
#  --machine-type=n1-standard-4 \
#  --scopes=storage-full,cloud-platform

# Deploy a DaemonSet that enables the GPUs.
#kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/nvidia-driver-installer/cos/daemonset-preloaded.yaml

# Create a GCS bucket to store checkpoints.
#gsutil mb gs://${BUCKET_NAME}
#Create Bucket for Pachyderm data
#gsutil mb -l us-central1 gs://${NAME}-data
#Create Bucket for Seldon Drift/Outlier Data 
#gsutil mb -l us-central1 gs://${NAME}-detector

# By default, GKE clusters have RBAC enabled. To allow the 'helm install' to give the 'pachyderm' service account
# the requisite privileges via clusterrolebindings, you will need to grant *your user account* the privileges
# needed to create those clusterrolebindings.
#
# Note that this command is simple and concise, but gives your user account more privileges than necessary. See
# https://docs.pachyderm.io/en/latest/deploy-manage/deploy/rbac/ for the complete list of privileges that the
# pachyderm serviceaccount needs.
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account)

# Update your kubeconfig to point at your newly created cluster.
gcloud container clusters get-credentials ${CLUSTER_NAME}

# List all pods in the kube-system namespace.
kubectl get pods -n kube-system

#2 Create GCS Bucket

#gsutil mb -l ${GCP_ZONE}  gs://${BUCKET_NAME} 
#gsutil mb -l ${REGION}  gs://${BUCKET_NAME} 
gsutil mb gs://${BUCKET_NAME} 

gsutil ls

#Setup Service Account
gcloud iam service-accounts create ${GSA_NAME}

SERVICE_ACCOUNT="${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
# "default" or the namespace in which your cluster was deployed
K8S_NAMESPACE="default" 
PACH_WI="serviceAccount:${PROJECT_ID}.svc.id.goog[${K8S_NAMESPACE}/pachyderm]"
SIDECAR_WI="serviceAccount:${PROJECT_ID}.svc.id.goog[${K8S_NAMESPACE}/pachyderm-worker]"
CLOUDSQLAUTHPROXY_WI="serviceAccount:${PROJECT_ID}.svc.id.goog[${K8S_NAMESPACE}/k8s-cloudsql-auth-proxy]"

# Grant access to cloudSQL to the Service Account
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role="roles/cloudsql.client"
# Grant access to storage (bucket + volumes) to the Service Account
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role="roles/storage.admin"

gcloud iam service-accounts add-iam-policy-binding ${SERVICE_ACCOUNT} \
    --role roles/iam.workloadIdentityUser \
    --member "${PACH_WI}"
gcloud iam service-accounts add-iam-policy-binding ${SERVICE_ACCOUNT} \
    --role roles/iam.workloadIdentityUser \
    --member "${SIDECAR_WI}"
gcloud iam service-accounts add-iam-policy-binding ${SERVICE_ACCOUNT} \
    --role roles/iam.workloadIdentityUser \
    --member "${CLOUDSQLAUTHPROXY_WI}"


#4 GCP Managed PostgresSQL Database 

gcloud sql instances create ${INSTANCE_NAME} \
--database-version=POSTGRES_13 \
--cpu=2 \
--memory=7680MB \
--zone=${GCP_ZONE} \
--availability-type=ZONAL \
--storage-size=50GB \
--storage-type=SSD \
--storage-auto-increase \
--root-password=${INSTANCE_ROOT_PASSWORD}

#Create pachyderm and dex databases on CloudSQL instance
gcloud sql databases create pachyderm -i ${INSTANCE_NAME}
gcloud sql databases create dex -i ${INSTANCE_NAME}

CLOUDSQL_CONNECTION_NAME=$(gcloud sql instances describe ${INSTANCE_NAME} --format=json | jq ."connectionName")
echo "CLOUDSQL_CONNECTION_NAME=$CLOUDSQL_CONNECTION_NAME"

echo "BUCKET_NAME=$BUCKET_NAME"
echo "SERVICE_ACCOUNT=$SERVICE_ACCOUNT"

echo "Ready to helm install..."


