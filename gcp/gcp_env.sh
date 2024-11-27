#!/bin/bash

# Variables
REGION="us-central1"
ZONE="us-central1-a"
PROJECT_ID=""

# Data-plane VPC and subnet
if ! gcloud compute networks describe data-plane-vpc &> /dev/null; then
  gcloud compute networks create data-plane-vpc \
    --bgp-routing-mode=regional \
    --mtu=1460 \
    --subnet-mode=custom \
    --project=$PROJECT_ID
fi

if ! gcloud compute networks subnets describe data-plane-subnet --region=$REGION --project=$PROJECT_ID &> /dev/null; then
  gcloud compute networks subnets create data-plane-subnet \
    --network=data-plane-vpc \
    --range=192.168.1.0/24 \
    --region=$REGION \
    --project=$PROJECT_ID
fi

# Control-plane VPC and subnet
if ! gcloud compute networks describe control-plane-vpc &> /dev/null; then
  gcloud compute networks create control-plane-vpc \
    --bgp-routing-mode=regional \
    --mtu=1460 \
    --subnet-mode=custom \
    --project=$PROJECT_ID
fi

if ! gcloud compute networks subnets describe control-plane-subnet --region=$REGION --project=$PROJECT_ID &> /dev/null; then
  gcloud compute networks subnets create control-plane-subnet \
    --network=control-plane-vpc \
    --range=192.168.2.0/24 \
    --region=$REGION \
    --project=$PROJECT_ID
fi


# Create VM1 with network interfaces in both VPCs
if ! gcloud compute instances describe vm1 &> /dev/null; then
  gcloud compute instances create vm1 \
    --image-family=ubuntu-2004-lts \
    --image-project=ubuntu-os-cloud \
    --machine-type=c2-standard-60 \
    --network-interface=network=control-plane-vpc,subnet=control-plane-subnet,nic-type=GVNIC \
    --network-interface=network=data-plane-vpc,subnet=data-plane-subnet,nic-type=GVNIC \
    --network-performance-configs=total-egress-bandwidth-tier=TIER_1 \
    --zone=$ZONE \
    --project=$PROJECT_ID \
     --metadata-from-file=startup-script=startup.sh
fi

# Create VM2 with network interfaces in both VPCs
if ! gcloud compute instances describe vm2 &> /dev/null; then
  gcloud compute instances create vm2 \
    --image-family=ubuntu-2004-lts \
    --image-project=ubuntu-os-cloud \
    --machine-type=c2-standard-60 \
    --network-interface=network=control-plane-vpc,subnet=control-plane-subnet,nic-type=GVNIC \
    --network-interface=network=data-plane-vpc,subnet=data-plane-subnet,nic-type=GVNIC \
    --network-performance-configs=total-egress-bandwidth-tier=TIER_1 \
    --zone=$ZONE \
    --project=$PROJECT_ID \
    --metadata-from-file=startup-script=startup.sh
fi

# Create firewall rule for SSH access
if ! gcloud compute firewall-rules describe allowssh-control --project=$PROJECT_ID &> /dev/null; then
  gcloud compute firewall-rules create allowssh-control \
    --action=allow \
    --network=control-plane-vpc \
    --rules=tcp:22 \
    --project=$PROJECT_ID
fi
