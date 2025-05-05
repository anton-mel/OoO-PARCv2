//=========================================================================
// 5-Stage PARC Scoreboard
//=========================================================================

`ifndef PARC_CORE_REORDERBUFFER_V
`define PARC_CORE_REORDERBUFFER_V

module parc_CoreReorderBuffer
(
  input         clk,
  input         reset,

  input         rob_alloc_req_val,
  output wire   rob_alloc_req_rdy,
  input  [ 4:0] rob_alloc_req_preg,
  input         rob_alloc_req_spec,

  input  [ 3:0] rob_spec_resolve_slot,
  input  [ 1:0] rob_spec_resolve_result,
  
  output wire [ 3:0] rob_alloc_resp_slot,

  input         rob_fill_val,
  input  [ 3:0] rob_fill_slot,

  output wire   rob_commit_wen,
  output wire [ 3:0] rob_commit_slot,
  output wire [ 4:0] rob_commit_rf_waddr
);

  reg[ 3:0]  rob_head;
  reg[ 3:0]  rob_tail;

  reg[ 15:0] rob_valid;
  reg[ 15:0] rob_pending;
  reg[ 4:0] rob_physical_register [ 15:0];
  reg[ 15:0] rob_spec;

  // allocation logic
  assign rob_alloc_req_rdy   = (!rob_valid[rob_tail]);
  assign rob_alloc_resp_slot = rob_tail;

  // commit logic
  assign rob_commit_wen      = !rob_pending[rob_head] && rob_valid[rob_head] && !rob_spec[rob_head];
  assign rob_commit_rf_waddr = rob_physical_register[rob_head];
  assign rob_commit_slot     = rob_head;

  always @(posedge clk) begin
    if (reset) begin
      rob_head <= 4'b0;
      rob_tail <= 4'b0;

      rob_valid <= 16'b0;
      rob_spec <= 16'b0;
    end else begin
      if (rob_alloc_req_val && rob_alloc_req_rdy) begin
        rob_valid[rob_tail] <= 1'b1;
        rob_pending[rob_tail] <= 1'b1;
        rob_physical_register[rob_tail] <= rob_alloc_req_preg;
        rob_spec[rob_tail] <= rob_alloc_req_spec;
        rob_tail <= rob_tail + 1;
      end
      if (rob_spec_resolve_result[0] && rob_valid[rob_spec_resolve_slot]) begin
        rob_spec[rob_spec_resolve_slot] <= 1'b0;
        rob_valid[rob_spec_resolve_slot] <= rob_spec_resolve_result[1];
      end
      if (rob_fill_val && rob_valid[rob_fill_slot]) begin
        rob_pending[rob_fill_slot] <= 1'b0;
      end
      if ((!rob_pending[rob_head] && rob_valid[rob_head] && !rob_spec[rob_head]) || ((rob_head != rob_tail) && !rob_valid[rob_head])) begin
        rob_valid[rob_head] <= 1'b0;
        rob_head <= rob_head + 1;
      end
    end
  end






// `ifndef SYNTHESIS
//   // Debug ROB branch resolution (using rob_spec_resolve signals)
//   always @(posedge clk) begin
//     if (rob_spec_resolve_result != 2'b0) begin
//       $display("ROB Spec Resolution: result=%b, slot=%d, head=%d, tail=%d", 
//                rob_spec_resolve_result, rob_spec_resolve_slot, rob_head, rob_tail);
//       $display("ROB Spec Bits After Resolve: %b", rob_spec);
//     end
//   end

//   // Debug ROB commit
//   always @(posedge clk) begin
//     if (rob_commit_wen) begin
//       $display("ROB Commit: slot=%d, waddr=%d, head=%d, tail=%d",
//                rob_commit_slot, rob_commit_rf_waddr, rob_head, rob_tail);
//     end
//   end

//   // Debug ROB allocation
//   always @(posedge clk) begin
//     if (rob_alloc_req_val && rob_alloc_req_rdy) begin
//       $display("ROB Allocation: slot=%d, spec=%b, head=%d, tail=%d",
//                rob_alloc_resp_slot, rob_alloc_req_spec, rob_head, rob_tail);
//     end
//   end
// `endif

endmodule

`endif

