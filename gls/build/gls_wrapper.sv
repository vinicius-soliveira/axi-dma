`timescale 1ns/1ps
module gls_top;
  dma_tb tb();
  initial begin
    $display("[GLS] Applying SDF: /home/vinicius.silva/axi_dma/synth/netlist/dma_axi_top.sdf");
    $sdf_annotate("/home/vinicius.silva/axi_dma/synth/netlist/dma_axi_top.sdf", tb.dut,,, "MAXIMUM");
  end
endmodule
