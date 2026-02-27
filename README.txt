ENVISA1.prw
------------------------------------------------------------------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------------------------------------------------------------

RELCLITXT.prw 
----------------------------------------------------------------------------------------------------------------------------------------
Criação de um Relatório Básico em um Arquivo TXT

Descrição: Escreva uma função ADVPL que crie um relatório em formato .TXT. O relatório deve conter a listagem de clientes cadastrados na tabela SA1 (Cadastro de Clientes do Protheus).
Instruções:

1) Obter os registros da tabela SA1 (clientes ativos).
2) Gravar as informações no formato TXT com os campos: Código do Cliente, Nome, CNPJ e Cidade.
3) Nome do arquivo gerado: "RelatorioClientes_.TXT".(Arquivo deve ser gerado no diretório escolhido pelo cliente)
4) Critérios de Avaliação:

Uso correto de filtros na tabela SA1
   - Geração correta do arquivo TXT e formatação do conteúdo.
    -Organização e legibilidade do código.

----------------------------------------------------------------------------------------------------------------------------------------

RELCLITRP.prw 
----------------------------------------------------------------------------------------------------------------------------------------
Criação de um Relatório Básico em TREPORT

Descrição: Escreva uma função ADVPL que crie um relatório em formato . O relatório deve conter a listagem de clientes cadastrados na tabela SA1 (Cadastro de Clientes do Protheus).
Instruções:

1) Obter os registros da tabela SA1 (clientes ativos) e que tenha tido alguma venda para esse cliente..
2) Código do Cliente, Nome, CNPJ e Cidade.

Critérios de Avaliação:
   - Uso correto de filtros na tabela SA1.
   - Organização e legibilidade do código.

----------------------------------------------------------------------------------------------------------------------------------------

IMPCLI.prw
----------------------------------------------------------------------------------------------------------------------------------------
Desenvolvimento de um importador de carga Cadastro de Clientes

Descrição: Crie uma rotina que importe dados cadastrais de clientes em lote de um arquivo CSV..
Instruções:

Criar um arquivo de layout (com os campos obrigatórios do cadastro de clientes)
Desenvolver uma rotina que abra uma tela de seleção de arquivo.
Cadastramento de dados via execauto.
Atualizar o cadastro do cliente, posicionando no registro e atualizando de forma convencional do registro(sem execauto (campos a sua escolha) )
Critérios de Avaliação:

Uso correto do execauto
Utilização de funções corretas de posicionamento e edição de registros em advpl
Performance em um lote de 1000 clientes .
Organização e legibilidade do código.
 
----------------------------------------------------------------------------------------------------------------------------------------
 
