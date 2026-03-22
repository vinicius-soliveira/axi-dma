module dma_axi_write_sva #(
  parameter int ADDR_W = 32,
  parameter int DATA_W = 32,
  parameter int STRB_W = DATA_W/8
)(
  input logic               ACLK,
  input logic               ARESETn,

  input logic [ADDR_W-1:0]  AWADDR,
  input logic [7:0]         AWLEN,
  input logic [2:0]         AWSIZE,
  input logic [1:0]         AWBURST,
  input logic               AWVALID,
  input logic               AWREADY,

  input logic [DATA_W-1:0]  WDATA,
  input logic [STRB_W-1:0]  WSTRB,
  input logic               WLAST,
  input logic               WVALID,
  input logic               WREADY,

  input logic [1:0]         BRESP,
  input logic               BVALID,
  input logic               BREADY
);

  logic        wr_active;
  logic [8:0]  wr_beats_left;

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      wr_active     <= 1'b0;
      wr_beats_left <= '0;
    end else begin
      if (AWVALID && AWREADY) begin
        wr_active     <= 1'b1;
        wr_beats_left <= AWLEN + 9'd1;
      end else if (WVALID && WREADY && wr_active) begin
        if (wr_beats_left > 9'd1) begin
          wr_beats_left <= wr_beats_left - 9'd1;
        end else begin
          wr_beats_left <= '0;
          wr_active     <= 1'b0;
        end
      end
    end
  end

  property p_awvalid_hold;
    @(posedge ACLK) disable iff (!ARESETn)
      AWVALID && !AWREADY |=> AWVALID;
  endproperty

  property p_aw_stable;
    @(posedge ACLK) disable iff (!ARESETn)
      AWVALID && !AWREADY |=> $stable(AWADDR)  &&
                              $stable(AWLEN)   &&
                              $stable(AWSIZE)  &&
                              $stable(AWBURST);
  endproperty

  property p_wvalid_hold;
    @(posedge ACLK) disable iff (!ARESETn)
      WVALID && !WREADY |=> WVALID;
  endproperty

  property p_w_stable;
    @(posedge ACLK) disable iff (!ARESETn)
      WVALID && !WREADY |=> $stable(WDATA) &&
                            $stable(WSTRB) &&
                            $stable(WLAST);
  endproperty

  property p_wlast_only_on_last_beat;
    @(posedge ACLK) disable iff (!ARESETn)
      (WVALID && WREADY && wr_active && (wr_beats_left > 9'd1)) |-> !WLAST;
  endproperty

  property p_last_beat_has_wlast;
    @(posedge ACLK) disable iff (!ARESETn)
      (WVALID && WREADY && wr_active && (wr_beats_left == 9'd1)) |-> WLAST;
  endproperty

  property p_bvalid_hold;
    @(posedge ACLK) disable iff (!ARESETn)
      BVALID && !BREADY |=> BVALID;
  endproperty

  property p_bresp_stable;
    @(posedge ACLK) disable iff (!ARESETn)
      BVALID && !BREADY |=> $stable(BRESP);
  endproperty
  
  // AWSIZE deve bater com largura de dados
  property p_awsize_matches_data_width;
    @(posedge ACLK) disable iff (!ARESETn)
      AWVALID |-> (AWSIZE == $clog2(DATA_W/8));
  endproperty

  // AWBURST deve ser INCR
  property p_awburst_incr_only;
    @(posedge ACLK) disable iff (!ARESETn)
      AWVALID |-> (AWBURST == 2'b01);
  endproperty

  // alinhamento de endereço
  property p_awaddr_aligned;
    @(posedge ACLK) disable iff (!ARESETn)
      AWVALID |-> (AWADDR % (1 << AWSIZE) == 0);
  endproperty

  assert property (p_awvalid_hold)
    else $error("DMA_AXI_WRITE_SVA: AWVALID dropped before handshake");

  assert property (p_aw_stable)
    else $error("DMA_AXI_WRITE_SVA: AW channel changed before handshake");

  assert property (p_wvalid_hold)
    else $error("DMA_AXI_WRITE_SVA: WVALID dropped before handshake");

  assert property (p_w_stable)
    else $error("DMA_AXI_WRITE_SVA: WDATA/WSTRB/WLAST changed before handshake");

  assert property (p_wlast_only_on_last_beat)
    else $error("DMA_AXI_WRITE_SVA: WLAST asserted too early");

  assert property (p_last_beat_has_wlast)
    else $error("DMA_AXI_WRITE_SVA: missing WLAST on final write beat");

  assert property (p_bvalid_hold)
    else $error("DMA_AXI_WRITE_SVA: BVALID dropped before handshake");

  assert property (p_bresp_stable)
    else $error("DMA_AXI_WRITE_SVA: BRESP changed before handshake");
    
  assert property (p_awsize_matches_data_width)
  	else $error("DMA_AXI_WRITE_SVA: AWSIZE mismatch");

  assert property (p_awburst_incr_only)
  	else $error("DMA_AXI_WRITE_SVA: AWBURST not INCR");

  assert property (p_awaddr_aligned)
  	else $error("DMA_AXI_WRITE_SVA: AWADDR not aligned");

  cover property (@(posedge ACLK) disable iff (!ARESETn) AWVALID && AWREADY);
  cover property (@(posedge ACLK) disable iff (!ARESETn) WVALID && WREADY && WLAST);
  cover property (@(posedge ACLK) disable iff (!ARESETn) BVALID && BREADY);
  cover property (@(posedge ACLK) disable iff (!ARESETn) AWVALID && AWREADY && (AWLEN == 0));
  cover property (@(posedge ACLK) disable iff (!ARESETn) AWVALID && AWREADY && (AWLEN > 0));

endmodule