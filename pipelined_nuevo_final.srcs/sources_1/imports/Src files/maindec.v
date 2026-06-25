// Controlador principal
// Decodifica la instruccion y genera senales de control
module maindec(input  [6:0] op,
               input [2:0] funct3,
               output [1:0] ResultSrc,
               output MemWrite,
               output BranchE, BranchNE, ALUSrc,
               output RegWrite, Jump, Jalr,
               output [2:0] ImmSrc,
               output [1:0] ALUOp);

  reg [13:0] controls;

  assign {RegWrite, ImmSrc, ALUSrc, MemWrite,
          ResultSrc, BranchE, BranchNE, ALUOp, Jump,  Jalr } = controls;

  always @* case(op)
    // RegWrite_ImmSrc[2:0]_ALUSrc_MemWrite_ResultSrc_BranchE_BranchNE_ALUOp_Jump_Jalr
      7'b0000011: controls = 14'b1_000_1_0_01_0_0_00_0_0; // lw
      7'b0100011: controls = 14'b0_001_1_1_00_0_0_00_0_0; // sw
      7'b0110011: controls = 14'b1_0xx_0_0_00_0_0_10_0_0; // Tipo-R
      7'b1100011:   case(funct3)
                        3'b000: // beq
                            controls = 14'b0_010_0_0_00_1_0_01_0_0;
                        3'b001: // bne
                            controls = 14'b0_010_0_0_00_0_1_01_0_0;
                        default:
                            controls = 14'b0_000_0_0_00_0_0_00_0_0;
                    endcase
      7'b0010011: controls = 14'b1_000_1_0_00_0_0_10_0_0; // Tipo-I ALU
      7'b1101111: controls = 14'b1_011_0_0_10_0_0_00_1_0; // jal
      7'b1100111: controls = 14'b1_000_0_0_10_0_0_00_0_1; // jalr
      7'b0110111: controls = 14'b1_100_0_0_11_0_0_00_0_0; // lui
      default:    controls = 14'b0_000_0_0_00_0_0_00_0_0; // NOP / indefinido
    endcase
endmodule