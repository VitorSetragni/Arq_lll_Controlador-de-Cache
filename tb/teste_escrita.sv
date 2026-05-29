`timescale 1ns/1ps

module teste_escrita;

  logic clk = 1'b0;
  logic reset;

  logic [31:0] cpu_addr;
  logic [31:0] cpu_data;
  logic        cpu_rw;
  logic        cpu_valid;
  logic [31:0] cpu_rdata;
  logic        cpu_ready;

  always #5 clk = ~clk;

  cache_com_memoria dut (
      .clk       (clk),
      .reset     (reset),
      .cpu_addr  (cpu_addr),
      .cpu_data  (cpu_data),
      .cpu_rw    (cpu_rw),
      .cpu_valid (cpu_valid),
      .cpu_rdata (cpu_rdata),
      .cpu_ready (cpu_ready)
  );

  `include "tb_common.svh"

  initial begin
    int falhas;
    int ciclos;

    logic [31:0] addr_a;
    logic [31:0] addr_b;
    logic [31:0] dado;
    logic [31:0] dado_mem;

    logic valid;
    logic dirty;
    logic [17:0] tag_lida;

    falhas = 0;

    $dumpfile("build/teste_escrita.vcd");
    $dumpvars(0, teste_escrita);

    tb_dut_reset();

    addr_a = tb_make_addr(18'h00000, 10'h080, 2'b10);
    addr_b = tb_make_addr(18'h00001, 10'h080, 2'b10);

    tb_mem_write_word(addr_a, 32'h1111_1111);
    tb_mem_write_word(addr_b, 32'h2222_2222);

    tb_cpu_read(addr_a, dado, ciclos);
    tb_check("bloco A carregado antes da escrita", dado === 32'h1111_1111, falhas);

    tb_cpu_write(addr_a, 32'hAAAA_5555, ciclos);

    tb_cpu_read(addr_a, dado, ciclos);
    tb_check("escrita com hit atualiza a palavra na cache", dado === 32'hAAAA_5555, falhas);

    tb_get_tag(addr_a, valid, dirty, tag_lida);
    tb_check("bloco escrito permanece valido", valid === 1'b1, falhas);
    tb_check("escrita com hit marca dirty", dirty === 1'b1, falhas);
    tb_check("tag continua apontando para o bloco A", tag_lida === tb_tag_of(addr_a), falhas);

    tb_mem_read_word(addr_a, dado_mem);
    tb_check("write-back nao atualiza a memoria imediatamente", dado_mem === 32'h1111_1111, falhas);

    tb_cpu_write(addr_b, 32'hBBBB_7777, ciclos);
    tb_check("escrita com miss exige mais ciclos que escrita com hit", ciclos > 1, falhas);

    tb_mem_read_word(addr_a, dado_mem);
    tb_check("substituicao de bloco dirty grava o bloco A na memoria", dado_mem === 32'hAAAA_5555, falhas);

    tb_cpu_read(addr_b, dado, ciclos);
    tb_check("dado escrito no bloco B fica disponivel na cache", dado === 32'hBBBB_7777, falhas);

    tb_get_tag(addr_b, valid, dirty, tag_lida);
    tb_check("bloco B fica valido apos write-allocate", valid === 1'b1, falhas);
    tb_check("bloco B fica dirty apos escrita", dirty === 1'b1, falhas);
    tb_check("tag passa a apontar para o bloco B", tag_lida === tb_tag_of(addr_b), falhas);

    tb_mem_read_word(addr_b, dado_mem);
    tb_check("memoria do bloco B ainda nao e atualizada antes da substituicao", dado_mem === 32'h2222_2222, falhas);

    if (falhas == 0) begin
      $display("PASS: teste_escrita");
      $finish;
    end else begin
      $fatal(1, "FAIL: teste_escrita com %0d falhas", falhas);
    end
  end

endmodule
