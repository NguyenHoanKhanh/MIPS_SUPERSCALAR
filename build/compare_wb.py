import re
from pathlib import Path

expected_path = Path('../expected/testdtp.txt')
actual_path = Path('testdtp_dbg2.log')

def parse_wb_lines(path):
    # Read file robustly: logs can be UTF-16 or UTF-8. Try utf-8, then utf-16.
    raw = path.read_bytes()
    for enc in ('utf-8', 'utf-16', 'latin-1'):
        try:
            text = raw.decode(enc)
            break
        except Exception:
            text = None
    if text is None:
        raise RuntimeError(f"Unable to decode {path}")
    # strip BOM/Unicode signature
    if text.startswith('\ufeff'):
        text = text.lstrip('\ufeff')
    lines = text.splitlines()
    wb = {}
    pattern_time = re.compile(r'^(\d+):')
    pattern_wb = re.compile(r'wb_ds1_o_data_rd\s*=\s*([0-9]+|x+).*wb_ds2_o_data_rd\s*=\s*([0-9]+|x+)', re.IGNORECASE)
    for i,l in enumerate(lines):
        m = pattern_time.match(l.strip())
        if m:
            t = int(m.group(1))
            mw = pattern_wb.search(l)
            if mw:
                a = mw.group(1)
                b = mw.group(2)
                wb[t] = (a,b,i,l)
    return wb

exp = parse_wb_lines(expected_path)
act = parse_wb_lines(actual_path)

# Compare times in expected order
mismatch = None
for t in sorted(exp.keys()):
    e = exp[t]
    a = act.get(t)
    if a is None:
        mismatch = (t, 'missing', e, None)
        break
    if e[0] != a[0] or e[1] != a[1]:
        mismatch = (t, 'diff', e, a)
        break

if mismatch is None:
    print('No mismatches for recorded WB times. All matched expected file.')
else:
    t, kind, e, a = mismatch
    print(f'First mismatch at time {t} ns: {kind}')
    print('\nEXPECTED LINE:')
    print(e[3])
    print('\nACTUAL LINE:')
    if a:
        print(a[3])
    else:
        print('(no line at that time)')
    # print small context around actual if available
    if a and isinstance(a[2], int):
        idx = a[2]
        with open(actual_path, 'r') as f:
            alines = f.readlines()
        start = max(0, idx-3)
        end = min(len(alines), idx+4)
        print('\n--- Context around actual line: ---')
        for li in alines[start:end]:
            print(li.rstrip())

# exit code
if mismatch:
    raise SystemExit(2)
else:
    raise SystemExit(0)
