// Quartus Prime Verilog Template
// Single port RAM with single read/write address and initial contents 
// specified with an initial block

module single_port_ram_with_init
#(parameter DATA_WIDTH=8, parameter ADDR_WIDTH=6)
(
	input [(DATA_WIDTH-1):0] data,
	input [(ADDR_WIDTH-1):0] addr,
	input we, clk,
	output [(DATA_WIDTH-1):0] q
);

	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];

	// Variable to hold the registered read address
	reg [ADDR_WIDTH-1:0] addr_reg;

	// Specify the initial contents.  You can also use the $readmemb
	// system task to initialize the RAM variable from a text file.
	// See the $readmemb template page for details.
	initial 
	begin : INIT
		integer i;
		for(i = 0; i < 2**ADDR_WIDTH; i = i + 1)
		if (i != 2)
		begin
			ram[i] = {DATA_WIDTH{1'b0}};
		end
		else
		begin
		  ram[i] = 992;
		end
	end 

	always @ (posedge clk)
	begin
		// Write
		if (we)
			ram[addr] <= data;

		addr_reg <= addr;
	end

	// Continuous assignment implies read returns NEW data.
	// This is the natural behavior of the TriMatrix memory
	// blocks in Single Port mode.  
	assign q = ram[addr_reg];

endmodule


module RISCV(
    input clk,
	 //output reg [31:0]instr,
	 //output reg [6:0]op,
	 output wire [2:0]PCo,
	 output reg blLed,
    //output reg vga_v,
    //output reg vga_h,
    //output reg[7:0] vga_r,
    //output reg[7:0] vga_g,
    //output reg[7:0] vga_b,
    output ram
);
  
  reg [7:0]ram[0:34000];
  
  
  //reg [31:0]registers[0:31];
  
  reg [31:0] Rdata = 0;
  reg [4:0] Raddr = 0;
  reg Rwe = 0;
  wire [31:0]Rq;
  single_port_ram_with_init #(32, 5) regs(Rdata, Raddr, Rwe, clk, Rq);
  
  reg [7:0] cycleCounter = 0;
  reg [31:0]PC = 0;
  //assign blLed = 0;
  assign PCo = PC[4:2];
  
  // Instr Decode data
  reg [31:0]instr = 0;
  reg [6:0]op = 0;
  reg [2:0]funct3 = 0;
  reg [6:0]funct7 = 0;
  reg [4:0]rd = 0;
  reg [4:0]rs1 = 0;
  reg [4:0]rs2 = 0;
  reg [11:0]ItypeIMM = 0;
  reg [20:0]JtypeIMM = 0;
  reg [11:0]BtypeIMM = 0;
  reg [31:0]UtypeIMM = 0;// 12bit offset and extended!
  reg [11:0]BtypeIMMBranch = 0;
  
  reg [31:0]ItypeIMMSignExtended = 0;
  reg [31:0]JtypeIMMSignExtended = 0;
  reg [31:0]BtypeIMMSignExtended = 0;
  reg [31:0]BtypeIMMBranchSignExtended = 0;
  
  reg [31:0]rdReg = 0;
  reg [31:0]rs1Reg = 0;
  reg [31:0]rs2Reg = 0;
  
  reg validInstr = 0;
  
  `define stringPos 804
  `define intPos 800
  
  reg clk1hz = 0;
  reg [63:0]clkCount = 0;
  
  always @(posedge clk)
  begin
	clkCount = clkCount + 1;
	if (clkCount > 500000)
	begin
		clk1hz = !clk1hz;
		clkCount = 0;
	end
  end
  
  integer i;
  
  initial begin
    for (i = 0; i < 34001; i = i+1)
      begin
        ram[i] = 0;
      end
    
    /*for (i = 0; i < 32; i = i+1)
      begin
        registers[i] = 0;
      end*/
    PC = 32'h000001ec;
    /*ram[0] = 8'h00;// addi  a0, a0, 1
    ram[1] = 8'h15;
    ram[2] = 8'h05;
    ram[3] = 8'h13;
	
	 ram[4] = 8'hff;// jal   x1, begin
    ram[5] = 8'h5f;
    ram[6] = 8'hf0;
    ram[7] = 8'hef;*/
    /*ram[4] = 8'h01;// li    a5, 24
    ram[5] = 8'h80;
    ram[6] = 8'h07;
    ram[7] = 8'h93;
    
    ram[8] = 8'h00;// sw    a0, 0(a5)
    ram[9] = 8'ha7;
    ram[10] = 8'ha0;
    ram[11] = 8'h23;
    
    ram[12] = 8'hff;// jal   x1, begin
    ram[13] = 8'h5f;
    ram[14] = 8'hf0;
    ram[15] = 8'hef;*/
    //registers[2] = 992;
    
  end
  
  always @ (posedge clk)
    begin
    //registers[0] = 0;
    //$display("cc: %d", cycleCounter);
      case (cycleCounter)
        0: begin
          instr = {ram[PC], ram[PC+1], ram[PC+2], ram[PC+3]};
          
          op = instr[6:0];
          funct3 = instr[14:12];
          funct7 = instr[31:25];
          rd = instr[11:7];
          rs1 = instr[19:15];
          rs2 = instr[24:20];
          ItypeIMM = instr[31:20];
          JtypeIMM = {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
          BtypeIMM = {instr[31:25], instr[11:7]};
          UtypeIMM[31:12] = instr[31:12];// 12bit offset and extended!
          UtypeIMM[11:0] = 0;
          BtypeIMMBranch = {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
          
          ItypeIMMSignExtended = {{20{ItypeIMM[11]}}, ItypeIMM};
          JtypeIMMSignExtended = {{11{JtypeIMM[20]}}, JtypeIMM};
          BtypeIMMSignExtended = {{20{BtypeIMM[11]}}, BtypeIMM};
          BtypeIMMBranchSignExtended = {{20{BtypeIMMBranch[11]}}, BtypeIMMBranch};
			 
			 Raddr = rd;
			 Rwe = 0;
        end
        1: begin
          rdReg = Rq;
			 Raddr = rs1;
          //$display("RD before(%d): %d", rd, rdReg);
        end
        2: begin
          rs1Reg = Rq;
			 Raddr = rs2;
          //$display("RS1 before(%d): %d", rs1, rs1Reg);
        end
        3: begin
          rs2Reg = Rq;
          //$display("RS2 before(%d): %d", rs2, rs2Reg);
        end
        4: begin
          //$display("PC: %d instr: %b op: %h funct3: %h rd: %d rs1: %d rs2: %d ItypeIMM: %d JtypeIMM: %d BtypeIMM: %d X1: %d X14(a4): %d X15(a5): %d X8: %d ram[32772r]: %d ram[int]: %d",
          //         PC, instr, op, funct3, rd, rs1, rs2, ItypeIMM, JtypeIMM, BtypeIMM, registers[1], registers[14], registers[15], registers[8],
          //         {ram[6004]}, {ram[`intPos], ram[`intPos +1], ram[`intPos +2], ram[`intPos +3]});
          //$display("string @ stringPos: %s", {ram[`stringPos ], ram[`stringPos +1], ram[`stringPos +2], ram[`stringPos +3], ram[`stringPos +4], ram[`stringPos +5], ram[`stringPos +6], ram[`stringPos +7], ram[`stringPos +8], ram[`stringPos +9], ram[`stringPos +10]});
          
          if (op == 7'b0010011)// Math immediate
            begin
              if (funct3 == 3'b000)// ADDI
                begin
                  $display("ADDI");
                  rdReg = rs1Reg+ItypeIMMSignExtended;
                  
                  validInstr = 1;
                end
              else if (funct3 == 3'b010)// SLTI
                begin
                  $display("SLTI");
                  rdReg = ($signed(rs1Reg) < $signed(ItypeIMMSignExtended));
                  
                  validInstr = 1;
                end
              else if (funct3 == 3'b011)// SLTIU
                begin
                  $display("SLTIU");
                  rdReg = (rs1Reg<ItypeIMMSignExtended);
                  
                  validInstr = 1;
                end
              else if (funct3 == 3'b100)// XORI
                begin
                  $display("XORI");
                  rdReg = (rs1Reg ^ ItypeIMMSignExtended);
                  
                  validInstr = 1;
                end
              else if (funct3 == 3'b110)// ORI
                begin
                  $display("ORI");
                  rdReg = (rs1Reg | ItypeIMMSignExtended);
                  
                  validInstr = 1;
                end
              else if (funct3 == 3'b111)// ANDI
                begin
                  $display("ANDI");
                  rdReg = (rs1Reg & ItypeIMMSignExtended);
                  
                  validInstr = 1;
                end
              else if (funct3 == 3'b001)// SLLI
                begin
                  if (funct7 == 7'b0000000)
                    begin
                      $display("SLLI");
                      rdReg = (rs1Reg << ItypeIMMSignExtended[4:0]);

                      validInstr = 1;
                    end
                end
              else if (funct3 == 3'b101)// SRLI
                begin
                  if (funct7 == 7'b0000000)
                    begin
                      $display("SRLI");
                      rdReg = (rs1Reg >> ItypeIMMSignExtended[4:0]);

                      validInstr = 1;
                    end
                end
              else if (funct3 == 3'b101)// SRAI
                begin
                  if (funct7 == 7'b0100000)
                    begin
                      $display("SRAI");
                      rdReg = (rs1Reg >>> ItypeIMMSignExtended[4:0]);

                      validInstr = 1;
                    end
                end
            end
          
          if (op == 7'b0110011)// Register math
            begin
              if (funct3 == 3'b000)
                begin
                  if (funct7 == 7'b0000000)// ADD
                	begin
                      $display("ADD");
                      rdReg = rs1Reg+rs2Reg;

                      validInstr = 1;
                    end
                  else if (funct7 == 7'b0100000)// SUB
                	begin
                      $display("SUB");
                      rdReg = rs1Reg-rs2Reg;

                      validInstr = 1;
                    end
                end
              else if (funct3 == 3'b010)
                begin
                  if (funct7 == 7'b0000000)// SLT
                	begin
                      $display("SLT");
                      rdReg = ($signed(rs1Reg) < $signed(rs2Reg));

                      validInstr = 1;
                    end
                end
              else if (funct3 == 3'b011)
                begin
                  if (funct7 == 7'b0000000)// SLTU
                	begin
                      $display("SLTU");
                      rdReg = (rs1Reg < rs2Reg);

                      validInstr = 1;
                    end
                end
              else if (funct3 == 3'b001)
                begin
                  if (funct7 == 7'b0000000)// SLL
                	begin
                      $display("SLL");
                      rdReg = (rs1Reg << rs2Reg[4:0]);

                      validInstr = 1;
                    end
                end
              else if (funct3 == 3'b101)
                begin
                  if (funct7 == 7'b0000000)// SRL
                	begin
                      $display("SRL");
                      rdReg = (rs1Reg >> rs2Reg[4:0]);

                      validInstr = 1;
                    end
                end
              else if (funct3 == 3'b101)
                begin
                  if (funct7 == 7'b0100000)// SRA
                	begin
                      $display("SRA");
                      rdReg = (rs1Reg >>> rs2Reg[4:0]);

                      validInstr = 1;
                    end
                end
              else if (funct3 == 3'b100)
                begin
                  if (funct7 == 7'b0000000)// XOR
                	begin
                      $display("XOR");
                      rdReg = (rs1Reg ^ rs2Reg);

                      validInstr = 1;
                    end
                end
              else if (funct3 == 3'b110)
                begin
                  if (funct7 == 7'b0000000)// OR
                	begin
                      $display("OR");
                      rdReg = (rs1Reg | rs2Reg);

                      validInstr = 1;
                    end
                end
              else if (funct3 == 3'b111)
                begin
                  if (funct7 == 7'b0000000)// AND
                	begin
                      $display("AND");
                      rdReg = (rs1Reg & rs2Reg);

                      validInstr = 1;
                    end
                end
            end
          
          if (op == 7'b1100011)// Branch instructions
            begin
              if (funct3 == 3'b000)// BEQ
                begin
                  $display("BEQ");
                  if (rs1Reg == rs2Reg)
                    begin
                      PC = PC + BtypeIMMBranchSignExtended - 4;
                    end
                  
                  validInstr = 1;
                end
              else if (funct3 == 3'b001)// BNE
                begin
                  $display("BNE");
                  if (rs1Reg != rs2Reg)
                    begin
                      PC = PC + BtypeIMMBranchSignExtended - 4;
                    end
                  
                  validInstr = 1;
                end
              else if (funct3 == 3'b100)// BLT
                begin
                  $display("BLT");
                  if ($signed(rs1Reg) < $signed(rs2Reg))
                    begin
                      PC = PC + BtypeIMMBranchSignExtended - 4;
                    end
                  
                  validInstr = 1;
                end
              else if (funct3 == 3'b101)// BGE
                begin
                  $display("BGE");
                  if ($signed(rs1Reg) >= $signed(rs2Reg))
                    begin
                      PC = PC + BtypeIMMBranchSignExtended - 4;
                    end
                  
                  validInstr = 1;
                end
              else if (funct3 == 3'b110)// BLTU
                begin
                  $display("BLTU");
                  if (rs1Reg < rs2Reg)
                    begin
                      PC = PC + BtypeIMMBranchSignExtended - 4;
                    end
                  
                  validInstr = 1;
                end
              else if (funct3 == 3'b111)// BGEU
                begin
                  $display("BGEU");
                  if (rs1Reg >= rs2Reg)
                    begin
                      PC = PC + BtypeIMMBranchSignExtended - 4;
                    end
                  
                  validInstr = 1;
                end
            end
          
          else if (op == 7'b1101111)// JAL
            begin
              $display("JAL");
              //PC = PC + {{21{JtypeIMM[10]}}, JtypeIMM[10:0]} - 4;
              rdReg = PC + 4;
              PC = PC + JtypeIMMSignExtended - 4;
              
              validInstr = 1;
            end
          
          else if (op == 7'b1100111)// JALR
            begin
              if (funct3 == 3'b000)
                begin
                  $display("JALR");
                  //PC = PC + {{21{JtypeIMM[10]}}, JtypeIMM[10:0]} - 4;
                  rdReg = PC + 4;
                  PC = rs1Reg + {ItypeIMMSignExtended[31:1], 1'b0} - 4;

                  validInstr = 1;
                end
            end
          
          else if (op == 7'b0100011)// Store instructions
            begin
              if (funct3 == 3'b010)// SW
                begin
                  $display("SW");
                  ram[BtypeIMMSignExtended+rs1Reg+3] = 	rs2Reg[7:0];
                  ram[BtypeIMMSignExtended+rs1Reg+2] = 	rs2Reg[15:8];
                  ram[BtypeIMMSignExtended+rs1Reg+1] = 	rs2Reg[23:16];
                  ram[BtypeIMMSignExtended+rs1Reg] = 	rs2Reg[31:24];

                  validInstr = 1;
                end
              else if (funct3 == 3'b001)// SH
                begin
                  $display("SH");
                  ram[BtypeIMMSignExtended+rs1Reg+1] = 	rs2Reg[7:0];
                  ram[BtypeIMMSignExtended+rs1Reg] = 	rs2Reg[15:8];

                  validInstr = 1;
                end
              else if (funct3 == 3'b000)// SB
                begin
                  $display("SB");
                  ram[BtypeIMMSignExtended+rs1Reg] = 	rs2Reg[7:0];

                  validInstr = 1;
                end
            end
          
          else if (op == 7'b0000011)// Load instructions
            begin
              if (funct3 == 3'b010)// LW
                begin
                  $display("LW");
                  rdReg = {ram[ItypeIMMSignExtended+rs1Reg], 
                                   ram[ItypeIMMSignExtended+rs1Reg+1], 
                                   ram[ItypeIMMSignExtended+rs1Reg+2], 
                                   ram[ItypeIMMSignExtended+rs1Reg+3]};

                  validInstr = 1;
                end
              else if (funct3 == 3'b001)// LH
                begin
                  $display("LH");
                  rdReg = {{16{ram[ItypeIMMSignExtended+rs1Reg][7]}}, 
                                   ram[ItypeIMMSignExtended+rs1Reg], 
                                   ram[ItypeIMMSignExtended+rs1Reg+1]};

                  validInstr = 1;
                end
              else if (funct3 == 3'b000)// LB
                begin
                  $display("LB");
                  rdReg = {{24{ram[ItypeIMMSignExtended+rs1Reg][7]}}, 
                                   ram[ItypeIMMSignExtended+rs1Reg]};

                  validInstr = 1;
                end
              else if (funct3 == 3'b101)// LHU
                begin
                  $display("LHU");
                  rdReg = {ram[ItypeIMMSignExtended+rs1Reg], 
                                   ram[ItypeIMMSignExtended+rs1Reg+1]};

                  validInstr = 1;
                end
              else if (funct3 == 3'b100)// LBU
                begin
                  $display("LBU");
                  rdReg = ram[ItypeIMMSignExtended+rs1Reg];

                  validInstr = 1;
                end
            end
          
          else if (op == 7'b0110111)// LUI
            begin
              $display("LUI");
              rdReg[31:12] = UtypeIMM[31:12];
              rdReg[11:0] = 0;

              validInstr = 1;
            end
          
          else if (op == 7'b0010111)// AUIPC
            begin
              $display("AUIPC");
              PC = PC + UtypeIMM;
              rdReg = PC;

              validInstr = 1;
            end
          
          if (!validInstr)
            begin
              $display("INV");
            end
          
          PC = PC+4;
          //registers[0] = 0;
          validInstr = 0;
          //$display("");
			 Raddr = 10;
        end
        5: begin
			 blLed = Rq[0];
			 Raddr = rd;
          //registers[rd] = rdReg;
			 Rdata = rdReg;
			 Rwe = 1;
          //$display("RD after(%d): %d", rd, rdReg);
        end
        /*6: begin
          //registers[rs1] = rs1Reg;
          //$display("RS1 after(%d): %d", rs1, rs1Reg);
        end*/
        6: begin
		  Raddr = 0;
        Rdata = 0;
		  Rwe = 1;
          //registers[rs2] = rs2Reg;
          //$display("RS2 after(%d): %d", rs2, rs2Reg);
          cycleCounter = -1;
        end
      endcase
      cycleCounter = cycleCounter + 1;
    end
  
endmodule
