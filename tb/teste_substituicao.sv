`timescale 1ns/1ps

module teste_substituicao;

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

    $dumpfile("build/teste_substituicao.vcd");
    $dumpvars(0, teste_substituicao);

    tb_dut_reset();

    addr_a = tb_make_addr(18'h00000, 10'h03A, 2'b00);
    addr_b = tb_make_addr(18'h00001, 10'h03A, 2'b00);

    tb_mem_write_word(addr_a, 32'h0101_0101);
    tb_mem_write_word(addr_b, 32'h0202_0202);

    tb_cpu_read(addr_a, dado, ciclos);
    tb_check("bloco A carregado na cache", dado === 32'h0101_0101, falhas);

    tb_get_tag(addr_a, valid, dirty, tag_lida);
    tb_check("bloco A fica valido", valid === 1'b1, falhas);
    tb_check("bloco A carregado por leitura fica limpo", dirty === 1'b0, falhas);

    tb_cpu_read(addr_b, dado, ciclos);
    tb_check("acesso ao bloco B substitui A por conflito de indice", dado === 32'h0202_0202, falhas);

    tb_get_tag(addr_b, valid, dirty, tag_lida);
    tb_check("tag apos substituicao aponta para B", tag_lida === tb_tag_of(addr_b), falhas);
    tb_check("substituicao de bloco limpo mantem dirty zerado", dirty === 1'b0, falhas);

    tb_mem_read_word(addr_a, dado_mem);
    tb_check("bloco A limpo nao precisou ser alterado na memoria", dado_mem === 32'h0101_0101, falhas);

    tb_cpu_write(addr_b, 32'h0B0B_0B0B, ciclos);

    tb_get_tag(addr_b, valid, dirty, tag_lida);
    tb_check("escrita em B marca o bloco como dirty", dirty === 1'b1, falhas);

    tb_cpu_read(addr_a, dado, ciclos);
    tb_check("novo acesso a A substitui o bloco B", dado === 32'h0101_0101, falhas);

    tb_mem_read_word(addr_b, dado_mem);
    tb_check("bloco B dirty foi gravado na memoria durante write-back", dado_mem === 32'h0B0B_0B0B, falhas);

    tb_get_tag(addr_a, valid, dirty, tag_lida);
    tb_check("tag final volta a apontar para A", tag_lida === tb_tag_of(addr_a), falhas);
    tb_check("bloco A carregado por leitura termina limpo", dirty === 1'b0, falhas);

    if (falhas == 0) begin
      $display("PASS: teste_substituicao");
      $finish;
    end else begin
      $fatal(1, "FAIL: teste_substituicao com %0d falhas", falhas);
    end
  end

endmodule
