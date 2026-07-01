module imem #(parameter MEM_FILE = "riscvtest.mem") (
    input  [31:0] a,
    output [31:0] rd
);

    // Memoria direccionable por media palabra (16 bits)
    reg [15:0] RAM [2047:0];

    initial
        $readmemh(MEM_FILE, RAM);

    // Dato de 32 bits a partir de cualquier dirección alineada a 16 bits
    assign rd = {RAM[a[31:1] + 1], RAM[a[31:1]]};

endmodule