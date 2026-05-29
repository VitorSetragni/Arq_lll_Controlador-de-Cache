`timescale 1ns/1ps

module teste_minimo;

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

    logic [31:0] addr;
    logic [31:0] dado;

    falhas = 0;

    $dumpfile("build/teste_minimo.vcd");
    $dumpvars(0, teste_minimo);

    tb_dut_reset();

    addr = tb_make_addr(18'h00000, 10'h012, 2'b00);

    tb_mem_write_word(addr, 32'hCAFE_1234);

    tb_cpu_read(addr, dado, ciclos_miss);
    tb_check("primeira leitura retorna o dado da memoria", dado === 32'hCAFE_1234, falhas);

    tb_cpu_read(addr, dado, ciclos_hit);
    tb_check("segunda leitura retorna o mesmo dado", dado === 32'hCAFE_1234, falhas);

    tb_check("segunda leitura e mais rapida que a primeira", ciclos_hit < ciclos_miss, falhas);

    if (falhas == 0) begin
      $display("PASS: teste_minimo");
      $finish;
    end else begin
      $fatal(1, "FAIL: teste_minimo com %0d falhas", falhas);
    end
  end

endmodule
