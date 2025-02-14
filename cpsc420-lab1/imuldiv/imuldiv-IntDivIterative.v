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
  input         divresp_rdy
);

  // Control Signals
  wire a_mux_sel;
  wire div_sign;
  wire rem_sign;
  wire sign_en;
  wire cntr_mux_sel;
  wire a_en;
  wire b_en;
  wire rem_sign_mux_sel;
  wire div_sign_mux_sel;
  wire sub_mux_sel;
  wire [64:0] sub_out;
  wire counter;

  imuldiv_IntDivIterativeDpath dpath
  (
    .clk                (clk),
    .reset              (reset),
    .divreq_msg_fn      (divreq_msg_fn),
    .divreq_msg_a       (divreq_msg_a),
    .divreq_msg_b       (divreq_msg_b),
    .divresp_msg_result (divresp_msg_result),
    .divreq_rdy         (divreq_rdy),
    .divreq_val         (divreq_val),
    .divresp_val        (divresp_val),
    .divresp_rdy        (divresp_rdy),
    .a_mux_sel          (a_mux_sel),
    .cntr_mux_sel       (cntr_mux_sel),
    .rem_sign_mux_sel   (rem_sign_mux_sel),
    .div_sign_mux_sel   (div_sign_mux_sel),
    .div_sign           (div_sign),
    .rem_sign           (rem_sign),
    .sub_mux_sel        (sub_mux_sel),
    .sub_out            (sub_out),
    .sign_en            (sign_en), 
    .a_en               (a_en),
    .b_en               (b_en),
    .counter            (counter)
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
    .div_sign           (div_sign),
    .rem_sign           (rem_sign),
    .cntr_mux_sel       (cntr_mux_sel),
    .rem_sign_mux_sel   (rem_sign_mux_sel),
    .div_sign_mux_sel   (div_sign_mux_sel),
    .sub_out            (sub_out),
    .sign_en            (sign_en),
    .a_en               (a_en),
    .b_en               (b_en),
    .counter            (counter)
  );

endmodule

//------------------------------------------------------------------------
// Datapath
//------------------------------------------------------------------------

module imuldiv_IntDivIterativeDpath
(
  input         clk,
  input         reset,

  input         divreq_rdy,
  input         divresp_val,
  input         divresp_rdy,
  input         divreq_val,

  input  [31:0] divreq_msg_a,       // Operand A
  input  [31:0] divreq_msg_b,       // Operand B
  input         divreq_msg_fn,

  input         a_mux_sel,
  input         sub_mux_sel,
  input         rem_sign_mux_sel,
  input         div_sign_mux_sel,
  input         cntr_mux_sel,
  output reg    div_sign,
  output reg    rem_sign,

  input         sign_en,
  input         a_en,
  input         b_en,

  output reg    counter,
  output [64:0] sub_out,
  output [63:0] divresp_msg_result  // Result of operation
);

  wire        stall_div;   // REgister to lock current inputs
  reg         fn_reg;      // Register for storing function
  reg  [64:0] a_reg;       // Register for storing operand A
  reg  [64:0] b_reg;       // Register for storing operand B

  wire [64:0] a_mux;       // Wire for sending A MUX
  wire [64:0] b_mux;       // Wire for sending B MUX
  wire [64:0] a_shift_out;
  wire [64:0] sub_mux_out;

  wire [31:0] signed_res_rem_mux_out, signed_res_div_mux_out;

  // Stall the pipeline inputs
  wire sign_bit_a = divreq_msg_a[31];
  wire sign_bit_b = divreq_msg_b[31];

  //----------------------------------------------------------------------
  // Combinational Logic
  //----------------------------------------------------------------------

  // Unsign operands if necessary
  wire [31:0] unsigned_a = (divreq_msg_fn == `IMULDIV_DIVREQ_MSG_FUNC_SIGNED && sign_bit_a) ? (~divreq_msg_a[31:0] + 1'b1) : divreq_msg_a[31:0];
  wire [31:0] unsigned_b = (divreq_msg_fn == `IMULDIV_DIVREQ_MSG_FUNC_SIGNED && sign_bit_b) ? (~divreq_msg_b[31:0] + 1'b1) : divreq_msg_b[31:0];
  
  // Multiplexer selection
  assign a_mux = (a_mux_sel) ? sub_mux_out : {33'b0, unsigned_a};

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
      end
      if (b_en) begin
        b_reg <= {1'b0, unsigned_b, 32'b0};
      end
    end
  end

  // Shifting logic
  assign a_shift_out = a_reg << 1;
  assign sub_out = a_shift_out - b_reg;
  
  assign sub_mux_out = (sub_mux_sel) ? a_shift_out : {sub_out[64:1], 1'b1};

  //--------------------------------------------------------------------
  // Result Handling
  //--------------------------------------------------------------------

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      div_sign <= 1'b0;
      rem_sign <= 1'b0;
    end else begin
      if (sign_en) begin
        div_sign <= (divreq_msg_fn == `IMULDIV_DIVREQ_MSG_FUNC_SIGNED) ? (sign_bit_a ^ sign_bit_b) : 1'b0;
        rem_sign <= (divreq_msg_fn == `IMULDIV_DIVREQ_MSG_FUNC_SIGNED) ? sign_bit_a : 1'b0;
      end
    end
  end

  // Determine whether or not result is signed. Usually the result is
  // signed if one and only one of the input operands is signed. In other
  // words, the result is signed if the xor of the sign bits of the input
  // operands is true. Remainder opeartions are a bit trickier, and here
  // we simply assume that the result is signed if the dividend for the
  // rem operation is signed.

  // Sign the final results if necessary

  assign signed_res_rem_mux_out = 
    (divreq_msg_fn == `IMULDIV_DIVREQ_MSG_FUNC_SIGNED 
    && rem_sign_mux_sel)
    ? (~a_reg[63:32] + 1'b1) 
    : a_reg[63:32];

  assign signed_res_div_mux_out = 
      (divreq_msg_fn == `IMULDIV_DIVREQ_MSG_FUNC_SIGNED 
      && div_sign_mux_sel) 
      ? (~a_reg[31:0] + 1'b1) 
      : a_reg[31:0];

  assign divresp_msg_result = { 
    signed_res_rem_mux_out,
    signed_res_div_mux_out
  };

  //--------------------------------------------------------------------
  // Counter Handling
  //--------------------------------------------------------------------

  reg [4:0] counter_reg;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      counter_reg <= 5'd31;
    end else begin
      if (cntr_mux_sel) begin
        counter_reg <= counter_reg - 1;
        // next clock cycle signal reg is 0
        if (counter_reg == 5'd1)
          counter <= 1;
        else
          counter <= 0;
      end else begin
        counter_reg <= 5'd31;
        counter <= 0;
      end
    end
  end

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

  input         counter,
  input [64:0]  sub_out,

  input         rem_sign,
  input         div_sign,
  output reg    rem_sign_mux_sel,
  output reg    div_sign_mux_sel,
  output reg    cntr_mux_sel,
  output reg    sub_mux_sel,
  output reg    a_mux_sel,
  output reg    sign_en,
  output reg    a_en,
  output reg    b_en
);

  //--------------------------------------------------------------------
  // State Encoding
  //--------------------------------------------------------------------

  localparam STATE_IDLE    = 2'b00;
  localparam STATE_COMPUTE = 2'b01;
  localparam STATE_DONE    = 2'b10;
  localparam STATE_UNUSED  = 2'b11;

  reg [2:0] state, next_state;
  
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= STATE_IDLE;
    end else begin
      state <= next_state;
    end
  end

  // rdy/val logic
  always @(*) begin
    next_state  = state;  // halt (no changes)
    divreq_rdy  = 1'b0;   // -> mod (keep fetching?)
    divresp_val = 1'b0;   // mod -> (ask to sink?)

    case (state)
      STATE_IDLE: begin
        divreq_rdy  = 1'b1;             // fetch until
        if (divreq_val) begin           // data is available
          next_state  = STATE_COMPUTE;  // begin compute
        end
      end
      STATE_COMPUTE: begin
        if (counter) begin              // while counter signals
          next_state  = STATE_DONE;     // execute 32 cycles
        end
      end
      STATE_DONE: begin
        divresp_val = 1'b1;             // ready to supply
        if (divresp_rdy) begin          // data flashed
          next_state = STATE_IDLE;      // finish cycle
        end
      end
      STATE_UNUSED: begin
        next_state = STATE_IDLE;
      end
    endcase
  end

  // switch logic
  always @(*) begin
    // default off control signals
    cntr_mux_sel      = 1'b0;     // shifted unless IDLE
    a_mux_sel         = 1'b1;     // shifted unless IDLE
    sub_mux_sel       = 1'b0;
    rem_sign_mux_sel  = 1'b0;
    div_sign_mux_sel  = 1'b0;
    sign_en           = 1'b0;
    a_en              = 1'b0;
    b_en              = 1'b0;

    case (state)
      STATE_IDLE: begin
        // propagate values to prevent
        // overwrite upon req_rdy is on
        if (divreq_val) begin
          sign_en       = 1'b1; // remember current sign state
          a_en          = 1'b1; // register A to avoid overwrite
          b_en          = 1'b1; // register B to avoid overwrite
        end
        a_mux_sel     = 1'b0;   // fetch the operand A (shifted or original)
      end
      STATE_COMPUTE: begin
        cntr_mux_sel  = 1'b1;   // pexecute counter (shifted or 5'b31)
        a_en          = 1'b1;   // fetched shifted operation

        if (sub_out[64])        // if difference is negative
          sub_mux_sel = 1'b1;   // use previous a_shit_out 
      end
      STATE_DONE: begin
        // result is ready to be sent
        div_sign_mux_sel = div_sign;
        rem_sign_mux_sel = rem_sign;
      end
    endcase
  end

endmodule

`endif
