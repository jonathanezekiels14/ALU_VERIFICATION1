# Parameterized ALU – RTL Design & Verificatio

A fully parameterized 8-bit (scalable) Arithmetic Logic Unit implemented in synthesizable Verilog HDL, verified using a self-checking testbench against a golden reference model. Simulation and coverage analysis performed in Mentor Questa SIM.

---
.
├── src/
│   ├── design/
│   │   └── alu.v                   # DUT – Parameterized ALU RTL
│   └── testbench/
│       └── ALU_tb.v                # Self-checking testbench
├── docs/
│   ├── test_plan.md                # Test plan with feature IDs and pass/fail status
│   └── verification_report.md      # Full verification report
├── Miscellaneous
└── README.md
---

## Design Overview

The ALU is a synchronous, registered design with an asynchronous reset and a clock-enable input. It supports two operating modes selected by the `mode` signal, and is fully parameterized by `DATA_WIDTH` (default 8-bit, result bus is 2×DATA_WIDTH).

### Inputs

| Signal | Width | Description |
|---|---|---|
| `clk` | 1 | System clock (rising-edge triggered) |
| `rst` | 1 | Asynchronous reset (active-high) |
| `ce` | 1 | Clock enable — holds outputs when low |
| `mode` | 1 | `1` = Arithmetic Mode, `0` = Logical Mode |
| `op_a` | DATA_WIDTH | Operand A |
| `op_b` | DATA_WIDTH | Operand B |
| `inp_valid` | 2 | Per-operand validity: `[1]`=OPA valid, `[0]`=OPB valid |
| `c_in` | 1 | Carry-in for ADD_CIN / SUB_CIN |
| `cmd` | 4 | Command selector |

### Outputs

| Signal | Width | Description |
|---|---|---|
| `result` | 2×DATA_WIDTH | Operation result |
| `c_out` | 1 | Carry-out flag |
| `overflow` | 1 | Overflow flag |
| `err` | 1 | Error flag (invalid cmd or invalid inputs) |
| `G / L / E` | 1 each | Comparator flags (Greater / Less / Equal) |

---

## Supported Operations

### Arithmetic Mode (`mode = 1`)

| CMD | Operation | Description |
|---|---|---|
| 0 | ADD | `OPA + OPB` — unsigned add with carry-out |
| 1 | SUB | `OPA - OPB` — unsigned subtract with overflow |
| 2 | ADD_CIN | `OPA + OPB + CIN` |
| 3 | SUB_CIN | `OPA - OPB - CIN` |
| 4 | INC_A | `OPA + 1` |
| 5 | DEC_A | `OPA - 1` |
| 6 | INC_B | `OPB + 1` |
| 7 | DEC_B | `OPB - 1` |
| 8 | CMP | Sets `E`, `G`, or `L` flag |
| 9 | INC_MUL | `(OPA+1) × (OPB+1)` — **3-cycle latency** |
| 10 | SHL_MUL | `(OPA<<1) × OPB` — **3-cycle latency** |
| 11 | Si_ADD | Signed addition with overflow detection |
| 12 | Si_SUB | Signed subtraction with overflow detection |

### Logical Mode (`mode = 0`)

| CMD | Operation | Description |
|---|---|---|
| 0 | AND | `OPA & OPB` |
| 1 | NAND | `~(OPA & OPB)` |
| 2 | OR | `OPA \| OPB` |
| 3 | NOR | `~(OPA \| OPB)` |
| 4 | XOR | `OPA ^ OPB` |
| 5 | XNOR | `~(OPA ^ OPB)` |
| 6 | NOT_A | `~OPA` |
| 7 | NOT_B | `~OPB` |
| 8 | SHR1_A | `OPA >> 1` |
| 9 | SHL1_A | `OPA << 1` |
| 10 | SHR1_B | `OPB >> 1` |
| 11 | SHL1_B | `OPB << 1` |
| 12 | ROL_A_B | Rotate left `OPA` by `OPB[2:0]` bits |
| 13 | ROR_A_B | Rotate right `OPA` by `OPB[2:0]` bits |

> **Note:** For CMD 9 and CMD 10, the result is valid 3 clock cycles after inputs are applied. The testbench driver accounts for this automatically.

---

## Timing

| Operation Type | Latency |
|---|---|
| All standard commands | 1 clock cycle |
| CMD 9 – INC & MUL | 3 clock cycles |
| CMD 10 – SHL & MUL | 3 clock cycles |

---

## Testbench Architecture

The testbench is a flat Verilog module that instantiates both the DUT and the reference model on shared stimulus, then compares outputs on every test.

```
┌─────────────────────────────────────────────────────┐
│                   alu_testbench                     │
│  ┌───────────┐  ┌──────────┐  ┌──────┐  ┌────────┐ │
│  │ Generator │─▶│  Driver  │─▶│  DUT │  │  Ref   │ │
│  │  (task)   │  │  (task)  │  │(inst1│  │ Model  │ │
│  └───────────┘  └──────────┘  └──┬───┘  └───┬────┘ │
│                                  └─────┬─────┘      │
│                                        ▼             │
│                               ┌──────────────┐      │
│                               │  Scoreboard  │      │
│                               │   (task)     │      │
│                               └──────────────┘      │
└─────────────────────────────────────────────────────┘
```

### Test Categories

| Category | Count | Description |
|---|---|---|
| Sanity Tests | ~10 | RST, CE, MODE, clock toggle verification |
| Directed Tests | ~111 | Corner cases for every command |
| Randomized Tests | 2,600 | 100 random iterations × 26 commands |
| **Total** | **2,811** | — |

---

## Simulation Results

```
---------------------------------------------------
             Test Summary
---------------------------------------------------
Total Tests Run : 2811
Passed          : 2438
Failed          : 373
 ***        Bugs Found         ***
---------------------------------------------------
```

### Known Bugs (from Test Plan)

| Feature ID | Feature | Description |
|---|---|---|
| 3 | CE | Clock-enable latch behavior failed — output not held when CE=0 |
| 54 | CMD_9 MUL | Multiplication with OPA=255, OPB=255 produces wrong result |
| 57 | CMD_9 MUL | Counter logic fails when CMD transitions mid-sequence |
| 63 | CMD_10 MUL | Output incorrect when inputs change during 3-cycle window |
| 64 | CMD_10 MUL | CMD transition 10→9 produces wrong output |
| 65 | CMD_10 MUL | CMD transition 10→other does not recover cleanly |
| 67 | CMD_10 MUL | Toggling extended bits (OPA=127, OPB=255) fails |
| 69–74 | CMD_11 SiADD | EGL flags not asserted; only COUT triggered instead |
| 75–80 | CMD_12 SiSUB | EGL flags not asserted; only COUT triggered instead |

---

## Coverage Report

Collected using Questa SIM `vcover` on `ALU1.ucdb`.

| Coverage Type | Bins | Hits | Misses | Coverage |
|---|---|---|---|---|
| Statements | 160 | 158 | 2 | **98.75%** |
| Branches | 117 | 115 | 2 | **98.29%** |
| FEC Expressions | 4 | 4 | 0 | **100.00%** |
| FEC Conditions | 20 | 20 | 0 | **100.00%** |
| Toggles | 258 | 256 | 2 | **99.22%** |
| FSMs | 14 | 14 | 0 | **100.00%** |
| **Total** | — | — | — | **99.37%** |

---

## How to Run

### Prerequisites
- Mentor Questa SIM (or ModelSim)
- Verilog-2001 compatible simulator

### Compile & Simulate

```bash
# Compile all files
vlog ALU_referencemodel.v ALU_toverify.v ALU_tb.v

# Run simulation with coverage
vsim work.alu_testbench -coverage -c \
  -do "coverage save -onexit -codeAll ALU1.ucdb; run -all; exit"

# Generate HTML coverage report
vcover report -html ALU1.ucdb -htmldir covReport -details
```

### View Coverage Report

Open `covReport/index.html` in a browser after running the coverage commands above.

---

## Tool Information

| Item | Details |
|---|---|
| Simulator | Mentor Questa SIM v10.6c |
| Language | Verilog HDL (IEEE 1364-2001) |
| Coverage DB | ALU1.ucdb |
| Simulation Time | 60,685 ns |
| Elapsed Wall Time | < 1 second |

---

## Warnings

Two elaboration warnings are present and do not affect functional correctness:

```
** Warning: ALU_referencemodel.v(249): (vopt-2697) MSB of part-select into 'OPB' is out of bounds.
** Warning: ALU_referencemodel.v(265): (vopt-2697) MSB of part-select into 'OPB' is out of bounds.
```

These originate from the rotate boundary check (`OPB[(2*OP_WIDTH)-1 : OP_WIDTH/2]`) when `OP_WIDTH = 8`, where the MSB index exceeds the declared width of the signal. A future fix would clamp the index to the declared width.
