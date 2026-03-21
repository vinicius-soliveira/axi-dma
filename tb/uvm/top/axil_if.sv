interface axil_if #(parameter int ADDR_W = 32, DATA_W = 32) (input logic ACLK);
  logic ARESETn;

  logic [ADDR_W-1:0] AWADDR;
  logic              AWVALID;
  logic              AWREADY;
  logic [DATA_W-1:0] WDATA;
  logic [(DATA_W/8)-1:0] WSTRB;
  logic              WVALID;
  logic              WREADY;
  logic [1:0]        BRESP;
  logic              BVALID;
  logic              BREADY;

  logic [ADDR_W-1:0] ARADDR;
  logic              ARVALID;
  logic              ARREADY;
  logic [DATA_W-1:0] RDATA;
  logic [1:0]        RRESP;
  logic              RVALID;
  logic              RREADY;

  clocking drv_cb @(posedge ACLK);
    default input #1step output #1step;
    output AWADDR, AWVALID, WDATA, WSTRB, WVALID, BREADY;
    output ARADDR, ARVALID, RREADY;
    input  AWREADY, WREADY, BRESP, BVALID;
    input  ARREADY, RDATA, RRESP, RVALID;
  endclocking

  clocking mon_cb @(posedge ACLK);
    default input #1step output #1step;
    input AWADDR, AWVALID, AWREADY;
    input WDATA, WSTRB, WVALID, WREADY;
    input BRESP, BVALID, BREADY;
    input ARADDR, ARVALID, ARREADY;
    input RDATA, RRESP, RVALID, RREADY;
  endclocking

  modport DUT (
    input  ACLK, ARESETn,
    input  AWADDR, AWVALID, WDATA, WSTRB, WVALID, BREADY,
    input  ARADDR, ARVALID, RREADY,
    output AWREADY, WREADY, BRESP, BVALID,
    output ARREADY, RDATA, RRESP, RVALID
  );

  modport TB (clocking drv_cb, clocking mon_cb, input ARESETn, input ACLK);
endinterface
