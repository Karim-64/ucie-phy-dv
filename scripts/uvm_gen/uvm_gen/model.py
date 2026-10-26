"""
Internal data model for a UVM environment spec.

This is the single source of truth that templates render from. The XML
parser's only job is to populate these dataclasses; every other module
(renderer, validator, CLI) works against this model, never against raw
XML/ElementTree nodes.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field, replace


# An expression made only of identifiers/numbers and the operators * / %  binds tighter
# than the "-1", so it needs no parentheses ('2*NC' -> '2*NC-1'); anything else
# ('NC+8', 'NC<<1', '$clog2(NC)') is wrapped: '(NC+8)-1'.
_TIGHT_EXPR_RE = re.compile(r"[A-Za-z0-9_\s*/%]+")


def _msb(n: str) -> str:
    """Upper bound of a [n-1:0] range. Folds integer literals ('64' -> '63'), leaves
    parameter names / expressions symbolic ('DATA_WIDTH' -> 'DATA_WIDTH-1',
    '2*NC' -> '2*NC-1', 'NC+8' -> '(NC+8)-1')."""
    n = n.strip()
    if n.isdigit():
        return str(int(n) - 1)
    return f"{n}-1" if _TIGHT_EXPR_RE.fullmatch(n) else f"({n})-1"


# Tokens of a size expression: sized literals (8'hFF) and $functions are skipped over,
# bare identifiers are the names that may need substituting.
_TOKEN_RE = re.compile(r"\d*'[sS]?[bBoOdDhH][0-9a-fA-F_xXzZ?]+|\$\w+|[A-Za-z_]\w*")
_ATOM_RE = re.compile(r"[A-Za-z_]\w*|\d+")
_NUMERIC_RE = re.compile(r"[0-9+\-*/%()\s]+")


def _fold_numeric(expr: str) -> str:
    """'2*8' -> '16'. Anything that is not a plain numeric expression is returned unchanged."""
    if _NUMERIC_RE.fullmatch(expr) and "**" not in expr and "//" not in expr:
        try:
            value = int(eval(expr.replace("/", "//"), {"__builtins__": {}}, {}))  # noqa: S307
        except Exception:
            return expr
        if value >= 1:
            return str(value)
    return expr


@dataclass
class ParamSpec:
    name: str
    value: str  # kept as string; it's emitted verbatim into SystemVerilog


def _substitute(expr: str, consts: dict[str, str]) -> str:
    """Replace localparam names in a size expression by their (already resolved) values,
    parenthesising non-trivial values so operator precedence is preserved, then fold
    pure-number results ('NUM_LANES' -> '16')."""
    expr = expr.strip()
    if expr in consts:
        return consts[expr]

    def repl(match: re.Match) -> str:
        tok = match.group(0)
        if tok not in consts:
            return tok
        val = consts[tok]
        return val if _ATOM_RE.fullmatch(val) else f"({val})"

    return _fold_numeric(_TOKEN_RE.sub(repl, expr))


@dataclass
class SignalSpec:
    name: str
    width: str          # literal integer ("1", "4") or a parameter name ("DATA_WIDTH")
    direction: str       # "drv" or "mon"
    depth: str | None = None     # optional outer PACKED dimension (literal or parameter/localparam name)
    unpacked: str | None = None  # optional UNPACKED dimension (literal or parameter/localparam name)

    def resolved(self, consts: dict[str, str]) -> "SignalSpec":
        """Copy whose width/depth/unpacked have every localparam name replaced by its value."""
        sub_ = lambda x: None if x is None else _substitute(x, consts)  # noqa: E731
        return replace(self, width=sub_(self.width), depth=sub_(self.depth),
                       unpacked=sub_(self.unpacked))

    @property
    def is_packed_array(self) -> bool:
        return self.depth is not None

    @property
    def is_unpacked(self) -> bool:
        return self.unpacked is not None

    @property
    def is_array(self) -> bool:
        """True if the signal has any array dimension (packed depth and/or unpacked)."""
        return self.is_packed_array or self.is_unpacked

    @property
    def array_size(self) -> str:
        """Size of the outermost array dimension (the unpacked one if present)."""
        return self.unpacked if self.is_unpacked else self.depth

    @property
    def cov_elements(self) -> list[tuple[str, str]]:
        """(tag, index-suffix) pairs for the subscriber: the first and the last element,
        fully indexed through every array dimension (unpacked first, then packed), e.g.
        ('first', '[0][0]') / ('last', '[15][63]'). Every element has `width` bits."""
        dims = [d for d in (self.unpacked, self.depth) if d is not None]
        first = "".join("[0]" for _ in dims)
        last = "".join(f"[{_msb(d)}]" for d in dims)
        return [("first", first), ("last", last)]

    @property
    def is_scalar(self) -> bool:
        """True for a plain 1-bit signal (no range at all)."""
        return self.width == "1" and not self.is_array

    @property
    def is_driven(self) -> bool:
        return self.direction == "drv"

    @property
    def is_monitored(self) -> bool:
        return self.direction == "mon"

    @property
    def width_expr(self) -> str:
        """Element bit-range, e.g. '[DATA_WIDTH-1:0]' or '' for width==1."""
        if self.width == "1":
            return ""
        return f"[{_msb(self.width)}:0]"

    @property
    def dims(self) -> str:
        """Full packed range, e.g. '[63:0][7:0]' (depth first), '[DATA_WIDTH-1:0]', or ''."""
        outer = f"[{_msb(self.depth)}:0]" if self.is_packed_array else ""
        return f"{outer}{self.width_expr}"

    @property
    def sv_type(self) -> str:
        """Packed part of the declaration: 'logic [..]' (no name, no unpacked dims)."""
        rng = self.dims
        return f"logic {rng}" if rng else "logic"

    @property
    def unpacked_dims(self) -> str:
        """Unpacked range, e.g. '[15:0]', or '' if the signal is not unpacked."""
        return f"[{_msb(self.unpacked)}:0]" if self.is_unpacked else ""

    @property
    def decl(self) -> str:
        """Complete declaration (without 'wire'/'rand'): 'logic [7:0] Lanes [15:0]'."""
        base = f"{self.sv_type} {self.name}"
        return f"{base} {self.unpacked_dims}" if self.is_unpacked else base


@dataclass
class DutPortSpec:
    dut_port: str
    signal: str  # references a SignalSpec.name, or the clock name


@dataclass
class DutSpec:
    module_name: str
    instance_name: str
    ports: list[DutPortSpec] = field(default_factory=list)


@dataclass
class EnvFlags:
    has_scoreboard: bool = True
    # has_agent is always True for a single-agent generator (the agent IS the env's purpose)
    has_agent: bool = True
    # generic (semantics-free) coverage subscriber; one coverpoint per signal
    has_subscriber: bool = True


@dataclass
class UvmEnvSpec:
    name: str
    clock_name: str
    parameters: list[ParamSpec] = field(default_factory=list)
    # localparams: constants that can NOT be overridden. They are declared ONLY inside the
    # interface (never in the package, never passed through #(...) to the interface or DUT).
    # Package-side code (sequence item, subscriber) cannot see them, so it uses the
    # pkg_* signal views below, in which every localparam is replaced by its value.
    localparams: list[ParamSpec] = field(default_factory=list)
    signals: list[SignalSpec] = field(default_factory=list)
    dut: DutSpec | None = None
    env: EnvFlags = field(default_factory=EnvFlags)

    # ---- convenience views used heavily by templates ----
    @property
    def driven_signals(self) -> list[SignalSpec]:
        return [s for s in self.signals if s.is_driven]

    @property
    def monitored_signals(self) -> list[SignalSpec]:
        return [s for s in self.signals if s.is_monitored]

    @property
    def localparam_values(self) -> dict[str, str]:
        """localparam name -> value expressed only with literals and <parameter> names."""
        values: dict[str, str] = {}
        for lp in self.localparams:
            values[lp.name] = _substitute(lp.value, values)
        return values

    @property
    def pkg_signals(self) -> list[SignalSpec]:
        """Signals as seen from the package: localparams substituted by their values."""
        consts = self.localparam_values
        return [s.resolved(consts) for s in self.signals]

    @property
    def pkg_driven_signals(self) -> list[SignalSpec]:
        return [s for s in self.pkg_signals if s.is_driven]

    @property
    def pkg_monitored_signals(self) -> list[SignalSpec]:
        return [s for s in self.pkg_signals if s.is_monitored]

    @property
    def constant_names(self) -> list[str]:
        """Every name a signal width/depth/unpacked size may legally refer to."""
        return [p.name for p in self.parameters] + [p.name for p in self.localparams]

    @property
    def upper(self) -> str:
        return self.name.upper()

    @property
    def param_names(self) -> list[str]:
        return [p.name for p in self.parameters]

    @property
    def if_param_port_list(self) -> str:
        """e.g. 'DATA_WIDTH, ADDRESS_WIDTH' for virtual <name>_if#(...) references."""
        return ", ".join(self.param_names)
