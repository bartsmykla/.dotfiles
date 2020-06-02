#!/usr/bin/env bash

# TODO: Sometimes it happens when tmux is starting the ssh-add is called in
#       inactive window, so it would be good to write solution which would
#       switch to the pane where it was called if it happenes

get_ssh_hash() {
    local line;

    read -r line

    echo "${line}" | awk '{ print $2 }'
}

# Function which is checking in ssh agent if our main identity is there
# present and if not or if its fingerprint doesn't match adding it
# Arguments:
#   None
# Globals:
#   KEY_FILE
# Dependencies:
#   ssh-keygen
#   ssh-add
#   grep
#
#   get_ssh_hash
add_identity_maybe() {
    # KEY_FILE exists and isn't empty
    if ! [[ -s "${KEY_FILE}" ]]; then
        echo -n "add_identity: KEYFILE (${KEY_FILE}) doesn't exist or" >&2
        echo    " is empty. Skipping" >&2
        return 1
    fi

    local key_hash;
        key_hash="$(ssh-keygen -lf "${KEY_FILE}" | get_ssh_hash)"
    if [[ $? != 0 ]]; then
        echo -n "add_identity: couldn't get hash fingerprint from" >&2
        echo    " KEY_FILE (${KEY_FILE}). Exiting" >&2
        return 1
    elif [[ -z "${key_hash}" ]]; then
        echo -n "add_identity: something went wrong when trying to" >&2
        echo    " get hash fingerprint from KEY_FILE (${KEY_FILE})" >&2
        echo    " and looks like it's empty" >&2
        return 1
    fi

    local agent_hash;
        agent_hash="$(ssh-add -l | grep "${KEY_FILE}" \
            | get_ssh_hash 2>/dev/null)"

    if [[ $? != 0 ]] || [[ -z "${agent_hash}" ]]; then
        echo "No identity (${KEY_FILE}) found in ssh agent. Adding"
    elif [[ "${key_hash}" != "${agent_hash}" ]]; then
        echo -n "Found identity (${KEY_FILE}) in ssh agent, but"
        echo    " fingerprints don't match"
        echo -e "   key:\t${key_hash}"
        echo -e "   agent:\t${agent_hash}"
        echo    "Adding identity"
    else
        return 0
    fi

    ssh-add "${KEY_FILE}"
}

add_identity_maybe

