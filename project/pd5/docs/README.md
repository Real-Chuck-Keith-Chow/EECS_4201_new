# PD5 – Five-Stage RV32I Pipeline

## Overview
PD5 extends our YorkU RV32I design into a full five-stage pipeline (IF → ID → EX → MEM → WB) with realistic hazard handling. The current core:

- Implements full data forwarding (EX/MEM → EX, MEM/WB → EX, WB → ID, and WB → MEM for stores).
- Inserts load-use bubbles only when the consumer truly reads the loaded register.
- Flushes both IF/ID and ID/EX on taken branches/jumps, with JALR targets correctly masking bit 0.
- Keeps instruction/data memories synchronized with byte/halfword/word accesses and sign extension.
- Exposes rich probe signals for ModelSim/Verilator waveform inspection (`probes.svh`).

## What Works

| Feature | Status |
| --- | --- |
| RV32I ISA (base integer) | ✅ (32-bit, no CSR) |
| Five pipeline stages | ✅ |
| Forwarding network | ✅ (EX/MEM, MEM/WB, WB→ID, WB→MEM for stores) |
| Hazard handling | ✅ load-use stall, branch/jump flush |
| Memory subsystem | ✅ shared memory model with byte/half/word ops |
| VCD tracing | ✅ `VCD=1` with selectable `VCD_FILE` |

The processor runs real programs end-to-end, not just micro-tests.

## Benchmarks
Verified full benchmarks (all reach the pass label with `x15 = 1`):

1. `BubbleSort.x`
2. `Fibonacci.x`
3. `SumArray.x`
4. `gcd.x`
5. `Swap.x`

Passing these workloads proves forwarding, stall logic, control hazard recovery, and memory timing all cooperate under dense dependency chains and pointer-rich loops.

## Running Tests

### Pipeline diagnostics / micro-tests
cd project/pd5/verif/scripts
export VERILATOR=1
make run TEST=../pipeline_tests/mx-bypass-rs1-alu PATTERN_CHECK=0(Each pipeline test needs a dummy `.pattern` file; run `touch *.pattern` inside `verif/pipeline_tests` once.)

### Full benchmarks
cd project/pd5/verif/scripts
export VERILATOR=1
MEM_PATH=/mnt/c/.../rv32-bmarks/full-bmarks/BubbleSort.x make run PATTERN_CHECK=0Repeat with the other `.x` images (`Fibonacci.x`, `SumArray.x`, `gcd.x`, `Swap.x`).

### Capturing waveforms
VCD=1 VCD_FILE=BubbleSort.vcd MEM_PATH=.../BubbleSort.x make run PATTERN_CHECK=0
cd ../sim/verilator/test_pd
gtkwave BubbleSort.vcd## Technical Highlights
- **Forwarding Fixes:** MEM-forward uses the actual WB value (including `PC+4` for jal/jalr) so return addresses stay intact.
- **Load-Use Detector:** The hazard unit checks “uses_rs1/rs2” bits per opcode to avoid false stalls.
- **Store Bypass:** WB → MEM path ensures stores immediately followed by loads see the newest data.
- **Branch Flush:** Single flush signal bubbles both IF/ID and ID/EX, preventing wrong-path commits.

## Lessons Learned
Building PD5 was mostly about timing discipline: every value must be owned by exactly one stage per cycle, and the only way to prove that is through traces. ModelSim/Verilator plus VCD inspection were critical for debugging forwarding, stall timing, and control hazards. The final core is resilient enough to run realistic software and provides clean instrumentation for future PDs.
