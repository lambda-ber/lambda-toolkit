#!/usr/bin/env bash
# Locate (or install) lambda-ber-schema and print a command prefix that runs its CLI.
#
# Usage:
#   eval "$(scripts/lambda_env.sh)"      # exports LAMBDA_RUN and LAMBDA_SCHEMA_DIR
#   $LAMBDA_RUN lambda-ber-schema --help
#
# Resolution order:
#   1. $LAMBDA_BER_SCHEMA_DIR, if it points at a checkout with pyproject.toml
#   2. A checkout next to this toolkit, or in $HOME: lambda-ber-schema/
#   3. A `lambda-ber-schema` executable already on PATH
#   4. Fresh install into $LAMBDA_TOOLKIT_VENV (default ~/.cache/lambda-toolkit/venv)
#      from GitHub, since the package is not on PyPI yet.
#
# Every branch prints shell assignments on stdout and diagnostics on stderr,
# so the caller can `eval` the output safely.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
toolkit="$(dirname "$here")"
repo_url="https://github.com/lambda-ber/lambda-ber-schema.git"

emit() {
  # $1 = run prefix, $2 = schema dir (may be empty)
  printf 'export LAMBDA_RUN=%q\n' "$1"
  printf 'export LAMBDA_SCHEMA_DIR=%q\n' "$2"
}

is_checkout() {
  [[ -n "$1" && -f "$1/pyproject.toml" && -f "$1/src/lambda_ber_schema/cli.py" ]]
}

# 1. explicit env var
if is_checkout "${LAMBDA_BER_SCHEMA_DIR:-}"; then
  emit "uv run --directory $LAMBDA_BER_SCHEMA_DIR" "$LAMBDA_BER_SCHEMA_DIR"
  exit 0
fi

# 2. sibling or home checkout
for cand in "$(dirname "$toolkit")/lambda-ber-schema" "$HOME/lambda-ber-schema"; do
  if is_checkout "$cand"; then
    echo "lambda_env: using checkout at $cand" >&2
    emit "uv run --directory $cand" "$cand"
    exit 0
  fi
done

# 3. already installed
if command -v lambda-ber-schema >/dev/null 2>&1; then
  echo "lambda_env: using lambda-ber-schema on PATH" >&2
  emit "" ""
  exit 0
fi

# 4. install from GitHub
venv="${LAMBDA_TOOLKIT_VENV:-$HOME/.cache/lambda-toolkit/venv}"
if [[ ! -x "$venv/bin/lambda-ber-schema" ]]; then
  echo "lambda_env: installing lambda-ber-schema into $venv (this needs uv and network)" >&2
  command -v uv >/dev/null 2>&1 || { echo "lambda_env: uv not found; install it from https://docs.astral.sh/uv/" >&2; exit 1; }
  uv venv "$venv" >&2
  uv pip install --python "$venv/bin/python" "git+$repo_url" >&2
fi
emit "" ""
printf 'export PATH=%q:"$PATH"\n' "$venv/bin"
