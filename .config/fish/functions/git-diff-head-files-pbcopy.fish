function git-diff-head-files-pbcopy \
  --description "Diff given files against HEAD and copy the output to clipboard"

  af shortcuts abbreviations gd --files % --reference HEAD --pbcopy
end
