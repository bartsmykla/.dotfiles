function git-push-origin-first-no-verify \
  --description "Push to origin if it exists, otherwise fallback to upstream with --no-verify flag"

  af shortcuts abbreviations gp --remote origin-first --no-verify
end

