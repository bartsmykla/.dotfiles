#!/usr/bin/env bash

export CHARLES_VAR_NAMES=(
    HTTP_PROXY
    HTTPS_PROXY
    FTP_PROXY
    RSYNC_PROXY
    http_proxy
    https_proxy
    ftp_proxy
    rsync_proxy
)

# Function which will set few env vars which some apps can use
# with address of the charles proxy
# Globals:
#   CHARLES_VAR_NAMES
# Arguments:
#   $1:  charles proxy address (default: http://localhost:8888)
#   $2+: variable names
# Example usage:
#   charles
#   charles http://some/path:8080
charles() {
    local proxy="${1:=http://localhost:8888}"

    if [ $# -lt 2 ]; then
        set -- "${CHARLES_VAR_NAMES[@]}"
    fi

    echo "Setting Charles Proxy env vars"

    for name in "$@"; do
        echo "    exporting ${name}='${proxy}'"
        export "${name}=${proxy}"
    done
}

# Function to unset charles-related env vars
# Globals:
#   CHARLES_VAR_NAMES
# Arguments:
#   None
# Example usage:
#   uncharles
uncharles() {
    echo "Unsetting Charles Proxy env vars"

    for name in "${CHARLES_VAR_NAMES[@]}"; do
        echo "    unsetting ${name}"
        unset "${name}"
    done
}
