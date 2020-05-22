#!/usr/bin/env zsh

# Globals:
#   match
_parse_github_url() {
    if [[ $# -lt 1 ]]; then
        echo "_parse_github_url: function expects one parameter" >&2
        return 1
    fi

    local regex='^(git:\/\/|git@|https:\/\/)?github.com[:\/]([[:alnum:]_-]+)\/([[:alnum:]_-\.]+)\/?(\.git)?$'
    local repository="${1}"
    local organization
    local name

    if [[ ${repository} =~ ${regex} ]]; then
        organization="${match[2]}"
        name="${match[3]}"
    else
        echo -n "_parse_github_url: failed in parsing repository's" >&2
        echo    " organization and/or name" >&2
        return 1
    fi

    echo "${organization}" "${name}"
}

# Globals:
#   PROJECTS_PATH
#   HOME
_get_projects_path() {
    if [[ $# != 2 ]]; then
        echo -n "_get_projects_path(organization, name): function expects" >&2
        echo    " two parameters" >&2
        return 1
    fi

    local projects_path="${PROJECTS_PATH:-${HOME}/Projects/github.com}"
    local organization="${1}"
    local name="${2}"

    echo "${projects_path}/${organization}/${name}"
}

gccl() {
    local repository="${1}"; shift
    local names; names=($(_parse_github_url "${repository}")) || return
    local organization="${names[1]}"
    local name="${names[2]}"
    local project_path; project_path="$(_get_projects_path "${organization}" \
        "${name}")" || return

    git clone $@ "${repository}" "${project_path}" || return
}

gccld() {
    local repository="${1}"; shift
    local names; names=($(_parse_github_url "${repository}")) || return
    local organization="${names[1]}"
    local name="${names[2]}"
    local project_path; project_path="$(_get_projects_path "${organization}" \
        "${name}")" || return

    git clone $@ "${repository}" "${project_path}" || return
    echo "Changing directory to cloned repository (from: $(pwd))"
    cd "${project_path}" || return
}

# Push to current branch (origin) with force flag
ggpf() {
    if [[ $# != 0 ]]; then
        echo "ggpf(): function doesn't expect any parameters" >&2
        return 1
    fi

    local branch; branch="$(git_current_branch)" || return

    git push --force origin "${branch}"
}
