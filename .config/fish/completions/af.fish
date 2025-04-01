# Print an optspec for argparse to handle cmd's options that are independent of any subcommand.
function __fish_af_global_optspecs
	string join \n v/verbose q/quiet debug h/help V/version
end

function __fish_af_needs_command
	# Figure out if the current invocation already has a command.
	set -l cmd (commandline -opc)
	set -e cmd[1]
	argparse -s (__fish_af_global_optspecs) -- $cmd 2>/dev/null
	or return
	if set -q argv[1]
		# Also print the command, so this can be used to figure out what it is.
		echo $argv[1]
		return 1
	end
	return 0
end

function __fish_af_using_subcommand
	set -l cmd (__fish_af_needs_command)
	test -z "$cmd"
	and return 1
	contains -- $cmd[1] $argv
end

complete -c af -n "__fish_af_needs_command" -s v -l verbose -d 'Increase logging verbosity'
complete -c af -n "__fish_af_needs_command" -s q -l quiet -d 'Decrease logging verbosity'
complete -c af -n "__fish_af_needs_command" -l debug
complete -c af -n "__fish_af_needs_command" -s h -l help -d 'Print help'
complete -c af -n "__fish_af_needs_command" -s V -l version -d 'Print version'
complete -c af -n "__fish_af_needs_command" -f -a "completions" -d 'Generate shell completions'
complete -c af -n "__fish_af_needs_command" -f -a "git" -d 'Collection of helper subcommands for git'
complete -c af -n "__fish_af_needs_command" -f -a "pgc" -d 'Clone Project'
complete -c af -n "__fish_af_needs_command" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c af -n "__fish_af_using_subcommand completions" -s v -l verbose -d 'Increase logging verbosity'
complete -c af -n "__fish_af_using_subcommand completions" -s q -l quiet -d 'Decrease logging verbosity'
complete -c af -n "__fish_af_using_subcommand completions" -l debug
complete -c af -n "__fish_af_using_subcommand completions" -s h -l help -d 'Print help'
complete -c af -n "__fish_af_using_subcommand git; and not __fish_seen_subcommand_from clone-project cp help" -s v -l verbose -d 'Increase logging verbosity'
complete -c af -n "__fish_af_using_subcommand git; and not __fish_seen_subcommand_from clone-project cp help" -s q -l quiet -d 'Decrease logging verbosity'
complete -c af -n "__fish_af_using_subcommand git; and not __fish_seen_subcommand_from clone-project cp help" -l debug
complete -c af -n "__fish_af_using_subcommand git; and not __fish_seen_subcommand_from clone-project cp help" -s h -l help -d 'Print help'
complete -c af -n "__fish_af_using_subcommand git; and not __fish_seen_subcommand_from clone-project cp help" -f -a "clone-project" -d 'Clone Project'
complete -c af -n "__fish_af_using_subcommand git; and not __fish_seen_subcommand_from clone-project cp help" -f -a "cp" -d 'Clone Project'
complete -c af -n "__fish_af_using_subcommand git; and not __fish_seen_subcommand_from clone-project cp help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c af -n "__fish_af_using_subcommand git; and __fish_seen_subcommand_from clone-project" -l open-ide -d 'Should open the repository in matching IDE (if found and available)' -r -f -a "true\t''
false\t''"
complete -c af -n "__fish_af_using_subcommand git; and __fish_seen_subcommand_from clone-project" -l root-directory -r -f -a "(__fish_complete_directories)"
complete -c af -n "__fish_af_using_subcommand git; and __fish_seen_subcommand_from clone-project" -l directory -r -f -a "(__fish_complete_directories)"
complete -c af -n "__fish_af_using_subcommand git; and __fish_seen_subcommand_from clone-project" -l rename-origin -r -f -a "true\t''
false\t''"
complete -c af -n "__fish_af_using_subcommand git; and __fish_seen_subcommand_from clone-project" -s f -l force
complete -c af -n "__fish_af_using_subcommand git; and __fish_seen_subcommand_from clone-project" -s v -l verbose -d 'Increase logging verbosity'
complete -c af -n "__fish_af_using_subcommand git; and __fish_seen_subcommand_from clone-project" -s q -l quiet -d 'Decrease logging verbosity'
complete -c af -n "__fish_af_using_subcommand git; and __fish_seen_subcommand_from clone-project" -l debug
complete -c af -n "__fish_af_using_subcommand git; and __fish_seen_subcommand_from clone-project" -s h -l help -d 'Print help'
complete -c af -n "__fish_af_using_subcommand git; and __fish_seen_subcommand_from cp" -l open-ide -d 'Should open the repository in matching IDE (if found and available)' -r -f -a "true\t''
false\t''"
complete -c af -n "__fish_af_using_subcommand git; and __fish_seen_subcommand_from cp" -l root-directory -r -f -a "(__fish_complete_directories)"
complete -c af -n "__fish_af_using_subcommand git; and __fish_seen_subcommand_from cp" -l directory -r -f -a "(__fish_complete_directories)"
complete -c af -n "__fish_af_using_subcommand git; and __fish_seen_subcommand_from cp" -l rename-origin -r -f -a "true\t''
false\t''"
complete -c af -n "__fish_af_using_subcommand git; and __fish_seen_subcommand_from cp" -s f -l force
complete -c af -n "__fish_af_using_subcommand git; and __fish_seen_subcommand_from cp" -s v -l verbose -d 'Increase logging verbosity'
complete -c af -n "__fish_af_using_subcommand git; and __fish_seen_subcommand_from cp" -s q -l quiet -d 'Decrease logging verbosity'
complete -c af -n "__fish_af_using_subcommand git; and __fish_seen_subcommand_from cp" -l debug
complete -c af -n "__fish_af_using_subcommand git; and __fish_seen_subcommand_from cp" -s h -l help -d 'Print help'
complete -c af -n "__fish_af_using_subcommand git; and __fish_seen_subcommand_from help" -f -a "clone-project" -d 'Clone Project'
complete -c af -n "__fish_af_using_subcommand git; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c af -n "__fish_af_using_subcommand pgc" -l open-ide -d 'Should open the repository in matching IDE (if found and available)' -r -f -a "true\t''
false\t''"
complete -c af -n "__fish_af_using_subcommand pgc" -l root-directory -r -f -a "(__fish_complete_directories)"
complete -c af -n "__fish_af_using_subcommand pgc" -l directory -r -f -a "(__fish_complete_directories)"
complete -c af -n "__fish_af_using_subcommand pgc" -l rename-origin -r -f -a "true\t''
false\t''"
complete -c af -n "__fish_af_using_subcommand pgc" -s f -l force
complete -c af -n "__fish_af_using_subcommand pgc" -s v -l verbose -d 'Increase logging verbosity'
complete -c af -n "__fish_af_using_subcommand pgc" -s q -l quiet -d 'Decrease logging verbosity'
complete -c af -n "__fish_af_using_subcommand pgc" -l debug
complete -c af -n "__fish_af_using_subcommand pgc" -s h -l help -d 'Print help'
complete -c af -n "__fish_af_using_subcommand help; and not __fish_seen_subcommand_from completions git pgc help" -f -a "completions" -d 'Generate shell completions'
complete -c af -n "__fish_af_using_subcommand help; and not __fish_seen_subcommand_from completions git pgc help" -f -a "git" -d 'Collection of helper subcommands for git'
complete -c af -n "__fish_af_using_subcommand help; and not __fish_seen_subcommand_from completions git pgc help" -f -a "pgc" -d 'Clone Project'
complete -c af -n "__fish_af_using_subcommand help; and not __fish_seen_subcommand_from completions git pgc help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c af -n "__fish_af_using_subcommand help; and __fish_seen_subcommand_from git" -f -a "clone-project" -d 'Clone Project'
