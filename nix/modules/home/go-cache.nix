# Trim of Go build and golangci-lint caches.
#
# Go only drops cache entries unused for 5 days and has no size cap, so a day
# of agent-driven go test/build/vet/lint across many worktrees can add tens of
# GB before that trim (or this job's age trim) runs. Go refreshes an entry's
# mtime when it is used, so deleting entries untouched for 2 days is safe
# during builds. A size cap is also required: same-day unique ActionIDs are
# all younger than 2 days.
{
  config,
  lib,
  pkgs,
  ...
}: let
  home = config.home.homeDirectory;
  trim = pkgs.writeShellScript "go-cache-trim" ''
    set -u

    log() { printf '%s %s\n' "$(/bin/date '+%Y-%m-%d %H:%M:%S')" "$*"; }

    size_kb() { /usr/bin/du -sk "$1" 2>/dev/null | /usr/bin/awk '{print $1}'; }

    # Delete oldest regular files in dir until it is at most target_kb.
    # Skips trim.txt (go's own trim bookmark). Safe if a build is running:
    # a missing cache file is a miss, not corruption. The file list is written
    # to a temp file so the delete loop runs in this shell (a pipeline
    # `while` would not stop the parent at the size target).
    prune_to_kb() {
      dir=$1
      target_kb=$2
      cur=$(size_kb "$dir")
      [ -n "$cur" ] || return 0
      [ "$cur" -gt "$target_kb" ] || return 0
      log "size-prune $dir ''${cur}KB -> target ''${target_kb}KB"

      list=$(/usr/bin/mktemp "''${TMPDIR:-/tmp}/go-cache-prune.XXXXXX") || return 1
      /usr/bin/find "$dir" -type f ! -name 'trim.txt' -exec /usr/bin/stat -f '%m %z %N' {} + \
        | /usr/bin/sort -n > "$list" || true

      need_bytes=$(( (cur - target_kb) * 1024 ))
      freed=0
      while read -r _mtime bytes path; do
        [ -n "$path" ] || continue
        /bin/rm -f "$path" || continue
        freed=$((freed + bytes))
        if [ "$freed" -ge "$need_bytes" ]; then
          break
        fi
      done < "$list"
      /bin/rm -f "$list"

      log "size-prune $dir now $(size_kb "$dir")KB"
    }

    # Shared caches plus stray per-worktree ones (e.g. GOCACHE=$PWD/bin/.cache/go-build).
    for dir in "${home}/Library/Caches/go-build" "${home}/Library/Caches/golangci-lint"; do
      if [ -d "$dir" ]; then
        log "age-trim $dir before $(size_kb "$dir")KB"
        /usr/bin/find "$dir" -type f -mtime +2 -delete
      fi
    done

    # go-build: 15 GiB high water, 10 GiB target. golangci-lint: 2 GiB / 1 GiB.
    if [ -d "${home}/Library/Caches/go-build" ]; then
      cur=$(size_kb "${home}/Library/Caches/go-build")
      if [ -n "$cur" ] && [ "$cur" -gt $((15 * 1024 * 1024)) ]; then
        prune_to_kb "${home}/Library/Caches/go-build" $((10 * 1024 * 1024))
      fi
    fi
    if [ -d "${home}/Library/Caches/golangci-lint" ]; then
      cur=$(size_kb "${home}/Library/Caches/golangci-lint")
      if [ -n "$cur" ] && [ "$cur" -gt $((2 * 1024 * 1024)) ]; then
        prune_to_kb "${home}/Library/Caches/golangci-lint" $((1 * 1024 * 1024))
      fi
    fi

    for root in /Users/Shared/codex-home/worktrees "${home}/.t3/worktrees" "${home}/Projects"; do
      [ -d "$root" ] || continue
      /usr/bin/find "$root" -maxdepth 6 -type d \( -name node_modules -o -name .git \) -prune -o \
        -type d -path '*/.cache/go-build' -print 2>/dev/null |
        while IFS= read -r dir; do /usr/bin/find "$dir" -type f -mtime +2 -delete; done
    done

    log "done go-build=$(size_kb "${home}/Library/Caches/go-build")KB golangci=$(size_kb "${home}/Library/Caches/golangci-lint")KB"
  '';
in {
  # The user go env file is read by every `go` invocation, including GUI/agent
  # launches that do not get shell sessionVariables. An empty process GOFLAGS
  # does not override this file. Keep CGO_ENABLED=0 as already configured.
  # -trimpath: share compile/test cache across worktrees with identical source.
  # -buildvcs=false: avoid main-package link misses on dirty worktrees (Go 1.24+
  # stamps VCS version). Release builds can pass -buildvcs=true explicitly.
  # force: a previously unmanaged go env file would otherwise block activation.
  home.file."Library/Application Support/go/env" = {
    text = ''
      CGO_ENABLED=0
      GOFLAGS=-trimpath -buildvcs=false
    '';
    force = true;
  };

  launchd.agents.go-cache-trim = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
    config = {
      ProgramArguments = ["${trim}"];
      StartCalendarInterval = map (h: {
        Hour = h;
        Minute = 15;
      }) [0 4 8 12 16 20];
      RunAtLoad = true;
      ProcessType = "Background";
      LowPriorityIO = true;
      Nice = 10;
      StandardOutPath = "${home}/Library/Logs/go-cache-trim.log";
      StandardErrorPath = "${home}/Library/Logs/go-cache-trim.log";
    };
  };
}
