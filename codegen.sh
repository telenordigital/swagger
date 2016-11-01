#!/usr/bin/env bash
#
#                                                 .___
#   ____  ____   _____   _____ _____    ____    __| _/______
# _/ ___\/  _ \ /     \ /     \\__  \  /    \  / __ |/  ___/
# \  \__(  <_> )  Y Y  \  Y Y  \/ __ \|   |  \/ /_/ |\___ \
#  \___  >____/|__|_|  /__|_|  (____  /___|  /\____ /____  >
#      \/            \/      \/     \/     \/      \/    \/
#
# Boilerplate for creating a bash program with commands. https://github.com/alphabetum/bash-boilerplate
#
# LICENSE: MIT https://github.com/alphabetum/bash-boilerplate/blob/master/LICENSE
#
# Depends on:
#  list
#  of
#  programs
#  expected
#  in
#  environment
#
# Bash Boilerplate: https://github.com/alphabetum/bash-boilerplate
#
# Copyright (c) 2015 William Melody • hi@williammelody.com

# Notes #######################################################################

# Extensive descriptions are included for easy reference.
#
# Explicitness and clarity are generally preferable, especially since bash can
# be difficult to read. This leads to noisier, longer code, but should be
# easier to maintain. As a result, some general design preferences:
#
# - Use leading underscores on internal variable and function names in order
#   to avoid name collisions. For unintentionally global variables defined
#   without `local`, such as those defined outside of a function or
#   automatically through a `for` loop, prefix with double underscores.
# - Always use braces when referencing variables, preferring `${NAME}` instead
#   of `$NAME`. Braces are only required for variable references in some cases,
#   but the cognitive overhead involved in keeping track of which cases require
#   braces can be reduced by simply always using them.
# - Prefer `printf` over `echo`. For more information, see:
#   http://unix.stackexchange.com/a/65819
# - Prefer `$_explicit_variable_name` over names like `$var`.
# - Use the `#!/usr/bin/env bash` shebang in order to run the preferred
#   Bash version rather than hard-coding a `bash` executable path.
# - Prefer splitting statements across multiple lines rather than writing
#   one-liners.
# - Group related code into sections with large, easily scannable headers.
# - Describe behavior in comments as much as possible, assuming the reader is
#   a programmer familiar with the shell, but not experienced writing shell
#   scripts.

###############################################################################
# Strict Mode
###############################################################################

# Treat unset variables and parameters other than the special parameters ‘@’ or
# ‘*’ as an error when performing parameter expansion. An 'unbound variable'
# error message will be written to the standard error, and a non-interactive
# shell will exit.
#
# This requires using parameter expansion to test for unset variables.
#
# http://www.gnu.org/software/bash/manual/bashref.html#Shell-Parameter-Expansion
#
# The two approaches that are probably the most appropriate are:
#
# ${parameter:-word}
#   If parameter is unset or null, the expansion of word is substituted.
#   Otherwise, the value of parameter is substituted. In other words, "word"
#   acts as a default value when the value of "$parameter" is blank. If "word"
#   is not present, then the default is blank (essentially an empty string).
#
# ${parameter:?word}
#   If parameter is null or unset, the expansion of word (or a message to that
#   effect if word is not present) is written to the standard error and the
#   shell, if it is not interactive, exits. Otherwise, the value of parameter
#   is substituted.
#
# Examples
# ========
#
# Arrays:
#
#   ${some_array[@]:-}              # blank default value
#   ${some_array[*]:-}              # blank default value
#   ${some_array[0]:-}              # blank default value
#   ${some_array[0]:-default_value} # default value: the string 'default_value'
#
# Positional variables:
#
#   ${1:-alternative} # default value: the string 'alternative'
#   ${2:-}            # blank default value
#
# With an error message:
#
#   ${1:?'error message'}  # exit with 'error message' if variable is unbound
#
# Short form: set -u
set -o nounset


command_exists () {
    type "$1" &> /dev/null ;
}
if ! command_exists swagger-codegen ; then
  echo "does not exist"
  alias swagger-codegen="java -jar swagger-codegen-cli.jar"
  #add aliases
  # shopt -s expand_aliases
fi


# Exit immediately if a pipeline returns non-zero.
#
# NOTE: this has issues. When using read -rd '' with a heredoc, the exit
# status is non-zero, even though there isn't an error, and this setting
# then causes the script to exit. read -rd '' is synonymous to read -d $'\0',
# which means read until it finds a NUL byte, but it reaches the EOF (end of
# heredoc) without finding one and exits with a 1 status. Therefore, when
# reading from heredocs with set -e, there are three potential solutions:
#
# Solution 1. set +e / set -e again:
#
# set +e
# read -rd '' variable <<EOF
# EOF
# set -e
#
# Solution 2. <<EOF || true:
#
# read -rd '' variable <<EOF || true
# EOF
#
# Solution 3. Don't use set -e or set -o errexit at all.
#
# More information:
#
# https://www.mail-archive.com/bug-bash@gnu.org/msg12170.html
#
# Short form: set -e
set -o errexit

# Return value of a pipeline is the value of the last (rightmost) command to
# exit with a non-zero status, or zero if all commands in the pipeline exit
# successfully.
set -o pipefail

# Set IFS to just newline and tab at the start
#
# http://www.dwheeler.com/essays/filenames-in-shell.html
#
# $DEFAULT_IFS and $SAFER_IFS
#
# $DEFAULT_IFS contains the default $IFS value in case it's needed, such as
# when expanding an array and you want to separate elements by spaces.
# $SAFER_IFS contains the preferred settings for the program, and setting it
# separately makes it easier to switch between the two if needed.
#
# Supress ShellCheck unused variable warning:
# shellcheck disable=SC2034
DEFAULT_IFS="${IFS}"
SAFER_IFS=$'\n\t'
IFS="${SAFER_IFS}"

###############################################################################
# Globals
###############################################################################

# $_VERSION
#
# Manually set this to to current version of the program. Adhere to the
# semantic versioning specification: http://semver.org
_VERSION="0.1.0-alpha"

# $DEFAULT_COMMAND
#
# The command to be run by default, when no command name is specified. If the
# environment has an existing $DEFAULT_COMMAND set, then that value is used.
DEFAULT_COMMAND="${DEFAULT_COMMAND:-help}"

###############################################################################
# Debug
###############################################################################

# _debug()
#
# Usage:
#   _debug printf "Debug info. Variable: %s\n" "$0"
#
# A simple function for executing a specified command if the `$_USE_DEBUG`
# variable has been set. The command is expected to print a message and
# should typically be either `echo`, `printf`, or `cat`.
__DEBUG_COUNTER=0
_debug() {
  if [[ "${_USE_DEBUG:-"0"}" -eq 1 ]]
  then
    __DEBUG_COUNTER=$((__DEBUG_COUNTER+1))
    # Prefix debug message with "bug (U+1F41B)"
    printf "🐛  %s " "${__DEBUG_COUNTER}"
    "${@}"
    printf "――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――\n"
  fi
}
# debug()
#
# Usage:
#   debug "Debug info. Variable: $0"
#
# Print the specified message if the `$_USE_DEBUG` variable has been set.
#
# This is a shortcut for the _debug() function that simply echos the message.
debug() {
  _debug echo "${@}"
}

###############################################################################
# Die
###############################################################################

# _die()
#
# Usage:
#   _die printf "Error message. Variable: %s\n" "$0"
#
# A simple function for exiting with an error after executing the specified
# command. The command is expected to print a message and should typically
# be either `echo`, `printf`, or `cat`.
_die() {
  # Prefix die message with "cross mark (U+274C)", often displayed as a red x.
  printf "❌  "
  "${@}" 1>&2
  exit 1
}
# die()
#
# Usage:
#   die "Error message. Variable: $0"
#
# Exit with an error and print the specified message.
#
# This is a shortcut for the _die() function that simply echos the message.
die() {
  _die echo "${@}"
}

###############################################################################
# Options
###############################################################################

# Get raw options for any commands that expect them.
_RAW_OPTIONS="${*:-}"

# Steps:
#
# 1. set expected short options in `optstring` at beginning of the "Normalize
#    Options" section,
# 2. parse options in while loop in the "Parse Options" section.

# Normalize Options ###########################################################

# Source:
#   https://github.com/e36freak/templates/blob/master/options

# The first loop, even though it uses 'optstring', will NOT check if an
# option that takes a required argument has the argument provided. That must
# be done within the second loop and case statement, yourself. Its purpose
# is solely to determine that -oARG is split into -o ARG, and not -o -A -R -G.

# Set short options -----------------------------------------------------------

# option string, for short options.
#
# Very much like getopts, expected short options should be appended to the
# string here. Any option followed by a ':' takes a required argument.
#
# In this example, `-x` and `-h` are regular short options, while `o` is
# assumed to have an argument and will be split if joined with the string,
# meaning `-oARG` would be split to `-o ARG`.
optstring=h

# Normalize -------------------------------------------------------------------

# iterate over options, breaking -ab into -a -b and --foo=bar into --foo bar
# also turns -- into --endopts to avoid issues with things like '-o-', the '-'
# should not indicate the end of options, but be an invalid option (or the
# argument to the option, such as wget -qO-)
unset options
# while the number of arguments is greater than 0
while ((${#}))
do
  case ${1} in
    # if option is of type -ab
    -[!-]?*)
      # loop over each character starting with the second
      for ((i=1; i<${#1}; i++))
      do
        # extract 1 character from position 'i'
        c=${1:i:1}
        # add current char to options
        options+=("-${c}")

        # if option takes a required argument, and it's not the last char
        # make the rest of the string its argument
        if [[ ${optstring} = *"${c}:"* && ${1:i+1} ]]
        then
          options+=("${1:i+1}")
          break
        fi
      done
      ;;
    # if option is of type --foo=bar, split on first '='
    --?*=*)
      options+=("${1%%=*}" "${1#*=}")
      ;;
    # end of options, stop breaking them up
    --)
      options+=(--endopts)
      shift
      options+=("${@}")
      break
      ;;
    # otherwise, nothing special
    *)
      options+=("${1}")
      ;;
  esac

  shift
done
# set new positional parameters to altered options. Set default to blank.
set -- "${options[@]:-}"
unset options

# Parse Options ###############################################################

# Initialize $_COMMAND_ARGV array
#
# This array contains all of the arguments that get passed along to each
# command. This is essentially the same as the program arguments, minus those
# that have been filtered out in the program option parsing loop. This array
# is initialized with $0, which is the program's name.
_COMMAND_ARGV=("${0}")
# Initialize $_CMD and `$_USE_DEBUG`, which can continue to be blank depending
# on what the program needs.
_CMD=""
_USE_DEBUG=0

while [[ ${#} -gt 0 ]]
do
  __opt="${1}"
  shift
  case "${__opt}" in
    -h|--help)
      _CMD="help"
      ;;
    --version)
      _CMD="version"
      ;;
    --debug)
      _USE_DEBUG=1
      ;;
    *)
      # The first non-option argument is assumed to be the command name.
      # All subsequent arguments are added to $_COMMAND_ARGV.
      if [[ -n "${_CMD}" ]]
      then
        _COMMAND_ARGV+=("${__opt}")
      else
        _CMD="${__opt}"
      fi
      ;;
  esac
done

# Set $_COMMAND_PARAMETERS to $_COMMAND_ARGV, minus the initial element, $0. This
# provides an array that is equivalent to $* and $@ within each command
# function, though the array is zero-indexed, which could lead to confusion.
#
# Use `unset` to remove the first element rather than slicing (e.g.,
# `_COMMAND_PARAMETERS=("${_COMMAND_ARGV[@]:1}")`) because under bash 3.2 the
# resulting slice is treated as a quoted string and doesn't easily get coaxed
# into a new array.
_COMMAND_PARAMETERS=(${_COMMAND_ARGV[*]})
unset _COMMAND_PARAMETERS[0]

_debug printf "\${_CMD}: %s\n" "${_CMD}"
_debug printf "\${_RAW_OPTIONS} (one per line):\n%s\n" "${_RAW_OPTIONS}"
_debug printf "\${_COMMAND_ARGV[*]}: %s\n" "${_COMMAND_ARGV[*]}"
_debug printf \
  "\${_COMMAND_PARAMETERS[*]:-}: %s\n" \
  "${_COMMAND_PARAMETERS[*]:-}"

###############################################################################
# Environment
###############################################################################

# $_ME
#
# Set to the program's basename.
_ME=$(basename "${0}")

_debug printf "\${_ME}: %s\n" "${_ME}"

###############################################################################
# Load Commands
###############################################################################

# Initialize $_DEFINED_COMMANDS array.
_DEFINED_COMMANDS=()

# _load_commands()
#
# Usage:
#   _load_commands
#
# Loads all of the commands sourced in the environment.
_load_commands() {

  _debug printf "_load_commands(): entering...\n"
  _debug printf "_load_commands() declare -F:\n%s\n" "$(declare -F)"

  # declare is a bash built-in shell function that, when called with the '-F'
  # option, displays all of the functions with the format
  # `declare -f function_name`. These are then assigned as elements in the
  # $function_list array.
  local _function_list=($(declare -F))

  for __name in "${_function_list[@]}"
  do
    # Each element has the format `declare -f function_name`, so set the name
    # to only the 'function_name' part of the string.
    local _function_name
    _function_name=$(printf "%s" "${__name}" | awk '{ print $3 }')

    _debug printf \
      "_load_commands() \${_function_name}: %s\n" \
      "${_function_name}"

    # Add the function name to the $_DEFINED_COMMANDS array unless it starts
    # with an underscore or is one of the desc(), debug(), or die() functions,
    # since these are treated as having 'private' visibility.
    if ! ( [[ "${_function_name}" =~ ^_(.*)  ]] || \
           [[ "${_function_name}" == "desc"  ]] || \
           [[ "${_function_name}" == "debug" ]] || \
           [[ "${_function_name}" == "die"   ]]
    )
    then
      _DEFINED_COMMANDS+=("${_function_name}")
    fi
  done

  _debug printf \
    "commands() \${_DEFINED_COMMANDS[*]:-}:\n%s\n" \
    "${_DEFINED_COMMANDS[*]:-}"
}

###############################################################################
# Main
###############################################################################

# _main()
#
# Usage:
#   _main
#
# The primary function for starting the program.
#
# NOTE: must be called at end of program after all commands have been defined.
_main() {
  _debug printf "main(): entering...\n"
  _debug printf "main() \${_CMD} (upon entering): %s\n" "${_CMD}"

  # If $_CMD is blank, then set to `$DEFAULT_COMMAND`
  if [[ -z "${_CMD}" ]]
  then
    _CMD="${DEFAULT_COMMAND}"
  fi

  # Load all of the commands.
  _load_commands

  # If the command is defined, run it, otherwise return an error.
  if _contains "${_CMD}" "${_DEFINED_COMMANDS[*]:-}"
  then
    # Pass all comment arguments to the program except for the first ($0).
    ${_CMD} "${_COMMAND_PARAMETERS[@]:-}"
  else
    _die printf "Unknown command: %s\n" "${_CMD}"
  fi
}

###############################################################################
# Utility Functions
###############################################################################

# _function_exists()
#
# Usage:
#   _function_exists "possible_function_name"
#
# Returns:
#   0  If a function with the given name is defined in the current environment.
#   1  If not.
#
# Other implementations, some with better performance:
# http://stackoverflow.com/q/85880
_function_exists() {
  [ "$(type -t "${1}")" == 'function' ]
}

# _command_exists()
#
# Usage:
#   _command_exists "possible_command_name"
#
# Returns:
#   0  If a command with the given name is defined in the current environment.
#   1  If not.
#
# Information on why `hash` is used here:
# http://stackoverflow.com/a/677212
_command_exists() {
  hash "${1}" 2>/dev/null
}

# _contains()
#
# Usage:
#   _contains "$item" "${list[*]}"
#
# Returns:
#   0  If the item is included in the list.
#   1  If not.
_contains() {
  local _test_list=(${*:2})
  for __test_element in "${_test_list[@]:-}"
  do
    _debug printf "_contains() \${__test_element}: %s\n" "${__test_element}"
    if [[ "${__test_element}" == "${1}" ]]
    then
      _debug printf "_contains() match: %s\n" "${1}"
      return 0
    fi
  done
  return 1
}

# _join()
#
# Usage:
#   _join "," a b c
#   _join "${an_array[@]}"
#
# Returns:
#   The list or array of items joined into a string with elements divided by
#   the optional separator if one is provided.
_join() {
  local _separator
  local _target_array
  local _dirty
  local _clean
  _separator="${1}"
  _target_array=(${@:2})
  _dirty="$(printf "${_separator}%s"  "${_target_array[@]}")"
  _clean="${_dirty:${#_separator}}"
  printf "%s" "${_clean}"
}

# _command_argv_includes()
#
# Usage:
#   _command_argv_includes "an_argument"
#
# Returns:
#   0  If the argument is included in `$_COMMAND_ARGV`, the program's command
#      argument list.
#   1  If not.
#
# This is a shortcut for simple cases where a command wants to check for the
# presence of options quickly without parsing the options again.
_command_argv_includes() {
  _contains "${1}" "${_COMMAND_ARGV[*]}"
}

# _blank()
#
# Usage:
#   _blank "$an_argument"
#
# Returns:
#   0  If the argument is not present or null.
#   1  If the argument is present and not null.
_blank() {
  [[ -z "${1:-}" ]]
}

# _present()
#
# Usage:
#   _present "$an_argument"
#
# Returns:
#   0  If the argument is present and not null.
#   1  If the argument is not present or null.
_present() {
  [[ -n "${1:-}" ]]
}

# _interactive_input()
#
# Usage:
#   _interactive_input
#
# Returns:
#   0  If the current input is interactive (eg, a shell).
#   1  If the current input is stdin / piped input.
_interactive_input() {
  [[ -t 0 ]]
}

# _piped_input()
#
# Usage:
#   _piped_input
#
# Returns:
#   0  If the current input is stdin / piped input.
#   1  If the current input is interactive (eg, a shell).
_piped_input() {
  ! _interactive_input
}

###############################################################################
# desc
###############################################################################

# desc()
#
# Usage:
#   desc <name> <description>
#   desc --get <name>
#
# Options:
#   --get  Print the description for <name> if one has been set.
#
# Examples:
# ```
#   desc "list" <<HEREDOC
# Usage:
#   ${_ME} list
#
# Description:
#   List items.
# HEREDOC
#
# desc --get "list"
# ```
#
# Set or print a description for a specified command or function <name>. The
# <description> text can be passed as the second argument or as standard input.
#
# To make the <description> text available to other functions, `desc()` assigns
# the text to a variable with the format `$___desc_<name>`.
#
# When the `--get` option is used, the description for <name> is printed, if
# one has been set.
#
# NOTE:
#
# The `read` form of assignment is used for a balance of ease of
# implementation and simplicity. There is an alternative assignment form
# that could be used here:
#
# var="$(cat <<'HEREDOC'
# some message
# HEREDOC
# )
#
# However, this form appears to require trailing space after backslases to
# preserve newlines, which is unexpected. Using `read` simply requires
# escaping backslashes, which is more common.
desc() {
  set +e
  [[ -z "${1:-}" ]] && _die printf "desc(): No command name specified.\n"

  if [[ "${1}" == "--get" ]]
  then # get ------------------------------------------------------------------
    [[ -z "${2:-}" ]] && _die printf "desc(): No command name specified.\n"

    local _name="${2:-}"
    local _desc_var="___desc_${_name}"

    if [[ -n "${!_desc_var:-}" ]]
    then
      printf "%s\n" "${!_desc_var}"
    else
      printf "No additional information for \`%s\`\n" "${_name}"
    fi
  else # set ------------------------------------------------------------------
    if [[ -n "${2:-}" ]]
    then # argument is present
      read -r -d '' "___desc_${1}" <<HEREDOC
${2}
HEREDOC

      _debug printf "desc() set with argument: \${___desc_%s}\n" "${1}"
    else # no argument is present, so assume piped input
      read -r -d '' "___desc_${1}"

      _debug printf "desc() set with pipe: \${___desc_%s}\n" "${1}"
    fi
  fi
  set -e
}

###############################################################################
# Default Commands
###############################################################################

# Version #####################################################################

desc "version" <<HEREDOC
Usage:
  ${_ME} ( version | --version )

Description:
  Display the current program version.

  To save you the trouble, the current version is ${_VERSION}
HEREDOC
version() {
  printf "%s\n" "${_VERSION}"
}

# Help ########################################################################

desc "help" <<HEREDOC
Usage:
  ${_ME} help [<command>]

Description:
  Display help information for ${_ME} or a specified command.
HEREDOC
help() {
  if [[ ${#_COMMAND_ARGV[@]} = 1 ]]
  then
    cat <<HEREDOC


                 ..NMMMMN.
             .dMMMMMMH"
             MM""=!                                     _
      ...&ggdb.            _       _                   | |     _ _     _ _       _
   .gMMMMY! JMMN.         | |_ ___| |___ ___ ___ ___   | |   _| |_|___|_| |_ ___| |
 .MMMMMB!   JMMMMN.       |  _| -_| | -_|   | . |  _|  | |  | . | | . | |  _| .'| |
.MMMMM5     JMMMMMM,      |_| |___|_|___|_|_|___|_|    | |  |___|_|_  |_|_| |__,|_|
 "M#"        MMMMM#M2                                  |_|        |___|
             .MMMMMMM     
              .MMMMMM:
                ?MMM@


Tool for generating clients for the different Telenor Digital APIs, includinsg CONNECT payment (and CONNECT ID soon).
 
Version: ${_VERSION}

Usage:
  ${_ME} <command> [--command-options] [<arguments>]
  ${_ME} -h | --help
  ${_ME} --version

Options:
  -h --help      Show this screen.

Help:
  ${_ME} help [<command>]

$(commands)
HEREDOC
  else
    desc --get "${1}"
  fi
}

# Command List ################################################################

desc "commands" <<HEREDOC
Usage:
  ${_ME} commands [--raw]

Options:
  --raw  Display the command list without formatting.

Description:
  Display the list of available commands.
HEREDOC
commands() {
  if _command_argv_includes "--raw"
  then
    printf "%s\n" "${_DEFINED_COMMANDS[@]}"
  else
    printf "Available commands:\n"
    printf "  %s\n" "${_DEFINED_COMMANDS[@]}"
  fi
}

###############################################################################
# Commands
# ========.....................................................................
#
# Client command group structure:
#
# desc client "Generates client for given language, or the default Java, JavaScript, and Ruby."   - Optional. A short description for the command.
# client() { : }   - The command called by the user.
#
#
# desc client <<HEREDOC
#   Usage:
#     $_ME client
#
#   Description:
#     Print "Hello, World!"
#
#     For usage formatting conventions see:
#     - http://docopt.org/
#     - http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html
# HEREDOC
# client() {
#   printf "Hello, World!\n"
# }
#
###############################################################################

# Client Section #############################################################

# --------------------------------------------------------------------- client

desc "client" <<HEREDOC
Usage:
  ${_ME} client [<language>]

Description:
  Generates client or server in language provided. See "list" for available languages.
HEREDOC
client() {
  # These debug statements demonstrate the different behaviors of the
  # positional parameters, the special variables, and the two generated
  # command argument arrays.
  #
  # Note in particular that $@ and $* omit the script name like the
  # $_COMMAND_PARAMETERS array does, whereas the positional parameter variables
  # $0, $1, $2 do include it, like the $_COMMAND_ARGV array.
  #
  # Individual elements 0, 1, and 2 of each:
  _debug printf "client() \${0:-}: %s\n" "${0:-}"
  _debug printf "client() \${_COMMAND_ARGV[0]:-}: %s\n" "${_COMMAND_ARGV[0]:-}"
  _debug \
    printf "client() \${_COMMAND_PARAMETERS[0]:-}: %s\n" \
    "${_COMMAND_PARAMETERS[0]:-}"
  _debug printf "client() \${1:-}: %s\n" "${1:-}"
  _debug printf "client() \${_COMMAND_ARGV[1]:-}: %s\n" "${_COMMAND_ARGV[1]:-}"
  _debug \
    printf "client() \${_COMMAND_PARAMETERS[1]:-}: %s\n" \
    "${_COMMAND_PARAMETERS[1]:-}"
  _debug printf "client() \${2:-}: %s\n" "${2:-}"
  _debug printf "client() \${_COMMAND_ARGV[2]:-}: %s\n" "${_COMMAND_ARGV[2]:-}"
  _debug \
    printf "client() \${_COMMAND_PARAMETERS[2]:-}: %s\n" \
    "${_COMMAND_PARAMETERS[2]:-}"
  # Each expanded to string:
  _debug printf "client() \${*:-}: %s\n" "${*:-}"
  _debug printf "client() \${_COMMAND_ARGV[*]:-}: %s\n" "${_COMMAND_ARGV[*]:-}"
  _debug \
    printf "client() \${_COMMAND_PARAMETERS[*]:-}: %s\n" \
    "${_COMMAND_PARAMETERS[*]:-}"

  # Initialize arguments array.
  local _arguments=()

  # Parse command arguments.
  for __arg in "${_COMMAND_ARGV[@]:-}"
  do
    case ${__arg} in
      -*) _die printf "Unexpected option: %s\n" "${__arg}";;
      *) _arguments+=(${__arg});;
    esac
  done

  _debug printf "client() \${_arguments[0]:-}: %s\n" "${_arguments[0]:-}"
  _debug printf "client() \${_arguments[1]:-}: %s\n" "${_arguments[1]:-}"

  local _name=${_arguments[1]:-}

  
  _debug printf "client() \${name}: %s\n" "${_name}"
  
  local _languages=(java ruby)
  local _subdir="client"
  local _servers=( aspnet5 python-flask jaxrs jaxrs-cxf jaxrs-resteasy jaxrs-spec inflector nancyfx nodejs-server scalatra silex-PHP sinatra rails5 slim spring haskell lumen go-server )
  if [[ "${_name}" == "all-clients" ]]
  then
    printf "Generating all clients!\n"
    
    _languages=( android async-scala cwiki csharp cpprest dart flash go groovy java javascript javascript-closure-angular jmeter objc perl php python qt5cpp ruby scala dynamic-html html html2 swagger swagger-yaml swift tizen typescript-angular2 typescript-angular typescript-node typescript-fetch akka-scala CsharpDotNet2 clojure )
  elif [[ "${_name}" == "all-servers" ]]
  then
    printf "Generating all servers!\n"
    _subdir="server"
    _languages=( aspnet5 python-flask jaxrs jaxrs-cxf jaxrs-resteasy jaxrs-spec inflector nancyfx nodejs-server scalatra silex-PHP sinatra rails5 slim spring haskell lumen go-server )
  elif [[ -n "${_name}" ]]
  then
    _languages=(${_name})
    if [[ ${_servers[*]} =~ (^|[[:space:]])"${_name}"($|[[:space:]]) ]] ; then
      _subdir="server"
    fi
  fi
  
  for LANGUAGE in ${_languages[*]}
  do
    if [ ! -f ./config-files/${LANGUAGE}-config.json ]
    then
      printf "Generating ${_subdir} for %s! Config file: NO\n" "${LANGUAGE}"
      swagger-codegen generate -i ./payment-api-swagger.yml -l ${LANGUAGE} -o ./bin/${_subdir}/${LANGUAGE}/ >/dev/null 
    else
      printf "Generating ${_subdir} for %s! Config file: YES\n" "${LANGUAGE}"
      swagger-codegen generate -i ./payment-api-swagger.yml -l ${LANGUAGE} -o ./bin/${_subdir}/${LANGUAGE}/ -c ./config-files/${LANGUAGE}-config.json >/dev/null
    fi
  done
}



###############################################################################
# Commands
# ========.....................................................................
#
# List command group structure:
#
# desc list "Shows available languages for server and clients combined"   - List all languages available
# list() { : }   - The command called by the user.
#
#
# desc client <<HEREDOC
#   Usage:
#     $_ME client
#
#   Description:
#     Print "Hello, World!"
#
#     For usage formatting conventions see:
#     - http://docopt.org/
#     - http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html
# HEREDOC
# client() {
#   printf "Hello, World!\n"
# }
#
###############################################################################

# Client Section #############################################################

# --------------------------------------------------------------------- client

desc "list" <<HEREDOC
Usage:
  ${_ME} list

Description:
  Prints out all available languages
HEREDOC
list() {
  _debug printf "list() \${0:-}: %s\n" "${0:-}"
  _debug printf "list() \${_COMMAND_ARGV[0]:-}: %s\n" "${_COMMAND_ARGV[0]:-}"
  _debug \
    printf "list() \${_COMMAND_PARAMETERS[0]:-}: %s\n" \
    "${_COMMAND_PARAMETERS[0]:-}"
  _debug printf "list() \${1:-}: %s\n" "${1:-}"
  _debug printf "list() \${_COMMAND_ARGV[1]:-}: %s\n" "${_COMMAND_ARGV[1]:-}"
  _debug \
    printf "list() \${_COMMAND_PARAMETERS[1]:-}: %s\n" \
    "${_COMMAND_PARAMETERS[1]:-}"
  _debug printf "list() \${2:-}: %s\n" "${2:-}"
  _debug printf "list() \${_COMMAND_ARGV[2]:-}: %s\n" "${_COMMAND_ARGV[2]:-}"
  _debug \
    printf "list() \${_COMMAND_PARAMETERS[2]:-}: %s\n" \
    "${_COMMAND_PARAMETERS[2]:-}"
  # Each expanded to string:
  _debug printf "list() \${*:-}: %s\n" "${*:-}"
  _debug printf "list() \${_COMMAND_ARGV[*]:-}: %s\n" "${_COMMAND_ARGV[*]:-}"
  _debug \
    printf "list() \${_COMMAND_PARAMETERS[*]:-}: %s\n" \
    "${_COMMAND_PARAMETERS[*]:-}"

 
  swagger-codegen langs
}


###############################################################################
# Commands
# ========.....................................................................
#
# List command group structure:
#
# desc list "Shows available languages for server and clients combined"   - List all languages available
# list() { : }   - The command called by the user.
#
#
# desc client <<HEREDOC
#   Usage:
#     $_ME client
#
#   Description:
#     Print "Hello, World!"
#
#     For usage formatting conventions see:
#     - http://docopt.org/
#     - http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html
# HEREDOC
# client() {
#   printf "Hello, World!\n"
# }
#
###############################################################################

# Client Section #############################################################

# --------------------------------------------------------------------- client

desc "configs" <<HEREDOC
Usage:
  ${_ME} configs

Description:
  Generates basic config files for each language. Puts them in the "config-files" directory
HEREDOC
configs() {
  _debug printf "configs() \${0:-}: %s\n" "${0:-}"
  _debug printf "configs() \${_COMMAND_ARGV[0]:-}: %s\n" "${_COMMAND_ARGV[0]:-}"
  _debug \
    printf "configs() \${_COMMAND_PARAMETERS[0]:-}: %s\n" \
    "${_COMMAND_PARAMETERS[0]:-}"
  _debug printf "configs() \${1:-}: %s\n" "${1:-}"
  _debug printf "configs() \${_COMMAND_ARGV[1]:-}: %s\n" "${_COMMAND_ARGV[1]:-}"
  _debug \
    printf "configs() \${_COMMAND_PARAMETERS[1]:-}: %s\n" \
    "${_COMMAND_PARAMETERS[1]:-}"
  _debug printf "configs() \${2:-}: %s\n" "${2:-}"
  _debug printf "configs() \${_COMMAND_ARGV[2]:-}: %s\n" "${_COMMAND_ARGV[2]:-}"
  _debug \
    printf "configs() \${_COMMAND_PARAMETERS[2]:-}: %s\n" \
    "${_COMMAND_PARAMETERS[2]:-}"
  # Each expanded to string:
  _debug printf "configs() \${*:-}: %s\n" "${*:-}"
  _debug printf "configs() \${_COMMAND_ARGV[*]:-}: %s\n" "${_COMMAND_ARGV[*]:-}"
  _debug \
    printf "configs() \${_COMMAND_PARAMETERS[*]:-}: %s\n" \
    "${_COMMAND_PARAMETERS[*]:-}"

    #all languaegs
    _languages=( android async-scala cwiki csharp cpprest dart flash go groovy java javascript javascript-closure-angular jmeter objc perl php python qt5cpp ruby scala dynamic-html html html2 swagger swagger-yaml swift tizen typescript-angular2 typescript-angular typescript-node typescript-fetch akka-scala CsharpDotNet2 clojure aspnet5 python-flask jaxrs jaxrs-cxf jaxrs-resteasy jaxrs-spec inflector nancyfx nodejs-server scalatra silex-PHP sinatra rails5 slim spring haskell lumen go-server )
    mkdir -p ./config-files/
    for LANGUAGE in ${_languages[*]}
    do
      if [ ! -f "./config-files/$LANGUAGE-config.json" ]
      then
        ./config-gen.sh $LANGUAGE > ./config-files/$LANGUAGE-config.json
        echo "Configs created for $LANGUAGE"
      else
        echo "skipping $LANGUAGE"
      fi
    done

}

###############################################################################
# Run Program
###############################################################################

# Call the `_main` function after everything has been defined.
_main