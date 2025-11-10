function git_clone_to_projects --description "Git clone repository to\
 \$PROJECTS_PATH ($PROJECTS_PATH) and create parent directory if doesn't exist"\
 --argument-names repo_url;
  # TODO: Make it configurable
  if ! set -q PROJECTS_PATH;
    echo "Variable \$PROJECTS_PATH is not defined" >&2
    return 1
  end

  set regex 's/^git@github\\.com:(.+)?\\/(.+)?.git$/\1 \2/'
  set names (echo $repo_url | sed -E $regex | string split " ")

  if test (count $names) -ne 2
    echo "Invalid or unsupported repository path ($repo_url)" >&2
    return 121
  end

  set org_name $names[1]
  set repo_name $names[2]
  set org_path $PROJECTS_PATH/$org_name
  set full_path $org_path/$repo_name

  # TODO: Add option to overwrite directories
  if test -e $full_path
    echo "Directory \"$full_path\" already exists" >&2
    return 121
  end

  mkdir -p $full_path && \
  git clone $repo_url $full_path && \
  set -xg __LAST_CLONED_REPO_PATH $full_path
end
