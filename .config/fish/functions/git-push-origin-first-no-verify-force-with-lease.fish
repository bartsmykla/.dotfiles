function git-push-origin-first-no-verify-force-with-lease \
  --description "Push to origin if it exists, otherwise fallback to upstream with --no-verify and --force-with-lease flags"

  af shortcuts abbreviations gp --remote origin-first --no-verify --force-with-lease
end

