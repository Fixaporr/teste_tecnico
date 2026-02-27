#Include "protheus.ch"
#Include "topconn.ch"

// ===============================================================
// RELATÓRIO TREPORT: Clientes ativos com venda (SA1 + SF2)
// Campos: Código, Nome, CNPJ, Cidade
// ===============================================================

User Function RELCLITRP()
    Local oRep, oSec
    Local oCod, oNom, oCnpj, oCid
    Local cTitle := "Clientes Ativos com Venda (SA1/SF2)"
    Local cQry   := ""
    Local nLin   := 0

    // clientes ativos que possuem venda em SF2 
    // - Amarra por Cliente + Loja

    cQry := ;
        "SELECT DISTINCT " + ;
        "  A1.A1_COD  AS COD, " + ;
        "  A1.A1_NOME AS NOME, " + ;
        "  A1.A1_CGC  AS CNPJ, " + ;
        "  A1.A1_MUN  AS CIDADE " + ;
        "FROM " + RetSqlName("SA1") + " A1 " + ;
        "WHERE A1.D_E_L_E_T_ = ' ' " + ;
        "  AND A1.A1_MSBLQL <> '1' " + ;
        "  AND EXISTS ( " + ;
        "      SELECT 1 " + ;
        "      FROM " + RetSqlName("SF2") + " F2 " + ;
        "      WHERE F2.D_E_L_E_T_ = ' ' " + ;
        "        AND F2.F2_CLIENTE = A1.A1_COD " + ;
        "        AND F2.F2_LOJA    = A1.A1_LOJA " + ;
        "  ) " + ;
        "ORDER BY A1.A1_COD "

    TCQuery cQry New Alias "QCLI"

    If QCLI->(Eof())
        QCLI->(DbCloseArea())
        MsgInfo("Nenhum cliente encontrado com os filtros aplicados.")
        Return .T.
    EndIf

    // --- Cria relatório
    oRep := TReport():New( cTitle, cTitle, , {|| .T. }, cTitle )

    // --- Seção
    oSec := TRSection():New(oRep, "Clientes", {"QCLI"}, .F., .T.)

    // --- Colunas
    oCod  := TRCell():New(oSec, "COD",     "Código",  "@!",  10, 0)
    oNom  := TRCell():New(oSec, "NOME",    "Nome",    "@!",  40, 0)
    oCnpj := TRCell():New(oSec, "CNPJ",    "CNPJ",    "@!",  18, 0)
    oCid  := TRCell():New(oSec, "CIDADE",  "Cidade",  "@!",  25, 0)

    // --- Impressão/execução
    oRep:SetLandscape()     // opcional
    oRep:PrintDialog()      // abre diálogo padrão
    oRep:Run()              // executa

    // --- Fecha consulta 
    QCLI->(DbCloseArea())

Return .T.