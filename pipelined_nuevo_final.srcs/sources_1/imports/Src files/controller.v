// Controlador principal y decodificador ALU
module controller(
  input  [6:0] op,
  input  [2:0] funct3,
  input        funct7b5,
  output [1:0] ResultSrc,
  output       MemWrite,
  output       ALUSrc,
  output       RegWrite, Jump, Jalr, BranchE, BranchNE,
  output [2:0] ImmSrc,
  output [3:0] ALUControl
);

  wire [1:0] ALUOp;

  maindec md(
    .op(op),
    .funct3(funct3),
    .ResultSrc(ResultSrc), .MemWrite(MemWrite),
    .BranchE(BranchE), .BranchNE(BranchNE), .ALUSrc(ALUSrc),
    .RegWrite(RegWrite),   .Jump(Jump), .Jalr(Jalr),
    .ImmSrc(ImmSrc),       .ALUOp(ALUOp)
  );

  aludec ad(
    .opb5(op[5]),
    .funct3(funct3),
    .funct7b5(funct7b5),
    .ALUOp(ALUOp),
    .ALUControl(ALUControl)
  );

endmodule
