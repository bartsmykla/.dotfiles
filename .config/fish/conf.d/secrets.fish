for secret in $SECRETS_PATH/*
  eval "set -gx (basename $secret) (cat $secret)"
end
