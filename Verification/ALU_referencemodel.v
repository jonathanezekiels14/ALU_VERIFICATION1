module reference_model #(parameter OP_WIDTH = 8, parameter CMD_WIDTH = 4)(
	input [OP_WIDTH-1:0] OPA,OPB,
	input [1:0] INP_VALID,
	input CIN,MODE,
	input [CMD_WIDTH-1:0] CMD,
	output reg [2*OP_WIDTH-1:0] RES,
	output reg COUT,ERR,OFLOW,E,G,L
);
	always @(*) begin
		RES=0;
		COUT=0;
		ERR=0;
		OFLOW=0;
		E=0;
		G=0;
		L=0;
		if(MODE) begin
			case (CMD)
				0: begin
					if(INP_VALID == 3) begin
						{COUT,RES[OP_WIDTH-1:0]}=OPA+OPB;
					end
					else begin
						RES=0;
						ERR=1;
					end
				end
				1: begin 
					if(INP_VALID == 3) begin
						RES[OP_WIDTH-1:0]=OPA-OPB;
						OFLOW=(OPA<OPB);
					end
					else begin
						RES=0;
						ERR=1;
					end
				end
				2: begin
					if(INP_VALID == 3) begin
						{COUT,RES[OP_WIDTH-1:0]} = OPA + OPB +CIN;
					end
					else begin
						RES=0;
						ERR=1;
					end
				end
				3: begin
					if(INP_VALID == 3) begin
						RES[OP_WIDTH-1:0] = OPA - OPB - CIN;
						OFLOW = (OPA<(OPB+CIN));
					end
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				4: begin
					if(INP_VALID == 3 || INP_VALID == 1) begin
						RES[OP_WIDTH-1:0] = OPA + 1;
					end
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				5: begin
					if(INP_VALID == 3 || INP_VALID == 1 ) begin
						RES[OP_WIDTH-1:0] = OPA - 1;
					end
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				6: begin
					if(INP_VALID == 3 || INP_VALID == 2) begin
						RES [OP_WIDTH-1:0] = OPB + 1;
					end
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				7: begin
					if(INP_VALID == 3 || INP_VALID == 2 ) begin
						RES [OP_WIDTH-1:0] = OPB - 1;
					end
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				8: begin
					if(INP_VALID == 3) begin
						{E,G,L} = {(OPA==OPB),(OPA>OPB),(OPA<OPB)};
					end
					else begin
						{E,G,L} = 0;
						RES = 0;
						ERR = 1;
					end
				end
				9: begin
					if(INP_VALID == 3) begin
						RES = (OPA + 1) * (OPB + 1);
					end
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				10: begin
					if(INP_VALID == 3) begin
						RES = ((OPA << 1) * OPB);
					end
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				11: begin
					if(INP_VALID == 3) begin
						RES [OP_WIDTH-1:0] = $signed(OPA) + $signed(OPB);
						OFLOW = (OPA[OP_WIDTH-1] == OPB[OP_WIDTH-1]) && (RES [OP_WIDTH-1] != OPA[OP_WIDTH-1]);	
						{E,G,L}={($signed(OPA)==$signed(OPB)),($signed(OPA)>$signed(OPB)),($signed(OPA)<$signed(OPB))};
					end
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				12: begin
					if(INP_VALID == 3) begin
						RES [OP_WIDTH-1:0] = $signed(OPA) - $signed(OPB);
						OFLOW = (OPA[OP_WIDTH-1] == OPB[OP_WIDTH-1]) && (RES [OP_WIDTH-1] != OPA[OP_WIDTH-1]);	
						{E,G,L}={($signed(OPA)==$signed(OPB)),($signed(OPA)>$signed(OPB)),($signed(OPA)<$signed(OPB))};
					end
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				default: begin
					RES = 0;
					ERR = 1;
				end
			endcase
		end
		else begin
			case(CMD)
				0: begin
					if(INP_VALID == 3) 
						RES [OP_WIDTH-1:0] = OPA & OPB;
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				1: begin
					if(INP_VALID == 3)
						RES [OP_WIDTH-1:0] = ~ (OPA & OPB);
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				2: begin
					if(INP_VALID == 3)
						RES [OP_WIDTH-1:0] = (OPA | OPB);
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				3: begin
					if(INP_VALID == 3)
						RES [OP_WIDTH-1:0] = ~ (OPA & OPB);
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				4: begin
					if(INP_VALID == 3)
						RES [OP_WIDTH-1:0] =  (OPA ^ OPB);
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				5: begin
					if(INP_VALID == 3)
						RES [OP_WIDTH-1:0] = ~ (OPA ^ OPB);
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				6: begin
					if(INP_VALID == 3 || INP_VALID == 1)
						RES [OP_WIDTH-1:0] = ~ OPA;
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				7: begin
					if(INP_VALID == 3 || INP_VALID == 2)
						RES [OP_WIDTH-1:0] = ~OPB;
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				8: begin
					if(INP_VALID == 3 || INP_VALID == 1)
						RES [OP_WIDTH-1:0] = OPA>>1;
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				9: begin
					if(INP_VALID == 3 || INP_VALID == 1)
						RES [OP_WIDTH-1:0] = OPA<<1;
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				10: begin
					if(INP_VALID == 3 || INP_VALID == 2)
						RES [OP_WIDTH-1:0] = OPB>>1;
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				11: begin
					if(INP_VALID == 3 || INP_VALID == 2)
						RES [OP_WIDTH-1:0] = OPB<<1;
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				12: begin
					if(INP_VALID == 3) begin
						if (|(OPB[(2*OP_WIDTH)-1 : OP_WIDTH/2])) begin
            						ERR = 1'b1;
						end
						else begin
							ERR = 1'b0;
							RES[OP_WIDTH-1:0] = (OPA << (OPB % OP_WIDTH)) | (OPA >> (OP_WIDTH - (OPB % OP_WIDTH)));
							RES[(2*OP_WIDTH)-1 : OP_WIDTH] = 0;
						end
					end
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				13: begin
					if(INP_VALID == 3) begin
						if (|(OPB[(2*OP_WIDTH)-1 : OP_WIDTH/2])) begin
            						ERR = 1'b1;
						end
						else begin
							ERR = 1'b0;
							RES[OP_WIDTH-1:0] = (OPA >> (OPB % OP_WIDTH)) | (OPA << (OP_WIDTH - (OPB % OP_WIDTH)));
							RES[(2*OP_WIDTH)-1 : OP_WIDTH] = 0;
						end
					end
					else begin
						RES = 0;
						ERR = 1;
					end
				end
				default: begin
					RES = 0;
					ERR = 1;
				end
			endcase	
		end
	end
endmodule
					

