# uvm_gen

Generates single-agent (`mem`-style) or multi-agent (`Priority_Encoder_SBTX`-style)
UVM verification environments from a single XML spec file.

The mode is chosen automatically from the XML:
- `<signals>` at root -> **single-agent** mode (`mem` layout)
- `<agents>` + `<interfaces>` at root -> **multi-agent** mode (`Priority_Encoder_SBTX` layout)

## Quick Start (Copy & Paste)

Requires Python 3.10+ and `jinja2` (`pip install jinja2`).

```bash
# Quick Command to run 
python generate_uvm.py --config spec.xml --out-dir ./generated --force

# Run from scripts/uvm_gen/ (multi-agent example)
python generate_uvm.py --config examples/pe_sbtx_spec.xml --out-dir ./generated --force

# Preview files without writing anything
python generate_uvm.py --config examples/pe_sbtx_spec.xml --out-dir ./generated --dry-run

# Single-agent example
python generate_uvm.py --config examples/mem_spec.xml --out-dir ./generated --force
```

> On Windows you can replace `python` with `py`.

Output lands at `<out-dir>/<env_name>/...`. Copy your DUT source files
(`.sv` / `.v`) into `<out-dir>/<env_name>/RTL/`, then run QuestaSim from
`sim/`:

```bash
cd generated/pe_sbtx/sim
vsim -do run.do
```

## Features & How to Use Them

| Feature | What it generates / does | How to use it |
|---------|--------------------------|---------------|
| **Multi-agent environments** | Separate UVCs (`components/<AGT>_agent/`), per-agent sequence items & base sequences, virtual sequencer (`vseqr`), and virtual sequence (`vseq`) | Add `<interfaces>` and `<agents count="N">` with `<agent name="D2D" .../>` entries |
| **Single-agent environments** | Compact single-agent UVM environment (`mem` layout) | Put `<signals>` directly under `<uvm_env>` (no `<agents>`) |
| **Active & passive agents** | Active agents get driver + sequencer + base sequence (`drive_<agt>_item` / `drive_<agt>_idle`) + TLM feedback (`seqr_aport` -> `mon_aimp`, `mon_aport` -> `seqr_aexport`/`seqr_fifo`); passive agents get monitor + agent only | Set `mode="active"` or `mode="passive"` on each `<agent>` |
| **Reusable interfaces** | One `.sv` interface per `<interface>` definition with `drv_cb` & `mon_cb` clocking blocks; multiple agents can share one interface type with separate instances in `tb_top` | Define `<interface name="in">` under `<interfaces>` and reference it via `interface="in"` on `<agent>` |
| **TLM-FIFO scoreboard** | `uvm_analysis_export` + `uvm_tlm_analysis_fifo` per connected agent, `run_phase` (skipping cycle 0), `ref_model()` stub, auto-generated `check_results()` (including `foreach` for unpacked arrays), and `report_phase()` summary | Set `<has_scoreboard>true</has_scoreboard>` in `<env>` and `scoreboard="true\|false"` per `<agent>` |
| **Multi-agent coverage collector** | Extends `uvm_component` with `` `uvm_analysis_imp_decl(_<agt>) ``, `write_<agt>()`, cycle-synchronized `all_valid()` -> `sample_and_advance()` -> `update_state()`, and generic per-agent covergroups | Set `<has_coverage>true</has_coverage>` in `<env>` and `coverage="true\|false"` per `<agent>` |
| **Parameters, localparams & arrays** | Overridable `<parameter>`s, interface-only `<localparam>`s (auto-inlined in package code), expression widths (`2*NC`, `$clog2(N)`), packed 2D (`depth`), unpacked (`unpacked`), and idle defaults (`idle`) | Declare under `<parameters>` and use `width`, `depth`, `unpacked`, `idle` attributes on `<signal>` |
| **DUT wiring & Questa `run.do`** | Instantiates DUT in `tb_top.sv`, registers VIFs in `uvm_config_db`, and generates `sim/run.do` with ordered RTL compilation and code/functional coverage reports | Add `<dut>` with `<module_name>`, optional `<rtl_file>`, and `<port>` mappings |
| **Fail-fast XML validation & CLI flags** | Validates all identifiers, agent counts, widths, interfaces, and DUT ports before writing any file | Use `--dry-run` to validate/preview and `--force` to overwrite an existing output folder |

## XML reference

Complete skeleton (every supported option; optional parts are marked):

```xml
<uvm_env name="agent_name">                       <!-- required: prefix of every generated file/class -->

  <parameters>                                    <!-- optional -->
    <parameter  name="DATA_WIDTH" value="128"/>   <!-- 0+, overridable, passed to interface and DUT -->
    <localparam name="NUM_BYTES"  value="DATA_WIDTH/8"/>  <!-- 0+, fixed constants -->
  </parameters>

  <clock name="clk"/>                             <!-- required -->

  <signals>                                       <!-- required: >=1 "drv" and >=1 "mon" -->
    <signal name="rst"  width="1"          direction="drv"/>
    <signal name="data" width="DATA_WIDTH" direction="drv"/>
    <signal name="buf"  width="8" depth="NUM_BYTES" direction="mon"/>     <!-- packed array   -->
    <signal name="lane" width="8" unpacked="16"     direction="mon"/>     <!-- unpacked array -->
  </signals>

  <dut>                                           <!-- optional: omit to leave the DUT out of tb_top -->
    <module_name>MyDut</module_name>              <!-- required inside <dut> -->
    <instance_name>dut</instance_name>            <!-- optional, default "dut" -->
    <port dut_port="data_in" signal="data"/>      <!-- 1+ ; signal = a <signal> name or the clock -->
  </dut>

  <env>                                           <!-- optional -->
    <has_scoreboard>true</has_scoreboard>         <!-- optional, default true -->
    <has_subscriber>true</has_subscriber>         <!-- optional, default true -->
  </env>
</uvm_env>
```

### `<uvm_env>`

| Attribute | Required | Meaning |
|-----------|----------|---------|
| `name`    | yes      | Valid SystemVerilog identifier. Used as the prefix for all generated files and classes (`<name>_driver`, `<name>_if`, `<name>_pkg`, ...). |

### `<parameters>`

Optional block holding any number of `<parameter>` and `<localparam>`
elements. Both take `name` (identifier) and `value` (any non-empty
SystemVerilog constant expression, emitted verbatim).

| Element        | Overridable | Where it is emitted |
|----------------|-------------|---------------------|
| `<parameter>`  | yes         | package (`parameter`), interface `#(...)` header, `virtual <name>_if#(...)` references, and the `.NAME(NAME)` overrides on both the interface and the DUT instance in `tb_top` |
| `<localparam>` | no          | **inside the interface body only**. Not declared in the package, and never passed through `#(...)` to the interface or the DUT |

Rules:
- Names are unique across *both* kinds. Localparams cannot be referenced by hand-written package code; use a `<parameter>` for anything your own testbench code needs.
- All `<parameter>`s are emitted before all `<localparam>`s. A `<localparam>`
  value may use any `<parameter>` and any `<localparam>` declared **earlier**
  in the XML; anything else is rejected. (A `<parameter>` default that refers
  to a `<localparam>` is therefore not supported.)
- Because the package cannot see interface localparams, package-side code (sequence
  item, subscriber) gets each localparam's *value* substituted into the sizes that use it:
  with `<localparam name="HALF" value="NC/2"/>` and `width="HALF"`, the interface has
  `[HALF-1:0]` while the sequence item has `[NC/2-1:0]`; a localparam that is a plain
  number (`16`) becomes `[15:0]` there.
- Every `<parameter>` is passed to the DUT as `.NAME(NAME)`, so the DUT must
  declare a parameter of the same name. If it does not, leave the parameter
  out of the XML and use a literal width instead, or turn it into a
  `<localparam>`.

### `<clock>`

`<clock name="clk"/>` is required. The name may be anything (`MB_CLK`,
`CLK`, ...). It becomes the interface clock input, the clocking-block event
and the `tb_top` clock generator. No signal may use the clock's name, and
`clk` is reserved as a signal name.

### `<signal>`

One element per interface signal (clock excluded; reset is just a normal
signal).

| Attribute  | Required | Meaning |
|------------|----------|---------|
| `name`     | yes      | Identifier, unique among signals. |
| `width`    | yes      | Bit width of one element. A size (see below). `1` gives a plain `logic`. |
| `direction`| yes      | `drv` = driven into the DUT (`rand` field in the sequence item, driven through `drv_cb`). `mon` = sampled from the DUT (non-`rand` field, sampled through `mon_cb`). |
| `depth`    | no       | Adds an outer **packed** dimension: `logic [depth-1:0][width-1:0]`. |
| `unpacked` | no       | Adds an **unpacked** dimension: `logic [width-1:0] name [unpacked-1:0]`. May be combined with `depth`. |

At least one signal must be `drv` and at least one `mon`.

#### Sizes: `width`, `depth`, `unpacked`

A size can be written as:

| Form | Example | Generated range |
|------|---------|-----------------|
| integer literal (>= 1) | `64` | `[63:0]` |
| parameter / localparam name | `DATA_WIDTH` | `[DATA_WIDTH-1:0]` |
| constant expression | `2*NC` | `[2*NC-1:0]` |
| | `NC+8` | `[(NC+8)-1:0]` |
| | `NC<<1`, `$clog2(NC)` | `[(NC<<1)-1:0]`, `[($clog2(NC))-1:0]` |
| numbers only | `2*32` | folded to `64`, so `[63:0]` |

Allowed in an expression: declared parameter/localparam names, integers,
`+ - * / % ( ) << >>`, sized literals such as `8'd4`, and `$` system
functions such as `$clog2(...)`. Parentheses are added around the
expression only where the trailing `-1` needs them. An unknown name, a
disallowed character, or a value that evaluates to zero or less is rejected
with an error naming the signal.

#### Mapping SystemVerilog ports to XML

| SystemVerilog port | XML |
|--------------------|-----|
| `input logic rst` | `<signal name="rst" width="1" direction="drv"/>` |
| `input [31:0] a` | `<signal name="a" width="32" direction="drv"/>` |
| `input [NC-1:0] lp_cfg` | `<signal name="lp_cfg" width="NC" direction="drv"/>` |
| `output [2*NC-1:0] msg` | `<signal name="msg" width="2*NC" direction="mon"/>` |
| `input [63:0][7:0] data` (packed 2D) | `<signal name="data" width="8" depth="64" direction="drv"/>` |
| `output reg [7:0] Lanes [15:0]` (unpacked) | `<signal name="Lanes" width="8" unpacked="16" direction="mon"/>` |
| `logic [3:0] x [2][8]`-style multi-dimension unpacked | not supported (one unpacked dimension only) |

Generation notes for arrays:
- Unpacked ranges are always emitted as `[N-1:0]`. A DUT port declared
  `[0:N-1]` would need the XML or the template adjusted.
- The sequence item's `convert2string` prints unpacked arrays element by
  element (`$sformatf` cannot take them directly).
- The subscriber samples only the **first and last element** of an array
  signal (indexed through every dimension, e.g. `[0][0]` and `[15][63]`).
- `output reg` / `output logic` / `wire` on the DUT side make no difference;
  the interface always declares `wire logic ...`.

### `<dut>`

Optional. Omit it to generate a testbench without a DUT instance (the
`run.do` coverage commands then refer to a module called `DUT`).

| Element / attribute | Required | Meaning |
|---------------------|----------|---------|
| `<module_name>`     | yes      | DUT module name. |
| `<instance_name>`   | no       | Instance name in `tb_top`, default `dut`. |
| `<port dut_port="..." signal="..."/>` | 1 or more | Connects DUT port `dut_port` to interface signal `signal` (or to the clock if `signal` is the clock name). Port names are unique. Not every signal has to be wired. A `signal` that is neither the clock nor a declared signal is an error. |

### `<env>`

| Element | Default | Effect |
|---------|---------|--------|
| `<has_scoreboard>true\|false</has_scoreboard>` | `true`  | Generates `<name>_scoreboard` (TODO stub), its config bit, and the connection from the agent. |
| `<has_subscriber>true\|false</has_subscriber>` | `true`  | Generates `<name>_subscriber` (coverage), its config bit, and the connection from the agent. |

When a flag is `false` the corresponding file, config bit, environment code
and package `include` are all left out.

### Multi-agent XML reference (`<agents>`)

Complete multi-agent skeleton (see `examples/pe_sbtx_spec.xml` for a full
working example reproducing `Priority_Encoder_SBTX`):

```xml
<uvm_env name="pe_sbtx">
  <parameters>                                    <!-- optional, same rules as single-agent -->
    <parameter name="DATA_WIDTH" value="64"/>
  </parameters>

  <clock name="CLK"/>                             <!-- required -->

  <interfaces>                                    <!-- required: 1+ reusable interface defs -->
    <interface name="in">                         <!-- emits <env>_<name>_if -->
      <signal name="rst_n"       width="1"          direction="drv" idle="1'b1"/>
      <signal name="en"          width="1"          direction="drv"/>
      <signal name="data"        width="DATA_WIDTH" direction="drv"/>
      <signal name="resend_req"  width="1"          direction="mon"/>
    </interface>
    <interface name="out">
      <signal name="fifo_wr"     width="1"          direction="mon"/>
      <signal name="fifo_data"   width="DATA_WIDTH" direction="mon"/>
    </interface>
  </interfaces>

  <agents count="3">                              <!-- count optional; validated if present -->
    <agent name="D2D"  interface="in"  mode="active"  scoreboard="true" coverage="true"/>
    <agent name="PHY"  interface="in"  mode="active"  scoreboard="true" coverage="true"/>
    <agent name="FIFO" interface="out" mode="passive" scoreboard="true" coverage="false"/>
  </agents>

  <dut>                                           <!-- optional -->
    <module_name>Priority_Encoder_SBTX</module_name>
    <instance_name>dut</instance_name>            <!-- optional, default "dut" -->
    <rtl_file>Universal_pkg.sv</rtl_file>         <!-- optional, controls run.do vlog order -->
    <rtl_file>Priority_Encoder_SBTX.sv</rtl_file>
    <port dut_port="CLK"    signal="CLK"/>        <!-- clock port omits @agent -->
    <port dut_port="PHY_En" agent="PHY" signal="en"/>
    ...
  </dut>

  <env>                                           <!-- optional -->
    <has_scoreboard>true</has_scoreboard>         <!-- optional, default true -->
    <has_coverage>true</has_coverage>             <!-- optional, default true (alias: has_subscriber) -->
  </env>
</uvm_env>
```

#### Multi-agent tags & attributes

- **`<interface name="...">`**: Declares a reusable interface `<env>_<name>_if`.
  Multiple agents may share the same interface type (each gets its own instance
  `<agt_lower>_if` in `tb_top` and config DB key `<ENV>_<AGT>_VIF`). Signals use
  the same attributes as single-agent mode, plus optional `idle="..."` (default
  `'0`) for the generated `drive_<agt>_item()` helper in `<env>_<AGT>_base_seq`.
- **`<agents count="N">`**: Optional `count` attribute is checked against the
  number of `<agent>` children.
- **`<agent>`**:
  - `name`: Agent abbreviation (e.g., `D2D`, `PHY`, `FIFO`), unique ignoring
    case. Used for prefixes (`<env>_<AGT>_*`), folders (`components/<AGT>_agent`,
    `sequences/<AGT>_seqs`), and instance handles (`<AGT>_agt`).
  - `interface`: Name of a declared `<interface>`.
  - `mode`: `active` (default; generates driver, sequencer with
    `seqr_aport`/`seqr_aexport`/`seqr_fifo`, and base sequence) or `passive`
    (monitor + agent only). Active agents require at least one `direction="drv"`
    signal on their interface.
  - `scoreboard`: `true` (default) or `false` — connects `agt_aport` to the
    scoreboard's `sb_<agt>_aexport`.
  - `coverage`: `true` (default) or `false` — connects `agt_aport` to the
    coverage collector's `<agt>_imp`.
- **`<dut>`**:
  - `<rtl_file>`: Optional ordered list of RTL files under `RTL/` for `sim/run.do`
    (omitting `<rtl_file>` compiles `../RTL/*.sv`).
  - `<port>`: Uses `agent="<AGT>" signal="<sig>"` to wire `dut_port` to
    `<agt>_if.<sig>`, or `signal="<clock_name>"` without `agent` for the clock.

## Validation

The parser checks everything before writing any file and stops with a
specific message on the first problem:

- root element is `<uvm_env>` with a valid `name`; `<clock>` and `<signals>` present;
- parameter / localparam / signal / DUT-port names are valid identifiers and unique;
- no signal uses the clock name (or `clk`);
- every size (`width`, `depth`, `unpacked`) is valid and only refers to declared parameters/localparams;
- every localparam value only refers to parameters or earlier localparams;
- `direction` is `drv` or `mon`, with at least one of each;
- `<dut>`, when present, has `<module_name>` and at least one `<port>`, and each port references the clock or a declared signal;
- `<has_scoreboard>` / `<has_subscriber>` are `true` or `false`.

## Generated files

### Single-agent (`<signals>`)

```
<name>/
  cfg_obj/      <name>_drv_mon_cfg_obj.svh  <name>_agt_cfg_obj.svh  <name>_env_cfg_obj.svh
  sequences/    <name>_sequence_item.svh  <name>_base_sequence.svh
  components/   <name>_sequencer.svh  _driver.svh  _monitor.svh  _agent.svh
                [_scoreboard.svh]  [_subscriber.svh]  _environment.svh  _base_test.svh
  interfaces/   <name>_if.sv
  packages/     <name>_pkg.sv
  tb/           tb_top.sv
  sim/          run.do
  RTL/          README.md     (drop your DUT files here)
```

### Multi-agent (`<agents>`)

```
<name>/
  cfg_obj/                      <name>_<AGT>_drv_mon_cfg_obj.svh  <name>_<AGT>_agt_cfg_obj.svh
                                <name>_env_cfg_obj.svh
  sequences/sequence_items/     <name>_<AGT>_sequence_item.svh
  sequences/<AGT>_seqs/         <name>_<AGT>_base_seq.svh              (active agents)
  sequences/                    <name>_vseq.svh
  components/<AGT>_agent/       <name>_<AGT>_agent.svh  _monitor.svh
                                [_driver.svh  _sequencer.svh]          (active agents)
  components/                   <name>_vseqr.svh  [_scoreboard.svh]  [_coverage.svh]
                                _environment.svh  _base_test.svh
  interfaces/                   <name>_<if>_if.sv
  packages/                     <name>_pkg.sv
  tb/                           tb_top.sv
  sim/                          run.do
  RTL/                          README.md
```

`[...]` files depend on `<env>` flags and each agent's `mode`.

### Multi-agent Scoreboard & Coverage Collector

- **Scoreboard (`<name>_scoreboard`)**: Uses one `uvm_analysis_export` and
  `uvm_tlm_analysis_fifo` (`sb_<agt>_aexport` / `sb_<agt>_fifo`) per
  scoreboard-connected agent. `run_phase` discards the initial cycle-0 item,
  then pulls one item from each FIFO per cycle and calls `ref_model(...)` and
  `check_results(...)`, reporting `pass_count` and `error_count` in
  `report_phase`. Output signal comparisons in `check_results` are generated
  automatically; `ref_model` is left as a `TODO` stub for DUT logic.
- **Coverage collector (`<name>_coverage`)**: Extends `uvm_component` (not
  `uvm_subscriber`) and declares `` `uvm_analysis_imp_decl(_<agt>) `` ports
  and `write_<agt>()` callbacks for each coverage-connected agent. Valid flags
  synchronize sampling once per cycle after all connected monitors have written
  (`all_valid()` -> `sample_and_advance()` -> `update_state()`), with a
  generic per-signal `covergroup cg_<agt>` ready to extend with scenario crosses.

### Coverage subscriber (single-agent)

`<name>_subscriber` is a `uvm_subscriber` with one coverpoint per signal,
default binning (`auto_bin_max = 16` on multi-bit fields). It is
deliberately semantics-free: `iff` gates and `cross` coverage depend on
the DUT and are left as a `TODO` for you to add. Array signals get
`_first` / `_last` coverpoints (see above).

### `sim/run.do`

Questa/ModelSim script: compiles RTL, package, interface and `tb_top` with
code coverage, runs `<name>_base_test` with `-onfinish stop` (so the script
keeps going after UVM's `$finish`), saves `<name>_coverage.ucdb`, prints
DUT code-coverage and covergroup summaries to the terminal, and writes the
details to `coverage_detailed_report.txt`. Uncomment `quit -f` at the end
for batch runs.

## Examples

| File | Shows |
|------|-------|
| `spec.xml`, `examples/mem_spec.xml` | single-agent `mem` reference: parameters, plain signals, DUT, scoreboard |
| `examples/demux_spec.xml` | packed 2D arrays (`width="8" depth="64"`) |
| `examples/byte_mapper_spec.xml` | unpacked arrays, localparams used as sizes, packed array |
| `examples/pe_sbtx_spec.xml` | multi-agent `Priority_Encoder_SBTX` architecture (`D2D`, `PHY`, `FIFO`), shared `in` interface, `active`/`passive`, virtual sequencer/sequence, TLM FIFO scoreboard, `uvm_component` coverage collector |

## Scope

- **Single-agent or multi-agent environments.** Single-agent specs use `<signals>`;
  multi-agent specs use `<interfaces>` and `<agents count="N">` with per-agent
  `active`/`passive` modes, `scoreboard`/`coverage` routing, virtual sequencer,
  and virtual sequence.
- **Scoreboard `ref_model` and scenario coverage/sequences are TODO-stubs** —
  DUT-specific functional logic is not invented; structural TLM wiring, output
  comparison checks, and generic coverpoints are generated automatically.
- **Logic types only.** Signals are `logic` (4-state), packed arrays are
  `logic` vectors; structs, enums, interfaces-as-ports and multiple
  unpacked dimensions are not supported.
- **Questa/ModelSim only** for `sim/run.do` (`vlib`/`vlog`/`vsim`).

## Fidelity check

`examples/mem_spec.xml` reproduces `mem.zip`'s `mem` single-agent environment.
`examples/pe_sbtx_spec.xml` reproduces the folder structure, agent UVCs, TLM
feedback loops, virtual sequencer/sequence, TLM FIFO scoreboard skeleton, and
`uvm_component` coverage collector skeleton of `verification/SB_TX/ip_level/Priority_Encoder_SBTX`.

## Project layout

```
generate_uvm.py          CLI entry point
uvm_gen/
  model.py                Single-agent dataclasses & shared SignalSpec/ParamSpec/DutSpec
  multi_model.py          Multi-agent dataclasses (MultiEnvSpec, AgentSpec, InterfaceSpec, ...)
  xml_parser.py           Single-agent parser + shared validation helpers & format dispatch
  multi_parser.py         Multi-agent XML -> MultiEnvSpec parser & validation
  renderer.py             UvmEnvSpec / MultiEnvSpec -> rendered files via Jinja2 templates
templates/                 Single-agent .j2 templates + templates/multi/ for multi-agent
spec.xml                   Spec used to produce generated/mem
examples/                  mem_spec.xml, demux_spec.xml, byte_mapper_spec.xml, pe_sbtx_spec.xml
generated/                 Output of the fidelity-check run (safe to delete/regenerate)
```

## Supported features at a glance

Quick reference. Details are in the "XML reference" section above.

### Parameters and constants

| Feature | XML | Notes |
|---------|-----|-------|
| Parameter | `<parameter name="NC" value="32"/>` | Overridable. Declared in the package and the interface `#(...)`, and passed to the DUT as `.NC(NC)`. The DUT must have a parameter of that name. |
| Localparam | `<localparam name="HALF" value="NC/2"/>` | Fixed constant. Declared **only in the interface**; the package sees its value substituted in. Never passed to the interface or DUT. Value may use parameters and earlier localparams. |

### Signals

| Feature | XML | Generated |
|---------|-----|-----------|
| Scalar | `width="1"` | `logic x` |
| Vector | `width="32"` | `logic [31:0] x` |
| Parameter width | `width="NC"` | `logic [NC-1:0] x` |
| Localparam width | `width="HALF"` | `[HALF-1:0]` in the interface, value inlined in the package |
| Expression width | `width="2*NC"`, `"NC+8"`, `"NC<<1"`, `"$clog2(NC)"` | `[2*NC-1:0]`, `[(NC+8)-1:0]`, ... |
| Numeric expression | `width="2*32"` | folded to `[63:0]` |
| Packed array | `width="8" depth="64"` | `logic [63:0][7:0] x` |
| Unpacked array | `width="8" unpacked="16"` | `logic [7:0] x [15:0]` |
| Packed + unpacked | `width="8" depth="4" unpacked="16"` | `logic [3:0][7:0] x [15:0]` |
| Driven signal | `direction="drv"` | `rand` field in the sequence item, driven via `drv_cb` |
| Monitored signal | `direction="mon"` | plain field, sampled via `mon_cb` |

`depth` and `unpacked` accept the same size forms as `width` (number, name, expression).

### Environment options

| Feature | XML | Default |
|---------|-----|---------|
| Custom clock name | `<clock name="MB_CLK"/>` | required |
| DUT instance in `tb_top` | `<dut>` ... `</dut>` | optional |
| DUT instance name | `<instance_name>` | `dut` |
| Partial DUT port wiring | one `<port>` per port you want wired | - |
| Scoreboard | `<has_scoreboard>` | `true` |
| Coverage collector / subscriber | `<has_coverage>` (multi-agent) / `<has_subscriber>` (single-agent) | `true` |

### Generated automatically

- Interface(s) with `drv_cb` / `mon_cb` clocking blocks and config objects (`drv_mon`, `agt`, `env`).
- Per-agent sequence item, base sequence, sequencer (with feedback FIFO in multi-agent mode), driver, monitor, and agent; plus virtual sequencer (`vseqr`) and virtual sequence (`vseq`) in multi-agent mode.
- Scoreboard (`uvm_tlm_analysis_fifo` + `run_phase` / `ref_model` / `check_results` in multi-agent mode) and coverage collector (`uvm_component` with `uvm_analysis_imp_decl` in multi-agent mode; `uvm_subscriber` in single-agent mode).
- Package with correct include order, `tb_top`, and a Questa `run.do` that saves and reports code and functional coverage.

### Not supported

- Types other than `logic` (structs, enums, interface ports).
- More than one unpacked dimension per signal; unpacked ranges written `[0:N-1]` (always generated `[N-1:0]`).
- A `<parameter>` default that refers to a `<localparam>`.
- Passive mode toggle in single-agent XML (use multi-agent `<agents>` format for `active`/`passive` control).
- Simulators other than Questa/ModelSim for `run.do`.