`timescale 1ns/1ps

module dma_tb;

  import dma_pkg::*;

  localparam int unsigned ADDR_W = 32;
  localparam int unsigned DATA_W = 32;
  localparam int unsigned STRB_W = DATA_W/8;
  localparam int unsigned FIFO_D = 16;
  localparam int unsigned CLK_NS = 10;

  localparam bit DEBUG = 1'b0;

  logic ACLK = 0;
  logic ARESETn = 0;
  always #(CLK_NS/2) ACLK = ~ACLK;

  // -----------------------------
  // AXI-Lite CSR
  // -----------------------------
  logic [ADDR_W-1:0] S_AWADDR;
  logic              S_AWVALID;
  logic              S_AWREADY;
  logic [31:0]       S_WDATA;
  logic [3:0]        S_WSTRB;
  logic              S_WVALID;
  logic              S_WREADY;
  logic [1:0]        S_BRESP;
  logic              S_BVALID;
  logic              S_BREADY;
  logic [ADDR_W-1:0] S_ARADDR;
  logic              S_ARVALID;
  logic              S_ARREADY;
  logic [31:0]       S_RDATA;
  logic [1:0]        S_RRESP;
  logic              S_RVALID;
  logic              S_RREADY;

  // -----------------------------
  // AXI4 Read Master interface
  // -----------------------------
  logic [ADDR_W-1:0] M_ARADDR;
  logic [7:0]        M_ARLEN;
  logic [2:0]        M_ARSIZE;
  logic [1:0]        M_ARBURST;
  logic              M_ARVALID;
  logic              M_ARREADY;
  logic [DATA_W-1:0] M_RDATA;
  logic [1:0]        M_RRESP;
  logic              M_RLAST;
  logic              M_RVALID;
  logic              M_RREADY;

  // -----------------------------
  // AXI4 Write Master interface
  // -----------------------------
  logic [ADDR_W-1:0] M_AWADDR;
  logic [7:0]        M_AWLEN;
  logic [2:0]        M_AWSIZE;
  logic [1:0]        M_AWBURST;
  logic              M_AWVALID;
  logic              M_AWREADY;
  logic [DATA_W-1:0] M_WDATA;
  logic [STRB_W-1:0] M_WSTRB;
  logic              M_WLAST;
  logic              M_WVALID;
  logic              M_WREADY;
  logic [1:0]        M_BRESP;
  logic              M_BVALID;
  logic              M_BREADY;

  logic IRQ;

  // -----------------------------
  // DUT
  // -----------------------------
  dma_axi_top #(
    .ADDR_WIDTH      (ADDR_W),
    .DATA_WIDTH      (DATA_W),
    .AXIL_DATA_WIDTH (32),
    .FIFO_DEPTH      (FIFO_D)
  ) dut (
    .ACLK(ACLK),
    .ARESETn(ARESETn),

    .S_AXI_AWADDR (S_AWADDR),
    .S_AXI_AWVALID(S_AWVALID),
    .S_AXI_AWREADY(S_AWREADY),
    .S_AXI_WDATA  (S_WDATA),
    .S_AXI_WSTRB  (S_WSTRB),
    .S_AXI_WVALID (S_WVALID),
    .S_AXI_WREADY (S_WREADY),
    .S_AXI_BRESP  (S_BRESP),
    .S_AXI_BVALID (S_BVALID),
    .S_AXI_BREADY (S_BREADY),
    .S_AXI_ARADDR (S_ARADDR),
    .S_AXI_ARVALID(S_ARVALID),
    .S_AXI_ARREADY(S_ARREADY),
    .S_AXI_RDATA  (S_RDATA),
    .S_AXI_RRESP  (S_RRESP),
    .S_AXI_RVALID (S_RVALID),
    .S_AXI_RREADY (S_RREADY),

    .M_AXI_ARADDR (M_ARADDR),
    .M_AXI_ARLEN  (M_ARLEN),
    .M_AXI_ARSIZE (M_ARSIZE),
    .M_AXI_ARBURST(M_ARBURST),
    .M_AXI_ARVALID(M_ARVALID),
    .M_AXI_ARREADY(M_ARREADY),
    .M_AXI_RDATA  (M_RDATA),
    .M_AXI_RRESP  (M_RRESP),
    .M_AXI_RLAST  (M_RLAST),
    .M_AXI_RVALID (M_RVALID),
    .M_AXI_RREADY (M_RREADY),

    .M_AXI_AWADDR (M_AWADDR),
    .M_AXI_AWLEN  (M_AWLEN),
    .M_AXI_AWSIZE (M_AWSIZE),
    .M_AXI_AWBURST(M_AWBURST),
    .M_AXI_AWVALID(M_AWVALID),
    .M_AXI_AWREADY(M_AWREADY),
    .M_AXI_WDATA  (M_WDATA),
    .M_AXI_WSTRB  (M_WSTRB),
    .M_AXI_WLAST  (M_WLAST),
    .M_AXI_WVALID (M_WVALID),
    .M_AXI_WREADY (M_WREADY),
    .M_AXI_BRESP  (M_BRESP),
    .M_AXI_BVALID (M_BVALID),
    .M_AXI_BREADY (M_BREADY),

    .IRQ(IRQ)
  );

  // -----------------------------
  // Simple memory model
  // -----------------------------
  logic [7:0] mem [logic [ADDR_W-1:0]];

  function automatic logic [31:0] mem_rd32(input logic [ADDR_W-1:0] addr);
    return {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr+0]};
  endfunction

  task automatic mem_wr32(input logic [ADDR_W-1:0] addr, input logic [31:0] data);
    mem[addr+0] = data[7:0];
    mem[addr+1] = data[15:8];
    mem[addr+2] = data[23:16];
    mem[addr+3] = data[31:24];
  endtask

  task automatic mem_fill(
    input logic [ADDR_W-1:0] base,
    input int unsigned       n_words,
    input logic [31:0]       seed
  );
    for (int i = 0; i < n_words; i++) begin
      mem_wr32(base + i*4, seed + i);
    end
  endtask

  task automatic mem_check_range(
    input logic [ADDR_W-1:0] src,
    input logic [ADDR_W-1:0] dst,
    input int unsigned       n_words
  );
    logic [31:0] exp, got;
    for (int i = 0; i < n_words; i++) begin
      exp = mem_rd32(src + i*4);
      got = mem_rd32(dst + i*4);
      if (got !== exp) begin
        $error("[TB] Mismatch at word %0d: exp=%08h got=%08h", i, exp, got);
        $fatal(1);
      end
    end
  endtask

  // -----------------------------
  // AXI4 read slave model
  // -----------------------------
  initial begin : rd_slave
    int unsigned beats;
    logic [ADDR_W-1:0] base;
    logic [31:0] data_word;
    logic last_word;

    M_ARREADY = 0;
    M_RDATA   = '0;
    M_RRESP   = 2'b00;
    M_RLAST   = 0;
    M_RVALID  = 0;

    forever begin
      @(negedge ACLK);
      M_ARREADY <= 1;

      do @(posedge ACLK); while (!(M_ARVALID && M_ARREADY));

      base  = M_ARADDR;
      beats = int'(M_ARLEN) + 1;

      if (DEBUG)
        $display("[RD] AR addr=%08h len=%0d", M_ARADDR, M_ARLEN);

      @(negedge ACLK);
      M_ARREADY <= 0;

      while (beats > 0) begin
        data_word = mem_rd32(base);
        last_word = (beats == 1);

        @(negedge ACLK);
        M_RVALID <= 1;
        M_RDATA  <= data_word;
        M_RRESP  <= 2'b00;
        M_RLAST  <= last_word;

        do @(posedge ACLK); while (!(M_RVALID && M_RREADY));

        if (DEBUG)
          $display("[RD] data=%08h last=%0b", data_word, last_word);

        base  = base + (DATA_W/8);
        beats = beats - 1;
      end

      @(negedge ACLK);
      M_RVALID <= 0;
      M_RLAST  <= 0;
      M_RDATA  <= '0;
    end
  end

  // -----------------------------
  // AXI4 write slave model
  // -----------------------------
  initial begin : wr_slave
    int unsigned beats;
    logic [ADDR_W-1:0] base;

    M_AWREADY = 0;
    M_WREADY  = 0;
    M_BVALID  = 0;
    M_BRESP   = 2'b00;

    forever begin
      @(negedge ACLK);
      M_AWREADY <= 1;

      do @(posedge ACLK); while (!(M_AWVALID && M_AWREADY));

      base  = M_AWADDR;
      beats = int'(M_AWLEN) + 1;

      if (DEBUG)
        $display("[WR] AW addr=%08h len=%0d", M_AWADDR, M_AWLEN);

      @(negedge ACLK);
      M_AWREADY <= 0;
      M_WREADY  <= 1;

      while (beats > 0) begin
        do @(posedge ACLK); while (!(M_WVALID && M_WREADY));

        for (int b = 0; b < STRB_W; b++) begin
          if (M_WSTRB[b]) mem[base + b] = M_WDATA[b*8 +: 8];
        end

        if ((beats == 1) && !M_WLAST) begin
          $error("[TB] Missing WLAST on final beat");
          $fatal(1);
        end

        if ((beats > 1) && M_WLAST) begin
          $error("[TB] Early WLAST detected");
          $fatal(1);
        end

        if (DEBUG)
          $display("[WR] data=%08h last=%0b", M_WDATA, M_WLAST);

        base  = base + (DATA_W/8);
        beats = beats - 1;
      end

      @(negedge ACLK);
      M_WREADY <= 0;
      M_BVALID <= 1;
      M_BRESP  <= 2'b00;

      do @(posedge ACLK); while (!(M_BVALID && M_BREADY));

      @(negedge ACLK);
      M_BVALID <= 0;
    end
  end

  // -----------------------------
  // AXI-Lite helpers
  // -----------------------------
  task automatic csr_write(input logic [ADDR_W-1:0] addr, input logic [31:0] data);
    bit aw_done, w_done;
    begin
      aw_done = 0;
      w_done  = 0;

      @(negedge ACLK);
      S_AWADDR  <= addr;
      S_AWVALID <= 1;
      S_WDATA   <= data;
      S_WSTRB   <= 4'hF;
      S_WVALID  <= 1;
      S_BREADY  <= 0;

      fork
        begin
          while (!aw_done) begin
            @(posedge ACLK);
            if (S_AWVALID && S_AWREADY) begin
              aw_done = 1;
              @(negedge ACLK);
              S_AWVALID <= 0;
            end
          end
        end
        begin
          while (!w_done) begin
            @(posedge ACLK);
            if (S_WVALID && S_WREADY) begin
              w_done = 1;
              @(negedge ACLK);
              S_WVALID <= 0;
            end
          end
        end
      join

      @(negedge ACLK);
      S_BREADY <= 1;
      do @(posedge ACLK); while (!(S_BVALID && S_BREADY));
      @(negedge ACLK);
      S_BREADY <= 0;
    end
  endtask

  task automatic csr_read(input logic [ADDR_W-1:0] addr, output logic [31:0] data);
    begin
      @(negedge ACLK);
      S_ARADDR  <= addr;
      S_ARVALID <= 1;
      S_RREADY  <= 0;

      do @(posedge ACLK); while (!(S_ARVALID && S_ARREADY));
      @(negedge ACLK);
      S_ARVALID <= 0;

      @(negedge ACLK);
      S_RREADY <= 1;
      do @(posedge ACLK); while (!(S_RVALID && S_RREADY));
      data = S_RDATA;
      @(negedge ACLK);
      S_RREADY <= 0;
    end
  endtask

  // -----------------------------
  // DMA helpers
  // -----------------------------
  task automatic dma_start(
    input logic [ADDR_W-1:0] src,
    input logic [ADDR_W-1:0] dst,
    input logic [31:0]       len_bytes,
    input logic [7:0]        max_beats = 8
  );
    csr_write(CSR_SRC_ADDR_OFF,  src);
    csr_write(CSR_DST_ADDR_OFF,  dst);
    csr_write(CSR_LEN_BYTES_OFF, len_bytes);
    csr_write(CSR_BURST_CFG_OFF, {24'd0, max_beats});
    csr_write(CSR_CTRL_OFF,      32'h0000_0003);
  endtask

  task automatic dma_wait_done(output logic got_err);
    logic [31:0] status;
    int watchdog;

    got_err  = 0;
    watchdog = 0;

    forever begin
      csr_read(CSR_STATUS_OFF, status);

      if (DEBUG) begin
        $display("[TB] status=%08h busy=%0b done=%0b err=%0b fsm=%0s wr_st=%0d fifo=%0d",
                 status, status[0], status[1], status[2],
                 dut.u_fsm.state.name(), dut.u_wr.state, dut.fifo_level);
      end

      if (status[2]) begin
        got_err = 1;
        disable dma_wait_done;
      end

      if (status[1]) begin
        disable dma_wait_done;
      end

      repeat (20) @(posedge ACLK);
      watchdog++;

      if (watchdog > 300) begin
        $error("[TB] Timeout waiting DMA completion");
        $fatal(1);
      end
    end
  endtask

  task automatic clear_done_and_wait_idle;
    begin
      csr_write(CSR_STATUS_OFF, 32'h0000_0002);
      do @(posedge ACLK); while (dut.u_fsm.state != dut.u_fsm.ST_IDLE);
    end
  endtask

  task automatic run_case(
    input string              name,
    input logic [ADDR_W-1:0]  src,
    input logic [ADDR_W-1:0]  dst,
    input int unsigned        n_words,
    input logic [31:0]        seed,
    input logic [7:0]         max_beats = 8
  );
    logic got_err;
    begin
      $display("\n=== %s ===", name);

      mem_fill(src, n_words, seed);
      dma_start(src, dst, n_words * 4, max_beats);
      dma_wait_done(got_err);

      if (got_err) begin
        $error("[TB] DMA signaled error in %s", name);
        $fatal(1);
      end

      mem_check_range(src, dst, n_words);
      $display("[TB] %s passed", name);

      clear_done_and_wait_idle();
    end
  endtask

  // -----------------------------
  // Optional monitors
  // -----------------------------
  generate
    if (DEBUG) begin : g_debug
      always @(posedge ACLK) begin
        if (ARESETn) begin
          $strobe("[MON] t=%0t AWV=%0b AWR=%0b WV=%0b WR=%0b WL=%0b BV=%0b BR=%0b | wr_busy=%0b wr_done=%0b | FSM=%0s | start=%0b",
                  $time,
                  M_AWVALID, M_AWREADY,
                  M_WVALID,  M_WREADY, M_WLAST,
                  M_BVALID,  M_BREADY,
                  dut.wr_master_busy, dut.wr_done,
                  dut.u_fsm.state.name(), dut.start_pulse);

          $strobe("[DBG] t=%0t WR_ST=%0d fifo_level=%0d fifo_empty=%0b fifo_out_valid=%0b",
                  $time,
                  dut.u_wr.state,
                  dut.fifo_level,
                  dut.fifo_empty,
                  dut.fifo_out_valid);
        end
      end
    end
  endgenerate

  // -----------------------------
  // Test sequence
  // -----------------------------
  initial begin
    
    $dumpfile("dma_tb.vcd");
    $dumpvars(0, dma_tb);
    
    S_AWADDR  = '0;
    S_AWVALID = 0;
    S_WDATA   = '0;
    S_WSTRB   = '0;
    S_WVALID  = 0;
    S_BREADY  = 0;
    S_ARADDR  = '0;
    S_ARVALID = 0;
    S_RREADY  = 0;

    repeat (5) @(posedge ACLK);
    ARESETn = 1;
    repeat (4) @(posedge ACLK);

    run_case("TC1: Single burst (32 B, 8 beats)",
             32'h0001_0000, 32'h0002_0000, 8,  32'hA000_0000, 8);

    run_case("TC2: Multi-burst (80 B, max_beats=8)",
             32'h0001_1000, 32'h0002_1000, 20, 32'hB000_0000, 8);

    run_case("TC3: Short burst (12 B, 3 beats)",
             32'h0001_2000, 32'h0002_2000, 3,  32'hC000_0000, 8);

    $display("\n[TB] All directed tests passed.");
    repeat (10) @(posedge ACLK);
    $finish;
  end

endmodule
