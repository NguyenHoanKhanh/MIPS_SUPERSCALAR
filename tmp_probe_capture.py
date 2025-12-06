from collections import OrderedDict
from pathlib import Path

VCD_PATH = Path(r"Code/MIPS_SUPERSCALAR/waveform/dtp.vcd")

# Times (in ns) we want to snapshot
INTEREST_TIMES = [75, 85, 95, 105, 115, 125, 135, 145, 155, 165, 175]

# Signals grouped roughly by functional block for easier reading
SIGNAL_GROUPS = OrderedDict([
    ("pipe1", [
        "mc1_o_addr_rs", "mc1_o_addr_rt", "mc1_o_addr_rd",
        "mc1_o_reg_write", "mc1_o_memtoreg",
        "es1_ex_stage_addr_rd", "es1_ex_stage_regwrite", "es1_ex_stage_memread",
        "fw1_o_data_rs", "fw1_o_data_rt", "fw1_o_stall",
        "mx31_1_o_data_rs", "mx31_1_o_data_rt",
    ]),
    ("pipe2", [
        "mc2_o_addr_rs", "mc2_o_addr_rt", "mc2_o_addr_rd",
        "mc2_o_reg_write", "mc2_o_memtoreg",
        "es2_ex_stage_addr_rd", "es2_ex_stage_regwrite", "es2_ex_stage_memread",
        "fw2_o_data_rs", "fw2_o_data_rt", "fw2_o_stall",
        "mx31_2_o_data_rs", "mx31_2_o_data_rt",
    ]),
    ("queue_scoreboard", [
        "qc1_o_ce_r", "qc1_o_addr_rd_r", "qc1_o_addr_rs_r", "qc1_o_addr_rt_r",
        "qc2_o_ce_r", "qc2_o_addr_rd_r", "qc2_o_addr_rs_r", "qc2_o_addr_rt_r",
        "choose_mux_1", "choose_mux_2",
        "es1_o_qc1", "es2_o_qc2",
        "qc1_operand_busy", "qc2_operand_busy",
        "ms_wb1_o_regwrite", "ms_wb1_o_memtoreg", "ms_wb1_o_addr_rd",
        "ms_wb2_o_regwrite", "ms_wb2_o_memtoreg", "ms_wb2_o_addr_rd",
        "clear_write_mask", "set_write_mask",
        "busy_load", "busy_write",
        "ds1_issue_block", "ds2_issue_block",
    ]),
])


def load_vcd_mapping(lines):
    """Build mapping from signal name to (identifier, width)."""
    mapping = {}
    for line in lines:
        if line.startswith("$var"):
            parts = line.split()
            if len(parts) >= 5:
                width = int(parts[2])
                mapping[parts[4]] = (parts[3], width)
        if line.startswith("$enddefinitions"):
            break
    return mapping


def snapshot(values, time_ns, ids_by_group):
    print(f"\n===== time {time_ns} ns =====")
    for group, ids in ids_by_group.items():
        print(f"{group}:")
        for sig, vid, _ in ids:
            val = values.get(vid, None)
            if val is None:
                print(f"  {sig:20s}: (missing)")
            else:
                print(f"  {sig:20s}: {val}")


def main():
    lines = VCD_PATH.read_text().splitlines()
    mapping = load_vcd_mapping(lines)

    ids_by_group = OrderedDict()
    missing = []
    for group, signals in SIGNAL_GROUPS.items():
        group_ids = []
        for sig in signals:
            entry = mapping.get(sig)
            if entry is None:
                missing.append(sig)
                continue
            vid, width = entry
            group_ids.append((sig, vid, width))
        ids_by_group[group] = group_ids

    if missing:
        print("Missing signals (not found in VCD):")
        for sig in missing:
            print("  ", sig)
        print()

    tracked_ids = {vid for group in ids_by_group.values() for _, vid, _ in group}
    width_by_id = {vid: width for group in ids_by_group.values() for _, vid, width in group}
    values = {vid: 0 for vid in tracked_ids}

    for line in lines:
        if not line:
            continue
        c = line[0]
        if c == "#":
            time_ns = int(line[1:])
            if time_ns in INTEREST_TIMES:
                snapshot(values, time_ns, ids_by_group)
            continue
        if c in "01":
            vid = line[1:]
            if vid in values:
                values[vid] = int(c)
        elif c == "b":
            bits, vid = line.split()
            if vid in values and "x" not in bits and "z" not in bits:
                width = width_by_id.get(vid, len(bits) - 1)
                payload = bits[1:]
                # some 1-bit signals occasionally get dumped with extra digits, so just take LSB
                if width == 1:
                    values[vid] = int(payload[-1], 2)
                else:
                    values[vid] = int(payload, 2)


if __name__ == "__main__":
    main()
