function git-get-default-branch \
  --description "Return the default branch name (e.g. main/master) for the given remote"

  set --function remote $argv[1]
  if test -z "$remote"
    return 1
  end

  string replace "$remote/" "" (git rev-parse --abbrev-ref "$remote/HEAD")
end
