function git-checkout-default-fetch-fast-forward \
  --description "Git checkout, fetch, and merge command for the default branch of the first found remote (upstream, origin)"

  set --function remote (git-get-first-remote upstream origin)
  set --function branch (git-get-default-branch $remote)

  echo "git checkout $branch && git fetch $remote && git merge --ff-only $remote/$branch"
end
