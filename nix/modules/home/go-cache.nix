# Trim of Go build and golangci-lint caches.
#
# Go only drops cache entries unused for 5 days and has no size cap, so a day
# of agent-driven go test/build/vet/lint across many worktrees can add tens of
# GB before that trim (or this job's age trim) runs. Go refreshes an entry's
# mtime when it is used, so deleting entries untouched for 2 days is safe
# during builds. A size cap is also required: same-day unique ActionIDs are
# all younger than 2 days.
#
# The size pass and the stray per-worktree cache scan must not fight live
# builds: skip both when compile/link/test/lint is running or 1-minute load is
# above the CPU count; never delete files touched in the last 60 minutes;
# evict largest eligible files first and unlink them in one process; stop after
# a runtime cap (including a long worktree find). A lock directory prevents
# overlapping runs.
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

    START=$(/bin/date +%s)
    MAX_SECS="''${GO_CACHE_TRIM_MAX_SECS:-600}"
    MIN_AGE_SECS="''${GO_CACHE_TRIM_MIN_AGE_SECS:-3600}"
    NCPU=$(/usr/sbin/sysctl -n hw.ncpu 2>/dev/null || echo 1)
    LOAD_THRESHOLD="''${GO_CACHE_TRIM_LOAD_THRESHOLD:-$NCPU}"
    GOBUILD="''${GO_CACHE_TRIM_GOBUILD:-${home}/Library/Caches/go-build}"
    GOLANGCI="''${GO_CACHE_TRIM_GOLANGCI:-${home}/Library/Caches/golangci-lint}"
    GOBUILD_HIGH_KB="''${GO_CACHE_TRIM_GOBUILD_HIGH_KB:-$((15 * 1024 * 1024))}"
    GOBUILD_TARGET_KB="''${GO_CACHE_TRIM_GOBUILD_TARGET_KB:-$((10 * 1024 * 1024))}"
    GOLANGCI_HIGH_KB="''${GO_CACHE_TRIM_GOLANGCI_HIGH_KB:-$((2 * 1024 * 1024))}"
    GOLANGCI_TARGET_KB="''${GO_CACHE_TRIM_GOLANGCI_TARGET_KB:-$((1 * 1024 * 1024))}"
    LOCKDIR="''${GO_CACHE_TRIM_LOCKDIR:-${home}/Library/Caches/go-cache-trim.lock}"

    elapsed() { echo $(( $(/bin/date +%s) - START )); }

    over_time() { [ "$(elapsed)" -ge "$MAX_SECS" ]; }

    acquire_lock() {
      if /bin/mkdir "$LOCKDIR" 2>/dev/null; then
        printf '%s\n' "$$" > "$LOCKDIR/pid"
        return 0
      fi
      old=$(/bin/cat "$LOCKDIR/pid" 2>/dev/null || true)
      if [ -n "$old" ] && /bin/kill -0 "$old" 2>/dev/null; then
        log "already running pid $old, exit"
        return 1
      fi
      log "removing stale lock (pid ''${old:-unknown})"
      /bin/rm -rf "$LOCKDIR"
      /bin/mkdir "$LOCKDIR" || return 1
      printf '%s\n' "$$" > "$LOCKDIR/pid"
      return 0
    }

    release_lock() { /bin/rm -rf "$LOCKDIR"; }

    load1() {
      if [ -n "''${GO_CACHE_TRIM_FAKE_LOAD+x}" ]; then
        printf '%s\n' "$GO_CACHE_TRIM_FAKE_LOAD"
        return
      fi
      /usr/sbin/sysctl -n vm.loadavg | /usr/bin/awk '{gsub(/[{}]/, "", $1); print $1}'
    }

    go_busy() {
      if [ -n "''${GO_CACHE_TRIM_FAKE_BUSY+x}" ]; then
        [ "$GO_CACHE_TRIM_FAKE_BUSY" = "1" ]
        return
      fi
      # Match process names only so this script's own awk/perl source cannot
      # self-match. Any `go` / compile / link / lint is enough to skip the
      # size pass and stray-cache scan; a miss there is preferable to evicting
      # a warm cache or walking worktrees under load.
      /bin/ps -axco comm= | /usr/bin/awk '
        BEGIN { found = 0 }
        $1 == "golangci-lint" { found = 1; exit }
        $1 == "compile" { found = 1; exit }
        $1 == "link" { found = 1; exit }
        $1 == "asm" { found = 1; exit }
        $1 == "go" { found = 1; exit }
        END { exit found ? 0 : 1 }
      '
    }

    is_busy() {
      what=$1
      if go_busy; then
        log "skip $what: go compile/link/test/lint running"
        return 0
      fi
      load=$(load1)
      if /usr/bin/awk -v l="$load" -v t="$LOAD_THRESHOLD" 'BEGIN { exit !(l+0 > t+0) }'; then
        log "skip $what: load $load > threshold $LOAD_THRESHOLD"
        return 0
      fi
      return 1
    }

    # Delete largest eligible files (mtime older than MIN_AGE_SECS, not trim.txt)
    # until the directory is at most target_kb, or the runtime cap is hit.
    # Unlinks run in one perl process. Safe if a build is running: a missing
    # cache file is a miss, not corruption. current size is measured once
    # up front; a final du is left to the caller.
    prune_to_kb() {
      dir=$1
      target_kb=$2
      if over_time; then
        log "time cap reached ($(elapsed)s >= ''${MAX_SECS}s), skip size-prune $dir"
        return 0
      fi
      cur=$(size_kb "$dir")
      [ -n "$cur" ] || return 0
      [ "$cur" -gt "$target_kb" ] || return 0
      need_bytes=$(( (cur - target_kb) * 1024 ))
      deadline=$((START + MAX_SECS))
      log "size-prune $dir ''${cur}KB -> target ''${target_kb}KB (min-age ''${MIN_AGE_SECS}s, largest-old first)"

      # Lines: PROGRESS n freed | DONE n freed | TIME n freed
      # Process substitution keeps the heredoc attached to perl (a pipe after
      # <<'PERL' would steal the while-loop body as the program text).
      while IFS=' ' read -r ev n freed _; do
        case $ev in
          PROGRESS) log "size-prune progress unlinked $n freed ''${freed}B" ;;
          DONE) log "size-prune unlinked $n freed ''${freed}B" ;;
          TIME) log "time cap reached during size-prune unlinked $n freed ''${freed}B" ;;
          *) log "size-prune unexpected $ev $n $freed" ;;
        esac
      done < <(/usr/bin/perl - "$dir" "$need_bytes" "$MIN_AGE_SECS" "$deadline" <<'PERL'
use strict;
use warnings;
use File::Find;

my ($dir, $need_bytes, $min_age, $deadline) = @ARGV;
my $now = time;
my @files;

find(
  {
    wanted => sub {
      my @st = lstat($_);
      return unless @st && -f _;
      return if $_ eq 'trim.txt';
      return if $st[9] > $now - $min_age;
      push @files, [ $st[7], $File::Find::name ];
    },
    no_chdir => 1,
  },
  $dir
);

@files = sort { $b->[0] <=> $a->[0] } @files;

my $freed = 0;
my $n     = 0;
for my $it (@files) {
  if (time >= $deadline) {
    print "TIME $n $freed\n";
    exit 0;
  }
  my ($sz, $path) = @$it;
  if (unlink $path) {
    $freed += $sz;
    $n++;
    print "PROGRESS $n $freed\n" if $n % 2000 == 0;
  }
  last if $freed >= $need_bytes;
}
print "DONE $n $freed\n";
PERL
      )
    }

    if ! acquire_lock; then
      exit 0
    fi
    trap release_lock EXIT

    log "start max-secs=$MAX_SECS min-age=$MIN_AGE_SECS load-threshold=$LOAD_THRESHOLD"

    for dir in "$GOBUILD" "$GOLANGCI"; do
      if over_time; then
        log "time cap reached ($(elapsed)s >= ''${MAX_SECS}s), skip remaining work"
        break
      fi
      if [ -d "$dir" ]; then
        log "age-trim $dir before $(size_kb "$dir")KB"
        /usr/bin/find "$dir" -type f -mtime +2 -delete
      fi
    done

    if over_time; then
      log "time cap reached ($(elapsed)s >= ''${MAX_SECS}s), skip size-prune"
    elif is_busy "size-prune"; then
      :
    else
      if [ -d "$GOBUILD" ]; then
        cur=$(size_kb "$GOBUILD")
        if [ -n "$cur" ] && [ "$cur" -gt "$GOBUILD_HIGH_KB" ]; then
          prune_to_kb "$GOBUILD" "$GOBUILD_TARGET_KB"
        fi
      fi
      if [ -d "$GOLANGCI" ]; then
        cur=$(size_kb "$GOLANGCI")
        if [ -n "$cur" ] && [ "$cur" -gt "$GOLANGCI_HIGH_KB" ]; then
          prune_to_kb "$GOLANGCI" "$GOLANGCI_TARGET_KB"
        fi
      fi
    fi

    emit_stray_roots() {
      if [ -n "''${GO_CACHE_TRIM_STRAY_ROOTS+x}" ]; then
        printf '%s\n' "$GO_CACHE_TRIM_STRAY_ROOTS"
      else
        printf '%s\n' /Users/Shared/codex-home/worktrees "${home}/.t3/worktrees" "${home}/Projects"
      fi
    }

    # Same busy-check as the size pass: a worktree find can saturate disk
    # I/O even when it only age-trims. The walk is niced, prunes heavy
    # directories, is capped at maxdepth 6, and is aborted at the runtime cap.
    if over_time; then
      log "time cap reached ($(elapsed)s >= ''${MAX_SECS}s), skip stray-cache scan"
    elif [ -n "''${GO_CACHE_TRIM_NO_STRAY:-}" ]; then
      :
    elif is_busy "stray-cache scan"; then
      :
    else
      while IFS= read -r root; do
        [ -n "$root" ] || continue
        [ -d "$root" ] || continue
        if over_time; then
          log "time cap reached ($(elapsed)s >= ''${MAX_SECS}s), skip stray-cache scan"
          break
        fi
        remain=$((MAX_SECS - $(elapsed)))
        [ "$remain" -gt 0 ] || break
        list=$(/usr/bin/mktemp "''${TMPDIR:-/tmp}/go-cache-stray.XXXXXX") || continue
        # shellcheck disable=SC2016 # perl -e is single-quoted so bash does not expand it
        /usr/bin/nice -n 15 /usr/bin/perl -e '
          my $s = shift;
          $SIG{ALRM} = sub { exit 142 };
          alarm $s;
          my $rc = system(@ARGV);
          exit($rc == 0 ? 0 : ($? == -1 ? 1 : ($? & 127 ? 128 + ($? & 127) : $? >> 8)));
        ' "$remain" /usr/bin/find "$root" -maxdepth 6 -type d \( -name node_modules -o -name .git \) -prune -o \
          -type d -path "*/.cache/go-build" -print > "$list" 2>/dev/null
        find_rc=$?
        if [ "$find_rc" -eq 142 ] || over_time; then
          log "time cap reached during stray-cache scan"
          /bin/rm -f "$list"
          break
        fi
        while IFS= read -r dir; do
          [ -n "$dir" ] || continue
          if over_time; then
            log "time cap reached ($(elapsed)s >= ''${MAX_SECS}s), skip stray-cache scan"
            break
          fi
          /usr/bin/find "$dir" -type f -mtime +2 -delete
        done < "$list"
        /bin/rm -f "$list"
      done < <(emit_stray_roots)
    fi

    log "done go-build=$(size_kb "$GOBUILD")KB golangci=$(size_kb "$GOLANGCI")KB elapsed=$(elapsed)s"
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
