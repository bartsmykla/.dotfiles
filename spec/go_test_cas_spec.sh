#!/usr/bin/env bash
# shellcheck disable=SC2292  # ShellSpec uses [ ] intentionally for POSIX compliance
# shellcheck disable=SC2296  # $SHELLSPEC_PROJECT_ROOT is a ShellSpec built-in variable
# shellcheck disable=SC2012  # inode checks in tests use ls -i on controlled paths
# shellcheck disable=SC2016  # hook command must keep $HOME literal

Describe 'go-test-cas'
    setup() {
        export DOTFILES_PATH="${SHELLSPEC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
        export CAS_SRC="${DOTFILES_PATH}/nix/modules/home/go-test-cas"
        TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/go-test-cas-spec.XXXXXX")
        export TEST_ROOT
        export GO_TEST_CAS_DIR="${TEST_ROOT}/cache"
        export GO_TEST_CAS_EXEC="${CAS_SRC}/go-test-cas-exec.sh"
        export SHIM="${CAS_SRC}/go-shim.sh"
        export HOOK="${CAS_SRC}/hook.py"
        mkdir -p "$GO_TEST_CAS_DIR" "${TEST_ROOT}/bin"
        chmod +x "$GO_TEST_CAS_EXEC" "$SHIM" "$HOOK"

        # Fake test binary that records its identity and args, then exits with
        # the code in FAKE_BIN_EXIT (default 0).
        FAKE_BIN="${TEST_ROOT}/bin/pkg.test"
        cat >"$FAKE_BIN" <<'BIN'
#!/usr/bin/env bash
set -u
echo "ran-as=$0 args=$* inode=$(ls -i "$0" | awk '{print $1}')" >"${FAKE_BIN_LOG:-/dev/null}"
if [ -n "${FAKE_BIN_TRAP_FILE:-}" ]; then
  trap 'echo got-term >"$FAKE_BIN_TRAP_FILE"; exit 0' TERM
  # Stay alive until signalled or FAKE_BIN_SLEEP elapses.
  sleep "${FAKE_BIN_SLEEP:-5}"
  exit 0
fi
exit "${FAKE_BIN_EXIT:-0}"
BIN
        chmod +x "$FAKE_BIN"
        export FAKE_BIN
        export FAKE_BIN_LOG="${TEST_ROOT}/fake.log"
        : >"$FAKE_BIN_LOG"

        MOCK_GO="${TEST_ROOT}/bin/mock-go"
        MOCK_LOG="${TEST_ROOT}/mock-go.log"
        cat >"$MOCK_GO" <<'GO'
#!/usr/bin/env bash
set -u
printf '%s\n' "$*" >>"${MOCK_LOG}"
# If invoked as `go test -exec helper ...`, optionally run the helper so
# integration-style cases can observe exec behaviour.
if [ "${MOCK_GO_RUN_EXEC:-0}" != "0" ]; then
  exec_helper=""
  rest=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -exec)
        exec_helper=$2
        shift 2
        continue
        ;;
      -exec=*)
        exec_helper=${1#-exec=}
        shift
        continue
        ;;
      *)
        rest+=("$1")
        shift
        ;;
    esac
  done
  if [ -n "$exec_helper" ]; then
    "$exec_helper" "${FAKE_BIN}" -test.v
    exit $?
  fi
fi
exit 0
GO
        chmod +x "$MOCK_GO"
        export MOCK_GO MOCK_LOG
        : >"$MOCK_LOG"
        export GO_TEST_CAS_REAL_GO="$MOCK_GO"
        unset GO_TEST_CAS_DEBUG || true
        export GO_TEST_CAS=1
    }

    cleanup() {
        if [ -n "${TEST_ROOT:-}" ] && [ -d "${TEST_ROOT}" ]; then
            rm -rf "${TEST_ROOT}"
        fi
    }
    Before 'setup'
    After 'cleanup'

    sha_of() {
        /usr/bin/shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'
    }

    inode_of() {
        ls -i "$1" | awk '{print $1}'
    }

    Describe 'go-test-cas-exec'
        It 'stores a miss in the cache and execs that inode'
            When call "$GO_TEST_CAS_EXEC" "$FAKE_BIN" -test.run TestAdd
            The status should be success
            The file "$FAKE_BIN_LOG" should be exist
            sha=$(sha_of "$FAKE_BIN")
            The file "${GO_TEST_CAS_DIR}/${sha}" should be executable
            The output should eq ""
        End

        It 'hardlinks the cache entry to the original binary on the same volume'
            "$GO_TEST_CAS_EXEC" "$FAKE_BIN" linked >/dev/null
            sha=$(sha_of "$FAKE_BIN")
            cached="${GO_TEST_CAS_DIR}/${sha}"
            When call test "$(inode_of "$FAKE_BIN")" = "$(inode_of "$cached")"
            The status should be success
            The contents of file "$FAKE_BIN_LOG" should include "ran-as=${cached}"
        End

        It 'reuses the cached inode on a hit from a copy of the same bytes'
            "$GO_TEST_CAS_EXEC" "$FAKE_BIN" first >/dev/null
            sha=$(sha_of "$FAKE_BIN")
            cached="${GO_TEST_CAS_DIR}/${sha}"
            copy="${TEST_ROOT}/bin/copy.test"
            cp "$FAKE_BIN" "$copy"
            chmod +x "$copy"
            When call "$GO_TEST_CAS_EXEC" "$copy" second
            The status should be success
            The file "$cached" should be exist
            # Still a single cache object; the log records ran-as=$0 from the cache path.
            The contents of file "$FAKE_BIN_LOG" should include "second"
        End

        It 'passes through a non-zero exit code'
            export FAKE_BIN_EXIT=17
            When call "$GO_TEST_CAS_EXEC" "$FAKE_BIN"
            The status should eq 17
        End

        send_term_to_exec() {
            export FAKE_BIN_TRAP_FILE="${TEST_ROOT}/got-term"
            export FAKE_BIN_SLEEP=8
            "$GO_TEST_CAS_EXEC" "$FAKE_BIN" &
            pid=$!
            waited=0
            while [ "$waited" -lt 20 ]; do
                if [ -s "$FAKE_BIN_LOG" ]; then
                    break
                fi
                sleep 0.1
                waited=$((waited + 1))
            done
            kill -TERM "$pid" 2>/dev/null || true
            wait "$pid" || true
            cat "$FAKE_BIN_TRAP_FILE"
        }

        It 'forwards SIGTERM to the cached binary'
            When call send_term_to_exec
            The status should be success
            The output should include "got-term"
        End

        It 'survives concurrent first-exec misses of the same bytes'
            pids=""
            i=0
            while [ "$i" -lt 8 ]; do
                "$GO_TEST_CAS_EXEC" "$FAKE_BIN" "run-$i" &
                pids="$pids $!"
                i=$((i + 1))
            done
            fail=0
            for pid in $pids; do
                if ! wait "$pid"; then
                    fail=$((fail + 1))
                fi
            done
            sha=$(sha_of "$FAKE_BIN")
            When call test "$fail" -eq 0 -a -x "${GO_TEST_CAS_DIR}/${sha}"
            The status should be success
        End

        It 'falls back to the original binary when the cache dir cannot be used'
            export GO_TEST_CAS_DIR="${TEST_ROOT}/not-a-dir"
            mkdir -p "${TEST_ROOT}"
            touch "$GO_TEST_CAS_DIR"
            When call "$GO_TEST_CAS_EXEC" "$FAKE_BIN" fallback
            The status should be success
            The contents of file "$FAKE_BIN_LOG" should include "fallback"
        End

        It 'runs the original binary when GO_TEST_CAS=0'
            export GO_TEST_CAS=0
            When call "$GO_TEST_CAS_EXEC" "$FAKE_BIN" opted-out
            The status should be success
            sha=$(sha_of "$FAKE_BIN")
            The file "${GO_TEST_CAS_DIR}/${sha}" should not be exist
        End
    End

    Describe 'go shim'
        It 'injects -exec for go test'
            When call "$SHIM" test ./pkg
            The status should be success
            The contents of file "$MOCK_LOG" should include "-exec=${GO_TEST_CAS_EXEC}"
            The contents of file "$MOCK_LOG" should include "test"
        End

        It 'injects -exec after go -C DIR test'
            When call "$SHIM" -C /tmp test ./pkg
            The status should be success
            The contents of file "$MOCK_LOG" should include "-C /tmp test -exec=${GO_TEST_CAS_EXEC} ./pkg"
        End

        It 'injects -exec for go test -json'
            When call "$SHIM" test -json ./pkg
            The status should be success
            The contents of file "$MOCK_LOG" should include "-exec=${GO_TEST_CAS_EXEC}"
            The contents of file "$MOCK_LOG" should include "-json"
        End

        It 'does not inject -exec for go test -c'
            When call "$SHIM" test -c -o /tmp/out.test ./pkg
            The status should be success
            The contents of file "$MOCK_LOG" should not include "-exec="
            The contents of file "$MOCK_LOG" should include "test -c -o /tmp/out.test ./pkg"
        End

        It 'does not inject when -exec is already present'
            When call "$SHIM" test -exec /usr/bin/true ./pkg
            The status should be success
            The contents of file "$MOCK_LOG" should include "test -exec /usr/bin/true ./pkg"
            The contents of file "$MOCK_LOG" should not include "go-test-cas-exec"
        End

        It 'does not inject when GOFLAGS already has -exec'
            export GOFLAGS="-exec=/usr/bin/true"
            When call "$SHIM" test ./pkg
            The status should be success
            The contents of file "$MOCK_LOG" should include "test ./pkg"
            The contents of file "$MOCK_LOG" should not include "go-test-cas-exec"
        End

        It 'does not inject when GO_TEST_CAS=0'
            export GO_TEST_CAS=0
            When call "$SHIM" test ./pkg
            The status should be success
            The contents of file "$MOCK_LOG" should include "test ./pkg"
            The contents of file "$MOCK_LOG" should not include "-exec="
        End

        It 'does not inject for go build or go list'
            When call "$SHIM" build ./pkg
            The status should be success
            The contents of file "$MOCK_LOG" should eq "build ./pkg"
        End

        It 'does not recurse when the shim is first on PATH'
            # Put the shim ahead of the mock on PATH; the shim must still
            # exec the mock, not itself.
            PATH="$(dirname "$SHIM"):$PATH"
            export PATH
            When call "$SHIM" version
            The status should be success
            The contents of file "$MOCK_LOG" should eq "version"
        End
    End

    Describe 'PreToolUse hook'
        hook_run() {
            provider=$1
            cmd=$2
            printf '%s\n' "$cmd" >"${TEST_ROOT}/orig-cmd"
            python3 - "$provider" "$cmd" "$HOOK" "$TEST_ROOT" <<'PY'
import json, os, subprocess, sys
provider, cmd, hook, root = sys.argv[1:5]
# Point the hook at a copy of the shim path under TEST_ROOT so it believes
# the shim is installed, without touching ~/.local/bin.
bindir = os.path.join(root, "localbin")
os.makedirs(bindir, exist_ok=True)
shim = os.path.join(bindir, "go")
if not os.path.exists(shim):
    os.symlink(os.environ["SHIM"], shim)
payload = {
    "hook_event_name": "PreToolUse",
    "tool_name": "Bash" if provider == "claude" else "shell",
    "tool_input": {"command": cmd},
}
env = os.environ.copy()
env["GO_TEST_CAS_HOOK_HOME"] = root
env["GO_TEST_CAS_HOOK_SHIM"] = shim
env["GO_TEST_CAS_HOOK_BINDIR"] = bindir
args = [hook, "--" + provider]
proc = subprocess.run(args, input=json.dumps(payload), text=True, capture_output=True, env=env)
Path_out = os.path.join(root, "hook-out.json")
open(Path_out, "w").write(proc.stdout)
open(os.path.join(root, "hook-err.txt"), "w").write(proc.stderr)
raise SystemExit(proc.returncode)
PY
        }

        hook_claude_gotest() { hook_run claude "go test ./pkg"; }
        hook_codex_gotest() { hook_run codex "go test ./pkg"; }
        hook_claude_abspath() { hook_run claude "/opt/homebrew/bin/go test ./pkg"; }
        hook_claude_count() { hook_run claude "go test -count=1 ./pkg"; }
        hook_claude_ls() { hook_run claude "ls -la"; }
        hook_claude_optout() { hook_run claude "go test ./pkg"; }

        It 'rewrites a go test command when the shim would not already be used'
            When call hook_claude_gotest
            The status should be success
            The contents of file "${TEST_ROOT}/hook-out.json" should include "PATH="
            The contents of file "${TEST_ROOT}/hook-out.json" should include "go test ./pkg"
            The contents of file "${TEST_ROOT}/hook-out.json" should not include "permissionDecision"
        End

        It 'adds permissionDecision allow for Codex rewrites'
            When call hook_codex_gotest
            The status should be success
            The contents of file "${TEST_ROOT}/hook-out.json" should include "permissionDecision"
            The contents of file "${TEST_ROOT}/hook-out.json" should include "allow"
        End

        It 'rewrites an absolute go path to bare go so the shim wins'
            When call hook_claude_abspath
            The status should be success
            The contents of file "${TEST_ROOT}/hook-out.json" should include "go test ./pkg"
            The contents of file "${TEST_ROOT}/hook-out.json" should not include "/opt/homebrew/bin/go test"
        End

        It 'does not rewrite when GO_TEST_CAS=0'
            export GO_TEST_CAS=0
            When call hook_claude_optout
            The status should be success
            The contents of file "${TEST_ROOT}/hook-out.json" should eq ""
        End

        It 'does not strip -count=1'
            When call hook_claude_count
            The status should be success
            The contents of file "${TEST_ROOT}/hook-out.json" should include "-count=1"
        End

        It 'leaves unrelated commands alone'
            When call hook_claude_ls
            The status should be success
            The contents of file "${TEST_ROOT}/hook-out.json" should eq ""
        End
    End

    Describe 'merge helpers'
        merge_hooks_twice() {
            live="${TEST_ROOT}/settings.json"
            printf '%s\n' '{"hooks":{"PreToolUse":[]}}' >"$live"
            python3 "${CAS_SRC}/merge-hooks.py" --file "$live" --matcher Bash --command '$HOME/.local/bin/go-test-cas-hook --claude' --needle go-test-cas-hook >/dev/null 2>&1
            python3 "${CAS_SRC}/merge-hooks.py" --file "$live" --matcher Bash --command '$HOME/.local/bin/go-test-cas-hook --claude' --needle go-test-cas-hook >/dev/null 2>&1
            python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(len(d["hooks"]["PreToolUse"]))' "$live"
        }

        merge_guidance_twice() {
            live="${TEST_ROOT}/AGENTS.md"
            printf '%s\n' "# existing" >"$live"
            bash "${CAS_SRC}/merge-guidance.sh" --file "$live" --block "${CAS_SRC}/guidance.md" >/dev/null 2>&1
            bash "${CAS_SRC}/merge-guidance.sh" --file "$live" --block "${CAS_SRC}/guidance.md" >/dev/null 2>&1
            grep -c 'managed:go-test-macos' "$live"
        }

        It 'adds a PreToolUse hook and is idempotent'
            When call merge_hooks_twice
            The output should eq "1"
            The status should be success
        End

        It 'appends guidance only once'
            When call merge_guidance_twice
            The output should eq "2"
            The status should be success
        End
    End
End
