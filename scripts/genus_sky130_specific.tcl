# Cadence Genus synthesis script specialized for axi_dma + SKY130
# Run with:
#   make genus
# or:
#   ./scripts/run_genus.sh
#
# Environment variables supported:
#   TOP_MODULE         default: dma_axi_top
#   RTL_DIR            default: ./rtl
#   CONSTRAINTS_FILE   default: ./synth/constraints/dma_axi_top.sdc
#   OUT_DIR            default: ./synth/genus
#   LIB_FILES          optional, overrides automatic SKY130 resolution
#   SKY130_LIB         optional, single liberty file shortcut
#   SKY130_PDK_ROOT    optional, used to auto-resolve liberty
#   PDK_ROOT           optional, used to auto-resolve liberty
#
# Typical liberty auto-detected:
#   $SKY130_PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
# or
#   $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

set_db init_lib_search_path [list .]
set_db information_level 7

proc getenv_default {name default} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default
}

proc detect_sky130_lib {} {
    if {[info exists ::env(LIB_FILES)] && $::env(LIB_FILES) ne ""} {
        return [split $::env(LIB_FILES)]
    }

    if {[info exists ::env(SKY130_LIB)] && $::env(SKY130_LIB) ne ""} {
        return [list $::env(SKY130_LIB)]
    }

    set candidates {}

    if {[info exists ::env(SKY130_PDK_ROOT)] && $::env(SKY130_PDK_ROOT) ne ""} {
        lappend candidates \
            "$::env(SKY130_PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib" \
            "$::env(SKY130_PDK_ROOT)/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
    }

    if {[info exists ::env(PDK_ROOT)] && $::env(PDK_ROOT) ne ""} {
        lappend candidates \
            "$::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib" \
            "$::env(PDK_ROOT)/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
    }

    foreach c $candidates {
        if {[file exists $c]} {
            return [list $c]
        }
    }

    return {}
}

set TOP_MODULE       [getenv_default TOP_MODULE "dma_axi_top"]
set RTL_DIR          [getenv_default RTL_DIR "./rtl"]
set CONSTRAINTS_FILE [getenv_default CONSTRAINTS_FILE "./synth/constraints/dma_axi_top.sdc"]
set OUT_DIR          [getenv_default OUT_DIR "./synth/genus"]

set LIB_FILES [detect_sky130_lib]

if {[llength $LIB_FILES] == 0} {
    puts stderr "ERROR: Could not resolve SKY130 liberty."
    puts stderr "Set one of the following:"
    puts stderr "  LIB_FILES"
    puts stderr "  SKY130_LIB"
    puts stderr "  SKY130_PDK_ROOT"
    puts stderr "  PDK_ROOT"
    exit 2
}

file mkdir $OUT_DIR
file mkdir $OUT_DIR/logs
file mkdir $OUT_DIR/reports
file mkdir $OUT_DIR/netlist
file mkdir $OUT_DIR/db

puts "== axi_dma Genus SKY130 configuration =="
puts "TOP_MODULE       = $TOP_MODULE"
puts "RTL_DIR          = $RTL_DIR"
puts "CONSTRAINTS_FILE = $CONSTRAINTS_FILE"
puts "OUT_DIR          = $OUT_DIR"
puts "LIB_FILES        = $LIB_FILES"

set_db hdl_search_path [list $RTL_DIR]
set_db library $LIB_FILES

# Read RTL
read_hdl -sv [list \
    $RTL_DIR/dma_pkg.sv \
    $RTL_DIR/dma_fifo.sv \
    $RTL_DIR/dma_csr.sv \
    $RTL_DIR/dma_fsm.sv \
    $RTL_DIR/dma_axi_master_rd.sv \
    $RTL_DIR/dma_axi_master_wr.sv \
    $RTL_DIR/dma_axi_top.sv \
]

elaborate $TOP_MODULE
check_design -unresolved > $OUT_DIR/reports/check_design_unresolved.rpt
check_design -all        > $OUT_DIR/reports/check_design_all.rpt

# Constraints
if {[file exists $CONSTRAINTS_FILE]} {
    read_sdc $CONSTRAINTS_FILE
} else {
    puts stderr "WARNING: Constraints file not found: $CONSTRAINTS_FILE"
}

# Generic synthesis
syn_generic
write_hdl > $OUT_DIR/netlist/${TOP_MODULE}_generic_genus.v
report_timing > $OUT_DIR/reports/timing_generic.rpt
report_area   > $OUT_DIR/reports/area_generic.rpt
report_power  > $OUT_DIR/reports/power_generic.rpt
report_qor    > $OUT_DIR/reports/qor_generic.rpt

# Mapped synthesis
syn_map
syn_opt

write_hdl > $OUT_DIR/netlist/${TOP_MODULE}_genus.v
write_sdf > $OUT_DIR/netlist/${TOP_MODULE}_genus.sdf
write_design -innovus -base_name $OUT_DIR/db/${TOP_MODULE}

report_timing -max_paths 20 -path_type full_clock > $OUT_DIR/reports/timing_mapped.rpt
report_area   > $OUT_DIR/reports/area_mapped.rpt
report_power  > $OUT_DIR/reports/power_mapped.rpt
report_qor    > $OUT_DIR/reports/qor_mapped.rpt
report_gates  > $OUT_DIR/reports/gates_mapped.rpt
report_clocks > $OUT_DIR/reports/clocks.rpt

puts "Genus SKY130 synthesis completed successfully."
quit
