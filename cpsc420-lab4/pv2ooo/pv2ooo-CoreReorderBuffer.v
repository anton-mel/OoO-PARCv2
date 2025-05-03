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

  // allocation logic
  assign rob_alloc_req_rdy   = (!rob_valid[rob_tail]);
  assign rob_alloc_resp_slot = rob_tail;

  // commit logic
  assign rob_commit_wen      = !rob_pending[rob_head] && rob_valid[rob_head];
  assign rob_commit_rf_waddr = rob_physical_register[rob_head];
  assign rob_commit_slot     = rob_head;

  always @(posedge clk) begin
    if (reset) begin
      rob_head = 4'b0;
      rob_tail = 4'b0;

      rob_valid = 16'b0;
    end else begin
      if (rob_alloc_req_val && rob_alloc_req_rdy) begin
        rob_valid[rob_tail] <= 1'b1;
        rob_pending[rob_tail] <= 1'b1;
        rob_physical_register[rob_tail] <= rob_alloc_req_preg;
        rob_tail <= rob_tail + 1;
      end
      if (rob_fill_val && rob_valid[rob_fill_slot]) begin
        rob_pending[rob_fill_slot] <= 1'b0;
      end
      if (rob_commit_wen) begin
        rob_valid[rob_head] <= 1'b0;
        rob_head <= rob_head + 1;
      end
    end
  end

endmodule

`endif

