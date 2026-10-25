# Black-Box Functional Description: `Pattern_Generator_SBTX`

## 1. Overview & System Role
`Pattern_Generator_SBTX` is a synchronous leaf module operating in the 800 MHz `SB_CLK` domain inside the **SB CLK & Data Lanes Handler** subsystem. During the UCIe Sideband initialization phase (`SBINIT`), the Physical Layer must transmit an alternating `101010...` clock-like training pattern for 64 cycles (followed by a 32-cycle idle window in non-PMO mode) until the remote die detects the pattern. 

Controlled directly by the `TX_FSM`, this module generates that serialized `101010...` bitstream and simultaneously triggers the shared 64-cycle hardware timer (`Timer_64`) that tracks the duration of the pattern burst.

---

## 2. Interface Specification

| Port Name | Direction | Width | Clock Domain | Functional Description |
| :--- | :--- | :--- | :--- | :--- |
| **`CLK`** | Input | 1-bit | `SB_CLK` | 800 MHz Sideband clock; all state and output transitions occur on the rising edge (`posedge CLK`). |
| **`RST_n`** | Input | 1-bit | Async | Active-low asynchronous reset (`negedge RST_n`). Immediately forces outputs low and pre-loads internal state. |
| **`Patt_Gen_En`** | Input | 1-bit | `SB_CLK` | Active-high enable driven by `TX_FSM`. Also acts as the select line for the downstream output `MUX` and feeds the `OR` gate enabling `CLK_Generator`. |
| **`start_64`** | Output | 1-bit | `SB_CLK` | Active-high trigger routed (via an `OR` gate shared with `Serializer`) to start `Timer_64` so the system counts 64 UI of pattern transmission. |
| **`SBTX_DATA`** | Output | 1-bit | `SB_CLK` | Serialized pattern output (`Pattern` wire in Figure 3-29) feeding the final output `MUX` on the `SBTX_DATA` physical lane. |

---

## 3. Detailed Black-Box Behavior & Modes of Operation

The module's external behavior is governed by three distinct operational states:

1. **Asynchronous Reset State (`RST_n == 0`):**
   * Regardless of `CLK` or `Patt_Gen_En`, asserting reset (`RST_n = 0`) immediately clears both external outputs: `SBTX_DATA = 0` and `start_64 = 0`.
   * Internally, the module pre-initializes its seed bit (`Pattern = 1`) so that the very first active cycle after enable assertion is guaranteed to start with a logic `'1'`.

2. **Idle / Disabled State (`RST_n == 1` and `Patt_Gen_En == 0`):**
   * On every rising edge of `CLK` where `Patt_Gen_En` is low, the module holds `SBTX_DATA = 0` and `start_64 = 0`.
   * Crucially, de-asserting `Patt_Gen_En` also acts as a **synchronous re-arm**: the internal toggle state is forced back to `'1'`. This guarantees that every new 64-UI pattern burst starts deterministically from `'1'` (`101010...`), regardless of whether the previous burst was cut short on a `'0'` or a `'1'` (for example, if halted early by `patt_alarm`).

3. **Active Pattern Generation State (`RST_n == 1` and `Patt_Gen_En == 1`):**
   * **Cycle 1 (`posedge CLK` #1 with `Patt_Gen_En == 1`):**
     * `start_64` transitions from `0` $\rightarrow$ `1` and remains high (`1`) for as long as `Patt_Gen_En` stays asserted.
     * `SBTX_DATA` outputs `'1'` (the pre-loaded seed bit).
   * **Cycle 2 (`posedge CLK` #2 with `Patt_Gen_En == 1`):**
     * `start_64` remains `1`.
     * `SBTX_DATA` outputs `'0'`.
   * **Cycles 3 to $N$ (Typically 64 Cycles):**
     * `SBTX_DATA` strictly alternates (`1, 0, 1, 0, 1, 0...`) on every consecutive rising clock edge while `start_64` stays continuously asserted (`1`).
   * **Termination (`Patt_Gen_En` drops to `0` after `alarm_64` fires):**
     * On the very next rising edge of `CLK` where `Patt_Gen_En == 0`, both `SBTX_DATA` and `start_64` drop cleanly back to `0` (entering the 32-UI idle window controlled by `Timer_32`), and the internal seed re-arms to `'1'` for the next burst.

---

## 4. Cycle-by-Cycle Timing Summary

| Clock Edge (`posedge CLK`) | `RST_n` | `Patt_Gen_En` | Internal `Pattern` (Before $\rightarrow$ After Edge) | Output `start_64` (After Edge) | Output `SBTX_DATA` (After Edge) | Phase Description |
| :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| Async | `0` | `X` | $\rightarrow$ `1` | `0` | `0` | Reset active |
| **T0** | `1` | `0` | `1` $\rightarrow$ `1` | `0` | `0` | Idle / Armed |
| **T1** | `1` | `1` | `1` $\rightarrow$ `0` | `1` | **`1`** | Bit 0 of Pattern (First `'1'`) |
| **T2** | `1` | `1` | `0` $\rightarrow$ `1` | `1` | **`0`** | Bit 1 of Pattern (`'0'`) |
| **T3** | `1` | `1` | `1` $\rightarrow$ `0` | `1` | **`1`** | Bit 2 of Pattern (`'1'`) |
| **T4** | `1` | `1` | `0` $\rightarrow$ `1` | `1` | **`0`** | Bit 3 of Pattern (`'0'`) |
| **T5** | `1` | `0` | `1` $\rightarrow$ `1` | `0` | `0` | Burst stopped; re-armed to `'1'` |