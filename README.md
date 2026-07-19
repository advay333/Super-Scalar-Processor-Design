# Out-of-Order 2-Way Superscalar Processor (IITB-RISC ISA)

A cycle-accurate VHDL implementation of an out-of-order, 2-way superscalar processor backend, built for the IITB-RISC instruction set architecture as part of the Processor Design course at IIT Bombay.

## Overview

This project implements a dynamically scheduled superscalar backend supporting dual-instruction dispatch, out-of-order execution with in-order retirement, and precise exception recovery. The design is organized around distributed reservation stations, tag-based register renaming, a unified broadcast bus, and a reorder buffer (ROB), extended with a dedicated store buffer for memory-ordering correctness.

## Key Microarchitectural Features

- **2-way dispatch** with a register alias table for renaming, eliminating false dependencies
- **Distributed reservation stations** for ALU, branch, and load/store domains, each with independent scheduling
- **Split-flag register renaming** — separate rename files for general-purpose data, the zero flag, and the carry flag, since IITB-RISC instructions update flag state non-uniformly
- **4-lane common data bus (CDB)** broadcasting results and update tags in the same cycle, waking multiple dependent instructions across functional domains without centralized scoreboarding
- **Reorder Buffer (ROB)** for strict in-order commit and precise architectural state recovery on branch misprediction
- **Store buffer with store-to-load forwarding**, bypassing the data cache when a load matches a pending store address
- **Dynamic branch prediction** using a branch target buffer (BTB), pattern history table (PHT), and 2-bit saturating counter FSMs, with direct operand-comparison branch resolution
- **Multi_Inst_Block** — a hardware microcode sequencer that unrolls multi-register `LM`/`SM` instructions into a sequence of standard loads/stores

## Repository Structure

| Module Group | Files |
|---|---|
| **Front-end** | `fetch_stage.vhd`, `decoder.vhd`, `dispatch.vhd`, `dispatch_top.vhd` |
| **Rename & Commit** | `ARF.vhd`, `RRF.vhd`, `RRF_zero.vhd`, `RRF_carry.vhd`, `Flag_Register.vhd`, `tag_generator.vhd`, `flag_tag_generator.vhd`, `ROB.vhd`, `Commit_From_ROB.vhd` |
| **ALU Datapath** | `alu.vhd`, `alu_pipeline.vhd`, `alu_reservation_station.vhd`, `alu_scheduler.vhd` |
| **Branch Prediction & Resolution** | `branch_predictor.vhd`, `bp_btb.vhd`, `bp_pht.vhd`, `bp_bhsr.vhd`, `bp_logic.vhd`, `fsm_2bit_bhb.vhd`, `branch_module.vhd`, `branch_tag_register.vhd`, `branch_reservation_station.vhd`, `branch_scheduler.vhd`, `br_pipeline.vhd` |
| **Load/Store Unit** | `lsu_reservation_station.vhd`, `lsu_scheduler.vhd`, `ls_pipeline.vhd`, `store_buffer.vhd`, `Store_Retire_Controller.vhd` |
| **Memory** | `memory.vhd`, `data_memory.vhd` |
| **Multi-register Load/Store** | `Multi_Inst_Block.vhd` |
| **Combinational Primitives** | `full_adder.vhd`, `n_bit_full_adder.vhd`, `inverter.vhd`, `n_bit_inverter.vhd`, `nand_block.vhd`, `n_bit_nand.vhd`, `n_bit_register.vhd`, `mux2to1.vhd`, `mux_2x1_16.vhd`, `mux_4x1_16.vhd`, `mux16bit2to1.vhd`, `common_pkg.vhd` |
| **Top-level & Verification** | `datapath.vhd` (top-level integration), `tb_datapath.vhd` (testbench), `program.txt` (sample assembled program) |
| **Documentation** | `Team_39_Superscalar_Report.pdf` — full design report with proof-of-concept waveforms |

## Verification

Functional correctness was verified across 23 instruction-level, cycle-accurate testbenches covering arithmetic, flag-producing, branch, load/store, load/store-multiple, and jump-and-link instructions, using a custom Python assembler built for the IITB-RISC ISA. Full simulation waveforms for each test are documented in the project report.

## Author's Contributions

This was a 4-person team project (Team 39, Processor Design, IIT Bombay). My primary responsibilities were the **fetch stage**, the **branch predictor**, and the **3 execution pipelines** (dual ALU, branch, LSU). Full work distribution and design details are in `Team_39_Superscalar_Report.pdf`.
