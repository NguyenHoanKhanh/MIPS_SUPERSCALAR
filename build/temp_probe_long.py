from pathlib import Path
from collections import OrderedDict
VCD_PATH = Path(r"Code/MIPS_SUPERSCALAR/waveform/dtp.vcd")
INTEREST_TIMES = list(range(70,156,5))
SIGNALS = [
    'mc1_o_addr_rs','mc1_o_addr_rt','mc1_o_addr_rd','mc1_o_data_rs','mc1_o_data_rt',
    'mc2_o_addr_rs','mc2_o_addr_rt','mc2_o_addr_rd','mc2_o_data_rs','mc2_o_data_rt',
    'es1_ex_stage_addr_rd','es1_ex_stage_regwrite','es1_ex_stage_memread','es1_o_alu_value',
    'es2_ex_stage_addr_rd','es2_ex_stage_regwrite','es2_ex_stage_memread','es2_o_alu_value',
    'fw1_o_data_rs','fw1_o_data_rt','fw1_o_stall',
    'fw2_o_data_rs','fw2_o_data_rt','fw2_o_stall',
    'mx31_1_o_data_rs','mx31_1_o_data_rt','mx31_2_o_data_rs','mx31_2_o_data_rt',
    'wb_ds1_o_data_rd','wb_ds2_o_data_rd',
    'ms_wb1_o_addr_rd','ms_wb1_o_regwrite','ms_wb2_o_addr_rd','ms_wb2_o_regwrite',
    'busy_load','busy_write','choose_mux_1','choose_mux_2','qc1_o_ce_r','qc2_o_ce_r','qc1_operand_busy','qc2_operand_busy',
    'ds1_issue_block','ds2_issue_block','queue1_issue_req','queue2_issue_req'
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


def format_val(val, width):
    return val


lines = VCD_PATH.read_text().splitlines()
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
