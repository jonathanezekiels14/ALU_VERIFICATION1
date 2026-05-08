`timescale 1ns/1ps
`define WIDTH 8
`define CMD_WIDTH 4
`include "ALU_reference.v"
module alu_testbench();
	
	// DUT Signals
	reg [WIDTH-1:0] OPA,OPB;
	reg CLK,RST,CE,CIN;
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
	alu inst1 #(.WIDTH(WIDTH))(
		.clk(CLK),.rst(RST),.ce(CE),
		.c_in(CIN),.mode(MODE),.inp_valid(INP_VALID),
		.op_a(OPA),.op_b(OPB),.result(RES),
		.err(ERR),.G(G),.L(L),.E(E),
		.c_out(COUT),.overflow(OFLOW)
	);

	// Reference Model Instantiation 
	reference_model inst2 #(.OP_WIDTH(WIDTH),.CMD_WIDTH(CMD_WIDTH))(
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
	task driver();
		input [WIDTH-1:0] d_opa,d_opb;
		input [CMD_WIDTH-1:0] d_cmd;
		input [1:0] d_inp_valid;
		input d_cin,d_mode;
		begin
			@(negedge CLK);
			OPA = d_opa;
			OPB = d_opb;
			MODE = d_mode;
			CIN = d_cin;
			INP_VALID = d_inp_valid;
			CMD = d_cmd;

			@(posedge CLK);
			
			// Wait 2 Cycles more for Multiplication Commands
			if(d_mode == 1 && (d_cmd == 9 || d_cmd == 10)) begin
				repeat (2) @(posedge CLK);
			end
		end
	endtask

	// Scoreboard to track 
	task scoreboard();
		input [CMD_WIDTH-1:0] scb_cmd;
		begin
			test_count = test_count + 1;
			if(RES != RES_ref || ERR != ERR_ref || COUT != COUT_ref || OFLOW != OFLOW_ref || G != G_ref || L != L_ref || E != E_ref) begin
				fail_count = fail_count + 1;
				$display("-----------------------------------------------------------------------");
				$display(" [FAIL] Incorrect Output at MODE: %b , CMD: %d ",MODE,CMD);
				$display(" Inputs:	OPA: %d , OPB: %d , INP_VALID : %b ", OPA,OPB,INP_VALID);
				$display(" Expected Result : RES: %d , COUT: %b , OFLOW: %b , EGL: %b , ERR: %b ",RES_ref,COUT_ref,OFLOW_ref,{E_ref,G_ref,L_ref},ERR_ref);
				$display(" DUT Result	: RES: %d , COUT: %b , OFLOW: %b , EGL: %b , ERR: %b ",RES,COUT,OFLOW,{E,G,L},ERR);
				$display("-----------------------------------------------------------------------");
			end
			else begin
				$display(" [PASS] Inputs: OPA: %d , OPB: %d , INP_VALID : %b ", OPA,OPB,INP_VALID)
				$display(" Expected Result : RES: %d , COUT: %b , OFLOW: %b , EGL: %b , ERR: %b ",RES_ref,COUT_ref,OFLOW_ref,{E_ref,G_ref,L_ref},ERR_ref);
				$display(" DUT Result	: RES: %d , COUT: %b , OFLOW: %b , EGL: %b , ERR: %b ",RES,COUT,OFLOW,{E,G,L},ERR);
				pass_count = pass_count + 1;
			end
		end
	endtask	
	
	
endmodule	
