#!/usr/bin/env bash
set -euo pipefail

# Run inside ros-gazebo after colcon build.
# This patches generated launch files under install/ and, when available, source files too.

WORKSPACE="${LIMX_WS:-$HOME/limx_ws}"
python3 - <<'PY'
from pathlib import Path
import re
import os
import sys

workspace = Path(os.environ.get("LIMX_WS", str(Path.home() / "limx_ws"))).expanduser()
patterns = [
    workspace / "install" / "pointfoot_gazebo" / "share" / "pointfoot_gazebo" / "launch" / "empty_world.launch.py",
]
patterns.extend(workspace.glob("src/**/empty_world.launch.py"))

changed = []
for path in dict.fromkeys(patterns):
    if not path.exists():
        continue
    text = path.read_text()
    new = re.sub(
        r'("use_support:=",\s*)\n?\s*([\"\'])(false|False|0)\2',
        r'\1\n    "true"',
        text,
        count=1,
    )
    if new == text:
        new = text.replace("'false',   # 29行目をtrueに変更するとロボットにサポートが追加される", "'true',   # patched by robot-sim-docker")
        new = new.replace('"false",   # 29行目をtrueに変更するとロボットにサポートが追加される', '"true",   # patched by robot-sim-docker')
    if new != text:
        path.write_text(new)
        changed.append(str(path))

if not changed:
    print("[WARN] empty_world.launch.py was not found or no use_support=false pattern matched.")
    print(f"       workspace searched: {workspace}")
    sys.exit(0)

print("[OK] patched use_support=true in:")
for item in changed:
    print(f"  - {item}")
PY
