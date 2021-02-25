#!/bin/bash

# Exit on all errors and undefined vars
set -o errexit
set -o errtrace
set -o pipefail
set -o nounset
set -x

doc() {
    cat <<-EOF
Translates the instance.yml to a tfvars file, that can be used by terraform for deployment.
Should be invoked from parent directory of unipipe-osb-demo-cicd and the instances repository.
Alternativley using absolute paths also allows execution of this script from any dir.

USAGE:
    ./unipipe-osb-demo-cicd/pipeline/scripts/create-tfvars.sh <ci-repository> <instances-repository> <small_flavor> <medium_flavor> 

EXAMPLES:
    ./unipipe-osb-demo-cicd/pipeline/scripts/create-tfvars.sh unipipe-osb-demo-cicd example-osb-repo t2.nano t2.micro

EOF
}

main(){
  CI_ROOT="$1"
  INSTANCES_ROOT="$2"
  SMALL_FLAVOR="$3"
  MEDIUM_FLAVOR="$4"

  for dir in $INSTANCES_ROOT/instances/*
  do
      echo "Generating tfvars for: $dir"
      plan_id="$(grep 'planId:' $dir/instance.yml | cut -d\  -f2-)"
      # deleted is also written to tfvars to trigger an update of the git resource used in deploy job
      username="$(grep 'username: ' $dir/instance.yml | cut -d\  -f4-)"
      isDeleted="$(grep 'deleted:' $dir/instance.yml | cut -d\  -f2-)"

      if [[ "$plan_id" == "\"b13edcdf-eb54-44d3-8902-8f24d5acb07e\"" ]]
      then
        flavor="$SMALL_FLAVOR"
      elif [[ "$plan_id" == "\"c387b010-c002-4eab-8902-3851694ef7ba\"" ]]
      then
        flavor="$MEDIUM_FLAVOR"
      else
        echo "plan $plan_id not found! I am just doing nothing!"
        ./$CI_ROOT/pipeline/scripts/update-status.sh "$dir" "succeeded" "just did nothing"
        continue
      fi

      if [[ -e "$dir/instance.tfvars" ]]; then
        rm "$dir/instance.tfvars"
      fi
      cat >"$dir/instance.tfvars" <<EOL
service_instance_id="${dir##*/}"
username=${username}
flavor="${flavor}"
server_port="8080"

EOL

      if [[ -e "$dir/status.yml" ]]; then
        last_status="$(grep 'status:' $dir/status.yml | cut -d\  -f2-)"
      else
        last_status="\"in progress\""
      fi
      if [[ $last_status == "\"in progress\"" ]]; then
        is_deleted="$(grep 'deleted:' $dir/instance.yml |  cut -d\  -f2-)"
        description="provisioning service"
        if [[ $is_deleted == "true" ]]; then
          description="deprovisioning service"
        fi
        ./$CI_ROOT/pipeline/scripts/update-status.sh "$dir" "in progress" "$description"
      fi
  done
}

if [[ $# == 4 ]]; then
    main "$@"
else
    doc
    exit 1;
fi
