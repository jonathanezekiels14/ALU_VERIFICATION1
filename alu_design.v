module alu_design #(parameter WIDTH=4)(
    CLK,RST,MODE,CIN,CE,OPA,OPB,INP_VALID,CMD,RES,ERR,G,L,E,COUT,OFLOW 
    );
	input CLK,RST,MODE,CIN,CE;                    //Initialized all values to 0
	input [WIDTH-1:0] OPA,OPB;
	input [1:0] INP_VALID;
	input [3:0] CMD;
	output reg [2*WIDTH-1:0] RES;
	output reg ERR,G,L,E,COUT,OFLOW;
	reg [1:0] count;
	reg [WIDTH-1:0] temp,tempA, tempB;	
	always @(posedge CLK) begin
		if (MODE==1 && ( CMD==9 || CMD ==10))
				count<=count+1;
		else	
			count<=0;
	always @(posedge CLK or posedge RST) begin    //Asynchronous Active High RESET
		if(RST) begin
			RES<=0;
			COUT<=0;
			ERR<=0;
			G<=0;
			L<=0;
			E<=0;
			OFLOW<=0;
			count<=0;
		end
		else begin
			if(CE) begin
				if(MODE) begin       //Mode - 1: Arithmetic Operation | Mode - 0: Logical Operation
					case (CMD)
						0: case( INP_VALID) // CMD - 0 : ADD
							3:begin     // Perform OPA+OPB only if INP_VALID = 3
								RES<= OPA+OPB;
								COUT<=RES[WIDTH]?1:0;
							end
							default: begin     // Else ERR=1 , RES = 0
								RES<=0;
								ERR<=1'b1;
							end                              
						endcase
						1: case( INP_VALID)  // CMD -1 : SUB
							3: begin  // Perform OPA-OPB only if INP_VALID = 3
								OFLOW<=(OPA<OPB)?1:0;
								RES<=OPA-OPB;
								ERR<=0;
							end
							default: begin // Else ERR=1 , RES = 0
								RES<=0;
								ERR<=1'b1;
							end
						endcase
						2: case( INP_VALID)  // CMD - 2 : ADD_CIN
							3: begin
								RES<=OPA+OPB+CIN;
								COUT<=RES[WIDTH]? 1:0;
								ERR<=0;
							end
							default: begin
								RES<=0;
								ERR<=1'b1;
							end
						endcase
						3: case(INP_VALID)  // CMD - 3 : SUB_CIN
							3: begin
								OFLOW<=(OPA<(OPB+CIN))?1:0;
								RES<=OPA-OPB-CIN;
							end
							default: begin
								RES<=0;
								ERR<=1'b1;
							end
						endcase
						4: case (INP_VALID)  // CMD - 4 : INC_A 
							1: RES<=OPA+1;
							3: RES<=OPA+1;
							default: begin
								RES<=0;
								ERR<=1;
							end
						endcase
						5: case (INP_VALID)  // CMD - 5 : DEC_A 
							1: RES<=OPA-1;
							3: RES<=OPA-1;
							default: begin
								RES<=0;
								ERR<=1;
							end
						endcase              
						6: case(INP_VALID) // CMD - 6 : INC_B
							2: RES<=OPB+1;
							3: RES<=OPB+1;
							default: begin
								RES<=0;
								ERR<=1;
							end
						endcase
						7:case(INP_VALID) // CMD - 7 : DEC_B
							2: RES<=OPB-1;
							3: RES<=OPB-1;
							default: begin
								RES<=0;
								ERR<=1;
							end
						endcase
						8: case(INP_VALID) // CMD  - 8: CMP
							3: begin
								if(OPA==OPB) 
									{E,G,L}=3'b100;
								else if (OPA>OPB)
									{E,G,L}=3'b010;
								else 
									{E,G,L}=3'b001;
							end
							default: {E,G,L}=3'b000;
						endcase
						9: case (INP_VALID) //CMD - 9: MULTIPLICATION w INC_A and INC_B
			 				3: begin
								case(count)
									1: begin
										tempA<=OPA;
										tempB<=OPB;
									end
									2: begin
										tempA<=tempA+1;
										tempB<=tempB+1;
									end
									3: begin
										RES<=tempA*tempB;
										count<=0;
									default: count<=0;
								endcase
							default: begin
									RES<=0;
									ERR<=1;
							end
						10: case (INP_VALID) //CMD - 10: MULTIPLICATION w SHIL_A
                                                        3: begin
                                                                case(count)
                                                                        1: begin
                                                                                tempA<=OPA;
                                                                                tempB<=OPB;
                                                                        end
                                                                        2: begin
                                                                                temp<=tempA<<1;
                                                                        end
                                                                        3: begin
                                                                                RES<=temp * tempB;
                                                                                count<=0;
                                                                        default: count<=0;
                                                                endcase
                                                        default: begin
                                                                        RES<=0;
                                                                        ERR<=1;
                                                        end
						11: case(INP_VALID) // CMD - 11: SIGNED ADDITION
							3: begin
														
					endcase
                		end
			end
			else begin
				RES<=RES;
				ERR<=ERR;
				COUT<=COUT;
				G<=G;
				L<=L;
				E<=E;
				OFLOW<=OFLOW;
			end
        	end
	end
endmodule

