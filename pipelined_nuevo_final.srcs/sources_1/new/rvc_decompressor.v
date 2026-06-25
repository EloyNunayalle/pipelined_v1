module rvc_decompressor(
    input  [31:0] instr_in,
    output reg [31:0] instr_out,
    output is_compressed
);

    //=========================================================
    // Detección de instrucción comprimida
    //=========================================================

    assign is_compressed = (instr_in[1:0] != 2'b11);

    //=========================================================
    // Campos básicos
    //=========================================================

    wire [15:0] cinstr;

    wire [1:0] quadrant;
    wire [2:0] funct3;

    assign cinstr   = instr_in[15:0];
    assign quadrant = cinstr[1:0];
    assign funct3   = cinstr[15:13];

    //=========================================================
    // Campos de función (según formato RVC)
    //=========================================================

    // Formato CB (SRLI, SRAI, ANDI)
    wire [1:0] cb_funct2;

    // Formato CA (SUB, XOR, OR, AND)
    wire [1:0] ca_funct2;

    // Formato CR (JR, JALR, ADD)
    wire [3:0] cr_funct4;

    // Formato CA
    wire [5:0] ca_funct6;

    assign cb_funct2 = cinstr[11:10];
    assign ca_funct2 = cinstr[6:5];
    assign cr_funct4 = cinstr[15:12];
    assign ca_funct6 = cinstr[15:10];

    //=========================================================
    // Registros normales
    //=========================================================

    wire [4:0] rd;
    wire [4:0] rs1;
    wire [4:0] rs2;

    assign rd  = cinstr[11:7];
    assign rs1 = cinstr[11:7];
    assign rs2 = cinstr[6:2];

    //=========================================================
    // Registros comprimidos (x8-x15)
    //=========================================================

    wire [4:0] rd_c;
    wire [4:0] rs1_c;
    wire [4:0] rs2_c;

    assign rd_c  = {2'b01, cinstr[4:2]};
    assign rs1_c = {2'b01, cinstr[9:7]};
    assign rs2_c = {2'b01, cinstr[4:2]};
    
    // immediatos complicados
    wire [12:0] imm_cb;

    assign imm_cb = {
        {4{cinstr[12]}},   // imm[12:9] (extensión de signo)
        cinstr[12],        // imm[8]
        cinstr[6],         // imm[7]
        cinstr[5],         // imm[6]
        cinstr[2],         // imm[5]
        cinstr[11],        // imm[4]
        cinstr[10],        // imm[3]
        cinstr[4],         // imm[2]
        cinstr[3],         // imm[1]
        1'b0               // imm[0]
    };
    
    wire [20:0] imm_cj;
    
    assign imm_cj = {
        {9{cinstr[12]}},   // imm[20:12] (extensión de signo)
        cinstr[12],        // imm[11]
        cinstr[8],         // imm[10]
        cinstr[10],        // imm[9]
        cinstr[9],         // imm[8]
        cinstr[6],         // imm[7]
        cinstr[7],         // imm[6]
        cinstr[2],         // imm[5]
        cinstr[11],        // imm[4]
        cinstr[5],         // imm[3]
        cinstr[4],         // imm[2]
        cinstr[3],         // imm[1]
        1'b0               // imm[0]
    };

    //=========================================================
    // Descompresión
    //=========================================================

    always @* begin

        // Instrucción RV32I normal
        if (!is_compressed) begin
            instr_out = instr_in;
        end

        // Instrucción RVC
        else begin

            case (quadrant)

            //=================================================
            // QUADRANT 0 (C0)
            //=================================================

            2'b00: begin

                case (funct3)

                    3'b010: // c.lw
                        instr_out = {
                            {5'b00000, cinstr[5], cinstr[12:10], cinstr[6], 2'b00},
                            rs1_c,
                            3'b010,
                            rd_c,
                            7'b0000011
                        }; 

                    3'b110: // c.sw
                        instr_out = {
                            {5'b00000, cinstr[5], cinstr[12]},
                            rs2_c,
                            rs1_c,
                            3'b010,
                            {cinstr[11:10], cinstr[6], 2'b00},
                            7'b0100011
                        };
                        
                    default:
                        instr_out = 32'h00000013;

                endcase

            end

            //=================================================
            // QUADRANT 1 (C1)
            //=================================================

            2'b01: begin

                case (funct3)

                    3'b000:  // c.addi
                        instr_out = {
                            {{6{cinstr[12]}}, cinstr[12], cinstr[6:2]},
                            rd,
                            3'b000,
                            rd,
                            7'b0010011
                        };
                       
                    3'b001: // c.jal
                        instr_out = {
                            imm_cj[20],
                            imm_cj[10:1],
                            imm_cj[11],
                            imm_cj[19:12],
                            5'd1,              // rd = x1 (ra)
                            7'b1101111
                        };
                        
                    3'b011: // c.lui
                        if (rd == 5'd2)
                            instr_out = 32'h00000013;   // c.addi16sp no soportado
                        else begin
                            instr_out = {
                                {{15{cinstr[12]}}, cinstr[12], cinstr[6:2]},
                                rd,
                                7'b0110111
                            };
                        end
                        
                    3'b100: begin

                        case (cb_funct2)

                            2'b00: // c.srli
                                instr_out = {
                                    7'b0000000,
                                    cinstr[12],
                                    cinstr[6:2],
                                    rs1_c,
                                    3'b101,
                                    rs1_c,
                                    7'b0010011
                                };
                          
                            2'b01: // c.srai
                                instr_out = {
                                    7'b0100000,
                                    cinstr[12],
                                    cinstr[6:2],
                                    rs1_c,
                                    3'b101,
                                    rs1_c,
                                    7'b0010011
                                };
                                
                            2'b10: // c.andi
                                instr_out = {
                                    {{6{cinstr[12]}}, cinstr[12], cinstr[6:2]},
                                    rs1_c,
                                    3'b111,
                                    rs1_c,
                                    7'b0010011
                                };
                                
                            2'b11: begin

                                case (ca_funct2)

                                    2'b00: // c.sub
                                        instr_out = {
                                            7'b0100000,
                                            rs2_c,
                                            rs1_c,
                                            3'b000,
                                            rs1_c,
                                            7'b0110011
                                        };
                                        
                                    2'b01: // c.xor
                                        instr_out = {
                                            7'b0000000,
                                            rs2_c,
                                            rs1_c,
                                            3'b100,
                                            rs1_c,
                                            7'b0110011
                                        };
                                        
                                    2'b10: // c.or
                                        instr_out = {
                                            7'b0000000,
                                            rs2_c,
                                            rs1_c,
                                            3'b110,
                                            rs1_c,
                                            7'b0110011
                                        };
                                        
                                    2'b11: // c.and
                                        instr_out = {
                                            7'b0000000,
                                            rs2_c,
                                            rs1_c,
                                            3'b111,
                                            rs1_c,
                                            7'b0110011
                                        };
                                        
                                endcase

                            end

                        endcase

                    end

                    3'b101: // c.j
                        instr_out = {
                            imm_cj[20],        // imm[20]
                            imm_cj[10:1],      // imm[10:1]
                            imm_cj[11],        // imm[11]
                            imm_cj[19:12],     // imm[19:12]
                            5'd0,              // rd = x0
                            7'b1101111         // JAL
                        };
                        
                    3'b110: // c.beqz
                        instr_out = {
                            imm_cb[12],
                            imm_cb[10:5],
                            5'd0,
                            rs1_c,
                            3'b000,
                            imm_cb[4:1],
                            imm_cb[11],
                            7'b1100011
                        };
                         

                    3'b111: // c.bnez
                        instr_out = {
                            imm_cb[12],
                            imm_cb[10:5],
                            5'd0,
                            rs1_c,
                            3'b001,
                            imm_cb[4:1],
                            imm_cb[11],
                            7'b1100011
                        };
                        
                    default:
                        instr_out = 32'h00000013;

                endcase

            end

            //=================================================
            // QUADRANT 2 (C2)
            //=================================================

            2'b10: begin

                case (funct3)

                    3'b000: begin
                        // c.slli
                    end

                    3'b010: begin
                        // c.lwsp
                    end

                    3'b100: begin

                        case (cr_funct4)

                            // Aquí luego distinguiremos:
                            // c.jr
                            // c.jalr
                            // c.add

                        endcase

                    end

                    3'b110: begin
                        // Reservado en RV32
                    end

                    3'b111: begin
                        // c.swsp
                    end

                    default:
                        instr_out = 32'h00000013;

                endcase

            end

            //=================================================
            // Illegal / Reserved
            //=================================================

            default:
                instr_out = 32'h00000013;

            endcase

        end

    end

endmodule