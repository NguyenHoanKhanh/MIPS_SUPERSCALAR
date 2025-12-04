from pathlib import Path
lines = Path('Code/MIPS_SUPERSCALAR/waveform/dtp.vcd').read_text().splitlines()
name_to_id = {}
for line in lines:
    if line.startswith(''):
        parts = line.split()
        if len(parts) < 5:
            continue
        name = parts[4]
        var_id = parts[3]
        name_to_id[name] = var_id
    if line.startswith(''):
        break
signals = {name_to_id[name]: name for name in ['ds1_issue_stall','ds1_scoreboard_block','ds1_scoreboard_rs_block','busy_alu','mc1_o_ce','mc1_o_addr_rd']}
values = {vid:0 for vid in signals}
record = [55,65,75,85,95]
for line in lines:
    if not line:
        continue
    if line[0] == '#':
        t = int(line[1:])
        if t in record:
            print('time', t, {name: values[vid] for vid,name in signals.items()})
        continue
    if line[0] in '01':
        vid = line[1:]
        if vid in values:
            values[vid] = int(line[0])
    elif line[0] == 'b':
        parts = line.split()
        val_str = parts[0][1:]
        vid = parts[1]
        if vid in values and 'x' not in val_str.lower():
            values[vid] = int(val_str, 2)
