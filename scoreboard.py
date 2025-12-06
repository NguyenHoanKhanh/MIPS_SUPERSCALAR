import sys
from collections import defaultdict

from generated import generate_instructions


def parse_args():
    if len(sys.argv) < 2:
        print("Usage: python scoreboard.py <num_instructions> [seed]")
        sys.exit(1)
    try:
        num_instr = int(sys.argv[1])
    except ValueError:
        print("Instruction count must be an integer.")
        sys.exit(1)
    seed = int(sys.argv[2]) if len(sys.argv) > 2 else None
    return num_instr, seed


def regs_ready(ready_cycle, regs, current_cycle):
    for r in regs:
        if r is None:
            continue
        if ready_cycle[r] >= current_cycle:
            return False
    return True


def reg_available(ready_cycle, rd, current_cycle):
    if rd is None:
        return True
    return ready_cycle[rd] <= current_cycle


def format_inst(inst):
    op = inst["op"]
    if inst["type"] == "R":
        return f"{inst['id']} {op} {inst['rd']}, {inst['rs']}, {inst['rt']}"
    if inst["type"] == "I":
        return f"{inst['id']} {op} {inst['rd']}, {inst['rs']}, {inst['imm']}"
    if inst["type"] == "LW":
        return f"{inst['id']} {op} {inst['rd']}, {inst['imm']}({inst['rs']})"
    if inst["type"] == "SW":
        return f"{inst['id']} {op} {inst['rt']}, {inst['imm']}({inst['rs']})"
    return f"{inst['id']} {op}"


def schedule(instructions):
    ready_cycle = defaultdict(int)
    scheduled = set()
    cycle = 0
    log = []
    total = len(instructions)
    latency = 1

    while len(scheduled) < total:
        cycle += 1
        issued = []
        for pipe in range(1, 3):
            candidate = None
            for inst in instructions:
                if inst["id"] in scheduled:
                    continue
                sources = [inst["rs"], inst["rt"]]
                if not regs_ready(ready_cycle, sources, cycle):
                    continue
                if not reg_available(ready_cycle, inst["rd"], cycle):
                    continue
                candidate = inst
                break
            if candidate is None:
                issued.append((pipe, None))
                continue
            scheduled.add(candidate["id"])
            if candidate["rd"] is not None:
                ready_cycle[candidate["rd"]] = cycle + latency
            issued.append((pipe, candidate))
        log.append((cycle, issued))
    return log


def main():
    num_instr, seed = parse_args()
    instructions = generate_instructions(num_instr, seed=seed)
    schedule_log = schedule(instructions)

    print(f"Scheduling {num_instr} instructions with dual pipe scoreboard\n")
    for cycle, row in schedule_log:
        line = [f"Cycle {cycle:>3}:"]
        for pipe, inst in row:
            if inst is None:
                line.append(f"Pipe{pipe}: (stall)")
            else:
                line.append(f"Pipe{pipe}: {format_inst(inst)}")
        print(" | ".join(line))


if __name__ == "__main__":
    main()
