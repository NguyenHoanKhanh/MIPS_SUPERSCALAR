import re
from pathlib import Path
p = Path('testdtp_dbg2.log')
raw = p.read_bytes()
for enc in ('utf-8','utf-16','latin-1'):
    try:
        text = raw.decode(enc)
        break
    except Exception:
        text = None
if text is None:
    raise RuntimeError('cant decode')
if text.startswith('\ufeff'):
    text = text.lstrip('\ufeff')
lines = text.splitlines()
pat = re.compile(r'wb_ds1_o_data_rd', re.IGNORECASE)
for i,l in enumerate(lines[:40]):
    if pat.search(l):
        print(i+1, repr(l))

print('\nAll occurrences:')
for i,l in enumerate(lines):
    if pat.search(l):
        print(i+1, l)
