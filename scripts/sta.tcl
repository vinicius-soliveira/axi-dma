# ============================================================
# OpenSTA Script - AXI DMA
# Target Technology: SKY130 (sky130_fd_sc_hd)
# ============================================================

# Read standard cell timing library
read_liberty /home/vinicius.silva/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# Read synthesized gate-level netlist
read_verilog synth/netlist/dma_axi_top_netlist_sky130.v

# Set top module
link_design dma_axi_top

# Read timing constraints
read_sdc synth/constraints/dma_axi_top.sdc

# Basic timing reports
report_checks -path_delay max -digits 4  > synth/reports/timing_checks.rpt
report_wns > synth/reports/wns.rpt
report_tns > synth/reports/tns.rpt

exit
