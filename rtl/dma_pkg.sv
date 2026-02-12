// dma_pkg.sv

package dma_pkg;

  // ============================================================
  // Parameters
  // ============================================================
  parameter int unsigned DATA_WIDTH = 32;
  parameter int unsigned AXIL_DATA_WIDTH = 32;
  parameter int unsigned ADDR_WIDTH = 32;
  parameter int unsigned LEN_WIDTH  = 16;

  // FIFO
  parameter int unsigned FIFO_DEPTH  = 16; 
  parameter bit          FIFO_ENABLE = 1'b1;

  // AXI
  parameter int unsigned AXI_ID_WIDTH    = 4;
  localparam logic [AXI_ID_WIDTH-1:0] AXI_ID_FIXED = '0;
  parameter int unsigned MAX_BURST_LEN   = 16; 
  parameter bit [1:0]    AXI_BURST_TYPE  = 2'b01; // INCR
  localparam int unsigned AXI_MAX_BEATS  = 256;   // AXI4 protocol limit (LEN=255 -> 256 beats)

  // Restrictions
  parameter int unsigned AXI_BEAT_BYTES = (DATA_WIDTH/8);
  parameter bit          IRQ_ENABLE_DEFAULT = 1'b1;

  // ============================================================
  // Functions
  // ============================================================
  function automatic int unsigned clog2_int(input int unsigned v);
    int unsigned r;
    begin
      r = 0;
      if (v <= 1) return 0;
      v = v - 1;
      while (v > 0) begin
        v >>= 1;
        r++;
      end
      return r;
    end
  endfunction

  // AXI size
  function automatic logic [2:0] axi_size_from_data_width(input int unsigned dw);
     int unsigned bytes;
     logic [31:0] tmp;
     begin
       bytes = (dw/8);
       tmp   = clog2_int(bytes);
       axi_size_from_data_width = tmp[2:0];
     end
  endfunction


  // ============================================================
  // AXI constants
  // ============================================================
  
  localparam logic [2:0] AXI_SIZE = axi_size_from_data_width(DATA_WIDTH);
  
  // BURST types
  localparam logic [1:0] AXI_BURST_FIXED = 2'b00;
  localparam logic [1:0] AXI_BURST_INCR  = 2'b01;
  localparam logic [1:0] AXI_BURST_WRAP  = 2'b10;

  // RESP
  localparam logic [1:0] AXI_RESP_OKAY   = 2'b00;
  localparam logic [1:0] AXI_RESP_EXOKAY = 2'b01;
  localparam logic [1:0] AXI_RESP_SLVERR = 2'b10;
  localparam logic [1:0] AXI_RESP_DECERR = 2'b11;

  // ============================================================
  // Register Map (AXI4-Lite) 
  // ============================================================
  localparam logic [7:0] CSR_CTRL_OFF      = 8'h00; // R/W
  localparam logic [7:0] CSR_STATUS_OFF    = 8'h04; // R
  localparam logic [7:0] CSR_SRC_ADDR_OFF  = 8'h08; // R/W
  localparam logic [7:0] CSR_DST_ADDR_OFF  = 8'h0C; // R/W
  localparam logic [7:0] CSR_LEN_BYTES_OFF = 8'h10; // R/W
  localparam logic [7:0] CSR_BURST_CFG_OFF = 8'h14; // R/W 
  localparam logic [7:0] CSR_ERROR_CODE_OFF= 8'h18; // R
  localparam logic [7:0] CSR_IRQ_STATUS_OFF= 8'h1C; // R/W1C

  // Reset values 
  localparam logic [31:0] CSR_CTRL_RST       = 32'h0000_0000;
  localparam logic [31:0] CSR_STATUS_RST     = 32'h0000_0000;
  localparam logic [31:0] CSR_SRC_ADDR_RST   = 32'h0000_0000;
  localparam logic [31:0] CSR_DST_ADDR_RST   = 32'h0000_0000;
  localparam logic [31:0] CSR_LEN_BYTES_RST  = 32'h0000_0000;
  localparam logic [31:0] CSR_BURST_CFG_RST  = 32'h0000_0010; 
  localparam logic [31:0] CSR_ERROR_CODE_RST = 32'h0000_0000;
  localparam logic [31:0] CSR_IRQ_STATUS_RST = 32'h0000_0000;

  // ============================================================
  // Bitfields 
  // ============================================================

  typedef struct packed {
    logic [27:0] rsvd_31_4;
    logic        abort_w1p;     // [3]
    logic        sw_reset_w1p;  // [2]
    logic        irq_en;        // [1]
    logic        start_w1p;     // [0]
  } csr_ctrl_t;

  typedef struct packed {
    logic [28:0] rsvd_31_3;
    logic        error; // [2]
    logic        done;  // [1]
    logic        busy;  // [0]
  } csr_status_t;

  typedef struct packed {
    logic [23:0] rsvd_31_8;
    logic [7:0]  max_beats; // [7:0]
  } csr_burst_cfg_t;

  typedef struct packed {
    logic [29:0] rsvd_31_2;
    logic        irq_error; // [1] W1C
    logic        irq_done;  // [0] W1C
  } csr_irq_status_t;

  // ============================================================
  // Errors
  // ============================================================
  typedef enum logic [2:0] {
    ERR_NONE        = 3'd0, // None
    ERR_ALIGN       = 3'd1, // Invalid Address
    ERR_LEN         = 3'd2, // Invalid Length
    ERR_AXI_READ    = 3'd3, // AXI Read Error
    ERR_AXI_WRITE   = 3'd4, // AXI Write Error
    ERR_ABORT       = 3'd5  // Software Abort
  } dma_err_e;

  // ============================================================
  // FSM 
  // ============================================================
  typedef enum logic [3:0] {
    ST_IDLE       = 4'd0,
    ST_CHECK      = 4'd1,
    ST_READ_ADDR  = 4'd2,
    ST_READ_DATA  = 4'd3,
    ST_WRITE_ADDR = 4'd4,
    ST_WRITE_DATA = 4'd5,
    ST_WRITE_RESP = 4'd6,
    ST_DONE       = 4'd7,
    ST_ERROR      = 4'd8
  } dma_state_e;

  // ============================================================
  // Checkers
  // ============================================================

  // Alignment
  function automatic bit is_aligned(input logic [ADDR_WIDTH-1:0] addr);
    return (addr[clog2_int(AXI_BEAT_BYTES)-1:0] == '0);
  endfunction

  // LEN_BYTES 
  function automatic bit len_is_multiple_of_beat(input logic [31:0] len_bytes);
    int unsigned bytes_per_beat;
    begin
      bytes_per_beat = (DATA_WIDTH/8);
      return ((len_bytes % bytes_per_beat) == 0);
    end
  endfunction

  // Beats per burst 
  function automatic logic [7:0] compute_beats(
      input logic [31:0] bytes_remaining,
      input logic [7:0]  max_beats
    );
    int unsigned bytes_per_beat;
    int unsigned beats;
    begin
      bytes_per_beat = (DATA_WIDTH/8);
      beats = bytes_remaining / bytes_per_beat;
      if (beats > max_beats) 
      	 beats = max_beats;
      if (beats == 0) 
         beats = 1; 
      return logic'(beats[7:0]);
    end
  endfunction

  // ARLEN/AWLEN
  function automatic logic [7:0] axi_len_from_beats(input logic [7:0] beats);
    return (beats - 8'd1);
  endfunction

  // WSTRB
  function automatic logic [(DATA_WIDTH/8)-1:0] full_wstrb();
    return { (DATA_WIDTH/8){1'b1} };
  endfunction

  function automatic int unsigned effective_max_beats(input logic [7:0] max_beats_cfg);
    int unsigned m;
    begin
      m = (max_beats_cfg == 8'd0) ? AXI_MAX_BEATS : int'(max_beats_cfg);
      if (m > AXI_MAX_BEATS) m = AXI_MAX_BEATS;
      if (m > FIFO_DEPTH)    m = FIFO_DEPTH;
      if (m < 1)             m = 1;
      return m;
    end
  endfunction


  // ============================================================
  // Datatype
  // ============================================================

  typedef struct packed {
    logic [ADDR_WIDTH-1:0] src_addr;
    logic [ADDR_WIDTH-1:0] dst_addr;
    logic [31:0]           len_bytes;
    logic [7:0]            max_beats;
    logic                  irq_en;
  } dma_cfg_t;

  typedef struct packed {
    logic                  busy;
    logic                  done;
    logic                  error;
    dma_err_e              error_code;
    logic                  irq_done;
    logic                  irq_error;
  } dma_status_t;

endpackage


