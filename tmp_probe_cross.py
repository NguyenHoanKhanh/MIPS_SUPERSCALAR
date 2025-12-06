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
signals=[
    'mc1_o_addr_rs','mc1_o_addr_rt','mc1_o_addr_rd','mc1_o_data_rs','mc1_o_data_rt',
    'mc2_o_addr_rs','mc2_o_addr_rt','mc2_o_addr_rd','mc2_o_data_rs','mc2_o_data_rt',
    'es1_ex_stage_addr_rd','es1_ex_stage_regwrite','es1_ex_stage_memread','es1_o_alu_value',
    'es2_ex_stage_addr_rd','es2_ex_stage_regwrite','es2_ex_stage_memread','es2_o_alu_value',
    'fw1_o_data_rs','fw1_o_data_rt','fw1_o_stall',
    'fw2_o_data_rs','fw2_o_data_rt','fw2_o_stall',
    'mx31_1_o_data_rs','mx31_1_o_data_rt',
    'mx31_2_o_data_rs','mx31_2_o_data_rt',
    'wb_ds1_o_data_rd','wb_ds2_o_data_rd',
    'ms_wb1_o_addr_rd','ms_wb1_o_regwrite','ms_wb2_o_addr_rd','ms_wb2_o_regwrite',
    'busy_load','busy_write','choose_mux_1','choose_mux_2','qc1_o_ce','qc2_o_ce',
    'ds1_issue_block','ds2_issue_block'
]
ids={sig:name_to_id[sig] for sig in signals if sig in name_to_id}
values={vid:0 for vid in ids.values()}
interest=[55,65,75,85,95,105,115]
cur=0
for line in lines:
    if not line:
        continue
    if line[0]=='#':
        cur=int(line[1:])
        if cur in interest:
            snap={sig:values[vid] for sig,vid in ids.items()}
            print('time',cur,snap)
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
