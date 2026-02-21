# spinup wrapper — source this file from .zshrc:
#   source /path/to/spinup/spinup-init.sh

spinup() {
    command "$(dirname "${(%):-%x}")/spinup.sh" "$@" || return $?
    if [ -f /tmp/.spinup-last-dir ]; then
        cd "$(cat /tmp/.spinup-last-dir)" && rm -f /tmp/.spinup-last-dir
        echo "Now in: $(pwd)"
        echo "Run 'claude' to start developing!"
    fi
}
