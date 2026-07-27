# MIPS_SUPERSCALAR

This repository contains a small two-wide superscalar processor RTL project and a standalone simulation flow for running the supported RISC-V-style benchmark subset.

The flow is designed to run from WSL/Linux using `make`, `iverilog`, `vvp`, and a RISC-V bare-metal GCC toolchain.

## 1. Prepare WSL

Install common build and simulation tools:

```bash
sudo apt update
sudo apt install -y make git iverilog python3
```

Install the RISC-V bare-metal toolchain:

```bash
sudo apt install -y gcc-riscv64-unknown-elf binutils-riscv64-unknown-elf
```

Check that the required commands are available:

```bash
make --version
iverilog -V
vvp -V
riscv64-unknown-elf-gcc --version
riscv64-unknown-elf-objcopy --version
```

This project also calls Windows PowerShell from WSL through `powershell.exe` for the hex conversion helper script. On normal WSL installations, `powershell.exe` is available automatically.

Check it with:

```bash
powershell.exe -NoProfile -Command "Write-Host OK"
```

## 2. Clone The Repository

From WSL:

```bash
cd /mnt/d
git clone https://github.com/NguyenHoanKhanh/MIPS_SUPERSCALAR.git
cd /mnt/d/MIPS_SUPERSCALAR
```

If Git reports a `dubious ownership` warning, allow this folder once:

```bash
git config --global --add safe.directory /mnt/d/MIPS_SUPERSCALAR
```

## 3. Repository Layout

```text
source/                         RTL source files
test/                           Verilog testbenches
tools/                          Hex/program-info helper scripts
riscv-tests-master/isa/
  rv32i_mips_safe/              Supported safe benchmark subset
  rv32i_mips_friendly/          IPC-friendly benchmark subset
  rv32im_clean/                 Reference clean RV32IM tests
  macros/scalar/                Test macro reference files
Makefile                        Wrapper that includes Makefile.mips
Makefile.mips                   Main standalone simulation flow
```

## 4. Run A Quick Simulation

Run the current program stored in `source/imem.txt`:

```bash
make run_raw_print
```

This prints commit/debug information and writes the waveform to:

```text
waveform/mips_benchmark.vcd
```

## 5. Run The Supported Benchmark Report

Run the MIPS-safe RV32I benchmark subset:

```bash
make mips_report_i
```

Expected output format:

```text
==========================================
MIPS_SUPERSCALAR RV32I-safe benchmark summary
==========================================
Group              |    N |  Commits |   Cycles |    IPC | Result
-------------------+------+----------+----------+--------+-------
...
TOTAL              |   .. |       .. |       .. |  ..... | PASS
Logs: sim/mips_report_<benchmark>.log
```

Run the IPC-friendly benchmark subset:

```bash
make mips_friendly_report_i
```

## 6. Run One Benchmark

Example with `add`:

```bash
make mips_run_clean BENCH=add
```

Example with the friendly version:

```bash
make mips_run_friendly BENCH=add
```

Generated files are placed under:

```text
build/
sim/
waveform/
```

These generated folders are ignored by Git.

## 7. Notes

- `mips_report_i` uses `riscv-tests-master/isa/rv32i_mips_safe`.
- `mips_friendly_report_i` uses `riscv-tests-master/isa/rv32i_mips_friendly`.
- `riscv-tests-master/isa/rv32im_clean` is kept as a reference benchmark source.
- This old MIPS superscalar RTL does not run the full RV32IM report in the same way as the newer RISC-V Out-of-Order project.
