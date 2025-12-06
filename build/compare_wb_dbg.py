import re
from pathlib import Path
expected_path = Path('../expected/testdtp.txt')
actual_path = Path('testdtp_dbg2.log')

def parse_times(path):
    lines = path.read_text().splitlines()
    times = []
    pattern_time = re.compile(r'^(\d+):')
    for l in lines:
        m = pattern_time.match(l.strip())
        if m:
            times.append(int(m.group(1)))
    return times, lines

et, elines = parse_times(expected_path)
at, alines = parse_times(actual_path)
print('expected times:', et)
print('actual times  :', at)
print('\nFirst 10 lines of actual:')
for l in alines[:20]:
    print(l)
