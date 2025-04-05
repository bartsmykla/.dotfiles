function git-checkout-default \
  --description "git checkout for the default branch of the first found remote (upstream, origin)"

  set --function remote (git-get-first-remote upstream origin)
  set --function branch (git-get-default-branch $remote)

  echo "git checkout $branch"
end
