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
  reg [3:0]  rob_count;

  localparam ROB_SIZE = 16;  // Define ROB size

  reg[ 15:0] rob_valid;
  reg[ 15:0] rob_pending;
  reg [15:0] rob_spec; // <-- speculation bit
  reg[ 4:0] rob_physical_register [ 15:0];

  assign rob_commit_rf_waddr = rob_physical_register[rob_head];
  assign rob_commit_slot     = rob_head;

// allocation logic
  assign rob_alloc_req_rdy   = (rob_count != ROB_SIZE); // ROB is not full
  assign rob_alloc_resp_slot = rob_tail;

  // commit logic
  assign rob_commit_wen      = !rob_pending[rob_head]
                               && rob_valid[rob_head]
                               && !rob_spec[rob_head];

  integer i;
  always @(posedge clk) begin
    if (reset) begin
      rob_head    <= 4'b0;
      rob_tail    <= 4'b0;
      rob_count   <= 4'b0;    // Initialize ROB count
      rob_pending <= 16'b0;
      rob_valid   <= 16'b0;
      rob_spec    <= 16'd0;
    end else begin
      // 1) Branch resolution: on any branch resolution, clear or squash
      if (branch_resolve_val) begin
        // Always squash speculative entries *after* the branch
        for (i = 0; i < 16; i = i + 1) begin
          if (i > branch_resolve_slot && rob_spec[i]) begin
            rob_valid[i]   <= 1'b0;
            rob_pending[i] <= 1'b0;
            rob_spec[i]    <= 1'b0;
          end
        end
        // Clear speculation bit for the resolved branch *only if mispredicted*
        if (!branch_resolve_taken) begin
            rob_spec[branch_resolve_slot] <= 1'b0;
        end
      end

      // 2) Allocate a new entry
      if (rob_alloc_req_val && rob_alloc_req_rdy) begin
        rob_valid[rob_tail]            <= 1'b1;
        rob_pending[rob_tail]          <= 1'b1;
        rob_spec[rob_tail]             <= rob_alloc_req_spec;
        rob_physical_register[rob_tail]<= rob_alloc_req_preg;
        rob_tail                       <= rob_tail + 4'd1;
        rob_count                      <= rob_count + 4'd1;  // Increment ROB count
      end

      // 3) Mark an entry "finished" when its result arrives
      if (rob_fill_val && rob_valid[rob_fill_slot]) begin
        rob_pending[rob_fill_slot] <= 1'b0;
      end

      // 4) Commit the head of the ROB
      if (rob_commit_wen) begin
        rob_valid[rob_head] <= 1'b0;
        rob_head            <= rob_head + 4'd1;
        rob_count           <= rob_count - 4'd1;  // Decrement ROB count
      end
    end
  end

  `ifndef SYNTHESIS
  // Debug ROB state
  always @(posedge clk) begin
    if (branch_resolve_val) begin
      $display("ROB Branch Resolution: val=%b, taken=%b, slot=%d, head=%d, tail=%d", 
              branch_resolve_val, branch_resolve_taken, branch_resolve_slot, rob_head, rob_tail);
      $display("ROB Spec Bits: %b", rob_spec);
    end
  end

  // Debug ROB commit
  always @(posedge clk) begin
    if (rob_commit_wen) begin
      $display("ROB Commit: slot=%d, waddr=%d, head=%d, tail=%d",
              rob_commit_slot, rob_commit_rf_waddr, rob_head, rob_tail);
    end
  end

  // Debug ROB allocation
  always @(posedge clk) begin
    if (rob_alloc_req_val && rob_alloc_req_rdy) begin
      $display("ROB Allocation: slot=%d, spec=%b, head=%d, tail=%d",
              rob_alloc_resp_slot, rob_alloc_req_spec, rob_head, rob_tail);
    end
  end
  `endif

endmodule

`endif

