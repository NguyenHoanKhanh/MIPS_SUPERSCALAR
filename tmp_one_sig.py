from pathlib import Path
path = Path(r"Code/MIPS_SUPERSCALAR/waveform/dtp.vcd")
lines = path.read_text().splitlines()
name_to_id = {}
for line in lines:
    if line.startswith('$var'):
        parts = line.split()
        if len(parts) >= 5:
            name_to_id[parts[4]] = parts[3]
    if line.startswith('$enddefinitions'):
        break
sig_id = name_to_id['es1_ms_o_addr_rd']
current_time = 0
for line in lines:
    if not line:
        continue
    if line[0] == '#':
        current_time = int(line[1:])
        continue
    if line[0] != 'b':
        continue
    bits, vid = line.split()
    if vid != sig_id or 'x' in bits:
        continue
    val = int(bits[1:], 2)
    if current_time in (75,85,95):
        print('time', current_time, 'es1_ms_o_addr_rd =', val)
