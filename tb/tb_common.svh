// Utilitários compartilhados — incluir DENTRO do módulo de teste (após clk, reset, cpu_*, dut)
// Requer: import cache_def::*; e instância cache_com_memoria chamada dut

// Monta endereço: tag[31:14] | index[13:4] | palavra[3:2] | 00
// Para testes com main_memory, prefira tags com tag[1:0]==0 (bits [15:14] do endereço).
function automatic logic [31:0] tb_make_addr(
    
    input logic [17:0] tag,
    
    input logic [9:0]  idx,
    
    input logic [1:0]  word
);

  tb_make_addr = {tag, idx, word, 2'b00};
endfunction



function automatic logic [9:0] tb_index_of(input logic [31:0] addr);
    
  tb_index_of = addr[13:4];
endfunction

//
function automatic logic [17:0] tb_tag_of(input logic [31:0] addr);
    
  tb_tag_of = addr[31:14];
    //
endfunction

//
task automatic tb_dut_reset(input int cycles = 3);
    //
  cpu_addr  = '0;
  cpu_data  = '0;
  cpu_rw    = 1'b0;
  cpu_valid = 1'b0;
  reset     = 1'b1;
    
  repeat (cycles) @(posedge clk);
  reset     = 1'b0;
  @(posedge clk);
    //
endtask

//
task automatic tb_cpu_read(
    
    input  logic [31:0] addr,
    output logic [31:0] data,
    output int        ciclos
);
    //
  ciclos    = 0;
  cpu_addr  = addr;
  cpu_data  = '0;
  cpu_rw    = 1'b0;
  cpu_valid = 1'b1;
  @(posedge clk);
  ciclos++;
  while (!cpu_ready) begin
    @(posedge clk);
    ciclos++;
      
  end//
    
  data      = cpu_rdata;
    //
  cpu_valid = 1'b0;
    //
  @(posedge clk);
    
endtask
//
task automatic tb_cpu_write(
    
    input  logic [31:0] addr,
    input  logic [31:0] data,
    output int        ciclos
    
);
    //
  ciclos    = 0;
  cpu_addr  = addr;
  cpu_data  = data;
  cpu_rw    = 1'b1;
  cpu_valid = 1'b1;
  @(posedge clk);
  ciclos++;
  while (!cpu_ready) begin
    @(posedge clk);
    ciclos++;
      
  end
    
  cpu_valid = 1'b0;
  @(posedge clk);
    
endtask

task automatic tb_mem_write_word(input logic [31:0] addr, input logic [31:0] data);
    
  dut.u_mem.debug_write_word(addr, data);
    
endtask

task automatic tb_mem_read_word(
    
    input  logic [31:0] addr,
    output logic [31:0] data
    
);
  dut.u_mem.debug_read_word(addr, data);
    
endtask

task automatic tb_get_tag(
    
    input  logic [31:0] ref_addr,
    output logic        valid,
    output logic        dirty,
    output logic [17:0] tag_out
    
);
    
  logic [31:0] saved_addr;
  saved_addr = cpu_addr;
  cpu_addr   = ref_addr;
  @(posedge clk);
  valid      = dut.u_cache.u_fsm.tag_read.valid;
  dirty      = dut.u_cache.u_fsm.tag_read.dirty;
  tag_out    = dut.u_cache.u_fsm.tag_read.tag;
  cpu_addr   = saved_addr;
    
endtask

task automatic tb_check(
    
    input string      nome,
    input logic       condicao,
    inout int         falhas
    
);
  if (!condicao) begin
      
    $display("FALHA: %s", nome);
    falhas++;
      
  end else
      
    $display("OK:    %s", nome);
endtask
