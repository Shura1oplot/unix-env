# Guidelines

- Write scripts, not enterprise software
- Follow the KISS principle; simplicity first
- Hard cutover; no backward compatibility
- Surgical changes; edit only what you must:
  - No features or flexibility beyond what was asked
  - No abstractions for single-use code
  - No configurability that was not requested
- Refer to `karpathy-guidelines` skill
- No outdated/abandoned libraries

## Data

- Always start by defining data models (e.g., `pydantic` for Python) and aligning them with the users
- Process any JSON-like objects through models
- `jq` for JSON in Bash

## Before coding

- Fetch up-to-date documentation from Context7 and DeepWiki, and consult the official documentation
- If users ask to implement or fix something marked with `CODEX:`, `CLAUDE:`, `FIXME:` or `TODO:` in a file, read the file, build a checklist, execute, and report using the checklist

# After coding

- Check that the code follows the coding guidelines and quality standards
- Verify the codebase does not contain the forbidden techniques
- Refactor if needed
- Keep the workspace tidy

# Forbidden techniques

- Silent error/warning drops
  - Including logging without reraising an exception
- Broad exception catching
- Any kind of fallback
- Monkey patching
- Silencing linter messages
- Type casts (e.g., `typing.cast` in Python)
- Mixing different programming languages in a single file (e.g., long awk script call inside bash script file)

## Language-specific

## Python

- Python 3.13+
- `uv` to manage libs
- Lint: `ruff` and `basedpyright`
- Format with `black`
- No outdated/abandoned libraries
- Prefer async

## Shell

- Bash 4+
- Use GNU tools, modern cli tools; POSIX compatibility does not required
- Bashisms are preferable (e.g., `<<<`, `&>`, `[[ ]]`)
- Use `$!/usr/bin/env bash`
- `set -euo pipefail` is a must
  - You can temporary turn off `-e` (`set +e`) and `-o pipefail` for a block of code if it simplifies the logic
- Avoid long and complex awk, sed, grep and jq scripts

# Checklist

After coding is done, check and report:

- [ ] I followed the KISS principle
- [ ] No banned techniques used
- [ ] No linting errors or warnings
- [ ] I have cleaned up the workspace

Comment on every unchecked mark
