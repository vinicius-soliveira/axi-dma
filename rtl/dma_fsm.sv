// rtl/dma_fsm.sv

module dma_fsm #(
  parameter int unsigned ADDR_WIDTH = dma_pkg::ADDR_WIDTH,
  parameter int unsigned DATA_WIDTH = dma_pkg::DATA_WIDTH,
  parameter int unsigned FIFO_DEPTH = dma_pkg::FIFO_DEPTH
) (
  input  logic                   clk,
  input  logic                   rst_n,

  // From CSR
  input  logic                   start_pulse,
  input  logic                   abort_pulse,
  input  logic                   soft_rst_pulse,
  input  logic                   status_ack,    

  input  logic [ADDR_WIDTH-1:0]  src_addr,
  input  logic [ADDR_WIDTH-1:0]  dst_addr,
  input  logic [31:0]            len_bytes,
  input logic [7:0]              max_beats_cfg,

  input  logic                   fifo_empty,
  input  logic                   fifo_full,

  // Read master command
  output logic                   rd_cmd_valid,
  input  logic                   rd_cmd_ready,
  output logic [ADDR_WIDTH-1:0]  rd_cmd_addr,
  output logic [7:0]             rd_cmd_len,   
  input  logic                   rd_done,
  input  logic                   rd_err,

  // Write master command 
  output logic                   wr_cmd_valid,
  input  logic                   wr_cmd_ready,
  output logic [ADDR_WIDTH-1:0]  wr_cmd_addr,
  output logic [7:0]             wr_cmd_len, 
  input  logic                   wr_done,
  input  logic                   wr_err,

  // To CSR
  output logic                   core_busy,
  output logic                   core_done_pulse,
  output logic                   core_err_pulse,
  output logic [3:0]             core_err_code
);

  import dma_pkg::*;

  // ----------------------------
  // Constants & Functions
  // ----------------------------
  localparam int unsigned BYTES_PER_BEAT  = AXI_BEAT_BYTES;
  localparam int unsigned MAX_BURST_BEATS = 256;

  function automatic logic is_aligned(input logic [ADDR_WIDTH-1:0] a);
    logic [ADDR_WIDTH-1:0] mask;
    begin
      mask = (BYTES_PER_BEAT-1);
      is_aligned = ((a & mask) == '0);
    end
  endfunction

  function automatic [8:0] calc_burst_beats(input [31:0] rem_b);
    int unsigned beats;
    begin
      beats = rem_b / BYTES_PER_BEAT;
      if (beats > MAX_BURST_BEATS) beats = MAX_BURST_BEATS;
      if (beats == 0) beats = 1;
      calc_burst_beats = beats[8:0];
    end
  endfunction

  function automatic [7:0] beats_to_len_field(input [8:0] beats);
    begin
      beats_to_len_field = (beats - 9'd1);
    end
  endfunction

  // ----------------------------
  // State
  // ----------------------------
  dma_state_e state, state_n;

  logic [ADDR_WIDTH-1:0] cur_src_q, cur_dst_q;
  logic [31:0]           rem_bytes_q;

  logic [8:0]            burst_beats_q;
  logic [7:0]            burst_len_q;

  logic [3:0]            err_code_q;

  logic len_ok, align_ok, fifo_ok, cfg_ok;

  assign core_err_code = err_code_q;

  always_comb begin
    core_busy = (state != ST_IDLE) && (state != ST_DONE) && (state != ST_ERROR);
  end

  // ----------------------------
  // Configuration checks
  // ----------------------------
  assign len_ok   = (len_bytes != 32'd0) && ((len_bytes % BYTES_PER_BEAT) == 0);
  assign align_ok = is_aligned(src_addr) && is_aligned(dst_addr);
  assign fifo_ok  = fifo_empty && !fifo_full; 
  assign cfg_ok   = len_ok && align_ok && fifo_ok;

  // ----------------------------
  // Command outputs 
  // ----------------------------
  assign rd_cmd_addr = cur_src_q;
  assign rd_cmd_len  = burst_len_q;

  assign wr_cmd_addr = cur_dst_q;
  assign wr_cmd_len  = burst_len_q;

  // ----------------------------
  // Next-state 
  // ----------------------------
  always_comb begin
    state_n        = state;

    rd_cmd_valid   = 1'b0;
    wr_cmd_valid   = 1'b0;

    unique case (state)

      ST_IDLE: begin
        if (start_pulse) begin
          state_n = ST_CHECK;
        end
      end

      ST_CHECK: begin
        if (abort_pulse) begin
          state_n = ST_ERROR;
        end else if (!cfg_ok) begin
          state_n = ST_ERROR;
        end else begin
          state_n = ST_READ_ADDR;
        end
      end

      ST_READ_ADDR: begin
        rd_cmd_valid = 1'b1;         
        if (abort_pulse) begin
          state_n = ST_ERROR;
        end else if (rd_cmd_ready) begin
          state_n = ST_READ_DATA;
        end
      end

      ST_READ_DATA: begin
        if (abort_pulse) begin
          state_n = ST_ERROR;
        end else if (rd_done) begin
          if (rd_err) state_n = ST_ERROR;
          else        state_n = ST_WRITE_ADDR;
        end
      end

      ST_WRITE_ADDR: begin
        wr_cmd_valid = 1'b1;          
        if (abort_pulse) begin
          state_n = ST_ERROR;
        end else if (wr_cmd_ready) begin
          state_n = ST_WRITE_RESP;
        end
      end

      ST_WRITE_RESP: begin
        if (abort_pulse) begin
          state_n = ST_ERROR;
        end else if (wr_done) begin
          if (wr_err) begin
            state_n = ST_ERROR;
          end else begin
            if (rem_bytes_q == (burst_beats_q * BYTES_PER_BEAT)) state_n = ST_DONE;
            else                                                state_n = ST_READ_ADDR;
          end
        end
      end

      ST_DONE: begin
        if (status_ack) state_n = ST_IDLE;
      end

      ST_ERROR: begin
        if (status_ack) state_n = ST_IDLE;
      end

      default: state_n = ST_IDLE;
    endcase
  end

  // ----------------------------
  // Sequential
  // ----------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state           <= ST_IDLE;

      cur_src_q       <= '0;
      cur_dst_q       <= '0;
      rem_bytes_q     <= 32'd0;

      burst_beats_q   <= 9'd0;
      burst_len_q     <= 8'd0;

      err_code_q      <= 4'd0;

      core_done_pulse <= 1'b0;
      core_err_pulse  <= 1'b0;

    end else begin

      core_done_pulse <= 1'b0;
      core_err_pulse  <= 1'b0;

      if (soft_rst_pulse) begin
        state       <= ST_IDLE;
        cur_src_q   <= '0;
        cur_dst_q   <= '0;
        rem_bytes_q <= 32'd0;
        burst_beats_q <= 9'd0;
        burst_len_q   <= 8'd0;
        err_code_q  <= 4'd0;
      end else begin
        state <= state_n;

        if (state == ST_IDLE && start_pulse) begin
          cur_src_q   <= src_addr;
          cur_dst_q   <= dst_addr;
          rem_bytes_q <= len_bytes;

          burst_beats_q <= calc_burst_beats(len_bytes);
          burst_len_q   <= beats_to_len_field(calc_burst_beats(len_bytes));

          err_code_q    <= 4'd0;
        end

        // Config error 
        if (state == ST_CHECK && !cfg_ok) begin
          if (!len_ok)        err_code_q <= 4'd2; 
          else if (!align_ok) err_code_q <= 4'd1; 
          else                err_code_q <= 4'd2;
        end

        // Read error 
        if (state == ST_READ_DATA && rd_done && rd_err) begin
          err_code_q <= 4'd3; 
        end

        // Write error
        if (state == ST_WRITE_RESP && wr_done && wr_err) begin
          err_code_q <= 4'd4; 
        end

        // Successful burst 
        if (state == ST_WRITE_RESP && wr_done && !wr_err) begin
          logic [31:0] rem_next;
          logic [8:0]  beats_next;

          rem_next   = rem_bytes_q - (burst_beats_q * BYTES_PER_BEAT);
          beats_next = calc_burst_beats(rem_next);

          // Update context
          rem_bytes_q   <= rem_next;
          cur_src_q     <= cur_src_q + (burst_beats_q * BYTES_PER_BEAT);
          cur_dst_q     <= cur_dst_q + (burst_beats_q * BYTES_PER_BEAT);
          burst_beats_q <= beats_next;
          burst_len_q   <= beats_to_len_field(beats_next);
        end

        if (state != ST_DONE && state_n == ST_DONE) begin
          core_done_pulse <= 1'b1;
        end
        if (state != ST_ERROR && state_n == ST_ERROR) begin
          core_err_pulse <= 1'b1;
        end

        if ((state == ST_DONE || state == ST_ERROR) && status_ack) begin
          err_code_q <= 4'd0;
        end
      end
    end
  end

endmodule

