// rtl/dma_axi_master_wr.sv

module dma_axi_master_wr #(
  parameter int unsigned ADDR_WIDTH = dma_pkg::ADDR_WIDTH,
  parameter int unsigned DATA_WIDTH = dma_pkg::DATA_WIDTH
) (
  input  logic                   clk,
  input  logic                   rst_n,

  // ----------------------------
  // Command interface
  // ----------------------------
  input  logic                   cmd_valid,
  output logic                   cmd_ready,
  input  logic [ADDR_WIDTH-1:0]  cmd_addr,
  input  logic [7:0]             cmd_len,   // AXI AWLEN

  output logic                   wr_busy,
  output logic                   wr_done,   
  output logic                   wr_err,    

  input  logic                   fifo_out_valid,
  output logic                   fifo_out_ready,
  input  logic [DATA_WIDTH-1:0]  fifo_out_data,

  // ----------------------------
  // AXI4 Write Address Channel (AW)
  // ----------------------------
  output logic [ADDR_WIDTH-1:0]  M_AXI_AWADDR,
  output logic [7:0]             M_AXI_AWLEN,
  output logic [2:0]             M_AXI_AWSIZE,
  output logic [1:0]             M_AXI_AWBURST,
  output logic                   M_AXI_AWVALID,
  input  logic                   M_AXI_AWREADY,

  // ----------------------------
  // AXI4 Write Data Channel (W)
  // ----------------------------
  output logic [DATA_WIDTH-1:0]  M_AXI_WDATA,
  output logic [(DATA_WIDTH/8)-1:0] M_AXI_WSTRB,
  output logic                   M_AXI_WLAST,
  output logic                   M_AXI_WVALID,
  input  logic                   M_AXI_WREADY,

  // ----------------------------
  // AXI4 Write Response Channel (B)
  // ----------------------------
  input  logic [1:0]             M_AXI_BRESP,
  input  logic                   M_AXI_BVALID,
  output logic                   M_AXI_BREADY
);

  import dma_pkg::*;

  // ------------------------------------------------------------
  // AXI constants
  // ------------------------------------------------------------
  localparam logic [2:0] AXI_SIZE_LOCAL  = dma_pkg::axi_size_from_data_width(DATA_WIDTH);
  localparam logic [1:0] AXI_BURST_LOCAL = dma_pkg::AXI_BURST_INCR;
  localparam int unsigned STRB_WIDTH     = (DATA_WIDTH/8);

  // ------------------------------------------------------------
  // Internal state
  // ------------------------------------------------------------
  typedef enum logic [1:0] {
    ST_IDLE  = 2'd0,
    ST_AW    = 2'd1,
    ST_WDATA = 2'd2,
    ST_BRESP = 2'd3
  } wr_state_e;

  wr_state_e state, state_n;

  logic [ADDR_WIDTH-1:0] addr_q;
  logic [7:0]            len_q;            // AWLEN
  logic [8:0]            beats_left_q;     
  logic                  err_q;

  // Handshake 
  logic aw_fire;
  logic w_fire;
  logic b_fire;

  // ------------------------------------------------------------
  // Combinational assignments
  // ------------------------------------------------------------
  assign cmd_ready = (state == ST_IDLE);
  assign wr_busy   = (state != ST_IDLE);

  // AW channel
  assign M_AXI_AWADDR  = addr_q;
  assign M_AXI_AWLEN   = len_q;
  assign M_AXI_AWSIZE  = AXI_SIZE_LOCAL;
  assign M_AXI_AWBURST = AXI_BURST_LOCAL;

  assign M_AXI_AWVALID = (state == ST_AW);
  assign aw_fire       = M_AXI_AWVALID && M_AXI_AWREADY;

  // W channel
  assign fifo_out_ready = (state == ST_WDATA) ? M_AXI_WREADY : 1'b0;

  assign M_AXI_WVALID   = (state == ST_WDATA) ? fifo_out_valid : 1'b0;
  assign M_AXI_WDATA    = fifo_out_data;
  assign M_AXI_WSTRB    = {STRB_WIDTH{1'b1}};

  assign w_fire         = M_AXI_WVALID && M_AXI_WREADY;

  // WLAST
  assign M_AXI_WLAST    = (state == ST_WDATA) && (beats_left_q == 9'd1) && fifo_out_valid;

  // B channel
  assign M_AXI_BREADY   = (state == ST_BRESP);
  assign b_fire         = M_AXI_BVALID && M_AXI_BREADY;

  // ------------------------------------------------------------
  // Next-state logic
  // ------------------------------------------------------------
  always_comb begin
    state_n = state;

    unique case (state)
      ST_IDLE: begin
        if (cmd_valid) begin
          state_n = ST_AW;
        end
      end

      ST_AW: begin
        if (aw_fire) begin
          state_n = ST_WDATA;
        end
      end

      ST_WDATA: begin
        if (w_fire && (beats_left_q == 9'd1)) begin
          state_n = ST_BRESP;
        end
      end

      ST_BRESP: begin
        if (b_fire) begin
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
      state         <= ST_IDLE;
      addr_q        <= '0;
      len_q         <= '0;
      beats_left_q  <= '0;
      err_q         <= 1'b0;

      wr_done       <= 1'b0;
      wr_err        <= 1'b0;
    end else begin
      state   <= state_n;
      wr_done <= 1'b0;

      if (state == ST_IDLE && cmd_valid && cmd_ready) begin
        addr_q       <= cmd_addr;
        len_q        <= cmd_len;

        beats_left_q <= {1'b0, cmd_len} + 9'd1;
        
        err_q        <= 1'b0;
        wr_err       <= 1'b0;
      end

      if (state == ST_WDATA && w_fire) begin
        if (beats_left_q != 0) begin
          beats_left_q <= beats_left_q - 9'd1;
        end
      end

      if (state == ST_BRESP && b_fire) begin
        if (M_AXI_BRESP != dma_pkg::AXI_RESP_OKAY) begin
          err_q  <= 1'b1;
          wr_err <= 1'b1;
        end
        wr_done <= 1'b1; 
      end
    end
  end

endmodule



