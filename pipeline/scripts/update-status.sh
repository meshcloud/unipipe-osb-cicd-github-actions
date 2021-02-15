#!/bin/bash

# Exit on all errors and undefined vars
set -o errexit
set -o errtrace
set -o pipefail
set -o nounset
set -x

doc() {
    cat <<-EOF
Should be invoked from parent directory of the instances repository.
Alternativley using absolute paths also allows execution of this script from any dir.

USAGE:
    ./unipipe-osb-demo-cicd/pipeline/scripts/update-status.sh <instance-folder> <status> <status-description>

EXAMPLES:
    ./unipipe-osb-demo-cicd/pipeline/scripts/update-status.sh "example-osb-repo/instances/MY-ID-123" "in progress" "deploying service"

EOF
}

main(){
  INSTANCES_ROOT="$1"
  STATUS="$2"
  DESCRIPTION="$3"
  if [[ -e "$INSTANCES_ROOT/status.yml" ]]; then
    rm "$INSTANCES_ROOT/status.yml"
  fi
  cat >"$INSTANCES_ROOT/status.yml" <<EOL
status: "$STATUS"
description: "$DESCRIPTION"
EOL
}

if [[ $# == 3 ]]; then
    main "$@"
else
    doc
    exit 1;
fi