# shellcheck shell=sh
# Filter PATH to existing directories, preserving order and dropping duplicates.
#
# Sourced from bash and zsh startup files after path_helper and mise. macOS
# path_helper reads /etc/paths.d, which can add directories that do not exist
# (Apple cryptexd bootstrap paths and /pkg/env/global/bin). libuv and
# posix_spawnp try posix_spawn once per PATH entry; each miss from a
# provenance-tracked app logs a syspolicyd qtn_proc error.
#
# POSIX and zsh-safe: no word-splitting, so it works when zsh is not in
# sh-word-split mode. Safe to source more than once.

filter_existing_path() {
  _fep_new=""
  _fep_rest="${PATH-}"

  while [ -n "$_fep_rest" ]; do
    _fep_dir="${_fep_rest%%:*}"
    if [ "$_fep_dir" = "$_fep_rest" ]; then
      _fep_rest=""
    else
      _fep_rest="${_fep_rest#*:}"
    fi

    # Skip empty components from leading, trailing, or doubled colons.
    [ -n "$_fep_dir" ] || continue
    [ -d "$_fep_dir" ] || continue

    case ":${_fep_new}:" in
      *":${_fep_dir}:"*) continue ;;
      *) ;;
    esac

    if [ -n "$_fep_new" ]; then
      _fep_new="${_fep_new}:${_fep_dir}"
    else
      _fep_new="${_fep_dir}"
    fi
  done

  PATH="${_fep_new}"
  export PATH
  unset _fep_new _fep_rest _fep_dir
}

filter_existing_path
