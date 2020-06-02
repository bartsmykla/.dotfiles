#!/usr/bin/env bash

# TODO: Sometimes it happens when tmux is starting the ssh-add is called in
#       inactive window, so it would be good to write solution which would
#       switch to the pane where it was called if it happenes

readonly SCRIPT_NAME=$(basename "${0}")
readonly LOCKDIR="/tmp/lock"
readonly LOCKFILE="${LOCKDIR}/${SCRIPT_NAME}"
readonly LOCKFD=99
readonly KEY_FILE="${1:?ssh-agent.bash expects KEY_FILE to be passed as a first parameter}"

# PRIVATE
_lock()             { flock -${1} ${LOCKFD}; }
_no_more_locking()  { _lock u; _lock xn && rm -f "${LOCKFILE}"; }
_prepare_locking()  {
    mkdir -p "${LOCKDIR}"
    eval "exec ${LOCKFD}>\"${LOCKFILE}\""
    trap _no_more_locking EXIT
}
 
# ON START
_prepare_locking

# PUBLIC
exlock_now()    { _lock xn; }  # obtain an exclusive lock immediately or fail
exlock()        { _lock x; }   # obtain an exclusive lock
shlock()        { _lock s; }   # obtain a shared lock
unlock()        { _lock u; }   # drop a lock

get_ssh_hash() {
    local line;
    local ssh_hash;

    read -r line

    if ! ssh_hash=$(echo "${line}" | awk '{ print $2 }' 2>/dev/null) \
        || [[ -z "${ssh_hash}" ]]; then
        return 1
    fi

    echo "${ssh_hash}"
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
    # Check if KEY_FILE exists and isn't empty
    if ! [[ -s "${KEY_FILE}" ]]; then
        echo -n "add_identity_maybe: KEYFILE (${KEY_FILE}) doesn't exist or" >&2
        echo    " is empty. Skipping" >&2
        return 1
    fi

    local key_hash;
    local agent_hash;

    if ! key_hash=$(ssh-keygen -lf "${KEY_FILE}" | get_ssh_hash); then
        echo -n "add_identity_maybe: couldn't get hash fingerprint from" >&2
        echo    " KEY_FILE (${KEY_FILE}). Exiting" >&2
        return 1
    fi

    if ! agent_hash=$(ssh-add -l | grep "${KEY_FILE}" | get_ssh_hash); then
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

exlock; add_identity_maybe; unlock
