#!/bin/bash

# Exit on all errors and undefined vars
set -o errexit
set -o errtrace
set -o pipefail
set -o nounset
set -x

doc() {
    cat <<-EOF
Deploys service instances via terraform. Should be invoked from parent directory of unipipe-osb-demo-cicd and
the instances repository. Alternativley using absolute paths also allows execution of this script from any dir.

The create-tfvars.sh scripts must have been executed before. The deployment
uses the created instance.tfvars file for the deployment via terraform.

USAGE:
    ./unipipe-osb-demo-cicd/pipeline/scripts/deploy.sh <ci-repository> <instances-repository>

EXAMPLES:
    ./unipipe-osb-demo-cicd/pipeline/scripts/deploy.sh unipipe-osb-demo-cicd example-osb-repo

EOF
}

executeTerraformApply() {
  terraform init
  terraform apply -var-file=instance.tfvars -auto-approve
}

executeTerraformDestroy() {
  terraform init
  terraform destroy -var-file=instance.tfvars -auto-approve
}

main(){
  CI_ROOT="$1"
  INSTANCES_ROOT="$2"
  anyFailed=false
  for dir in $INSTANCES_ROOT/instances/*
  do
    if [[ ! -e "$dir/instance.tfvars" ]]; then
      continue
    fi
    echo "Deploying $dir"
    cp "$CI_ROOT/terraform/example-sb.tf" "$dir"

    cd $dir
    isDeleted="$(grep 'deleted:' instance.yml | cut -d\  -f2-)"

    if [[ -e "status.yml" ]]; then
      initialStatus="$(grep 'status:' status.yml | cut -d\  -f2-)"
    else
      initialStatus="\"in progress\""
    fi

    if [[ "$initialStatus" == "\"in progress\"" ]]; then
      if [[ "$isDeleted" == "true" ]]; then
        if executeTerraformDestroy; then
          status="succeeded"
          description=""
        else
          status="failed"
          description="Deprovisioning failed! Please contact an administrator."
          echo "--- Deprovisioning of '$dir' failed! ---"
          anyFailed="true"
        fi
      else
        if executeTerraformApply; then
          host="$(terraform output public_ip)"
          if [[ ! -z "${host}" ]] ; then
            status="succeeded"
            description=""
          else
            status="failed"
            description="Configuration of instance failed! Please contact an administrator."
            echo "--- Configuration of instance of '$dir' failed! ---"
            anyFailed="true"
          fi
        else
          status="failed"
          description="Provisioning failed! Please contact an administrator."
          echo "--- Provisioning of '$dir' failed! ---"
          anyFailed="true"
        fi
      fi
    fi

    rm -f example-sb.tf
    cd -

    if [[ -n "${status-}" ]]; then
      ./$CI_ROOT/pipeline/scripts/update-status.sh "$dir" "$status" "$description"
    fi
  done

  if [[ $anyFailed == "true" ]]; then
    echo "!!! At least one provisiong failed! Check this log for details! !!!"
    exit 1
  fi
}

if [[ $# == 2 ]]; then
    main "$@"
else
    doc
    exit 1;
fi