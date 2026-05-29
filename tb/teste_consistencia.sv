`timescale 1ns/1ps

module teste_consistencia;

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

    logic [31:0] addr_a0;
    logic [31:0] addr_a1;
    logic [31:0] addr_b0;
    logic [31:0] dado;
    logic [31:0] dado_mem;

    falhas = 0;

    $dumpfile("build/teste_consistencia.vcd");
    $dumpvars(0, teste_consistencia);

    tb_dut_reset();

    addr_a0 = tb_make_addr(18'h00000, 10'h155, 2'b00);
    addr_a1 = tb_make_addr(18'h00000, 10'h155, 2'b01);
    addr_b0 = tb_make_addr(18'h00001, 10'h155, 2'b00);

    tb_mem_write_word(addr_a0, 32'hAAAA_0000);
    tb_mem_write_word(addr_a1, 32'hAAAA_1111);
    tb_mem_write_word(addr_b0, 32'hBBBB_0000);

    tb_cpu_read(addr_a0, dado, ciclos);
    tb_check("leitura inicial de A0 retorna valor correto", dado === 32'hAAAA_0000, falhas);

    tb_cpu_read(addr_a1, dado, ciclos);
    tb_check("leitura de A1 no mesmo bloco retorna valor correto", dado === 32'hAAAA_1111, falhas);

    tb_cpu_write(addr_a1, 32'hABCD_0001, ciclos);

    tb_cpu_read(addr_a1, dado, ciclos);
    tb_check("valor escrito em A1 e lido corretamente da cache", dado === 32'hABCD_0001, falhas);

    tb_cpu_read(addr_a0, dado, ciclos);
    tb_check("escrita em A1 nao altera A0", dado === 32'hAAAA_0000, falhas);

    tb_cpu_read(addr_b0, dado, ciclos);
    tb_check("conflito de indice carrega B0 corretamente", dado === 32'hBBBB_0000, falhas);

    tb_mem_read_word(addr_a1, dado_mem);
    tb_check("write-back preserva A1 atualizado na memoria", dado_mem === 32'hABCD_0001, falhas);

    tb_mem_read_word(addr_a0, dado_mem);
    tb_check("write-back preserva A0 sem alteracao indevida", dado_mem === 32'hAAAA_0000, falhas);

    tb_cpu_read(addr_a1, dado, ciclos);
    tb_check("apos recarregar A, A1 continua com valor atualizado", dado === 32'hABCD_0001, falhas);

    tb_cpu_read(addr_a0, dado, ciclos);
    tb_check("apos recarregar A, A0 continua correto", dado === 32'hAAAA_0000, falhas);

    if (falhas == 0) begin
      $display("PASS: teste_consistencia");
      $finish;
    end else begin
      $fatal(1, "FAIL: teste_consistencia com %0d falhas", falhas);
    end
  end

endmodule
