# MUX_SBRX Verification Sequences Summary

This document describes the stimulus sequences developed for the IP-level verification of the `MUX_SBRX` (2:1 Multiplexer).

---

## 1. Random Sequence (`mux_sbrx_rand_seq`)
* **File:** [`sequences/mux_sbrx_rand_seq.svh`](sequences/mux_sbrx_rand_seq.svh)
* **Transaction Count:** 200 items
* **Objective:** Broad randomized functional verification and exploration of the input state space.
* **Stimulus Details:**
  * Driven by default constraints in `mux_sbrx_sequence_item`:
    * Balanced 50/50 distribution on `sel` (`0` vs `1`).
    * Weighted corner cases (`5'h00`, `5'h1F`, `5'h15`, `5'h0A`) alongside evenly distributed mid-range values (`[5'h01:5'h1E]`).
    * Soft constraint enforcing `in0 != in1` to prevent false positive passes where both inputs are identical.

---

## 2. Corner-Case Sequence (`mux_sbrx_corner_seq`)
* **File:** [`sequences/mux_sbrx_corner_seq.svh`](sequences/mux_sbrx_corner_seq.svh)
* **Transaction Count:** 32 items ($4 \times 4 \times 2$)
* **Objective:** Exhaustive cross-verification of critical boundary conditions across both data ports.
* **Stimulus Details:**
  * Defines 4 representative corner patterns:
    * All Zeros: `5'h00` (`5'b00000`)
    * All Ones: `5'h1F` (`5'b11111`)
    * Alternating 10101: `5'h15`
    * Alternating 01010: `5'h0A`
  * Executes a complete nested loop over:
    * All 4 corner patterns applied to `in0`.
    * All 4 corner patterns applied to `in1`.
    * Both `sel` states (`0` and `1`).

---

## 3. Isolation Sequence (`mux_sbrx_isolation_seq`)
* **File:** [`sequences/mux_sbrx_isolation_seq.svh`](sequences/mux_sbrx_isolation_seq.svh)
* **Transaction Count:** 40 items
* **Objective:** Validates channel isolation and ensures that the unselected input port does not leak or corrupt the active output.
* **Stimulus Details:**
  * For every transaction, `in1` is constrained to the exact bitwise inverse of `in0` (`in1 == ~in0`).
  * `sel` toggles deterministically each transaction (`sel == i % 2`).
  * Ensures that switching the select line routes the expected inverted data without any bit bleed-through.

