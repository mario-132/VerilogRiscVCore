`define dbg(a) 
`define dbgINV(a) a
`define waitforram oldTA == TA
`define mmuAddrSize 31
`define ramAddrSize 23

//`define edpg

// Handles all memory accesses
module RISCVBasicMMU32(
  input clk,
  
  output reg [31:0]ram_io_w_data = 0,
  output reg [`ramAddrSize:0]ram_io_addr = 0,
  input wire [31:0]ram_io_r_data,
  output reg ram_io_w_we = 0,
  
  input wire [`mmuAddrSize:0]addr,
  input wire [1:0]reqSize,// 0=1b 1=2b 2=4b
  input wire [31:0]writeData,
  output reg [31:0]readData = 0,
  input wire rw,// 0=read; 1=write
  output reg [`mmuAddrSize:0]rdrAddr = 0,
  output reg [`mmuAddrSize:0]wrrAddr = 0,
  
  input activate,
  input TA,
  output reg oldTA = 0
);
  
  reg [7:0]Rcounter = 0;
  reg [7:0]newRcounter = 0;
  
  always @(posedge clk)
    begin
      if (activate)
        begin
          if (rw == 0)
            begin
              // Start Read
              if (Rcounter == 0 && oldTA != TA)
                begin
                  newRcounter = Rcounter + 1;
                  ram_io_w_we = 0;
                  ram_io_addr = addr >> 2;// Divide by 4, we use the discarded lower 2 bits later
                  readData <= 0;
                end
              
              if (Rcounter == 1)
                begin
                  newRcounter = Rcounter + 1;
                  if (reqSize == 0)// 1 byte read
                    begin
                      if (addr[1:0] == 0)
                        begin
                          readData <= ram_io_r_data[7:0];
                        end
                      if (addr[1:0] == 1)
                        begin
                          readData <= ram_io_r_data[15:8];
                        end
                      if (addr[1:0] == 2)
                        begin
                          readData <= ram_io_r_data[23:16];
                        end
                      if (addr[1:0] == 3)
                        begin
                          readData <= ram_io_r_data[31:24];
                        end
                      rdrAddr = addr;
                      oldTA = TA;
                      newRcounter = 0;
                    end
                  
                  if (reqSize == 1)// 2 byte read
                    begin
                      if (addr[1:0] == 0)
                        begin
                          readData[15:8] <= ram_io_r_data[7:0];
                          readData[7:0] <= ram_io_r_data[15:8];
                          newRcounter = 0;
                          rdrAddr = addr;
                          oldTA = TA;
                        end
                      if (addr[1:0] == 1)
                        begin
                          readData[15:8] <= ram_io_r_data[15:8];
                          readData[7:0] <= ram_io_r_data[23:16];
                          newRcounter = 0;
                          rdrAddr = addr;
                          oldTA = TA;
                        end
                      if (addr[1:0] == 2)
                        begin
                          readData[15:8] <= ram_io_r_data[23:16];
                          readData[7:0] <= ram_io_r_data[31:24];
                          newRcounter = 0;
                          rdrAddr = addr;
                          oldTA = TA;
                        end
                      if (addr[1:0] == 3)
                        begin
                          readData[15:8] <= ram_io_r_data[31:24];
                          //readData[7:0] <= ram_io_r_data[31:24];
                          // Dont change newRcounter so it will continue to the next cylce
                        end
                    end
                  
                  if (reqSize == 2)// 4 byte read
                    begin
                      if (addr[1:0] == 0)
                        begin
                          readData[31:24] <= ram_io_r_data[7:0];
                          readData[23:16] <= ram_io_r_data[15:8];
                          readData[15:8] <= ram_io_r_data[23:16];
                          readData[7:0] <= ram_io_r_data[31:24];
                          newRcounter = 0;
                          rdrAddr = addr;
                      	  oldTA = TA;
                        end
                      if (addr[1:0] == 1)
                        begin
                          readData[31:24] <= ram_io_r_data[15:8];
                          readData[23:16] <= ram_io_r_data[23:16];
                          readData[15:8] <= ram_io_r_data[31:24];
                          //readData[7:0] <= ram_io_r_data[31:24];
                          // Dont change newRcounter so it will continue to the next cylce
                        end
                      if (addr[1:0] == 2)
                        begin
                          readData[31:24] <= ram_io_r_data[23:16];
                          readData[23:16] <= ram_io_r_data[31:24];
                          //readData[15:8] <= ram_io_r_data[23:16];
                          //readData[7:0] <= ram_io_r_data[31:24];
                          // Dont change newRcounter so it will continue to the next cylce
                        end
                      if (addr[1:0] == 3)
                        begin
                          readData[31:24] <= ram_io_r_data[31:24];
                          //readData[23:16] <= ram_io_r_data[15:8];
                          //readData[15:8] <= ram_io_r_data[23:16];
                          //readData[7:0] <= ram_io_r_data[31:24];
                          // Dont change newRcounter so it will continue to the next cylce
                        end
                      
                    end
                  
                  if (newRcounter != 0)
                    begin
                      ram_io_addr = (addr >> 2)+1;
                    end
                end
              
              // Cycle 2
              if (Rcounter == 2)
                begin
                  if (reqSize == 1)// 2 byte read
                    begin
                      if (addr[1:0] == 3)
                        begin
                          readData[7:0] <= ram_io_r_data[7:0];
                        end
                    end
                  
                  if (reqSize == 2)// 4 byte read
                    begin
                      if (addr[1:0] == 1)
                        begin
                          readData[7:0] <= ram_io_r_data[7:0];
                        end
                      if (addr[1:0] == 2)
                        begin
                          readData[15:8] <= ram_io_r_data[7:0];
                          readData[7:0] <= ram_io_r_data[15:8];
                        end
                      if (addr[1:0] == 3)
                        begin
                          readData[23:16] <= ram_io_r_data[7:0];
                          readData[15:8] <= ram_io_r_data[15:8];
                          readData[7:0] <= ram_io_r_data[23:16];
                        end
                      
                    end
                  
                  rdrAddr = addr;
                  oldTA = TA;
                  newRcounter = 0;
                end
              
              // Set new Rcounter
              Rcounter = newRcounter;
            end
          else
            begin
              // Start Write
              if (Rcounter == 0 && oldTA != TA)
                begin
                  newRcounter = Rcounter + 1;
                  if (reqSize == 2 && addr[1:0] == 0)
                    begin
                      // No need to read memory first as we can directly write
                      ram_io_addr = addr >> 2;
                      ram_io_w_data = 0;
                      ram_io_w_data[31:24] = writeData[7:0];
                      ram_io_w_data[23:16] = writeData[15:8];
                      ram_io_w_data[15:8] = writeData[23:16];
                      ram_io_w_data[7:0] = writeData[31:24];
                      ram_io_w_we = 1;
                      wrrAddr = addr;
                      oldTA = TA;
                      newRcounter = 0;
                    end
                  else
                    begin
                      ram_io_w_we = 0;
                      ram_io_addr = addr >> 2;
                    end
                end
              
              // Cycle 1
              if (Rcounter == 1)
                begin
                  ram_io_w_data = ram_io_r_data;
                  newRcounter = Rcounter + 1;
                  
                  if (reqSize == 0)
                    begin
                      if (addr[1:0] == 0)
                        begin
                          ram_io_w_data[7:0] = writeData[7:0];
                        end
                      if (addr[1:0] == 1)
                        begin
                          ram_io_w_data[15:8] = writeData[7:0];
                        end
                      if (addr[1:0] == 2)
                        begin
                          ram_io_w_data[23:16] = writeData[7:0];
                        end
                      if (addr[1:0] == 3)
                        begin
                          ram_io_w_data[31:24] = writeData[7:0];
                        end
                      wrrAddr = addr;
                      oldTA = TA;
                      newRcounter = 0;
                      
                      ram_io_addr = addr >> 2;
                  	  ram_io_w_we = 1;
                    end
                  
                  if (reqSize == 1)
                    begin
                      if (addr[1:0] == 0)
                        begin
                          ram_io_w_data[7:0] = writeData[15:8];
                          ram_io_w_data[15:8] = writeData[7:0];
                          wrrAddr = addr;
                          oldTA = TA;
                          newRcounter = 0;
                          
                          ram_io_addr = addr >> 2;
                  		  ram_io_w_we = 1;
                        end
                      if (addr[1:0] == 1)
                        begin
                          ram_io_w_data[15:8] = writeData[15:8];
                          ram_io_w_data[23:16] = writeData[7:0];
                          wrrAddr = addr;
                          oldTA = TA;
                          newRcounter = 0;
                          
                          ram_io_addr = addr >> 2;
                  		  ram_io_w_we = 1;
                        end
                      if (addr[1:0] == 2)
                        begin
                          ram_io_w_data[23:16] = writeData[15:8];
                          ram_io_w_data[31:24] = writeData[7:0];
                          wrrAddr = addr;
                          oldTA = TA;
                          newRcounter = 0;
                          
                          ram_io_addr = addr >> 2;
                  		  ram_io_w_we = 1;
                        end
                      if (addr[1:0] == 3)
                        begin
                          ram_io_w_data[31:24] = writeData[15:8];
                          //ram_io_w_data[31:24] = writeData[7:0];
                          /*wrrAddr = addr;
                          oldTA = TA;
                          newRcounter = 0;*/
                          
                          ram_io_addr = addr >> 2;
                  		  ram_io_w_we = 1;
                        end
                      
                    end
                  
                  if (reqSize == 2)
                    begin
                      if (addr[1:0] == 1)
                        begin
                          ram_io_w_data[15:8] = writeData[31:24];
                          ram_io_w_data[23:16] = writeData[23:16];
                          ram_io_w_data[31:24] = writeData[15:8];
                          /*wrrAddr = addr;
                          oldTA = TA;
                          newRcounter = 0;*/
                          
                          ram_io_addr = addr >> 2;
                  		  ram_io_w_we = 1;
                        end
                      if (addr[1:0] == 2)
                        begin
                          ram_io_w_data[23:16] = writeData[31:24];
                          ram_io_w_data[31:24] = writeData[23:16];
                          //ram_io_w_data[31:24] = writeData[15:8];
                          /*wrrAddr = addr;
                          oldTA = TA;
                          newRcounter = 0;*/
                          
                          ram_io_addr = addr >> 2;
                  		  ram_io_w_we = 1;
                        end
                      if (addr[1:0] == 3)
                        begin
                          ram_io_w_data[31:24] = writeData[31:24];
                          //ram_io_w_data[23:16] = writeData[23:16];
                          //ram_io_w_data[31:24] = writeData[15:8];
                          /*wrrAddr = addr;
                          oldTA = TA;
                          newRcounter = 0;*/
                          
                          ram_io_addr = addr >> 2;
                  		  ram_io_w_we = 1;
                        end
                    end
                end
              
              // Cycle 2
              if (Rcounter == 2)
                begin
                  newRcounter = Rcounter + 1;
                  
                  ram_io_w_we = 0;
                  ram_io_addr = (addr >> 2) + 1;
                end
              
              if (Rcounter == 3)
                begin
                  newRcounter = 0;
                  ram_io_w_data = ram_io_r_data;
                  
                  if (reqSize == 1)
                    begin
                      if (addr[1:0] == 3)
                        begin
                          ram_io_w_data[7:0] = writeData[7:0];
                        end
                    end
                  if (reqSize == 2)
                    begin
                      if (addr[1:0] == 1)
                        begin
                          ram_io_w_data[7:0] = writeData[7:0];
                        end
                      if (addr[1:0] == 2)
                        begin
                          ram_io_w_data[7:0] = writeData[15:8];
                          ram_io_w_data[15:8] = writeData[7:0];
                        end
                      if (addr[1:0] == 3)
                        begin
                          ram_io_w_data[7:0] = writeData[23:16];
                          ram_io_w_data[15:8] = writeData[15:8];
                          ram_io_w_data[23:16] = writeData[7:0];
                        end
                    end
                  
                  ram_io_addr = (addr >> 2)+1;
                  ram_io_w_we = 1;
                  
                  wrrAddr = addr;
                  oldTA = TA;
                  newRcounter = 0;
                end
              
              Rcounter = newRcounter;
            end
        end
      else
        begin
          Rcounter = 0;
        end
    end
  
endmodule

module RISCVBasicMMU(
  input clk,
  
  output reg [7:0]ram_io_w_data = 0,
  output reg [`ramAddrSize:0]ram_io_addr = 0,
  input wire [7:0]ram_io_r_data,
  output reg ram_io_w_we = 0,
  
  input wire [`mmuAddrSize:0]addr,
  input wire [1:0]reqSize,// 0=1b 1=2b 2=4b
  input wire [31:0]writeData,
  output reg [31:0]readData = 0,
  input wire rw,// 0=read; 1=write
  output reg [`mmuAddrSize:0]rdrAddr = 0,
  output reg [`mmuAddrSize:0]wrrAddr = 0,
  
  input activate,
  input TA,
  output reg oldTA = 0
);
  
  reg [7:0]Rcounter = 0;
  reg [7:0]newRcounter = 0;
  
  always @(posedge clk)
    begin
      if (activate)
        begin
          if (rw == 0)
            begin
              // Start Read
              if (Rcounter == 0 && oldTA != TA)
                begin
                  newRcounter = Rcounter + 1;
                  ram_io_w_we = 0;
                  ram_io_addr = addr;
                  readData = 0;
                end

              // Cycle 1
              else if (Rcounter == 1)
                begin
                  newRcounter = Rcounter + 1;
                  if (reqSize == 0)// 1 byte read
                    begin
                      readData = ram_io_r_data;
                      rdrAddr = addr;
                      oldTA = TA;
                      newRcounter = 0;
                    end
                  else if (reqSize == 1)// 2 byte read
                    begin
                      readData[15:8] = ram_io_r_data;
                      ram_io_addr = addr+1;
                    end
                  else if (reqSize == 2)// 4 byte read
                    begin
                      readData[31:24] = ram_io_r_data;
                      ram_io_addr = addr+1;
                    end
                end

              // Cycle 2
              else if (Rcounter == 2)
                begin
                  newRcounter = Rcounter + 1;
                  if (reqSize == 1)// 2 byte read
                    begin
                      readData[7:0] = ram_io_r_data;
                      rdrAddr = addr;
                      oldTA = TA;
                      newRcounter = 0;
                    end
                  else if (reqSize == 2)// 4 byte read
                    begin
                      readData[23:16] = ram_io_r_data;
                      ram_io_addr = addr+2;
                    end
                end

              // Cycle 3
              else if (Rcounter == 3)
                begin
                  newRcounter = Rcounter + 1;
                  if (reqSize == 2)// 4 byte read
                    begin
                      readData[15:8] = ram_io_r_data;
                      ram_io_addr = addr+3;
                    end
                end

              // Cycle 4
              else if (Rcounter == 4)
                begin
                  newRcounter = Rcounter + 1;
                  if (reqSize == 2)// 4 byte read
                    begin
                      readData[7:0] = ram_io_r_data;
                      rdrAddr = addr;
                      oldTA = TA;
                      newRcounter = 0;
                    end
                end
              Rcounter = newRcounter;
            end
          else
            begin
              // Start Write
              if (Rcounter == 0 && oldTA != TA)
                begin
                  if (addr == 2049)
                    begin
                      $display("%c", writeData);
                    end
                  newRcounter = Rcounter + 1;
                  ram_io_addr = addr;
                  ram_io_w_we = 1;
                  `dbg($display("Write: %d to %h", writeData, ram_io_addr));
                  if (reqSize == 0)// 1 byte write
                    begin
                      ram_io_w_data = writeData[7:0];
                      wrrAddr = ram_io_addr;
                      oldTA = TA;
                      newRcounter = 0;
                    end
                  else if (reqSize == 1)// 2 byte write
                    begin
                      ram_io_w_data = writeData[15:8];
                    end
                  else if (reqSize == 2)// 4 byte write
                    begin
                      ram_io_w_data = writeData[31:24];
                    end
                end
              
              // Cycle 1
              if (Rcounter == 1)
                begin
                  newRcounter = Rcounter + 1;
                  ram_io_addr = addr+1;
                  if (reqSize == 1)// 2 byte write
                    begin
                      ram_io_w_data = writeData[7:0];
                      wrrAddr = addr;
                      oldTA = TA;
                      newRcounter = 0;
                    end
                  else if (reqSize == 2)// 4 byte write
                    begin
                      ram_io_w_data = writeData[23:16];
                    end
                end
              
              // Cycle 2
              if (Rcounter == 2)
                begin
                  newRcounter = Rcounter + 1;
                  ram_io_addr = addr+2;
                  if (reqSize == 2)// 4 byte write
                    begin
                      ram_io_w_data = writeData[15:8];
                    end
                end
              
              // Cycle 3
              if (Rcounter == 3)
                begin
                  newRcounter = Rcounter + 1;
                  ram_io_addr = addr+3;
                  if (reqSize == 2)// 4 byte write
                    begin
                      ram_io_w_data = writeData[7:0];
                      wrrAddr = addr;
                      oldTA = TA;
                      newRcounter = 0;
                    end
                end
              Rcounter = newRcounter;
            end
        end
      else
        begin
          Rcounter = 0;
        end
    end
  
endmodule



module RISCVCore(
  `ifndef edpg
  input CLK
  `endif
);
  `ifdef edpg
  reg CLK = 0;// System clock
  `endif
  
  // Cpu registers
  reg [31:0]registers[0:31];
  reg [31:0]counter = 0;
  reg [31:0]newCounter = 0;
  
  reg [31:0]PC = 32'h00000000;
  reg [31:0]newPC = PC;
  
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
  reg [11:0]StypeIMM = 0;
  reg [31:0]UtypeIMM = 0;
  reg [12:0]BtypeIMMBranch = 0;
  
  reg [31:0]ItypeIMMSignExtended = 0;
  reg [31:0]JtypeIMMSignExtended = 0;
  reg [31:0]StypeIMMSignExtended = 0;
  reg [31:0]BtypeIMMBranchSignExtended = 0;
  
  reg [31:0]rdReg = 0;
  reg [31:0]rs1Reg = 0;
  reg [31:0]rs2Reg = 0;
  
  reg validInstr = 0;
  
  reg EBREAKcalled = 0;
  // Debugging:
  reg doneExecutingInstr = 0;
  
  // Ram bus
  // for 8 bit
  /*wire [7:0]ram_io_w_data;
  wire [`ramAddrSize:0]ram_io_addr;
  wire [7:0]ram_io_r_data;
  wire ram_io_w_we;*/
  
  // for 32 bit
  wire [31:0]ram_io_w_data;
  wire [`ramAddrSize:0]ram_io_addr;
  wire [31:0]ram_io_r_data;
  wire ram_io_w_we;
  
  reg [`mmuAddrSize:0]addr = 0;
  reg [1:0]reqSize = 0;// 0=1b 1=2b 3=4b
  reg [31:0]writeData = 0;
  wire [31:0]readData;
  reg rw = 0;// 0=read; 1=write
  wire [`mmuAddrSize:0]rdrAddr;
  wire [`mmuAddrSize:0]wrrAddr;
  reg activate = 0;
  reg TA = 0;
  wire oldTA;
  
  RISCVBasicMMU32 rvmmu(
    CLK,
    
    ram_io_w_data,
    ram_io_addr,
    ram_io_r_data,
    ram_io_w_we,
    
    addr,
    reqSize,
    writeData,
    readData,
    rw,
    rdrAddr,
    wrrAddr,
    
    activate,
    TA,
    oldTA
  );
  
  single_port_ram #(.DATA_WIDTH(32), .ADDR_WIDTH(`ramAddrSize+1)) ram(
    ram_io_w_data,
    ram_io_addr,
    ram_io_w_we,
    CLK,
    ram_io_r_data
  );
  
  initial begin
    `ifdef edpg
    $dumpfile("dump.vcd");
    $dumpvars;
    `endif
    
    for (int i = 0; i < 32; i++)
      begin
        registers[i] = 0;
      end
    `ifdef edpg
    registers[2] = 32'h0000ffff;
    `else
    registers[2] = 2800000;
    `endif
    `ifdef edpg
    for (int i = 0; i < 100; i = i+1)
      begin
        #10 CLK = 1;
        #10 CLK = 0;
      end
    `endif
    EBREAKcalled = 0;
  end
  
  always @(posedge CLK)
    begin
      
      if (counter == 0 && `waitforram)// Make sure no memory operation is busy before continuing
        begin
          addr = PC;
          reqSize = 2;
          rw = 0;
          activate = 1;
          TA = ~oldTA;
          newCounter = counter + 1;
        end
        
      if (counter == 1 && `waitforram)
        begin
          instr = {readData[7:0], readData[15:8], readData[23:16], readData[31:24]};
          
          op <= instr[6:0];
          funct3 <= instr[14:12];
          funct7 <= instr[31:25];
          rd = instr[11:7];
          rs1 = instr[19:15];
          rs2 = instr[24:20];
          ItypeIMM = instr[31:20];
          JtypeIMM = {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
          StypeIMM = {instr[31:25], instr[11:7]};
          UtypeIMM[31:12] = instr[31:12];// 12bit offset
          UtypeIMM[11:0] = 0;
          BtypeIMMBranch = {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
          
          ItypeIMMSignExtended = {{20{ItypeIMM[11]}}, ItypeIMM};
          JtypeIMMSignExtended = {{11{JtypeIMM[20]}}, JtypeIMM};
          StypeIMMSignExtended = {{20{StypeIMM[11]}}, StypeIMM};
          BtypeIMMBranchSignExtended = {{20{BtypeIMMBranch[12]}}, BtypeIMMBranch};
          `dbg($display("instr: %h", instr));
          `dbg($display("PC: %d instr: %b op: %h funct3: %h rd: %d rs1: %d rs2: %d ItypeIMM: %d JtypeIMM: %d StypeIMM: %d Bsx: %d \n		x1: %d x2: %d a0(x10): %d",
                        PC, instr, op, funct3, rd, rs1, rs2, ItypeIMM, JtypeIMM, StypeIMM, $signed(BtypeIMMBranchSignExtended), registers[1], registers[2], registers[10]));
          
          
          rdReg = registers[rd];
          rs1Reg = registers[rs1];
          rs2Reg = registers[rs2];
          newCounter = 2;
        end
      
      if (counter == 2)
        begin
          
          newPC = PC + 4;
          validInstr = 0;
          newCounter = 3;
          `dbg($display("rdReg: %d rs1Reg: %d rs2Reg: %d", rdReg, rs1Reg, rs2Reg));
          
          if (op == 7'b0010011)// Math immediate
            begin
              if (funct3 == 3'b000)// ADDI
                begin
                  `dbg($display("ADDI"));
                  rdReg = rs1Reg+ItypeIMMSignExtended;
                  
                  validInstr = 1;
                end
              else if (funct3 == 3'b010)// SLTI
                begin
                  `dbg($display("SLTI"));
                  rdReg = ($signed(rs1Reg) < $signed(ItypeIMMSignExtended));
                  
                  validInstr = 1;
                end
              else if (funct3 == 3'b011)// SLTIU
                begin
                  `dbg($display("SLTIU"));
                  rdReg = (rs1Reg<ItypeIMMSignExtended);
                  
                  validInstr = 1;
                end
              else if (funct3 == 3'b100)// XORI
                begin
                  `dbg($display("XORI"));
                  rdReg = (rs1Reg ^ ItypeIMMSignExtended);
                  
                  validInstr = 1;
                end
              else if (funct3 == 3'b110)// ORI
                begin
                  `dbg($display("ORI"));
                  rdReg = (rs1Reg | ItypeIMMSignExtended);
                  
                  validInstr = 1;
                end
              else if (funct3 == 3'b111)// ANDI
                begin
                  `dbg($display("ANDI"));
                  rdReg = (rs1Reg & ItypeIMMSignExtended);
                  
                  validInstr = 1;
                end
              else if (funct3 == 3'b001)// SLLI
                begin
                  if (funct7 == 7'b0000000)
                    begin
                      `dbg($display("SLLI"));
                      rdReg = (rs1Reg << ItypeIMMSignExtended[4:0]);

                      validInstr = 1;
                    end
                end
              else if (funct3 == 3'b101)
                begin
                  if (funct7 == 7'b0000000)// SRLI
                    begin
                      `dbg($display("SRLI"));
                      rdReg = (rs1Reg >> ItypeIMMSignExtended[4:0]);

                      validInstr = 1;
                    end
                  else if (funct7 == 7'b0100000)// SRAI
                    begin
                      `dbg($display("SRAI"));
                      rdReg = ($signed(rs1Reg) >>> ItypeIMMSignExtended[4:0]);

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
                      `dbg($display("ADD"));
                      rdReg = rs1Reg+rs2Reg;

                      validInstr = 1;
                    end
                  else if (funct7 == 7'b0100000)// SUB
                	begin
                      `dbg($display("SUB"));
                      rdReg = rs1Reg-rs2Reg;

                      validInstr = 1;
                    end
                end
              else if (funct3 == 3'b010)
                begin
                  if (funct7 == 7'b0000000)// SLT
                	begin
                      `dbg($display("SLT"));
                      rdReg = ($signed(rs1Reg) < $signed(rs2Reg));

                      validInstr = 1;
                    end
                end
              else if (funct3 == 3'b011)
                begin
                  if (funct7 == 7'b0000000)// SLTU
                	begin
                      `dbg($display("SLTU"));
                      rdReg = (rs1Reg < rs2Reg);

                      validInstr = 1;
                    end
                end
              else if (funct3 == 3'b001)
                begin
                  if (funct7 == 7'b0000000)// SLL
                	begin
                      `dbg($display("SLL"));
                      rdReg = (rs1Reg << rs2Reg[4:0]);

                      validInstr = 1;
                    end
                end
              else if (funct3 == 3'b101)
                begin
                  if (funct7 == 7'b0000000)// SRL
                	begin
                      `dbg($display("SRL"));
                      rdReg = (rs1Reg >> rs2Reg[4:0]);

                      validInstr = 1;
                    end
                  if (funct7 == 7'b0100000)// SRA
                	begin
                      `dbg($display("SRA"));
                      rdReg = ($signed(rs1Reg) >>> rs2Reg[4:0]);

                      validInstr = 1;
                    end
                end
              else if (funct3 == 3'b100)
                begin
                  if (funct7 == 7'b0000000)// XOR
                	begin
                      `dbg($display("XOR"));
                      rdReg = (rs1Reg ^ rs2Reg);

                      validInstr = 1;
                    end
                end
              else if (funct3 == 3'b110)
                begin
                  if (funct7 == 7'b0000000)// OR
                	begin
                      `dbg($display("OR"));
                      rdReg = (rs1Reg | rs2Reg);

                      validInstr = 1;
                    end
                end
              else if (funct3 == 3'b111)
                begin
                  if (funct7 == 7'b0000000)// AND
                	begin
                      `dbg($display("AND"));
                      rdReg = (rs1Reg & rs2Reg);

                      validInstr = 1;
                    end
                end
            end
          
          if (op == 7'b1100011)// Branch instructions
            begin
              if (funct3 == 3'b000)// BEQ
                begin
                  `dbg($display("BEQ"));
                  if (rs1Reg == rs2Reg)
                    begin
                      newPC = PC + BtypeIMMBranchSignExtended;
                    end
                  
                  validInstr = 1;
                end
              else if (funct3 == 3'b001)// BNE
                begin
                  `dbg($display("BNE"));
                  if (rs1Reg != rs2Reg)
                    begin
                      newPC = PC + BtypeIMMBranchSignExtended;
                    end
                  
                  validInstr = 1;
                end
              else if (funct3 == 3'b100)// BLT
                begin
                  `dbg($display("BLT"));
                  if ($signed(rs1Reg) < $signed(rs2Reg))
                    begin
                      newPC = PC + BtypeIMMBranchSignExtended;
                    end
                  
                  validInstr = 1;
                end
              else if (funct3 == 3'b101)// BGE
                begin
                  `dbg($display("BGE"));
                  if ($signed(rs1Reg) >= $signed(rs2Reg))
                    begin
                      newPC = PC + BtypeIMMBranchSignExtended;
                    end
                  
                  validInstr = 1;
                end
              else if (funct3 == 3'b110)// BLTU
                begin
                  `dbg($display("BLTU"));
                  if (rs1Reg < rs2Reg)
                    begin
                      newPC = PC + BtypeIMMBranchSignExtended;
                    end
                  
                  validInstr = 1;
                end
              else if (funct3 == 3'b111)// BGEU
                begin
                  `dbg($display("BGEU"));
                  if (rs1Reg >= rs2Reg)
                    begin
                      newPC = PC + BtypeIMMBranchSignExtended;
                    end
                  
                  validInstr = 1;
                end
            end
          
          else if (op == 7'b1101111)// JAL
            begin
              `dbg($display("JAL"));
              rdReg = PC + 4;
              newPC = PC + JtypeIMMSignExtended;
              
              validInstr = 1;
            end
          
          else if (op == 7'b1100111)// JALR
            begin
              if (funct3 == 3'b000)
                begin
                  `dbg($display("JALR"));
                  rdReg = PC + 4;
                  newPC = (rs1Reg + ItypeIMMSignExtended);// todo fix me fixme

                  validInstr = 1;
                end
            end
          
          else if (op == 7'b0100011)// Store instructions
            begin
              if (funct3 == 3'b010)// SW
                begin
                  `dbg($display("SW"));
                  addr = StypeIMMSignExtended+rs1Reg;
                  reqSize = 2;
                  rw = 1;
                  writeData = {rs2Reg[7:0], rs2Reg[15:8], rs2Reg[23:16], rs2Reg[31:24]};
                  activate = 1;
                  TA = ~oldTA;
                  //newCounter = counter + 1;

                  validInstr = 1;
                end
              else if (funct3 == 3'b001)// SH
                begin
                  `dbg($display("SH"));
                  addr = StypeIMMSignExtended+rs1Reg;
                  reqSize = 1;
                  rw = 1;
                  writeData = {rs2Reg[7:0], rs2Reg[15:8]};
                  activate = 1;
                  TA = ~oldTA;
                  //newCounter = counter + 1;

                  validInstr = 1;
                end
              else if (funct3 == 3'b000)// SB
                begin
                  `dbg($display("SB"));
                  addr = StypeIMMSignExtended+rs1Reg;
                  reqSize = 0;
                  rw = 1;
                  writeData = rs2Reg[7:0];
                  activate = 1;
                  TA = ~oldTA;
                  //newCounter = counter + 1;

                  validInstr = 1;
                end
            end
          
          else if (op == 7'b0000011)// Load instructions
            begin
              if (funct3 == 3'b010)// LW
                begin
                  `dbg($display("LW"));
                  addr = ItypeIMMSignExtended+rs1Reg;
                  reqSize = 2;
                  rw = 0;
                  activate = 1;
                  TA = ~oldTA;
                  newCounter = 4;

                  validInstr = 1;
                end
              else if (funct3 == 3'b001)// LH
                begin
                  `dbg($display("LH"));
                  addr = ItypeIMMSignExtended+rs1Reg;
                  reqSize = 1;
                  rw = 0;
                  activate = 1;
                  TA = ~oldTA;
                  newCounter = 4;

                  validInstr = 1;
                end
              else if (funct3 == 3'b000)// LB
                begin
                  `dbg($display("LB"));
                  addr = ItypeIMMSignExtended+rs1Reg;
                  reqSize = 0;
                  rw = 0;
                  activate = 1;
                  TA = ~oldTA;
                  newCounter = 4;

                  validInstr = 1;
                end
              else if (funct3 == 3'b101)// LHU
                begin
                  `dbg($display("LHU"));
                  addr = ItypeIMMSignExtended+rs1Reg;
                  reqSize = 1;
                  rw = 0;
                  activate = 1;
                  TA = ~oldTA;
                  newCounter = 4;

                  validInstr = 1;
                end
              else if (funct3 == 3'b100)// LBU
                begin
                  `dbg($display("LBU"));
                  addr = ItypeIMMSignExtended+rs1Reg;
                  reqSize = 0;
                  rw = 0;
                  activate = 1;
                  TA = ~oldTA;
                  newCounter = 4;

                  validInstr = 1;
                end
            end
          
          else if (op == 7'b0110111)// LUI
            begin
              `dbg($display("LUI"));
              rdReg[31:12] = UtypeIMM[31:12];
              rdReg[11:0] = 0;

              validInstr = 1;
            end
          
          else if (op == 7'b0010111)// AUIPC
            begin
              `dbg($display("AUIPC"));
              rdReg = PC + UtypeIMM;

              validInstr = 1;
            end
          
          else if (instr == 32'b00000000000100000000000001110011)// EBREAK
            begin
              `dbgINV($display("EBREAK from 0x%h", PC));
              EBREAKcalled = 1;
              
              validInstr = 1;
            end
          else if (instr == 32'b00000000000000000000000001110011)// ECALL
            begin
              `dbgINV($display("ECALL from 0x%h, IGNORED!", PC));
              
              validInstr = 1;
            end
          
          else if (op == 7'b0001111)
            begin
              if (funct3 == 3'b000)// FENCE
                begin
                  `dbg($display("FENCE"));
                  // Implemented as NOP because this core currently doesn't require it.

                  validInstr = 1;
                end
              else if (funct3 == 3'b001)// FENCE.I
                begin
                  `dbg($display("FENCE.I"));
                  // Implemented as NOP because this core currently doesn't require it.

                  validInstr = 1;
                end
            end
          
          if (!validInstr)// Instruction not found, print message and continue
            begin
              `dbgINV($display("INV PC: %d(0x%h) instr: %h", PC, PC, instr));
            end
          
        end
        
      if (counter == 3)
        begin
          registers[rd] = rdReg;
          `dbg($display("New rd: %d", rdReg));
          registers[0] = 0;
          doneExecutingInstr = ~doneExecutingInstr;
          newCounter = 0;
        end
      
      if (counter == 4 && `waitforram)
        begin
          newCounter = 0;
          if (op == 7'b0000011)// Load instructions
            begin
              if (funct3 == 3'b010)// LW
                begin
                  //`dbg($display("LW late"));
                  rdReg = {readData[7:0], readData[15:8], readData[23:16], readData[31:24]};
                end
              else if (funct3 == 3'b001)// LH
                begin
                  //`dbg($display("LH"));
                  rdReg = {{16{readData[7]}}, 
                           readData[7:0], 
                           readData[15:8]};
                end
              else if (funct3 == 3'b000)// LB
                begin
                  //`dbg($display("LB"));
                  rdReg = {{24{readData[7]}}, 
                          readData[7:0]};
                end
              else if (funct3 == 3'b101)// LHU
                begin
                  //`dbg($display("LHU"));
                  rdReg = {readData[7:0], readData[15:8]};
                end
              else if (funct3 == 3'b100)// LBU
                begin
                  //`dbg($display("LBU finish"));
                  rdReg = readData[7:0];
                end
              else
                begin
                  `dbgINV($display("INV Second Stage Instr: %d(0x%h) instr: %h", PC, PC, instr));
                end
            end
          else
            begin
              `dbgINV($display("INV Second Stage Instr: %d(0x%h) instr: %h", PC, PC, instr));
            end
          registers[rd] = rdReg;
          `dbg($display("New rd(second stage): %d", rdReg));
          doneExecutingInstr = ~doneExecutingInstr;
      end
      
      counter = newCounter;
      PC = newPC;
    end
  
endmodule

