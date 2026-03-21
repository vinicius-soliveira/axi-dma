// dma_fsm.sv — pipelined version
// Pipeline: write address is issued once FIFO has enough data,
// while the read master is still fetching remaining beats.
// Guard: only enters ST_PIPE_WR_ADDR when wr_busy=0 (master idle).
// ST_WRITE_RESP exits on wr_done=1 (wr_busy guard only at pipeline entry).

module dma_fsm #(
  parameter int unsigned ADDR_WIDTH = dma_pkg::ADDR_WIDTH,
  parameter int unsigned DATA_WIDTH = dma_pkg::DATA_WIDTH,
  parameter int unsigned FIFO_DEPTH = dma_pkg::FIFO_DEPTH
) (
  input  logic                             clk,
  input  logic                             rst_n,

  input  logic                             start_pulse,
  input  logic                             abort_pulse,
  input  logic                             soft_rst_pulse,
  input  logic                             status_ack,

  input  logic [ADDR_WIDTH-1:0]            src_addr,
  input  logic [ADDR_WIDTH-1:0]            dst_addr,
  input  logic [31:0]                      len_bytes,
  input  logic [7:0]                       max_beats_cfg,

  input  logic                             fifo_empty,
  input  logic                             fifo_full,
  input  logic [$clog2(FIFO_DEPTH+1)-1:0] fifo_level,

  output logic                             rd_cmd_valid,
  input  logic                             rd_cmd_ready,
  output logic [ADDR_WIDTH-1:0]            rd_cmd_addr,
  output logic [7:0]                       rd_cmd_len,
  input  logic                             rd_done,
  input  logic                             rd_err,

  output logic                             wr_cmd_valid,
  input  logic                             wr_cmd_ready,
  output logic [ADDR_WIDTH-1:0]            wr_cmd_addr,
  output logic [7:0]                       wr_cmd_len,
  input  logic                             wr_done,
  input  logic                             wr_err,
  input  logic                             wr_busy,    // NEW: from write master

  output logic                             core_busy,
  output logic                             core_done_pulse,
  output logic                             core_err_pulse,
  output logic [3:0]                       core_err_code
);

  import dma_pkg::*;

  localparam int unsigned BYTES_PER_BEAT = DATA_WIDTH / 8;

  // ------------------------------------------------------------------
  // State encoding
  // ------------------------------------------------------------------
  typedef enum logic [3:0] {
    ST_IDLE         = 4'd0,
    ST_CHECK        = 4'd1,
    ST_READ_ADDR    = 4'd2,
    ST_READ_DATA    = 4'd3,
    ST_PIPE_WR_ADDR = 4'd4,  // pipeline: issue WR addr while read runs
    ST_WRITE_ADDR   = 4'd5,  // sequential fallback (rd_done before threshold)
    ST_WRITE_RESP   = 4'd6,
    ST_DONE         = 4'd7,
    ST_ERROR        = 4'd8
  } dma_state_e;

  dma_state_e state, state_n;

  // ------------------------------------------------------------------
  // Datapath registers
  // ------------------------------------------------------------------
  logic [ADDR_WIDTH-1:0] cur_src_q, cur_dst_q;
  logic [31:0]           rem_bytes_q;
  logic [8:0]            burst_beats_q;
  logic [7:0]            burst_len_q;
  logic [3:0]            err_code_q;
  logic                  wr_addr_issued_q; // set when pipeline path taken

  // Combinational burst update
  logic [31:0] rem_next;
  logic [8:0]  beats_next;

  // ------------------------------------------------------------------
  // Functions
  // ------------------------------------------------------------------
  function automatic logic [ADDR_WIDTH-1:0] addr_mask;
    addr_mask = ADDR_WIDTH'(BYTES_PER_BEAT - 1);
  endfunction

  function automatic logic loc_aligned(input logic [ADDR_WIDTH-1:0] a);
    loc_aligned = ((a & addr_mask()) == '0);
  endfunction

  function automatic logic [8:0] calc_beats(
    input logic [31:0] rem_b,
    input logic [7:0]  max_b
  );
    int unsigned beats, m;
    m     = (max_b == 8'd0) ? 256 : int'(max_b);
    if (m > 256) m = 256;
    beats = int'(rem_b) / BYTES_PER_BEAT;
    if (beats > m)  beats = m;
    if (beats == 0) beats = 1;
    calc_beats = 9'(beats);
  endfunction

  function automatic logic [7:0] to_axlen(input logic [8:0] beats);
    to_axlen = 8'(beats - 9'd1);
  endfunction

  // ------------------------------------------------------------------
  // Configuration checks
  // ------------------------------------------------------------------
  logic len_ok, align_ok, fifo_ok, cfg_ok;

  assign len_ok   = (len_bytes != '0) &&
                    ((len_bytes % 32'(BYTES_PER_BEAT)) == '0);
  assign align_ok = loc_aligned(src_addr) && loc_aligned(dst_addr);
  assign fifo_ok  = fifo_empty && !fifo_full;
  assign cfg_ok   = len_ok && align_ok && fifo_ok;

  // Pipeline threshold: FIFO has accumulated all beats for this burst.
  // The write master needs the full burst in the FIFO before it starts,
  // otherwise it stalls mid-burst waiting for data.
  logic pipeline_wr_ready;
  assign pipeline_wr_ready =
      (fifo_level >= ($clog2(FIFO_DEPTH+1))'(burst_beats_q));

  // ------------------------------------------------------------------
  // Output assignments
  // ------------------------------------------------------------------
  assign rd_cmd_addr   = cur_src_q;
  assign rd_cmd_len    = burst_len_q;
  assign wr_cmd_addr   = cur_dst_q;
  assign wr_cmd_len    = burst_len_q;
  assign core_err_code = err_code_q;

  always_comb
    core_busy = (state != ST_IDLE) &&
                (state != ST_DONE) &&
                (state != ST_ERROR);

  // ------------------------------------------------------------------
  // Burst update (combinational)
  // ------------------------------------------------------------------
  always_comb begin
    rem_next   = rem_bytes_q - (32'(burst_beats_q) * 32'(BYTES_PER_BEAT));
    beats_next = calc_beats(rem_next, max_beats_cfg);
  end

  // ------------------------------------------------------------------
  // Next-state
  // ------------------------------------------------------------------
  always_comb begin
    state_n      = state;
    rd_cmd_valid = 1'b0;
    wr_cmd_valid = 1'b0;

    unique case (state)

      ST_IDLE:
        if (start_pulse) state_n = ST_CHECK;

      ST_CHECK:
        if (abort_pulse || !cfg_ok) state_n = ST_ERROR;
        else                        state_n = ST_READ_ADDR;

      ST_READ_ADDR: begin
        rd_cmd_valid = 1'b1;
        if (abort_pulse)       state_n = ST_ERROR;
        else if (rd_cmd_ready) state_n = ST_READ_DATA;
      end

      ST_READ_DATA: begin
        if (abort_pulse)
          state_n = ST_ERROR;
        else if (rd_done) begin
          if (rd_err)
            state_n = ST_ERROR;
          else if (wr_addr_issued_q)
            // Pipeline path: WR addr already sent, wait for rd_done then
            // go straight to ST_WRITE_RESP (wr_done is the exit condition)
            state_n = ST_WRITE_RESP;
          else
            // Sequential fallback: rd finished before FIFO threshold
            state_n = ST_WRITE_ADDR;
        end
        // Pipeline trigger: FIFO has enough data AND master is idle
        else if (pipeline_wr_ready && !wr_addr_issued_q && !wr_busy)
          state_n = ST_PIPE_WR_ADDR;
      end

      ST_PIPE_WR_ADDR: begin
        wr_cmd_valid = 1'b1;
        if (abort_pulse)
          state_n = ST_ERROR;
        else if (wr_cmd_ready)
          state_n = ST_READ_DATA; // back to waiting for rd_done
      end

      ST_WRITE_ADDR: begin
        wr_cmd_valid = 1'b1;
        if (abort_pulse)       state_n = ST_ERROR;
        else if (wr_cmd_ready) state_n = ST_WRITE_RESP;
      end

      // wr_done is a registered 1-cycle pulse fired from ST_BRESP.
      // At that exact cycle the master is still in ST_BRESP (wr_busy=1).
      // wr_busy only falls to 0 the NEXT cycle when state moves to ST_IDLE,
      // but by then wr_done is already back to 0.
      // Conclusion: wr_done=1 && wr_busy=0 can NEVER be true simultaneously.
      // Correct condition: just wr_done — it is already the final handshake.
      ST_WRITE_RESP: begin
        if (abort_pulse)
          state_n = ST_ERROR;
        else if (wr_done) begin
          if (wr_err)
            state_n = ST_ERROR;
          else if (rem_next == '0)
            state_n = ST_DONE;
          else
            state_n = ST_READ_ADDR;
        end
      end

      ST_DONE:  if (status_ack) state_n = ST_IDLE;
      ST_ERROR: if (status_ack) state_n = ST_IDLE;
      default:  state_n = ST_IDLE;

    endcase
  end

  // ------------------------------------------------------------------
  // Sequential
  // ------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state            <= ST_IDLE;
      cur_src_q        <= '0;
      cur_dst_q        <= '0;
      rem_bytes_q      <= '0;
      burst_beats_q    <= '0;
      burst_len_q      <= '0;
      err_code_q       <= '0;
      wr_addr_issued_q <= 1'b0;
      core_done_pulse  <= 1'b0;
      core_err_pulse   <= 1'b0;

    end else begin
      core_done_pulse <= 1'b0;
      core_err_pulse  <= 1'b0;

      if (soft_rst_pulse) begin
        state            <= ST_IDLE;
        cur_src_q        <= '0;
        cur_dst_q        <= '0;
        rem_bytes_q      <= '0;
        burst_beats_q    <= '0;
        burst_len_q      <= '0;
        err_code_q       <= '0;
        wr_addr_issued_q <= 1'b0;

      end else begin
        state <= state_n;

        // Latch config on start
        if (state == ST_IDLE && start_pulse) begin
          cur_src_q        <= src_addr;
          cur_dst_q        <= dst_addr;
          rem_bytes_q      <= len_bytes;
          burst_beats_q    <= calc_beats(len_bytes, max_beats_cfg);
          burst_len_q      <= to_axlen(calc_beats(len_bytes, max_beats_cfg));
          err_code_q       <= '0;
          wr_addr_issued_q <= 1'b0;
        end

        // Mark write address as issued (pipeline path)
        if (state == ST_PIPE_WR_ADDR && wr_cmd_ready)
          wr_addr_issued_q <= 1'b1;

        // Config errors
        if (state == ST_CHECK && !cfg_ok) begin
          if      (!len_ok)   err_code_q <= 4'(ERR_LEN);
          else if (!align_ok) err_code_q <= 4'(ERR_ALIGN);
          else                err_code_q <= 4'd6; // ERR_FIFO
        end

        // AXI errors
        if (state == ST_READ_DATA && rd_done && rd_err)
          err_code_q <= 4'(ERR_AXI_READ);
        if (state == ST_WRITE_RESP && wr_done && wr_err)
          err_code_q <= 4'(ERR_AXI_WRITE);

        // Abort
        if (abort_pulse &&
            state != ST_IDLE && state != ST_DONE && state != ST_ERROR)
          err_code_q <= 4'(ERR_ABORT);

        // Burst completion: advance pointers, compute next burst
        if (state == ST_WRITE_RESP && wr_done && !wr_err) begin
          rem_bytes_q      <= rem_next;
          cur_src_q        <= cur_src_q + (32'(burst_beats_q) * 32'(BYTES_PER_BEAT));
          cur_dst_q        <= cur_dst_q + (32'(burst_beats_q) * 32'(BYTES_PER_BEAT));
          burst_beats_q    <= beats_next;
          burst_len_q      <= to_axlen(beats_next);
          wr_addr_issued_q <= 1'b0; // reset for next burst
        end

        // Done / error one-cycle pulses
        if (state != ST_DONE  && state_n == ST_DONE)  core_done_pulse <= 1'b1;
        if (state != ST_ERROR && state_n == ST_ERROR) core_err_pulse  <= 1'b1;

        // Clear error code when returning to IDLE
        if ((state == ST_DONE || state == ST_ERROR) && status_ack)
          err_code_q <= '0;

      end
    end
  end

endmodule

