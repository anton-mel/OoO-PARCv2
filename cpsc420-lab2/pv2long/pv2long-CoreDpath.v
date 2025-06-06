//=========================================================================
// 5-Stage PARCv2 Datapath
//=========================================================================

`ifndef PARC_CORE_DPATH_V
`define PARC_CORE_DPATH_V

`include "pv2long-CoreDpathPipeMulDiv.v"
`include "pv2long-InstMsg.v"
`include "pv2long-CoreDpathAlu.v"
`include "pv2long-CoreDpathRegfile.v"

module parc_CoreDpath
(
  input clk,
  input reset,

  // Instruction Memory Port

  output [31:0] imemreq_msg_addr,

  // Data Memory Port

  output [31:0] dmemreq_msg_addr,
  output [31:0] dmemreq_msg_data,
  input  [31:0] dmemresp_msg_data,

  // Controls Signals (ctrl->dpath)

  input   [1:0] pc_mux_sel_Phl,
  input   [1:0] op0_mux_sel_Dhl,
  input   [2:0] op1_mux_sel_Dhl,
  input  [31:0] inst_Dhl,
  input   [3:0] alu_fn_Xhl,
  input   [2:0] muldivreq_msg_fn_Dhl,
  input         muldivreq_val,
  output        muldivreq_rdy,
  output        muldivresp_val,
  input         muldivresp_rdy,
  input         muldiv_mux_sel_PWhl,
  // input         execute_mux_sel_Xhl,
  input   [2:0] dmemresp_mux_sel_Mhl,
  input         dmemresp_queue_en_Mhl,
  input         dmemresp_queue_val_Mhl,
  input         execute_mux_sel_PWhl,
  input         wb_mux_sel_Mhl,
  input         rf_wen_Whl,
  input  [ 4:0] rf_waddr_Whl,
  input         stall_Fhl,
  input         stall_Dhl,
  input         stall_Xhl,
  input         stall_Mhl,
  input         stall_PMhl,
  input         stall_PWhl,
  input         stall_Whl,

  // Bypass Control Signals

  input   [2:0] op0_byp_mux_sel_Dhl,  // Bypass mux select for op0
  input   [2:0] op1_byp_mux_sel_Dhl,  // Bypass mux select for op1

  // Control Signals (dpath->ctrl)

  output        branch_cond_eq_Xhl,
  output        branch_cond_zero_Xhl,
  output        branch_cond_neg_Xhl,
  output [31:0] proc2cop_data_Whl
);

  //--------------------------------------------------------------------
  // Bypass Muxes
  //--------------------------------------------------------------------

  // Bypass values from X, M, and W stages
  wire [31:0] rs_byp_X_Dhl = alu_out_Xhl;  // @anton-mel: update wire. Bypass value for rs from X stage
  wire [31:0] rs_byp_M_Dhl = pm_mux_out_Mhl;  // @anton-mel: update wire. Bypass value for rs from M stage
  wire [31:0] rs_byp_W_Dhl = wb_mux_out_Whl;  // @anton-mel: update wire. Bypass value for rs from W stage

  wire [31:0] rt_byp_X_Dhl = alu_out_Xhl;  // @anton-mel: update-wire. Bypass value for rt from X stage
  wire [31:0] rt_byp_M_Dhl = pm_mux_out_Mhl;  // @anton-mel: update wire. Bypass value for rt from M stage
  wire [31:0] rt_byp_W_Dhl = wb_mux_out_Whl;  // @anton-mel: update wire. Bypass value for rt from W stage

  // @anton-mel: Add new bypass paths (PM & PW)
  wire [31:0] rs_byp_PW_Dhl = execute_mux_out_PWhl; // rs (PM) op0 & op1
  wire [31:0] rs_byp_PM_Dhl = execute_out_PMhl;
  wire [31:0] rt_byp_PW_Dhl = execute_mux_out_PWhl; // rt (PW) op0 & op1
  wire [31:0] rt_byp_PM_Dhl = execute_out_PMhl;
  // ******************************************

  // @anton-mel: update the bypassing
  // Bypass mux for op0 (rs)
  wire [31:0] op0_byp_mux_out_Dhl
    = ( op0_byp_mux_sel_Dhl == 3'b001 ) ? rs_byp_X_Dhl
    : ( op0_byp_mux_sel_Dhl == 3'b010 ) ? rs_byp_M_Dhl
    : ( op0_byp_mux_sel_Dhl == 3'b011 ) ? rs_byp_PM_Dhl
    : ( op0_byp_mux_sel_Dhl == 3'b100 ) ? rs_byp_PW_Dhl
    : ( op0_byp_mux_sel_Dhl == 3'b101 ) ? rs_byp_W_Dhl
    : rf_rdata0_Dhl;
  // ********************************

  // @anton-mel: update the bypassing
  // Bypass mux for op1 (rt)
  wire [31:0] op1_byp_mux_out_Dhl
    = ( op1_byp_mux_sel_Dhl == 3'b001 ) ? rt_byp_X_Dhl
    : ( op1_byp_mux_sel_Dhl == 3'b010 ) ? rt_byp_M_Dhl
    : ( op1_byp_mux_sel_Dhl == 3'b011 ) ? rt_byp_PM_Dhl
    : ( op1_byp_mux_sel_Dhl == 3'b100 ) ? rt_byp_PW_Dhl
    : ( op1_byp_mux_sel_Dhl == 3'b101 ) ? rt_byp_W_Dhl
    : rf_rdata1_Dhl;
  // ********************************

  //--------------------------------------------------------------------
  // PC Logic Stage
  //--------------------------------------------------------------------

  // PC mux

  wire [31:0] pc_plus4_Phl;
  wire [31:0] branch_targ_Phl;
  wire [31:0] jump_targ_Phl;
  wire [31:0] jumpreg_targ_Phl;
  wire [31:0] pc_mux_out_Phl;

  wire [31:0] reset_vector = 32'h00080000;

  // Pull mux inputs from later stages

  assign pc_plus4_Phl       = pc_plus4_Fhl;
  assign branch_targ_Phl    = branch_targ_Xhl;
  assign jump_targ_Phl      = jump_targ_Dhl;
  assign jumpreg_targ_Phl   = jumpreg_targ_Dhl;

  assign pc_mux_out_Phl
    = ( pc_mux_sel_Phl == 2'd0 ) ? pc_plus4_Phl
    : ( pc_mux_sel_Phl == 2'd1 ) ? branch_targ_Phl
    : ( pc_mux_sel_Phl == 2'd2 ) ? jump_targ_Phl
    : ( pc_mux_sel_Phl == 2'd3 ) ? jumpreg_targ_Phl
    :                              32'bx;

  // Send out imem request early

  assign imemreq_msg_addr
    = ( reset ) ? reset_vector
    :             pc_mux_out_Phl;

  //----------------------------------------------------------------------
  // F <- P
  //----------------------------------------------------------------------

  reg  [31:0] pc_Fhl;

  always @ (posedge clk) begin
    if( reset ) begin
      pc_Fhl <= reset_vector;
    end
    else if( !stall_Fhl ) begin
      pc_Fhl <= pc_mux_out_Phl;
    end
  end

  //--------------------------------------------------------------------
  // Fetch Stage
  //--------------------------------------------------------------------

  // PC incrementer

  wire [31:0] pc_plus4_Fhl;

  assign pc_plus4_Fhl = pc_Fhl + 32'd4;

  //----------------------------------------------------------------------
  // D <- F
  //----------------------------------------------------------------------

  reg [31:0] pc_Dhl;
  reg [31:0] pc_plus4_Dhl;

  always @ (posedge clk) begin
    if( !stall_Dhl ) begin
      pc_Dhl       <= pc_Fhl;
      pc_plus4_Dhl <= pc_plus4_Fhl;
    end
  end

  //--------------------------------------------------------------------
  // Decode Stage (Register Read)
  //--------------------------------------------------------------------

  // Parse instruction fields

  wire   [4:0] inst_rs_Dhl;
  wire   [4:0] inst_rt_Dhl;
  wire   [4:0] inst_rd_Dhl;
  wire   [4:0] inst_shamt_Dhl;
  wire  [15:0] inst_imm_Dhl;
  wire         inst_imm_sign_Dhl;
  wire  [25:0] inst_target_Dhl;

  // Branch and jump address generation

  wire [31:0] branch_targ_Dhl;
  wire [31:0] jump_targ_Dhl;

  assign branch_targ_Dhl = pc_plus4_Dhl + (imm_sext_Dhl << 2);
  assign jump_targ_Dhl   = { pc_plus4_Dhl[31:28], inst_target_Dhl, 2'b0 };

  // Register file

  wire [ 4:0] rf_raddr0_Dhl = inst_rs_Dhl;
  wire [31:0] rf_rdata0_Dhl;
  wire [ 4:0] rf_raddr1_Dhl = inst_rt_Dhl;
  wire [31:0] rf_rdata1_Dhl;

  // Jump reg address

  wire [31:0] jumpreg_targ_Dhl;

  assign jumpreg_targ_Dhl  = op0_byp_mux_out_Dhl;

  // Zero and sign extension immediate

  wire [31:0] imm_sext_Dhl = { {16{inst_imm_sign_Dhl}}, inst_imm_Dhl };
  wire [31:0] imm_zext_Dhl = { 16'b0, inst_imm_Dhl };

  // Shift amount immediate

  wire [31:0] shamt_Dhl = { 27'b0, inst_shamt_Dhl };

  // Constant operand mux inputs

  wire [31:0] const0    = 32'd0;
  wire [31:0] const16   = 32'd16;

  // Operand 0 mux

  wire [31:0] op0_mux_out_Dhl
    = ( op0_mux_sel_Dhl == 2'd0 ) ? op0_byp_mux_out_Dhl // Use bypassed value
    : ( op0_mux_sel_Dhl == 2'd1 ) ? shamt_Dhl
    : ( op0_mux_sel_Dhl == 2'd2 ) ? const16
    : ( op0_mux_sel_Dhl == 2'd3 ) ? const0
    :                               32'bx;

  // Operand 1 mux

  wire [31:0] op1_mux_out_Dhl
    = ( op1_mux_sel_Dhl == 3'd0 ) ? op1_byp_mux_out_Dhl // Use bypassed value
    : ( op1_mux_sel_Dhl == 3'd1 ) ? imm_zext_Dhl
    : ( op1_mux_sel_Dhl == 3'd2 ) ? imm_sext_Dhl
    : ( op1_mux_sel_Dhl == 3'd3 ) ? pc_plus4_Dhl
    : ( op1_mux_sel_Dhl == 3'd4 ) ? const0
    :                               32'bx;

  // wdata with bypassing

  wire [31:0] wdata_Dhl = op1_byp_mux_out_Dhl;

  //----------------------------------------------------------------------
  // X <- D
  //----------------------------------------------------------------------

  reg [31:0] pc_Xhl;
  reg [31:0] branch_targ_Xhl;
  reg [31:0] op0_mux_out_Xhl;
  reg [31:0] op1_mux_out_Xhl;
  reg [31:0] wdata_Xhl;

  always @ (posedge clk) begin
    if( !stall_Xhl ) begin
      pc_Xhl          <= pc_Dhl;
      branch_targ_Xhl <= branch_targ_Dhl;
      op0_mux_out_Xhl <= op0_mux_out_Dhl;
      op1_mux_out_Xhl <= op1_mux_out_Dhl;
      wdata_Xhl       <= wdata_Dhl;
    end
  end

  //----------------------------------------------------------------------
  // Execute Stage
  //----------------------------------------------------------------------

  // ALU

  wire [31:0] alu_out_Xhl;

  // Branch condition logic

  assign branch_cond_eq_Xhl    = ( alu_out_Xhl == 32'd0 );
  assign branch_cond_zero_Xhl  = ( op0_mux_out_Xhl == 32'd0 );
  assign branch_cond_neg_Xhl   = ( op0_mux_out_Xhl[31] == 1'b1 );

  // Send out memory request during X, response returns in M

  assign dmemreq_msg_addr = alu_out_Xhl;
  assign dmemreq_msg_data = wdata_Xhl;

  // Muldiv Unit

  // wire [63:0] muldivresp_msg_result_Xhl;

  // @anton-mel: NO RESULT HANDLING HERE, PW STAGE
  // // Muldiv Result Mux 
  // wire [31:0] muldiv_mux_out_Xhl
  //   = ( muldiv_mux_sel_Xhl == 1'd0 ) ? muldivresp_msg_result_Xhl[31:0]
  //   : ( muldiv_mux_sel_Xhl == 1'd1 ) ? muldivresp_msg_result_Xhl[63:32]
  //   :                                  32'bx;
  // *********************************************

  // @anton-mel: THEREFORE, NO MUX AS WELL, PW STAGE
  // // Execute Result Mux
  // wire [31:0] execute_mux_out_Xhl
  //   = ( execute_mux_sel_Xhl == 1'd0 ) ? alu_out_Xhl
  //   : ( execute_mux_sel_Xhl == 1'd1 ) ? muldiv_mux_out_Xhl
  //   :                                   32'bx;
  // ***********************************************

  // USED OUTPUT: alu_out_Xhl

  //----------------------------------------------------------------------
  // M <- X
  //----------------------------------------------------------------------

  reg  [31:0] pc_Mhl;
  reg  [31:0] execute_mux_out_Mhl;
  reg  [31:0] wdata_Mhl;

  always @ (posedge clk) begin
    if( !stall_Mhl ) begin
      pc_Mhl              <= pc_Xhl;
      // @anton-mel: propagate correct output
      execute_mux_out_Mhl <= alu_out_Xhl;
      // execute_mux_out_Mhl <= execute_mux_out_Xhl;
      // ************************************
      wdata_Mhl           <= wdata_Xhl;
    end
  end

  //----------------------------------------------------------------------
  // Memory Stage
  //----------------------------------------------------------------------

  // Data memory subword adjustment mux

  wire [31:0] dmemresp_lb_Mhl
    = { {24{dmemresp_msg_data[7]}}, dmemresp_msg_data[7:0] };

  wire [31:0] dmemresp_lbu_Mhl
    = { {24{1'b0}}, dmemresp_msg_data[7:0] };

  wire [31:0] dmemresp_lh_Mhl
    = { {16{dmemresp_msg_data[15]}}, dmemresp_msg_data[15:0] };

  wire [31:0] dmemresp_lhu_Mhl
    = { {16{1'b0}}, dmemresp_msg_data[15:0] };

  wire [31:0] dmemresp_mux_out_Mhl
    = ( dmemresp_mux_sel_Mhl == 3'd0 ) ? dmemresp_msg_data
    : ( dmemresp_mux_sel_Mhl == 3'd1 ) ? dmemresp_lb_Mhl
    : ( dmemresp_mux_sel_Mhl == 3'd2 ) ? dmemresp_lbu_Mhl
    : ( dmemresp_mux_sel_Mhl == 3'd3 ) ? dmemresp_lh_Mhl
    : ( dmemresp_mux_sel_Mhl == 3'd4 ) ? dmemresp_lhu_Mhl
    :                                    32'bx;

  //----------------------------------------------------------------------
  // Queue for data memory response
  //----------------------------------------------------------------------

  reg [31:0] dmemresp_queue_reg_Mhl;

  always @ ( posedge clk ) begin
    if ( dmemresp_queue_en_Mhl ) begin
      dmemresp_queue_reg_Mhl <= dmemresp_mux_out_Mhl;
    end
  end

  //----------------------------------------------------------------------
  // Data memory queue mux
  //----------------------------------------------------------------------

  wire [31:0] dmemresp_queue_mux_out_Mhl
    = ( !dmemresp_queue_val_Mhl ) ? dmemresp_mux_out_Mhl
    : ( dmemresp_queue_val_Mhl )  ? dmemresp_queue_reg_Mhl
    :                               32'bx;

  // @anton-mel: MUX is still needed, but another one (naming issue)
  // //----------------------------------------------------------------------
  // // Writeback mux
  // //----------------------------------------------------------------------
  // wire [31:0] wb_mux_out_Mhl
  //   = ( wb_mux_sel_Mhl == 1'd0 ) ? execute_mux_out_Mhl
  //   : ( wb_mux_sel_Mhl == 1'd1 ) ? dmemresp_queue_mux_out_Mhl
  //   :                              32'bx;
  // *************************************************

  // @anton-mel: New MUX for subword, Writeback will be handled for imuldiv
  //----------------------------------------------------------------------
  // Post-Memory mux
  //----------------------------------------------------------------------
  wire [31:0] pm_mux_out_Mhl
    = ( wb_mux_sel_Mhl == 1'd0 ) ? execute_mux_out_Mhl
    : ( wb_mux_sel_Mhl == 1'd1 ) ? dmemresp_queue_mux_out_Mhl
    :                                   32'bx;
  // **********************************************************************

  // USED OUTPUT: pm_mux_out_Mhl

  // @anton-mel: New stages added *****************************************
  // **********************************************************************
  // **********************************************************************

  //----------------------------------------------------------------------
  // @anton-mel: PM <- M (dummy)
  //----------------------------------------------------------------------

  reg  [31:0] pc_PMhl;
  reg  [31:0] execute_out_PMhl;
  reg  [31:0] wdata_PMhl;

  always @ (posedge clk) begin
    if( !stall_PMhl ) begin
      pc_PMhl             <= pc_Mhl;
      execute_out_PMhl    <= pm_mux_out_Mhl;
    end
  end

  // USED OUTPUT: execute_out_PMhl

  //----------------------------------------------------------------------
  // @anton-mel: PW <- PM (dummy)
  //----------------------------------------------------------------------

  reg  [31:0] pc_PWhl;
  reg  [31:0] execute_out_PWhl;
  reg  [31:0] wdata_PWhl;

  always @ (posedge clk) begin
    if( !stall_PWhl ) begin
      pc_PWhl           <= pc_PMhl;
      execute_out_PWhl  <= execute_out_PMhl;
    end
  end

  // USED OUTPUT: execute_out_PWhl

  //----------------------------------------------------------------------
  // Pre-Writeback Stage (MulDiv - Shifted from Execute)
  //----------------------------------------------------------------------

  wire [63:0] muldivresp_msg_result_PWhl;

  // Muldiv Result Mux 
  wire [31:0] muldiv_mux_out_PWhl
    = ( muldiv_mux_sel_PWhl == 1'd0 ) ? muldivresp_msg_result_PWhl[31:0]
    : ( muldiv_mux_sel_PWhl == 1'd1 ) ? muldivresp_msg_result_PWhl[63:32]
    :                                   32'bx;

  // Execute Result Mux
  wire [31:0] execute_mux_out_PWhl
    = ( execute_mux_sel_PWhl == 1'd0 ) ? execute_out_PWhl
    : ( execute_mux_sel_PWhl == 1'd1 ) ? muldiv_mux_out_PWhl
    :                               32'bx;

  // **********************************************************************
  // **********************************************************************
  // **********************************************************************

  // USED OUTPUT: execute_mux_out_PWhl

  //----------------------------------------------------------------------
  // W <- PW
  //----------------------------------------------------------------------

  reg  [31:0] pc_Whl;
  reg  [31:0] wb_mux_out_Whl;

  always @ (posedge clk) begin
    if( !stall_Whl ) begin
      // @anton-mel: Connect the Pre-Writeback with Writeback
      // pc_Whl                 <= pc_Mhl;
      // wb_mux_out_Whl         <= wb_mux_out_Mhl;
      pc_Whl                 <= pc_PWhl;
      wb_mux_out_Whl         <= execute_mux_out_PWhl;
      // ****************************************************
    end
  end

  // USED OUTPUT: wb_mux_out_Whl

  //----------------------------------------------------------------------
  // Writeback Stage
  //----------------------------------------------------------------------

  // CP0 write data

  assign proc2cop_data_Whl = wb_mux_out_Whl;

  //----------------------------------------------------------------------
  // Debug registers for instruction disassembly
  //----------------------------------------------------------------------

  reg [31:0] pc_debug;

  always @ ( posedge clk ) begin
    pc_debug <= pc_Whl;
  end

  //----------------------------------------------------------------------
  // Submodules
  //----------------------------------------------------------------------

  // Address Generation 

  parc_InstMsgFromBits inst_msg_from_bits
  (
    .msg      (inst_Dhl),
    .opcode   (),
    .rs       (inst_rs_Dhl),
    .rt       (inst_rt_Dhl),
    .rd       (inst_rd_Dhl),
    .shamt    (inst_shamt_Dhl),
    .func     (),
    .imm      (inst_imm_Dhl),
    .imm_sign (inst_imm_sign_Dhl),
    .target   (inst_target_Dhl)
  );

  // Register File

  parc_CoreDpathRegfile rfile
  (
    .clk     (clk),
    .raddr0  (rf_raddr0_Dhl),
    .rdata0  (rf_rdata0_Dhl),
    .raddr1  (rf_raddr1_Dhl),
    .rdata1  (rf_rdata1_Dhl),
    .wen_p   (rf_wen_Whl),
    .waddr_p (rf_waddr_Whl),
    .wdata_p (wb_mux_out_Whl)
  );

  // ALU

  parc_CoreDpathAlu alu
  (
    .in0  (op0_mux_out_Xhl),
    .in1  (op1_mux_out_Xhl),
    .fn   (alu_fn_Xhl),
    .out  (alu_out_Xhl)
  );

  // Multiplier/Divider

  parc_CoreDpathPipeMulDiv imuldiv
  (
    .clk                   (clk),
    .reset                 (reset),
    // @anton-mel: move to the decode stage
    .muldivreq_msg_fn      (muldivreq_msg_fn_Dhl),
    .muldivreq_msg_a       (op0_mux_out_Dhl),
    .muldivreq_msg_b       (op1_mux_out_Dhl),
    // ************************************
    .muldivreq_val         (muldivreq_val),
    .muldivreq_rdy         (muldivreq_rdy),
    // @anton-mel: move to the pre-writeback stage
    .muldivresp_msg_result (muldivresp_msg_result_PWhl),
    // *******************************************
    .muldivresp_val        (muldivresp_val),
    .muldivresp_rdy        (muldivresp_rdy)
  );

endmodule

`endif

