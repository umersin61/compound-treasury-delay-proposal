"""Regenerate in isolation; verify executable fields without rewriting historical evidence."""
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as directory:
    stage = Path(directory)
    shutil.copy(ROOT / "build_payloads.py", stage)
    subprocess.run([sys.executable, str(stage / "build_payloads.py")], check=True)
    for name in ("transactions.json", "proposal-1.json", "proposal-2.json"):
        assert json.loads((stage / name).read_text()) == json.loads((ROOT / name).read_text()), name
    for prefix in ("proposal-1", "proposal-2"):
        name = prefix + "-submission.json"
        expected = json.loads((ROOT / name).read_text())
        actual = json.loads((stage / name).read_text())
        expected.pop("status", None)
        actual.pop("status", None)
        assert actual == expected, name
        name = prefix + "-description.txt"
        assert (stage / name).read_bytes() == (ROOT / name).read_bytes(), name
print("PASS: deterministic regeneration of both unsigned submissions and every action.")
