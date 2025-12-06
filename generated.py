import random

REGISTERS = [f"$S{i}" for i in range(16)]

OPS = [
    {"name": "ADD", "type": "R", "dest": "rd"},
    {"name": "SUB", "type": "R", "dest": "rd"},
    {"name": "AND", "type": "R", "dest": "rd"},
    {"name": "OR", "type": "R", "dest": "rd"},
    {"name": "XOR", "type": "R", "dest": "rd"},
    {"name": "SLT", "type": "R", "dest": "rd"},
    {"name": "ADDI", "type": "I", "dest": "rt"},
    {"name": "ANDI", "type": "I", "dest": "rt"},
    {"name": "ORI", "type": "I", "dest": "rt"},
    {"name": "LW", "type": "LW", "dest": "rt"},
    {"name": "SW", "type": "SW", "dest": None},
]


def random_reg(rng, avoid_zero_dest=False):
    candidates = REGISTERS[1:] if avoid_zero_dest else REGISTERS
    return rng.choice(candidates)


def random_imm(rng):
    return rng.randint(-128, 127)


def generate_instructions(count, seed=None):
    rng = random.Random(seed)
    instructions = []
    for idx in range(count):
        op = rng.choice(OPS)
        rs = random_reg(rng)
        rt = random_reg(rng)
        rd = random_reg(rng, avoid_zero_dest=True)
        imm = random_imm(rng)

        if op["type"] == "R":
            dest = rd
            src1, src2 = rs, rt
            imm_val = None
        elif op["type"] == "I":
            dest = rt
            src1, src2 = rs, None
            imm_val = imm
        elif op["type"] == "LW":
            dest = rt
            src1, src2 = rs, None
            imm_val = imm
        elif op["type"] == "SW":
            dest = None
            src1, src2 = rs, rt
            imm_val = imm
        else:
            dest = rd
            src1, src2 = rs, rt
            imm_val = None

        instructions.append(
            {
                "id": f"I{idx + 1}",
                "op": op["name"],
                "type": op["type"],
                "rd": dest,
                "rs": src1,
                "rt": src2,
                "imm": imm_val,
            }
        )
    return instructions


if __name__ == "__main__":
    for inst in generate_instructions(5, seed=42):
        imm = f", {inst['imm']}" if inst["imm"] is not None else ""
        print(f"{inst['id']}: {inst['op']} {inst['rd']}, {inst['rs']}, {inst['rt']}{imm}")
