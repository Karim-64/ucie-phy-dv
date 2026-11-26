---
name: rtl-blackbox-spec-writer
description: Reads Verilog/SystemVerilog RTL files alongside a design or protocol specification to produce a professional, verifier-safe black-box functional description. Use whenever a verification engineer asks to summarize an RTL block, write a black-box spec, extract a module's external interface and behavioral contract without looking at the RTL directly, or prepare a functional description before building a UVM testbench or verification plan.
---

# RTL Black-Box Spec Writer

Produce an unbiased, verification-ready black-box functional description of a digital hardware block by combining authoritative design specifications with boundary-level extraction from Verilog or SystemVerilog RTL. This keeps the verification engineer isolated from white-box implementation details so reference models, assertions, and testbenches remain truly independent.

## When to Use

- The user wants a black-box functional description (`.md`) of an RTL module before writing a verification plan, UVM testbench, or golden reference model.
- The user provides an RTL file (`.v`, `.sv`) together with a protocol spec, architecture doc, or requirements and wants a unified external behavioral description.
- The user explicitly asks to inspect the RTL on their behalf so they do not read the RTL directly and introduce white-box bias.
- The user needs a clean port map, clock/reset domain table, timing contract, and corner-case summary derived without exposing internal RTL code.

## Core Isolation and Authority Rules

### 1. Maintain a Strict Black-Box Firewall

Never expose white-box implementation details in the output. The verifier must only see what is observable at the module pins.

- **Forbidden:** Internal signal names, internal registers or wires, FSM state names or encodings, internal sub-module hierarchy, line numbers, code structure descriptions, or RTL code snippets.
- **Allowed:** Module name, parameters, external ports, typedef/struct field definitions used on external ports, clock/reset relationships, and externally observable input-to-output behavior.

### 2. Enforce Spec-First Precedence (Prevent Bug Mirroring)

The single biggest danger when reading RTL for a verifier is accidentally documenting an RTL bug as "expected behavior," which causes the verifier to replicate the same bug in their scoreboard.

- **Spec governs behavior:** When both a specification and RTL are provided, treat the specification as the sole authority for functional requirements, protocol rules, and legal latency ranges.
- **RTL governs the physical boundary:** Use the RTL only to extract exact module names, port names, bit widths, parameter defaults, active polarities, clock/reset domain memberships, and spec-silent implementation choices.
- **Never rationalize RTL bugs:** If the RTL appears to contradict the specification, document the **specification's required behavior** in the main functional description so the verifier's testbench naturally catches the defect. Do not modify the functional description to match buggy RTL, and do not reveal the internal RTL defect unless the user explicitly requests a white-box review.
- **Tag provenance explicitly:** Whenever a detail is absent from the spec and had to be inferred from the RTL (such as reset polarity, default tie-offs, or exact cycle latency), append `[Inferred from RTL - confirm with designer]`.
- **RTL-only fallback warning:** If the user provides RTL with no specification, place a prominent warning at the top of the document stating that functional behavior was derived from RTL alone and must be validated against design intent before locking down a golden reference model.

## Workflow Steps

1. **Resolve Inputs and Boundary Types**

   Read the provided specification (if any) and the target RTL top module. Follow imported packages (`*_pkg.sv`) or included headers (`.svh`, `.vh`) strictly to resolve parameter values, port widths, and external struct or enum field layouts. Do not document internal sub-modules.

2. **Map the External Boundary**

   Catalog every parameter, clock, reset, and I/O port. Map each port to its exact clock domain, reset domain, active polarity, and reset output value. If multiple clocks or resets exist, explicitly document the CDC and RDC boundaries from an external pin perspective.

3. **Write Purely Observable Functional Behavior**

   Express all behavior as input-to-output causality: operating modes, data transformations, arbitration or priority rules, flow control, backpressure, cycle latency, ordering guarantees, and reset or error handling. Replace any internal state thinking with observable interface history (for example, write "after `req` is asserted and before `ack` is sampled high" instead of naming an internal FSM state).

4. **Audit Spec Gaps Without Leaking Internals**

   Identify ambiguities, missing corner-case rules (back-to-back traffic, simultaneous control assertions, boundary values, asymmetric multi-reset sequences), and all RTL-inferred details. List them as concrete questions for the RTL designer phrased strictly in external port terms.

5. **Run the Black-Box Sanitization Check**

   Before delivering the final document, verify every criterion below:

   - Zero internal signal, register, wire, FSM state, or sub-module names appear anywhere in the document.
   - Zero RTL code snippets or source line numbers appear.
   - Every port in the RTL module header is accounted for in the Port Map with direction, width, clock domain, reset domain, and reset value (for outputs).
   - Every port using a package struct or enum has its visible fields and bit layout expanded so the verifier does not need to open RTL files.
   - All details inferred from RTL where the spec was silent are tagged with `[Inferred from RTL - confirm with designer]`.

## Standard Output Structure

Output the black-box functional description in clean Markdown using this structure (adapt section depth to block complexity, and save to a `.md` file if the user requests a file output):

# <Module Name> - Black-Box Functional Description

> **Source Basis:** <Spec document name(s) + RTL boundary extraction | WARNING: RTL-only extraction - confirm functional intent with designer before writing reference model>

## 1. Block Overview

Concise summary of the block's architectural role, primary inputs/outputs, and core responsibilities.

## 2. Parameters and Configuration

| Parameter | Default | Valid Range / Constraints | Black-Box Functional Impact |
| :--- | :--- | :--- | :--- |

## 3. Clock and Reset Domains

| Signal | Type (Clock / Reset) | Polarity / Edge | Sync or Async | Associated Interface / Ports | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |

- Explicitly state the reset de-assertion and multi-reset contract (for example, whether independent resets can assert asymmetrically during active traffic).

## 4. External Interface (Port Map)

Group ports logically by interface (e.g., Control, Data Input, Data Output, Sideband).

| Port Name | Direction | Width / Type | Clock Domain | Reset Domain | Reset Value | Polarity | Black-Box Description |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |

- If any port uses a custom struct or enum from a package, include a compact field/encoding table right beneath the Port Map.

## 5. Functional Behavior and Operating Modes

Describe all observable behaviors strictly in terms of external inputs, outputs, and parameters:

- Operating modes and mode selection rules
- Data transformations, framing, or encoding rules
- Priority, arbitration, and tie-breaking rules
- Observable side effects and status indicators

## 6. Protocol and Timing Contracts

- **Handshake Rules:** Valid/ready, req/ack, or pulse requirements (including minimum pulse width for CDC inputs).
- **Latency:** Exact or bounded min/max cycle latency from input event to output response.
- **Throughput and Backpressure:** Back-to-back transfer capability, stall behavior, and input stability requirements while stalled.
- **Ordering:** In-order, out-of-order, or channel isolation guarantees.

## 7. Reset, Corner Cases, and Error Handling

- Power-on and mid-operation reset behavior on outputs.
- Asymmetric or staggered reset behavior (for multi-reset blocks).
- Boundary conditions: min/max payload, zero-length, full/empty, overflow/underflow, simultaneous assertions, and illegal input combinations.

## 8. Spec Gaps and Questions for the Designer

- List every `[Inferred from RTL - confirm with designer]` assumption.
- List any spec ambiguities or unspecified corner cases phrased strictly in terms of external pins.

## Gotchas

- **Leaking internal FSM names:** Never describe behavior via internal state names like `IDLE` or `WAIT_DONE` unless those exact states are exposed on an external status port or mandated by the architecture spec.
- **Over-constraining timing:** When the spec specifies a legal latency window (such as 2 to 3 destination clock cycles across a synchronizer), document the spec window rather than pinning it to one exact cycle observed in the RTL.
- **Ignoring multi-clock and multi-reset contracts:** Never assume all ports share one clock or that multiple resets assert together. Explicitly map every port's clock and reset domain and flag unstated asymmetric reset behavior as a designer question.
- **Leaving typedefs opaque:** If an interface uses `my_pkt_t`, the verifier should not have to open `*_pkg.sv` to know its bit fields. Always unpack external port types into a readable table.
- **Quietly merging RTL bugs into the spec:** Always treat contradictions between RTL and spec in favor of the spec so verification actually finds bugs instead of masking them.
