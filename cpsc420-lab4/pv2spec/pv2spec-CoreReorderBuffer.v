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
  input         rob_alloc_req_spec, // @anton-mel
  output wire   rob_alloc_req_rdy,
  input  [ 4:0] rob_alloc_req_preg,
  
  output wire [ 3:0] rob_alloc_resp_slot,

  input         rob_fill_val,
  input  [ 3:0] rob_fill_slot,

  // @anton-mel. -- branch resolution interface
  input            branch_resolve_val,       // high when a branch just resolved in X
  input   [3:0]    branch_resolve_slot,      // the ROB slot of that branch
  input            branch_resolve_taken,     // 1 if branch was taken, 0 if not

  output wire   rob_commit_wen,
  output wire [ 3:0] rob_commit_slot,
  output wire [ 4:0] rob_commit_rf_waddr
);

  reg[ 3:0]  rob_head;
  reg[ 3:0]  rob_tail;

  reg[ 15:0] rob_valid;
  reg[ 15:0] rob_pending;
  reg [15:0] rob_spec; // <-- speculation bit
  reg[ 4:0] rob_physical_register [ 15:0];

  // allocation logic
  assign rob_alloc_req_rdy   = (!rob_valid[rob_tail]);
  assign rob_alloc_resp_slot = rob_tail;

  // commit logic
  assign rob_commit_wen      = !rob_pending[rob_head]
                               && rob_valid[rob_head]
                               && !rob_spec[rob_head]; // <- updated
  assign rob_commit_rf_waddr = rob_physical_register[rob_head];
  assign rob_commit_slot     = rob_head;

  integer i;
  always @(posedge clk) begin
    if (reset) begin
      rob_head    <= 4'b0;
      rob_tail    <= 4'b0;
      rob_pending <= 16'b0;
      rob_valid   <= 16'b0;
      rob_spec    <= 16'd0;
    end else begin
      // 1) Branch resolution: on any branch resolution, clear or squash
      if (branch_resolve_val) begin
        if (branch_resolve_taken) begin
          // squash *all* speculative entries
          for (i = 0; i < 16; i = i + 1) begin
            if (rob_spec[i]) begin
              rob_valid[i]   <= 1'b0;
              rob_pending[i] <= 1'b0;
              rob_spec[i]    <= 1'b0;
            end
          end
        end else begin
          // mis-speculated? No: just clear speculation flags
          rob_spec <= 16'd0;
        end
      end

      // 2) Allocate a new entry
      if (rob_alloc_req_val && rob_alloc_req_rdy) begin
        rob_valid[rob_tail]            <= 1'b1;
        rob_pending[rob_tail]          <= 1'b1;
        rob_spec[rob_tail]             <= rob_alloc_req_spec;
        rob_physical_register[rob_tail]<= rob_alloc_req_preg;
        rob_tail                       <= rob_tail + 4'd1;
      end

      // 3) Mark an entry “finished” when its result arrives
      if (rob_fill_val && rob_valid[rob_fill_slot]) begin
        rob_pending[rob_fill_slot] <= 1'b0;
      end

      // 4) Commit the head of the ROB
      if (rob_commit_wen) begin
        rob_valid[rob_head] <= 1'b0;
        rob_head            <= rob_head + 4'd1;
      end
    end
  end

endmodule

`endif

