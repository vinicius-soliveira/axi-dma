module dma_ctrl_sva (
  input logic ACLK,
  input logic ARESETn,

  input logic start_pulse,
  input logic busy,
  input logic done,
  input logic error,

  input logic [31:0] src_addr,
  input logic [31:0] dst_addr,
  input logic [31:0] len_bytes
);

  property p_done_error_mutex;
    @(posedge ACLK) disable iff (!ARESETn)
      !(done && error);
  endproperty

  property p_start_sets_busy;
    @(posedge ACLK) disable iff (!ARESETn)
      start_pulse |=> busy;
  endproperty

  property p_start_eventually_finishes;
    @(posedge ACLK) disable iff (!ARESETn)
      start_pulse |-> ##[1:5000] (done || error);
  endproperty

  property p_done_has_activity_context;
    @(posedge ACLK) disable iff (!ARESETn)
      done |-> (busy || $past(busy,1) || $past(busy,2));
  endproperty

  property p_error_has_activity_context;
    @(posedge ACLK) disable iff (!ARESETn)
      error |-> (busy || $past(busy,1) || $past(busy,2));
  endproperty

  property p_finish_clears_busy;
    @(posedge ACLK) disable iff (!ARESETn)
      (done || error) |=> !busy;
  endproperty

  property p_len_aligned_on_start;
    @(posedge ACLK) disable iff (!ARESETn)
      start_pulse |-> (len_bytes[1:0] == 2'b00);
  endproperty

  property p_addr_aligned_on_start;
    @(posedge ACLK) disable iff (!ARESETn)
      start_pulse |-> (src_addr[1:0] == 2'b00 && dst_addr[1:0] == 2'b00);
  endproperty

  property p_len_nonzero_on_start;
    @(posedge ACLK) disable iff (!ARESETn)
      start_pulse |-> (len_bytes != 32'd0);
  endproperty
  
  property p_start_only_when_idle;
    @(posedge ACLK) disable iff (!ARESETn)
    start_pulse |-> !busy;
  endproperty

  assert property (p_done_error_mutex)
    else $error("DMA_CTRL_SVA: done and error asserted simultaneously");

  assert property (p_start_sets_busy)
    else $error("DMA_CTRL_SVA: busy did not assert after start");

  assert property (p_start_eventually_finishes)
    else $error("DMA_CTRL_SVA: DMA did not finish within expected window");

  assert property (p_done_has_activity_context)
    else $error("DMA_CTRL_SVA: done asserted without prior busy context");

  assert property (p_error_has_activity_context)
    else $error("DMA_CTRL_SVA: error asserted without prior busy context");

  assert property (p_finish_clears_busy)
    else $error("DMA_CTRL_SVA: busy did not clear after done/error");

  assert property (p_len_aligned_on_start)
    else $error("DMA_CTRL_SVA: len_bytes not word aligned on start");

  assert property (p_addr_aligned_on_start)
    else $error("DMA_CTRL_SVA: src/dst address not word aligned on start");

  assert property (p_len_nonzero_on_start)
    else $error("DMA_CTRL_SVA: zero-length transfer started");
    
  assert property (p_start_only_when_idle)
  else $error("DMA_CTRL_SVA: start asserted while busy");

  cover property (@(posedge ACLK) disable iff (!ARESETn)
    start_pulse ##[1:5000] done);

  cover property (@(posedge ACLK) disable iff (!ARESETn)
    start_pulse ##[1:5000] error);

endmodule