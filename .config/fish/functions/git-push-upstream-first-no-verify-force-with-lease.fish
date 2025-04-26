function git-push-upstream-first-no-verify-force-with-lease \
  --description "Push to upstream if it exists, otherwise fallback to origin with --no-verify and --force-with-lease flags"

  af shortcuts abbreviations gp --remote upstream-first --no-verify --force-with-lease
end

