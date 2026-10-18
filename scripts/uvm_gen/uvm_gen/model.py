"""
Internal data model for a UVM environment spec.

This is the single source of truth that templates render from. The XML
parser's only job is to populate these dataclasses; every other module
(renderer, validator, CLI) works against this model, never against raw
XML/ElementTree nodes.
"""
from __future__ import annotations

from dataclasses import dataclass, field


def _msb(n: str) -> str:
    """Upper bound of a [n-1:0] range: folds integer literals ('64' -> '63'),
    leaves parameter names symbolic ('DATA_WIDTH' -> 'DATA_WIDTH-1')."""
    return str(int(n) - 1) if n.isdigit() else f"{n}-1"


@dataclass
class ParamSpec:
    name: str
    value: str  # kept as string; it's emitted verbatim into SystemVerilog


@dataclass
class SignalSpec:
    name: str
    width: str          # literal integer ("1", "4") or a parameter name ("DATA_WIDTH")
    direction: str       # "drv" or "mon"
    depth: str | None = None  # optional outer packed dimension (integer literal or parameter name)

    @property
    def is_array(self) -> bool:
        return self.depth is not None

    @property
    def last_index(self) -> str:
        """Index of the last array element, e.g. '63' (only meaningful if is_array)."""
        return _msb(self.depth)

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
        outer = f"[{_msb(self.depth)}:0]" if self.is_array else ""
        return f"{outer}{self.width_expr}"

    @property
    def sv_type(self) -> str:
        """Full 'logic [..]' declaration fragment (no trailing name)."""
        rng = self.dims
        return f"logic {rng}" if rng else "logic"


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
    def upper(self) -> str:
        return self.name.upper()

    @property
    def param_names(self) -> list[str]:
        return [p.name for p in self.parameters]

    @property
    def if_param_port_list(self) -> str:
        """e.g. 'DATA_WIDTH, ADDRESS_WIDTH' for virtual <name>_if#(...) references."""
        return ", ".join(self.param_names)
