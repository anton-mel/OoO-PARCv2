// this has to be changed 1

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

  wire a_mux_sel;
  wire b_mux_sel;
  wire result_mux_sel;
  wire add_mux_sel;
  wire sign_mux_sel;
  wire result_en;

  // Declare b_reg as wire to connect 
  // the datapath and control module
  wire [31:0] b_reg; 

  imuldiv_IntMulIterativeDpath dpath
  (
    .clk                (clk),
    .reset              (reset),
    .mulreq_msg_a       (mulreq_msg_a),
    .mulreq_msg_b       (mulreq_msg_b),
    .mulreq_val         (mulreq_val),
    .mulreq_rdy         (mulreq_rdy),
    .mulresp_msg_result (mulresp_msg_result),
    .mulresp_val        (mulresp_val),
    .mulresp_rdy        (mulresp_rdy),
    .a_mux_sel          (a_mux_sel),      // multiplexer a_mux
    .b_mux_sel          (b_mux_sel),      // multiplexer b_mux
    .result_mux_sel     (result_mux_sel), // multiplexer result_mux
    .add_mux_sel        (add_mux_sel),    // multiplexer after ADDer
    .sign_mux_sel       (sign_mux_sel),   // multiplexer on OUTPUT
    .result_en          (result_en),      // switch for result_reg
    .b_reg              (b_reg)           // Pass b_reg to control module?
  );

  imuldiv_IntMulIterativeCtrl ctrl
  (
    .clk                (clk),
    .reset              (reset),

    .mulreq_val         (mulreq_val),
    .mulresp_rdy        (mulresp_rdy),
    .mulreq_rdy         (mulreq_rdy),

    .a_mux_sel          (a_mux_sel),      // multiplexer a_mux
    .b_mux_sel          (b_mux_sel),      // multiplexer b_mux
    .result_mux_sel     (result_mux_sel), // multiplexer result_mux
    .add_mux_sel        (add_mux_sel),    // multiplexer after ADDer
    .sign_mux_sel       (sign_mux_sel),   // multiplexer on OUTPUT
    .result_en          (result_en),      // switch for result_reg
    .b_reg              (b_reg)           // b_reg as input to control module
  );

endmodule

//------------------------------------------------------------------------
// Datapath
//------------------------------------------------------------------------

module imuldiv_IntMulIterativeDpath
(
  input         clk,
  input         reset,

  input  [31:0] mulreq_msg_a,       // Operand A
  input  [31:0] mulreq_msg_b,       // Operand B
  input         mulreq_val,         // Request val Signal
  output        mulreq_rdy,         // Request rdy Signal

  output [63:0] mulresp_msg_result, // Result of operation
  output        mulresp_val,        // Response val Signal
  input         mulresp_rdy,        // Response rdy Signal

  // Control signals for mux selection
  input         a_mux_sel,
  input         b_mux_sel,
  input         result_mux_sel,
  input         add_mux_sel,
  input         sign_mux_sel,
  input         result_en,

  output [31:0] b_reg
);

  //--------------------------------------------------------------------
  // Registers and Wires
  //--------------------------------------------------------------------
  reg  [63:0] a_reg, a_shift_out;
  reg  [31:0] b_reg, b_shift_out;
  reg  [63:0] result_reg;
  reg         val_reg;

  wire [63:0] a_mux;
  wire [31:0] b_mux;
  wire [63:0] result_mux;
  wire [63:0] add_mux_out;
  wire [63:0] signed_result;

  always @( posedge clk ) begin

    // Stall the pipeline if the response interface is not ready
    if ( mulresp_rdy ) begin
      a_reg   <= mulreq_msg_a;
      b_reg   <= mulreq_msg_b;
      val_reg <= mulreq_val;
    end

  end

  //--------------------------------------------------------------------
  // A Operand Handling
  //--------------------------------------------------------------------
  wire [31:0] unsigned_a = (mulreq_msg_a[31]) ? (~mulreq_msg_a + 1'b1) : mulreq_msg_a;
  assign a_mux = (a_mux_sel) ? a_shift_out : {32'b0, unsigned_a};

  always @(posedge clk) begin
    if (reset) begin
      a_reg <= 64'b0;
      a_shift_out <= 64'b0;
    end else begin
      a_reg <= a_mux;
      a_shift_out <= a_reg << 1;
    end
  end

  //--------------------------------------------------------------------
  // B Operand Handling
  //--------------------------------------------------------------------
  wire[31:0] unsigned_b = (mulreq_msg_b[31]) ? (~mulreq_msg_b + 1'b1) : mulreq_msg_b;
  assign b_mux = (b_mux_sel) ? b_shift_out : unsigned_b;

  always @(posedge clk) begin
    if (reset) begin
      b_reg <= 32'b0;
      b_shift_out <= 32'b0;
    end else begin
      b_reg <= b_mux;
      b_shift_out <= (b_reg[0]) ? (b_reg >> 1) : b_reg; // Shift only if LSB is 1
    end
  end

  //--------------------------------------------------------------------
  // Result Handling
  //--------------------------------------------------------------------
  assign result_mux = (result_mux_sel) ? add_mux_out : 64'b0;

  always @(posedge clk) begin
    if (reset) begin
      result_reg <= 64'b0;
    end else if (result_en) begin
      result_reg <= result_reg + a_reg;
    end
  end

  assign add_mux_out = (add_mux_sel) ? (result_reg + a_reg) : result_reg;

  //--------------------------------------------------------------------
  // Final Output and Sign Correction
  //--------------------------------------------------------------------
  assign signed_result = (mulreq_msg_a[31] ^ mulreq_msg_b[31]) ? (~result_reg + 1'b1) : result_reg;
  assign mulresp_msg_result = (sign_mux_sel) ? signed_result : result_reg;

  assign mulresp_val = val_reg;

  //--------------------------------------------------------------------
  // Request Ready Signal
  //--------------------------------------------------------------------
  assign mulreq_rdy = mulresp_rdy;

endmodule

//------------------------------------------------------------------------
// Control Logic
//------------------------------------------------------------------------

module imuldiv_IntMulIterativeCtrl
(
  input clk,
  input reset,

  input mulreq_val,
  input mulresp_rdy,

  output reg mulreq_rdy,
  output reg a_mux_sel,
  output reg b_mux_sel,
  output reg result_mux_sel,
  output reg add_mux_sel,
  output reg sign_mux_sel,
  output reg result_en,

  input [31:0] b_reg
);

  //--------------------------------------------------------------------
  // State Encoding
  //--------------------------------------------------------------------

  localparam STATE_IDLE    = 3'b000;
  localparam STATE_COMPUTE = 3'b001;
  localparam STATE_DONE    = 3'b010;

  reg [2:0] state, next_state;
  reg [5:0] cycle_count;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= STATE_IDLE;
      cycle_count <= 6'b0;
    end else begin
      state <= next_state;
      if (state == STATE_COMPUTE)
        cycle_count <= cycle_count + 1;
      else
        cycle_count <= 6'b0;
    end
  end

  always @(*) begin
    case (state)
      STATE_IDLE: begin
        if (mulreq_val && mulresp_rdy)
          next_state = STATE_COMPUTE;
        else
          next_state = STATE_IDLE;
      end
      STATE_COMPUTE: begin
        if (cycle_count == 6'd32)
          next_state = STATE_DONE;
        else
          next_state = STATE_COMPUTE;
      end
      STATE_DONE: begin
        if (mulresp_rdy)
          next_state = STATE_IDLE;
        else
          next_state = STATE_DONE;
      end
      default: next_state = STATE_IDLE;
    endcase
  end

  always @(*) begin
    // Default control signals
    a_mux_sel       = 1'b0;
    b_mux_sel       = 1'b0;
    result_mux_sel  = 1'b0;
    add_mux_sel     = 1'b0;
    sign_mux_sel    = 1'b0;
    result_en       = 1'b0;
    mulreq_rdy      = 1'b0;

    case (state)
      STATE_IDLE: begin
        a_mux_sel       = 1'b1;
        b_mux_sel       = 1'b1;
        result_mux_sel  = 1'b1;
        if (mulreq_val && mulresp_rdy)
          mulreq_rdy = 1'b1;
      end
      STATE_COMPUTE: begin
        result_en       = 1'b1;
        add_mux_sel     = b_reg[0];
        mulreq_rdy      = 1'b1;
      end
      STATE_DONE: begin
        sign_mux_sel    = 1'b1;
        mulreq_rdy      = 1'b0;
      end
    endcase
  end

endmodule

`endif
