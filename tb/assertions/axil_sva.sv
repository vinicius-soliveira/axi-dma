module axil_sva #(
  parameter int ADDR_W = 32,
  parameter int DATA_W = 32
)(
  input logic                 ACLK,
  input logic                 ARESETn,

  input logic [ADDR_W-1:0]    AWADDR,
  input logic                 AWVALID,
  input logic                 AWREADY,
  input logic [DATA_W-1:0]    WDATA,
  input logic [(DATA_W/8)-1:0] WSTRB,
  input logic                 WVALID,
  input logic                 WREADY,
  input logic [1:0]           BRESP,
  input logic                 BVALID,
  input logic                 BREADY,

  input logic [ADDR_W-1:0]    ARADDR,
  input logic                 ARVALID,
  input logic                 ARREADY,
  input logic [DATA_W-1:0]    RDATA,
  input logic [1:0]           RRESP,
  input logic                 RVALID,
  input logic                 RREADY
);

  // -------------------------
  // Write address channel
  // -------------------------
  property p_awvalid_hold;
    @(posedge ACLK) disable iff (!ARESETn)
      AWVALID && !AWREADY |=> AWVALID;
  endproperty

  property p_awaddr_stable;
    @(posedge ACLK) disable iff (!ARESETn)
      AWVALID && !AWREADY |=> $stable(AWADDR);
  endproperty

  // -------------------------
  // Write data channel
  // -------------------------
  property p_wvalid_hold;
    @(posedge ACLK) disable iff (!ARESETn)
      WVALID && !WREADY |=> WVALID;
  endproperty

  property p_wdata_stable;
    @(posedge ACLK) disable iff (!ARESETn)
      WVALID && !WREADY |=> $stable(WDATA) && $stable(WSTRB);
  endproperty

  // -------------------------
  // Write response channel
  // -------------------------
  property p_bvalid_hold;
    @(posedge ACLK) disable iff (!ARESETn)
      BVALID && !BREADY |=> BVALID;
  endproperty

  property p_bresp_stable;
    @(posedge ACLK) disable iff (!ARESETn)
      BVALID && !BREADY |=> $stable(BRESP);
  endproperty

  // -------------------------
  // Read address channel
  // -------------------------
  property p_arvalid_hold;
    @(posedge ACLK) disable iff (!ARESETn)
      ARVALID && !ARREADY |=> ARVALID;
  endproperty

  property p_araddr_stable;
    @(posedge ACLK) disable iff (!ARESETn)
      ARVALID && !ARREADY |=> $stable(ARADDR);
  endproperty

  // -------------------------
  // Read data channel
  // -------------------------
  property p_rvalid_hold;
    @(posedge ACLK) disable iff (!ARESETn)
      RVALID && !RREADY |=> RVALID;
  endproperty

  property p_rdata_stable;
    @(posedge ACLK) disable iff (!ARESETn)
      RVALID && !RREADY |=> $stable(RDATA) && $stable(RRESP);
  endproperty

  // -------------------------
  // Assertions
  // -------------------------
  assert property (p_awvalid_hold)
    else $error("AXIL_SVA: AWVALID dropped before handshake");

  assert property (p_awaddr_stable)
    else $error("AXIL_SVA: AWADDR changed before handshake");

  assert property (p_wvalid_hold)
    else $error("AXIL_SVA: WVALID dropped before handshake");

  assert property (p_wdata_stable)
    else $error("AXIL_SVA: WDATA/WSTRB changed before handshake");

  assert property (p_bvalid_hold)
    else $error("AXIL_SVA: BVALID dropped before handshake");

  assert property (p_bresp_stable)
    else $error("AXIL_SVA: BRESP changed before handshake");

  assert property (p_arvalid_hold)
    else $error("AXIL_SVA: ARVALID dropped before handshake");

  assert property (p_araddr_stable)
    else $error("AXIL_SVA: ARADDR changed before handshake");

  assert property (p_rvalid_hold)
    else $error("AXIL_SVA: RVALID dropped before handshake");

  assert property (p_rdata_stable)
    else $error("AXIL_SVA: RDATA/RRESP changed before handshake");

  // -------------------------
  // Coverage
  // -------------------------
  cover property (@(posedge ACLK) disable iff (!ARESETn) AWVALID && AWREADY);
  cover property (@(posedge ACLK) disable iff (!ARESETn) WVALID  && WREADY);
  cover property (@(posedge ACLK) disable iff (!ARESETn) BVALID  && BREADY);
  cover property (@(posedge ACLK) disable iff (!ARESETn) ARVALID && ARREADY);
  cover property (@(posedge ACLK) disable iff (!ARESETn) RVALID  && RREADY);

endmodule