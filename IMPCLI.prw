#Include "protheus.ch"
#Include "topconn.ch"

// ================================================================
// IMPORTADOR CSV - SA1 (Clientes)
// - Gera layout CSV
// - Seleciona arquivo CSV
// - Inclui/atualiza via ExecAuto (MsExecAuto + MATA030)
// - Atualiza campos convencionais SEM ExecAuto (DbSeek + RecLock)
// Performance: lote 1000+
// ================================================================


// ------------------------------------------------
// Menu principal do importador (chame no SIGACFG/rotina)
// ------------------------------------------------
User Function IMPCLI()
    Local aOp := {"1 - Gerar Layout CSV", "2 - Importar CSV (ExecAuto + Update Convencional)"}
    Local n   := 0

    n := AChoice(0,0,10,60, aOp)

    Do Case
    Case n == 1
        _GeraLayoutClientesCSV()
    Case n == 2
        _ImportaClientesCSV()
    Otherwise
        // cancela
    EndCase

Return .T.

// ------------------------------------------------
// 1) Gera arquivo de layout (com header + exemplo)
// ------------------------------------------------
Static Function _GeraLayoutClientesCSV()
    Local cDir  := _EscolheDiretorio()
    Local cFile := ""
    Local nH    := -1

    If Empty(cDir)
        MsgStop("Diretório não informado.")
        Return .F.
    EndIf

    If !(Right(cDir,1) $ "/\")
        cDir += "\"
    EndIf

    cFile := cDir + "LAYOUT_CLIENTES_SA1.csv"
    nH := FCreate(cFile)

    If nH < 0
        MsgStop("Não foi possível criar: " + cFile)
        Return .F.
    EndIf

    // Header + exemplo
    FWrite(nH, "A1_COD;A1_LOJA;A1_NOME;A1_CGC;A1_END;A1_MUN;A1_CEP;A1_EMAIL;A1_TEL" + CRLF)
    FWrite(nH, "000001;01;CLIENTE TESTE LTDA;12345678000199;RUA A 123;SAO PAULO;01001000;teste@cliente.com;11999999999" + CRLF)

    FClose(nH)
    MsgInfo("Layout gerado com sucesso:" + CRLF + cFile)

Return .T.


// ------------------------------------------------
// 2) Importa CSV (ExecAuto para cadastro + update convencional)
// ------------------------------------------------
Static Function _ImportaClientesCSV()
    Local cFile := _EscolheArquivoCSV()
    Local nH    := -1
    Local cLine := ""
    Local nLin  := 0
    Local nOk   := 0
    Local nErr  := 0
    Local aHead := {}
    Local aCols := {}
    Local oMap  := {}      // mapa: campo -> pos
    Local aLog  := {}

    If Empty(cFile)
        MsgStop("Arquivo não selecionado.")
        Return .F.
    EndIf

    nH := FOpen(cFile, FO_READ)
    If nH < 0
        MsgStop("Não foi possível abrir: " + cFile)
        Return .F.
    EndIf

    // Lê header
    cLine := _ReadLine(nH)
    If Empty(cLine)
        FClose(nH)
        MsgStop("CSV vazio.")
        Return .F.
    EndIf

    aHead := _SplitSemi(cLine)
    oMap  := _BuildMap(aHead)

    // Valida colunas mínimas
    If !_HasCol(oMap, "A1_COD") .Or. !_HasCol(oMap, "A1_LOJA") .Or. !_HasCol(oMap, "A1_NOME")
        FClose(nH)
        MsgStop("CSV sem colunas mínimas. Exige: A1_COD;A1_LOJA;A1_NOME (no header).")
        Return .F.
    EndIf

    // Processa linhas
    While .T.
        cLine := _ReadLine(nH)
        If cLine == NIL
            Exit
        EndIf

        nLin++

        // Ignora linhas vazias
        If Empty(AllTrim(cLine))
            Loop
        EndIf

        aCols := _SplitSemi(cLine)

        If _ProcessaLinhaCliente(oMap, aCols, @aLog)
            nOk++
        Else
            nErr++
        EndIf

        // Performance: opcional atualizar tela a cada 50
        If (nLin % 50) == 0
            // ConOut("Processados: " + cValToChar(nLin))
        EndIf
    EndDo

    FClose(nH)

    // Mostra resumo
    MsgInfo(;
        "Importação finalizada." + CRLF + ;
        "Linhas lidas: " + cValToChar(nLin) + CRLF + ;
        "Sucesso: " + cValToChar(nOk) + CRLF + ;
        "Erros: " + cValToChar(nErr) )

    // Se quiser, pode gravar log em arquivo TXT (aLog)
    // _GravaLogImport(cFile, aLog)

Return .T.


// ------------------------------------------------
// Processa 1 linha: ExecAuto (upsert) + update convencional
// ------------------------------------------------
Static Function _ProcessaLinhaCliente(oMap, aCols, aLog)
    Local cCod   := _Get(oMap, aCols, "A1_COD")
    Local cLoja  := _Get(oMap, aCols, "A1_LOJA")
    Local cNome  := _Get(oMap, aCols, "A1_NOME")
    Local cCgc   := _Get(oMap, aCols, "A1_CGC")
    Local cEnd   := _Get(oMap, aCols, "A1_END")
    Local cMun   := _Get(oMap, aCols, "A1_MUN")
    Local cCep   := _Get(oMap, aCols, "A1_CEP")

    // Campos que vamos atualizar sem ExecAuto (exemplo)
    Local cEmail := _Get(oMap, aCols, "A1_EMAIL")
    Local cTel   := _Get(oMap, aCols, "A1_TEL")

    Local aDados := {}
    Local lOkEA  := .F.
    Local cMsg   := ""

    // Validação mínima
    If Empty(cCod) .Or. Empty(cLoja) .Or. Empty(cNome)
        AAdd(aLog, "Linha inválida (faltou COD/LOJA/NOME): " + cCod + "/" + cLoja)
        Return .F.
    EndIf

    // ---------------------------
    // 1) ExecAuto (Upsert)
    // ---------------------------
    AAdd(aDados, {"A1_COD" , cCod , NIL})
    AAdd(aDados, {"A1_LOJA", cLoja, NIL})
    AAdd(aDados, {"A1_NOME", cNome, NIL})

    // opcionais do layout
    If !Empty(cCgc)  ; AAdd(aDados, {"A1_CGC", cCgc, NIL}) ; EndIf
    If !Empty(cEnd)  ; AAdd(aDados, {"A1_END", cEnd, NIL}) ; EndIf
    If !Empty(cMun)  ; AAdd(aDados, {"A1_MUN", cMun, NIL}) ; EndIf
    If !Empty(cCep)  ; AAdd(aDados, {"A1_CEP", cCep, NIL}) ; EndIf

    // OBS: Se seu ambiente exigir outros campos obrigatórios, inclua aqui.

    lOkEA := _TryAlterThenIncludeEA(aDados, @cMsg)

    If !lOkEA
        AAdd(aLog, "ExecAuto erro [" + cCod + "-" + cLoja + "]: " + cMsg)
        Return .F.
    EndIf

    // ---------------------------
    // 2) Update convencional SEM ExecAuto (campos “à sua escolha”)
    //    - posiciona registro e edita com RecLock
    // ---------------------------
    If !_UpdateConvencionalSA1(cCod, cLoja, cEmail, cTel, @cMsg)
        AAdd(aLog, "Update conv. erro [" + cCod + "-" + cLoja + "]: " + cMsg)
        // opcional: considerar como sucesso parcial ou erro total
        Return .F.
    EndIf

Return .T.


// ------------------------------------------------
// ExecAuto: tenta alterar (3), se falhar tenta incluir (1)
// ------------------------------------------------
Static Function _TryAlterThenIncludeEA(aDados, cMsg)
    Local lErro := .F.

    cMsg := ""

    // ALTERAÇÃO
    MsExecAuto({|x,y,z| MATA030(x,y,z)}, aDados, 3)
    lErro := _HasExecAutoError()

    If !lErro
        Return .T.
    EndIf

    cMsg := _GetExecAutoErrorMsg()

    // INCLUSÃO
    _ClearExecAutoError()
    MsExecAuto({|x,y,z| MATA030(x,y,z)}, aDados, 1)
    lErro := _HasExecAutoError()

    If lErro
        cMsg := _GetExecAutoErrorMsg()
        Return .F.
    EndIf

Return .T.


// ------------------------------------------------
// Update convencional sem ExecAuto (posiciona e altera)
// Campos exemplo: A1_EMAIL, A1_TEL
// ------------------------------------------------
Static Function _UpdateConvencionalSA1(cCod, cLoja, cEmail, cTel, cMsg)
    Local lOk := .F.
    Local cKey := ""

    cMsg := ""

    DbSelectArea("SA1")
    SA1->(DbSetOrder(1)) // Ajuste: ordem 1 normalmente é por A1_FILIAL + A1_COD + A1_LOJA

    cKey := xFilial("SA1") + cCod + cLoja

    If !SA1->(DbSeek(cKey))
        cMsg := "Cliente não encontrado para update convencional."
        Return .F.
    EndIf

    // Trava e altera
    If RecLock("SA1", .F.)
        If !Empty(cEmail)
            SA1->A1_EMAIL := cEmail
        EndIf

        If !Empty(cTel)
            SA1->A1_TEL := cTel
        EndIf

        MsUnlock()
        lOk := .T.
    Else
        cMsg := "Não foi possível travar registro (RecLock)."
        lOk := .F.
    EndIf

Return lOk


// ================================================================
// Utilitários (CSV / leitura / seleção)
// ================================================================

Static Function _EscolheArquivoCSV()
    Local cFile := ""

    // Em muitos ambientes: cGetFile( aExt, cTitulo, nModo, cDirIni, lNew )
    If Type("cGetFile") <> "U"
        cFile := cGetFile("CSV|*.csv", "Selecione o CSV de clientes", 0, "", .F.)
    Else
        cFile := AllTrim(MsgGet("Arquivo", "Informe o caminho completo do CSV (ex: C:\TEMP\clientes.csv):"))
    EndIf

Return cFile


Static Function _EscolheDiretorio()
    Local cDir := ""

    If Type("cGetDir") <> "U"
        cDir := cGetDir("Selecione o diretório")
    Else
        cDir := AllTrim(MsgGet("Diretório", "Informe o diretório (ex: C:\TEMP):"))
    EndIf

Return cDir


// Lê linha do arquivo (retorna NIL no EOF)
Static Function _ReadLine(nH)
    Local c := ""
    Local n := 0
    Local cChr := ""

    If nH < 0
        Return NIL
    EndIf

    // EOF?
    If FEOF(nH)
        Return NIL
    EndIf

    // Leitura char a char (simples e suficiente p/ 1000 linhas).
    // Se quiser, dá pra otimizar com buffer.
    While !FEOF(nH)
        cChr := FReadStr(nH, 1)
        If cChr == Chr(10) // LF
            Exit
        ElseIf cChr == Chr(13) // CR
            Loop
        EndIf
        c += cChr
    EndDo

Return c


// Split simples por ';' (para layout sem aspas/escape)
Static Function _SplitSemi(cLine)
    Local a := {}
    Local nPos := 0
    Local cTmp := cLine

    // Remove espaços finais
    cTmp := AllTrim(cTmp)

    // Split manual (compatível)
    While .T.
        nPos := At(";", cTmp)
        If nPos == 0
            AAdd(a, AllTrim(cTmp))
            Exit
        EndIf

        AAdd(a, AllTrim(SubStr(cTmp, 1, nPos-1)))
        cTmp := SubStr(cTmp, nPos+1)
    EndDo

Return a


// Cria mapa: campo -> posição
Static Function _BuildMap(aHead)
    Local o := {}
    Local i := 0
    Local c := ""

    For i := 1 To Len(aHead)
        c := Upper(AllTrim(aHead[i]))
        If !Empty(c)
            o[c] := i
        EndIf
    Next

Return o


Static Function _HasCol(oMap, cCol)
    Return (HB_HHasKey(oMap, Upper(cCol)))
Return .F.


// Get valor por coluna (se não existir, retorna "")
Static Function _Get(oMap, aCols, cCol)
    Local cKey := Upper(cCol)
    Local nPos := 0

    If !HB_HHasKey(oMap, cKey)
        Return ""
    EndIf

    nPos := oMap[cKey]
    If nPos <= 0 .Or. nPos > Len(aCols)
        Return ""
    EndIf

Return AllTrim(aCols[nPos])


// ------------------------------------------------
// ExecAuto error helpers
// ------------------------------------------------
Static Function _HasExecAutoError()
    Return ( Len(GetAutoGRLog()) > 0 )
Return .F.

Static Function _GetExecAutoErrorMsg()
    Local aLog := GetAutoGRLog()
    Local cMsg := "Erro ExecAuto."

    If Len(aLog) > 0
        cMsg := aLog[1]
    EndIf

Return cMsg

Static Function _ClearExecAutoError()
    // Normalmente não precisa limpar; log é por execução.
    // Se seu padrão tiver função própria para limpar, coloque aqui.
Return