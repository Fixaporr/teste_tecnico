#Include "protheus.ch"
#Include "topconn.ch"
#Include "restful.ch"

/* =======================================================================
   PROTHEUS - Integração SA1 (Clientes)
   -----------------------------------------------------------------------
   1) CLIENTE REST: Envia clientes ativos (SA1) para API externa
   ----------------------------------------------------------------------- */

User Function ENVIA_SA1()
    Local cUrl      := "https://sua-api.com.br/clientes/import" // AJUSTE
    Local cToken    := "Bearer SEU_TOKEN"                       // AJUSTE
    Local oHttp     := NIL
    Local oJsonReq  := JsonObject():New()
    Local aClientes := {}
    Local cBody     := ""
    Local nStatus   := 0
    Local cResp     := ""
    Local lOk       := .F.

    // 1) Coleta clientes ativos
    aClientes := _GetClientesAtivosSA1()

    If Len(aClientes) == 0
        MsgInfo("Nenhum cliente ativo encontrado para envio.")
        Return .T.
    EndIf

    // 2) Monta JSON (estrutura simples)
    // { "clientes": [ {codigo:"000001", nome:"X", ...}, ... ] }
    oJsonReq["clientes"] := aClientes
    cBody := oJsonReq:ToJson()

    // 3) POST + headers
    oHttp := FWRest():New(cUrl)
    oHttp:SetContentType("application/json; charset=utf-8")
    oHttp:AddHeader("Authorization", cToken)

    lOk := oHttp:Post(cBody)

    nStatus := oHttp:GetLastStatus()
    cResp   := oHttp:GetResult()

    // 4) Tratamento por status
    Do Case
    Case lOk .And. (nStatus == 200 .Or. nStatus == 201)
        MsgInfo("Envio OK. Status: " + cValToChar(nStatus) + CRLF + "Resposta: " + cResp)

    Case nStatus >= 400 .And. nStatus < 500
        MsgStop("Erro de requisição (4xx). Status: " + cValToChar(nStatus) + CRLF + "Resposta: " + cResp)

    Case nStatus >= 500
        MsgStop("Erro no servidor (5xx). Status: " + cValToChar(nStatus) + CRLF + "Resposta: " + cResp)

    Otherwise
        MsgStop("Falha no POST. Status: " + cValToChar(nStatus) + CRLF + "Resposta: " + cResp)
    EndCase

Return .T.


/* Busca SA1 clientes ativos e retorna Array com objeto */
Static Function _GetClientesAtivosSA1()
    Local aRet := {}
    Local cQry := ""

    // Critério "ativo": sem esta D_E_L_E_T_
    cQry := "SELECT A1_COD, A1_NOME, A1_CGC, A1_END, A1_MUN, A1_CEP " + ;
            "  FROM " + RetSqlName("SA1") + " SA1 " + ;
            " WHERE SA1.D_E_L_E_T_ = ' ' " + ;
            "   AND SA1.A1_MSBLQL <> '1' "

    TCQuery cQry New Alias "QSA1"

    While !QSA1->(Eof())
        Local oCli := JsonObject():New()

        oCli["codigo"]   := AllTrim(QSA1->A1_COD)
        oCli["nome"]     := AllTrim(QSA1->A1_NOME)
        oCli["cnpj"]     := AllTrim(QSA1->A1_CGC)
        oCli["endereco"] := AllTrim(QSA1->A1_END)
        oCli["cidade"]   := AllTrim(QSA1->A1_MUN)
        oCli["cep"]      := AllTrim(QSA1->A1_CEP)

        AAdd(aRet, oCli)
        QSA1->(DbSkip())
    EndDo

    QSA1->(DbCloseArea())

Return aRet


/* -----------------------------------------------------------------------
   2) SERVIDOR REST: Atualiza/Inclui cliente via ExecAuto
   ----------------------------------------------------------------------- */

WSRESTFUL CLIENTES DESCRIPTION "API Clientes SA1"

    WSMETHOD POST DESCRIPTION "Cria/Atualiza cliente via JSON" ;
        WSSYNTAX "/api/clientes" ;
        PRODUCES APPLICATION_JSON ;
        CONSUMES APPLICATION_JSON

    WSMETHOD PUT DESCRIPTION "Atualiza cliente por código via JSON" ;
        WSSYNTAX "/api/clientes/{codigo}" ;
        PRODUCES APPLICATION_JSON ;
        CONSUMES APPLICATION_JSON

END WSRESTFUL


/* POST /api/clientes */
WSMETHOD POST WSRECEIVE BODY oBody WSRESTFUL CLIENTES
    Local oReq   := JsonObject():New()
    Local oResp  := JsonObject():New()
    Local cBody  := Self:GetContent()
    Local lOk    := .F.
    Local cMsg   := ""

    If Empty(cBody)
        Self:SetStatus(400)
        oResp["ok"] := .F.
        oResp["erro"] := "Body vazio."
        Return Self:SetResponse(oResp:ToJson())
    EndIf

    If !oReq:FromJson(cBody)
        Self:SetStatus(400)
        oResp["ok"] := .F.
        oResp["erro"] := "JSON inválido."
        Return Self:SetResponse(oResp:ToJson())
    EndIf

    If Empty(AllTrim(oReq["codigo"])) .Or. Empty(AllTrim(oReq["nome"]))
        Self:SetStatus(400)
        oResp["ok"] := .F.
        oResp["erro"] := "Campos obrigatórios: codigo, nome."
        Return Self:SetResponse(oResp:ToJson())
    EndIf

    lOk := _UpsertClienteSA1_ExecAuto(oReq, @cMsg)

    If lOk
        Self:SetStatus(200)
        oResp["ok"] := .T.
        oResp["mensagem"] := "Cliente atualizado com sucesso."
        oResp["cliente"] := _RespClienteSimples(oReq)
    Else
        Self:SetStatus(400)
        oResp["ok"] := .F.
        oResp["erro"] := cMsg
    EndIf

Return Self:SetResponse(oResp:ToJson())


/* PUT /api/clientes/{codigo} */
WSMETHOD PUT WSRECEIVE BODY oBody WSRESTFUL CLIENTES
    Local oReq   := JsonObject():New()
    Local oResp  := JsonObject():New()
    Local cCodigo := AllTrim(Self:GetParam("codigo"))
    Local cBody  := Self:GetContent()
    Local lOk    := .F.
    Local cMsg   := ""

    If Empty(cCodigo)
        Self:SetStatus(400)
        oResp["ok"] := .F.
        oResp["erro"] := "Parametro {codigo} é obrigatório."
        Return Self:SetResponse(oResp:ToJson())
    EndIf

    If Empty(cBody)
        Self:SetStatus(400)
        oResp["ok"] := .F.
        oResp["erro"] := "Body vazio."
        Return Self:SetResponse(oResp:ToJson())
    EndIf

    If !oReq:FromJson(cBody)
        Self:SetStatus(400)
        oResp["ok"] := .F.
        oResp["erro"] := "JSON inválido."
        Return Self:SetResponse(oResp:ToJson())
    EndIf

    // Força código do path
    oReq["codigo"] := cCodigo

    If Empty(AllTrim(oReq["nome"]))
        Self:SetStatus(400)
        oResp["ok"] := .F.
        oResp["erro"] := "Campo obrigatório: nome."
        Return Self:SetResponse(oResp:ToJson())
    EndIf

    lOk := _UpsertClienteSA1_ExecAuto(oReq, @cMsg)

    If lOk
        Self:SetStatus(200)
        oResp["ok"] := .T.
        oResp["mensagem"] := "Cliente atualizado com sucesso."
        oResp["cliente"] := _RespClienteSimples(oReq)
    Else
        Self:SetStatus(400)
        oResp["ok"] := .F.
        oResp["erro"] := cMsg
    EndIf

Return Self:SetResponse(oResp:ToJson())

Static Function _RespClienteSimples(oReq)
    Local oCli := JsonObject():New()

    oCli["codigo"]   := AllTrim(oReq["codigo"])
    oCli["nome"]     := AllTrim(oReq["nome"])
    oCli["cnpj"]     := AllTrim(oReq["cnpj"])
    oCli["endereco"] := AllTrim(oReq["endereco"])
    oCli["cidade"]   := AllTrim(oReq["cidade"])
    oCli["cep"]      := AllTrim(oReq["cep"])

Return oCli


/* Upsert em SA1 via ExecAuto */
Static Function _UpsertClienteSA1_ExecAuto(oReq, cMsg)
    Local aDados := {}
    Local lOk    := .F.

    cMsg := ""

    // Campos
    AAdd(aDados, {"A1_COD" , AllTrim(oReq["codigo"])  , NIL})
    AAdd(aDados, {"A1_NOME", AllTrim(oReq["nome"])    , NIL})
    AAdd(aDados, {"A1_CGC" , AllTrim(oReq["cnpj"])    , NIL})
    AAdd(aDados, {"A1_END" , AllTrim(oReq["endereco"]), NIL})
    AAdd(aDados, {"A1_MUN" , AllTrim(oReq["cidade"])  , NIL})
    AAdd(aDados, {"A1_CEP" , AllTrim(oReq["cep"])     , NIL})

    // Se necessário (ambientes exigem loja/filial):
    // AAdd(aDados, {"A1_LOJA", "01", NIL})

    Begin Transaction
        lOk := _TryAlterThenInclude(aDados, @cMsg)

        If !lOk
            DisarmTransaction
        EndIf
    End Transaction

Return lOk


/* Tenta alterar; se falhar, tenta incluir */
Static Function _TryAlterThenInclude(aDados, cMsg)
    Local lErro := .F.

    // 1) ALTERAÇÃO (3)
    MsExecAuto({|x,y,z| MATA030(x,y,z)}, aDados, 3)
    lErro := _HasExecAutoError()

    If !lErro
        Return .T.
    EndIf

    // 2) INCLUSÃO (1)
    _ClearExecAutoError()
    MsExecAuto({|x,y,z| MATA030(x,y,z)}, aDados, 1)
    lErro := _HasExecAutoError()

    If lErro
        cMsg := _GetExecAutoErrorMsg()
        Return .F.
    EndIf

Return .T.


/* Helpers de erro ExecAuto */
Static Function _HasExecAutoError()
    Return ( Len(GetAutoGRLog()) > 0 )
Return .F.

Static Function _GetExecAutoErrorMsg()
    Local aLog := GetAutoGRLog()
    Local cMsg := ""

    If Len(aLog) > 0
        cMsg := aLog[1]
    Else
        cMsg := "Erro ExecAuto (sem log disponível)."
    EndIf

Return cMsg

Static Function _ClearExecAutoError()

Return
