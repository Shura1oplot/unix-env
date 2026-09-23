#!/usr/bin/env python3
"""Offline regression tests for the exact OpenClaw/fnm blocks in update.sh."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import TypedDict, Unpack, cast


class Scenario(TypedDict, total=False):

    fail: str
    packages: list[str]
    invalid_inventory: bool
    version: str
    no_npm: bool
    no_fnm: bool
    external_prefix: bool
    installation: str
    symlink: bool
    expect: int


class Call(TypedDict):

    tool: str
    args: list[str]
    path: str
    prefix: str | None
    repair_policy: str | None
    home: str | None


def mock(command: Path, args: list[str]) -> None:
    fixture = Path(os.environ["UPDATE_TEST_FIXTURE"])
    scenario = cast(Scenario,
                    json.loads((fixture / "scenario.json").read_text()))
    name = command.name
    entry: Call = {
        "tool": name,
        "args": args,
        "path": str(command),
        "prefix": os.environ.get("NPM_CONFIG_PREFIX"),
        "repair_policy": os.environ.get("OPENCLAW_SERVICE_REPAIR_POLICY"),
        "home": os.environ.get("HOME"),
    }

    with (fixture / "calls.jsonl").open("a") as log:
        _ = log.write(json.dumps(entry) + "\n")
    failure = scenario.get("fail", "")

    if failure and " ".join([name, *args]).startswith(failure):
        sys.exit(47)
    prefix = command.resolve().parent.parent

    if name == "fnm":
        if args[0] == "env":
            print('fnm() { "$UPDATE_TEST_FNM" "$@" || return $?;')
            print(
                'if [[ $1 == use ]]; then export PATH="$UPDATE_TEST_NEW_BIN:$PATH"; fi; }'
            )

        elif args[0] not in {"install", "default", "use"}:
            raise AssertionError(args)

    elif name == "node":
        assert args == ["-p", "process.execPath"], args
        print(command.resolve())

    elif name == "npm":
        if os.environ.get("NPM_CONFIG_PREFIX"):
            prefix = Path(os.environ["NPM_CONFIG_PREFIX"])

        if "--prefix" in args:
            prefix = Path(args[args.index("--prefix") + 1])
        inventory = prefix / "inventory.json"
        packages = cast(list[str], json.loads(inventory.read_text()))

        if args[0] == "ls":
            if scenario.get("invalid_inventory"):
                print("not json")

            else:
                print(
                    json.dumps(
                        {
                            "dependencies": {
                                p: {"version": "1.0.0"} for p in packages
                            }
                        }))

        elif args[0] in {"prefix", "root"}:
            print(
                prefix if args[0] == "prefix" else prefix / "lib/node_modules")

        elif args[0] in {"install", "update", "rebuild"}:
            names = [
                arg.rsplit("@", 1)[0] if "@" in arg[1:] else arg
                for arg in args[1:]
                if not arg.startswith("-") and not arg.startswith(str(fixture))]

            if args[0] == "install":
                assert names, ("Unbounded npm install", args)
                packages = sorted(set(packages + names))
                _ = inventory.write_text(json.dumps(packages))

            if "openclaw" in packages:
                make_tool(prefix / "bin/openclaw")

        else:
            raise AssertionError(args)

    elif name == "openclaw":
        if args[:2] == ["gateway", "status"] and "--json" in args:
            print(
                json.dumps(
                    {"cli": {"version": scenario.get("version", "2026.9.5")}}))

    elif name == "rm":
        paths = [Path(arg) for arg in args if not arg.startswith("-")]
        assert len(paths) == 1 and paths[0].is_relative_to(fixture), paths
        assert paths[0].name == "openclaw", paths
        paths[0].unlink()

    else:
        raise AssertionError((name, args))


def make_tool(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    _ = path.write_text(
        '#!/usr/bin/env bash\nexec "$UPDATE_TEST_PYTHON" "$UPDATE_TEST_SCRIPT" --mock "$0" "$@"\n'
    )
    path.chmod(0o755)


def extract_blocks(source: str) -> str:
    """Keep original lines; never execute OS/package updaters outside this scope."""
    lines = source.splitlines(keepends=True)
    selected: set[int] = set()
    starts = (
        "if command -v fnm &>/dev/null; then",
        "if command -v npm &>/dev/null; then",
        "if [[ -n $openclaw_command ]]; then")
    preamble_start = next(
        i
        for i, line in enumerate(lines)
        if line.rstrip() == "openclaw_command=")
    preamble_end = next(
        i
        for i, line in enumerate(lines)
        if line.startswith("if [[ $(id -u) == 0 ]]"))
    selected.update(range(preamble_start, preamble_end))

    for begin, line in enumerate(lines):
        if line.rstrip() not in starts:
            continue
        end = next(
            i for i in range(begin + 1, len(lines)) if lines[i].rstrip() == "fi"
        )
        selected.update(range(begin, end + 1))

    return "set -euo pipefail\n" + "".join(lines[i] for i in sorted(selected))


def run_case(name: str,
             **scenario: Unpack[Scenario]) -> tuple[int, list[Call], str]:
    with tempfile.TemporaryDirectory(
            prefix="openclaw updater test ") as temporary:
        fixture = Path(temporary).resolve()
        bin_dir = fixture / "safe bin"
        bin_dir.mkdir()

        for tool in (
                "bash",
                "jq",
                "realpath",
                "dirname",
                "readlink",
                "basename"):
            executable = shutil.which(tool)
            assert executable, f"Required test dependency missing: {tool}"
            (bin_dir / tool).symlink_to(executable)

        make_tool(bin_dir / "rm")
        old_prefix = fixture / "old node" / "installation"
        new_prefix = fixture / "new node" / "installation"
        private_prefix = fixture / "private prefix"

        for prefix in (old_prefix, new_prefix, private_prefix):
            (prefix / "bin").mkdir(parents=True)

        for prefix in (old_prefix, new_prefix):
            make_tool(prefix / "bin/node")
            make_tool(prefix / "bin/npm")
        multishell_bin = fixture / "transient multishell bin"
        multishell_bin.symlink_to(new_prefix / "bin", target_is_directory=True)

        if scenario.get("no_npm"):
            (old_prefix / "bin/npm").unlink()

        if not scenario.get("no_fnm"):
            make_tool(bin_dir / "fnm")
        installation = scenario.get("installation", "private")
        initial_prefix = new_prefix if installation == "current" else old_prefix
        packages = scenario.get("packages",
                                ["npm", "corepack", "alpha", "@scope/beta"])

        if installation in {"old", "current"} and "packages" not in scenario:
            packages = [*packages, "openclaw"]

        for inventory_prefix in (old_prefix, new_prefix, private_prefix):
            _ = (inventory_prefix / "inventory.json").write_text(
                json.dumps(
                    packages if inventory_prefix == initial_prefix else []))

        if installation != "absent":
            prefix = {
                "private": private_prefix,
                "old": old_prefix,
                "current": new_prefix,
            }[installation]
            make_tool(prefix / "bin/openclaw")

            if scenario.get("symlink"):
                (bin_dir / "openclaw").symlink_to(
                    os.path.relpath(prefix / "bin/openclaw", bin_dir))
        env = os.environ.copy()
        _ = env.pop("NPM_CONFIG_PREFIX", None)
        _ = env.pop("npm_config_prefix", None)
        env.update(
            PATH=os.pathsep.join(
                map(str,
                    (bin_dir, private_prefix / "bin", initial_prefix / "bin"))),
            FNM_DIR=str(fixture),
            NODE_VERSION="24",
            UPDATE_TEST_FIXTURE=str(fixture),
            UPDATE_TEST_PYTHON=sys.executable,
            UPDATE_TEST_SCRIPT=str(Path(__file__).resolve()),
            UPDATE_TEST_NEW_BIN=str(multishell_bin),
            UPDATE_TEST_FNM=str(bin_dir / "fnm"))

        if scenario.get("external_prefix"):
            external = fixture / "external npm prefix"
            external.mkdir()
            _ = (external / "inventory.json").write_text(json.dumps(packages))
            env["NPM_CONFIG_PREFIX"] = str(external)
        _ = (fixture / "scenario.json").write_text(json.dumps(scenario))
        script = fixture / "extracted.sh"
        _ = script.write_text(
            extract_blocks(
                (Path(__file__).resolve().parents[1] / "update.sh").read_text())
        )
        result = subprocess.run([str(bin_dir / "bash"), str(script)],
                                env=env,
                                text=True,
                                capture_output=True,
                                timeout=20,
                                check=False)
        log = fixture / "calls.jsonl"
        calls = (
            [
                cast(Call, json.loads(line))
                for line in log.read_text().splitlines()]
            if log.exists()
            else [])
        output = result.stdout + result.stderr
        expected = scenario.get("expect", 0)
        assert result.returncode == expected, (
            name,
            result.returncode,
            expected,
            output,
            calls)

        for call in calls:
            assert call["home"] == os.environ.get("HOME"), (name,
                                                            "HOME changed",
                                                            call)

            if call["tool"] == "npm" and call["args"][0] in {
                "install",
                "update",
                "rebuild",
            }:
                args = call["args"]
                packages = [
                    arg
                    for arg in args[1:]
                    if not arg.startswith("-")
                    and not arg.startswith(str(fixture))]
                assert packages, (name, "Unbounded npm mutation", call)

                if installation != "absent":
                    assert command_list(calls).index(
                        "openclaw gateway stop --force") < calls.index(call), (
                        name,
                        "Package mutated before service stop",
                        call)

                if not scenario.get("no_fnm"):
                    assert call["prefix"] == str(new_prefix) or (
                        "--prefix" in args
                        and args[args.index("--prefix") + 1] == str(new_prefix)
                    ), (name, "Wrong npm target prefix", call)

        if installation != "absent":
            original = (
                bin_dir / "openclaw"
                if scenario.get("symlink")
                else prefix / "bin/openclaw")
            migrated = any(call["tool"] == "rm" for call in calls)
            assert original.exists() != migrated, (
                name,
                "Incorrect original launcher retention")

        commands = command_list(calls)

        if expected == 0 and installation != "absent":
            health = commands.index("openclaw gateway status --require-rpc")
            service_changes = [
                i
                for i, call in enumerate(calls)
                if call["tool"] == "openclaw"
                and call["args"][:2]
                in (["gateway", "install"], ["gateway", "start"])]
            assert len(service_changes) == 1 and service_changes[0] < health, (
                name,
                commands)

            for i, call in enumerate(calls):
                if call["tool"] == "rm":
                    assert health < i, (name, commands)

                if call["tool"] == "openclaw" and call["args"][:2] == [
                        "gateway",
                        "install"]:
                    doctor = commands.index(
                        "openclaw doctor --fix --non-interactive")
                    assert doctor < i, (name, commands)
                    assert all(
                        j < doctor
                        for j, prior in enumerate(calls)
                        if prior["tool"] == "npm"
                        and prior["args"][0] in {"install", "update", "rebuild"}
                    ), (name, commands)
                    assert calls[doctor]["repair_policy"] == "external", (
                        name,
                        calls[doctor])
                    assert call["args"][-2:] == [
                        "--runtime-path",
                        str(
                            initial_prefix / "bin/node"
                            if scenario.get("no_fnm")
                            else new_prefix / "bin/node")], (name, call)

            if not scenario.get("no_fnm"):
                assert not any(
                    call["tool"] == "openclaw" and call["args"][0] == "update"
                    for call in calls), (name, commands)
                assert (new_prefix / "bin/openclaw").exists(), name

        if expected != 0:
            assert not any(call["tool"] == "rm" for call in calls), (name,
                                                                     commands)
        print(f"PASS {name}")

        return result.returncode, calls, output


def command_list(calls: list[Call]) -> list[str]:
    return [" ".join([call["tool"], *call["args"]]) for call in calls]


def main() -> None:
    _, calls, _ = run_case("private wrapper migration")
    commands = command_list(calls)
    assert next(
        i for i, command in enumerate(commands) if command.startswith("npm ls ")
    ) < commands.index("fnm env --shell bash")
    assert any(
        call["tool"] == "npm"
        and call["args"]
        == [
            "install",
            "--global",
            "openclaw",
            "--dangerously-allow-all-scripts",
            "--engine-strict"]
        for call in calls), calls

    for call in calls:
        if call["tool"] == "openclaw" and call["args"][0] in {
            "doctor",
            "update",
        }:
            assert "/new node/installation/" in call["path"], call

    _ = run_case("relative symlink launcher", symlink=True)
    _, calls, _ = run_case("private beta follows common npm policy",
                           version="2026.9.6-beta.1")
    assert not any(
        "openclaw@2026.9.6-beta.1" in call["args"] for call in calls), calls

    _, calls, _ = run_case("old fnm installation migration", installation="old")

    for operation in ("install", "update", "rebuild"):
        assert any(
            call["tool"] == "npm"
            and call["args"][0] == operation
            and {"openclaw", "alpha", "@scope/beta"}.issubset(call["args"])
            for call in calls), (operation, calls)

    _, calls, _ = run_case("current fnm installation", installation="current")
    assert not any(call["tool"] == "rm" for call in calls), calls
    _ = run_case("external npm prefix",
                 installation="old",
                 external_prefix=True)
    _ = run_case("private wrapper with external npm prefix",
                 external_prefix=True)
    _ = run_case("missing OpenClaw", installation="absent")
    _ = run_case("missing npm before fnm", no_npm=True, installation="absent")
    _ = run_case("private wrapper without npm before fnm", no_npm=True)
    _ = run_case("missing fnm and npm", no_fnm=True, no_npm=True)
    _, calls, _ = run_case("no fnm private official updater", no_fnm=True)
    commands = command_list(calls)
    assert commands.index(
        "openclaw update --yes --accept-capabilities --no-restart"
    ) < commands.index("openclaw gateway start"), commands
    _, calls, _ = run_case("no fnm npm-managed installation",
                           no_fnm=True,
                           installation="old")
    assert not any(
        call["tool"] == "openclaw" and call["args"][0] == "update"
        for call in calls), calls
    _ = run_case("no fnm no OpenClaw", no_fnm=True, installation="absent")
    _ = run_case("empty npm inventory", packages=[], installation="absent")
    _ = run_case("OpenClaw-only npm inventory",
                 packages=["openclaw"],
                 installation="old")
    _ = run_case("npm and corepack only",
                 packages=["npm", "corepack"],
                 installation="absent")
    _ = run_case("scoped package only",
                 packages=["@scope/beta"],
                 installation="absent")

    for failure in ("fnm env", "npm ls"):
        _, calls, _ = run_case(f"failure: {failure}", fail=failure, expect=47)
        assert not any(
            call["tool"] == "fnm" and call["args"][0] == "install"
            for call in calls), calls
    _, calls, _ = run_case("invalid inventory",
                           invalid_inventory=True,
                           expect=5)
    assert not any(
        call["tool"] == "fnm" and call["args"][0] == "install" for call in calls
    ), calls

    for failure in ("fnm install", "fnm default", "fnm use", "node -p"):
        _ = run_case(f"failure: {failure}", fail=failure, expect=47)

    for failure in (
            "openclaw gateway stop",
            "npm install --global",
            "npm update --global",
            "npm rebuild --global",
            "openclaw doctor",
            "openclaw gateway install",
            "openclaw gateway status --require-rpc"):
        _, calls, _ = run_case(f"failure: {failure}", fail=failure, expect=47)

    _ = run_case("failure: private install",
                 fail="npm install --global openclaw",
                 packages=[],
                 expect=47)

    for failure in ("openclaw update", "openclaw gateway start"):
        _ = run_case(f"failure without fnm: {failure}",
                     fail=failure,
                     no_fnm=True,
                     expect=47)

    _ = run_case("failure: no-fnm npm prefix",
                 fail="npm prefix",
                 no_fnm=True,
                 expect=47)

    print(
        "All offline OpenClaw updater tests passed; no real package or service operations ran."
    )


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--mock":
        mock(Path(sys.argv[2]), sys.argv[3:])

    else:
        main()
