# `WR_Control_SBTX` (`D2D_Data_Integrity`) — Ideal Spec-First Black-Box Functional Description

> **Source Basis:** UCIe 2.0 Specification — Section 3.3.1 / 3.3.1.2 (*Sideband Transmitter `SB_TX` — `D2D_Data_Integrity`*) and UCIe RDI / Sideband Framing & Credit Rules (Figures 3-15, 3-16, 3-17, 3-18), with external port boundary aligned to [WR_Control_SBTX.sv](file:///d:/University/Digital_Verification/UCIe_GP/git/ucie-phy-dv/verification/SB_TX/ip_level/wr_control_sbtx/RTL/WR_Control_SBTX.sv) and [Universal_pkg.sv](file:///d:/University/Digital_Verification/UCIe_GP/git/ucie-phy-dv/verification/SB_TX/ip_level/wr_control_sbtx/RTL/Universal_pkg.sv).  
> **Authority Rule:** This specification defines the **ideal, protocol-compliant golden behavior** for building an independent UVM reference model (`ref_model`). Where the specification and current RTL diverge, this document strictly follows the **specification's intended behavior** so your reference model naturally catches RTL defects instead of mirroring them.

---

## 1. Block Overview

`WR_Control_SBTX` (`D2D_Data_Integrity`) is the RDI ingress validation, framing, and classification stage of the Sideband Transmitter (`SB_TX`) in the `LCLK` domain. Its ideal black-box contract is:

1. **RDI Phase Assembly:** Collects 32-bit sideband packet phases on `lp_cfg[31:0]` whenever `lp_cfg_vld` is asserted, grouping consecutive 32-bit phases into 64-bit words (`Interface_Message[63:0]`):
   - **2-Phase Packets (Header-Only):** Emits one 64-bit Header word.
   - **4-Phase Packets (Header + Data):** Holds the 64-bit Header until both Data phases arrive, then—if valid—emits the 64-bit Header word followed immediately on the next cycle by the 64-bit Data word.
2. **End-to-End Parity Validation & Source-Side Blocking:** Checks even Control Parity (`CP`) across the 64-bit Header and even Data Parity (`DP`) across the 64-bit Data payload (or `DP == 1'b0` for Header-Only packets).
   - **Pass:** Commits the validated 64-bit word(s) to the downstream Synchronous FIFO (`FIFO_WR = 1'b1`) along with classification markers.
   - **Fail (Parity Error):** **Blocks the FIFO write directly** (`FIFO_WR = 1'b0` on all cycles of the errored packet, keeping `Interface_Message = 64'h0` and all markers `1'b0`) and emits a clean **single-cycle** `UIE` pulse (plus `Error_Handler` for non-completion packets) so downstream error reporting and credit recovery remain exact.
3. **Header Classification:** Decodes the packet `opcode` and `msgcode` to drive the five classification markers (`Data_Marker`, `Reg_Acc_Marker`, `Reg_Acc_Data_Marker`, `Comp_Marker`, `Req_Resp_Marker`) on the Header output cycle of every valid packet.

---

## 2. Parameters and Configuration

| Parameter | Default | Valid Range / Constraints | Black-Box Functional Impact |
| :--- | :---: | :--- | :--- |
| `NC` | `32` | `32` (UCIe RDI sideband phase width, Table 3-31) | Sets input phase bus width `lp_cfg[NC-1:0]` (`32` bits) and assembled output word width `Interface_Message[2*NC-1:0]` (`64` bits). |

---

## 3. Clock and Reset Domains

| Signal | Type (Clock / Reset) | Polarity / Edge | Sync or Async | Associated Interface / Ports | Notes |
| :--- | :---: | :--- | :---: | :--- | :--- |
| `CLK` | Clock | Rising edge (`posedge`) `[Inferred from RTL - confirm with designer]` | — | All inputs and outputs | `lclk` (D2D / RDI clock domain). Single clock domain; no CDC inside this block. |
| `RST_n` | Reset | Active-Low (`1'b0` = reset asserted) `[Inferred from RTL - confirm with designer]` | Asynchronous assertion `[Inferred from RTL - confirm with designer]` | All outputs and packet-phase tracking | `sys_rst`. Asserting `RST_n = 1'b0` immediately clears all outputs to `'0` and aborts any in-flight partial packet. |

---

## 4. External Interface (Port Map)

### 4.1 Pin-Level Port Map

| Port Name | Direction | Width / Type | Clock Domain | Reset Domain | Reset Value | Polarity | Ideal Black-Box Description |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **Clock & Reset** | | | | | | | |
| `CLK` | Input | `1` (`logic`) | `CLK` | — | — | Rising Edge | LCLK domain clock. |
| `RST_n` | Input | `1` (`logic`) | `CLK` | `RST_n` | — | Active-Low | Asynchronous active-low reset `[Inferred from RTL - confirm with designer]`. |
| **RDI Ingress Interface** | | | | | | | |
| `lp_cfg_vld` | Input | `1` (`logic`) | `CLK` | `RST_n` | — | Active-High | Qualifies `lp_cfg`. When `1'b1`, a valid 32-bit packet phase is accepted on `posedge CLK`. |
| `lp_cfg` | Input | `NC` (`[31:0]`) | `CLK` | `RST_n` | — | Data Bus | 32-bit D2D sideband packet phase. |
| **Synchronous FIFO Write Interface** | | | | | | | |
| `Interface_Message` | Output | `2*NC` (`[63:0]`) | `CLK` | `RST_n` | `64'h0` | Data Bus | Assembled 64-bit Header (`{Header_Ph2, Header_Ph1}`) or Data (`{Data_Ph2, Data_Ph1}`) word. Driven to `64'h0` whenever `FIFO_WR == 1'b0`. |
| `FIFO_WR` | Output | `1` (`logic`) | `CLK` | `RST_n` | `1'b0` | Active-High | Asserted (`1'b1`) **only** for validated, parity-clean 64-bit words (1 cycle for 2-phase packets; 2 consecutive cycles for 4-phase packets). Remains **`1'b0`** on any parity-errored packet. |
| **Message Classification Markers (`Mess_Info[4:0]`, valid on Header output cycle when `FIFO_WR == 1'b1`)** | | | | | | | |
| `Data_Marker` | Output | `1` (`logic`) | `CLK` | `RST_n` | `1'b0` | Active-High | Asserted (`1'b1`) on the Header output cycle of a valid 4-phase (Header + Data) packet; `1'b0` on 2-phase packets and on the Data output cycle. |
| `Reg_Acc_Marker` | Output | `1` (`logic`) | `CLK` | `RST_n` | `1'b0` | Active-High | Asserted (`1'b1`) on the Header output cycle of any valid Register Access Request (RAR Read or Write, 32-bit or 64-bit). |
| `Reg_Acc_Data_Marker` | Output | `1` (`logic`) | `CLK` | `RST_n` | `1'b0` | `0`: 32b, `1`: 64b | Asserted (`1'b1`) on the Header output cycle of any valid **64-bit** RAR (Read or Write); `1'b0` for 32-bit RARs and non-RAR packets. |
| `Comp_Marker` | Output | `1` (`logic`) | `CLK` | `RST_n` | `1'b0` | Active-High | Asserted (`1'b1`) on the Header output cycle of any valid Completion packet (with or without data) so credit return is suppressed downstream. |
| `Req_Resp_Marker` | Output | `1` (`logic`) | `CLK` | `RST_n` | `1'b0` | Active-High | Asserted (`1'b1`) on the Header output cycle of any valid D2D Request/Response control message (`Message_Without_Data` or `Message_With_64b_Data` with a Req/Resp `msgcode`) for Sync FIFO priority queuing. |
| **Error & Credit Recovery Outputs** | | | | | | | |
| `UIE` | Output | `1` (`logic`) | `CLK` | `RST_n` | `1'b0` | Active-High | **Single-cycle pulse** asserted (`1'b1`) when a packet fails Control Parity (`CP`) or Data Parity (`DP`) checking. Never asserted for 2 cycles on a 4-phase packet. |
| `Error_Handler` | Output | `1` (`logic`) | `CLK` | `RST_n` | `1'b0` | Active-High | **Single-cycle pulse** asserted (`1'b1`) concurrently with `UIE` **only if the errored packet is NOT a Completion** (i.e., it consumed a D2D credit that must be recovered and/or triggers RDI corrective action) `[Inferred from RTL - confirm with designer]`. |

---

### 4.2 64-Bit Header Bit Layout Across `lp_cfg[31:0]` Phases

| 64-Bit Header Slice | Input Phase & `lp_cfg` Slice | Field Name | Width | Role in Reference Model |
| :---: | :---: | :--- | :---: | :--- |
| `[4:0]` | Header Phase 1 `lp_cfg[4:0]` | `opcode` | 5 | Selects 2-phase vs. 4-phase framing and determines `Data_Marker`, `Reg_Acc_Marker`, `Reg_Acc_Data_Marker`, `Comp_Marker`, and completion qualification of `Error_Handler`. |
| `[13:5]` | Header Phase 1 `lp_cfg[13:5]` | `rsvd0` | 9 | Passed into `Interface_Message[13:5]`; included in `CP`. |
| `[21:14]` | Header Phase 1 `lp_cfg[21:14]` | `msgcode` / `be[7:0]` | 8 | Evaluated on Message opcodes to assert `Req_Resp_Marker`; passed into `Interface_Message[21:14]`; included in `CP`. |
| `[28:22]` | Header Phase 1 `lp_cfg[28:22]` | `tag[4:0]` / `rsvd1` | 7 | Passed into `Interface_Message[28:22]`; included in `CP`. |
| `[31:29]` | Header Phase 1 `lp_cfg[31:29]` | `srcid[2:0]` | 3 | Passed into `Interface_Message[31:29]`; included in `CP`. |
| `[55:32]` | Header Phase 2 `lp_cfg[23:0]` | `addr[23:0]` / `{msginfo, msgsubcode}` / `status` | 24 | Passed into `Interface_Message[55:32]`; included in `CP`. |
| `[58:56]` | Header Phase 2 `lp_cfg[26:24]` | `dstid[2:0]` | 3 | Passed into `Interface_Message[58:56]`; included in `CP`. |
| `[61:59]` | Header Phase 2 `lp_cfg[29:27]` | `rsvd2` | 3 | Passed into `Interface_Message[61:59]`; included in `CP`. |
| `[62]` | Header Phase 2 `lp_cfg[30]` | `CP` (Control Parity) | 1 | Expected: $\text{CP} = \bigoplus (\text{Header}[61:0])$. Excluded from parity calculation. |
| `[63]` | Header Phase 2 `lp_cfg[31]` | `DP` (Data Parity) | 1 | Expected: `1'b0` for 2-phase packets; $\bigoplus (\text{Data}[63:0])$ for 4-phase packets. Excluded from `CP` calculation. |

---

### 4.3 Complete Ideal Opcode Truth Table (Valid Parity-Clean Packets)

All classification markers below apply to the **Header output cycle** when `FIFO_WR == 1'b1` (no parity error). On the **Data output cycle** of a 4-phase packet, `FIFO_WR = 1'b1`, `Interface_Message = {Data_Ph2, Data_Ph1}`, and **all 5 markers are `1'b0`**.

| Opcode Name | `opcode` (`5'b`) | Phases | `Data_Marker` | `Reg_Acc_Marker` | `Reg_Acc_Data_Marker` | `Comp_Marker` | `Req_Resp_Marker` | Is Completion? (suppresses `Error_Handler`) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `Memory_Read_32b` | `5'b00000` | 2 | `0` | `1` | `0` | `0` | `0` | No |
| `Configuration_Read_32b` | `5'b00100` | 2 | `0` | `1` | `0` | `0` | `0` | No |
| `DMS_Register_Read_32b`\* | `5'b00010` | 2 | `0` | `1` | `0` | `0` | `0` | No |
| `Memory_Read_64b` | `5'b01000` | 2 | `0` | `1` | `1` | `0` | `0` | No |
| `Configuration_Read_64b` | `5'b01100` | 2 | `0` | `1` | `1` | `0` | `0` | No |
| `DMS_Register_Read_64b`\* | `5'b01010` | 2 | `0` | `1` | `1` | `0` | `0` | No |
| `Completion_Without_Data` | `5'b10000` | 2 | `0` | `0` | `0` | `1` | `0` | **Yes** |
| `Message_Without_Data` | `5'b10010` | 2 | `0` | `0` | `0` | `0` | `is_req_resp(msgcode)` | No |
| `MPM_Without_Data`\* | `5'b10111` | 2 | `0` | `0` | `0` | `0` | `0` | No |
| `Memory_Write_32b` | `5'b00001` | 4 | `1` | `1` | `0` | `0` | `0` | No |
| `Configuration_Write_32b` | `5'b00101` | 4 | `1` | `1` | `0` | `0` | `0` | No |
| `DMS_Register_Write_32b`\* | `5'b00011` | 4 | `1` | `1` | `0` | `0` | `0` | No |
| `Memory_Write_64b` | `5'b01001` | 4 | `1` | `1` | **`1`** | `0` | `0` | No |
| `Configuration_Write_64b` | `5'b01101` | 4 | `1` | `1` | **`1`** | `0` | `0` | No |
| `DMS_Register_Write_64b`\* | `5'b01011` | 4 | `1` | `1` | **`1`** | `0` | `0` | No |
| `Completion_With_32b_Data` | `5'b10001` | 4 | `1` | `0` | `0` | `1` | `0` | **Yes** |
| `Completion_With_64b_Data` | `5'b11001` | 4 | `1` | `0` | `0` | `1` | `0` | **Yes** |
| `Message_With_64b_Data` | `5'b11011` | 4 | `1` | `0` | `0` | `0` | `is_req_resp(msgcode)` | No |
| `MPM_With_Data`\* | `5'b11000` | 4 | `1` | `0` | `0` | `0` | `0` | No |

*\*Note: If your verification plan restricts legal D2D RDI traffic to non-DMS / non-MPM opcodes, constrain the generator accordingly; otherwise the table above gives the complete spec-consistent classification for every `OPCODES` enum in `Universal_pkg.sv`.*

#### `is_req_resp(msgcode)` Rule (`lp_cfg[21:14]` on `Message_Without_Data` / `Message_With_64b_Data`)
`Req_Resp_Marker` asserts (`1'b1`) on the Header output cycle when `opcode` is a Message (`5'b10010` or `5'b11011`) and `msgcode` belongs to `req_resp_msgcode_e` (see [packets_pkg.sv](file:///d:/University/Digital_Verification/UCIe_GP/git/ucie-phy-dv/verification/SB_TX/ip_level/wr_control_sbtx/packages/packets_pkg.sv)).
* *(Note: `Req_Resp_Marker` must ONLY be evaluated when `opcode` is a Message opcode — never on RAR opcodes where bits `[21:14]` carry `be[7:0]` Byte Enables!)*

---

## 5. Functional Behavior and Operating Modes

### 5.1 Parity Checking Rules
For every completed packet, compute:
$$\text{cp\_err} = \left(\bigoplus_{i=0}^{61} \text{Header}[i]\right) \neq \text{Header}[62]$$
$$\text{dp\_err} = \begin{cases} \text{Header}[63] \neq 1'b0 & \text{if 2-phase (Header-Only) packet} \\ \left(\bigoplus_{i=0}^{63} \text{Data}[i]\right) \neq \text{Header}[63] & \text{if 4-phase (Header + Data) packet} \end{cases}$$
$$\text{parity\_err} = \text{cp\_err} \;\lor\; \text{dp\_err}$$

### 5.2 Output Decision Table (Ideal Spec-First Contract)

| Packet Type | Parity Result | Cycle +1 After Final Phase | Cycle +2 After Final Phase |
| :--- | :---: | :--- | :--- |
| **2-Phase (Header-Only)** | **PASS** (`parity_err == 0`) | `FIFO_WR = 1`, `Interface_Message = {H1, H0}`, Markers per Table 4.3, `UIE = 0`, `Error_Handler = 0` | Idle (`'0`) unless next packet completes |
| **2-Phase (Header-Only)** | **FAIL** (`parity_err == 1`) | **`FIFO_WR = 0`**, `Interface_Message = 64'h0`, All Markers `= 0`, **`UIE = 1`**, `Error_Handler = ~is_comp` | Idle (`'0`) unless next packet completes |
| **4-Phase (Header + Data)** | **PASS** (`parity_err == 0`) | `FIFO_WR = 1`, `Interface_Message = {H1, H0}`, `Data_Marker = 1`, Markers per Table 4.3, `UIE = 0`, `Error_Handler = 0` | `FIFO_WR = 1`, `Interface_Message = {D1, D0}`, All Markers `= 0`, `UIE = 0`, `Error_Handler = 0` |
| **4-Phase (Header + Data)** | **FAIL** (`parity_err == 1`) | **`FIFO_WR = 0`**, `Interface_Message = 64'h0`, All Markers `= 0`, **`UIE = 1`**, `Error_Handler = ~is_comp` | **`FIFO_WR = 0`**, `Interface_Message = 64'h0`, All Markers `= 0`, **`UIE = 0`**, `Error_Handler = 0` |

---

## 6. Protocol and Timing Contracts

### 6.1 Handshake & Framing Rules (UCIe Spec Figure 3-15)
* **Intra-Packet Continuity:** `lp_cfg_vld` must remain continuously asserted (`1'b1`) across all 2 cycles of a Header-Only packet or all 4 cycles of a Header + Data packet.
* **Inter-Packet Continuity (Zero-Bubble Pipelining):** `lp_cfg_vld` may remain `1'b1` with zero idle cycles between any combination of consecutive packets (`2->2`, `2->4`, `4->2`, `4->4`).
* **32-Bit Data Payload Padding:** For 32-bit Write and 32-bit Completion-With-Data packets (`Memory_Write_32b`, `Configuration_Write_32b`, `Completion_With_32b_Data`), 64 bits of data (2 data phases) are always sent on RDI; Data Phase 2 (`Data[63:32]`) is `32'h0000_0000`.
* **In-Order Guarantee:** All valid packets are emitted strictly in arrival order, with each 4-phase packet's Header word always immediately followed by its Data word on the next clock cycle without interleaving.

### 6.2 Back-to-Back Pipelining (Worst Case: 4-Phase M1 Followed Immediately by 2-Phase M2)

| `CLK` Cycle | `lp_cfg_vld` | `lp_cfg[31:0]` Input | Output on `Interface_Message` / `FIFO_WR` (Assuming Valid Parity) |
| :---: | :---: | :---: | :--- |
| `C1` | `1` | `M1_H0` (4-phase) | Idle (`FIFO_WR = 0`) |
| `C2` | `1` | `M1_H1` | Idle (`FIFO_WR = 0`) |
| `C3` | `1` | `M1_D0` | Idle (`FIFO_WR = 0`) |
| `C4` | `1` | `M1_D1` | Idle (`FIFO_WR = 0`) |
| `C5` | `1` | `M2_H0` (2-phase) | **`M1` Header** (`{M1_H1, M1_H0}`), `FIFO_WR = 1`, `Data_Marker = 1` |
| `C6` | `1` | `M2_H1` | **`M1` Data** (`{M1_D1, M1_D0}`), `FIFO_WR = 1`, `Data_Marker = 0` |
| `C7` | `0` or `1` | Idle or `M3_H0` | **`M2` Header** (`{M2_H1, M2_H0}`), `FIFO_WR = 1`, `Data_Marker = 0` |

* **Latency Contract:**
  * **2-Phase Packet:** `1` clock cycle from `Header Phase 2` to output (`FIFO_WR` or `UIE`).
  * **4-Phase Packet:** `1` clock cycle from `Data Phase 2` to Header output (or single-cycle `UIE` if errored), and `2` clock cycles from `Data Phase 2` to Data output (if valid).

---

## 7. Reset, Corner Cases, and Error Handling

* **Asynchronous Reset (`RST_n == 1'b0`):** Immediately drives all outputs to `'0` and clears any partially received packet phases and any pending Data output cycle from a previously completed 4-phase packet.
* **Mid-Packet Reset:** If `RST_n` asserts after Phase 1, Phase 2, or Phase 3 of a packet, no `FIFO_WR`, `UIE`, or `Error_Handler` pulse is emitted. Upon `RST_n` de-assertion, the next `lp_cfg_vld == 1'b1` is treated as `Header Phase 1` of a new packet.
* **Both `CP` and `DP` Errors Simultaneously on a 4-Phase Packet:** Treated as a single packet error — `FIFO_WR` stays `1'b0` for both cycles, and `UIE` (and `Error_Handler` if non-completion) pulses for **1 cycle** on Cycle +1 after Data Phase 2.
* **Errored 4-Phase Packet Followed Back-to-Back by a Valid 2-Phase Packet:**
  * On `C5` (`M2_H0` arrives): `M1` is blocked (`FIFO_WR = 0`, `UIE = 1`).
  * On `C6` (`M2_H1` arrives): `M1`'s Data word is also blocked (`FIFO_WR = 0`, `UIE = 0`).
  * On `C7`: `M2` Header outputs cleanly (`FIFO_WR = 1`, `UIE = 0`).
* **RAR Byte-Enable Collision with `MSGCODES`:** On RAR packets, Header bits `[21:14]` are `be[7:0]` (which can legally equal a `req_resp_msgcode_e` value). The reference model must **never** assert `Req_Resp_Marker` for RAR opcodes—only for Message opcodes (`Message_Without_Data` / `Message_With_64b_Data`).

---

## 8. Spec Gaps and Questions for the Designer (Expected Mismatches vs. Current RTL)

When you run your golden `ref_model` built from this ideal specification against the current RTL, you should **expect your scoreboard to flag the following design bugs/divergences** (which should be confirmed with the RTL designer before waiving):

1. **Parity Error Write Blocking (`FIFO_WR` & `UIE`):** This ideal spec requires `FIFO_WR = 1'b0` on parity errors and a **1-cycle** `UIE` pulse. The current RTL asserts `FIFO_WR = 1'b1` alongside `UIE = 1'b1`, and holds `UIE = 1'b1` for **2 consecutive cycles** on 4-phase errored packets (causing double credit returns in `Credits_Handler`).
2. **64-Bit Write RAR `Reg_Acc_Data_Marker`:** This ideal spec asserts `Reg_Acc_Data_Marker = 1'b1` for 64-bit RAR Writes (`Memory_Write_64b`, `Configuration_Write_64b`) just like 64-bit RAR Reads. Confirm with the designer whether `Reg_Acc_Data_Marker` is intentionally `0` on writes (since write completions are always `Completion_Without_Data`).
3. **`Req_Resp_Marker` Qualified by `opcode`:** This ideal spec evaluates `Req_Resp_Marker` only on Message opcodes (`Message_Without_Data` and `Message_With_64b_Data`), not on RAR opcodes whose `be[7:0]` overlaps bits `[21:14]`.
4. **Unsupported `OPCODES` (`DMS_Register_*`, `MPM_*`):** Confirm whether `DMS_Register_Read/Write_*` and `MPM_*` are valid on the D2D RDI port or out of scope for this IP.
5. **Completion Data-Cycle `Comp_Marker`:** This ideal spec asserts `Comp_Marker = 1'b1` only on the Header output cycle (keeping all markers `0` on the Data output cycle). Confirm whether the downstream Sync FIFO requires `Comp_Marker` to be repeated on the Data output cycle of `Completion_With_32b_Data` / `Completion_With_64b_Data`.

