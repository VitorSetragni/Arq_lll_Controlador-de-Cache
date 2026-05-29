# Controlador de Cache (Trabalho Prático 1)

Implementação em SystemVerilog de um controlador de cache **mapeado diretamente**, conforme Patterson & Hennessy — *Computer Organization and Design: RISC-V Edition*, **Seção 5.12**.

## Arquitetura

| Módulo | Pasta | Função |
|--------|-------|--------|
| `cache_def` | `rtl/` | Tipos e parâmetros (tag, index, interfaces) |
| `dm_cache_tag` | `rtl/` | RAM de tags (`valid`, `dirty`, `tag`) |
| `dm_cache_data` | `rtl/` | RAM de dados (1024 × 128 bits) |
| `dm_cache_fsm` | `rtl/` | FSM de controle (4 estados) |
| `controlador_cache` | `hardware/` | Wrapper com portas planas |
| `main_memory` | `hardware/` | Memória principal (blocos de 4 palavras) |
| `cache_com_memoria` | `hardware/` | Top: CPU ↔ cache ↔ memória |

### Políticas

- **Mapeamento:** direto (1024 linhas)
- **Bloco:** 4 palavras × 32 bits = 128 bits
- **Endereço:** tag `[31:14]`, index `[13:4]`, palavra `[3:2]`
- **Escrita:** write-back + write-allocate em miss

### FSM

`idle` → `compare_tag` → (`hit` → `idle` | `miss` → `allocate` ou `write_back` → `allocate` → `compare_tag`)

## Dependências

- [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog`, `vvp`) com suporte a SystemVerilog (`-g2012`)

```bash
sudo apt install iverilog
```

## Compilação e simulação (Linux)

```bash
make test        # todos os testes (Seção 7 do trabalho)
make sim_min     # só o teste mínimo
```

| Arquivo | Classe (PDF §7) |
|---------|-----------------|
| `tb/teste_leitura.sv` | 7.1 Leitura (hit, miss, valid/tag) |
| `tb/teste_escrita.sv` | 7.2 Escrita (hit, miss, write-back/dirty) |
| `tb/teste_substituicao.sv` | 7.3 Substituição (linha limpa e dirty) |
| `tb/teste_consistencia.sv` | 7.4 Consistência e conflito de index |
| `tb/teste_limites.sv` | 7.5 Casos limite |
| `tb/teste_minimo.sv` | Smoke test (miss + hit) |

Utilitários compartilhados: `tb/tb_common.svh`

Logs em `build/<nome>.log`.

```bash
make clean
```

## Estrutura de pastas

```
rtl/           # Núcleo da cache (livro §5.12)
hardware/      # Wrapper + memória principal
tb/            # Testbenches
build/         # Artefatos de simulação (gerado)
```

## Integração CPU ↔ cache ↔ memória

**CPU:** `cpu_addr`, `cpu_data`, `cpu_rw`, `cpu_valid` → `cpu_rdata`, `cpu_ready`

**Memória:** `mem_valid`, `mem_rw`, `mem_addr`, `mem_wdata`/`mem_rdata`, `mem_ready`

Manter `cpu_valid = 1` até `cpu_ready = 1` (incluindo em misses de vários ciclos).
