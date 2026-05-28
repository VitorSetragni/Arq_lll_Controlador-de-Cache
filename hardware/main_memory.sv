
`timescale 1ns/1ps

module main_memory #(
    parameter int ADDR_WIDTH  = 32,   // Quantidade de bits do endereço
    parameter int DATA_WIDTH  = 32,   // Quantidade de bits de uma palavra
    parameter int BLOCK_WORDS = 4,    // Quantidade de palavras dentro de um bloco da cache
    parameter int MEM_BLOCKS  = 4096, // Quantidade de blocos que a memoria vai ter na simulação
    parameter int LATENCY     = 1     // Quantidade de ciclos que a memoria demora para responder
)(
    input  logic clk,   
    input  logic reset, 

    input  logic mem_valid, // Indica que a cache esta fazendo uma requisição para a memoria
    input  logic mem_rw,    // 0 para leitura e 1 para escrita

    input  logic [ADDR_WIDTH-1:0] mem_addr, // Endereço que a cache quer acessar na memoria

    input  logic [(DATA_WIDTH*BLOCK_WORDS)-1:0] mem_wdata, // Bloco de dados que sera escrito na memoria

    output logic [(DATA_WIDTH*BLOCK_WORDS)-1:0] mem_rdata, // Bloco de dados que sera lido da memoria

    output logic mem_ready // Indica termino da operação
);

    localparam int BLOCK_WIDTH = DATA_WIDTH * BLOCK_WORDS; // Tamanho total do bloco em bits 128 bits

    localparam int BLOCK_BYTES = (DATA_WIDTH / 8) * BLOCK_WORDS; // Tamanho do bloco em bytes 16 bytes

    localparam int OFFSET_BITS = $clog2(BLOCK_BYTES); // Quantidade de bits usados para o offset 

    localparam int MEM_INDEX_BITS = $clog2(MEM_BLOCKS); // Quantidade de bits usados para escolher um bloco da memoria

    logic [BLOCK_WIDTH-1:0] memory [0:MEM_BLOCKS-1]; // Array que representa a memoria principal da simulação

    logic busy; // Indica se a memoria esta ocupada processando uma requisição

    logic saved_rw; // Guarda se a operação salva era leitura ou escrita

    logic [ADDR_WIDTH-1:0] saved_addr; // Guarda o endereço da requisição enquanto a memoria espera a latência

    logic [BLOCK_WIDTH-1:0] saved_wdata; // Guarda o dado que sera escrito depois da latência

    int cycles_left; // Guarda quantos ciclos faltam para a memoria terminar a operação

    function automatic logic [MEM_INDEX_BITS-1:0] get_block_index(
        input logic [ADDR_WIDTH-1:0] addr // Endereço completo recebido da cache
    );
        get_block_index = addr[OFFSET_BITS +: MEM_INDEX_BITS]; // Pega apenas os bits que identificam o bloco
    endfunction

    initial begin
        for (int i = 0; i < MEM_BLOCKS; i++) begin
            memory[i] = '0; 
        end

        mem_rdata   = '0;   // Começa sem dado lido
        mem_ready   = 1'b0; // Começa dizendo que a memoria ainda não esta pronta
        busy        = 1'b0; // Começa sem nenhuma operação em andamento
        saved_rw    = 1'b0; // Valor inicial da operação salva
        saved_addr  = '0;   // Endereço salvo começa zerado
        saved_wdata = '0;   // Dado salvo começa zerado
        cycles_left = 0;    // Não existe ciclo pendente no começo
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            mem_ready   <= 1'b0; 
            mem_rdata   <= '0;   
            busy        <= 1'b0; 
            saved_rw    <= 1'b0; 
            saved_addr  <= '0;   
            saved_wdata <= '0;   
            cycles_left <= 0;    
        end
        else begin
            mem_ready <= 1'b0; 

            if (!busy && mem_valid) begin
                if (LATENCY <= 1) begin
                    if (mem_rw) begin
                        memory[get_block_index(mem_addr)] <= mem_wdata; // Escreve um bloco na memoria
                    end
                    else begin
                        mem_rdata <= memory[get_block_index(mem_addr)]; // Lê um bloco da memoria
                    end

                    mem_ready <= 1'b1; // Avisa que a operação terminou
                end
                else begin
                    busy        <= 1'b1;      
                    saved_rw    <= mem_rw;    
                    saved_addr  <= mem_addr;  
                    saved_wdata <= mem_wdata; 
                    cycles_left <= LATENCY - 1; 
                end
            end
            else if (busy) begin
                if (cycles_left <= 1) begin
                    if (saved_rw) begin
                        memory[get_block_index(saved_addr)] <= saved_wdata; // Faz a escrita que estava esperando
                    end
                    else begin
                        mem_rdata <= memory[get_block_index(saved_addr)]; // Faz a leitura que estava esperando
                    end

                    mem_ready   <= 1'b1; 
                    busy        <= 1'b0; 
                    cycles_left <= 0;    
                end
                else begin
                    cycles_left <= cycles_left - 1; 
                end
            end
        end
    end

    task automatic debug_write_block(
        input logic [ADDR_WIDTH-1:0] addr,   // Endereço onde o bloco sera escrito
        input logic [BLOCK_WIDTH-1:0] data   // Bloco completo que sera colocado na memoria
    );
        memory[get_block_index(addr)] = data; // Escreve direto na memoria
    endtask

    task automatic debug_read_block(
        input  logic [ADDR_WIDTH-1:0] addr,  // Endereço do bloco que sera lido
        output logic [BLOCK_WIDTH-1:0] data  // Variavel que recebe o bloco lido
    );
        data = memory[get_block_index(addr)]; // Lê direto da memoria
    endtask

    task automatic debug_write_word(
        input logic [ADDR_WIDTH-1:0] addr, // Endereço da palavra que sera escrita
        input logic [DATA_WIDTH-1:0] data  // Palavra de 32 bits que sera escrita
    );
        logic [MEM_INDEX_BITS-1:0] block_index; // Índice do bloco dentro da memoria

        logic [$clog2(BLOCK_WORDS)-1:0] word_index; // Índice da palavra dentro do bloco

        block_index = get_block_index(addr); // Calcula em qual bloco esta o endereço

        word_index = addr[3:2]; // Escolhe qual das 4 palavras do bloco sera acessada

        memory[block_index][word_index * DATA_WIDTH +: DATA_WIDTH] = data; // Escreve só uma palavra dentro do bloco
    endtask

    task automatic debug_read_word(
        input  logic [ADDR_WIDTH-1:0] addr, // Endereço da palavra que sera lida
        output logic [DATA_WIDTH-1:0] data  // Variavel que recebe a palavra lida
    );
        logic [MEM_INDEX_BITS-1:0] block_index; 

        logic [$clog2(BLOCK_WORDS)-1:0] word_index; 

        block_index = get_block_index(addr); 

        word_index = addr[3:2]; 

        data = memory[block_index][word_index * DATA_WIDTH +: DATA_WIDTH]; 
    endtask

endmodule
