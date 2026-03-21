// rtl/dma_csr.sv

module dma_csr #(
  parameter int unsigned ADDR_WIDTH      = dma_pkg::ADDR_WIDTH,
  parameter int unsigned AXIL_DATA_WIDTH = 32
) (
  input  logic                       clk,
  input  logic                       rst_n,

  // ----------------------------
  // AXI4-Lite Slave Interface
  // ----------------------------
  // Write address channel
  input  logic [ADDR_WIDTH-1:0]      S_AXI_AWADDR,
  input  logic                       S_AXI_AWVALID,
  output logic                       S_AXI_AWREADY,

  // Write data channel
  input  logic [AXIL_DATA_WIDTH-1:0] S_AXI_WDATA,
  input  logic [(AXIL_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
  input  logic                       S_AXI_WVALID,
  output logic                       S_AXI_WREADY,

  // Write response channel
  output logic [1:0]                 S_AXI_BRESP,
  output logic                       S_AXI_BVALID,
  input  logic                       S_AXI_BREADY,

  // Read address channel
  input  logic [ADDR_WIDTH-1:0]      S_AXI_ARADDR,
  input  logic                       S_AXI_ARVALID,
  output logic                       S_AXI_ARREADY,

  // Read data channel
  output logic [AXIL_DATA_WIDTH-1:0] S_AXI_RDATA,
  output logic [1:0]                 S_AXI_RRESP,
  output logic                       S_AXI_RVALID,
  input  logic                       S_AXI_RREADY,

  // ----------------------------
  // Control outputs to core/FSM
  // ----------------------------
  output logic                       start_pulse,
  output logic                       abort_pulse,
  output logic                       soft_rst_pulse,
  output logic                       status_ack,

  output logic [ADDR_WIDTH-1:0]      src_addr,
  output logic [ADDR_WIDTH-1:0]      dst_addr,
  output logic [31:0]                len_bytes,
  output logic [7:0]                 max_beats,

  output logic                       irq_en,
  output logic                       irq_o,

  // ----------------------------
  // Status inputs from core/FSM
  // ----------------------------
  input  logic                       core_busy,
  input  logic                       core_done_pulse,
  input  logic                       core_err_pulse,
  input  dma_pkg::dma_err_e          core_err_code
);

  import dma_pkg::*;

  localparam int unsigned STRB_W = (AXIL_DATA_WIDTH/8);

  // ---------------------------------------
  // Internal register storage
  // ---------------------------------------
  logic [ADDR_WIDTH-1:0] src_reg, dst_reg;
  logic [31:0]           len_reg;
  logic [7:0]            max_beats_reg;
  logic                  irq_en_reg;
  logic                  done_sticky;
  logic                  err_sticky;
  dma_err_e              err_code_reg;

  // IRQ status
  logic                  irq_done_sticky;
  logic                  irq_err_sticky;

  // ---------------------------------------
  // AXI-Lite write address/data holding
  // ---------------------------------------
  logic                  aw_hold_valid;
  logic [ADDR_WIDTH-1:0] aw_hold_addr;

  logic                  w_hold_valid;
  logic [AXIL_DATA_WIDTH-1:0] w_hold_data;
  logic [STRB_W-1:0]          w_hold_strb;

  // Write response state
  logic bvalid_q;

  // Read response state
  logic                  rvalid_q;
  logic [AXIL_DATA_WIDTH-1:0] rdata_q;
  logic [ADDR_WIDTH-1:0]      ar_hold_addr;

  // ---------------------------------------
  // Apply WSTRB
  // ---------------------------------------
  function automatic [AXIL_DATA_WIDTH-1:0] apply_wstrb(
    input [AXIL_DATA_WIDTH-1:0] oldv,
    input [AXIL_DATA_WIDTH-1:0] newv,
    input [STRB_W-1:0]          strb
  );
    automatic logic [AXIL_DATA_WIDTH-1:0] tmp;
    int i;
    begin
      tmp = oldv;
      for (i = 0; i < STRB_W; i++) begin
        if (strb[i]) tmp[i*8 +: 8] = newv[i*8 +: 8];
      end
      apply_wstrb = tmp;
    end
  endfunction

  // ---------------------------------------
  // Outputs
  // ---------------------------------------
  assign src_addr  = src_reg;
  assign dst_addr  = dst_reg;
  assign len_bytes = len_reg;
  assign max_beats = max_beats_reg;
  assign irq_en    = irq_en_reg;

  wire irq_pending = irq_done_sticky || irq_err_sticky;
  assign irq_o = irq_en_reg && irq_pending;

  // ---------------------------------------
  // AXI-Lite constants
  // ---------------------------------------
  assign S_AXI_BRESP = AXI_RESP_OKAY;
  assign S_AXI_RRESP = AXI_RESP_OKAY;

  assign S_AXI_AWREADY = (!aw_hold_valid) && (!bvalid_q);
  assign S_AXI_WREADY  = (!w_hold_valid)  && (!bvalid_q);
  assign S_AXI_ARREADY = (!rvalid_q);

  assign S_AXI_BVALID = bvalid_q;
  assign S_AXI_RVALID = rvalid_q;
  assign S_AXI_RDATA  = rdata_q;

  // ---------------------------------------
  // Main sequential logic
  // ---------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      start_pulse    <= 1'b0;
      abort_pulse    <= 1'b0;
      soft_rst_pulse <= 1'b0;
      status_ack <= 1'b0;

      // Config regs
      src_reg       <= CSR_SRC_ADDR_RST[ADDR_WIDTH-1:0];
      dst_reg       <= CSR_DST_ADDR_RST[ADDR_WIDTH-1:0];
      len_reg       <= CSR_LEN_BYTES_RST;
      max_beats_reg <= CSR_BURST_CFG_RST[7:0];
      irq_en_reg    <= IRQ_ENABLE_DEFAULT;

      // Status
      done_sticky       <= 1'b0;
      err_sticky        <= 1'b0;
      err_code_reg      <= ERR_NONE;
      irq_done_sticky   <= 1'b0;
      irq_err_sticky    <= 1'b0;

      // AXI-Lite internals
      aw_hold_valid <= 1'b0;
      aw_hold_addr  <= '0;
      w_hold_valid  <= 1'b0;
      w_hold_data   <= '0;
      w_hold_strb   <= '0;
      bvalid_q      <= 1'b0;

      rvalid_q      <= 1'b0;
      rdata_q       <= '0;
      ar_hold_addr  <= '0;

    end else begin
      start_pulse    <= 1'b0;
      abort_pulse    <= 1'b0;
      soft_rst_pulse <= 1'b0;
      status_ack <= 1'b0;

      // --------------------------
      // Latch status from FSM
      // --------------------------
      if (core_done_pulse) begin
        done_sticky     <= 1'b1;
        irq_done_sticky <= 1'b1;
      end
      if (core_err_pulse) begin
        err_sticky      <= 1'b1;
        err_code_reg    <= core_err_code;
        irq_err_sticky  <= 1'b1;
      end

      // --------------------------
      // Capture AW
      // --------------------------
      if (S_AXI_AWVALID && S_AXI_AWREADY) begin
        aw_hold_valid <= 1'b1;
        aw_hold_addr  <= S_AXI_AWADDR;
      end

      // --------------------------
      // Capture W
      // --------------------------
      if (S_AXI_WVALID && S_AXI_WREADY) begin
        w_hold_valid <= 1'b1;
        w_hold_data  <= S_AXI_WDATA;
        w_hold_strb  <= S_AXI_WSTRB;
      end

      // --------------------------
      // Write
      // --------------------------
      if (aw_hold_valid && w_hold_valid && !bvalid_q) begin
        unique case (aw_hold_addr[7:0])

          CSR_CTRL_OFF: begin
            logic [AXIL_DATA_WIDTH-1:0] ctrl_shadow;
            logic [AXIL_DATA_WIDTH-1:0] ctrl_merged;

            ctrl_shadow = '0;
            ctrl_shadow[1] = irq_en_reg;

            ctrl_merged = apply_wstrb(ctrl_shadow, w_hold_data, w_hold_strb);

            if (w_hold_strb[0]) begin
              irq_en_reg <= ctrl_merged[1];

              if (ctrl_merged[2]) begin
                soft_rst_pulse <= 1'b1;

                done_sticky     <= 1'b0;
                err_sticky      <= 1'b0;
                err_code_reg    <= ERR_NONE;
                irq_done_sticky <= 1'b0;
                irq_err_sticky  <= 1'b0;

              end else if (ctrl_merged[3]) begin
                abort_pulse <= core_busy;

              end else if (ctrl_merged[0]) begin
                if (!core_busy) begin
                  start_pulse <= 1'b1;
                  done_sticky  <= 1'b0;
                  err_sticky   <= 1'b0;
                  err_code_reg <= ERR_NONE;
                end
              end
            end
          end

          CSR_SRC_ADDR_OFF: begin
            src_reg <= apply_wstrb(src_reg[AXIL_DATA_WIDTH-1:0], w_hold_data, w_hold_strb);
          end

          CSR_DST_ADDR_OFF: begin
            dst_reg <= apply_wstrb(dst_reg[AXIL_DATA_WIDTH-1:0], w_hold_data, w_hold_strb);
          end

          CSR_LEN_BYTES_OFF: begin
            len_reg <= apply_wstrb(len_reg, w_hold_data, w_hold_strb);
          end

          CSR_BURST_CFG_OFF: begin
            logic [AXIL_DATA_WIDTH-1:0] oldv, merged;
            oldv = '0;
            oldv[7:0] = max_beats_reg;
            merged = apply_wstrb(oldv, w_hold_data, w_hold_strb);
            max_beats_reg <= merged[7:0];
          end

          CSR_IRQ_STATUS_OFF: begin
            if (w_hold_strb[0]) begin
              if (w_hold_data[0]) irq_done_sticky <= 1'b0;
              if (w_hold_data[1]) irq_err_sticky  <= 1'b0;
            end
          end
          
         CSR_STATUS_OFF: begin
  	   if (w_hold_strb[0]) begin
             if (w_hold_data[1]) done_sticky <= 1'b0;
             if (w_hold_data[2]) begin
                err_sticky   <= 1'b0;
                err_code_reg <= ERR_NONE;
             end

             if (w_hold_data[1] || w_hold_data[2]) begin
                status_ack <= 1'b1; // pulso 1 ciclo para FSM voltar ao IDLE
             end
           end
         end

          default: begin
          end
        endcase

        aw_hold_valid <= 1'b0;
        w_hold_valid  <= 1'b0;
        bvalid_q      <= 1'b1;
      end

      // --------------------------
      // Write response handshake
      // --------------------------
      if (bvalid_q && S_AXI_BREADY) begin
        bvalid_q <= 1'b0;
      end

      // --------------------------
      // Read address capture 
      // --------------------------
      if (S_AXI_ARVALID && S_AXI_ARREADY) begin
        ar_hold_addr <= S_AXI_ARADDR;

        unique case (S_AXI_ARADDR[7:0])
          CSR_CTRL_OFF: begin
            rdata_q <= '0;
            rdata_q[1] <= irq_en_reg; // IRQ_EN
          end

          CSR_STATUS_OFF: begin
            rdata_q <= '0;
            rdata_q[0] <= core_busy;
            rdata_q[1] <= done_sticky;
            rdata_q[2] <= err_sticky;
          end

          CSR_SRC_ADDR_OFF: begin
            rdata_q <= '0;
            rdata_q[ADDR_WIDTH-1:0] <= src_reg;
          end

          CSR_DST_ADDR_OFF: begin
            rdata_q <= '0;
            rdata_q[ADDR_WIDTH-1:0] <= dst_reg;
          end

          CSR_LEN_BYTES_OFF: begin
            rdata_q <= len_reg;
          end

          CSR_BURST_CFG_OFF: begin
            rdata_q <= '0;
            rdata_q[7:0] <= max_beats_reg;
          end

          CSR_ERROR_CODE_OFF: begin
            rdata_q <= '0;
            rdata_q[2:0] <= err_code_reg;
          end

          CSR_IRQ_STATUS_OFF: begin
            rdata_q <= '0;
            rdata_q[0] <= irq_done_sticky;
            rdata_q[1] <= irq_err_sticky;
          end

          default: begin
            rdata_q <= '0;
          end
        endcase

        rvalid_q <= 1'b1;
      end

      // --------------------------
      // Read data handshake
      // --------------------------
      if (rvalid_q && S_AXI_RREADY) begin
        rvalid_q <= 1'b0;
      end
    end
  end

endmodule


