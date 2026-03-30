`timescale 1ns/1ps

module dma_tb;

  import dma_pkg::*;

  localparam integer ADDR_W    = 32;
  localparam integer DATA_W    = 32;
  localparam integer STRB_W    = DATA_W/8;
  localparam integer CLK_NS    = 10;
  localparam integer MEM_BYTES = 1 << 20;

  reg ACLK;
  reg ARESETn;

  initial begin
    ACLK = 1'b0;
  end

  always #(CLK_NS/2) ACLK = ~ACLK;

  // Important for GLS:
  // create a real reset pulse after time 0
  initial begin
    ARESETn = 1'b1;
    #1;
    ARESETn = 1'b0;
    $display("[TB] reset asserted t=%0t", $time);

    repeat (10) @(posedge ACLK);
    ARESETn = 1'b1;
    $display("[TB] reset deasserted t=%0t", $time);
  end

  // ------------------------------------------------------------
  // AXI-Lite slave side (CSR)
  // ------------------------------------------------------------
  reg  [ADDR_W-1:0] S_AXI_AWADDR;
  reg               S_AXI_AWVALID;
  wire              S_AXI_AWREADY;
  reg  [31:0]       S_AXI_WDATA;
  reg  [3:0]        S_AXI_WSTRB;
  reg               S_AXI_WVALID;
  wire              S_AXI_WREADY;
  wire [1:0]        S_AXI_BRESP;
  wire              S_AXI_BVALID;
  reg               S_AXI_BREADY;
  reg  [ADDR_W-1:0] S_AXI_ARADDR;
  reg               S_AXI_ARVALID;
  wire              S_AXI_ARREADY;
  wire [31:0]       S_AXI_RDATA;
  wire [1:0]        S_AXI_RRESP;
  wire              S_AXI_RVALID;
  reg               S_AXI_RREADY;

  // ------------------------------------------------------------
  // AXI master read channel
  // ------------------------------------------------------------
  wire [ADDR_W-1:0] M_AXI_ARADDR;
  wire [7:0]        M_AXI_ARLEN;
  wire [2:0]        M_AXI_ARSIZE;
  wire [1:0]        M_AXI_ARBURST;
  wire              M_AXI_ARVALID;
  reg               M_AXI_ARREADY;

  reg  [DATA_W-1:0] M_AXI_RDATA;
  reg  [1:0]        M_AXI_RRESP;
  reg               M_AXI_RLAST;
  reg               M_AXI_RVALID;
  wire              M_AXI_RREADY;

  // ------------------------------------------------------------
  // AXI master write channel
  // ------------------------------------------------------------
  wire [ADDR_W-1:0] M_AXI_AWADDR;
  wire [7:0]        M_AXI_AWLEN;
  wire [2:0]        M_AXI_AWSIZE;
  wire [1:0]        M_AXI_AWBURST;
  wire              M_AXI_AWVALID;
  reg               M_AXI_AWREADY;

  wire [DATA_W-1:0] M_AXI_WDATA;
  wire [STRB_W-1:0] M_AXI_WSTRB;
  wire              M_AXI_WLAST;
  wire              M_AXI_WVALID;
  reg               M_AXI_WREADY;

  reg  [1:0]        M_AXI_BRESP;
  reg               M_AXI_BVALID;
  wire              M_AXI_BREADY;

  wire IRQ;

  // ------------------------------------------------------------
  // DUT
  // ------------------------------------------------------------
  dma_axi_top dut (
    .ACLK         (ACLK),
    .ARESETn      (ARESETn),

    .S_AXI_AWADDR (S_AXI_AWADDR),
    .S_AXI_AWVALID(S_AXI_AWVALID),
    .S_AXI_AWREADY(S_AXI_AWREADY),
    .S_AXI_WDATA  (S_AXI_WDATA),
    .S_AXI_WSTRB  (S_AXI_WSTRB),
    .S_AXI_WVALID (S_AXI_WVALID),
    .S_AXI_WREADY (S_AXI_WREADY),
    .S_AXI_BRESP  (S_AXI_BRESP),
    .S_AXI_BVALID (S_AXI_BVALID),
    .S_AXI_BREADY (S_AXI_BREADY),
    .S_AXI_ARADDR (S_AXI_ARADDR),
    .S_AXI_ARVALID(S_AXI_ARVALID),
    .S_AXI_ARREADY(S_AXI_ARREADY),
    .S_AXI_RDATA  (S_AXI_RDATA),
    .S_AXI_RRESP  (S_AXI_RRESP),
    .S_AXI_RVALID (S_AXI_RVALID),
    .S_AXI_RREADY (S_AXI_RREADY),

    .M_AXI_ARADDR (M_AXI_ARADDR),
    .M_AXI_ARLEN  (M_AXI_ARLEN),
    .M_AXI_ARSIZE (M_AXI_ARSIZE),
    .M_AXI_ARBURST(M_AXI_ARBURST),
    .M_AXI_ARVALID(M_AXI_ARVALID),
    .M_AXI_ARREADY(M_AXI_ARREADY),
    .M_AXI_RDATA  (M_AXI_RDATA),
    .M_AXI_RRESP  (M_AXI_RRESP),
    .M_AXI_RLAST  (M_AXI_RLAST),
    .M_AXI_RVALID (M_AXI_RVALID),
    .M_AXI_RREADY (M_AXI_RREADY),

    .M_AXI_AWADDR (M_AXI_AWADDR),
    .M_AXI_AWLEN  (M_AXI_AWLEN),
    .M_AXI_AWSIZE (M_AXI_AWSIZE),
    .M_AXI_AWBURST(M_AXI_AWBURST),
    .M_AXI_AWVALID(M_AXI_AWVALID),
    .M_AXI_AWREADY(M_AXI_AWREADY),
    .M_AXI_WDATA  (M_AXI_WDATA),
    .M_AXI_WSTRB  (M_AXI_WSTRB),
    .M_AXI_WLAST  (M_AXI_WLAST),
    .M_AXI_WVALID (M_AXI_WVALID),
    .M_AXI_WREADY (M_AXI_WREADY),
    .M_AXI_BRESP  (M_AXI_BRESP),
    .M_AXI_BVALID (M_AXI_BVALID),
    .M_AXI_BREADY (M_AXI_BREADY),

    .IRQ          (IRQ)
  );

  // ------------------------------------------------------------
  // Simple byte-addressable memory model
  // ------------------------------------------------------------
  reg [7:0] mem [0:MEM_BYTES-1];

  function [31:0] mem_rd32;
    input [ADDR_W-1:0] addr;
    integer a;
    begin
      a = addr;
      mem_rd32 = {mem[a+3], mem[a+2], mem[a+1], mem[a+0]};
    end
  endfunction

  task mem_wr32;
    input [ADDR_W-1:0] addr;
    input [31:0] data;
    integer a;
    begin
      a = addr;
      mem[a+0] = data[7:0];
      mem[a+1] = data[15:8];
      mem[a+2] = data[23:16];
      mem[a+3] = data[31:24];
    end
  endtask

  task mem_fill;
    input [ADDR_W-1:0] base;
    input integer n_words;
    input [31:0] seed;
    integer i;
    begin
      for (i = 0; i < n_words; i = i + 1)
        mem_wr32(base + i*4, seed + i);
    end
  endtask

  task mem_check_range;
    input [ADDR_W-1:0] src;
    input [ADDR_W-1:0] dst;
    input integer n_words;
    integer i;
    reg [31:0] exp;
    reg [31:0] got;
    begin
      for (i = 0; i < n_words; i = i + 1) begin
        exp = mem_rd32(src + i*4);
        got = mem_rd32(dst + i*4);
        if (got !== exp) begin
          $display("[TB][FAIL] Mismatch word=%0d exp=%08h got=%08h t=%0t", i, exp, got, $time);
          $fatal(1);
        end
      end
    end
  endtask

  // ------------------------------------------------------------
  // AXI read slave model
  // ------------------------------------------------------------
  initial begin : rd_slave
    integer beats;
    reg [ADDR_W-1:0] base;
    reg [31:0] data_word;
    reg last_word;

    M_AXI_ARREADY = 0;
    M_AXI_RDATA   = 0;
    M_AXI_RRESP   = 2'b00;
    M_AXI_RLAST   = 0;
    M_AXI_RVALID  = 0;

    forever begin
      @(negedge ACLK);
      M_AXI_ARREADY <= 1'b1;

      wait (M_AXI_ARVALID && M_AXI_ARREADY);

      base  = M_AXI_ARADDR;
      beats = M_AXI_ARLEN + 1;

      $display("[TB] AR handshake addr=%08h len=%0d t=%0t", M_AXI_ARADDR, M_AXI_ARLEN, $time);

      @(negedge ACLK);
      M_AXI_ARREADY <= 1'b0;

      while (beats > 0) begin
        data_word = mem_rd32(base);
        last_word = (beats == 1);

        @(negedge ACLK);
        M_AXI_RVALID <= 1'b1;
        M_AXI_RDATA  <= data_word;
        M_AXI_RRESP  <= 2'b00;
        M_AXI_RLAST  <= last_word;

        wait (M_AXI_RVALID && M_AXI_RREADY);

        base  = base + 4;
        beats = beats - 1;
      end

      @(negedge ACLK);
      M_AXI_RVALID <= 1'b0;
      M_AXI_RLAST  <= 1'b0;
      M_AXI_RDATA  <= 0;
    end
  end

  // ------------------------------------------------------------
  // AXI write slave model
  // ------------------------------------------------------------
  initial begin : wr_slave
    integer beats;
    integer b;
    integer a;
    reg [ADDR_W-1:0] base;

    M_AXI_AWREADY = 0;
    M_AXI_WREADY  = 0;
    M_AXI_BVALID  = 0;
    M_AXI_BRESP   = 2'b00;

    forever begin
      @(negedge ACLK);
      M_AXI_AWREADY <= 1'b1;

      wait (M_AXI_AWVALID && M_AXI_AWREADY);

      base  = M_AXI_AWADDR;
      beats = M_AXI_AWLEN + 1;

      $display("[TB] AW handshake addr=%08h len=%0d t=%0t", M_AXI_AWADDR, M_AXI_AWLEN, $time);

      @(negedge ACLK);
      M_AXI_AWREADY <= 1'b0;
      M_AXI_WREADY  <= 1'b1;

      while (beats > 0) begin
        wait (M_AXI_WVALID && M_AXI_WREADY);

        a = base;
        for (b = 0; b < STRB_W; b = b + 1)
          if (M_AXI_WSTRB[b]) mem[a+b] = M_AXI_WDATA[b*8 +: 8];

        if ((beats == 1) && !M_AXI_WLAST) begin
          $display("[TB][FAIL] Missing WLAST t=%0t", $time);
          $fatal(1);
        end

        if ((beats > 1) && M_AXI_WLAST) begin
          $display("[TB][FAIL] Early WLAST t=%0t", $time);
          $fatal(1);
        end

        base  = base + 4;
        beats = beats - 1;
      end

      @(negedge ACLK);
      M_AXI_WREADY <= 1'b0;
      M_AXI_BVALID <= 1'b1;
      M_AXI_BRESP  <= 2'b00;

      wait (M_AXI_BVALID && M_AXI_BREADY);

      @(negedge ACLK);
      M_AXI_BVALID <= 1'b0;
    end
  end

  // ------------------------------------------------------------
  // AXI-Lite helpers with watchdogs
  // ------------------------------------------------------------
  task csr_write;
    input [ADDR_W-1:0] addr;
    input [31:0] data;
    reg aw_done;
    reg w_done;
    integer watchdog;
    begin
      $display("[TB] csr_write addr=%08h data=%08h t=%0t", addr, data, $time);

      aw_done   = 0;
      w_done    = 0;
      watchdog  = 0;

      @(negedge ACLK);
      S_AXI_AWADDR  <= addr;
      S_AXI_AWVALID <= 1'b1;
      S_AXI_WDATA   <= data;
      S_AXI_WSTRB   <= 4'hF;
      S_AXI_WVALID  <= 1'b1;
      S_AXI_BREADY  <= 1'b0;

      fork
        begin
          while (!aw_done) begin
            @(posedge ACLK);
            if (S_AXI_AWVALID && S_AXI_AWREADY) begin
              aw_done = 1;
              @(negedge ACLK);
              S_AXI_AWVALID <= 1'b0;
              $display("[TB]  AW done t=%0t", $time);
            end
          end
        end
        begin
          while (!w_done) begin
            @(posedge ACLK);
            if (S_AXI_WVALID && S_AXI_WREADY) begin
              w_done = 1;
              @(negedge ACLK);
              S_AXI_WVALID <= 1'b0;
              $display("[TB]  W done t=%0t", $time);
            end
          end
        end
      join_none

      while (!(aw_done && w_done)) begin
        @(posedge ACLK);
        watchdog = watchdog + 1;
        if (watchdog > 2000) begin
          $display("[TB][FAIL] csr_write timeout AW/W AWREADY=%b WREADY=%b t=%0t",
                   S_AXI_AWREADY, S_AXI_WREADY, $time);
          $fatal(1);
        end
      end
      disable fork;

      watchdog = 0;
      @(negedge ACLK);
      S_AXI_BREADY <= 1'b1;

      while (!(S_AXI_BVALID && S_AXI_BREADY)) begin
        @(posedge ACLK);
        watchdog = watchdog + 1;
        if (watchdog > 2000) begin
          $display("[TB][FAIL] csr_write timeout BVALID BVALID=%b BRESP=%0h t=%0t",
                   S_AXI_BVALID, S_AXI_BRESP, $time);
          $fatal(1);
        end
      end

      $display("[TB]  B done resp=%0h t=%0t", S_AXI_BRESP, $time);

      @(negedge ACLK);
      S_AXI_BREADY <= 1'b0;
    end
  endtask

  task csr_read;
    input  [ADDR_W-1:0] addr;
    output [31:0] data;
    integer watchdog;
    begin
      $display("[TB] csr_read addr=%08h t=%0t", addr, $time);

      watchdog = 0;
      @(negedge ACLK);
      S_AXI_ARADDR  <= addr;
      S_AXI_ARVALID <= 1'b1;
      S_AXI_RREADY  <= 1'b0;

      while (!(S_AXI_ARVALID && S_AXI_ARREADY)) begin
        @(posedge ACLK);
        watchdog = watchdog + 1;
        if (watchdog > 2000) begin
          $display("[TB][FAIL] csr_read timeout ARREADY ARREADY=%b t=%0t",
                   S_AXI_ARREADY, $time);
          $fatal(1);
        end
      end

      @(negedge ACLK);
      S_AXI_ARVALID <= 1'b0;

      watchdog = 0;
      @(negedge ACLK);
      S_AXI_RREADY <= 1'b1;

      while (!(S_AXI_RVALID && S_AXI_RREADY)) begin
        @(posedge ACLK);
        watchdog = watchdog + 1;
        if (watchdog > 2000) begin
          $display("[TB][FAIL] csr_read timeout RVALID RVALID=%b t=%0t",
                   S_AXI_RVALID, $time);
          $fatal(1);
        end
      end

      data = S_AXI_RDATA;
      $display("[TB]  R done data=%08h resp=%0h t=%0t", data, S_AXI_RRESP, $time);

      @(negedge ACLK);
      S_AXI_RREADY <= 1'b0;
    end
  endtask

  // ------------------------------------------------------------
  // DMA helpers
  // ------------------------------------------------------------
  task dma_start;
    input [ADDR_W-1:0] src;
    input [ADDR_W-1:0] dst;
    input [31:0] len_bytes;
    input [7:0] max_beats;
    begin
      $display("[TB] dma_start src=%08h dst=%08h len=%0d max_beats=%0d t=%0t",
               src, dst, len_bytes, max_beats, $time);
      csr_write(CSR_SRC_ADDR_OFF,  src);
      csr_write(CSR_DST_ADDR_OFF,  dst);
      csr_write(CSR_LEN_BYTES_OFF, len_bytes);
      csr_write(CSR_BURST_CFG_OFF, {24'd0, max_beats});
      csr_write(CSR_CTRL_OFF,      32'h0000_0003);
    end
  endtask

  task dma_wait_done;
    output reg got_err;
    reg [31:0] status;
    integer watchdog;
    begin
      got_err  = 1'b0;
      watchdog = 0;

      while (1) begin
        csr_read(CSR_STATUS_OFF, status);
        $display("[TB] status=%08h busy=%0b done=%0b err=%0b t=%0t",
                 status, status[0], status[1], status[2], $time);

        if (status[2]) begin
          got_err = 1'b1;
          disable dma_wait_done;
        end

        if (status[1]) begin
          disable dma_wait_done;
        end

        repeat (20) @(posedge ACLK);
        watchdog = watchdog + 1;

        if (watchdog > 300) begin
          $display("[TB][FAIL] Timeout waiting DMA completion t=%0t", $time);
          $fatal(1);
        end
      end
    end
  endtask

  task clear_done_and_wait_idle;
    reg [31:0] status;
    integer watchdog;
    begin
      $display("[TB] clear_done_and_wait_idle t=%0t", $time);
      csr_write(CSR_STATUS_OFF, 32'h0000_0002);
      watchdog = 0;

      while (1) begin
        csr_read(CSR_STATUS_OFF, status);
        if (!status[0]) disable clear_done_and_wait_idle;

        repeat (5) @(posedge ACLK);
        watchdog = watchdog + 1;

        if (watchdog > 100) begin
          $display("[TB][FAIL] Timeout waiting idle after clear t=%0t", $time);
          $fatal(1);
        end
      end
    end
  endtask

  task run_case;
    input [8*64-1:0] name;
    input [ADDR_W-1:0] src;
    input [ADDR_W-1:0] dst;
    input integer n_words;
    input [31:0] seed;
    input [7:0] max_beats;
    reg got_err;
    begin
      $display("\n[TB] run_case start: %0s t=%0t", name, $time);

      mem_fill(src, n_words, seed);
      dma_start(src, dst, n_words*4, max_beats);
      dma_wait_done(got_err);

      if (got_err) begin
        $display("[TB][FAIL] DMA signaled error in %0s t=%0t", name, $time);
        $fatal(1);
      end

      mem_check_range(src, dst, n_words);
      $display("[TB] %0s passed t=%0t", name, $time);

      clear_done_and_wait_idle();
    end
  endtask

  // ------------------------------------------------------------
  // Main stimulus
  // ------------------------------------------------------------
  initial begin
    integer i;

    $display("[TB] simulation started t=%0t", $time);
    $dumpfile("dma_tb.vcd");
    $dumpvars(0, dma_tb);

    for (i = 0; i < MEM_BYTES; i = i + 1)
      mem[i] = 8'h00;

    S_AXI_AWADDR  = 0;
    S_AXI_AWVALID = 0;
    S_AXI_WDATA   = 0;
    S_AXI_WSTRB   = 0;
    S_AXI_WVALID  = 0;
    S_AXI_BREADY  = 0;
    S_AXI_ARADDR  = 0;
    S_AXI_ARVALID = 0;
    S_AXI_RREADY  = 0;

    $display("[TB] waiting full reset sequence...");
    @(negedge ARESETn);
    @(posedge ARESETn);

    repeat (4) @(posedge ACLK);
    $display("[TB] reset released t=%0t", $time);
    $display("[TB] post-reset sample: AWREADY=%b WREADY=%b ARREADY=%b RVALID=%b BVALID=%b",
             S_AXI_AWREADY, S_AXI_WREADY, S_AXI_ARREADY, S_AXI_RVALID, S_AXI_BVALID);

    run_case("TC1: Single burst", 32'h0001_0000, 32'h0002_0000,  8, 32'hA000_0000, 8);
    run_case("TC2: Multi-burst",  32'h0001_1000, 32'h0002_1000, 20, 32'hB000_0000, 8);
    run_case("TC3: Short burst",  32'h0001_2000, 32'h0002_2000,  3, 32'hC000_0000, 8);

    $display("[TB][PASS] All directed GLS tests passed t=%0t", $time);
    repeat (10) @(posedge ACLK);
    $finish;
  end

  // global timeout
  initial begin
    #2000000;
    $display("[TB][FAIL] Global timeout t=%0t", $time);
    $fatal(1);
  end

endmodule
