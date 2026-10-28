# Shell integration for the `secrets` CLI, lifted from the block its installer appends to
# ~/.zshrc. Skipped on hosts where the binary isn't installed.
[[ -x "$HOME/.local/bin/secrets" ]] || return 0

# Ensure ~/.local/bin is in PATH (where the secrets binary lives)
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
secrets() {
  local _out _exit _activate
  # Create a temp file the binary may write export lines to (auto-activation
  # for init / paste / setup). Sourced after the binary exits.
  _activate="$(mktemp -t secrets-activate.XXXXXX 2>/dev/null)"
  case "$1" in
    paste|setup|wizard)
      SECRETS_ACTIVATE_FILE="$_activate" command secrets "$@"
      _exit=$?
      ;;
    unseal|seal|rename|mv|remove|rm)
      _out="$(SECRETS_ACTIVATE_FILE="$_activate" command secrets "$@")"
      _exit=$?
      eval "$_out"
      ;;
    *)
      _out="$(SECRETS_ACTIVATE_FILE="$_activate" command secrets "$@")"
      _exit=$?
      [ -n "$_out" ] && printf '%s\n' "$_out"
      ;;
  esac
  if [ -n "$_activate" ] && [ -s "$_activate" ]; then
    eval "$(cat "$_activate")"
  fi
  [ -n "$_activate" ] && rm -f "$_activate"
  return $_exit
}
# secrets tab completion
_secrets_zsh_complete() {
  local state
  _arguments -C '1:cmd:->cmd' '*:: :->args'
  case $state in
    cmd)
      _describe 'command' '(
        list:"List profiles"
        unseal:"Decrypt and export env vars"
        seal:"Unset env vars"
        show:"Show profile metadata"
        reveal:"Decrypt to plaintext file"
        remove:"Remove a profile"
        rename:"Rename a profile"
        setup:"Interactive wizard"
        paste:"Secure key=value capture"
        install:"Add shell integration"
        ksm:"Keeper Secrets Manager commands"
        env:"Env file commands"
        completion:"Print completion script"
        version:"Print version"
        help:"Show help"
      )'
      ;;
    args)
      case $words[1] in
        env)
          if (( ${#words[@]} == 2 )); then
            _describe 'subcommand' '(init:"Encrypt .env file" init-values:"Encrypt values only" add:"Add KEY=VALUE")'
          elif (( ${#words[@]} == 4 )) && [[ $words[2] == init* ]]; then
            _files
          fi
          ;;
        ksm)
          if (( ${#words[@]} == 2 )); then
            _describe 'subcommand' '(init:"Register profile" add:"Create vault record")'
          elif (( ${#words[@]} == 4 )) && [[ $words[2] == init && $words[3] != --token ]]; then
            _files -g '*.ini'
          fi
          ;;
        unseal|seal|show|reveal|remove|rm|rename|mv|paste)
          local profiles
          profiles=(${(f)"$(command secrets list 2>/dev/null | awk 'NR>2 && $1!="" {print $1}')"})
          [[ ${#profiles[@]} -gt 0 ]] && _describe 'profile' profiles
          ;;
        completion)
          _values 'shell' zsh bash fish
          ;;
      esac
      ;;
  esac
}
# Register completion only when zsh's compinit has been loaded (compdef is a
# function that compinit installs). Without this guard, sourcing .zshrc on a
# shell that hasn't run compinit yet errors with "command not found: compdef".
if typeset -f compdef >/dev/null 2>&1; then
  compdef _secrets_zsh_complete secrets
fi
