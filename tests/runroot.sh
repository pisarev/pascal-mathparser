# The run root is OUTSIDE the tree being checked. It is pulled in with . (a dot).
#
# Measured on 11.08.2026: 779 binary files from runs had settled in the release tree,
# 47 of them executable, so the gate was compiling INTO the subject of publication. A
# filtered fingerprint does not see them by construction, so "the tree has not
# changed" went on agreeing while the tree was changing.
#
# The rule lives in ONE file deliberately. The same review showed three independent
# answers to the question "what goes into the release": 191, 271 and 1370 files on
# one tree; they differ precisely because there was more than one definition. Seven
# copies of this prohibition would diverge the same way.
#
#     runroot_init <tree-directory>
#
# Sets RUNROOT. Takes it from the environment if it is set, otherwise creates a
# temporary one. Refuses if the run root is physically inside the tree.

runroot_init() {
    _rr_tree=$(cd "$1" && pwd -P) || {
        echo "REFUSED: tree root does not resolve: $1" >&2
        return 1
    }

    # ${RUNROOT:-} rather than $RUNROOT: the scripts run under set -u, and touching an
    # UNSET variable brings the run down on this very line, before the rule has a chance
    # to decide anything. Found by the standing set of injected faults on 11.08.2026:
    # "runroot.sh: line 24: RUNROOT: unbound variable".
    if [ -n "${RUNROOT:-}" ]; then
        mkdir -p "$RUNROOT" || {
            echo "REFUSED: RUNROOT not created: $RUNROOT" >&2
            return 1
        }
        RUNROOT=$(cd "$RUNROOT" && pwd -P) || {
            echo "REFUSED: RUNROOT does not resolve: $RUNROOT" >&2
            return 1
        }
    else
        RUNROOT=$(mktemp -d) || {
            echo "REFUSED: temporary run root not created" >&2
            return 1
        }
    fi

    # The separation is checked PHYSICALLY, by resolved paths: a symbolic link and ..
    # lead back inside while the name looks external. Checked on Linux with a real link
    # (lrwxrwxrwx) rather than by assumption: Git Bash on Windows makes a copy instead of
    # a link and cannot express this case.
    case "$RUNROOT/" in
        "$_rr_tree"/*)
            echo "REFUSED: run root is physically INSIDE the tree under test" >&2
            echo "  tree: $_rr_tree" >&2
            echo "  root: $RUNROOT" >&2
            return 1
            ;;
    esac

    echo "run root: $RUNROOT"
    return 0
}
