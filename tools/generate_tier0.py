#!/usr/bin/env python3
"""Generate Tier0 pin manifests and LibreLane configurations from one spec."""

from __future__ import annotations

import argparse
import csv
import io
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC_PATH = ROOT / "specs" / "tier0_profiles.json"
SIDES = ("south", "east", "north", "west")
INPUT_MANAGEMENT = {"mgmt_clk", "mgmt_rst_n", "jtag_tck", "jtag_tms", "jtag_tdi", "uart_rx"}
OUTPUT_MANAGEMENT = {"jtag_tdo", "uart_tx"}
MANAGEMENT_INSTANCES = {
    "mgmt_clk": "u_mgmt_clk_pad",
    "mgmt_rst_n": "u_mgmt_rst_n_pad",
    "jtag_tck": "u_jtag_tck_pad",
    "jtag_tms": "u_jtag_tms_pad",
    "jtag_tdi": "u_jtag_tdi_pad",
    "jtag_tdo": "u_jtag_tdo_pad",
    "uart_rx": "u_uart_rx_pad",
    "uart_tx": "u_uart_tx_pad",
}
POWER_INSTANCE_PREFIX = {
    "IOVDD": "u_iovdd_pads",
    "IOVSS": "u_iovss_pads",
    "VDD": "u_vdd_pads",
    "VSS": "u_vss_pads",
}
POWER_CELLS = {
    "IOVDD": "sg13g2_IOPadIOVdd",
    "IOVSS": "sg13g2_IOPadIOVss",
    "VDD": "sg13g2_IOPadVdd",
    "VSS": "sg13g2_IOPadVss",
}


def pad_path(instance: str) -> str:
    """Return the Tcl-escaped hierarchical instance name expected by LibreLane."""
    escaped = instance.replace("[", r"\\[").replace("]", r"\\]")
    return f'"u_reference.u_padframe.{escaped}"'


def management_record(pin: int, side: str, slot: int, signal: str) -> dict:
    if signal in INPUT_MANAGEMENT:
        direction = "input"
        cell = "sg13g2_IOPadIn"
        suffix = "_i"
    elif signal in OUTPUT_MANAGEMENT:
        direction = "output"
        cell = "sg13g2_IOPadOut30mA"
        suffix = "_o"
    else:
        raise ValueError(f"Unknown management signal: {signal}")
    return {
        "pin": pin,
        "side": side,
        "slot": slot,
        "function": signal,
        "direction": direction,
        "cell": cell,
        "rtl_signal": f"{signal}{suffix}",
        "instance": MANAGEMENT_INSTANCES[signal],
    }


def build_records(spec: dict, profile: dict) -> list[dict]:
    leads = profile["package_leads"]
    side_size = leads // 4
    pads_per_rail = profile["pads_per_rail"]
    if leads % 4 != 0:
        raise ValueError(f"{profile['id']}: package lead count must be divisible by four")

    power_slots = set(range(1, side_size + 1, 4))
    if len(power_slots) != pads_per_rail:
        raise ValueError(f"{profile['id']}: side power slots do not match pads_per_rail")

    management = spec["management_by_side"]
    power_order = spec["power_rail_order"]
    power_indices = {rail: 0 for rail in power_order}
    gpio_index = 0
    power_index = 0
    records: list[dict] = []

    for side_index, side in enumerate(SIDES):
        end_slot = side_size - 1
        while end_slot in power_slots:
            end_slot -= 1
        first_signal, last_signal = management[side]
        for slot in range(1, side_size + 1):
            pin = side_index * side_size + slot
            if slot in power_slots:
                rail = power_order[power_index % len(power_order)]
                index = power_indices[rail]
                power_indices[rail] += 1
                power_index += 1
                record = {
                    "pin": pin,
                    "side": side,
                    "slot": slot,
                    "function": rail,
                    "direction": "power" if rail.endswith("VDD") else "ground",
                    "cell": POWER_CELLS[rail],
                    "rtl_signal": rail,
                    "instance": f"{POWER_INSTANCE_PREFIX[rail]}[{index}].u_pad",
                }
            elif slot == 2:
                record = management_record(pin, side, slot, first_signal)
            elif slot == end_slot:
                record = management_record(pin, side, slot, last_signal)
            else:
                record = {
                    "pin": pin,
                    "side": side,
                    "slot": slot,
                    "function": "GPIO",
                    "direction": "inout",
                    "cell": "sg13g2_IOPadInOut30mA",
                    "rtl_signal": f"gpio[{gpio_index}]",
                    "instance": f"u_gpio_pads[{gpio_index}].u_pad",
                }
                gpio_index += 1
            records.append(record)

    expected_power = 4 * pads_per_rail
    if gpio_index != profile["gpio_count"] or len(records) != leads:
        raise ValueError(f"{profile['id']}: invalid GPIO or package-pin count")
    if sum(record["function"] in power_order for record in records) != expected_power:
        raise ValueError(f"{profile['id']}: invalid power-pad count")
    if any(power_indices[rail] != pads_per_rail for rail in power_order):
        raise ValueError(f"{profile['id']}: rail count is unbalanced")
    return records


def side_placement(records: list[dict], side: str) -> list[str]:
    selected = [record for record in records if record["side"] == side]
    if side in {"north", "west"}:
        selected.reverse()
    return [pad_path(record["instance"]) for record in selected]


def yaml_list(name: str, values: list[str]) -> str:
    lines = [f"{name}:"]
    lines.extend(f"- {value}" for value in values)
    return "\n".join(lines)


def render_config(profile: dict, records: list[dict]) -> str:
    die_side = profile["die_side_um"]
    core_offset = 365
    core_end = core_offset + profile["core_side_um"]
    placements = "\n\n".join(
        yaml_list(f"PAD_{side.upper()}", side_placement(records, side)) for side in SIDES
    )
    return f"""# Generated by tools/generate_tier0.py. Do not edit manually.
meta:
  version: 3
  flow: Chip
  substituting_steps:
    # The IO library has intentional pad/bondpad overlap reports.
    Checker.IllegalOverlap: null

DESIGN_NAME: {profile['top']}
VERILOG_FILES:
- dir::../rtl/tenon_tier0_padframe.sv
- dir::../rtl/tenon_tier0_reference.sv
- dir::../rtl/tenon_tier0_variants.sv
VERILOG_DEFINES: [FUNCTIONAL]
PRIMARY_GDSII_STREAMOUT_TOOL: klayout

{placements}

VDD_NETS: [VDD]
GND_NETS: [VSS]
CLOCK_PORT: mgmt_clk_pad
CLOCK_NET: u_reference.u_padframe.u_mgmt_clk_pad/p2c
CLOCK_PERIOD: 20

FP_SIZING: absolute
DIE_AREA: [0, 0, {die_side}, {die_side}]
CORE_AREA: [{core_offset}, {core_offset}, {core_end}, {core_end}]
PL_TARGET_DENSITY_PCT: 5
GRT_ALLOW_CONGESTION: true

PDN_CORE_RING: true
PDN_ENABLE_RAILS: true
PDN_ENABLE_PINS: false
PDN_CORE_RING_CONNECT_TO_PADS: true
PDN_CORE_RING_VWIDTH: 15
PDN_CORE_RING_HWIDTH: 15
PDN_CORE_RING_VSPACING: 5
PDN_CORE_RING_HSPACING: 5

PAD_BONDPAD_NAME: bondpad_70x70_novias
EXTRA_GDS:
- dir::../ip/bondpad_70x70_novias/gds/bondpad_70x70_novias.gds
EXTRA_LEFS:
- dir::../ip/bondpad_70x70_novias/lef/bondpad_70x70_novias.lef
IGNORE_DISCONNECTED_MODULES:
- bondpad_70x70_novias
MAGIC_EXT_UNIQUE: notopports
"""


def render_csv(records: list[dict]) -> str:
    output = io.StringIO(newline="")
    writer = csv.DictWriter(
        output,
        fieldnames=["package_pin", "side", "slot", "function", "direction", "cell", "rtl_signal", "instance"],
        lineterminator="\n",
    )
    writer.writeheader()
    for record in records:
        writer.writerow({"package_pin": f"P{record['pin']}", **{key: record[key] for key in writer.fieldnames[1:]}})
    return output.getvalue()


def render_markdown(spec: dict, profile: dict, records: list[dict]) -> str:
    rows = [
        f"# {profile['id'].upper()} Pin Manifest",
        "",
        f"{spec['pin_orientation']} QFN lead count excludes an exposed pad.",
        "",
        "| Pin | Side | Slot | Function | Direction | IHP cell | Core-facing signal |",
        "|---|---|---:|---|---|---|---|",
    ]
    for record in records:
        rows.append(
            f"| P{record['pin']} | {record['side']} | {record['slot']} | "
            f"{record['function']} | {record['direction']} | {record['cell']} | {record['rtl_signal']} |"
        )
    rows.append("")
    return "\n".join(rows)


def expected_outputs(spec: dict) -> dict[Path, str]:
    outputs: dict[Path, str] = {}
    for profile in spec["profiles"]:
        records = build_records(spec, profile)
        profile_id = profile["id"]
        outputs[ROOT / "flow" / f"{profile_id}.yaml"] = render_config(profile, records)
        outputs[ROOT / "docs" / "pinout" / f"{profile_id}.csv"] = render_csv(records)
        outputs[ROOT / "docs" / "pinout" / f"{profile_id}.md"] = render_markdown(spec, profile, records)
    return outputs


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="fail when generated files differ")
    args = parser.parse_args()

    spec = json.loads(SPEC_PATH.read_text())
    outputs = expected_outputs(spec)
    mismatches = []
    for path, content in outputs.items():
        if args.check:
            if not path.exists() or path.read_text() != content:
                mismatches.append(path.relative_to(ROOT))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
    if mismatches:
        print("Generated files are stale:", *mismatches, sep="\n  ", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
