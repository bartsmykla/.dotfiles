# credential_process front for okta-aws-cli:
#   credential_process = okta-aws-cached web --org-domain ... --format process-credentials --open-browser ...
#
# The AWS CLI and SDKs run credential_process on every call and never cache
# what it prints, so each call would open a new Okta activation page. This
# keeps one login per argument set until five minutes before it expires, and
# a lock makes parallel callers wait for that one login instead of each
# opening a page. okta-aws-cli hides its errors in process-credentials mode
# (an empty answer, exit 0), so the login runs in env-var mode, which reports
# them. When Okta refuses the activated token for the AWS app, okta-aws-cli
# calls it stale and opens another page; the login stops there instead. A
# failed login is printed and blocks new pages for two minutes, so a retry
# loop cannot flood the browser. OKTA_AWS_CACHED_FORCE=1 skips that.

cache="${XDG_CACHE_HOME:-$HOME/.cache}/okta-aws"
umask 077
mkdir -p "$cache"
key=$(printf '%s\0' "$@" | sha256sum | cut -c1-32)
creds="$cache/$key.json"
failed="$cache/$key.failed"
margin=300
cooldown=120

fresh() {
  [[ -s "$creds" ]] && jq -e --argjson margin "$margin" '(.Expiration | fromdateiso8601) > (now + $margin)' "$creds" >/dev/null 2>&1
}

if fresh; then
  exec cat "$creds"
fi
exec 9>"$cache/$key.lock"
flock 9
if fresh; then
  exec cat "$creds"
fi

if [[ -z "${OKTA_AWS_CACHED_FORCE:-}" && -s "$failed" ]] && (($(date +%s) - $(stat -c %Y "$failed") < cooldown)); then
  echo "okta-aws-cached: the last Okta login failed less than ${cooldown}s ago, so no new page opens (OKTA_AWS_CACHED_FORCE=1 retries now):" >&2
  cat "$failed" >&2
  exit 1
fi

args=()
duration=3600
while (($# > 0)); do
  case "$1" in
  --format) shift ;;
  --format=*) ;;
  --aws-session-duration)
    duration=$2
    args+=("$1" "$2")
    shift
    ;;
  --aws-session-duration=*)
    duration=${1#*=}
    args+=("$1")
    ;;
  *) args+=("$1") ;;
  esac
  shift
done
args+=(--format env-var)

started=$(date +%s)
errors="$cache/$key.err"
answer="$cache/$key.out"
okta-aws-cli "${args[@]}" >"$answer" 2>"$errors" &
login=$!
tail -n +1 -f "$errors" >&2 &
echoing=$!
refused=""
while kill -0 "$login" 2>/dev/null; do
  if grep -q 'appears to be stale' "$errors"; then
    refused=1
    kill "$login" 2>/dev/null || true
    break
  fi
  sleep 1
done
status=0
wait "$login" || status=$?
kill "$echoing" 2>/dev/null || true
output=$(cat "$answer")
rm -f "$answer"

value() {
  sed -n "s/^export $1=//p" <<<"$output" | tr -d "\"'"
}

id=$(value AWS_ACCESS_KEY_ID)
secret=$(value AWS_SECRET_ACCESS_KEY)
token=$(value AWS_SESSION_TOKEN)
if [[ "$status" -ne 0 || -z "$id" || -z "$secret" || -z "$token" ]]; then
  {
    if [[ -n "$refused" ]]; then
      echo "Okta activated the device but refused its token for the AWS app, which okta-aws-cli takes for a stale token and answers with a new page, so the login stopped there."
      echo "The usual cause is the app's sign-in policy: approve the page in a browser that signed in to Okta with MFA recently."
    else
      echo "okta-aws-cli exited $status without credentials:"
      grep -i -m 5 'error' "$errors" || tail -n 10 "$errors"
    fi
  } >"$failed"
  rm -f "$errors"
  cat "$failed" >&2
  exit 1
fi
rm -f "$errors" "$failed"

jq -n --arg id "$id" --arg secret "$secret" --arg token "$token" \
  --arg expiration "$(date -u -d "@$((started + duration))" +%Y-%m-%dT%H:%M:%SZ)" \
  '{Version: 1, AccessKeyId: $id, SecretAccessKey: $secret, SessionToken: $token, Expiration: $expiration}' >"$creds.tmp"
mv "$creds.tmp" "$creds"
cat "$creds"
