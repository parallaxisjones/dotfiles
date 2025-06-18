# Temporarily disable options that could affect parsing or evaluation.
builtin local -a p10k_config_opts
[[ ! -o aliases         ]] || p10k_config_opts+=('aliases')
[[ ! -o sh_glob         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o no_brace_expand ]] || p10k_config_opts+=('no_brace_expand')
builtin setopt no_aliases no_sh_glob brace_expand

() {
  emulate -L zsh
  setopt no_unset

  autoload -Uz is-at-least && is-at-least 5.1 || return
  unset -m 'POWERLEVEL9K_*'

  ##############
  # Prompt Segments
  ##############

  # Left prompt: from left to right
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
      dir                     # current directory
      vcs                     # git status
      context                 # user@host (only shown when root or over SSH)
      command_execution_time  # how long the last command took (if long enough)
      virtualenv              # python venv
      prompt_char             # ➤ or ❮ depending on mode
  )

  # Right prompt: shown on right edge
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
      nix_shell_with_name     # current nix shell environment
  )

  ##############
  # Appearance
  ##############

  typeset -g POWERLEVEL9K_MODE=nerdfont-complete           # use Nerd Font icons
  typeset -g POWERLEVEL9K_ICON_PADDING=none                # remove space after icons

  # Prompt spacing and separators
  typeset -g POWERLEVEL9K_BACKGROUND=                      # transparent background
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
  typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION=

  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true          # extra newline above prompt

  ##############
  # Prompt Char Colors
  ##############

  # Green for success, red for error
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS}_FOREGROUND=green
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS}_FOREGROUND=red

  # Prompt char symbols depending on vi mode
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=false

  ##############
  # Virtualenv
  ##############

  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=cyan       # brighter than gray
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
  typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=

  ##############
  # Current Directory
  ##############

  typeset -g POWERLEVEL9K_DIR_FOREGROUND=cyan

  ##############
  # Context (user@host)
  ##############

  typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE='%white%n%f%cyan@%m%f'
  typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE='%cyan%n@%m%f'
  typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_CONTENT_EXPANSION=

  ##############
  # Command Duration
  ##############

  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=5
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=yellow

  ##############
  # Git Segment Colors and Format
  ##############

  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON='\uF126 '
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='?'

  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=green
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=yellow
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=blue
  typeset -g POWERLEVEL9K_VCS_CONFLICTED_FOREGROUND=red
  typeset -g POWERLEVEL9K_VCS_LOADING_FOREGROUND=gray

  typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_COLOR=cyan
  typeset -g POWERLEVEL9K_VCS_LOADING_VISUAL_IDENTIFIER_COLOR=gray

  typeset -g POWERLEVEL9K_VCS_BACKENDS=(git)
  typeset -g POWERLEVEL9K_VCS_DISABLE_GITSTATUS_FORMATTING=true

  # Custom git formatter (called automatically)
  function my_git_formatter() {
    emulate -L zsh

    if [[ -n $P9K_CONTENT ]]; then
      typeset -g my_git_format=$P9K_CONTENT
      return
    fi

    if (( $1 )); then
      local meta='%f'
      local clean='%F{green}'
      local modified='%F{yellow}'
      local untracked='%F{blue}'
      local conflicted='%F{red}'
    else
      local meta='%F{244}'
      local clean=$meta
      local modified=$meta
      local untracked=$meta
      local conflicted=$meta
    fi

    local res branch tag
    branch=${(V)VCS_STATUS_LOCAL_BRANCH}
    (( $#branch > 32 )) && branch[13,-13]="…"

    if (( VCS_STATUS_HAS_CONFLICTED )); then
      res+="${conflicted}${(g::)POWERLEVEL9K_VCS_BRANCH_ICON}${branch//\%/%%}"
    elif (( VCS_STATUS_HAS_STAGED || VCS_STATUS_HAS_UNSTAGED )); then
      res+="${modified}${(g::)POWERLEVEL9K_VCS_BRANCH_ICON}${branch//\%/%%}"
    elif (( VCS_STATUS_HAS_UNTRACKED )); then
      res+="${untracked}${(g::)POWERLEVEL9K_VCS_BRANCH_ICON}${branch//\%/%%}"
    else
      res+="${clean}${(g::)POWERLEVEL9K_VCS_BRANCH_ICON}${branch//\%/%%}"
    fi

    if [[ -n $VCS_STATUS_TAG && -z $VCS_STATUS_LOCAL_BRANCH ]]; then
      tag=${(V)VCS_STATUS_TAG}
      (( $#tag > 32 )) && tag[13,-13]="…"
      res+="${meta}#${clean}${tag//\%/%%}"
    fi

    [[ -z $VCS_STATUS_LOCAL_BRANCH && -z $VCS_STATUS_TAG ]] &&
      res+="${meta}@${clean}${VCS_STATUS_COMMIT[1,8]}"

    if [[ -n ${VCS_STATUS_REMOTE_BRANCH:#$VCS_STATUS_LOCAL_BRANCH} ]]; then
      res+="${meta}:${clean}${(V)VCS_STATUS_REMOTE_BRANCH//\%/%%}"
    fi

    typeset -g my_git_format=$res
  }

  functions -M my_git_formatter 2>/dev/null
  typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${$((my_git_formatter(1)))+${my_git_format}}'
  typeset -g POWERLEVEL9K_VCS_LOADING_CONTENT_EXPANSION='${$((my_git_formatter(0)))+${my_git_format}}'

  # Git performance tweaks
  typeset -g POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=-1
  typeset -g POWERLEVEL9K_VCS_DISABLED_WORKDIR_PATTERN='~'
  typeset -g POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS=0

  # Git symbol configuration
  typeset -g POWERLEVEL9K_VCS_COMMIT_ICON='@'
  typeset -g POWERLEVEL9K_VCS_DIRTY_ICON='*'
  typeset -g POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON='⇣'
  typeset -g POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON='⇡'
  typeset -g POWERLEVEL9K_VCS_{COMMITS_AHEAD,COMMITS_BEHIND}_MAX_NUM=1

  ##############
  # Nix Shell
  ##############

  typeset -g POWERLEVEL9K_NIX_SHELL_FOREGROUND=white
  typeset -g POWERLEVEL9K_NIX_SHELL_BACKGROUND=magenta
  typeset -g POWERLEVEL9K_NIX_SHELL_CONTENT_EXPANSION=

  function prompt_nix_shell_with_name() {
    if [[ -n "${IN_NIX_SHELL-}" ]]; then
      if [[ "${name-nix-shell}" != nix-shell ]] && [ "${name-shell}" != shell ]; then
        p10k segment -b 5 -f 15 -r -i NIX_SHELL_ICON -t "$name"
      else
        p10k segment -b 5 -f 15 -r -i NIX_SHELL_ICON
      fi
    fi
  }

  ##############
  # Misc Options
  ##############

  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true

  (( ! $+functions[p10k] )) || p10k reload
}

# Restore original options
(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
builtin unset p10k_config_opts
