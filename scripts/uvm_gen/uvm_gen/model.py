"""
Internal data model for a UVM environment spec.

This is the single source of truth that templates render from. The XML
parser's only job is to populate these dataclasses; every other module
(renderer, validator, CLI) works against this model, never against raw
XML/ElementTree nodes.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field


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


@dataclass
class ParamSpec:
    name: str
    value: str  # kept as string; it's emitted verbatim into SystemVerilog


@dataclass
class SignalSpec:
    name: str
    width: str          # literal integer ("1", "4") or a parameter name ("DATA_WIDTH")
    direction: str       # "drv" or "mon"
    depth: str | None = None     # optional outer PACKED dimension (literal or parameter/localparam name)
    unpacked: str | None = None  # optional UNPACKED dimension (literal or parameter/localparam name)

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
    # localparams: constants that can NOT be overridden. They are declared in the package
    # and inside the interface, but never passed through #(...) to the interface or DUT.
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