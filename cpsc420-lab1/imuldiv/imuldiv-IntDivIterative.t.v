//========================================================================
// Test for Div Unit
//========================================================================

`include "imuldiv-DivReqMsg.v"
`include "imuldiv-IntDivIterative.v"
`include "vc-TestSource.v"
`include "vc-TestSink.v"
`include "vc-Test.v"

//------------------------------------------------------------------------
// Helper Module
//------------------------------------------------------------------------

module imuldiv_IntDivIterative_helper
(
  input       clk,
  input       reset,
  output      done
);

  wire [64:0] src_msg;
  wire        src_msg_fn;
  wire [31:0] src_msg_a;
  wire [31:0] src_msg_b;
  wire        src_val;
  wire        src_rdy;
  wire        src_done;

  wire [63:0] sink_msg;
  wire        sink_val;
  wire        sink_rdy;
  wire        sink_done;

  assign done = src_done && sink_done;

  vc_TestSource#(65,3) src
  (
    .clk   (clk),
    .reset (reset),
    .bits  (src_msg),
    .val   (src_val),
    .rdy   (src_rdy),
    .done  (src_done)
  );

  imuldiv_DivReqMsgFromBits msgfrombits
  (
    .bits (src_msg),
    .func (src_msg_fn),
    .a    (src_msg_a),
    .b    (src_msg_b)
  );

  imuldiv_IntDivIterative idiv
  (
    .clk                 (clk),
    .reset               (reset),
    .divreq_msg_fn       (src_msg_fn),
    .divreq_msg_a        (src_msg_a),
    .divreq_msg_b        (src_msg_b),
    .divreq_val          (src_val),
    .divreq_rdy          (src_rdy),
    .divresp_msg_result  (sink_msg),
    .divresp_val         (sink_val),
    .divresp_rdy         (sink_rdy)
  );

  vc_TestSink#(64,3) sink
  (
    .clk   (clk),
    .reset (reset),
    .bits  (sink_msg),
    .val   (sink_val),
    .rdy   (sink_rdy),
    .done  (sink_done)
  );

endmodule

//------------------------------------------------------------------------
// Main Tester Module
//------------------------------------------------------------------------

module tester;

  // VCD Dump
  initial begin
    $dumpfile("imuldiv-IntDivIterative.vcd");
    $dumpvars;
  end

  `VC_TEST_SUITE_BEGIN( "imuldiv-IntDivIterative" )

  reg  t0_reset = 1'b1;
  wire t0_done;

  imuldiv_IntDivIterative_helper t0
  (
    .clk   (clk),
    .reset (t0_reset),
    .done  (t0_done)
  );

  `VC_TEST_CASE_BEGIN( 1, "div/rem" )
  begin

    t0.src.m[ 0] = 65'h1_00000000_00000001; t0.sink.m[ 0] = 64'h00000000_00000000;
    t0.src.m[ 1] = 65'h1_00000001_00000001; t0.sink.m[ 1] = 64'h00000000_00000001;
    t0.src.m[ 2] = 65'h1_00000000_ffffffff; t0.sink.m[ 2] = 64'h00000000_00000000;
    t0.src.m[ 3] = 65'h1_ffffffff_ffffffff; t0.sink.m[ 3] = 64'h00000000_00000001;
    t0.src.m[ 4] = 65'h1_00000222_0000002a; t0.sink.m[ 4] = 64'h00000000_0000000d;
    t0.src.m[ 5] = 65'h1_0a01b044_ffffb146; t0.sink.m[ 5] = 64'h00000000_ffffdf76;
    t0.src.m[ 6] = 65'h1_00000032_00000222; t0.sink.m[ 6] = 64'h00000032_00000000;
    t0.src.m[ 7] = 65'h1_00000222_00000032; t0.sink.m[ 7] = 64'h0000002e_0000000a;
    t0.src.m[ 8] = 65'h1_0a01b044_ffffb14a; t0.sink.m[ 8] = 64'h00003372_ffffdf75;
    t0.src.m[ 9] = 65'h1_deadbeef_0000beef; t0.sink.m[ 9] = 64'hffffda72_ffffd353;
    t0.src.m[10] = 65'h1_f5fe4fbc_00004eb6; t0.sink.m[10] = 64'hffffcc8e_ffffdf75;
    t0.src.m[11] = 65'h1_f5fe4fbc_ffffb14a; t0.sink.m[11] = 64'hffffcc8e_0000208b;

    #5;   t0_reset = 1'b1;
    #20;  t0_reset = 1'b0;
    #10000; `VC_TEST_CHECK( "Is sink finished?", t0_done )

  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // Add Unsigned Test Case Here
  //----------------------------------------------------------------------
  
  //----------------------------------------------------------------------
  // Test Case 2: Unsigned Div/Rem Tests (function = 0)
  //----------------------------------------------------------------------
  `VC_TEST_CASE_BEGIN( 2, "Unsigned Div/Rem Tests" )
  begin
    // U1: 0 ÷ 1
    t0.src.m[ 0] = 65'h0_00000000_00000001;  t0.sink.m[ 0] = 64'h00000000_00000000; // Zero dividend

    // U2: 1 ÷ 1
    t0.src.m[ 1] = 65'h0_00000001_00000001;  t0.sink.m[ 1] = 64'h00000000_00000001; // Unity division

    // U3: 5 ÷ 7
    t0.src.m[ 2] = 65'h0_00000005_00000007;  t0.sink.m[ 2] = 64'h00000005_00000000; // Dividend less than divisor

    // U4: 7 ÷ 5
    t0.src.m[ 3] = 65'h0_00000007_00000005;  t0.sink.m[ 3] = 64'h00000002_00000001; // 7/5: Q=1, R=2

    // U5: 0xFFFFFFFF ÷ 2
    t0.src.m[ 4] = 65'h0_FFFFFFFF_00000002;  t0.sink.m[ 4] = 64'h00000001_7FFFFFFF; // Max unsigned / 2

    // U6: 0xFFFFFFFF ÷ 0xFFFFFFFF
    t0.src.m[ 5] = 65'h0_FFFFFFFF_FFFFFFFF;  t0.sink.m[ 5] = 64'h00000000_00000001; // Identical operands

    // U7: 0x80000000 ÷ 2
    t0.src.m[ 6] = 65'h0_80000000_00000002;  t0.sink.m[ 6] = 64'h00000000_40000000; // Even division

    // U8: 0x80000001 ÷ 0x80000000
    t0.src.m[ 7] = 65'h0_80000001_80000000;  t0.sink.m[ 7] = 64'h00000001_00000001; // Just over the divisor

    // U9: 123456789 ÷ 10000
    // 123456789 = 0x075BCD15; 10000 = 0x00002710
    // Expected: Quotient = 12345 (0x3039), Remainder = 6789 (0x1A85)
    t0.src.m[ 8] = 65'h0_075BCD15_00002710;  t0.sink.m[ 8] = 64'h00001A85_00003039;

    #5;   t0_reset = 1'b1;
    #20;  t0_reset = 1'b0;
    #10000; `VC_TEST_CHECK( "Unsigned Div/Rem finished", t0_done );
  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // Test Case 3: Divisor as Power-of-Two Tests
  //----------------------------------------------------------------------
  `VC_TEST_CASE_BEGIN( 3, "Divisor as Power-of-Two Tests" )
  begin
    // --- Signed Divisions (function bit = 1) ---
    // S1: 100 ÷ 2
    // 100 / 2 = 50, remainder 0.
    // Quotient = 50 (0x32), Remainder = 0.
    t0.src.m[0] = 65'h1_00000064_00000002;  
    t0.sink.m[0] = 64'h00000000_00000032;
    
    // S2: (-100) ÷ 4
    // -100 in 32-bit two's complement = 0xFFFFFF9C.
    // -100 / 4 = -25, remainder 0.
    // Quotient = -25 = 0xFFFFFFE7, Remainder = 0.
    t0.src.m[1] = 65'h1_FFFFFF9C_00000004;
    t0.sink.m[1] = 64'h00000000_FFFFFFE7;
    
    // S3: 123 ÷ 8
    // 123 / 8 = 15 remainder 3.
    // Quotient = 15 (0x0F), Remainder = 3 (0x03).
    t0.src.m[2] = 65'h1_0000007B_00000008;  
    t0.sink.m[2] = 64'h00000003_0000000F;
    
    // --- Unsigned Divisions (function bit = 0) ---
    // U1: 0x12345678 ÷ 2
    // Since 0x12345678 is even, the quotient is 0x12345678 >> 1 = 0x091A2B3C, remainder = 0.
    t0.src.m[3] = 65'h0_12345678_00000002;
    t0.sink.m[3] = 64'h00000000_091A2B3C;
    
    // U2: 0xFFFFFFFF ÷ 8
    // 0xFFFFFFFF = 4294967295, divided by 8 gives:
    //   Quotient = 536870911 = 0x1FFFFFFF, Remainder = 7.
    t0.src.m[4] = 65'h0_FFFFFFFF_00000008;
    t0.sink.m[4] = 64'h00000007_1FFFFFFF;

    #5;   t0_reset = 1'b1;
    #20;  t0_reset = 1'b0;
    #10000; `VC_TEST_CHECK( "Divisor as Power-of-Two Tests finished", t0_done );
  end
  `VC_TEST_CASE_END

  `VC_TEST_SUITE_END( 3 )

endmodule
