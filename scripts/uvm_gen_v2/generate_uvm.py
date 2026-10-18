#!/usr/bin/env python3
"""
generate_uvm.py - generate a single-agent UVM verification environment
from an XML config, following the mem.zip reference structure/conventions.

Usage:
    python generate_uvm.py --config spec.xml --out-dir ./generated
    python generate_uvm.py --config spec.xml --out-dir ./generated --dry-run
    python generate_uvm.py --config spec.xml --out-dir ./generated --force
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from uvm_gen.renderer import render_spec
from uvm_gen.xml_parser import SpecError, parse_spec


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Generate a UVM verification environment from an XML spec."
    )
    parser.add_argument("--config", required=True, help="Path to the XML config file")
    parser.add_argument(
        "--out-dir", required=True, help="Directory under which <agent_name>/ will be created"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Parse and validate only; print what would be generated without writing files",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite the output directory if <out_dir>/<agent_name> already exists",
    )
    args = parser.parse_args(argv)

    try:
        spec = parse_spec(args.config)
    except SpecError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1

    target_dir = Path(args.out_dir) / spec.name
    if target_dir.exists() and not args.dry_run and not args.force:
        print(
            f"error: {target_dir} already exists. Use --force to overwrite, "
            f"or choose a different --out-dir.",
            file=sys.stderr,
        )
        return 1

    written = render_spec(spec, args.out_dir, dry_run=args.dry_run)

    # --- RTL Folder Generation ---
    rtl_dir = target_dir / "RTL"
    readme_file = rtl_dir / "README.md"
    
    if not args.dry_run:
        rtl_dir.mkdir(parents=True, exist_ok=True)
        readme_file.write_text("Place your SystemVerilog/Verilog design files (.sv, .v) in this directory.\n")
    
    written.append(str(readme_file))
    # -----------------------------

    verb = "Would generate" if args.dry_run else "Generated"
    print(f"{verb} {len(written)} files for '{spec.name}':")
    for path in written:
        print(f"  {path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())