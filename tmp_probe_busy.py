from pathlib import Path
lines=Path(r"Code/MIPS_SUPERSCALAR/waveform/dtp.vcd").read_text().splitlines()
name_to_id={}
for line in lines:
    if line.startswith('$var'):
        parts=line.split()
        if len(parts)>=5:
            name_to_id[parts[4]]=parts[3]
    if line.startswith('$enddefinitions'):
        break
signals=['mc1_o_addr_rd','mc2_o_addr_rd','ms_wb1_o_addr_rd','ms_wb1_o_regwrite','ms_wb2_o_addr_rd','ms_wb2_o_regwrite','busy_write']
ids={sig:name_to_id[sig] for sig in signals}
values={vid:0 for vid in ids.values()}
interest=[75,85,95,105,115]
for line in lines:
    if not line:
        continue
    if line[0]=='#':
        t=int(line[1:])
        if t in interest:
            print('time',t,{sig:values[vid] for sig,vid in ids.items()})
        continue
    if line[0] in '01':
        vid=line[1:]
        if vid in values:
            values[vid]=int(line[0])
    elif line[0]=='b':
        parts=line.split()
        if len(parts)!=2:
            continue
        bits,vid=parts
        if vid in values and 'x' not in bits:
            values[vid]=int(bits[1:],2)
