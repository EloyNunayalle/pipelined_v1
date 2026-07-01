module regfile(
    input         clk,
    input         reset,
    input         we3,
    input  [4:0]  a1, a2, a3,
    input  [31:0] wd3,
    output [31:0] rd1, rd2
);

    reg [31:0] rf[31:0];

    integer i;

    // Escritura e inicializacion del banco de registros
    always @(posedge clk or posedge reset) begin

        if (reset) begin

            // Inicializar todos los registros a cero
            for (i = 0; i < 32; i = i + 1)
                rf[i] <= 32'd0;

            // Inicializar Stack Pointer (x2)
            // La memoria de datos ocupa:
            // 2048 palabras × 4 bytes = 8192 bytes = 0x2000.
            // El stack comienza inmediatamente despues de la RAM
            // y crecera hacia direcciones menores.
            rf[2] <= 32'h00002000;

        end

        else begin

            // x0 siempre permanece en cero
            if (we3 && (a3 != 5'd0))
                rf[a3] <= wd3;

        end

    end

    // Lecturas asíncronas
    assign rd1 = (a1 == 5'd0) ? 32'd0 :
                 ((we3 && (a3 == a1) && (a3 != 5'd0)) ? wd3 : rf[a1]);

    assign rd2 = (a2 == 5'd0) ? 32'd0 :
                 ((we3 && (a3 == a2) && (a3 != 5'd0)) ? wd3 : rf[a2]);

endmodule