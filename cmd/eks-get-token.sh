#!/bin/bash
aws eks get-token --region=eu-north-1 --cluster=k8s-workshop --profile=workshop | jq .
