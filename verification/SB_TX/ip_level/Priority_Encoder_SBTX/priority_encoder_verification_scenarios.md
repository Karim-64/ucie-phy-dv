# Verification Scenarios for Priority Encoder (`Priority_Encoder_SBTX`)

This document outlines the core verification scenarios required to thoroughly validate the `Priority_Encoder_SBTX` module across its normal operational modes, contention conditions, priority-lock atomicity, and edge-case exceptions.

---

## 1. Normal Sanity Sequence
* **Objective:** Verify basic, uncontended single-cycle write operations and multi-phase packet handling for both ingress paths in isolation.
* **Execution Steps:**
  1. Inject single-phase (header-only, `Data_Marker = 0`) messages independently through the D2D interface (`D2D_En`) while PHY is idle. Verify correct data, markers, and `FIFO_WR` appearance at the CDC FIFO egress.
  2. Inject two-phase (header + data, `Data_Marker = 1`) messages through the D2D interface. Verify that the 2-cycle lock window executes correctly and both phases are written sequentially without interruption.
  3. Repeat steps 1 and 2 independently for the PHY Controller interface (`PHY_En`) while D2D is idle.
* **Expected Outcome:** Uncontended transactions pass through immediately with correct data and control tags (`D2D_PHY_Marker`, `Data_Marker`, `Comp_Marker`).

---

## 2. Priority & Contention Check
* **Objective:** Verify arbitration behavior when both masters assert their enable requests simultaneously (`BOTH_ACTIVE`).
* **Execution Steps:**
  1. Assert `PHY_En` and `D2D_En` on the exact same clock cycle.
  2. Monitor the arbitration winner at the FIFO egress and observe the response flags.
* **Expected Outcome:** The PHY Controller is strictly prioritized and granted access to the FIFO. A resend request (`D2D_Resend_Req = 1`) is issued to the D2D Decoder for that cycle, while `PHY_Resend_Req` remains low.

---

## 3. Mid-Message Locking (Mid-of-Message Interruption)
* **Objective:** Verify that a multi-cycle (2-phase) packet's atomicity is protected by the Priority Lock mechanism and cannot be broken by competing requests.
* **Execution Steps:**
  1. Grant access to a master (e.g., D2D) sending a 2-phase packet (`Data_Marker = 1`).
  2. During **Lock Cycle 1** (while the header phase is being processed), have the competing master (PHY) assert its enable request (`PHY_En = 1`).
  3. Repeat the test by asserting the competing master's enable request during **Lock Cycle 2** (while the data phase is being processed).
* **Expected Outcome:** The competing master's request is ignored by the arbiter, its data is blocked from interleaving, and a resend request (`*_Resend_Req = 1`) is asserted to the interrupter. The ongoing 2-phase packet completes its second phase uninterrupted.

---

## 4. Completion Marker (`Comp_Marker_D2D`) Filtering & Passthrough
* **Objective:** Verify that D2D completion markers are correctly propagated when D2D wins, and strictly suppressed (forced to `0`) whenever the PHY wins.
* **Execution Steps:**
  1. Send a D2D message with `Comp_Marker_D2D = 1` while uncontended. Verify `Comp_Marker` is driven high at the FIFO output.
  2. Send a D2D message with `Comp_Marker_D2D = 1` during simultaneous contention with the PHY.
* **Expected Outcome:** When PHY wins contention, `Comp_Marker` at the FIFO output is forced to `0`, ignoring the D2D completion flag until D2D is individually granted access.

---

## 5. Back-to-Back Traffic & The Post-Lock Bubble
* **Objective:** Test high-throughput back-to-back traffic patterns and verify behavior around the 1-cycle post-lock cooldown window.
* **Execution Steps:**
  1. Stream multiple header-only messages back-to-back on consecutive cycles for a single master (D2D and PHY independently).
  2. Immediately issue a single-master request on the cycle *directly following* the completion of a D2D 2-phase locked transaction (during the post-lock cooldown bubble).
  3. Complete a PHY 2-phase locked transaction and immediately assert **both** `PHY_En = 1` and `D2D_En = 1` (`BOTH_ACTIVE`) during the 1-cycle post-lock cooldown bubble.
* **Expected Outcome:** Verify that the state machine enforces the mandatory 1-cycle idle bubble after a 2-cycle lock release (`Last_Priority` resets to `NONE`), and handles single-master and contended re-arbitration cleanly in the cooldown cycle without dropping packets.

---

## 6. Reactive Retry Loop (End-to-End Resend Completion)
* **Objective:** Verify that an upstream master receiving a resend request (`*_Resend_Req = 1`) successfully detects the NACK via `p_sequencer.seqr_fifo`, backs off, and reactively re-drives its enable and data until accepted.
* **Execution Steps:**
  1. **D2D Reactive Retry:** Assert D2D 1-phase request simultaneously with a PHY 2-phase packet so `D2D_Resend_Req = 1` is asserted. The D2D sequence monitors `p_sequencer.seqr_fifo` in a `do ... while (rsp.resend_req === 1'b1)` loop and reactively re-sends its enable and payload until `D2D_Resend_Req = 0`.
  2. **PHY Reactive Retry:** Assert PHY 1-phase request during an active D2D 2-phase lock so `PHY_Resend_Req = 1` is asserted. The PHY sequence monitors `p_sequencer.seqr_fifo` in a `do ... while (rsp.resend_req === 1'b1)` loop and reactively re-sends its enable and payload until `PHY_Resend_Req = 0`.
* **Expected Outcome:** Each rejected master detects its NACK, the priority lock releases cleanly, and the deferred packet is accepted on the subsequent attempt with its payload intact in the CDC FIFO.

---

## 7. Simultaneous Contention During a Lock (`BOTH_ACTIVE` Edge Case)
* **Objective:** Validate how the arbiter behaves when both masters are active (`BOTH_ACTIVE`) while a multi-cycle Priority Lock is already held by either master across both Lock Cycle 1 and Lock Cycle 2, with reactive NACK recovery on both sides.
* **Execution Steps:**
  1. **Sub-test 7a (D2D Lock, Lock Cycle 1):** D2D initiates a 2-phase packet; during **Lock Cycle 1**, both `D2D_En = 1` and `PHY_En = 1` are asserted simultaneously. Both sequences check `seqr_fifo` and reactively retry if `resend_req == 1`.
  2. **Sub-test 7b (PHY Lock, Lock Cycle 1):** PHY initiates a 2-phase packet; during **Lock Cycle 1**, both `PHY_En = 1` and `D2D_En = 1` are asserted simultaneously, with reactive NACK retry on both sides.
  3. **Sub-test 7c (D2D Lock, Lock Cycle 2):** D2D initiates a 2-phase packet; during **Lock Cycle 2**, both `D2D_En = 1` and `PHY_En = 1` are asserted simultaneously, with reactive NACK retry on both sides.
  4. **Sub-test 7d (PHY Lock, Lock Cycle 2):** PHY initiates a 2-phase packet; during **Lock Cycle 2**, both `PHY_En = 1` and `D2D_En = 1` are asserted simultaneously, with reactive NACK retry on both sides.
* **Expected Outcome:** `D2D_Resend_Req` is asserted (`1'b1`) and `PHY_Resend_Req` remains low (`1'b0`) on all `BOTH_ACTIVE` cycles per specification, the ongoing 2-phase packet completes uninterrupted, and the NACKed master successfully retries after lock release.

---

## 8. Mid-Transaction Asynchronous Reset (`RST_n`) Recovery
* **Objective:** Verify that asserting the asynchronous reset (`RST_n = 0`) mid-transaction immediately flushes all internal states and outputs to a safe idle state for both D2D-locked and PHY-locked transfers.
* **Execution Steps:**
  1. **Mid-D2D-Lock Reset:** Grant access to D2D for a 2-phase transaction, assert `RST_n = 0` between the Header Phase and Data Phase, de-assert `RST_n = 1` on the following cycle, and issue post-reset 1-phase sanity packets on both D2D and PHY.
  2. **Mid-PHY-Lock Reset:** Grant access to PHY for a 2-phase transaction, assert `RST_n = 0` between the Header Phase and Data Phase, de-assert `RST_n = 1` on the following cycle, and issue a post-reset 1-phase sanity packet on PHY.
* **Expected Outcome:** All internal states (`Priority_Lock`, `Lock_Counter`, `Last_Priority`, `*_Resend_Req`) and FIFO outputs (`FIFO_WR`, data, markers) clear to `0` instantly. The block recovers cleanly from both D2D and PHY mid-lock resets and processes subsequent packets normally.

---

## 9. Coverage Closure Sequence
* **Objective:** Close remaining RTL expression coverage (FEC targets) and cross-coverage corner cases not exercised by standard traffic.
* **Execution Steps:**
  1. **Same-Master Request During Own Lock (`Last_Priority == D2D_ONLY` / `PHY_ONLY`):**
     * D2D initiates a 2-phase packet and keeps `D2D_En = 1` (with `PHY_En = 0`) during Lock Cycle 1, exercising `(Last_Priority != D2D_ONLY & Priority_Lock) == 0` without triggering a false `D2D_Resend_Req`.
     * PHY initiates a 2-phase packet and keeps `PHY_En = 1` (with `D2D_En = 0`) during Lock Cycle 1, exercising `(Last_Priority != PHY_ONLY & Priority_Lock) == 0` without triggering a false `PHY_Resend_Req`.
  2. **Lock Cycle 2 Cross Corner:** Assert `D2D_En = 1, Data_Marker_D2D = 1` while `PHY_En = 0, Data_Marker_PHY = 1` during PHY Lock Cycle 2.
* **Expected Outcome:** Achieves `100.00%` DUT code coverage across Branch, Expression, Statement, and Toggle metrics with zero scoreboard mismatches.

---

## 10. Randomized Stress Sequence
* **Objective:** Stress-test arbitration, multi-phase locking, completion marker propagation, and reactive NACK recovery under unpredictable randomized timing and traffic mixes.
* **Execution Steps:**
  1. Launch `pe_sbtx_D2D_rand_seq` and `pe_sbtx_PHY_rand_seq` concurrently via `fork ... join`, each configured for `100` transactions (`num_tx = 100`).
  2. For every transaction, randomize packet type (1-phase vs. 2-phase), `Comp_Marker_D2D` (for D2D), 64-bit header/data payloads, and inter-transaction idle gaps (`0..4` cycles).
  3. After each attempt, check `p_sequencer.seqr_fifo` for `resend_req === 1'b1` (NACK); on NACK, apply a randomized backoff (`0..2` cycles) and re-issue the exact same packet until accepted.
* **Expected Outcome:** All 100 D2D and 100 PHY transactions complete and are written to the CDC FIFO in exact cycle-accurate agreement with the scoreboard reference model (`Error Count : 0`).