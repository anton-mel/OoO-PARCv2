//========================================================================
// Lab 1 - Iterative Mul Unit
//========================================================================

`ifndef PARC_INT_MUL_ITERATIVE_V
`define PARC_INT_MUL_ITERATIVE_V

module imuldiv_IntMulIterative
(
  input                clk,
  input                reset,

  input  [31:0] mulreq_msg_a,
  input  [31:0] mulreq_msg_b,
  input         mulreq_val,
  output        mulreq_rdy,

  output [63:0] mulresp_msg_result,
  output        mulresp_val,
  input         mulresp_rdy
);

  // dpath <-> ctl
  // wiring level
  wire a_mux_sel;
  wire b_mux_sel;
  wire result_mux_sel;
  wire cntr_mux_sel;
  wire sign_mux_sel;
  wire add_mux_sel;

  wire result_en;
  wire sign_en;
  wire sign;

  wire counter;
  wire [31:0] b_reg;

  imuldiv_IntMulIterativeDpath dpath
  (
    .clk                (clk),
    .reset              (reset),
    .mulreq_msg_a       (mulreq_msg_a),
    .mulreq_msg_b       (mulreq_msg_b),
    .mulresp_msg_result (mulresp_msg_result),

    // MUX Control Signals
    .a_mux_sel          (a_mux_sel),
    .b_mux_sel          (b_mux_sel),
    .result_mux_sel     (result_mux_sel),
    .cntr_mux_sel       (cntr_mux_sel),
    .sign_mux_sel       (sign_mux_sel),
    .add_mux_sel        (add_mux_sel),

    .result_en          (result_en),
    .sign_en            (sign_en),
    .sign               (sign),

    .counter            (counter),
    .b_reg              (b_reg)
  );

  imuldiv_IntMulIterativeCtrl ctrl
  (
    .clk                (clk),
    .reset              (reset),

    .mulreq_val         (mulreq_val),
    .mulresp_rdy        (mulresp_rdy),
    .mulreq_rdy         (mulreq_rdy),
    .mulresp_val        (mulresp_val),

    // MUX Control Signals
    .a_mux_sel          (a_mux_sel),
    .b_mux_sel          (b_mux_sel),
    .result_mux_sel     (result_mux_sel),
    .cntr_mux_sel       (cntr_mux_sel),
    .sign_mux_sel       (sign_mux_sel),
    .add_mux_sel        (add_mux_sel),
    .result_en          (result_en),
    .sign_en            (sign_en),
    .sign               (sign),

    .counter            (counter),
    .b_reg              (b_reg)
  );

endmodule

//------------------------------------------------------------------------
// Datapath
//------------------------------------------------------------------------

module imuldiv_IntMulIterativeDpath
(
  input         clk,
  input         reset,

  // Module Inputs/Outputs
  input  [31:0] mulreq_msg_a,       // Operand A
  input  [31:0] mulreq_msg_b,       // Operand B
  output [63:0] mulresp_msg_result, // Result

  // CTL Signals
  input         a_mux_sel,
  input         b_mux_sel,
  input         result_mux_sel,
  input         cntr_mux_sel,
  input         sign_mux_sel,
  input         add_mux_sel,
  input         result_en,
  input         sign_en,
  output reg    sign,

  output reg    counter,
  output reg [31:0] b_reg
);

  // Registers for the MM
  reg  [63:0] result_reg;               // Register for storing operand RESULT
  reg  [63:0] a_reg;                    // Register for storing operand A
  reg  [63:0] sign_reg;                 // Register for storing signed value
  reg         val_reg;                  // Register for storing valid bit

  wire [63:0] a_mux;                    // Register for storing A MUX
  wire [31:0] b_mux;                    // Register for storing B MUX
  wire [63:0] result_mux;               // Register for storing RESULT MUX

  wire sign_bit_a;
  wire sign_bit_b;
  wire [31:0] unsigned_a;
  wire [31:0] unsigned_b;
  wire [63:0] a_shift_out;
  wire [31:0] b_shift_out;
  wire [63:0] add_mux_out;

  //----------------------------------------------------------------------
  // Combinational Logic
  //----------------------------------------------------------------------

  // Extract sign bits
  assign sign_bit_a = mulreq_msg_a[31];
  assign sign_bit_b = mulreq_msg_b[31];
  // Unsign operands (if necessary)
  assign unsigned_a = ( sign_bit_a ) ? (~mulreq_msg_a[31:0] + 1'b1) : mulreq_msg_a[31:0];
  assign unsigned_b = ( sign_bit_b ) ? (~mulreq_msg_b[31:0] + 1'b1) : mulreq_msg_b[31:0];
  // Multiplexer selection
  assign a_mux = (a_mux_sel) ? a_shift_out : {32'b0, unsigned_a};
  assign b_mux = (b_mux_sel) ? b_shift_out : unsigned_b;
  assign result_mux = (result_mux_sel) ? add_mux_out : 64'b0;
  
  //----------------------------------------------------------------------
  // Sequential Logic
  //----------------------------------------------------------------------

  always @( posedge clk or posedge reset ) begin
    if (reset) begin
      a_reg <= 64'b0;
      b_reg <= 32'b0;
    end else begin
      a_reg <= a_mux;
      b_reg <= b_mux;
    end
  end

  // Shifting logic
  assign a_shift_out = a_reg << 1;
  assign b_shift_out = b_reg >> 1;

  //--------------------------------------------------------------------
  // Result Handling
  //--------------------------------------------------------------------

  always @( posedge clk or posedge reset ) begin
    if (reset) begin
      result_reg <= 64'b0;
    end else if (result_en) begin
      result_reg <= result_mux;
    end else begin
      result_reg <= 64'b0;
    end
  end

  assign add_mux_out = (add_mux_sel) ? (result_reg + a_reg) : result_reg;

  // Determine whether or not result is signed. Usually the result is
  // signed if one and only one of the input operands is signed. In other
  // words, the result is signed if the xor of the sign bits of the input
  // operands is true. Remainder opeartions are a bit trickier, and here
  // we simply assume that the result is signed if the dividend for the
  // rem operation is signed.

  wire is_result_signed = sign_bit_a ^ sign_bit_b;

  always @( posedge clk or posedge reset ) begin
    if (reset) begin
      sign <= 1'b0;
    end else begin
      if (sign_en) begin
        sign <= is_result_signed;
      end
    end
  end

  assign mulresp_msg_result
    = (sign_mux_sel) ? (~result_reg + 1'b1) : result_reg;

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

module imuldiv_IntMulIterativeCtrl
(
  input clk,
  input reset,

  input         mulreq_val,
  output reg    mulreq_rdy,
  output reg    mulresp_val,
  input         mulresp_rdy,

  output reg    a_mux_sel,
  output reg    b_mux_sel,
  output reg    result_mux_sel,
  output reg    cntr_mux_sel,
  output reg    add_mux_sel,
  output reg    sign_mux_sel,
  output reg    result_en,
  output reg    sign_en,
  input         sign,

  input         counter,
  input [31:0]  b_reg
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
    mulreq_rdy  = 1'b0;   // -> mod (keep fetching?)
    mulresp_val = 1'b0;   // mod -> (ask to sink?)

    case (state)
      STATE_IDLE: begin
        mulreq_rdy  = 1'b1;             // fetch until
        if (mulreq_val) begin           // data is available
          next_state  = STATE_COMPUTE;  // begin compute
        end
      end
      STATE_COMPUTE: begin
        if (counter) begin              // while counter signals
          next_state  = STATE_DONE;     // execute 32 cycles
        end
      end
      STATE_DONE: begin
        mulresp_val = 1'b1;             // ready to supply
        if (mulresp_rdy) begin          // data flashed
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
    a_mux_sel       = 1'b1; // shifted unless IDLE
    b_mux_sel       = 1'b1; // shifted unless IDLE
    cntr_mux_sel    = 1'b1; // shifted unless IDLE
    result_mux_sel  = 1'b0;
    result_en       = 1'b0;
    add_mux_sel     = 1'b0;
    sign_mux_sel    = 1'b0;
    sign_en         = 1'b0;

    case (state)
      STATE_IDLE: begin
        if (mulreq_val) begin             // if data is present
          // propagate values 
          // to prevent overwrite
          sign_en = 1'b1;                 // remember current sign state
          a_mux_sel = 1'b0;               // fetch the operand A (shifted or original)
          b_mux_sel = 1'b0;               // fetch the operand B (shifted or original)
          cntr_mux_sel = 1'b0;            // prepare the counter (shifted or 5'b31)
        end
      end
      STATE_COMPUTE: begin
        // compute for each clock cycle
        if (b_reg[0] == 1'b1)
          add_mux_sel = 1'b1;             // use the add logic for result accumulation
        result_mux_sel = 1'b1;            // enable result selection
        result_en = 1'b1;                 // enable result accumulation
      end
      STATE_DONE: begin
        // result is ready to be sent
        sign_mux_sel = sign;              // If sign flag is enabled, select signed result
      end
    endcase
  end

endmodule

`endif
