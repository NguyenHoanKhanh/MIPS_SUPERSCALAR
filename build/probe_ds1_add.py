from pathlib import Path
VCD_PATH = Path(r"C:/HK_7/Code/MIPS_SUPERSCALAR/waveform/dtp.vcd")
INTEREST_TIMES = [70,75,80,85,90,95,100,105,110]
SIGNALS = [
    'ds1_o_addr_rd','ds1_o_addr_rs','ds1_o_addr_rt',
    'ds2_o_addr_rd','ds2_o_addr_rs','ds2_o_addr_rt',
    'im_ds1_o_instr','im_ds2_o_instr',
    'mc1_o_addr_rs','mc1_o_addr_rt','mc1_o_addr_rd',
    'mc2_o_addr_rs','mc2_o_addr_rt','mc2_o_addr_rd',
    'wb_ds1_o_data_rd','wb_ds2_o_data_rd',
    'ms_wb1_o_addr_rd','ms_wb1_o_regwrite','ms_wb1_o_memtoreg','ms_wb1_o_load_data_1','ms_wb1_o_alu_value',
    'ms_wb2_o_addr_rd','ms_wb2_o_regwrite','ms_wb2_o_memtoreg','ms_wb2_o_load_data_2','ms_wb2_o_alu_value',
    'busy_load','busy_write','ds1_issue_block','ds2_issue_block','qc1_operand_busy','qc2_operand_busy','fw1_o_stall','fw2_o_stall'
]

def load_vcd_mapping(lines):
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


lines = VCD_PATH.read_text(encoding='utf-8',errors='replace').splitlines()
mapping = load_vcd_mapping(lines)
ids = {}
widths = {}
missing = []
for s in SIGNALS:
    if s in mapping:
        vid,w = mapping[s]
        ids[vid]=s
        widths[vid]=w
    else:
        missing.append(s)

if missing:
    print('Missing signals:', missing)

values = {vid:0 for vid in ids}
cur=0
for line in lines:
    if not line: continue
    c=line[0]
    if c=='#':
        cur=int(line[1:])
        if cur in INTEREST_TIMES:
            print('\n===== time',cur,'ns =====')
            for vid,s in ids.items():
                print(f"{s:25s}: {values[vid]}")
        continue
    if c in '01':
        vid=line[1:]
        if vid in values:
            values[vid]=int(c)
    elif c=='b':
        parts=line.split()
        if len(parts)!=2: continue
        bits,vid=parts
        if vid in values and 'x' not in bits and 'z' not in bits:
            val=int(bits[1:],2)
            values[vid]=val

print('\nDone')
