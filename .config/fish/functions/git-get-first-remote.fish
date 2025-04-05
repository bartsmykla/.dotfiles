function git-get-first-remote \
  --description "Return the first existing remote from given arguments"

  for remote in $argv
    if git remote | grep --quiet --fixed-strings --line-regexp "$remote"
      echo "$remote"
      return 0
    end
  end

  return 1
end
