# SPDX-License-Identifier: Apache-2.0
# LibreLane/OpenROAD currently models IOVDD/IOVSS as secondary rails of one
# voltage domain. Their separation from VDD/VSS is retained in the pad library,
# pin manifest and package handoff; this Tcl never shorts the nets.

source $::env(SCRIPTS_DIR)/openroad/common/io.tcl
source $::env(SCRIPTS_DIR)/openroad/common/set_global_connections.tcl
set_global_connections

set secondary {}
foreach vdd $::env(VDD_NETS) gnd $::env(GND_NETS) {
    if {$vdd != $::env(VDD_NET)} {
        lappend secondary $vdd
        if {[[ord::get_db_block] findNet $vdd] == "NULL"} {
            set net [odb::dbNet_create [ord::get_db_block] $vdd]
            $net setSpecial
            $net setSigType "POWER"
        }
    }
    if {$gnd != $::env(GND_NET)} {
        lappend secondary $gnd
        if {[[ord::get_db_block] findNet $gnd] == "NULL"} {
            set net [odb::dbNet_create [ord::get_db_block] $gnd]
            $net setSpecial
            $net setSigType "GROUND"
        }
    }
}

set_voltage_domain -name CORE -power $::env(VDD_NET) -ground $::env(GND_NET) \
    -secondary_power $secondary

define_pdn_grid -name tenon_grid -starts_with POWER -voltage_domain CORE
add_pdn_ring \
    -grid tenon_grid \
    -layers "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)" \
    -widths "15 15" \
    -spacings "5 5" \
    -core_offset "10 10" \
    -connect_to_pads
