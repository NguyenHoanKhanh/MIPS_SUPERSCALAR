from pathlib import Path
path=Path(r"Code/MIPS_SUPERSCALAR/waveform/dtp.vcd")
lines=path.read_text().splitlines()
name_to_id={}
for line in lines:
    if line.startswith('$var'):
        parts=line.split()
        if len(parts)>=5:
            name_to_id[parts[4]]=parts[3]
    if line.startswith('$enddefinitions'):
        break
signals=['choose_mux_1','choose_mux_2','qc1_o_ce_r','qc2_o_ce_r']
ids={sig:name_to_id[sig] for sig in signals}
values={vid:0 for vid in ids.values()}
target={75,85,95}
cur=0
for line in lines:
    if not line:
        continue
    if line[0]=='#':
        cur=int(line[1:])
        if cur in target:
            snap={sig:values[vid] for sig,vid in ids.items()}
            print('time',cur,snap)
        continue
    if line[0] in '01':
        vid=line[1:]
        if vid in values:
            values[vid]=int(line[0])
