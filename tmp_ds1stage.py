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
signals=['im_ds1_o_instr','im_ds1_o_ce','ds1_o_ce','ds1_o_addr_rd','ds1_o_addr_rs','ds1_o_addr_rt']
ids={sig:name_to_id[sig] for sig in signals}
values={vid:0 for vid in ids.values()}
target=[55,65,75]
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
    elif line[0]=='b':
        bits,vid=line.split()
        if vid in values and 'x' not in bits:
            values[vid]=int(bits[1:],2)
