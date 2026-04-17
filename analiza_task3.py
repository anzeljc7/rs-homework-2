import os
import re
import csv

def extract_value(text, pattern):
    m = re.search(pattern, text, re.MULTILINE)
    return m.group(1) if m else ""

def detect_topology(run_name: str) -> str:
    name = run_name.lower()

    if "crossbar" in name:
        return "crossbar"
    if "circle" in name or "ring" in name:
        return "ring"
    if "pt2pt" in name or "point" in name or "simple" in name:
        return "point-to-point"

    return "unknown"

def detect_cores(run_name: str) -> str:
    m = re.search(r'(\d+)\s*cores?', run_name.lower())
    if m:
        return m.group(1)

    m = re.search(r'_(\d+)_', run_name.lower())
    if m:
        return m.group(1)

    return ""

rows = []

for d in sorted(os.listdir(".")):
    if not d.startswith("m5out_network"):
        continue

    stats_path = os.path.join(d, "stats.txt")
    if not os.path.isfile(stats_path):
        continue

    with open(stats_path, "r", encoding="utf-8", errors="ignore") as f:
        text = f.read()

    req_ctrl = extract_value(
        text,
        r"^board\.cache_hierarchy\.ruby_system\.network\.msg_count\.Request_Control\s+([0-9.eE+-]+)"
    )
    resp_data = extract_value(
        text,
        r"^board\.cache_hierarchy\.ruby_system\.network\.msg_count\.Response_Data\s+([0-9.eE+-]+)"
    )
    wb_data = extract_value(
        text,
        r"^board\.cache_hierarchy\.ruby_system\.network\.msg_count\.Writeback_Data\s+([0-9.eE+-]+)"
    )

    rows.append({
        "run": d,
        "topology": detect_topology(d),
        "cores": detect_cores(d),
        "Request_Control": req_ctrl,
        "Response_Data": resp_data,
        "Writeback_Data": wb_data,
    })

rows.sort(key=lambda r: (r["topology"], int(r["cores"]) if r["cores"].isdigit() else 9999, r["run"]))

with open("task3_results.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(
        f,
        fieldnames=["run", "topology", "cores", "Request_Control", "Response_Data", "Writeback_Data"]
    )
    writer.writeheader()
    writer.writerows(rows)

print("Written: task3_results.csv")
for row in rows:
    print(row)