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
  1. Stream multiple header-only messages back-to-back on consecutive cycles for a single master.
  2. Immediately issue a new request on the cycle *directly following* the completion of a 2-phase locked transaction.
* **Expected Outcome:** Verify whether the state machine requires a mandatory 1-cycle idle bubble after a 2-cycle lock release (where `Last_Priority` resets to `NONE`), ensuring back-to-back requests across lock boundaries handle re-arbitration correctly without dropping packets.

---

## 6. Reactive Retry Loop (End-to-End Resend Completion)
* **Objective:** Verify that an upstream master receiving a resend request (`*_Resend_Req = 1`) successfully backs off and re-drives its transaction after the block becomes available.
* **Execution Steps:**
  1. Induce a contention or lock rejection so that `*_Resend_Req` asserts for a specific master.
  2. Have the agent's driver react to `*_Resend_Req` by holding or re-issuing the packet once `*_Resend_Req` drops back to `0`.
* **Expected Outcome:** The priority lock cleanly releases, the deferred packet is accepted on the subsequent attempt, and its data makes it into the FIFO intact.

---

## 7. Simultaneous Contention During a Lock (`BOTH_ACTIVE` Edge Case)
* **Objective:** Validate how the arbiter behaves when both masters are active (`BOTH_ACTIVE`) while a multi-cycle Priority Lock is already held by one of the masters.
* **Execution Steps:**
  1. Initiate a 2-phase packet from the D2D Decoder, locking the priority.
  2. During the active lock window (Cycle $N+1$), keep the D2D Decoder active (`D2D_En = 1`) while simultaneously asserting the PHY Controller request (`PHY_En = 1`).
* **Expected Outcome:** Verify whether the RTL correctly identifies the conflicting request and asserts the appropriate resend flag (`PHY_Resend_Req`) without erroneously penalizing the locked master.

---

## 8. Mid-Transaction Asynchronous Reset (`RST_n`) Recovery
* **Objective:** Verify that asserting the asynchronous reset (`RST_n = 0`) mid-transaction immediately flushes all internal states and outputs to a safe idle state.
* **Execution Steps:**
  1. Grant access to a master and assert `RST_n = 0` right between the Header Phase and Data Phase of a locked 2-phase transaction.
  2. De-assert `RST_n = 1` on the following cycle and issue a standard 1-phase sanity packet.
* **Expected Outcome:** All internal states (`Priority_Lock`, `Lock_Counter`, `Last_Priority`, `*_Resend_Req`) and FIFO outputs (`FIFO_WR`, data, markers) clear to `0` instantly. The block recovers cleanly and processes subsequent packets normally without remaining "half-locked."