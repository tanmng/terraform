#!/usr/bin/fish

# Helper function to get current command with terraform
function __fish_terraform_get_cmd
  for c in (commandline -opc)
    if not string match -q -- '-*' $c
      echo $c
    end
  end
end

function __fish_terraform_needs_command
  set cmd (__fish_terraform_get_cmd)
  if not set -q cmd[2]
    return 0
  end
  return 1
end

function __fish_terraform_all_general_action_lines
  eval $terraform_alias | grep -E "^ +"
end

function __fish_terraform_last_option_is
    set cmd (commandline -opc)
    if [ "-$argv[1]" = $cmd[-1] ]
        return 0
    end

    return 1
end

function __fish_terraform_using_command
  set index 2

  if set -q argv[2]
    set index $argv[2]
  end

  set cmd (__fish_terraform_get_cmd)

  if set -q cmd[$index]
    if [ $argv[1] = $cmd[$index] ]
      return 0
    end
  end
  return 1
end

# Check if terraform is running command $argv[1] with option $argv[2] as the last option]
function __fish_terraform_using_command_with_option
    if not set -q argv[1]
        # Parameter missing
        return 1
    end
    if not set -q argv[2]
        # Parameter missing
        return 1
    end

    __fish_terraform_using_command $argv[1]
    if [ $status -eq 1 ]
        return 1
    end

    __fish_terraform_last_option_is $argv[2]
    if [ $status -eq 1 ]
        return 1
    end

    return 0
end

# Check if a command already contain some options
function __fish_terraform_not_already_using
    # TODO: Do it you twat
end


set terraform_alias tf
alias $terraform_alias "~/bin/terraform"

complete -x -c $terraform_alias -n '__fish_terraform_needs_command' -l 'version' -s 'v' -d 'Display version number and check for update'
complete -x -c $terraform_alias -n '__fish_terraform_needs_command' -l 'help' -s 'h' -d 'Display help message'

set all_general_action_lines  (__fish_terraform_all_general_action_lines)
for general_action_line in $all_general_action_lines
    set action (echo $general_action_line | awk '{print $1}')
    set description (echo $general_action_line | awk '{ print substr($0, index($0,$2)) }')

    # Make this general_action available when no action is provided
    complete -f -c $terraform_alias -n '__fish_terraform_needs_command' -a $action -d $description

    complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -l 'help' -s 'h' -d 'Display help message'

    # Every actions that accept backup
    if contains -- $action 'apply' 'destroy' 'import' 'refresh' 'taint' 'untaint'
        complete -c $terraform_alias -n "__fish_terraform_using_command $action" -r -o 'backup' -d 'Backup state file to this path before running'
    end

    # Every actions that accept input
    if contains -- $action 'apply' 'import' 'plan' 'refresh'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'input=true' -d 'Default - Ask for value of variables'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'input=false' -d 'Do NOT ask for value of variables'
    end

    # Every actions that does NOT accept no-color
    if not contains -- $action 'console' 'fmt'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'no-color' -d 'Disable colour output'
    end

    # Every actions that accept parallelism and refresh
    if contains -- $action 'apply' 'destroy' 'plan'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'parallelism' -r -a '10 20 30' -d 'Number of max parallel operations, default 10'

        # Options for parallelism
        # complete -f -c $terraform_alias -n "__fish_terraform_using_command_with_option $action parallelism" -a '10 20 30' -d 'Number of max parallel operations, default 10'

        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'refresh=true' -d 'Default - Update state prior to checking for differences'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'refresh=false' -d 'Do NOT update state prior to checking for differences'
    end

    # Every actions that accept state
    if contains -- $action 'apply' 'console' 'destroy' 'import' 'output' 'plan' 'refresh' 'tain' 'untaint'
        complete -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'state' -r -d 'Path to state file'
    end

    # Every actions that accept state-out
    if contains -- $action 'apply' 'destroy' 'import' 'refresh' 'tain' 'untaint'
        complete -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'state-out' -r -d 'Path to new state file (preseve old one)'
    end

    # Every actions that accept target
    if contains -- $action 'apply' 'destroy' 'plan' 'refresh'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'target' -r -d 'Resources to target (can be multiple)'
    end

    # Every actions that accept var and var-file
    if contains -- $action 'apply' 'console' 'destroy' 'plan' 'push' 'refresh'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'var' -r -d 'foo=bar'
        complete -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'var-file' -r -d 'Path to var file'
    end

    # Every actions that accept var and force
    if contains -- $action 'destroy'
        complete -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'force' -d 'Force the action'
    end

    # Every actions that accept list, write and diff
    if contains -- $action 'fmt'
        complete -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'list=true' -d 'Default - List files that formatting differ'
        complete -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'list=false' -d 'Do NOT list files that formatting differ'
        complete -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'write=true' -d 'Default - Write result to source file'
        complete -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'write=false' -d 'Do NOT write result to source file'
        complete -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'diff=false' -d 'Default - Do NOT display diff of formatting changes'
        complete -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'write=true' -d 'Display diff of formatting changes'
    end

    # Every actions that accept update
    if contains -- $action 'get'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'update=false' -d 'Default - Do NOT update already downloaded modules'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'update=true' -d 'Update already downloaded modules'
    end

    # Every actions that accept draw-cycles and type
    if contains -- $action 'graph'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'draw-cycles' -d 'Colour edges of any cycles'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'type=plan' -d 'Default - Draw plan graph'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'type=plan-destroy' -d 'Draw graph of plan to destroy'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'type=apply' -d 'Draw plan to apply'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'type=legacy' -d 'Draw legacy plan'
    end

    # Every actions that accept backend and backend-config
    if contains -- $action 'init'
        # complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'backend' -r -a 'atlas artifactory azure consul etcd gcs http local manta s3 swift' -d 'Type of remote backend, default: localstorage'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'backend' -r -d 'Type of remote backend, default: local'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'backend-config' -r -d 'foo=bar'
    end

    # Every actions that accept module
    if contains -- $action 'output' 'tain' 'untaint'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'module' -r -d 'Apply to specific modules only'
    end

    # Every actions that accept json
    if contains -- $action 'output' 'tain' 'untaint'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'json' -r -d 'Output in JSON format'
    end

    # Every actions that accept destroy, detailed-exitcode and out
    if contains -- $action 'plan'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'destroy' -r -d 'Make a plan to destroy things'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'detailed-exitcode' -r -d 'Return the code'
        complete -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'out' -r -d 'Write plan to a file (can be used for apply)'
    end

    # Every actions that accept module-depth
    if contains -- $action 'plan' 'show'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'module-depth' -r -d 'Depth of modules to show in the output, default -1'
    end

    # Every actions that accept atlas-address, upload-modules, name, token, overwrite and vcs
    if contains -- $action 'push'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'atlas-address' -r -d 'An alternate address to an Atlas instance. Defaults to https://atlas.hashicorp.com'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'upload-modules' -d 'Module is locked down to current version and uploaded'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'name' -r -d 'Name of the configuration on Atlas'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'token' -r -d 'Access token to upload'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'overwrite' -r -d 'Access token to upload'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'vcs' -r -d 'Upload only files that are in our VCS'
    end

    # Every actions that accept atlas-address, upload-modules, name, token, overwrite and vcs
    if contains -- $action 'taint' 'untaint'
        complete -f -c $terraform_alias -n "__fish_terraform_using_command $action" -o 'allow-missing' -d 'Allow command to success even if resources are missing'
    end
end
