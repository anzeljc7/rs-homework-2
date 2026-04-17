import os
import re
import csv
import math

def extract_value(text, pattern):
    m = re.search(pattern, text, re.MULTILINE)
    return m.group(1) if m else ""

rows = []

for d in sorted(os.listdir(".")):
    if not d.startswith("m5out_pprefix"):
        continue

    stats_path = os.path.join(d, "stats.txt")
    if not os.path.isfile(stats_path):
        continue

    with open(stats_path, "r", encoding="utf-8", errors="ignore") as f:
        text = f.read()

    sim_seconds = extract_value(text, r"^simSeconds\s+([0-9.eE+-]+)")
    inv_total = extract_value(text, r"^board\.cache_hierarchy\.ruby_system\.L1Cache_Controller\.Inv::total\s+([0-9.eE+-]+)")
    i_load = extract_value(text, r"^board\.cache_hierarchy\.ruby_system\.L1Cache_Controller\.I\.Load::total\s+([0-9.eE+-]+)")
    s_load = extract_value(text, r"^board\.cache_hierarchy\.ruby_system\.L1Cache_Controller\.S\.Load::total\s+([0-9.eE+-]+)")
    e_load = extract_value(text, r"^board\.cache_hierarchy\.ruby_system\.L1Cache_Controller\.E\.Load::total\s+([0-9.eE+-]+)")
    m_load = extract_value(text, r"^board\.cache_hierarchy\.ruby_system\.L1Cache_Controller\.M\.Load::total\s+([0-9.eE+-]+)")
    l1_gets = extract_value(text, r"^board\.cache_hierarchy\.ruby_system\.L2Cache_Controller\.L1_GETS\s+([0-9.eE+-]+)")
    l1_getx = extract_value(text, r"^board\.cache_hierarchy\.ruby_system\.L2Cache_Controller\.L1_GETX\s+([0-9.eE+-]+)")
    req_ctrl = extract_value(text, r"^board\.cache_hierarchy\.ruby_system\.network\.msg_count\.Request_Control\s+([0-9.eE+-]+)")
    resp_data = extract_value(text, r"^board\.cache_hierarchy\.ruby_system\.network\.msg_count\.Response_Data\s+([0-9.eE+-]+)")
    wb_data = extract_value(text, r"^board\.cache_hierarchy\.ruby_system\.network\.msg_count\.Writeback_Data\s+([0-9.eE+-]+)")

    cpis = []
    for m in re.finditer(r"^board\.processor\.cores(\d+)\.core\.cpi\s+([0-9.eE+-]+)", text, re.MULTILINE):
        cpis.append(float(m.group(2)))

    cpi_mean = ""
    cpi_std_pop = ""

    if cpis:
        cpi_mean = sum(cpis) / len(cpis)
        cpi_std_pop = math.sqrt(sum((x - cpi_mean) ** 2 for x in cpis) / len(cpis))

    rows.append({
        "run": d,
        "simSeconds": sim_seconds,
        "cpi_mean": cpi_mean,
        "cpi_std_pop": cpi_std_pop,
        "inv_total": inv_total,
        "I_Load_total": i_load,
        "S_Load_total": s_load,
        "E_Load_total": e_load,
        "M_Load_total": m_load,
        "L1_GETS": l1_gets,
        "L1_GETX": l1_getx,
        "Request_Control": req_ctrl,
        "Response_Data": resp_data,
        "Writeback_Data": wb_data,
    })

with open("task2_results.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
    writer.writeheader()
    writer.writerows(rows)

print("Written: task2_results.csv")