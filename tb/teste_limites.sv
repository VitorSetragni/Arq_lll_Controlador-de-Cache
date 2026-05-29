`timescale 1ns/1ps

module teste_limites;

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
    int ciclos_miss;
    int ciclos_hit;

    logic [31:0] addr_zero;
    logic [31:0] addr_extremo;
    logic [31:0] dado;

    logic valid;
    logic dirty;
    logic [17:0] tag_lida;

    falhas = 0;

    $dumpfile("build/teste_limites.vcd");
    $dumpvars(0, teste_limites);

    tb_dut_reset();

    addr_zero    = tb_make_addr(18'h00000, 10'h000, 2'b00);
    addr_extremo = tb_make_addr(18'h3FFFF, 10'h3FF, 2'b11);

    tb_get_tag(addr_zero, valid, dirty, tag_lida);
    tb_check("apos reset a linha inicial esta invalida", valid === 1'b0, falhas);
    tb_check("apos reset a linha inicial nao esta dirty", dirty === 1'b0, falhas);

    tb_mem_write_word(addr_zero,    32'h0000_0001);
    tb_mem_write_word(addr_extremo, 32'hFFFF_FFFC);

    tb_cpu_read(addr_zero, dado, ciclos_miss);
    tb_check("acesso ao endereco inicial retorna dado correto", dado === 32'h0000_0001, falhas);

    tb_get_tag(addr_zero, valid, dirty, tag_lida);
    tb_check("linha do endereco inicial fica valida", valid === 1'b1, falhas);
    tb_check("tag do endereco inicial fica correta", tag_lida === tb_tag_of(addr_zero), falhas);

    tb_cpu_read(addr_extremo, dado, ciclos_miss);
    tb_check("acesso ao endereco extremo retorna dado correto", dado === 32'hFFFF_FFFC, falhas);

    tb_get_tag(addr_extremo, valid, dirty, tag_lida);
    tb_check("linha do endereco extremo fica valida", valid === 1'b1, falhas);
    tb_check("tag do endereco extremo fica correta", tag_lida === tb_tag_of(addr_extremo), falhas);
    tb_check("leitura do endereco extremo nao marca dirty", dirty === 1'b0, falhas);

    tb_cpu_read(addr_extremo, dado, ciclos_hit);
    tb_check("acesso repetido ao endereco extremo continua correto", dado === 32'hFFFF_FFFC, falhas);
    tb_check("acesso repetido ao endereco extremo e hit", ciclos_hit < ciclos_miss, falhas);

    if (falhas == 0) begin
      $display("PASS: teste_limites");
      $finish;
    end else begin
      $fatal(1, "FAIL: teste_limites com %0d falhas", falhas);
    end
  end

endmodule
