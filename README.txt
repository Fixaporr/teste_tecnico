Integração SA1 (Clientes) - ADVPL

Arquivos:
- clientes_integ.prw

O que contém:
1) ENVIA_SA1()
   - Consulta clientes ativos (SA1) via TopConn e envia via HTTP POST em JSON
   - Valida status HTTP (200/201, 4xx, 5xx)

2) WSRESTFUL CLIENTES
   - POST /api/clientes
   - PUT  /api/clientes/{codigo}
   - Recebe JSON e atualiza/inclui cliente via ExecAuto

Ajustes obrigatórios:
- URL e TOKEN no ENVIA_SA1()
- Critério de cliente ativo na query (A1_MSBLQL etc.)
- Campos obrigatórios (ex.: A1_LOJA/A1_FILIAL) no ExecAuto, se sua base exigir
- Rotina do ExecAuto (MATA030 é padrão para Clientes; se for outra, ajuste)

Build/Deploy:
- Não esquecer de compilar o PRW no ambiente Protheus e publique o serviço REST conforme seu padrão (AppServer + REST)
