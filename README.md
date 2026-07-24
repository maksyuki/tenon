# Tenon

Tenon is a customizable open-source SoC framework for hierarchical multi-project integration. Its first implemented layer is Tier0 Foundation: a reusable IHP SG13G2 (IHP130) padframe contract with reproducible LibreLane reference hardening targets.

## Three-tier model

| Tier | Role | Integration model |
|---|---|---|
| Tier0 Foundation | Padframe, package pinout, core/IO PDN and hardened reference views | Reused by source, manifest and physical constraints. |
| Tier1 Management | IO mapping, clock multiplication, debug probes and reserved application area | Re-hardens a complete chip around Tier1 logic. |
| Tier2 Application | User design | May originate as RTL or a hardened macro. |

Tier0 hardening outputs are standalone physical reference views. A pad-ring GDS cannot be placed as an ordinary macro around a separate Tier1 block; Tier1 must reuse `rtl/tenon_tier0_padframe.sv` in its full-chip run.

## Tier0 profiles

| Profile | Package leads | IOVDD/IOVSS/VDD/VSS pads | Management pins | GPIOs |
|---|---:|---:|---:|---:|
| QFN32 | 32 | 2 each | 8 | 16 |
| QFN64 | 64 | 4 each | 8 | 40 |
| QFN88 | 88 | 6 each | 8 | 56 |
| QFN128 | 128 | 8 each | 8 | 88 |

The fixed management pins are `mgmt_clk`, `mgmt_rst_n`, JTAG `TCK/TMS/TDI/TDO`, and UART `RX/TX`. Inputs use `sg13g2_IOPadIn`; JTAG TDO and UART TX use `sg13g2_IOPadOut30mA`; GPIOs use `sg13g2_IOPadInOut30mA`.

QFN N means N wire-bondable package leads. An optional exposed pad is a package and assembly decision, normally tied to VSS, and is not a Tier0 pad. The exact pin maps are generated under `docs/pinout/`; numbering is top-view from the south-west corner and advances counter-clockwise.

## Core-facing interface

`tenon_tier0_padframe` exposes management inputs `mgmt_clk_i`, `mgmt_rst_ni`, `jtag_tck_i`, `jtag_tms_i`, `jtag_tdi_i`, `uart_rx_i`; management outputs `jtag_tdo_o`, `uart_tx_o`; and `gpio_i[]`, `gpio_o[]`, `gpio_oe[]`.

The physical integration contract maintains two separate supplies: `VDD/VSS` for core logic and `IOVDD/IOVSS` for IO cells. They must not be shorted. Tier1 owns reset defaults and IO mux policy; the Tier0 reference stub keeps all GPIOs high impedance.

## Use an existing LibreLane and PDK

This repository deliberately contains no LibreLane installation, PDK download, Nix shell or container startup configuration. Provide an already available IHP Open PDK root when running commands:

```bash
make check-generated
make lint PDK_ROOT=/path/to/IHP-Open-PDK
make test PDK_ROOT=/path/to/IHP-Open-PDK
make harden-qfn32 PDK_ROOT=/path/to/IHP-Open-PDK
make harden-all PDK_ROOT=/path/to/IHP-Open-PDK
```

Hardening outputs are saved beneath `build/qfn*/final/`; LibreLane run logs are under `flow/runs/`. These are intentionally ignored because every view is reproducible from the committed specification and sources.

## Verification

`make test` uses Icarus Verilog and the IHP IO behavioral library to exercise all four parameter sets: management input/output propagation, GPIO output enable, GPIO high impedance and external GPIO sampling. `make harden-*` runs the LibreLane Chip flow with the IHP IO library and the reference bondpad macro. All standard signoff checks remain enabled except the template's intentional illegal-overlap checker suppression for bondpad/pad reporting.

## Physical asset attribution

The bondpad macro in `ip/bondpad_70x70_novias` is copied from the Apache-2.0 IHP LibreLane reference template. Its attribution is recorded in `third_party/NOTICE.md`.
