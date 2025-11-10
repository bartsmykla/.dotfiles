function git-push-origin-first-force-with-lease \
  --description "Push to origin if it exists, otherwise fallback to upstream with --force-with-lease flag"

  af shortcuts abbreviations gp --remote origin-first --force-with-lease
end

