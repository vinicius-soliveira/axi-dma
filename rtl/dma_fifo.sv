// rtl/dma_fifo.sv

module dma_fifo #(
  parameter int unsigned WIDTH = 32,
  parameter int unsigned DEPTH = 64
) (
  input  logic                  clk,
  input  logic                  rst_n,

  // Input stream
  input  logic                  in_valid,
  output logic                  in_ready,
  input  logic [WIDTH-1:0]      in_data,

  // Output stream
  output logic                  out_valid,
  input  logic                  out_ready,
  output logic [WIDTH-1:0]      out_data,

  // Status
  output logic                  full,
  output logic                  empty,
  output logic [$clog2(DEPTH+1)-1:0] level
);

  localparam int unsigned AW = (DEPTH <= 1) ? 1 : $clog2(DEPTH);

  logic [WIDTH-1:0] mem [0:DEPTH-1];
  logic [AW-1:0]    rd_ptr, wr_ptr;

  logic [$clog2(DEPTH+1)-1:0] count;

  logic push, pop;

  // ----------------------------
  // Registered output stage
  // ----------------------------
  logic [WIDTH-1:0] out_data_r;
  logic             out_valid_r;

  // ----------------------------
  // Combinational status
  // ----------------------------
  assign full  = (count == DEPTH[$clog2(DEPTH+1)-1:0]);
  assign empty = (count == '0);

  assign in_ready  = ~full;

  assign out_valid = out_valid_r;
  assign out_data  = out_data_r;

  assign push = in_valid && in_ready;
  assign pop  = out_valid_r && out_ready;

  assign level = count;


  function automatic [AW-1:0] ptr_next(input [AW-1:0] p);
     ptr_next = (p == (DEPTH-1)) ? '0 : (p + 1'b1);
  endfunction

  logic [$clog2(DEPTH+1)-1:0] count_next;
  logic [AW-1:0] rd_ptr_next, wr_ptr_next;

  always_comb begin
    count_next  = count;
    rd_ptr_next = rd_ptr;
    wr_ptr_next = wr_ptr;

    unique case ({push, pop})
      2'b10: count_next = count + 1'b1;
      2'b01: count_next = count - 1'b1;
      default: ;
    endcase

    if (push) wr_ptr_next = ptr_next(wr_ptr);
    if (pop)  rd_ptr_next = ptr_next(rd_ptr);
  end

  logic do_fetch;
  assign do_fetch = (~out_valid_r) || pop;

  // ----------------------------
  // Sequential logic
  // ----------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr      <= '0;
      wr_ptr      <= '0;
      count       <= '0;
      out_valid_r <= 1'b0;
      out_data_r  <= '0;
    end else begin
      
      if (push) begin
        mem[wr_ptr] <= in_data;
        wr_ptr      <= wr_ptr_next;
      end

      if (pop) begin
        rd_ptr <= rd_ptr_next;
      end

      count <= count_next;

 
      if (do_fetch) begin
        if (count_next != '0) begin
          out_valid_r <= 1'b1;

          if ((count == '0) && push && !pop) begin
            out_data_r <= in_data;
          end
          else begin
            out_data_r <= mem[rd_ptr_next];
          end
        end else begin
          out_valid_r <= 1'b0;
        end
      end
    end
  end

endmodule


