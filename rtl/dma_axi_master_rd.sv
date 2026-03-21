// rtl/dma_axi_master_rd.sv

module dma_axi_master_rd #(
  parameter int unsigned ADDR_WIDTH = dma_pkg::ADDR_WIDTH,
  parameter int unsigned DATA_WIDTH = dma_pkg::DATA_WIDTH
) (
  input  logic                   clk,
  input  logic                   rst_n,

  input  logic                   cmd_valid,
  output logic                   cmd_ready,
  input  logic [ADDR_WIDTH-1:0]  cmd_addr,
  input  logic [7:0]             cmd_len,   // AXI ARLEN = beats-1 (0..255)

  output logic                   rd_busy,
  output logic                   rd_done,   
  output logic                   rd_err,    

  output logic                   fifo_in_valid,
  input  logic                   fifo_in_ready,
  output logic [DATA_WIDTH-1:0]  fifo_in_data,

  output logic [ADDR_WIDTH-1:0]  M_AXI_ARADDR,
  output logic [7:0]             M_AXI_ARLEN,
  output logic [2:0]             M_AXI_ARSIZE,
  output logic [1:0]             M_AXI_ARBURST,
  output logic                   M_AXI_ARVALID,
  input  logic                   M_AXI_ARREADY,

  input  logic [DATA_WIDTH-1:0]  M_AXI_RDATA,
  input  logic [1:0]             M_AXI_RRESP,
  input  logic                   M_AXI_RLAST,
  input  logic                   M_AXI_RVALID,
  output logic                   M_AXI_RREADY
);

  import dma_pkg::*;

  // ------------------------------------------------------------
  // AXI constants 
  // ------------------------------------------------------------
  localparam logic [2:0] AXI_SIZE_LOCAL  = dma_pkg::axi_size_from_data_width(DATA_WIDTH);
  localparam logic [1:0] AXI_BURST_LOCAL = dma_pkg::AXI_BURST_INCR;

  // ------------------------------------------------------------
  // States
  // ------------------------------------------------------------
  typedef enum logic [1:0] {
    ST_IDLE  = 2'd0,
    ST_AR    = 2'd1,
    ST_RDATA = 2'd2
  } rd_state_e;

  rd_state_e state, state_n;

  logic [ADDR_WIDTH-1:0] addr_q;
  logic [7:0]            len_q;    // ARLEN
  logic                  err_q;   

  // Handshake
  logic ar_fire;
  logic r_fire;

  // ------------------------------------------------------------
  // Combinational
  // ------------------------------------------------------------
  assign cmd_ready = (state == ST_IDLE);
  assign rd_busy   = (state != ST_IDLE);

  // AR channel
  assign M_AXI_ARADDR  = addr_q;
  assign M_AXI_ARLEN   = len_q;
  assign M_AXI_ARSIZE  = AXI_SIZE_LOCAL;
  assign M_AXI_ARBURST = AXI_BURST_LOCAL;

  assign M_AXI_ARVALID = (state == ST_AR);
  assign ar_fire       = M_AXI_ARVALID && M_AXI_ARREADY;

  // R channel:
  assign M_AXI_RREADY  = (state == ST_RDATA) ? fifo_in_ready : 1'b0;
  assign r_fire        = M_AXI_RVALID && M_AXI_RREADY;

  // Stream into FIFO
  assign fifo_in_valid = (state == ST_RDATA) ? M_AXI_RVALID : 1'b0;
  assign fifo_in_data  = M_AXI_RDATA;

  // ------------------------------------------------------------
  // Next-state logic
  // ------------------------------------------------------------
  always_comb begin
    state_n = state;

    unique case (state)
      ST_IDLE: begin
        if (cmd_valid) begin
          state_n = ST_AR;
        end
      end

      ST_AR: begin
        if (ar_fire) begin
          state_n = ST_RDATA;
        end
      end

      ST_RDATA: begin
        if (r_fire && M_AXI_RLAST) begin
          state_n = ST_IDLE;
        end
      end

      default: state_n = ST_IDLE;
    endcase
  end

  // ------------------------------------------------------------
  // Sequential logic
  // ------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state   <= ST_IDLE;
      addr_q  <= '0;
      len_q   <= '0;
      err_q   <= 1'b0;

      rd_done <= 1'b0;
      rd_err  <= 1'b0;
    end else begin
      state   <= state_n;
      rd_done <= 1'b0;

      
      if (state == ST_IDLE && cmd_valid && cmd_ready) begin
        addr_q <= cmd_addr;
        len_q  <= cmd_len;
        
        err_q  <= 1'b0;
        rd_err <= 1'b0;
      end

      if (state == ST_RDATA && r_fire) begin
        if (M_AXI_RRESP != dma_pkg::AXI_RESP_OKAY) begin
          err_q  <= 1'b1;
          rd_err <= 1'b1;
        end

        if (M_AXI_RLAST) begin
          rd_done <= 1'b1;
        end
      end
    end
  end

endmodule



