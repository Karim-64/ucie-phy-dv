### 1. Should You Make Multiple Interfaces for These Agents?

**Yes, you should split them into separate SystemVerilog `interface` definitions, and only write TWO interface files (instantiating the ingress interface twice).**

Here is why this is the cleanest and most scalable approach:

1. **Write One Parameterized Ingress Interface (`pe_sbtx_in_if`), Instantiate It Twice:**
* Because the PHY Controller path and the D2D Decoder path have the exact same handshaking protocol (Enable, 64-bit Data, Data Marker, and Resend Request), you can define a single `pe_sbtx_in_if` that includes `Comp_Marker`.


* In your `tb_top`, you instantiate it twice: `pe_sbtx_in_if phy_if(clk, rst_n);` and `pe_sbtx_in_if d2d_if(clk, rst_n);`. For the `phy_if` instance, its `Comp_Marker` wire simply remains unconnected to the DUT (since the DUT has no `Comp_Marker_PHY` port).


* **The Benefit:** Your `pe_sbtx_in_driver` and `pe_sbtx_in_monitor` only need to hold one virtual interface type (`virtual pe_sbtx_in_if vif`). If you instead used one giant monolithic interface for the whole DUT, both the PHY driver and D2D driver would have to hardcode signal names (`vif.PHY_En` vs `vif.D2D_En`), which would force you to write `if (is_phy) ... else ...` branches on every single line of your driver and monitor!


2. **Write One Egress Interface (`pe_sbtx_out_if`):**
* Dedicated strictly to the downstream CDC FIFO write signals. The passive FIFO monitor connects only to `virtual pe_sbtx_out_if vif`, keeping input and output concerns completely decoupled.





---

### 2. Signal List for Every Agent

Every agent requires access to `CLK` and `RST_n` to synchronize its clocking blocks and handle reset cleanup. Below is the exact pin mapping for each of the three agents based on `Priority_Encoder_SBTX.sv`:

#### A. PHY Master Agent (`phy_agent` — Active, connected via `phy_if`)

| DUT Port Name | Interface Signal Name (`phy_if`) | Direction (Agent View) | Width | Agent Usage (Driver & Monitor) |
| --- | --- | --- | --- | --- |
| `CLK`

 | `clk` | Input | 1

 | Synchronizes driver and monitor clocking blocks. |
| `RST_n`

 | `rst_n` | Input | 1

 | Resets driver state (drives all outputs to `0`) and aborts active monitor captures. |
| `PHY_En`

 | `en` | **Driven** by Driver / Sampled by Monitor | 1

 | Asserted in Cycle $N$ to request FIFO write access.

 |
| `Data_Marker_PHY`

 | `data_marker` | **Driven** by Driver / Sampled by Monitor | 1

 | Asserted alongside `en` when sending a 2-phase (Header + Data) message.

 |
| `PHY_Data`

 | `data` | **Driven** by Driver / Sampled by Monitor | 64

 | Driven with Header phase in Cycle $N+1$ (and Data phase in Cycle $N+2$ if 2-phase).

 |
| *(None on DUT)* | `comp_marker` | Unused (Tied to `0`) | 1 | Kept in `pe_sbtx_in_if` for interface uniformity with D2D; driver forces `0`. |
| `PHY_Resend_Req`

 | `resend_req` | **Sampled** by Driver & Monitor | 1

 | Sampled by the reactive driver to detect lock rejection and trigger packet retry.

 |

---

#### B. D2D Master Agent (`d2d_agent` — Active, connected via `d2d_if`)

| DUT Port Name | Interface Signal Name (`d2d_if`) | Direction (Agent View) | Width | Agent Usage (Driver & Monitor) |
| --- | --- | --- | --- | --- |
| `CLK`

 | `clk` | Input | 1

 | Synchronizes driver and monitor clocking blocks. |
| `RST_n`

 | `rst_n` | Input | 1

 | Resets driver state (drives all outputs to `0`) and aborts active monitor captures. |
| `D2D_En`

 | `en` | **Driven** by Driver / Sampled by Monitor | 1

 | Asserted in Cycle $N$ to request FIFO write access.

 |
| `Data_Marker_D2D`

 | `data_marker` | **Driven** by Driver / Sampled by Monitor | 1

 | Asserted alongside `en` when sending a 2-phase (Header + Data) message.

 |
| `Comp_Marker_D2D`

 | `comp_marker` | **Driven** by Driver / Sampled by Monitor | 1

 | Driven alongside the message to flag D2D Completion packets.

 |
| `D2D_Data`

 | `data` | **Driven** by Driver / Sampled by Monitor | 64

 | Driven with Header phase in Cycle $N+1$ (and Data phase in Cycle $N+2$ if 2-phase).

 |
| `D2D_Resend_Req`

 | `resend_req` | **Sampled** by Driver & Monitor | 1

 | Sampled by the reactive driver to detect contention or lock rejection and trigger retry.

 |

---

#### C. FIFO Passive Agent (`fifo_agent` — Passive, connected via `fifo_if`)

| DUT Port Name | Interface Signal Name (`fifo_if`) | Direction (Agent View) | Width | Agent Usage (Monitor Only) |
| --- | --- | --- | --- | --- |
| `CLK`

 | `clk` | Input | 1

 | Synchronizes the passive monitor clocking block. |
| `RST_n`

 | `rst_n` | Input | 1

 | Used by monitor to verify that all FIFO outputs drop to `0` asynchronously during reset.

 |
| `FIFO_WR`

 | `fifo_wr` | **Sampled** by Monitor | 1

 | Valid qualifier; when `1'b1`, the monitor captures the bus signals into a transaction.

 |
| `FIFO_Data`

 | `fifo_data` | **Sampled** by Monitor | 64

 | Captured and sent to the Scoreboard to verify payload integrity against the winning master.

 |
| `Data_Marker`

 | `data_marker` | **Sampled** by Monitor | 1

 | Captured to verify `Data_Marker` passthrough and 2-cycle lock framing.

 |
| `D2D_PHY_Marker`

 | `d2d_phy_marker` | **Sampled** by Monitor | 1

 | Captured to verify source tagging (`1` = D2D won, `0` = PHY won).

 |
| `Comp_Marker`

 | `comp_marker` | **Sampled** by Monitor | 1

 | Captured to verify `Comp_Marker_D2D` passthrough when D2D wins, and `0` when PHY wins.

 |

---

Let me know if this interface partitioning and signal mapping looks good to you, and once you approve, we will dive into the verification plan!