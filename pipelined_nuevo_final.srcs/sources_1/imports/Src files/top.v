// Modulo superior (Top)
// Conecta el procesador RISC-V con la memoria de instrucciones y datos
module top #(parameter MEM_FILE = "riscvtest.mem") (
  input        clk, reset,
  output [31:0] WriteData, DataAdr,
  output        MemWrite,
  
  // ---- Instrucciones propagadas para depuracion ----
  output [31:0] InstrF,
  output [31:0] InstrD,
  output [31:0] InstrE,
  output [31:0] InstrM,
  output [31:0] InstrW
);

  wire [31:0] PC, Instr, ReadData;

  riscvpipelined rvpipelined(
    .clk(clk),      .reset(reset),
    .PC(PC),        .Instr(Instr),
    .MemWrite(MemWrite),
    .DataAdr(DataAdr), .WriteData(WriteData),
    .ReadData(ReadData),
    .InstrF(InstrF), .InstrD(InstrD), .InstrE(InstrE), 
    .InstrM(InstrM), .InstrW(InstrW)
  );

  imem #(.MEM_FILE(MEM_FILE)) imem(.a(PC), .rd(Instr));

  dmem dmem(
    .clk(clk), .we(MemWrite),
    .a(DataAdr), .wd(WriteData), .rd(ReadData)
  );
endmodule