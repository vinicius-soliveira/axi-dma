// rtl/dma_axi_top.sv 

module dma_axi_top #(
  parameter int unsigned ADDR_WIDTH      = dma_pkg::ADDR_WIDTH,
  parameter int unsigned DATA_WIDTH      = dma_pkg::DATA_WIDTH,
  parameter int unsigned AXIL_DATA_WIDTH = 32,
  parameter int unsigned FIFO_DEPTH      = dma_pkg::FIFO_DEPTH
) (
  input  logic                     ACLK,
  input  logic                     ARESETn,

  // ----------------------------
  // AXI-Lite slave 
  // ----------------------------
  input  logic [ADDR_WIDTH-1:0]    S_AXI_AWADDR,
  input  logic                     S_AXI_AWVALID,
  output logic                     S_AXI_AWREADY,

  input  logic [AXIL_DATA_WIDTH-1:0] S_AXI_WDATA,
  input  logic [(AXIL_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
  input  logic                     S_AXI_WVALID,
  output logic                     S_AXI_WREADY,

  output logic [1:0]               S_AXI_BRESP,
  output logic                     S_AXI_BVALID,
  input  logic                     S_AXI_BREADY,

  input  logic [ADDR_WIDTH-1:0]    S_AXI_ARADDR,
  input  logic                     S_AXI_ARVALID,
  output logic                     S_AXI_ARREADY,

  output logic [AXIL_DATA_WIDTH-1:0] S_AXI_RDATA,
  output logic [1:0]               S_AXI_RRESP,
  output logic                     S_AXI_RVALID,
  input  logic                     S_AXI_RREADY,

  // ----------------------------
  // AXI Read Master 
  // ----------------------------
  output logic [ADDR_WIDTH-1:0]    M_AXI_ARADDR,
  output logic [7:0]               M_AXI_ARLEN,
  output logic [2:0]               M_AXI_ARSIZE,
  output logic [1:0]               M_AXI_ARBURST,
  output logic                     M_AXI_ARVALID,
  input  logic                     M_AXI_ARREADY,

  input  logic [DATA_WIDTH-1:0]    M_AXI_RDATA,
  input  logic [1:0]               M_AXI_RRESP,
  input  logic                     M_AXI_RLAST,
  input  logic                     M_AXI_RVALID,
  output logic                     M_AXI_RREADY,

  // ----------------------------
  // AXI Write Master 
  // ----------------------------
  output logic [ADDR_WIDTH-1:0]    M_AXI_AWADDR,
  output logic [7:0]               M_AXI_AWLEN,
  output logic [2:0]               M_AXI_AWSIZE,
  output logic [1:0]               M_AXI_AWBURST,
  output logic                     M_AXI_AWVALID,
  input  logic                     M_AXI_AWREADY,

  output logic [DATA_WIDTH-1:0]    M_AXI_WDATA,
  output logic [(DATA_WIDTH/8)-1:0] M_AXI_WSTRB,
  output logic                     M_AXI_WLAST,
  output logic                     M_AXI_WVALID,
  input  logic                     M_AXI_WREADY,

  input  logic [1:0]               M_AXI_BRESP,
  input  logic                     M_AXI_BVALID,
  output logic                     M_AXI_BREADY,

  // ----------------------------
  // Interrupt
  // ----------------------------
  output logic                     IRQ
);

  import dma_pkg::*;

  wire rst_n = ARESETn;

  // ----------------------------
  // CSR <-> FSM wires
  // ----------------------------
  logic                 start_pulse, abort_pulse, soft_rst_pulse;
  logic [ADDR_WIDTH-1:0] src_addr, dst_addr;
  logic [31:0]           len_bytes;
  logic [7:0]            max_beats;      
  logic                 irq_en;
  logic                 csr_irq_o;

  logic                 core_busy;
  logic                 core_done_pulse;
  logic                 core_err_pulse;
  logic [3:0]           core_err_code;

  logic status_ack;

  // ----------------------------
  // FIFO wires
  // ----------------------------
  logic                 fifo_in_valid, fifo_in_ready;
  logic [DATA_WIDTH-1:0] fifo_in_data;

  logic                 fifo_out_valid, fifo_out_ready;
  logic [DATA_WIDTH-1:0] fifo_out_data;

  logic                 fifo_full, fifo_empty;
  logic [$clog2(FIFO_DEPTH+1)-1:0] fifo_level;

  // ----------------------------
  // FSM wires
  // ----------------------------
  logic                 rd_cmd_valid, rd_cmd_ready;
  logic [ADDR_WIDTH-1:0] rd_cmd_addr;
  logic [7:0]            rd_cmd_len;
  logic                 rd_done, rd_err;

  logic                 wr_cmd_valid, wr_cmd_ready;
  logic [ADDR_WIDTH-1:0] wr_cmd_addr;
  logic [7:0]            wr_cmd_len;
  logic                 wr_done, wr_err;

  // ----------------------------
  // CSR 
  // ----------------------------
  dma_csr #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .AXIL_DATA_WIDTH(AXIL_DATA_WIDTH)
  ) u_csr (
    .clk            (ACLK),
    .rst_n          (rst_n),

    .S_AXI_AWADDR   (S_AXI_AWADDR),
    .S_AXI_AWVALID  (S_AXI_AWVALID),
    .S_AXI_AWREADY  (S_AXI_AWREADY),

    .S_AXI_WDATA    (S_AXI_WDATA),
    .S_AXI_WSTRB    (S_AXI_WSTRB),
    .S_AXI_WVALID   (S_AXI_WVALID),
    .S_AXI_WREADY   (S_AXI_WREADY),

    .S_AXI_BRESP    (S_AXI_BRESP),
    .S_AXI_BVALID   (S_AXI_BVALID),
    .S_AXI_BREADY   (S_AXI_BREADY),

    .S_AXI_ARADDR   (S_AXI_ARADDR),
    .S_AXI_ARVALID  (S_AXI_ARVALID),
    .S_AXI_ARREADY  (S_AXI_ARREADY),

    .S_AXI_RDATA    (S_AXI_RDATA),
    .S_AXI_RRESP    (S_AXI_RRESP),
    .S_AXI_RVALID   (S_AXI_RVALID),
    .S_AXI_RREADY   (S_AXI_RREADY),

    .start_pulse    (start_pulse),
    .abort_pulse    (abort_pulse),
    .soft_rst_pulse (soft_rst_pulse),
    .status_ack     (status_ack),

    .src_addr       (src_addr),
    .dst_addr       (dst_addr),
    .len_bytes      (len_bytes),
    .max_beats      (max_beats),

    .irq_en         (irq_en),
    .irq_o          (csr_irq_o),

    .core_busy      (core_busy),
    .core_done_pulse(core_done_pulse),
    .core_err_pulse (core_err_pulse),
    .core_err_code  (dma_pkg::dma_err_e'(core_err_code)) 
  );

  assign IRQ = csr_irq_o;

  // ----------------------------
  // FIFO instance
  // ----------------------------
  dma_fifo #(
    .WIDTH (DATA_WIDTH),
    .DEPTH (FIFO_DEPTH)
  ) u_fifo (
    .clk       (ACLK),
    .rst_n     (rst_n),

    .in_valid  (fifo_in_valid),
    .in_ready  (fifo_in_ready),
    .in_data   (fifo_in_data),

    .out_valid (fifo_out_valid),
    .out_ready (fifo_out_ready),
    .out_data  (fifo_out_data),

    .full      (fifo_full),
    .empty     (fifo_empty),
    .level     (fifo_level)
  );

  // FSM instance
 
  assign status_ack = 1'b0; 

  dma_fsm #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) u_fsm (
    .clk            (ACLK),
    .rst_n          (rst_n),

    .start_pulse    (start_pulse),
    .abort_pulse    (abort_pulse),
    .soft_rst_pulse (soft_rst_pulse),
    .status_ack     (status_ack),

    .src_addr       (src_addr),
    .dst_addr       (dst_addr),
    .len_bytes      (len_bytes),

    .fifo_empty     (fifo_empty),
    .fifo_full      (fifo_full),

    .rd_cmd_valid   (rd_cmd_valid),
    .rd_cmd_ready   (rd_cmd_ready),
    .rd_cmd_addr    (rd_cmd_addr),
    .rd_cmd_len     (rd_cmd_len),
    .rd_done        (rd_done),
    .rd_err         (rd_err),

    .wr_cmd_valid   (wr_cmd_valid),
    .wr_cmd_ready   (wr_cmd_ready),
    .wr_cmd_addr    (wr_cmd_addr),
    .wr_cmd_len     (wr_cmd_len),
    .wr_done        (wr_done),
    .wr_err         (wr_err),

    .core_busy      (core_busy),
    .core_done_pulse(core_done_pulse),
    .core_err_pulse (core_err_pulse),
    .core_err_code  (core_err_code)
  );
  
  // Read master instance
  dma_axi_master_rd #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) u_rd (
    .clk           (ACLK),
    .rst_n         (rst_n),

    .cmd_valid     (rd_cmd_valid),
    .cmd_ready     (rd_cmd_ready),
    .cmd_addr      (rd_cmd_addr),
    .cmd_len       (rd_cmd_len),

    .rd_busy       (),
    .rd_done       (rd_done),
    .rd_err        (rd_err),

    .fifo_in_valid (fifo_in_valid),
    .fifo_in_ready (fifo_in_ready),
    .fifo_in_data  (fifo_in_data),

    .M_AXI_ARADDR  (M_AXI_ARADDR),
    .M_AXI_ARLEN   (M_AXI_ARLEN),
    .M_AXI_ARSIZE  (M_AXI_ARSIZE),
    .M_AXI_ARBURST (M_AXI_ARBURST),
    .M_AXI_ARVALID (M_AXI_ARVALID),
    .M_AXI_ARREADY (M_AXI_ARREADY),

    .M_AXI_RDATA   (M_AXI_RDATA),
    .M_AXI_RRESP   (M_AXI_RRESP),
    .M_AXI_RLAST   (M_AXI_RLAST),
    .M_AXI_RVALID  (M_AXI_RVALID),
    .M_AXI_RREADY  (M_AXI_RREADY)
  );

  // Write master instance
  dma_axi_master_wr #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) u_wr (
    .clk           (ACLK),
    .rst_n         (rst_n),

    .cmd_valid     (wr_cmd_valid),
    .cmd_ready     (wr_cmd_ready),
    .cmd_addr      (wr_cmd_addr),
    .cmd_len       (wr_cmd_len),

    .wr_busy       (),
    .wr_done       (wr_done),
    .wr_err        (wr_err),

    .fifo_out_valid(fifo_out_valid),
    .fifo_out_ready(fifo_out_ready),
    .fifo_out_data (fifo_out_data),

    .M_AXI_AWADDR  (M_AXI_AWADDR),
    .M_AXI_AWLEN   (M_AXI_AWLEN),
    .M_AXI_AWSIZE  (M_AXI_AWSIZE),
    .M_AXI_AWBURST (M_AXI_AWBURST),
    .M_AXI_AWVALID (M_AXI_AWVALID),
    .M_AXI_AWREADY (M_AXI_AWREADY),

    .M_AXI_WDATA   (M_AXI_WDATA),
    .M_AXI_WSTRB   (M_AXI_WSTRB),
    .M_AXI_WLAST   (M_AXI_WLAST),
    .M_AXI_WVALID  (M_AXI_WVALID),
    .M_AXI_WREADY  (M_AXI_WREADY),

    .M_AXI_BRESP   (M_AXI_BRESP),
    .M_AXI_BVALID  (M_AXI_BVALID),
    .M_AXI_BREADY  (M_AXI_BREADY)
  );

endmodule


