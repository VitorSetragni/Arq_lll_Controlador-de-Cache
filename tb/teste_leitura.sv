`timescale 1ns/1ps

module teste_leitura;

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
    int ciclos_hit2;

    logic [31:0] addr_w0;
    logic [31:0] addr_w1;
    logic [31:0] dado;

    logic valid;
    logic dirty;
    logic [17:0] tag_lida;

    falhas = 0;

    $dumpfile("build/teste_leitura.vcd");
    $dumpvars(0, teste_leitura);

    tb_dut_reset();

    addr_w0 = tb_make_addr(18'h00000, 10'h055, 2'b00);
    addr_w1 = tb_make_addr(18'h00000, 10'h055, 2'b01);

    tb_mem_write_word(addr_w0, 32'h1111_AAAA);
    tb_mem_write_word(addr_w1, 32'h2222_BBBB);

    tb_cpu_read(addr_w0, dado, ciclos_miss);
    tb_check("leitura inicial com miss retorna a palavra 0", dado === 32'h1111_AAAA, falhas);

    tb_get_tag(addr_w0, valid, dirty, tag_lida);
    tb_check("bit valid fica ativo depois do carregamento", valid === 1'b1, falhas);
    tb_check("tag armazenada corresponde ao endereco acessado", tag_lida === tb_tag_of(addr_w0), falhas);
    tb_check("leitura nao marca o bloco como dirty", dirty === 1'b0, falhas);

    tb_cpu_read(addr_w1, dado, ciclos_hit);
    tb_check("leitura de outra palavra do mesmo bloco gera hit", dado === 32'h2222_BBBB, falhas);
    tb_check("hit de leitura e mais rapido que o miss inicial", ciclos_hit < ciclos_miss, falhas);

    tb_cpu_read(addr_w0, dado, ciclos_hit2);
    tb_check("acesso repetido ao mesmo endereco continua correto", dado === 32'h1111_AAAA, falhas);
    tb_check("acesso repetido permanece como hit", ciclos_hit2 <= ciclos_hit, falhas);

    if (falhas == 0) begin
      $display("PASS: teste_leitura");
      $finish;
    end else begin
      $fatal(1, "FAIL: teste_leitura com %0d falhas", falhas);
    end
  end

endmodule
