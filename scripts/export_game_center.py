#!/usr/bin/env python3
"""Export the Swift source of truth to reviewable App Store Connect metadata and RGB badges.

No credentials, uploads, provisioning changes, or app builds. Requires macOS and Swift.
Run from any directory: python3 scripts/export_game_center.py
"""
import csv
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "terrariumidle_ios/Apps/Modules/Achievements/AchievementCatalog.swift"
OUTPUT = ROOT / "GameCenter"


def main():
    OUTPUT.mkdir(exist_ok=True)
    previous_file = OUTPUT / "achievements.json"
    previous = json.loads(previous_file.read_text()) if previous_file.exists() else []
    source = CATALOG.read_text() + "\n" + (ROOT / "scripts/render_game_center_badges.swift").read_text()
    with tempfile.TemporaryDirectory(prefix="terrarium-achievements-") as folder:
        script = Path(folder) / "Export.swift"
        script.write_text(source)
        subprocess.run(["swift", str(script), str(OUTPUT)], check=True)
    entries = json.loads((OUTPUT / "achievements.json").read_text())
    current_ids = {item["id"] for item in entries}
    for old in previous:
        identifier = old["id"]
        if identifier not in current_ids and identifier.startswith("terrarium.achievement.") and "/" not in identifier:
            (OUTPUT / "Badges" / (identifier + ".png")).unlink(missing_ok=True)
    assert len(entries) <= 100 and len({a["id"] for a in entries}) == len(entries)
    assert sum(a["points"] for a in entries) <= 1000
    with (OUTPUT / "app-store-connect.csv").open("w", newline="", encoding="utf-8-sig") as output:
        fields = ["achievementID", "referenceName", "points", "hidden", "repeatable", "locale",
                  "displayName", "preEarnedDescription", "earnedDescription", "image"]
        writer = csv.DictWriter(output, fieldnames=fields)
        writer.writeheader()
        for item in entries:
            for locale, suffix in [("vi", "VI"), ("en-US", "EN")]:
                description = item["description" + suffix]
                writer.writerow(dict(achievementID=item["id"], referenceName=item["titleEN"],
                                     points=item["points"], hidden="false", repeatable="false", locale=locale,
                                     displayName=item["title" + suffix], preEarnedDescription=description,
                                     earnedDescription=("Đã hoàn tất! " if locale == "vi" else "Completed! ") + description,
                                     image=f"Badges/{item['id']}.png"))
    total_points = sum(a["points"] for a in entries)
    reserved_count = 100 - len(entries)
    reserved_points = 1000 - total_points
    lines = ["# Danh mục thành tích Game Center", "", f"{len(entries)} thành tích · 19 nhóm · {total_points} điểm. Dự phòng {reserved_count} thành tích / {reserved_points} điểm.", "",
             "Sinh từ `AchievementCatalog.swift` bằng `python3 scripts/export_game_center.py`.", "",
             "| ID | Tên | Điều kiện | Điểm |", "|---|---|---|---:|"]
    lines += [f"| `{a['id']}` | {a['titleVI']} | {a['descriptionVI']} | {a['points']} |" for a in entries]
    (OUTPUT / "CATALOG.md").write_text("\n".join(lines) + "\n")
    print(f"Exported {len(entries)} achievements, {len(entries) * 2} localization rows and {len(entries)} badges to {OUTPUT}")


if __name__ == "__main__":
    main()
