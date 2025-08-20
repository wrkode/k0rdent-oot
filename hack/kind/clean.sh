#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

set +x

KIND_CLUSTERS=$(kind get clusters)

if [ -n "$KIND_CLUSTERS" ]; then
  echo "Deleting kind clusters: $KIND_CLUSTERS"
  for cluster in $KIND_CLUSTERS; do
    kind delete cluster --name "$cluster"
  done
else
  echo "No kind clusters found"
fi

echo "Stopping all docker containers"
RUNNING_CONTAINERS=$(docker ps -q)
if [ -n "$RUNNING_CONTAINERS" ]; then
  docker stop $RUNNING_CONTAINERS
else
  echo "No running containers found"
fi

echo "Cleaning docker system"
docker system prune -a -f
