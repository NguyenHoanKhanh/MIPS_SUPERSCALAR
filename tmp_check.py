from pathlib import Path
lines = Path('Code/MIPS_SUPERSCALAR/waveform/dtp.vcd').read_text().splitlines()
name_to_id = {}
for line in lines:
    if line.startswith('$var'):
        parts = line.split()
        if len(parts) < 5:
            continue
        name = parts[4]
        var_id = parts[3]
        name_to_id[name] = var_id
    if line.startswith('$enddefinitions'):
        break
vid = name_to_id['ds2_queue_request']
val = 0
for line in lines:
    if not line:
        continue
    if line[0] == '#':
        t = int(line[1:])
        if t in (55,65,75,85,95):
            print('time', t, 'ds2_queue_request', val)
        continue
    if line[0] in '01' and line[1:] == vid:
        val = int(line[0])
