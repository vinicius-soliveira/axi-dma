module dma_axi_read_sva #(
  parameter int ADDR_W = 32,
  parameter int DATA_W = 32
)(
  input logic              ACLK,
  input logic              ARESETn,

  input logic [ADDR_W-1:0] ARADDR,
  input logic [7:0]        ARLEN,
  input logic [2:0]        ARSIZE,
  input logic [1:0]        ARBURST,
  input logic              ARVALID,
  input logic              ARREADY,

  input logic [DATA_W-1:0] RDATA,
  input logic [1:0]        RRESP,
  input logic              RLAST,
  input logic              RVALID,
  input logic              RREADY
);

  logic        rd_active;
  logic [8:0]  rd_beats_left;

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      rd_active     <= 1'b0;
      rd_beats_left <= '0;
    end else begin
      if (ARVALID && ARREADY) begin
        rd_active     <= 1'b1;
        rd_beats_left <= ARLEN + 9'd1;
      end else if (RVALID && RREADY && rd_active) begin
        if (rd_beats_left > 9'd1) begin
          rd_beats_left <= rd_beats_left - 9'd1;
        end else begin
          rd_beats_left <= '0;
          rd_active     <= 1'b0;
        end
      end
    end
  end

  property p_arvalid_hold;
    @(posedge ACLK) disable iff (!ARESETn)
      ARVALID && !ARREADY |=> ARVALID;
  endproperty

  property p_ar_stable;
    @(posedge ACLK) disable iff (!ARESETn)
      ARVALID && !ARREADY |=> $stable(ARADDR) &&
                              $stable(ARLEN)  &&
                              $stable(ARSIZE) &&
                              $stable(ARBURST);
  endproperty

  property p_rvalid_hold;
    @(posedge ACLK) disable iff (!ARESETn)
      RVALID && !RREADY |=> RVALID;
  endproperty

  property p_r_stable;
    @(posedge ACLK) disable iff (!ARESETn)
      RVALID && !RREADY |=> $stable(RDATA) &&
                            $stable(RRESP) &&
                            $stable(RLAST);
  endproperty

  property p_rlast_only_on_last_beat;
    @(posedge ACLK) disable iff (!ARESETn)
      (RVALID && RREADY && rd_active && (rd_beats_left > 9'd1)) |-> !RLAST;
  endproperty

  property p_last_beat_has_rlast;
    @(posedge ACLK) disable iff (!ARESETn)
      (RVALID && RREADY && rd_active && (rd_beats_left == 9'd1)) |-> RLAST;
  endproperty
  
  property p_arsize_matches_data_width;
    @(posedge ACLK) disable iff (!ARESETn)
      ARVALID |-> (ARSIZE == $clog2(DATA_W/8));
  endproperty

  property p_arburst_incr_only;
    @(posedge ACLK) disable iff (!ARESETn)
      ARVALID |-> (ARBURST == 2'b01);
  endproperty

  property p_araddr_aligned;
     @(posedge ACLK) disable iff (!ARESETn)
     ARVALID |-> (ARADDR % (1 << ARSIZE) == 0);
  endproperty

  assert property (p_arvalid_hold)
    else $error("DMA_AXI_READ_SVA: ARVALID dropped before handshake");

  assert property (p_ar_stable)
    else $error("DMA_AXI_READ_SVA: AR channel changed before handshake");

  assert property (p_rvalid_hold)
    else $error("DMA_AXI_READ_SVA: RVALID dropped before handshake");

  assert property (p_r_stable)
    else $error("DMA_AXI_READ_SVA: RDATA/RRESP/RLAST changed before handshake");

  assert property (p_rlast_only_on_last_beat)
    else $error("DMA_AXI_READ_SVA: RLAST asserted too early");

  assert property (p_last_beat_has_rlast)
    else $error("DMA_AXI_READ_SVA: missing RLAST on final read beat");
    
  assert property (p_arsize_matches_data_width)
    else $error("DMA_AXI_READ_SVA: ARSIZE mismatch");

  assert property (p_arburst_incr_only)
    else $error("DMA_AXI_READ_SVA: ARBURST not INCR");

  assert property (p_araddr_aligned)
    else $error("DMA_AXI_READ_SVA: ARADDR not aligned");

  cover property (@(posedge ACLK) disable iff (!ARESETn) ARVALID && ARREADY);
  cover property (@(posedge ACLK) disable iff (!ARESETn) RVALID && RREADY && RLAST);
  cover property (@(posedge ACLK) disable iff (!ARESETn) ARVALID && ARREADY && (ARLEN == 0));
  cover property (@(posedge ACLK) disable iff (!ARESETn) ARVALID && ARREADY && (ARLEN > 0));

endmodule