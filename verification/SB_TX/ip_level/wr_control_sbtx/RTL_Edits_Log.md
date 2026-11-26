# RTL & Package Functional Edits Log (`WR_Control_SBTX`)

Running changelog of all **functional** edits made to `RTL/WR_Control_SBTX.sv`, `RTL/OPCODE_pkg.sv`, and `RTL/Universal_pkg.sv`.

---

### 1. [WR_Control_SBTX.sv](file:///d:/University/Digital_Verification/UCIe_GP/git/ucie-phy-dv/verification/SB_TX/ip_level/wr_control_sbtx/RTL/WR_Control_SBTX.sv#L229-L254) — Qualify `MSGCODE` Evaluation by `OPCODE` in `Phase_1`
* **Date:** 2026-11-26
* **Type:** Functional Bug Fix
* **Issue:** In `Phase_1` (second header phase), `case (MSGCODE)` was evaluated unconditionally outside `case (OPCODE)`. Because RAR packets carry `be[7:0]` (Byte Enables) in bits `[21:14]` (the same slice as `MSGCODE`), any 2-phase RAR with `be[7:0]` in `8'h03`–`8'h07` (e.g., `SB_MEM_RD_32B`) falsely asserted `Req_Resp_Marker = 1'b1`.
* **Change:** Moved `case (MSGCODE)` inside the `Message_Without_Data:` branch of `case (OPCODE)` (with `default: Req_Resp_Marker <= 1'b0;`) so `Phase_1` decodes `OPCODE` first and only evaluates `MSGCODE` on `Message_Without_Data` packets.
* **Verification:** Compiled with `vlog` (`0` errors, `0` warnings).

---

### 2. [WR_Control_SBTX.sv](file:///d:/University/Digital_Verification/UCIe_GP/git/ucie-phy-dv/verification/SB_TX/ip_level/wr_control_sbtx/RTL/WR_Control_SBTX.sv#L199-L302) — Block/Zero Outputs on Parity Error & Fix 2-Cycle `UIE` Pulse
* **Date:** 2026-11-26
* **Type:** Functional Bug Fix
* **Issue:**
  1. On `CP`/`DP` parity errors in `Phase_1` and `Phase_3`, the RTL still asserted `FIFO_WR <= 1'b1` and drove `Interface_Message` and classification markers alongside `UIE <= 1'b1`.
  2. On errored 4-phase packets, `Phase_0` (`if (Data_Message)`) still asserted `FIFO_WR <= 1'b1` and `UIE <= UIE_R`, producing a **2-cycle `UIE` pulse** and writing the corrupted data word (risking double credit return in `Credits_Handler`).
* **Change:**
  1. Gated `FIFO_WR`, `Interface_Message`, and all markers in `Phase_1` and `Phase_3` inside the `else` branch of the parity-error check so they remain `0` when `UIE <= 1'b1`.
  2. Changed `Phase_0` from `if (Data_Message)` to `if (Data_Message && !UIE_R)` and removed `UIE <= UIE_R;`, ensuring errored 4-phase packets emit **0 FIFO writes** and **exactly 1 `UIE` pulse**.
* **Related SVA Update:** Updated `UIE_assert` and `Error_Handler_assert` in [wr_control_sbtx_sva.sv](file:///d:/University/Digital_Verification/UCIe_GP/git/ucie-phy-dv/verification/SB_TX/ip_level/wr_control_sbtx/tb/wr_control_sbtx_sva.sv#L16-L28) to assert `!FIFO_WR` during `UIE` / `Error_Handler`.

---

### 3. [WR_Control_SBTX.sv](file:///d:/University/Digital_Verification/UCIe_GP/git/ucie-phy-dv/verification/SB_TX/ip_level/wr_control_sbtx/RTL/WR_Control_SBTX.sv#L131-L140) — Drop Reserved/Illegal Opcodes in `Phase_1` & Flag `UIE`/`Error_Handler`
* **Date:** 2026-11-26
* **Type:** Functional Bug Fix
* **Issue:** In `Phase_1` next-state logic, `default: next_state = Phase_2;` caused any reserved/illegal 5-bit opcode (e.g., `5'b01111`) to be treated as a 4-phase packet, leaving the FSM hung in `Phase_2` waiting for non-existent data phases and emitting no error (`UIE = 0`).
* **Change:**
  1. Explicitly listed the 7 valid 4-phase opcodes (`Memory_Write_32b/64b`, `Configuration_Write_32b/64b`, `Completion_With_32b/64b_Data`, `Message_With_64b_Data`) to transition to `Phase_2`, and routed `default:` back to `Phase_0`.
  2. In `Phase_1` output logic, added a `default:` branch for reserved/illegal opcodes that keeps `FIFO_WR = 0` and asserts `UIE <= 1'b1` and `Error_Handler <= 1'b1`.

---

### 4. [WR_Control_SBTX.sv](file:///d:/University/Digital_Verification/UCIe_GP/git/ucie-phy-dv/verification/SB_TX/ip_level/wr_control_sbtx/RTL/WR_Control_SBTX.sv#L38-L275) — Full Req/Resp `msgcode_e` on `Message_Without_Data` & Header-Only `Comp_Marker`
* **Date:** 2026-11-26
* **Type:** Functional Bug Fixes
* **Issues:**
  1. `Req_Resp_Marker` on `Message_Without_Data` (`Phase_1`) only checked the 5 D2D codes (`8'h03`–`8'h07`), missing the remaining Req/Resp `msgcode_e` values.
  2. `Comp_Marker` was asserted a second time on the Data payload output cycle (`Phase_0`) of 4-phase Completions (`Completion_With_32b_Data`, `Completion_With_64b_Data`).
* **Changes:**
  1. Widened `MSGCODE` from `MSGCODES` to `msgcode_e` and evaluated all 22 Req/Resp message codes (`lnkmgmt_*`, `lnkmgmnt_adp*`, `ParityFeature*`, `req/resp_tests`, `req/resp_sb`, `req/resp_MBINIT`, `req/resp_MBTRAIN`, `PHYRETRAIN_*`, `RECAL_*`, `TRAINERROR_*`) inside `Message_Without_Data` (`Phase_1`). (`Message_With_64b_Data` in `Phase_3` intentionally ignores `MSGCODE` and keeps `Req_Resp_Marker = 0`, as no data-bearing message on this interface is a Req/Resp message; 64-bit RAR Writes also intentionally keep `Reg_Acc_Data_Marker = 0`, which is reserved for 64-bit RAR Reads.)
  2. Removed the redundant `Comp_Marker <= 1'b1` on the Data payload output cycle in `Phase_0`, keeping markers strictly on the Header output cycle.
