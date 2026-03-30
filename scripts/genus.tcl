# Cadence Genus synthesis script for axi_dma
# Usage example:
#   genus -no_gui -files scripts/genus.tcl
#
# Required environment variables:
#   TOP_MODULE         = dma_axi_top               (default: dma_axi_top)
#   RTL_DIR            = ./rtl                     (default: ./rtl)
#   CONSTRAINTS_FILE   = ./synth/constraints/dma_axi_top.sdc
#   OUT_DIR            = ./synth/genus
#   LIB_FILES          = "<lib1.lib> <lib2.lib>"  (required for mapped synthesis)
# Optional:
#   HDL_SEARCH_PATH    = additional HDL search path
#   LEF_FILES          = "<tech.lef stdcells.lef>" (optional, for extra physical context)
#   QRC_TECH_FILE      = optional QRC tech file

set_db init_lib_search_path [list .]
set_db information_level 7

proc getenv_default {name default} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default
}

set TOP_MODULE       [getenv_default TOP_MODULE "dma_axi_top"]
set RTL_DIR          [getenv_default RTL_DIR "./rtl"]
set CONSTRAINTS_FILE [getenv_default CONSTRAINTS_FILE "./synth/constraints/dma_axi_top.sdc"]
set OUT_DIR          [getenv_default OUT_DIR "./synth/genus"]
set HDL_SEARCH_PATH  [getenv_default HDL_SEARCH_PATH $RTL_DIR]
set LIB_FILES_STR    [getenv_default LIB_FILES ""]
set LEF_FILES_STR    [getenv_default LEF_FILES ""]
set QRC_TECH_FILE    [getenv_default QRC_TECH_FILE ""]

if {$LIB_FILES_STR eq ""} {
    puts stderr "ERROR: LIB_FILES environment variable is required."
    puts stderr "Example:"
    puts stderr "  export LIB_FILES=\"/path/to/sky130_fd_sc_hd__tt_025C_1v80.lib\""
    exit 2
}

set LIB_FILES [split $LIB_FILES_STR]
set LEF_FILES [split $LEF_FILES_STR]

file mkdir $OUT_DIR
file mkdir $OUT_DIR/logs
file mkdir $OUT_DIR/reports
file mkdir $OUT_DIR/netlist
file mkdir $OUT_DIR/db

puts "== axi_dma Genus configuration =="
puts "TOP_MODULE       = $TOP_MODULE"
puts "RTL_DIR          = $RTL_DIR"
puts "CONSTRAINTS_FILE = $CONSTRAINTS_FILE"
puts "OUT_DIR          = $OUT_DIR"
puts "LIB_FILES        = $LIB_FILES"

set_db hdl_search_path [list $HDL_SEARCH_PATH]
set_db library $LIB_FILES

if {[llength $LEF_FILES] > 0} {
    catch {set_db lef_library $LEF_FILES}
}

if {$QRC_TECH_FILE ne ""} {
    catch {set_db qrc_tech_file $QRC_TECH_FILE}
}

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

# Apply constraints
if {[file exists $CONSTRAINTS_FILE]} {
    read_sdc $CONSTRAINTS_FILE
} else {
    puts stderr "WARNING: Constraints file not found: $CONSTRAINTS_FILE"
}

# Generic synthesis
syn_generic
write_hdl > $OUT_DIR/netlist/${TOP_MODULE}_generic_genus.v
report_timing  > $OUT_DIR/reports/timing_generic.rpt
report_area    > $OUT_DIR/reports/area_generic.rpt
report_power   > $OUT_DIR/reports/power_generic.rpt
report_qor     > $OUT_DIR/reports/qor_generic.rpt

# Technology mapping / optimization
syn_map
syn_opt

# Final deliverables
write_hdl > $OUT_DIR/netlist/${TOP_MODULE}_genus.v
write_sdf > $OUT_DIR/netlist/${TOP_MODULE}_genus.sdf
write_design -innovus -base_name $OUT_DIR/db/${TOP_MODULE}

# Reports
report_timing -max_paths 20 -path_type full_clock > $OUT_DIR/reports/timing_mapped.rpt
report_area                                   > $OUT_DIR/reports/area_mapped.rpt
report_power                                  > $OUT_DIR/reports/power_mapped.rpt
report_qor                                    > $OUT_DIR/reports/qor_mapped.rpt
report_gates                                  > $OUT_DIR/reports/gates_mapped.rpt
report_design_rules                           > $OUT_DIR/reports/design_rules.rpt
report_clocks                                 > $OUT_DIR/reports/clocks.rpt

puts "Genus synthesis completed successfully."
quit
