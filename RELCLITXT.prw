#Include "protheus.ch"
#Include "topconn.ch"

// ======================================================================
// Gera TXT: Relatorio Clientes .txt  no diretório escolhido pelo usuário
// Campos: Código, Nome, CNPJ, Cidade (apenas clientes ativos)
// ======================================================================
User Function RELCLITXT()
    Local cDir    := ""
    Local cFile   := ""
    Local nHandle := -1
    Local cLinha  := ""
    Local cQry    := ""
    Local nQtde   := 0

    // 1) Diretório escolhido pelo cliente
    cDir := _EscolheDiretorio()

    If Empty(cDir)
        MsgStop("Diretório não informado. Operação cancelada.")
        Return .F.
    EndIf

    // Garante barra final
    If Right(cDir, 1) $ "/\"
        // ok
    Else
        cDir += "\"
    EndIf

    // 2) Nome do arquivo
    cFile := cDir + "RelatorioClientes_.TXT"

    // 3) Cria arquivo
    nHandle := FCreate(cFile)
    If nHandle < 0
        MsgStop("Não foi possível criar o arquivo: " + cFile)
        Return .F.
    EndIf

    // Cabeçalho
    FWrite(nHandle, "RELATORIO DE CLIENTES (SA1) - ATIVOS" + CRLF)
    FWrite(nHandle, "CODIGO|NOME|CNPJ|CIDADE" + CRLF)
    FWrite(nHandle, Replicate("-", 80) + CRLF)

    // 4) Busca SA1 ativos
    // Critério "ativo": sem D_E_L_E_T_
    cQry := "SELECT A1_COD, A1_NOME, A1_CGC, A1_MUN " + ;
            "  FROM " + RetSqlName("SA1") + " SA1 " + ;
            " WHERE SA1.D_E_L_E_T_ = ' ' " + ;
            "   AND SA1.A1_MSBLQL <> '1' " + ;
            " ORDER BY SA1.A1_COD "

    TCQuery cQry New Alias "QSA1"

    While !QSA1->(Eof())
        cLinha := AllTrim(QSA1->A1_COD) + "|" + ;
                  _LimpaPipe(AllTrim(QSA1->A1_NOME)) + "|" + ;
                  AllTrim(QSA1->A1_CGC) + "|" + ;
                  _LimpaPipe(AllTrim(QSA1->A1_MUN)) + CRLF

        FWrite(nHandle, cLinha)
        nQtde++
        QSA1->(DbSkip())
    EndDo

    QSA1->(DbCloseArea())

    // Rodapé
    FWrite(nHandle, Replicate("-", 80) + CRLF)
    FWrite(nHandle, "TOTAL DE CLIENTES: " + cValToChar(nQtde) + CRLF)

    FClose(nHandle)

    MsgInfo("Arquivo gerado com sucesso:" + CRLF + cFile)

Return .T.


// ----------------------------------------------------------------------
// Escolha de diretório (cliente escolhe)
// ----------------------------------------------------------------------
Static Function _EscolheDiretorio()
    Local cDir := ""

    If Type("cGetDir") == "U"
        cDir := AllTrim(MsgGet("Diretório", "Informe o diretório para gerar o TXT (ex: C:\TEMP):"))
    Else
        cDir := cGetDir("Selecione o diretório para gerar o relatório")
    EndIf

Return cDir

// Evita quebrar o layout caso nome/cidade tenham "|"

Static Function _LimpaPipe(cTxt)
    If Empty(cTxt)
        Return ""
    EndIf
Return StrTran(cTxt, "|", " ")