# Guidelines

- Write scripts, not enterprise software
- Follow the KISS and the YAGNI principles; simplicity first
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
- Use `uv` to manage libs
- Lint: `ruff` and `basedpyright` (both mandatory), `vkus-python lint` if available
- Format (mandatory): use either `black` or `vkus-python format` (if available)
- No outdated/abandoned libraries
- Prefer `async`
- Use for cli args: `argparse.Namespace` + `pydantic.BaseModel.model_validate` -> no basedpyright warnings
- Use `pydantic-settings` if relevant
- Use `tqdm` and colored log for interactive scripts (output to tty)

## Shell

- Bash 5+
- Use GNU tools, modern cli tools; POSIX compatibility is not required
- Use bashisms (e.g., `<<<`, `&>`, `[[ ]]`)
- Use `$!/usr/bin/env bash`
- Add global `set -euo pipefail` in scripts, but not in libs (loaded using `source ./lib.sh`)
  - You can temporary turn off `-e` (`set +e`) and `-o pipefail` for a block of code if it simplifies the logic
- Avoid long and complex awk, sed, grep and jq queries; simplify if possible, or switch to Python
- Lint: use `shellcheck` (mandatory), use `vkus-bash lint` if available
- Format (mandatory): use either `shfmt` or `vkus-bash format` (if available)

# Checklist

After coding is done, check and report:

- [ ] I followed the KISS and the YAGNI principles
- [ ] I followed the guidelines
- [ ] No linting errors or warnings
- [ ] No banned techniques used
- [ ] I have cleaned up the workspace

Comment on every unchecked mark.
