#!/usr/bin/env python3
"""Run the Foundation-only achievement tests without building the iOS app or a simulator."""
from pathlib import Path
import re
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / "terrariumidle_ios/Apps/Modules/Achievements/AchievementCatalog.swift").read_text()
tests = (root / "terrariumidle_iosTests/AchievementTests.swift").read_text()
tests = tests.replace("@testable import terrariumidle_ios\n", "")
names = re.findall(r"    func (test\w+)\(", tests)
runner = f"""
let suite = AchievementTests.defaultTestSuite
precondition(suite.testCaseCount == {len(names)}, "All achievement tests must be discovered")
suite.run()
guard let run = suite.testRun, run.totalFailureCount == 0 else {{ exit(1) }}
"""
with tempfile.TemporaryDirectory(prefix="terrarium-achievement-check-") as folder:
    script = Path(folder) / "Checks.swift"
    script.write_text(source + "\n" + tests + runner)
    developer = subprocess.check_output(["xcode-select", "-p"], text=True).strip()
    frameworks = Path(developer) / "Platforms/MacOSX.platform/Developer/Library/Frameworks"
    libraries = Path(developer) / "Platforms/MacOSX.platform/Developer/usr/lib"
    subprocess.run(["swift", "-F", str(frameworks), "-I", str(libraries), "-L", str(libraries), str(script)], check=True)
