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
				repeat (2) @(posedge CLK);
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

				driver(target_mode, target_cmd, rand_opa, rand_opb, $random , 2'b11);
				scoreboard(target_cmd);
			end
		end
	endtask

	initial begin
		CLK = 0; RST = 1; CE = 0; MODE = 0; CMD = 0; 
		OPA = 0; OPB = 0; CIN = 0; INP_VALID = 0;

		#20 RST = 0; CE = 1;
		@(posedge CLK);

		$display("\n------------- Directed Test Cases --------------");
		driver(1'b1, 4'd11, 8'h7F, 8'h01, 0, 2'b11); scoreboard(4'd11); // Signed Overflow
		driver(1'b1, 4'd11, 8'h80, 8'hFF, 0, 2'b11); scoreboard(4'd11); // Signed Overflow (Negative)
		driver(1'b0, 4'd0,  8'hAA, 8'h55, 0, 2'b11); scoreboard(4'd0);  // Bitwise Masking
		driver(1'b1, 4'd0,  8'd10, 8'd20, 0, 2'b01); scoreboard(4'd0);  // Missing input error

		$display("\n------------- Randomized Testcases -------------");
		generator(1'b0, 4'd0, 50);   // Logical AND
		generator(1'b1, 4'd0, 100);  // Unsigned ADD
		generator(1'b1, 4'd9, 50);   // Inc & Multiply (takes 3 cycles!)
		generator(1'b1, 4'd11, 100); // Signed ADD

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
