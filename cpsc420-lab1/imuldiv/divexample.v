//========================================================================
// Lab 1 - Iterative Div Unit
//========================================================================

`ifndef PARC_INT_DIV_ITERATIVE_V
`define PARC_INT_DIV_ITERATIVE_V

`include "imuldiv-DivReqMsg.v"

module imuldiv_IntDivIterative
(

  input         clk,
  input         reset,

  input         divreq_msg_fn,
  input  [31:0] divreq_msg_a,
  input  [31:0] divreq_msg_b,
  input         divreq_val,
  output        divreq_rdy,

  output [63:0] divresp_msg_result,
  output        divresp_val,
  output [64:0] sub_out,
  input         divresp_rdy
);

  // Control Signals
  wire a_mux_sel;
  wire div_sign;
  wire rem_sign;
  wire sign_en;
  wire is_op_signed;
  wire a_en;
  wire b_en;
  wire rem_sign_mux_sel;
  wire div_sign_mux_sel;
  wire sub_mux_sel;
  wire [64:0] sub_out;

  imuldiv_IntDivIterativeDpath dpath
  (
    .clk                (clk),
    .reset              (reset),
    .divreq_msg_fn      (divreq_msg_fn),
    .divreq_msg_a       (divreq_msg_a),
    .divreq_msg_b       (divreq_msg_b),
    .divresp_msg_result (divresp_msg_result),
    .divreq_val         (divreq_val),
    .divresp_rdy        (divresp_rdy),
    .a_mux_sel          (a_mux_sel),
    .rem_sign_mux_sel   (rem_sign_mux_sel),
    .div_sign_mux_sel   (div_sign_mux_sel),
    .sub_mux_sel        (sub_mux_sel),
    .sub_out            (sub_out),
    .a_en               (a_en),
    .b_en               (b_en)
  );

  imuldiv_IntDivIterativeCtrl ctrl
  (
    .clk                (clk),
    .reset              (reset),
    .divreq_val         (divreq_val),
    .divreq_rdy         (divreq_rdy),
    .divresp_val        (divresp_val),
    .divresp_rdy        (divresp_rdy),
    .sub_mux_sel        (sub_mux_sel),
    .a_mux_sel          (a_mux_sel),
    .sub_out            (sub_out),
    .a_en               (a_en),
    .b_en               (b_en)
  );

endmodule

//------------------------------------------------------------------------
// Datapath
//------------------------------------------------------------------------

module imuldiv_IntDivIterativeDpath
(
  input         clk,
  input         reset,
  // assign divreq_rdy  = divresp_rdy;
  // assign divresp_val = val_reg;
  input         divresp_rdy,
  input         divreq_val,

  input  [31:0] divreq_msg_a,       // Operand A
  input  [31:0] divreq_msg_b,       // Operand B
  input         divreq_msg_fn,

  input         a_mux_sel,
  input         sub_mux_sel,
  input         rem_sign_mux_sel,
  input         div_sign_mux_sel,

  input         a_en,
  input         b_en,

  output [64:0] sub_out,
  output [63:0] divresp_msg_result  // Result of operation
);

  reg         fn_reg;      // Register for storing function
  reg  [64:0] a_reg;       // Register for storing operand A
  reg  [64:0] b_reg;       // Register for storing operand B
  reg         val_reg;     // Register for storing valid bit

  wire [64:0] a_mux;       // Wire for sending A MUX
  wire [64:0] b_mux;       // Wire for sending B MUX
  wire [64:0] a_shift_out;
  wire [64:0] sub_mux_out;

  wire [31:0] singed_res_rem_mux_out, singed_res_div_mux_out;

  always @( posedge clk ) begin
    // Stall the pipeline if the 
    // response interface is not ready
    if ( divresp_rdy ) begin
      fn_reg  <= divreq_msg_fn;
      val_reg <= divreq_val;
    end
  end

  //----------------------------------------------------------------------
  // Combinational Logic
  //----------------------------------------------------------------------

  // Extract sign bits
  wire sign_bit_a = divreq_msg_a[31];
  wire sign_bit_b = divreq_msg_a[31];
  // Unsign operands if necessary
  wire [31:0] unsigned_a = ( sign_bit_a ) ? (~divreq_msg_a[31:0] + 1'b1) : divreq_msg_a[31:0];
  wire [31:0] unsigned_b = ( sign_bit_b ) ? (~divreq_msg_a[31:0] + 1'b1) : divreq_msg_a[31:0];
  // Multiplexer selection
  assign a_mux = (a_mux_sel) ? sub_mux_out : {32'b0, unsigned_a};

  //----------------------------------------------------------------------
  // Sequential Logic
  //----------------------------------------------------------------------

  // Computation logic
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      a_reg <= 65'b0;
      b_reg <= 65'b0;
    end else begin
      if (a_en) begin
        a_reg <= a_mux;
      end else begin
        a_reg <= 65'b0;
      end
      if (b_en) begin
        b_reg <= {1'b0, unsigned_b, 32'b0};
      end else begin
        b_reg <= 65'b0;
      end
    end
  end

  // Shifting logic
  assign a_shift_out = a_reg << 1;
  assign sub_out = a_shift_out - b_reg;
  
  // execute in the clock cycle
  assign sub_mux_out = (sub_mux_sel) ? a_shift_out : {sub_out[64:1], 1'b1};

  //--------------------------------------------------------------------
  // Result Handling
  //--------------------------------------------------------------------

  // wire [31:0] unsigned_quotient
  //   = ( fn_reg == `IMULDIV_DIVREQ_MSG_FUNC_SIGNED )   ? unsigned_a / unsigned_b
  //   : ( fn_reg == `IMULDIV_DIVREQ_MSG_FUNC_UNSIGNED ) ? a_reg / b_reg
  //   :                                                   32'bx;

  // wire [31:0] unsigned_remainder
  //   = ( fn_reg == `IMULDIV_DIVREQ_MSG_FUNC_SIGNED )   ? unsigned_a % unsigned_b
  //   : ( fn_reg == `IMULDIV_DIVREQ_MSG_FUNC_UNSIGNED ) ? a_reg % b_reg
  //   :                                                   32'bx;

  // Determine whether or not result is signed. Usually the result is
  // signed if one and only one of the input operands is signed. In other
  // words, the result is signed if the xor of the sign bits of the input
  // operands is true. Remainder opeartions are a bit trickier, and here
  // we simply assume that the result is signed if the dividend for the
  // rem operation is signed.

  wire is_result_signed_div = sign_bit_a ^ sign_bit_b;
  wire is_result_signed_rem = sign_bit_a;

  // Sign the final results if necessary

  // wire [31:0] signed_quotient
  //   = ( fn_reg == `IMULDIV_DIVREQ_MSG_FUNC_SIGNED
  //    && is_result_signed_div ) ? ~unsigned_quotient + 1'b1
  //   :                            unsigned_quotient;

  // wire [31:0] signed_remainder
  //   = ( fn_reg == `IMULDIV_DIVREQ_MSG_FUNC_SIGNED
  //    && is_result_signed_rem )   ? ~unsigned_remainder + 1'b1
  //  :                              unsigned_remainder;

  assign singed_res_rem_mux_out = (rem_sign_mux_sel) ? a_reg[63:32] : a_reg[63:32];
  assign singed_res_div_mux_out = (div_sign_mux_sel) ? a_reg[31:0] : a_reg[31:0];
  assign divresp_msg_result = { singed_res_rem_mux_out, singed_res_div_mux_out };

  // assign divreq_rdy  = divresp_rdy;
  // assign divresp_val = val_reg;

endmodule

//------------------------------------------------------------------------
// Control Logic
//------------------------------------------------------------------------

module imuldiv_IntDivIterativeCtrl
(
  input clk,
  input reset,

  input         divreq_val,
  output reg    divreq_rdy,
  output reg    divresp_val,
  input         divresp_rdy,

  input [64:0]  sub_out,

  output reg    sub_mux_sel,
  output reg    a_mux_sel,
  output reg    a_en,
  output reg    b_en
);

  //--------------------------------------------------------------------
  // State Encoding
  //--------------------------------------------------------------------

  localparam STATE_IDLE    = 2'b00;
  localparam STATE_COMPUTE = 2'b01;
  localparam STATE_DONE    = 2'b10;

  reg [1:0] state, next_state;
  reg [4:0] cycle_count;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= STATE_IDLE;
      cycle_count <= 5'd31;
    end else begin
      state <= next_state;
      // avoids count down after coutner reset
      if (next_state == STATE_COMPUTE)
        cycle_count <= cycle_count - 1; // calculate A, B, RESULT
    end
  end

  // state logic
  always @(*) begin
    next_state  = state;  // default out to IDLE
    divreq_rdy  = 1'b1;   // -> mod (keep listening)
    divresp_val = 1'b0;   // mod -> (but do not supply)

    case (state)
      STATE_IDLE: begin
        // if data is present and valid
        if (divreq_val) begin
          divresp_val = 1'b1;
          divreq_rdy  = 1'b0;           // lock listener
          next_state  = STATE_COMPUTE;  // begin compute
        end
      end
      STATE_COMPUTE: begin
        divresp_val = 1'b1;
        divreq_rdy  = 1'b0;             // lock listener
        if (cycle_count == 5'd0) begin
          next_state  = STATE_DONE;     // next cycle complete
        end
      end
      STATE_DONE: begin
        if (divresp_rdy) begin
          next_state = STATE_IDLE;      // finish cycle
          divresp_val = 1'b1;
          cycle_count = 5'd31;          // reset counter
        end
      end
    endcase
  end

  // combinational logic
  always @(*) begin
    // default off control signals
    a_mux_sel = 1'b0;
    sub_mux_sel = 1'b0;
    a_en = 1'b0;
    b_en = 1'b0;

    case (state)
      STATE_IDLE: begin
        // no operation, waiting 
        // for request to begin
        if (divreq_val) begin
          a_mux_sel = 1'b1;
        end
      end
      STATE_COMPUTE: begin
        // compute for each clock cycle
        a_en = 1'b1;
        b_en = 1'b1;
        if (cycle_count == 6'd30) begin
          a_mux_sel = 1'b1;
        end
        // th values is negative
        if (!sub_out[64]) begin
          sub_mux_sel = 1'b1;
        end
      end
      STATE_DONE: begin
        // result is ready to be sent
      end
    endcase
  end

endmodule

`endif
