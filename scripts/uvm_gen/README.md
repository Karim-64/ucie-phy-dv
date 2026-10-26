# uvm_gen

Generates a single-agent UVM verification environment (interface, config
objects, sequence item, sequencer/driver/monitor, agent, scoreboard,
coverage subscriber, environment, base test, `tb_top`, `run.do`) from one
XML spec file. The output structure and SystemVerilog conventions reproduce
the `mem` reference environment this tool was built from.

## Usage

```bash
py generate_uvm.py --config spec.xml --out-dir ./generated
py generate_uvm.py --config spec.xml --out-dir ./generated --dry-run   # validate + preview only
py generate_uvm.py --config spec.xml --out-dir ./generated --force    # overwrite existing output
```

Output lands at `<out-dir>/<agent_name>/...`. Requires Python 3.10+ and
`jinja2`.

Then put your DUT source files (`.sv` / `.v`) in `<agent_name>/RTL/` and run
`sim/run.do` from the `sim/` directory in Questa/ModelSim.

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

`[...]` files depend on the `<env>` flags above.

### Coverage subscriber

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
| `dut_spec.xml`, `examples/mem_spec.xml` | the `mem` reference: parameters, plain signals, DUT, scoreboard |
| `examples/demux_spec.xml` | packed 2D arrays (`width="8" depth="64"`) |
| `examples/byte_mapper_spec.xml` | unpacked arrays, localparams used as sizes, packed array |

## Scope (v1, by design)

- **One agent per environment.** No multi-agent/multi-interface XML; each
  run produces one self-contained agent environment.
- **Scoreboard and base_sequence are TODO-stubs**, same as the reference —
  no reference-model logic is invented, since that's DUT-specific.
- **Active by default.** `active_passive_agents[name] = UVM_ACTIVE` is
  hardcoded in the generated `base_test`, matching the reference; there's
  no passive-mode XML toggle yet.
- **Logic types only.** Signals are `logic` (4-state), packed arrays are
  `logic` vectors; structs, enums, interfaces-as-ports and multiple
  unpacked dimensions are not supported.
- **Questa/ModelSim only** for `sim/run.do` (`vlib`/`vlog`/`vsim`).

## Fidelity check

`examples/mem_spec.xml` was written to reproduce `mem.zip`'s `mem`
environment. Diffing the generated output against the original files
(ignoring line-ending differences — the originals are CRLF) shows the
only semantic delta is that `mem_subscriber` is the generic version (no
hand-written `iff`/cross coverage). Every class structure, phase method,
config_db call, signal wiring, and the DUT instantiation in `tb_top.sv`
match exactly.

## Project layout

```
generate_uvm.py          CLI entry point
uvm_gen/
  model.py                Dataclasses: UvmEnvSpec, SignalSpec, ParamSpec, DutSpec, DutPortSpec, EnvFlags
  xml_parser.py            XML -> UvmEnvSpec, with validation (SpecError on anything malformed)
  renderer.py               UvmEnvSpec -> rendered files via Jinja2 templates
templates/                 One .j2 per generated file, mirroring mem/'s folder layout
dut_spec.xml               Spec used to produce generated/mem
examples/                  mem_spec.xml, demux_spec.xml, byte_mapper_spec.xml
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
| Coverage subscriber | `<has_subscriber>` | `true` |

### Generated automatically

- Interface with `drv_cb` / `mon_cb` clocking blocks, config objects (drv/mon, agent, env).
- Sequence item, base sequence, sequencer, driver, monitor, agent, environment, base test.
- Scoreboard stub and generic coverage subscriber (first/last element coverpoints for arrays).
- Package with correct include order, `tb_top`, and a Questa `run.do` that saves and reports code and functional coverage.

### Not supported

- More than one agent or interface per environment.
- Types other than `logic` (structs, enums, interface ports).
- More than one unpacked dimension per signal; unpacked ranges written `[0:N-1]` (always generated `[N-1:0]`).
- A `<parameter>` default that refers to a `<localparam>`.
- Passive agents (the base test is always `UVM_ACTIVE`).
- Simulators other than Questa/ModelSim for `run.do`.