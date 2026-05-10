`timescale 1ns/1ps
`include "ALU_referencemodel.v"
`include "ALU_toverify.v"
module alu_testbench();
	// Parameters
	parameter WIDTH = 8;
	parameter CMD_WIDTH = 4;
	// DUT Signals
	reg [WIDTH-1:0] OPA,OPB;
	reg CLK,RST,CE,CIN,MODE;
	reg [1:0] INP_VALID;
	reg [CMD_WIDTH-1:0] CMD;
	wire [2*WIDTH-1:0] RES;
	wire ERR,OFLOW,COUT,E,G,L;


	// Reference Model Signals
	wire [WIDTH-1:0] RES_ref;
	wire COUT_ref,OFLOW_ref,G_ref,E_ref,L_ref,ERR_ref;

	// Pass / Fail Counters
	integer pass_count = 0;
	integer fail_count = 0;
	integer test_count = 0;

	//DUT Instantiation
	alu #(.DATA_WIDTH(WIDTH)) inst1 (
		.clk(CLK),.rst(RST),.ce(CE),.cmd(CMD),
		.c_in(CIN),.mode(MODE),.inp_valid(INP_VALID),
		.op_a(OPA),.op_b(OPB),.result(RES),
		.err(ERR),.G(G),.L(L),.E(E),
		.c_out(COUT),.overflow(OFLOW)
	);

	// Reference Model Instantiation 
	reference_model #(.OP_WIDTH(WIDTH),.CMD_WIDTH(CMD_WIDTH)) inst2 ( 
		.OPA(OPA),.OPB(OPB),.INP_VALID(INP_VALID),
		.CIN(CIN),.MODE(MODE),.CMD(CMD),
		.RES(RES_ref),.COUT(COUT_ref),.OFLOW(OFLOW_ref),
		.ERR(ERR_ref),.E(E_ref),.G(G_ref),.L(L_ref)
	);
	
	// Clock Generation
	initial begin
		CLK = 0;
		forever #5 CLK = ~CLK;
	end
	
	// Driver to provide inputs to the 
	task driver;
		input d_mode;
		input [CMD_WIDTH-1:0] d_cmd;
		input [WIDTH-1:0] d_opa,d_opb;
		input d_cin;
		input [1:0] d_inp_valid;
		begin
			@(negedge CLK);
			OPA = d_opa;
			OPB = d_opb;
			MODE = d_mode;
			CIN = d_cin;
			INP_VALID = d_inp_valid;
			CMD = d_cmd;

			repeat (2) @(posedge CLK);
			
			// Wait 2 Cycles more for Multiplication Commands
			if(d_mode == 1 && (d_cmd == 9 || d_cmd == 10)) begin
				repeat (3) @(posedge CLK);
			end
		end
	endtask

	// Scoreboard to track 
	task scoreboard;
		input [CMD_WIDTH-1:0] scb_cmd;
		begin
			test_count = test_count + 1;
			if(RES != RES_ref || ERR != ERR_ref || COUT != COUT_ref || OFLOW != OFLOW_ref || G != G_ref || L != L_ref || E != E_ref) begin
				fail_count = fail_count + 1;
				$display("-----------------------------------------------------------------------");
				$display(" [FAIL] Incorrect Output at MODE: %b , CMD: %d ",MODE,scb_cmd);
				$display(" Inputs:	OPA: %d , OPB: %d , INP_VALID : %b ", OPA,OPB,INP_VALID);
				$display(" Expected Result : RES: %d , COUT: %b , OFLOW: %b , EGL: %b , ERR: %b ",RES_ref,COUT_ref,OFLOW_ref,{E_ref,G_ref,L_ref},ERR_ref);
				$display(" DUT Result	: RES: %d , COUT: %b , OFLOW: %b , EGL: %b , ERR: %b ",RES,COUT,OFLOW,{E,G,L},ERR);
				$display("-----------------------------------------------------------------------");
			end
			else begin
				$display(" [PASS] Inputs: OPA: %d , OPB: %d , INP_VALID : %b ", OPA,OPB,INP_VALID);
				$display(" Expected Result : RES: %d , COUT: %b , OFLOW: %b , EGL: %b , ERR: %b ",RES_ref,COUT_ref,OFLOW_ref,{E_ref,G_ref,L_ref},ERR_ref);
				$display(" DUT Result	: RES: %d , COUT: %b , OFLOW: %b , EGL: %b , ERR: %b ",RES,COUT,OFLOW,{E,G,L},ERR);
				pass_count = pass_count + 1;
			end
		end
	endtask	

	// Generator
	task generator;
		input target_mode;
		input [CMD_WIDTH-1:0] target_cmd;
		input [31:0] num_iterations;

		integer i;
		reg [WIDTH-1:0] rand_opa, rand_opb;

		begin
			for (i = 0; i < num_iterations ; i = i + 1) begin
				rand_opa = $random;
				rand_opb = $random;
				if ( target_mode == 0 && (target_cmd == 12 || target_cmd == 13 )) begin
					rand_opb = $random % 8;
				end

				driver(target_mode, target_cmd, rand_opa, rand_opb, $random ,2'b11);
				scoreboard(target_cmd);
			end
		end
	endtask

	initial begin
		CLK = 0; RST = 1; CE = 0; MODE = 0; CMD = 0; 
		OPA = 0; OPB = 0; CIN = 0; INP_VALID = 0;
		#5;
		
		$display("\n------------- Sanity Test Cases --------------");
		driver(1'b1,4'd11, 8'h7F, 8'h01, 0, 2'b11); scoreboard(4'd0); // Asynchronous RST Test
		CE = 1;
		#5; RST = 0;
		driver(1'b1,4'd11, 8'h7F, 8'h01, 0, 2'b11); scoreboard(4'd0); // Clock Enable Test
		CE = 0;
		driver(1'b1,4'd11, 8'h7F, 8'h01, 0, 2'b00); scoreboard(4'd0);
		CE = 1;
		driver(1'b0, 4'd0, 8'd1, 8'b11 , 0, 2'b11);scoreboard(4'd0); // Arithmetic Mode / Logical Mode
		driver(1'b1, 4'd0, 8'd1, 8'b11 , 0, 2'b11);scoreboard(4'd0); // Arithmetic Mode / Logical Mode
		#10; RST = 1;
		#20 RST = 0; CE = 1;
		@(posedge CLK);

		$display("\n------------- Directed Test Cases --------------");
		// Wrong Command
		driver(1'b1, 4'd15, 8'd1, 8'b11 , 0, 2'b11);scoreboard(4'd10); // Arithmetic Mode / Logical Mode
		driver(1'b0, 4'd15, 8'd1, 8'b11 , 0, 2'b11);scoreboard(4'd10); // Arithmetic Mode / Logical Mode
		// CMD_0_ADD
		driver(1'b1, 4'd0, 8'd24, 8'd81, 0, 2'b11); scoreboard(4'd0); // Checking with VALID INPUT
		driver(1'b1, 4'd0, 8'd24, 8'd81, 0, 2'b01); scoreboard(4'd0); // Checking with INVALID INPUT
		driver(1'b1, 4'd0, 8'd255, 8'd1, 0, 2'b11); scoreboard(4'd0); // Checking with COUT
		driver(1'b1, 4'd0, 8'd127, 8'd1, 0, 2'b11); scoreboard(4'd0); // Toggling Test
		// CMD_1_SUB
		driver(1'b1, 4'd1, 8'd84, 8'd67, 0, 2'b11); scoreboard(4'd1); // Valid Input Testcase
		driver(1'b1, 4'd1, 8'd84, 8'd67,0,  2'b01); scoreboard(4'd1); // Invalid Input Testcase
		driver(1'b1, 4'd1, 8'd200, 8'd231,  0, 2'b11); scoreboard(4'd1); // Overflow Testcase
		driver(1'b1, 4'd1, 8'd128, 8'd1, 0, 2'b11); scoreboard(4'd1); // Toggling Test
		driver(1'b1, 4'd1, 8'd0, 8'd1,   0, 2'b11); scoreboard(4'd1); // Subtraction with 0
		
		// CMD_2_ADD_CIN
		driver(1'b1, 4'd2, 8'd27, 8'd33,   1, 2'b11); scoreboard(4'd2); // Checking with Valid input
		driver(1'b1, 4'd2, 8'd27, 8'd33,   1, 2'b01); scoreboard(4'd2); // Checking with Invalid Input
		driver(1'b1, 4'd2, 8'd240, 8'd15,   1, 2'b11); scoreboard(4'd2); // COUT Testcase
		driver(1'b1, 4'd2, 8'd115, 8'd12,   1, 2'b11); scoreboard(4'd2); // Toggle Check

		// CMD_3_SUB_CIN
		driver(1'b1, 4'd3, 8'd115, 8'd12,   1, 2'b11); scoreboard(4'd3); // Checking Basic
		driver(1'b1, 4'd3, 8'd115, 8'd12,   1, 2'b10); scoreboard(4'd3); // Checking 
		driver(1'b1, 4'd3, 8'd115, 8'd211,   1, 2'b11); scoreboard(4'd3); // Checking Basic
		driver(1'b1, 4'd3, 8'd131, 8'd3,   1, 2'b11); scoreboard(4'd3); // Checking Basic
	

		// CMD_4_INC_A
		driver(1'b1, 4'd4, 8'd130, 8'd3,   0, 2'b11); scoreboard(4'd4); // Checking Basic
		driver(1'b1, 4'd4, 8'd255, 8'd3,   0, 2'b01); scoreboard(4'd4); // Checking MAX
		driver(1'b1, 4'd4, 8'd127, 8'd3,   0, 2'b01); scoreboard(4'd4); // Checking Toggle
		driver(1'b1, 4'd4, 8'd45, 8'd3,   0, 2'b00); scoreboard(4'd4); // Checking INP INVALID

		// CMD_5_DEC_A
		driver(1'b1, 4'd5, 8'd45, 8'd3,   0, 2'b11); scoreboard(4'd5); // Checking Basic 
		driver(1'b1, 4'd5, 8'd0, 8'd3,   0, 2'b01); scoreboard(4'd5); // Checking Decrementing 0  
		driver(1'b1, 4'd5, 8'd127, 8'd3,   0, 2'b11); scoreboard(4'd5); // Checking Toggle
		driver(1'b1, 4'd5, 8'd45, 8'd3,   0, 2'b00); scoreboard(4'd5); // Checking INP INVALID

		// CMD_6_INC_B

		driver(1'b1, 4'd6, 8'd3, 8'd130,   0, 2'b11); scoreboard(4'd6); // Checking Basic
		driver(1'b1, 4'd6, 8'd3, 8'd255,   0, 2'b10); scoreboard(4'd6); // Checking MAX
		driver(1'b1, 4'd6, 8'd3, 8'd127,   0, 2'b01); scoreboard(4'd6); // Checking Toggle
		driver(1'b1, 4'd6, 8'd3, 8'd45,   0, 2'b00); scoreboard(4'd6); // Checking INP INVALID

		// CMD_7_DEC_A
		driver(1'b1, 4'd7, 8'd3, 8'd45,   0, 2'b11); scoreboard(4'd7); // Checking Basic 
		driver(1'b1, 4'd7, 8'd3, 8'd0,   0, 2'b01); scoreboard(4'd7); // Checking Decrementing 0  
		driver(1'b1, 4'd7, 8'd31, 8'd127,   0, 2'b11); scoreboard(4'd7); // Checking Toggle
		driver(1'b1, 4'd7, 8'd33, 8'd45,   0, 2'b11); scoreboard(4'd7); // Checking INP INVALID

		// CMD_8_CMP
		driver(1'b1, 4'd8, 8'd100, 8'd100,   0, 2'b11); scoreboard(4'd8); // CMP EQUAL
		driver(1'b1, 4'd8, 8'd100, 8'd67,   0, 2'b11); scoreboard(4'd8); // CMP GREATER
		driver(1'b1, 4'd8, 8'd122, 8'd200,   0, 2'b11); scoreboard(4'd8); // CMP LESS
		driver(1'b1, 4'd8, 8'd100, 8'd100,   0, 2'b01); scoreboard(4'd8); // CMP INVALID INP
		driver(1'b1, 4'd8, 8'd100, 8'd100,   0, 2'b10); scoreboard(4'd8); // CMP INVAID INP
		driver(1'b1, 4'd8, 8'd100, 8'd100,   0, 2'b01); scoreboard(4'd8); // CMP INP VALID

		// CMD_9_MUL

		driver(1'b1, 4'd9, 8'd67, 8'd67,   0, 2'b11); scoreboard(4'd9); // Basic MUL
		driver(1'b1, 4'd9, 8'd255, 8'd56,   0, 2'b11); scoreboard(4'd9); // MUL with 0
		driver(1'b1, 4'd9, 8'd254, 8'd254,   0, 2'b11); scoreboard(4'd9); // Basic MUL
		driver(1'b1, 4'd9, 8'd254, 8'd0,   0, 2'b11); scoreboard(4'd9); // Basic MUL
		driver(1'b1, 4'd9, 8'd254, 8'd0,   0, 2'b00); scoreboard(4'd9); // Basic MUL
		driver(1'b1, 4'd9, 8'd254, 8'd0,   0, 2'b01); scoreboard(4'd9); // Basic MUL
		driver(1'b1, 4'd9, 8'd254, 8'd0,   0, 2'b10); scoreboard(4'd9); // Basic MUL
		driver(1'b1, 4'd9, 8'd1, 8'd22,   0, 2'b11); scoreboard(4'd9); // Basic MUL
		driver(1'b1, 4'd9, 8'd1, 8'd22,   0, 2'b10); scoreboard(4'd9); // Basic MUL
		// CMD_10_MUL

		driver(1'b1, 4'd10, 8'd254, 8'd0,   0, 2'b11); scoreboard(4'd10); // Basic MUL
		driver(1'b1, 4'd10, 8'd128, 8'd0,   0, 2'b11); scoreboard(4'd10); // MUL with 0
		driver(1'b1, 4'd10, 8'd127, 8'd255,   0, 2'b11); scoreboard(4'd10); // Basic Pass Through
		driver(1'b1, 4'd10, 8'd127, 8'd0,   0, 2'b11); scoreboard(4'd10); // Basic MUL
		driver(1'b1, 4'd10, 8'd127, 8'd0,   0, 2'b00); scoreboard(4'd10); // INP INVALID
		driver(1'b1, 4'd10, 8'd127, 8'd0,   0, 2'b01); scoreboard(4'd10); // INP INVALID
		driver(1'b1, 4'd10, 8'd127, 8'd0,   0, 2'b10); scoreboard(4'd10); // INP INVALID

		// CMD_11_SiADD
		driver(1'b1, 4'd11, 8'd5, -8'd6,   0, 2'b11); scoreboard(4'd11); // Basic Signed ADD
		driver(1'b1, 4'd11, -8'd21, -8'd67,   0, 2'b11); scoreboard(4'd11); // Basic Signed ADD
		driver(1'b1, 4'd11, 8'd255, 8'd1,   0, 2'b11); scoreboard(4'd11); // Basic Signed ADD
		driver(1'b1, 4'd11, 8'd11, 8'd0,   0, 2'b11); scoreboard(4'd11); // Basic Signed ADD
		driver(1'b1, 4'd11, 8'd5, -8'd0,   0, 2'b11); scoreboard(4'd11); // Basic Signed ADD
		driver(1'b1, 4'd11, 8'd5, 8'd66,   0, 2'b01); scoreboard(4'd11); // Basic Signed ADD
		driver(1'b1, 4'd11, 8'd5, 8'd66,   0, 2'b00); scoreboard(4'd11); // Basic Signed ADD
		driver(1'b1, 4'd11, 8'd5, 8'd66,   0, 2'b10); scoreboard(4'd11); // Basic Signed ADD

		// CMD_12_SiSUB
		driver(1'b1, 4'd12, 8'd5, 8'd66,   0, 2'b11); scoreboard(4'd12); // Basic Signed SUB
		driver(1'b1, 4'd12, 8'd26, -8'd6,   0, 2'b11); scoreboard(4'd12); // Basic Signed SUB
		driver(1'b1, 4'd12, 8'd255, -8'd1,   0, 2'b11); scoreboard(4'd12); // Corner Case
		driver(1'b1, 4'd12, 8'd5, 8'd0,   0, 2'b11); scoreboard(4'd12); // Corner Case
		driver(1'b1, 4'd12, 8'd128, 8'd1,   0, 2'b11); scoreboard(4'd12); // Corner Case
		driver(1'b1, 4'd12, 8'd127, -8'd1,   0, 2'b11); scoreboard(4'd12); // Corner Case
		driver(1'b1, 4'd12, -8'd12, -8'd74,   1, 2'b11); scoreboard(4'd12); // Corner Case
		driver(1'b1, 4'd12, -8'd12, -8'd74,   1, 2'b10); scoreboard(4'd12); // Corner Case
		driver(1'b1, 4'd12, -8'd12, -8'd74,   1, 2'b01); scoreboard(4'd12); // Corner Case

		// MODE = 0 
		// CMD_0_AND -> CMD_7_NOT_B
		driver(1'b0, 4'd0, 8'd12, 8'd74,   0, 2'b10); scoreboard(4'd0); // Corner Case
		driver(1'b0, 4'd1, 8'd12, 8'd74,   0, 2'b10); scoreboard(4'd1); // Corner Case
		driver(1'b0, 4'd2, 8'd12, 8'd74,   0, 2'b10); scoreboard(4'd2); // Corner Case
		driver(1'b0, 4'd3, 8'd12, 8'd74,   0, 2'b10); scoreboard(4'd3); // Corner Case
		driver(1'b0, 4'd4, 8'd12, 8'd74,   0, 2'b10); scoreboard(4'd4); // Corner Case
		driver(1'b0, 4'd5, 8'd12, 8'd74,   0, 2'b10); scoreboard(4'd5); // Corner Case
		driver(1'b0, 4'd6, 8'd12, 8'd74,   0, 2'b00); scoreboard(4'd6); // Corner Case
		driver(1'b0, 4'd7, 8'd12, 8'd74,   0, 2'b01); scoreboard(4'd7); // Corner Case

		// CMD_8_SHR1_A
		driver(1'b0, 4'd8, 8'd128, 8'd74,   0, 2'b01); scoreboard(4'd8); // Corner Case
		driver(1'b0, 4'd8, 8'd1, 8'd74,   0, 2'b01); scoreboard(4'd8); // Corner Case
		driver(1'b0, 4'd8, 8'd1, 8'd74,   0, 2'b10); scoreboard(4'd8); // Corner Case

		// CMD_9_SHIL_A
		driver(1'b0, 4'd9, 8'd128, 8'd74,   0, 2'b01); scoreboard(4'd9); // Corner Case
		driver(1'b0, 4'd9, 8'd1, 8'd74,   0, 2'b01); scoreboard(4'd9); // Corner Case
		driver(1'b0, 4'd9, 8'd1, 8'd74,   0, 2'b10); scoreboard(4'd9); // Corner Case

		// CMD_10_SHR1_B
		driver(1'b0, 4'd10, 8'd12, 8'd128,   0, 2'b10); scoreboard(4'd10); // Corner Case
		driver(1'b0, 4'd10, 8'd11, 8'd1,   0, 2'b10); scoreboard(4'd10); // Corner Case
		driver(1'b0, 4'd10, 8'd1, 8'd74,   0, 2'b01); scoreboard(4'd10); // Corner Case

		// CMD_11_SHIL_B
		driver(1'b0, 4'd11, 8'd1, 8'd128,   0, 2'b01); scoreboard(4'd11); // Corner Case
		driver(1'b0, 4'd11, 8'd17, 8'd1,   0, 2'b01); scoreboard(4'd11); // Corner Case
		driver(1'b0, 4'd11, 8'd1, 8'd74,   0, 2'b01); scoreboard(4'd11); // Corner Case

		// CMD_12_ROL_A_B
		driver(1'b0, 4'd12, 8'd1, 8'd0,   0, 2'b11); scoreboard(4'd12); // Roll by 0
		driver(1'b0, 4'd12, 8'd155, 8'd4,   0, 2'b11); scoreboard(4'd12); // Roll by 4
		driver(1'b0, 4'd12, 8'd24, 8'd7,   0, 2'b11); scoreboard(4'd12); // Roll by 7
		driver(1'b0, 4'd12, 8'd24, 8'bx,   0, 2'b11); scoreboard(4'd12); // Roll by 0
		driver(1'b0, 4'd12, 8'd24, 8'd212,   0, 2'b11); scoreboard(4'd12); // Roll by 0
		driver(1'b0, 4'd12, 8'd24, 8'd212,   0, 2'b01); scoreboard(4'd12); // INP INVALID

		// CMD_13_ROR_A_B
		driver(1'b0, 4'd13, 8'd128, 8'd0,   0, 2'b11); scoreboard(4'd13); // Roll by 0
		driver(1'b0, 4'd13, 8'd172, 8'd4,   0, 2'b11); scoreboard(4'd13); // Roll by 4
		driver(1'b0, 4'd13, 8'd170, 8'd7,   0, 2'b11); scoreboard(4'd13); // Roll by 7
		driver(1'b0, 4'd13, 8'd170, 8'bx,   0, 2'b11); scoreboard(4'd13); // Roll by 0
		driver(1'b0, 4'd13, 8'd170, 8'd167,   0, 2'b11); scoreboard(4'd13); // Roll by HIGH
		driver(1'b0, 4'd13, 8'd170, 8'd7,   0, 2'b10); scoreboard(4'd13); // INP_INVALID


		$display("\n------------- Randomized Testcases -------------");
		// MODE = 1
		generator(1'b1, 4'd0, 100);   // CMD_0_ADD
		generator(1'b1, 4'd1, 100);   // CMD_1_SUB
		generator(1'b1, 4'd2, 100);   // CMD_2_ADD_CIN
		generator(1'b1, 4'd3, 100);   // CMD_2_SUB_CIN
		generator(1'b1, 4'd4, 100);   // CMD_3
		generator(1'b1, 4'd5, 100);   // CMD_3
		generator(1'b1, 4'd6, 100);   // CMD_3
		generator(1'b1, 4'd7, 100);   // CMD_3
		generator(1'b1, 4'd8, 100);   // CMD_3
		generator(1'b1, 4'd9, 100);   // CMD_3
		generator(1'b1, 4'd10, 100);   // CMD_3
		generator(1'b1, 4'd11, 100);   // CMD_3
		generator(1'b1, 4'd12, 100);   // CMD_3
		// MODE = 0
		generator(1'b0, 4'd0, 100);   // CMD_3
		generator(1'b0, 4'd1, 100);   // CMD_3
		generator(1'b0, 4'd2, 100);   // CMD_3
		generator(1'b0, 4'd3, 100);   // CMD_3
		generator(1'b0, 4'd4, 100);   // CMD_3
		generator(1'b0, 4'd5, 100);   // CMD_3
		generator(1'b0, 4'd6, 100);   // CMD_3
		generator(1'b0, 4'd7, 100);   // CMD_3
		generator(1'b0, 4'd8, 100);   // CMD_3
		generator(1'b0, 4'd9, 100);   // CMD_3
		generator(1'b0, 4'd10, 100);   // CMD_3
		generator(1'b0, 4'd11, 100);   // CMD_3
		generator(1'b0, 4'd12, 100);   // CMD_3
		generator(1'b0, 4'd13, 100);   // CMD_3
		$display("\n-------------------------------------------------");
		$display("                 Test Summary                      ");
		$display("---------------------------------------------------");
		$display("Total Tests Run : %0d", test_count);
		$display("Passed          : %0d", pass_count);
		$display("Failed          : %0d", fail_count);
		if (fail_count == 0)
			$display(" ***  All Testcases PASSED ***");
		else
			$display(" ***	    Bugs Found	     ***");
        	$display("---------------------------------------------------\n");
        
        	#100; $finish;
    	end	
endmodule	
