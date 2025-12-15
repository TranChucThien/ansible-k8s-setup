#!/bin/bash
# Script to run clean-cluster with timestamped logging

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="logs/clean-cluster-${TIMESTAMP}.log"

echo "Starting cluster cleanup at $(date)" | tee -a $LOG_FILE
ansible-playbook -i inventory playbooks/clean-cluster.yml 2>&1 | tee -a $LOG_FILE
echo "Cleanup completed at $(date)" | tee -a $LOG_FILE