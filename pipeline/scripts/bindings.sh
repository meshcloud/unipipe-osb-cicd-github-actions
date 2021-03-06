#!/bin/bash

# Exit on all errors and undefined vars
set -o errexit
set -o errtrace
set -o pipefail
set -o nounset

doc() {
    cat <<-EOF
Creates and deletes Service Bindings. Should be invoked from parent directory of unipipe-osb-demo-cicd and
the instances repository. Alternativley using absolute paths also allows execution of this script from any dir.

The create-tfvars.sh and deploy.sh scripts must have been executed before. The deployment
uses the created instance.tfvars file. It creates the binding in the instance created via deploy.sh.

USAGE:
    ./unipipe-osb-demo-cicd/pipeline/scripts/bindings.sh <ci-repository> <instances-repository>

EXAMPLES:
    ./unipipe-osb-demo-cicd/pipeline/scripts/bindings.sh unipipe-osb-demo-cicd example-osb-repo

EOF
}


main(){
  CI_ROOT="$1"
  INSTANCES_ROOT="$2"
  anyFailed=false
  
  for dir in $INSTANCES_ROOT/instances/*/bindings/*
  do
    echo "Work on binding $dir"
    cp "$CI_ROOT/terraform/example-sb.tf" "$dir/../.."
    oldDir="$(pwd)"
    cd $dir

    isDeleted="$(grep 'deleted:' binding.yml | cut -d\  -f2-)"

    if [[ -e "status.yml" ]]; then
      initialStatus="$(grep 'status:' status.yml | cut -d\  -f2-)"
    else
      initialStatus="\"in progress\""
    fi

    if [[ "$initialStatus" == "\"in progress\"" ]]; then
      echo "Processing 'in progress' binding"
      cd ../..
      terraform init
      host="$(terraform output public_ip)"
      cd -
      if [[ "$isDeleted" == "true" ]]; then
        echo "Processing deleted binding"
        if [[ -e "credentials.yml" ]]; then
          host_ip="$(grep 'host_ip:' credentials.yml | cut -d\  -f2-)"
        fi
        if [[ ! -z "${host_ip-}" ]]; then
          rm -f credentials.yml
          echo "Delete instance binding at ${host_ip} successfully"
          status="succeeded"
          description=""
        else
          status="failed"
          description="Delete Binding failed! Please contact an administrator."
          echo "--- Delete Binding of '$dir' failed! ---"
          anyFailed="true"
        fi
        
      else
        echo "Creating new binding"
        if [[ -e "credentials.yml" ]]; then
          rm "credentials.yml"
        fi
        if [[ ! -z "$host" ]]; then
          echo "Create EC2 intance at ${host} executed successfully"
          cat >"credentials.yml" <<EOL
host_ip: ${host}
port: "8080"
EOL
          status="succeeded"
          description=""
        else
          status="failed"
          description="Create Binding failed! Please contact an administrator."
          echo "--- Create Binding of '$dir' failed! ---"
          anyFailed="true"
        fi
      fi
    fi

    rm -f ../../example-sb.tf
    cd ${oldDir}

    if [[ -n "${status-}" ]]; then
      ./$CI_ROOT/pipeline/scripts/update-status.sh "$dir" "$status" "$description"
    fi
  done

  if [[ $anyFailed == "true" ]]; then
    echo "!!! At least one binding failed! Check this log for details! !!!"
    exit 1
  fi
}

if [[ $# == 2 ]]; then
    main "$@"
else
    doc
    exit 1;
fi
