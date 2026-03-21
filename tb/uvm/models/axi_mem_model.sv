interface axi_mem_model #(
  parameter int ADDR_W = 32,
  parameter int DATA_W = 32,
  parameter int STRB_W = DATA_W/8
) (input logic ACLK);
  logic ARESETn;

  logic [ADDR_W-1:0] ARADDR;
  logic [7:0]        ARLEN;
  logic [2:0]        ARSIZE;
  logic [1:0]        ARBURST;
  logic              ARVALID;
  logic              ARREADY;

  logic [DATA_W-1:0] RDATA;
  logic [1:0]        RRESP;
  logic              RLAST;
  logic              RVALID;
  logic              RREADY;

  logic [ADDR_W-1:0] AWADDR;
  logic [7:0]        AWLEN;
  logic [2:0]        AWSIZE;
  logic [1:0]        AWBURST;
  logic              AWVALID;
  logic              AWREADY;

  logic [DATA_W-1:0] WDATA;
  logic [STRB_W-1:0] WSTRB;
  logic              WLAST;
  logic              WVALID;
  logic              WREADY;

  logic [1:0]        BRESP;
  logic              BVALID;
  logic              BREADY;

  bit inject_rresp_err;
  bit inject_bresp_err;
  int unsigned ar_delay_cycles;
  int unsigned aw_delay_cycles;
  int unsigned r_delay_cycles;
  int unsigned b_delay_cycles;

  logic [7:0] mem [longint unsigned];

  function automatic logic [31:0] read_word(input logic [ADDR_W-1:0] addr);
    return {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr+0]};
  endfunction

  task automatic write_word(input logic [ADDR_W-1:0] addr, input logic [31:0] data);
    mem[addr+0] = data[7:0];
    mem[addr+1] = data[15:8];
    mem[addr+2] = data[23:16];
    mem[addr+3] = data[31:24];
  endtask

  task automatic fill_pattern(
    input logic [ADDR_W-1:0] base,
    input int unsigned       n_words,
    input logic [31:0]       seed
  );
    for (int i = 0; i < n_words; i++) begin
      write_word(base + i*4, seed + i);
    end
  endtask

  function automatic bit check_copy(
    input logic [ADDR_W-1:0] src,
    input logic [ADDR_W-1:0] dst,
    input int unsigned       n_words,
    output int unsigned      bad_idx,
    output logic [31:0]      exp,
    output logic [31:0]      got
  );
    check_copy = 1'b1;
    bad_idx    = '0;
    exp        = '0;
    got        = '0;
    for (int i = 0; i < n_words; i++) begin
      exp = read_word(src + i*4);
      got = read_word(dst + i*4);
      if (got !== exp) begin
        check_copy = 1'b0;
        bad_idx    = i;
        return check_copy;
      end
    end
  endfunction

  initial begin
    ARREADY = 0;
    RDATA   = '0;
    RRESP   = 2'b00;
    RLAST   = 0;
    RVALID  = 0;
    AWREADY = 0;
    WREADY  = 0;
    BRESP   = 2'b00;
    BVALID  = 0;
    inject_rresp_err = 0;
    inject_bresp_err = 0;
    ar_delay_cycles  = 0;
    aw_delay_cycles  = 0;
    r_delay_cycles   = 0;
    b_delay_cycles   = 0;
  end

  initial begin : rd_slave
    int unsigned beats;
    logic [ADDR_W-1:0] base;
    logic [31:0] data_word;
    logic last_word;

    forever begin
      @(negedge ACLK);
      if (!ARESETn) begin
        ARREADY <= 0;
      end else begin
        ARREADY <= 1;
        do @(posedge ACLK); while (!(ARVALID && ARREADY));
        repeat (ar_delay_cycles) @(posedge ACLK);
        base  = ARADDR;
        beats = int'(ARLEN) + 1;
        @(negedge ACLK);
        ARREADY <= 0;

        while (beats > 0) begin
          data_word = read_word(base);
          last_word = (beats == 1);
          repeat (r_delay_cycles) @(posedge ACLK);
          @(negedge ACLK);
          RVALID <= 1;
          RDATA  <= data_word;
          RRESP  <= inject_rresp_err ? 2'b10 : 2'b00;
          RLAST  <= last_word;
          do @(posedge ACLK); while (!(RVALID && RREADY));
          base  = base + (DATA_W/8);
          beats = beats - 1;
        end

        @(negedge ACLK);
        RVALID <= 0;
        RLAST  <= 0;
        RDATA  <= '0;
      end
    end
  end

  initial begin : wr_slave
    int unsigned beats;
    logic [ADDR_W-1:0] base;

    forever begin
      @(negedge ACLK);
      if (!ARESETn) begin
        AWREADY <= 0;
        WREADY  <= 0;
        BVALID  <= 0;
      end else begin
        AWREADY <= 1;
        do @(posedge ACLK); while (!(AWVALID && AWREADY));
        repeat (aw_delay_cycles) @(posedge ACLK);
        base  = AWADDR;
        beats = int'(AWLEN) + 1;
        @(negedge ACLK);
        AWREADY <= 0;
        WREADY  <= 1;

        while (beats > 0) begin
          do @(posedge ACLK); while (!(WVALID && WREADY));
          for (int b = 0; b < STRB_W; b++) begin
            if (WSTRB[b]) mem[base+b] = WDATA[b*8 +: 8];
          end
          base  = base + (DATA_W/8);
          beats = beats - 1;
        end

        @(negedge ACLK);
        WREADY <= 0;
        repeat (b_delay_cycles) @(posedge ACLK);
        @(negedge ACLK);
        BVALID <= 1;
        BRESP  <= inject_bresp_err ? 2'b10 : 2'b00;
        do @(posedge ACLK); while (!(BVALID && BREADY));
        @(negedge ACLK);
        BVALID <= 0;
      end
    end
  end
endinterface
