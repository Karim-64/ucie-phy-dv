# Functional Specification: `WR_Control_MBRX`

## 1. Overview
The `WR_Control_MBRX` (Main Band Receiver Write Control) block is a data alignment and aggregation unit situated within the De-Mapper pipeline of a UCIe physical layer receiver. Its primary architectural role is to interface between the parallelized output of the lane deserializers and the input of the downstream Asynchronous CDC FIFO. 

Regardless of the physical link's operating width (Full x16 or Degraded x8), this block ensures that the downstream FIFO is consistently fed with complete, fully aligned 128-bit (16-byte) data words. It dynamically acts as either a single-cycle passthrough or a two-cycle temporal aggregator, and includes synchronous abort mechanisms to handle mid-transaction mode changes triggered by the system controller.

## 2. Interface Description

| Signal Name | Direction | Width | Domain | Description |
| :--- | :--- | :--- | :--- | :--- |
| `CLK` | Input | 1 | Clock | Main Band (MB) clock. |
| `R_RST_n` | Input | 1 | Async | Active-low asynchronous reset. |
| `Ip_Bytes` | Input | 128 | Data | Incoming deserialized data from the physical lanes. |
| `EN` | Input | 1 | Control | General operational enable driven by the Main Controller. |
| `Deser_Done` | Input | 1 | Control | Periodic trigger indicating a new parallel word is available. |
| `Width_Degrade` | Input | 3 | Control | Specifies the current link operating width (x16, lower x8, or upper x8). |
| `Width_Degrade_Update` | Input | 1 | Control | Indicates that a new value on the `Width_Degrade` bus is stable and must be sampled, serving as a synchronous flush/abort trigger. |
| `WR_EN` | Output | 1 | Control | Write-enable strobe targeted for the downstream FIFO. |
| `WR_DATA` | Output | 128 | Data | Aligned and aggregated 128-bit word to be written to the FIFO. |

## 3. Operational Modes & Data Flow

The block evaluates incoming data exclusively on clock cycles where both the gating signal (`EN`) and the data-valid trigger (`Deser_Done`) are simultaneously asserted. The aggregation logic is governed by the `Width_Degrade` control vector.

### 3.1 Full Width Mode (`Width_Degrade = 3'b011`)
When the physical link is operating with all 16 lanes active, the block acts as a zero-latency passthrough.
* **Behavior:** Upon receiving a valid input handshake (`EN && Deser_Done`), the block immediately maps the 128-bit `Ip_Bytes` input directly to the `WR_DATA` output.
* **Handshake:** The `WR_EN` output is asserted in the exact same clock cycle. 

### 3.2 Degraded Lower Mode (`Width_Degrade = 3'b001`)
When the physical link is degraded to operate only on the lower 8 lanes (Lanes 7:0), the block requires two valid input handshakes to assemble a complete 128-bit word.
* **Frame 1 (Capture):** On the first valid handshake, the block captures the lower 64 bits of the input (`Ip_Bytes[63:0]`). `WR_EN` remains **low**. The upper 64 bits of the input are ignored.
* **Frame 2 (Assembly):** On the second valid handshake, the block extracts the new lower 64 bits (`Ip_Bytes[63:0]`). It concatenates the newly received data into the upper half of the output word, and the previously cached Frame 1 data into the lower half. 
* **Output:** `WR_DATA` is driven as `{Frame2_Ip_Bytes[63:0], Frame1_Ip_Bytes[63:0]}`. `WR_EN` is asserted for exactly one clock cycle.

### 3.3 Degraded Upper Mode (`Width_Degrade = 3'b010`)
When the physical link is degraded to operate only on the upper 8 lanes (Lanes 15:8), the block performs the exact same two-cycle aggregation as Lower Mode, but targets the upper data boundaries.
* **Frame 1 (Capture):** On the first valid handshake, the block captures the upper 64 bits of the input (`Ip_Bytes[127:64]`). `WR_EN` remains **low**. The lower 64 bits are ignored.
* **Frame 2 (Assembly):** On the second valid handshake, the block extracts the new upper 64 bits (`Ip_Bytes[127:64]`). 
* **Output:** `WR_DATA` is driven as `{Frame2_Ip_Bytes[127:64], Frame1_Ip_Bytes[127:64]}`. `WR_EN` is asserted for exactly one clock cycle.

## 4. Dynamic Width Reconfiguration & Abort (`Width_Degrade_Update`)

The block must safely handle dynamic width changes commanded by the system controller without deadlocking the datapath.
* **Synchronous Flush:** If `Width_Degrade_Update` asserts, it indicates the link configuration has changed. The block must immediately abort any in-progress degraded frame aggregation, clear its internal cached data register, and synchronously reset its state machine back to Frame 1.
* **Deadlock Prevention:** This ensures that if the link is interrupted after receiving only one half of a degraded data word, the stale half-word is discarded and does not corrupt the next valid data phase.

## 5. Reset & Exception Handling

* **Asynchronous Reset:** Assertion of `R_RST_n` (low) unconditionally and asynchronously clears any cached/partial data frames. It immediately forces both `WR_EN` and `WR_DATA` to `0`.
* **Pipeline Stalls:** If `EN` or `Deser_Done` drops to `0` during a degraded-mode cycle (e.g., between Frame 1 and Frame 2), the block suspends aggregation. `WR_EN` is strictly held low, and any partially captured data from Frame 1 is preserved until the handshake resumes.
* **Illegal Width Configurations:** If `Width_Degrade` is driven with unmapped or reserved encodings (e.g., `3'b000`, `3'b100`-`3'b111`), the block must strictly prohibit data writes (`WR_EN` remains forced to `0`) and avoid initiating internal state transitions to prevent downstream FIFO corruption.