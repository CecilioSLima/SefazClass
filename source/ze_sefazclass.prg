/*
ZE_SEFAZCLASS - Rotinas pra comunica��o com SEFAZ
Jos� Quintas

Nota: CTE 2.00 vale at� 10/2017, CTE 2.00 at� 12/2017, NFE 3.10 at� 04/2018

2017.11.27 Aceita arquivo PFX pra assinatura somente
2018.03.13 SoapList de CTE e MDFE nos m�todos
*/

#include "hbclass.ch"
#include "sefazclass.ch"
#include "hb2xhb.ch"

#ifdef __XHARBOUR__
   #define ALL_PARAMETERS P1, P2, P3, P4, P5, P6, P7, P8, P9, P10
#else
   #define ALL_PARAMETERS ...
#endif

CREATE CLASS SefazClass

   /* configura��o */
   VAR    cProjeto        INIT NIL
   VAR    cAmbiente       INIT WS_AMBIENTE_PRODUCAO
   VAR    cVersao         INIT NIL
   VAR    cScan           INIT "N"                     // Indicar se for SCAN/SVAN, ainda n�o testado
   VAR    cUF             INIT "SP"                    // Modificada conforme m�todo
   VAR    cCertificado    INIT ""                      // Nome do certificado
   VAR    ValidFromDate   INIT ""                      // Validade do certificado
   VAR    ValidToDate     INIT ""                      // Validade do certificado
   VAR    cIndSinc        INIT WS_RETORNA_RECIBO       // Poucas UFs op��o de protocolo
   VAR    nTempoEspera    INIT 7                       // intervalo entre envia lote e consulta recibo
   VAR    cUFTimeZone     INIT "SP"                    // Para DateTimeXml() Obrigat�rio definir UF default
   VAR    cIdToken        INIT ""                      // Para NFCe obrigatorio identificador do CSC C�digo de Seguran�a do Contribuinte
   VAR    cCSC            INIT ""                      // Para NFCe obrigatorio CSC C�digo de Seguran�a do Contribuinte
   VAR    cPassword       INIT ""                      // Senha de arquivo PFX
   /* XMLs de cada etapa */
   VAR    cXmlDocumento   INIT ""                      // O documento oficial, com ou sem assinatura, depende do documento
   VAR    cXmlEnvio       INIT ""                      // usado pra criar/complementar XML do documento
   VAR    cXmlSoap        INIT ""                      // XML completo enviado pra Sefaz, incluindo informa��es do envelope
   VAR    cXmlRetorno     INIT [<erro text="*ERRO* Erro Desconhecido" />]    // Retorno do webservice e/ou rotina
   VAR    cXmlRecibo      INIT ""                      // XML recibo (obtido no envio do lote)
   VAR    cXmlProtocolo   INIT ""                      // XML protocolo (obtido no consulta recibo e/ou envio de outros docs)
   VAR    cXmlAutorizado  INIT ""                      // XML autorizado, caso tudo ocorra sem problemas
   VAR    cStatus         INIT Space(3)                // Status obtido da resposta final da Fazenda
   VAR    cRecibo         INIT ""                      // N�mero do recibo
   VAR    cMotivo         INIT ""                      // Motivo constante no Recibo
   /* uso interno */
   VAR    cSoapService    INIT ""                      // webservice Servi�o
   VAR    cSoapAction     INIT ""                      // webservice Action
   VAR    cSoapURL        INIT ""                      // webservice Endere�o
   VAR    cXmlNameSpace   INIT "xmlns="
   VAR    cNFCE           INIT "N"                     // Porque NFCE tem endere�os diferentes
   VAR    aSoapUrlList    INIT {}

   METHOD BPeConsultaProtocolo( cChave, cCertificado, cAmbiente )
   METHOD BPeStatusServico( cUF, cCertificado, cAmbiente )

   METHOD CTeConsultaProtocolo( cChave, cCertificado, cAmbiente )
   METHOD CTeConsultaRecibo( cRecibo, cUF, cCertificado, cAmbiente )
   METHOD CTeEventoSoapList()
   METHOD CTeEventoCancela( cChave, nSequencia, nProt, xJust, cCertificado, cAmbiente )
   METHOD CTeEventoCarta( cChave, nSequencia, aAlteracoes, cCertificado, cAmbiente )
   METHOD CTeEventoDesacordo( cChave, nSequencia, cObs, cCertificado, cAmbiente )
   METHOD CTeGeraAutorizado( cXmlAssinado, cXmlProtocolo )
   METHOD CTeGeraEventoAutorizado( cXmlAssinado, cXmlProtocolo )
   METHOD CTeInutiliza( cAno, cCnpj, cMod, cSerie, cNumIni, cNumFim, cJustificativa, cUF, cCertificado, cAmbiente )
   METHOD CTeLoteEnvia( cXml, cLote, cUF, cCertificado, cAmbiente )
   METHOD CTeStatusServico( cUF, cCertificado, cAmbiente )

   METHOD MDFeConsNaoEnc( CUF, cCNPJ , cCertificado, cAmbiente )
   METHOD MDFeConsultaProtocolo( cChave, cCertificado, cAmbiente )
   METHOD MDFeConsultaRecibo( cRecibo, cUF, cCertificado, cAmbiente )
   METHOD MDFeDistribuicaoDFe( cCnpj, cUltNSU, cNSU, cUF, cCertificado, cAmbiente )
   METHOD MDFeEventoSoapList()
   METHOD MDFeEventoCancela( cChave, nSequencia, nProt, xJust, cCertificado, cAmbiente )
   METHOD MDFeEventoEncerramento( cChave, nSequencia, nProt, cUFFim, cMunCarrega, cCertificado, cAmbiente )
   METHOD MDFeEventoInclusaoCondutor( cChave, nSequencia, cNome, cCpf, cCertificado, cAmbiente )
   METHOD MDFeGeraAutorizado( cXmlAssinado, cXmlProtocolo )
   METHOD MDFeGeraEventoAutorizado( cXmlAssinado, cXmlProtocolo )
   METHOD MDFeLoteEnvia( cXml, cLote, cUF, cCertificado, cAmbiente )
   METHOD MDFeStatusServico( cUF, cCertificado, cAmbiente )

   METHOD NFeConsultaCadastro( cCnpj, cUF, cCertificado, cAmbiente )

   METHOD NFeConsultaDest( cCnpj, cUltNsu, cIndNFe, cIndEmi, cUf, cCertificado, cAmbiente )
   METHOD NFeConsultaProtocolo( cChave, cCertificado, cAmbiente )
   METHOD NFeConsultaRecibo( cRecibo, cUF, cCertificado, cAmbiente )
   METHOD NFeDistribuicaoDFe( cCnpj, cUltNSU, cNSU, cUF, cCertificado, cAmbiente )
   METHOD NFeEventoSoapList()
   METHOD NFeEventoCancela( cChave, nSequencia, nProt, xJust, cCertificado, cAmbiente )
   METHOD NFeEventoCarta( cChave, nSequencia, cTexto, cCertificado, cAmbiente )
   METHOD NFeEventoManifestacao( cChave, nSequencia, xJust, cCodigoEvento, cCertificado, cAmbiente )
   METHOD NFeGeraAutorizado( cXmlAssinado, cXmlProtocolo )
   METHOD NFeGeraEventoAutorizado( cXmlAssinado, cXmlProtocolo )
   METHOD NFeInutiliza( cAno, cCnpj, cMod, cSerie, cNumIni, cNumFim, cJustificativa, cUF, cCertificado, cAmbiente )
   METHOD NFeLoteEnvia( cXml, cLote, cUF, cCertificado, cAmbiente, cIndSinc )
   METHOD NFeStatusServico( cUF, cCertificado, cAmbiente )

   METHOD CTeAddCancelamento( cXmlAssinado, cXmlCancelamento )
   METHOD NFeAddCancelamento( cXmlAssinado, cXmlCancelamento )

   /* Uso interno */
   METHOD SetSoapURL()
   METHOD XmlSoapEnvelope()
   METHOD XmlSoapPost()
   METHOD MicrosoftXmlSoapPost()

   /* Apenas redirecionamento */
   METHOD AssinaXml()                                 INLINE ::cXmlRetorno := CapicomAssinaXml( @::cXmlDocumento, ::cCertificado,,::cPassword )
   METHOD TipoXml( cXml )                             INLINE TipoXml( cXml )
   METHOD UFCodigo( cSigla )                          INLINE UFCodigo( cSigla )
   METHOD UFSigla( cCodigo )                          INLINE UFSigla( cCodigo )
   METHOD DateTimeXml( dDate, cTime, lUTC )           INLINE DateTimeXml( dDate, cTime, iif( ::cUFTimeZone == NIL, ::cUF, ::cUFTimeZone ), lUTC )
   METHOD ValidaXml( cXml, cFileXsd )                 INLINE ::cXmlRetorno := DomDocValidaXml( cXml, cFileXsd )
   METHOD Setup( cUF, cCertificado, cAmbiente )

   ENDCLASS

METHOD BPeConsultaProtocolo( cChave, cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cVersao, "1.00" )
   hb_Default( @::cProjeto, WS_PROJETO_BPE )
   ::aSoapUrlList := { ;
         { "MS",   "1.00P", "https://bpe.fazenda.ms.gov.br/ws/BPeConsulta" }, ;
         { "SVRS", "1.00P", "https://bpe.svrs.rs.gov.br/ms/bpeConsulta.asmx" }, ;
         ;
         { "MS",   "1.00H", "https://homologacao.bpe.ms.gov.br/ws/BPeConsulta" } }
   ::Setup( cChave, cCertificado, cAmbiente )
   ::cSoapAction  := "BpeConsulta"
   ::cSoapService := "http://www.portalfiscal.inf.br/bpe/wsdl/BPeConsulta/bpeConsultaBP"

   ::cXmlEnvio := [<consSitBPe> versao="] + ::cVersao + [" ] + WS_XMLNS_BPE + [>]
   ::cXmlEnvio +=   XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlEnvio +=   XmlTag( "xServ", "CONSULTAR" )
   ::cXmlEnvio +=   XmlTag( "chBPe", cChave )
   ::cXmlEnvio += [</conssitBPe>]
   IF DfeModFis( cChave ) != "63"
      ::cXmlRetorno := [<erro text="*ERRO* BpeConsultaProtocolo() Chave n�o se refere a BPE" />]
   ELSE
      ::XmlSoapPost()
   ENDIF
   ::cStatus := XmlNode( ::cXmlRetorno, "cStat" )
   ::cMotivo := XmlNode( ::cXmlRetorno, "xMotivo" )

   RETURN ::cXmlRetorno

      //::aSoapActionList := { ;
      //{ "**", WS_BPE_RECEPCAO,          "1.00", "BpeRecepcao",          "http://www.portalfiscal.inf.br/bpe/wsdl/BPeRecepcao/bpeRecepcao" } }
      //::aSoapActionList := { ;
      //{ "**", WS_BPE_RECEPCAOEVENTO,    "1.00", "BpeRecepcaoEvento",    "http://www.portalfiscal.inf.br/bpe/wsdl/bpeRecepcaoEvento" } }
     //::aSoapUrlList := { ;
         //{ "MS",   "1.00", WS_AMBIENTE_PRODUCAO,     "https://bpe.fazenda.ms.gov.br/ws/BPeRecepcao" }, ;
         //{ "SVRS", "1.00", WS_AMBIENTE_PRODUCAO,     "https://bpe.svrs.rs.gov.br/ws/bpeRecepcao/bpeRecepcao.asmx" }, ;
         //;
         //{ "MS",   "1.00", WS_AMBIENTE_HOMOLOGACAO,  "https://homologacao.bpe.ms.gov.br/ws/BPeRecepcao" }, ;
         //{ "SVRS", "1.00", WS_AMBIENTE_HOMOLOGACAO,  "https://bpe-homologacao.srvs.rs.gov.br/ws/bpeRecepcao/bpeRecepcao.asmx" } }

      //::aSoapUrlList := { ;
         //{ "MS",   "1.00", WS_AMBIENTE_PRODUCAO,     "https://bpe.fazenda.ms.gov.br/ws/BPeRecepcaoEvento" }, ;
         //{ "SVRS", "1.00", WS_AMBIENTE_PRODUCAO,     "https://bpe.svrs.rs.gov.br/ms/bpeRecepcaoEvento/bpeRecepcaoEvento.asmx" }, ;
         //;
         //{ "MS",   "1.00", WS_AMBIENTE_HOMOLOGACAO,  "https://homologacao.bpe.ms.gov.br/ws/BPeRecepcaoEvento" }, ;
         //{ "SVRS", "1.00", WS_AMBIENTE_HOMOLOGACAO,  "https://bpe-homologacao.svrs.rs.gov.br/ws/bpeRecepcaoEvento/bpeRecepcaoEvento.asmx" } }

      //aSoapUrlList := { ;
         //{ "MS",   "1.00", WS_AMBIENTE_PRODUCAO,     "http://dfe.ms.gov.br/bpe/qrcode" }, ;
         //{ "SVRS", "1.00", WS_AMBIENTE_PRODUCAO,     "https://bpe.svrs.rs.gov.br/ws/bpeQrCode/qrCode.asmx" }, ;
         //;
         //{ "MS",   "1.00", WS_AMBIENTE_HOMOLOGACAO,  "http//www.dfe.ms.gov.br/bpe/qrcode" }, ;
         //{ "SVRS", "1.00", WS_AMBIENTE_HOMOLOGACAO,  "https://bpe-homologacao.svrs.rs.gov.br/ws/bpeQrCode/qrCode.asmx" } }

METHOD BPeStatusServico( cUF, cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cVersao, "1.00" )
   hb_Default( @::cProjeto, WS_PROJETO_BPE )
   ::aSoapUrlList := { ;
         { "MS",   "1.00P", "https://bpe.fazenda.ms.gov.br/ws/BPeStatusServico" }, ;
         { "SVRS", "1.00P", "https://bpe.svrs.rs.gov.br/ms/bpeStatusServico/bpeStatusServico.asmx" }, ;
         ;
         { "MS",   "1.00H", "https://homologacao.bpe.ms.gov.br/ws/BPeStatusServico" }, ;
         { "SVRS", "1.00H", "https://bpe-homologacao.svrs.rs.gov.br/ws/bpeStatusServico/bpeStatusServico.asmx" } }
   ::Setup( cUF, cCertificado, cAmbiente )
   ::cSoapAction  := "BpeStatusServicoBP"
   ::cSoapService := "http://www.portalfiscal.inf.br/bpe/wsdl/BPeStatusServico"

   ::cXmlEnvio := [<consStatServBPe versao="] + ::cVersao + [" ] + WS_XMLNS_BPE + [>]
   ::cXmlEnvio +=    XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlEnvio +=    XmlTag( "xServ", "STATUS" )
   ::cXmlEnvio += [</consStatServBPe>]
   ::XmlSoapPost()

   RETURN ::cXmlRetorno

      //::aSoapUrlList := { ;
         //{ "MS",   "3.00", WS_AMBIENTE_PRODUCAO,    "https://producao.cte.ms.gov.br/ws/CadConsultaCadastro" } }

METHOD CTeConsultaProtocolo( cChave, cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cVersao, "3.00" )
   hb_Default( @::cProjeto, WS_PROJETO_CTE )
   ::aSoapUrlList := { ;
         { "MG",   "3.00P", "https://cte.fazenda.mg.gov.br/cte/services/CteConsulta" }, ;
         { "MS",   "3.00P", "https://producao.cte.ms.gov.br/ws/CteConsulta" }, ;
         { "MT",   "3.00P", "https://cte.sefaz.mt.gov.br/ctews/services/CteConsulta" }, ;
         { "SP",   "3.00P", "https://nfe.fazenda.sp.gov.br/cteWEB/services/cteConsulta.asmx" }, ;
         { "PR",   "3.00P", "https://cte.fazenda.pr.gov.br/cte/CteConsulta?wsdl" }, ;
         { "SVSP", "3.00P", "https://nfe.fazenda.sp.gov.br/cteWEB/services/CteConsulta.asmx" }, ;
         { "SVRS", "3.00P", "https://cte.svrs.rs.gov.br/ws/cteconsulta/CteConsulta.asmx" }, ;
         ;
         { "SP",   "3.00H", "https://homologacao.nfe.fazenda.sp.gov.br/cteWEB/services/cteConsulta.asmx" }, ;
         { "SVRS", "3.00H", "https://cte-homologacao.svrs.rs.gov.br/ws/cteconsulta/CteConsulta.asmx" } }
   ::Setup( cChave, cCertificado, cAmbiente )
   ::cSoapAction  := "cteConsultaCT"
   ::cSoapService := "http://www.portalfiscal.inf.br/cte/wsdl/CteConsulta"

   ::cXmlEnvio    := [<consSitCTe versao="] + ::cVersao + [" ] + WS_XMLNS_CTE + [>]
   ::cXmlEnvio    +=    XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlEnvio    +=    XmlTag( "xServ", "CONSULTAR" )
   ::cXmlEnvio    +=    XmlTag( "chCTe", cChave )
   ::cXmlEnvio    += [</consSitCTe>]
   IF ! DfeModFis( cChave ) $ "57,67"
      ::cXmlRetorno := [<erro text="*ERRO* CteConsultaProtocolo() Chave n�o se refere a CTE" />]
   ELSE
      ::XmlSoapPost()
   ENDIF
   ::cStatus := XmlNode( ::cXmlRetorno, "cStat" )
   ::cMotivo := XmlNode( ::cXmlRetorno, "xMotivo" )

   RETURN ::cXmlRetorno

METHOD CTeConsultaRecibo( cRecibo, cUF, cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cVersao, "3.00" )
   hb_Default( @::cProjeto, WS_PROJETO_CTE )
   IF cRecibo != NIL
      ::cRecibo := cRecibo
   ENDIF
   ::aSoapUrlList := { ;
      { "MG",   "3.00P", "https://cte.fazenda.mg.gov.br/cte/services/CteRetRecepcao" }, ;
      { "MS",   "3.00P", "https://producao.cte.ms.gov.br/ws/CteRetRecepcao" }, ;
      { "MT",   "3.00P", "https://cte.sefaz.mt.gov.br/ctews/services/CteRetRecepcao" }, ;
      { "PR",   "3.00P", "https://cte.fazenda.pr.gov.br/cte/CteRetRecepcao?wsdl" }, ;
      { "SP",   "3.00P", "https://nfe.fazenda.sp.gov.br/cteWEB/services/cteRetRecepcao.asmx" }, ;
      { "SVSP", "3.00P", "https://nfe.fazenda.sp.gov.br/cteWEB/services/CteRetRecepcao.asmx" }, ;
      { "SVRS", "3.00P", "https://cte.svrs.rs.gov.br/ws/cteretrecepcao/cteRetRecepcao.asmx" }, ;
      ;
      { "SP",   "3.00H", "https://homologacao.nfe.fazenda.sp.gov.br/cteWEB/services/cteRetRecepcao.asmx" }, ;
      { "SVRS", "3.00H", "https://cte-homologacao.svrs.rs.gov.br/ws/cteretrecepcao/cteRetRecepcao.asmx" } }
   ::Setup( cUF, cCertificado, cAmbiente )
   ::cSoapAction  := "cteRetRecepcao"
   ::cSoapService := "http://www.portalfiscal.inf.br/cte/wsdl/CteRetRecepcao"

   ::cXmlEnvio     := [<consReciCTe versao="] + ::cVersao + [" ] + WS_XMLNS_CTE + [>]
   ::cXmlEnvio     +=    XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlEnvio     +=    XmlTag( "nRec",  ::cRecibo )
   ::cXmlEnvio     += [</consReciCTe>]
   ::XmlSoapPost()
   ::cXmlProtocolo := ::cXmlRetorno                                           // ? hb_Utf8ToStr()
   ::cMotivo       := XmlNode( XmlNode( ::cXmlRetorno, "infProt" ), "xMotivo" ) // ? hb_Utf8ToStr()

   RETURN ::cXmlRetorno // ? hb_Utf8ToStr()

METHOD CTeEventoSoapList() CLASS SefazClass

   hb_Default( @::cVersao, "3.00" )
   hb_Default( @::cProjeto, WS_PROJETO_CTE )
   ::aSoapUrlList := { ;
      { "MG",   "3.00P", "https://cte.fazenda.mg.gov.br/cte/services/RecepcaoEvento" }, ;
      { "MS",   "3.00P", "https://producao.cte.ms.gov.br/ws/CteRecepcaoEvento" }, ;
      { "MT",   "3.00P", "https://cte.sefaz.mt.gov.br/ctews2/services/CteRecepcaoEvento?wsdl" }, ;
      { "PR",   "3.00P", "https://cte.fazenda.pr.gov.br/cte/CteRecepcaoEvento?wsdl" }, ;
      { "SP",   "3.00P", "https://nfe.fazenda.sp.gov.br/cteweb/services/cteRecepcaoEvento.asmx" }, ;
      { "SVRS", "3.00P", "https://cte.svrs.rs.gov.br/ws/cterecepcaoevento/cterecepcaoevento.asmx" }, ;
      ;
      { "SP",   "3.00H", "https://homologacao.nfe.fazenda.sp.gov.br/cteweb/services/cteRecepcaoEvento.asmx" }, ;
      { "SVRS", "3.00H", "https://cte-homologacao.svrs.rs.gov.br/ws/cterecepcaoevento/cterecepcaoevento.asmx" } }
   ::cSoapAction  := "cteRecepcaoEvento"
   ::cSoapService := "http://www.portalfiscal.inf.br/cte/wsdl/CteRecepcaoEvento"

      RETURN NIL

METHOD CTeEventoCancela( cChave, nSequencia, nProt, xJust, cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cVersao, "3.00" )
   hb_Default( @::cProjeto, WS_PROJETO_CTE )
   hb_Default( @nSequencia, 1 )

   ::CTeEventoSoapList()
   ::Setup( cChave, cCertificado, cAmbiente )

   ::cXmlDocumento := [<eventoCTe versao="] + ::cVersao + [" ] + WS_XMLNS_CTE + [>]
   ::cXmlDocumento +=    [<infEvento Id="ID110111] + cChave + StrZero( nSequencia, 2 ) + [">]
   ::cXmlDocumento +=       XmlTag( "cOrgao", Substr( cChave, 1, 2 ) )
   ::cXmlDocumento +=       XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlDocumento +=       XmlTag( "CNPJ", DfeEmitente( cChave ) )
   ::cXmlDocumento +=       XmlTag( "chCTe", cChave )
   ::cXmlDocumento +=       XmlTag( "dhEvento", ::DateTimeXml() )
   ::cXmlDocumento +=       XmlTag( "tpEvento", "110111" )
   ::cXmlDocumento +=       XmlTag( "nSeqEvento", Ltrim( Str( nSequencia, 4 ) ) )
   ::cXmlDocumento +=       [<detEvento versaoEvento="] + ::cVersao + [">]
   ::cXmlDocumento +=            [<evCancCTe>]
   ::cXmlDocumento +=                XmlTag( "descEvento", "Cancelamento" )
   ::cXmlDocumento +=                XmlTag( "nProt", Ltrim( Str( nProt, 16 ) ) )
   ::cXmlDocumento +=                XmlTag( "xJust", xJust )
   ::cXmlDocumento +=            [</evCancCTe>]
   ::cXmlDocumento +=       [</detEvento>]
   ::cXmlDocumento +=    [</infEvento>]
   ::cXmlDocumento += [</eventoCTe>]
   IF ::AssinaXml() == "OK"
      ::cXmlEnvio := ::cXmlDocumento
      ::XmlSoapPost()
      ::cXmlProtocolo := ::cXmlRetorno
      ::CTeGeraEventoAutorizado( ::cXmlDocumento, ::cXmlProtocolo )
   ENDIF

   RETURN ::cXmlRetorno

METHOD CTeEventoCarta( cChave, nSequencia, aAlteracoes, cCertificado, cAmbiente ) CLASS SefazClass

   LOCAL oElement

   hb_Default( @::cVersao, "3.00" )
   hb_Default( @::cProjeto, WS_PROJETO_CTE )
   hb_Default( @nSequencia, 1 )

   ::CTeEventoSoapList()
   ::Setup( cChave, cCertificado, cAmbiente )

   ::cXmlDocumento := [<eventoCTe versao="] + ::cVersao + [" ] + WS_XMLNS_CTE + [>]
   ::cXmlDocumento +=    [<infEvento Id="ID110110] + cChave + StrZero( nSequencia, 2 ) + [">]
   ::cXmlDocumento +=       XmlTag( "cOrgao", Substr( cChave, 1, 2 ) )
   ::cXmlDocumento +=       XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlDocumento +=       XmlTag( "CNPJ", DfeEmitente( cChave ) )
   ::cXmlDocumento +=       XmlTag( "chCTe", cChave )
   ::cXmlDocumento +=       XmlTag( "dhEvento", ::DateTimeXml( , ,.F.) )
   ::cXmlDocumento +=       XmlTag( "tpEvento", "110110" )
   ::cXmlDocumento +=       XmlTag( "nSeqEvento", LTrim( Str( nSequencia, 4 ) ) )
   ::cXmlDocumento +=       [<detEvento versaoEvento="] + ::cVersao + [">]
   ::cXmlDocumento +=            [<evCCeCTe>]
   ::cXmlDocumento +=                XmlTag( "descEvento", "Carta de Correcao" )
   FOR EACH oElement IN aAlteracoes
      ::cXmlDocumento +=                     [<infCorrecao>]
      ::cXmlDocumento +=                      XmlTag( "grupoAlterado", oElement[ 1 ] )
      ::cXmlDocumento +=                      XmlTag( "campoAlterado", oElement[ 2 ] )
      ::cXmlDocumento +=                      XmlTag( "valorAlterado", oElement[ 3 ] )
      ::cXmlDocumento +=                     [</infCorrecao>]
   NEXT
   ::cXmlDocumento +=                [<xCondUso>]
   ::cXmlDocumento +=                   "A Carta de Correcao e disciplinada pelo Art. 58-B "
   ::cXmlDocumento +=                   "do CONVENIO/SINIEF 06/89: Fica permitida a utilizacao de carta "
   ::cXmlDocumento +=                   "de correcao, para regularizacao de erro ocorrido na emissao de "
   ::cXmlDocumento +=                   "documentos fiscais relativos a prestacao de servico de transporte, "
   ::cXmlDocumento +=                   "desde que o erro nao esteja relacionado com: I - as variaveis que "
   ::cXmlDocumento +=                   "determinam o valor do imposto tais como: base de calculo, aliquota, "
   ::cXmlDocumento +=                   "diferenca de preco, quantidade, valor da prestacao;II - a correcao "
   ::cXmlDocumento +=                   "de dados cadastrais que implique mudanca do emitente, tomador, "
   ::cXmlDocumento +=                   "remetente ou do destinatario;III - a data de emissao ou de saida."
   ::cXmlDocumento +=                [</xCondUso>]
   ::cXmlDocumento +=          [</evCCeCTe>]
   ::cXmlDocumento +=       [</detEvento>]
   ::cXmlDocumento +=    [</infEvento>]
   ::cXmlDocumento += [</eventoCTe>]
   IF ::AssinaXml() == "OK"
      ::cXmlEnvio := ::cXmlDocumento
      ::XmlSoapPost()
      ::cXmlProtocolo := ::cXmlRetorno
      ::CTeGeraEventoAutorizado( ::cXmlDocumento, ::cXmlProtocolo )
   ENDIF

   RETURN ::cXmlRetorno

METHOD CTeEventoDesacordo( cChave, nSequencia, cObs, cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_CTE )
   hb_Default( @::cVersao, "3.00" )
   hb_Default( @nSequencia, 1 )

   ::CTeEventoSoapList()
   ::Setup( cChave, cCertificado, cAmbiente )

   ::cXmlDocumento := [<eventoCTe versao="] + ::cVersao + [" ] + WS_XMLNS_CTE + [>]
   ::cXmlDocumento +=    [<infEvento Id="ID110110] + cChave + StrZero( nSequencia, 2 ) + [">]
   ::cXmlDocumento +=       XmlTag( "cOrgao", Substr( cChave, 1, 2 ) )
   ::cXmlDocumento +=       XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlDocumento +=       XmlTag( "CNPJ", DfeEmitente( cChave ) )
   ::cXmlDocumento +=       XmlTag( "chCTe", cChave )
   ::cXmlDocumento +=       XmlTag( "dhEvento", ::DateTimeXml( , ,.F.) )
   ::cXmlDocumento +=       XmlTag( "tpEvento", "610110" )
   ::cXmlDocumento +=       XmlTag( "nSeqEvento", LTrim( Str( nSequencia, 4 ) ) )
   ::cXmlDocumento +=       [<detEvento versaoEvento="] + ::cVersao + [">]
   ::cXmlDocumento +=          [<evPrestDesacordo>]
   ::cXmlDocumento +=             XmlTag( "descEvento", "Prestacao do Servico em Desacordo" )
   ::cXmlDocumento +=             XmlTag( "indDesacordoOper", "" )
   ::cXmlDocumento +=             XmlTag( "xOBS", cObs )
   ::cXmlDocumento +=          [</evPrestDesacordo>]
   ::cXmlDocumento +=       [</detEvento>]
   ::cXmlDocumento +=    [</infEvento>]
   ::cXmlDocumento += [</eventoCTe>]
   IF ::AssinaXml() == "OK"
      ::cXmlEnvio := ::cXmlDocumento
      ::XmlSoapPost()
      ::cXmlProtocolo := ::cXmlRetorno
      ::CTeGeraEventoAutorizado( ::cXmlDocumento, ::cXmlProtocolo )
   ENDIF

   RETURN ::cXmlRetorno

METHOD CTeGeraAutorizado( cXmlAssinado, cXmlProtocolo ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_CTE )
   hb_Default( @::cVersao, "3.00" )
   cXmlAssinado  := iif( cXmlAssinado == NIL, ::cXmlDocumento, cXmlAssinado )
   cXmlProtocolo := iif( cXmlProtocolo == NIL, ::cXmlProtocolo, cXmlProtocolo )

   ::cStatus := Pad( XmlNode( XmlNode( cXmlProtocolo, "protCTe" ), "cStat" ), 3 )
   IF ! ::cStatus $ "100,101,150,301,302"
      ::cXmlRetorno := [<erro text="*ERRO* CTEGeraAutorizado() N�o autorizado" />] + cXmlProtocolo
      RETURN NIL
   ENDIF
   ::cXmlAutorizado := XML_UTF8
   ::cXmlAutorizado += [<cteProc versao="] + ::cVersao + [" ] + WS_XMLNS_CTE + [>]
   ::cXmlAutorizado +=    cXmlAssinado
   ::cXmlAutorizado +=    XmlNode( cXmlProtocolo, "protCTe", .T. ) // ?hb_Utf8ToStr()
   ::cXmlAutorizado += [</cteProc>]

   RETURN NIL

METHOD CTeGeraEventoAutorizado( cXmlAssinado, cXmlProtocolo ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_CTE )
   hb_Default( @::cVersao, "3.00" )
   cXmlAssinado  := iif( cXmlAssinado == NIL, ::cXmlDocumento, cXmlAssinado )
   cXmlProtocolo := iif( cXmlProtocolo == NIL, ::cXmlProtocolo, cXmlProtocolo )

   ::cStatus := Pad( XmlNode( XmlNode( cXmlProtocolo, "retEventoCTe" ), "cStat" ), 3 )
   ::cMotivo := XmlNode( XmlNode( cXmlProtocolo, "retEventoCTe" ), "xMotivo" ) // runner
   IF ! ::cStatus $ "135,155"
      ::cXmlRetorno := [<erro text="*ERRO* CteGeraEventoAutorizado() N�o autorizado" />] + cXmlProtocolo
      RETURN NIL
   ENDIF
   ::cXmlAutorizado := XML_UTF8
   ::cXmlAutorizado += [<procEventoCTe versao="] + ::cVersao + [" ] + WS_XMLNS_CTE + [>]
   ::cXmlAutorizado +=    cXmlAssinado
   ::cXmlAutorizado += [<retEventoCTe versao="] + ::cVersao + [">]
   ::cXmlAutorizado +=    XmlNode( cXmlProtocolo, "retEventoCTe" ) // hb_UTF8ToStr()
   ::cXmlAutorizado += [</retEventoCTe>]
   ::cXmlAutorizado += [</procEventoCTe>]
   ::cMotivo := XmlNode( XmlNode( cXmlProtocolo, "infEvento" ), "xMotivo" ) // hb_UTF8ToStr()

   RETURN NIL

METHOD CTeInutiliza( cAno, cCnpj, cMod, cSerie, cNumIni, cNumFim, cJustificativa, cUF, cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_CTE )
   hb_Default( @::cVersao, "3.00" )
   ::aSoapUrlList := { ;
      { "MG",   "3.00P", "https://cte.fazenda.mg.gov.br/cte/services/CteInutilizacao" }, ;
      { "MS",   "3.00P", "https://producao.cte.ms.gov.br/ws/CteInutilizacao" }, ;
      { "MT",   "3.00P", "https://cte.sefaz.mt.gov.br/ctews/services/CteInutilizacao" }, ;
      { "PR",   "3.00P", "https://cte.fazenda.pr.gov.br/cte/CteInutilizacao?wsdl" }, ;
      { "SP",   "3.00P", "https://nfe.fazenda.sp.gov.br/cteWEB/services/cteInutilizacao.asmx" }, ;
      { "SVRS", "3.00P", "https://cte.svrs.rs.gov.br/ws/cteinutilizacao/cteinutilizacao.asmx" }, ;
      ;
      { "SP",   "3.00H", "https://homologacao.nfe.fazenda.sp.gov.br/cteWEB/services/cteInutilizacao.asmx" }, ;
      { "SVRS", "3.00H", "https://cte-homologacao.svrs.rs.gov.br/ws/cteinutilizacao/cteinutilizacao.asmx" } }
   ::Setup( cUF, cCertificado, cAmbiente )
   ::cSoapAction  := "cteInutilizacaoCT"
   ::cSoapService := "http://www.portalfiscal.inf.br/cte/wsdl/CteInutilizacao"

   IF Len( cAno ) != 2
      cAno := Right( cAno, 2 )
   ENDIF
   ::cXmlDocumento := [<inutCTe versao="] + ::cVersao + [" ] + WS_XMLNS_CTE + [>]
   ::cXmlDocumento +=    [<infInut Id="ID] + ::UFCodigo( ::cUF ) + cCnpj + cMod + StrZero( Val( cSerie ), 3 )
   ::cXmlDocumento +=    StrZero( Val( cNumIni ), 9 ) + StrZero( Val( cNumFim ), 9 ) + [">]
   ::cXmlDocumento +=       XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlDocumento +=       XmlTag( "xServ", "INUTILIZAR" )
   ::cXmlDocumento +=       XmlTag( "cUF", ::UFCodigo( ::cUF ) )
   ::cXmlDocumento +=       XmlTag( "ano", cAno )
   ::cXmlDocumento +=       XmlTag( "CNPJ", SoNumeros( cCnpj ) )
   ::cXmlDocumento +=       XmlTag( "mod", cMod )
   ::cXmlDocumento +=       XmlTag( "serie", cSerie )
   ::cXmlDocumento +=       XmlTag( "nCTIni", Alltrim(Str(Val(cNumIni))) )
   ::cXmlDocumento +=       XmlTag( "nCTFin", Alltrim(Str(Val(cNumFim))) )
   ::cXmlDocumento +=       XmlTag( "xJust", cJustificativa )
   ::cXmlDocumento +=    [</infInut>]
   ::cXmlDocumento += [</inutCTe>]
   IF ::AssinaXml() == "OK"
      ::cXmlEnvio := ::cXmlDocumento
      ::XmlSoapPost()
      ::cStatus := Pad( XmlNode( ::cXmlRetorno, "cStat" ), 3 )
      ::cMotivo := XmlNode( ::cXmlRetorno, "xMotivo" )
      IF ::cStatus == "102"
         ::cXmlAutorizado := XML_UTF8
         ::cXmlAutorizado += [<ProcInutCTe versao="] + ::cVersao + [" ] + WS_XMLNS_CTE + [>]
         ::cXmlAutorizado += ::cXmlDocumento
         ::cXmlAutorizado += XmlNode( ::cXmlRetorno , "retInutCTe", .T. )
         ::cXmlAutorizado += [</ProcInutCTe>]
      ENDIF
   ENDIF

   RETURN ::cXmlRetorno

METHOD CTeLoteEnvia( cXml, cLote, cUF, cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_CTE )
   hb_Default( @::cVersao, "3.00" )
   IF Empty( cLote )
      cLote := "1"
   ENDIF
   ::aSoapUrlList := { ;
      { "MG",   "3.00P", "https://cte.fazenda.mg.gov.br/cte/services/CteRecepcao" }, ;
      { "MS",   "3.00P", "https://producao.cte.ms.gov.br/ws/CteRecepcao" }, ;
      { "MT",   "3.00P", "https://cte.sefaz.mt.gov.br/ctews/services/CteRecepcao" }, ;
      { "PR",   "3.00P", "https://cte.fazenda.pr.gov.br/cte/CteRecepcao?wsdl" }, ;
      { "SP",   "3.00P", "https://nfe.fazenda.sp.gov.br/cteWEB/services/cteRecepcao.asmx" }, ;
      { "SVSP", "3.00P", "https://nfe.fazenda.sp.gov.br/cteWEB/services/cteRecepcao.asmx" }, ;
      { "SVRS", "3.00P", "https://cte.svrs.rs.gov.br/ws/cterecepcao/CteRecepcao.asmx" }, ;
      ;
      { "SP",   "3.00H", "https://homologacao.nfe.fazenda.sp.gov.br/cteWEB/services/cteRecepcao.asmx" }, ;
      { "SVRS", "3.00H", "https://cte-homologacao.svrs.rs.gov.br/ws/cterecepcao/CteRecepcao.asmx" } }
   ::Setup( cUF, cCertificado, cAmbiente )
   ::cSoapAction  := "cteRecepcaoLote"
   ::cSoapService := "http://www.portalfiscal.inf.br/cte/wsdl/CteRecepcao"

   IF cXml != NIL
      ::cXmlDocumento := cXml
   ENDIF
   IF ::AssinaXml() != "OK"
      RETURN ::cXmlRetorno
   ENDIF
   ::cXmlEnvio    := [<enviCTe versao="] + ::cVersao + [" ] + WS_XMLNS_CTE + [>]
   ::cXmlEnvio    +=    XmlTag( "idLote", cLote )
   ::cXmlEnvio    +=    ::cXmlDocumento
   ::cXmlEnvio    += [</enviCTe>]
   ::XmlSoapPost()
   ::cXmlRecibo := ::cXmlRetorno
   ::cRecibo    := XmlNode( ::cXmlRecibo, "nRec" )
   ::cStatus    := Pad( XmlNode( ::cXmlRecibo, "cStatus" ), 3 )
   ::cMotivo    := XmlNode( ::cXmlRecibo, "xMotivo" )
   IF ! Empty( ::cRecibo )
      Inkey( ::nTempoEspera )
      ::CteConsultaRecibo()
      ::CteGeraAutorizado( ::cXmlDocumento, ::cXmlProtocolo ) // runner
   ENDIF

   RETURN ::cXmlRetorno

METHOD CTeStatusServico( cUF, cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cVersao, "3.00" )
   hb_Default( @::cProjeto, WS_PROJETO_CTE )
   ::aSoapUrlList := { ;
      { "MG",   "3.00P", "https://cte.fazenda.mg.gov.br/cte/services/CteStatusServico" }, ;
      { "MT",   "3.00P", "https://cte.sefaz.mt.gov.br/ctews/services/CteStatusServico" }, ;
      { "MS",   "3.00P", "https://producao.cte.ms.gov.br/ws/CteStatusServico" }, ;
      { "PR",   "3.00P", "https://cte.fazenda.pr.gov.br/cte/CteStatusServico?wsdl" }, ;
      { "SP",   "3.00P", "https://nfe.fazenda.sp.gov.br/cteWEB/services/cteStatusServico.asmx" }, ;
      { "SVSP", "3.00P", "https://nfe.fazenda.sp.gov.br/cteWEB/services/CteStatusServico.asmx" }, ;
      { "SVRS", "3.00P", "https://cte.svrs.rs.gov.br/ws/ctestatusservico/CteStatusServico.asmx" }, ;
      ;
      { "SP",   "3.00H", "https://homologacao.nfe.fazenda.sp.gov.br/cteWEB/services/cteStatusServico.asmx" }, ;
      { "SVRS", "3.00H", "https://cte-homologacao.svrs.rs.gov.br/ws/ctestatusservico/CteStatusServico.asmx" } }
   ::Setup( cUF, cCertificado, cAmbiente )
   ::cSoapAction  := "cteStatusServicoCT"
   ::cSoapService := "http://www.portalfiscal.inf.br/cte/wsdl/CteStatusServico"

   ::cXmlEnvio    := [<consStatServCte versao="] + ::cVersao + [" ] + WS_XMLNS_CTE + [>]
   ::cXmlEnvio    +=    XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlEnvio    +=    XmlTag( "xServ", "STATUS" )
   ::cXmlEnvio    += [</consStatServCte>]
   ::XmlSoapPost()

   RETURN ::cXmlRetorno

METHOD MDFeConsNaoEnc( cUF, cCNPJ , cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cVersao, "3.00" )
   hb_Default( @::cProjeto, WS_PROJETO_MDFE )
   ::cSoapAction  := "mdfeConsNaoEnc"
   ::cSoapService := "http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeConsNaoEnc"
   ::aSoapUrlList := { ;
         { "**", "3.00P", "https://mdfe.svrs.rs.gov.br/ws/mdfeConsNaoEnc/mdfeConsNaoenc.asmx" }, ;
         { "**", "3.00H", "https://mdfe-homologacao.svrs.rs.gov.br/ws/MDFeConsNaoEnc/MDFeConsNaoEnc.asmx" } }
   ::Setup( cUF, cCertificado, cAmbiente )

   ::cXmlEnvio := [<consMDFeNaoEnc versao="] + ::cVersao + [" ] + WS_XMLNS_MDFE + [>]
   ::cXmlEnvio +=    XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlEnvio +=    XmlTag( "xServ", "CONSULTAR N�O ENCERRADOS" )
   ::cXmlEnvio +=    XmlTag( "CNPJ", cCNPJ )
   ::cXmlEnvio += [</consMDFeNaoEnc>]
   ::XmlSoapPost()
   ::cStatus := Pad( XmlNode( XmlNode( ::cXmlRetorno , "retConsMDFeNaoEnc" ) , "cStat" ), 3 )
   ::cMotivo := XmlNode( XmlNode( ::cXmlRetorno , "retConsMDFeNaoEnc" ) , "xMotivo" )

   RETURN ::cXmlRetorno

METHOD MDFeConsultaProtocolo( cChave, cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_MDFE )
   hb_Default( @::cVersao, "3.00" )
   ::aSoapUrlList := { ;
      { "**", "3.00P", "https://mdfe.svrs.rs.gov.br/ws/MDFeConsulta/MDFeConsulta.asmx" }, ;
      { "**", "3.00H", "https://mdfe-homologacao.svrs.rs.gov.br/ws/MDFeConsulta/MDFeConsulta.asmx" } }
   ::Setup( cChave, cCertificado, cAmbiente )
   ::cSoapAction  := "mdfeConsultaMDF"
   ::cSoapService := "http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeConsulta"

   ::cXmlEnvio := [<consSitMDFe versao="] + ::cVersao + [" ] + WS_XMLNS_MDFE + [>]
   ::cXmlEnvio +=    XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlEnvio +=    XmlTag( "xServ", "CONSULTAR" )
   ::cXmlEnvio +=    XmlTag( "chMDFe", cChave )
   ::cXmlEnvio += [</consSitMDFe>]
   IF DfeModFis( cChave ) != "58"
      ::cXmlRetorno := [<erro text="*ERRO* MDFEConsultaProtocolo() Chave n�o se refere a MDFE" />]
   ELSE
      ::XmlSoapPost()
      ::cXmlProtocolo := ::cXmlRetorno
   ENDIF
   ::cStatus := XmlNode( ::cXmlRetorno, "cStat" )
   ::cMotivo := XmlNode( ::cXmlRetorno, "xMotivo" )

   RETURN ::cXmlRetorno

METHOD MDFeConsultaRecibo( cRecibo, cUF, cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_MDFE )
   hb_Default( @::cVersao, "3.00" )
   IF cRecibo != NIL
      ::cRecibo := cRecibo
   ENDIF
   ::aSoapUrlList := { ;
      { "**", "3.00P", "https://mdfe.svrs.rs.gov.br/ws/MDFeRetRecepcao/MDFeRetRecepcao.asmx" }, ;
      { "**", "3.00H", "https://mdfe-homologacao.svrs.rs.gov.br/ws/MDFeRetRecepcao/MDFeRetRecepcao.asmx" } }
   ::Setup( cUF, cCertificado, cAmbiente )
   ::cSoapAction  := "mdfeRetRecepcao"
   ::cSoapService := "http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeRetRecepcao"

   ::cXmlEnvio := [<consReciMDFe versao="] + ::cVersao + [" ] + WS_XMLNS_MDFE + [>]
   ::cXmlEnvio +=    XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlEnvio +=    XmlTag( "nRec", ::cRecibo )
   ::cXmlEnvio += [</consReciMDFe>]
   ::XmlSoapPost()
   ::cXmlProtocolo := ::cXmlRetorno
   ::cMotivo       := XmlNode( XmlNode( ::cXmlRetorno, "infProt" ), "xMotivo" )

   RETURN ::cXmlRetorno

   // 2016.01.31.2200 Iniciado apenas
METHOD MDFeDistribuicaoDFe( cCnpj, cUltNSU, cNSU, cUF, cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_MDFE )
   hb_Default( @::cVersao, "3.00" )
   hb_Default( @cUltNSU, "0" )
   hb_Default( @cNSU, "" )

   ::aSoapUrlList := { ;
      { "**", "3.00P", "https://mdfe.svrs.rs.gov.br/WS/MDFeDistribuicaoDFe/MDFeDistribuicaoDFe.asmx" } }
   ::Setup( cUF, cCertificado, cAmbiente )
   ::cSoapAction  := "mdfeDistDFeInteresse" // verificar na comunica��o
   ::cSoapService := "http://www.portalfiscal.inf.br/nfe/wsdl/MDFeDistribuicaoDFe"

   ::cXmlEnvio    := [<distDFeInt versao="] + ::cVersao + [" ] + WS_XMLNS_MDFE + [>]
   ::cXmlEnvio    +=    XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlEnvio    +=    XmlTag( "cUFAutor", ::UFCodigo( ::cUF ) )
   ::cXmlEnvio    +=    XmlTag( "CNPJ", cCnpj )
   IF Empty( cNSU )
      ::cXmlEnvio +=   [<distNSU>]
      ::cXmlEnvio +=      XmlTag( "ultNSU", cUltNSU )
      ::cXmlEnvio +=   [</distNSU>]
   ELSE
      ::cXmlEnvio +=   [<consNSU>]
      ::cXmlEnvio +=      XmlTag( "NSU", cNSU )
      ::cXmlEnvio +=   [</consNSU>]
   ENDIF
   ::cXmlEnvio    += [</distDFeInt>]
   ::XmlSoapPost()
   // UltNSU = ultimo NSU pesquisado
   // maxUSU = n�mero m�ximo existente
   // docZIP = Documento em formato ZIP
   // NSU    = NSU do documento fiscal
   // schema = schemma de valida��o do XML anexado ex. procMDFe_v1.00.xsd, procEventoMDFe_V1.00.xsd

   RETURN NIL

METHOD MDFeEventoSoapList() CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_MDFE )
   hb_Default( @::cVersao, "3.00" )
   ::aSoapUrlList := { ;
      { "**", "3.00P", "https://mdfe.svrs.rs.gov.br/ws/MDFeRecepcaoEvento/MDFeRecepcaoEvento.asmx" }, ;
      { "**", "3.00H", "https://mdfe-homologacao.svrs.rs.gov.br/ws/MDFeRecepcaoEvento/MDFeRecepcaoEvento.asmx" } }
   ::cSoapAction  := "mdfeRecepcaoEvento"
   ::cSoapService := "http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeRecepcaoEvento"

   RETURN NIL

METHOD MDFeEventoCancela( cChave, nSequencia, nProt, xJust, cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_MDFE )
   hb_Default( @::cVersao, "3.00" )
   hb_Default( @nSequencia, 1 )

   ::MDFeEventoSoapList()
   ::Setup( cChave, cCertificado, cAmbiente )

   ::cXmlDocumento := [<eventoMDFe versao="] + ::cVersao + [" ] + WS_XMLNS_MDFE + [>]
   ::cXmlDocumento +=    [<infEvento Id="ID110111] + cChave + StrZero( nSequencia, 2 ) + [">]
   ::cXmlDocumento +=       XmlTag( "cOrgao", Substr( cChave, 1, 2 ) )
   ::cXmlDocumento +=       XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlDocumento +=       XmlTag( "CNPJ", DfeEmitente( cChave ) )
   ::cXmlDocumento +=       XmlTag( "chMDFe", cChave )
   ::cXmlDocumento +=       XmlTag( "dhEvento", ::DateTimeXml() )
   ::cXmlDocumento +=       XmlTag( "tpEvento", "110111" )
   ::cXmlDocumento +=       XmlTag( "nSeqEvento", Ltrim( Str( nSequencia, 4 ) ) )
   ::cXmlDocumento +=       [<detEvento versaoEvento="] + ::cVersao + [">]
   ::cXmlDocumento +=            [<evCancMDFe>]
   ::cXmlDocumento +=                XmlTag( "descEvento", "Cancelamento" )
   ::cXmlDocumento +=                XmlTag( "nProt", Ltrim( Str( nProt ) ) )
   ::cXmlDocumento +=                XmlTag( "xJust", xJust )
   ::cXmlDocumento +=            [</evCancMDFe>]
   ::cXmlDocumento +=       [</detEvento>]
   ::cXmlDocumento +=    [</infEvento>]
   ::cXmlDocumento += [</eventoMDFe>]
   IF ::AssinaXml() == "OK"
      ::cXmlEnvio := ::cXmlDocumento
      ::XmlSoapPost()
      ::cXmlProtocolo := ::cXmlRetorno
      ::MDFeGeraEventoAutorizado( ::cXmlDocumento, ::cXmlProtocolo )
   ENDIF

   RETURN ::cXmlRetorno

METHOD MDFeEventoEncerramento( cChave, nSequencia , nProt, cUFFim , cMunCarrega , cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_MDFE )
   hb_Default( @::cVersao, "3.00" )
   hb_Default( @nSequencia, 1 )

   ::MDFeEventoSoapList()
   ::Setup( cChave, cCertificado, cAmbiente )

   ::cXmlDocumento := [<eventoMDFe versao="] + ::cVersao + [" ] + WS_XMLNS_MDFE + [>]
   ::cXmlDocumento +=    [<infEvento Id="ID110112] + cChave + StrZero( nSequencia, 2 ) + [">]
   ::cXmlDocumento +=       XmlTag( "cOrgao", Substr( cChave, 1, 2 ) )
   ::cXmlDocumento +=       XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlDocumento +=       XmlTag( "CNPJ", DfeEmitente( cChave ) )
   ::cXmlDocumento +=       XmlTag( "chMDFe", cChave )
   ::cXmlDocumento +=       XmlTag( "dhEvento", ::DateTimeXml() )
   ::cXmlDocumento +=       XmlTag( "tpEvento", "110112" )
   ::cXmlDocumento +=       XmlTag( "nSeqEvento", Ltrim( Str( nSequencia, 4 ) ) )
   ::cXmlDocumento +=       [<detEvento versaoEvento="] + ::cVersao + [">]
   ::cXmlDocumento +=            [<evEncMDFe>]
   ::cXmlDocumento +=                XmlTag( "descEvento", "Encerramento" )
   ::cXmlDocumento +=                  XmlTag( "nProt", Ltrim( Str( nProt ) ) )
   ::cXmlDocumento +=                  XmlTag( "dtEnc", DateXml( Date() ) )
   ::cXmlDocumento +=                  XmlTag( "cUF", ::UFCodigo( cUFFim ) )
   ::cXmlDocumento +=                  XmlTag( "cMun", cMunCarrega )
   ::cXmlDocumento +=            [</evEncMDFe>]
   ::cXmlDocumento +=       [</detEvento>]
   ::cXmlDocumento +=    [</infEvento>]
   ::cXmlDocumento += [</eventoMDFe>]
   IF ::AssinaXml() == "OK"
      ::cXmlEnvio := ::cXmlDocumento
      ::XmlSoapPost()
      ::cXmlProtocolo := ::cXmlRetorno
      ::MDFeGeraEventoAutorizado( ::cXmlDocumento, ::cXmlProtocolo ) // hb_Utf8ToStr(
   ENDIF

   RETURN ::cXmlRetorno

METHOD MDFeEventoInclusaoCondutor( cChave, nSequencia, cNome, cCpf, cCertificado, cAmbiente )

   hb_Default( @::cProjeto, WS_PROJETO_MDFE )
   hb_Default( @::cVersao, "3.00" )
   hb_Default( @nSequencia, 1 )

   ::MDFeEventoSoapList()
   ::Setup( cChave, cCertificado, cAmbiente )

   ::cXmlDocumento := [<eventoMDFe versao="] + ::cVersao + [" ] + WS_XMLNS_MDFE + [>]
   ::cXmlDocumento +=    [<infEvento Id="ID110112] + cChave + StrZero( nSequencia, 2 ) + [">]
   ::cXmlDocumento +=       XmlTag( "cOrgao", Substr( cChave, 1, 2 ) )
   ::cXmlDocumento +=       XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlDocumento +=       XmlTag( "CNPJ", DfeEmitente( cChave ) )
   ::cXmlDocumento +=       XmlTag( "chMDFe", cChave )
   ::cXmlDocumento +=       XmlTag( "dhEvento", ::DateTimeXml() )
   ::cXmlDocumento +=       XmlTag( "tpEvento", "110114" )
   ::cXmlDocumento +=       XmlTag( "nSeqEvento", Ltrim( Str( nSequencia, 4 ) ) )
   ::cXmlDocumento +=       [<detEvento versaoEvento="] + ::cVersao + [">]
   ::cXmlDocumento +=            [<evIncCondutorMDFe>]
   ::cXmlDocumento +=                XmlTag( "descEvento", "Inclusao Condutor" )
   ::cXmlDocumento +=               [<Condutor>]
   ::cXmlDocumento +=                  XmlTag( "xNome", cNome )
   ::cXmlDocumento +=                  XmlTag( "CPF", cCPF)
   ::cXmlDocumento +=               [</Condutor>]
   ::cXmlDocumento +=            [</evIncCondutorMDFe>]
   ::cXmlDocumento +=       [</detEvento>]
   ::cXmlDocumento +=    [</infEvento>]
   ::cXmlDocumento += [</eventoMDFe>]
   IF ::AssinaXml() == "OK"
      ::cXmlEnvio := ::cXmlDocumento
      ::XmlSoapPost()
      ::cXmlProtocolo := ::cXmlRetorno
      ::MDFeGeraEventoAutorizado( ::cXmlDocumento, ::cXmlProtocolo ) // hb_Utf8ToStr(
   ENDIF

   RETURN ::cXmlRetorno

METHOD MDFeGeraAutorizado( cXmlAssinado, cXmlProtocolo ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_MDFE )
   hb_Default( @::cVersao, "3.00" )
   cXmlAssinado  := iif( cXmlAssinado == NIL, ::cXmlDocumento, cXmlAssinado )
   cXmlProtocolo := iif( cXmlProtocolo == NIL, ::cXmlProtocolo, cXmlProtocolo )

   ::cStatus := Pad( XmlNode( XmlNode( cXmlProtocolo, "protMDFe" ), "cStat" ), 3 )
   IF ! ::cStatus $ "100,101,150,301,302"
      ::cXmlRetorno := [<erro text="*ERRO* MDFEGeraAutorizado() N�o autorizado" />] + ::cXmlProtocolo
      RETURN ::cXmlRetorno
   ENDIF
   ::cXmlAutorizado := XML_UTF8
   ::cXmlAutorizado += [<mdfeProc versao="] + ::cVersao + [" ] + WS_XMLNS_MDFE + [>]
   ::cXmlAUtorizado +=    cXmlAssinado
   ::cXmlAutorizado +=    XmlNode( cXmlProtocolo, "protMDFe", .T. )
   ::cXmlAutorizado += [</mdfeProc>]

   RETURN NIL

METHOD MDFeGeraEventoAutorizado( cXmlAssinado, cXmlProtocolo ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_MDFE )
   hb_Default( @::cVersao, "3.00" )
   cXmlAssinado  := iif( cXmlAssinado == NIL, ::cXmlDocumento, cXmlAssinado )
   cXmlProtocolo := iif( cXmlProtocolo == NIL, ::cXmlProtocolo, cXmlProtocolo )

   ::cStatus := Pad( XmlNode( XmlNode( cXmlProtocolo, "retEventoMDFe" ), "cStat" ), 3 )
   ::cMotivo := XmlNode( XmlNode( cXmlProtocolo, "retEventoMDFe" ), "xMotivo" ) // hb_utf8tostr()
   IF ! ::cStatus $ "135,136"
      ::cXmlRetorno := [<erro Text="*ERRO* MDFeGeraEventoAutorizado() Status inv�lido" />] + ::cXmlRetorno
      RETURN NIL
   ENDIF
   ::cXmlAutorizado := XML_UTF8
   ::cXmlAutorizado += [<procEventoMDFe versao="] + ::cVersao + [" ] + WS_XMLNS_MDFE + [>]
   ::cXmlAutorizado +=    cXmlAssinado
   ::cXmlAutorizado += [<retEventoMDFe versao="] + ::cVersao + [">]
   ::cXmlAutorizado +=    XmlNode( cXmlProtocolo, "retEventoMDFe" ) // hb_Utf8ToStr(
   ::cXmlAutorizado += [</retEventoMDFe>]
   ::cXmlAutorizado += [</procEventoMDFe>]
   ::cMotivo := XmlNode( XmlNode( cXmlProtocolo, "infEvento" ), "xMotivo" ) // hb_Utf8ToStr

   RETURN NIL

METHOD MDFeLoteEnvia( cXml, cLote, cUF, cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_MDFE )
   hb_Default( @::cVersao, "3.00" )
   ::aSoapUrlList := { ;
      { "**", "3.00P", "https://mdfe.svrs.rs.gov.br/ws/MDFerecepcao/MDFeRecepcao.asmx" }, ;
      { "**", "3.00H", "https://mdfe-homologacao.svrs.rs.gov.br/ws/MDFerecepcao/MDFeRecepcao.asmx" } }
   ::Setup( cUF, cCertificado, cAmbiente )
   ::cSoapAction  := "MDFeRecepcao"
   ::cSoapService := "http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeRecepcao"

   IF cXml != NIL
      ::cXmlDocumento := cXml
   ENDIF
   IF ::AssinaXml() != "OK"
      RETURN ::cXmlRetorno
   ENDIF
   ::cXmlEnvio  := [<enviMDFe versao="] + ::cVersao + [" ] + WS_XMLNS_MDFE + [>]
   ::cXmlEnvio  +=    XmlTag( "idLote", cLote )
   ::cXmlEnvio  +=    ::cXmlDocumento
   ::cXmlEnvio  += [</enviMDFe>]
   ::XmlSoapPost()
   ::cXmlRecibo := ::cXmlRetorno
   ::cRecibo    := XmlNode( ::cXmlRecibo, "nRec" )
   ::cStatus    := Pad( XmlNode( ::cXmlRecibo, "cStatus" ), 3 )
   ::cMotivo    := XmlNode( ::cXmlRecibo, "xMotivo" )
   IF ! Empty( ::cRecibo )
      Inkey( ::nTempoEspera )
      ::MDFeConsultaRecibo()
      ::MDFeGeraAutorizado( ::cXmlDocumento, ::cXmlProtocolo )
   ENDIF

   RETURN ::cXmlRetorno

METHOD MDFeStatusServico( cUF, cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_MDFE )
   hb_Default( @::cVersao, "3.00" )
   ::aSoapUrlList := { ;
      { "**", "3.00P", "https://mdfe.svrs.rs.gov.br/ws/MDFeStatusServico/MDFeStatusServico.asmx" }, ;
      ;
      { "**", "3.00H", "https://mdfe-homologacao.svrs.rs.gov.br/ws/MDFeStatusServico/MDFeStatusServico.asmx" } }
   ::Setup( cUF, cCertificado, cAmbiente )
   ::cSoapAction  := "MDFeStatusServico"
   ::cSoapService := "http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeStatusServico/mdfeStatusServicoMDF"

   ::cXmlEnvio := [<consStatServMDFe versao="] + ::cVersao + [" ] + WS_XMLNS_MDFE + [>]
   ::cXmlEnvio +=    XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlEnvio +=    XmlTag( "cUF", ::UFCodigo( ::cUF ) )
   ::cXmlEnvio +=    XmlTag( "xServ", "STATUS" )
   ::cXmlEnvio += [</consStatServMDFe>]
   ::XmlSoapPost()

   RETURN ::cXmlRetorno

METHOD NFeConsultaCadastro( cCnpj, cUF, cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_NFE )
   hb_Default( @::cVersao, "3.10" )
   ::cSoapUrlList := { ;
      { "BA",    "3.10P", "https://nfe.sefaz.ba.gov.br/webservices/nfenw/CadConsultaCadastro2.asmx" }, ;
      { "CE",    "3.10P", "https://nfe.sefaz.ce.gov.br/nfe2/services/CadConsultaCadastro2?wsdl" }, ;
      { "ES",    "3.10P", "https://app.sefaz.es.gov.br/ConsultaCadastroService/CadConsultaCadastro2.asmx" }, ;
      { "GO",    "3.10P", "https://nfe.sefaz.go.gov.br/nfe/services/v2/CadConsultaCadastro2?wsdl" }, ;
      { "MA",    "3.10P", "https://sistemas.sefaz.ma.gov.br/wscadastro/CadConsultaCadastro2?wsdl" }, ;
      { "MG",    "3.10P", "https://nfe.fazenda.mg.gov.br/nfe2/services/cadconsultacadastro2" }, ;
      { "MS",    "3.10P", "https://nfe.fazenda.ms.gov.br/producao/services2/CadConsultaCadastro2" }, ;
      { "MT",    "3.10P", "https://nfe.sefaz.mt.gov.br/nfews/v2/services/CadConsultaCadastro2?wsdl" }, ;
      { "PE",    "3.10P", "https://nfe.sefaz.pe.gov.br/nfe-service/services/CadConsultaCadastro2" }, ;
      { "PR",    "3.10P", "https://nfe.fazenda.pr.gov.br/nfe/CadConsultaCadastro2?wsdl" }, ;
      { "RS",    "3.10P", "https://cad.sefazrs.rs.gov.br/ws/cadconsultacadastro/cadconsultacadastro2.asmx" }, ;
      { "SP",    "3.10P", "https://nfe.fazenda.sp.gov.br/ws/cadconsultacadastro2.asmx" }, ;
      { "SVRS",  "3.10P", "https://cad.svrs.rs.gov.br/ws/cadconsultacadastro/cadconsultacadastro2.asmx" }, ;
      { "AC",    "3.10P", "https://cad.svrs.rs.gov.br/ws/cadconsultacadastro/cadconsultacadastro2.asmx" }, ;
      { "RN",    "3.10P", "https://cad.svrs.rs.gov.br/ws/cadconsultacadastro/cadconsultacadastro2.asmx" }, ;
      { "PB",    "3.10P", "https://cad.svrs.rs.gov.br/ws/cadconsultacadastro/cadconsultacadastro2.asmx" }, ;
      { "SC",    "3.10P", "https://cad.svrs.rs.gov.br/ws/cadconsultacadastro/cadconsultacadastro2.asmx" }, ;
      ;
      { "AM",    "3.10H", "https://homnfe.sefaz.am.gov.br/services2/services/CadConsultaCadastro2" }, ;
      { "BA",    "3.10H", "https://hnfe.sefaz.ba.gov.br/webservices/nfenw/CadConsultaCadastro2.asmx" }, ;
      { "CE",    "3.10H", "https://nfeh.sefaz.ce.gov.br/nfe2/services/CadConsultaCadastro2?wsdl" }, ;
      { "ES",    "3.10H", "https://app.sefaz.es.gov.br/ConsultaCadastroService/CadConsultaCadastro2.asmx" }, ;
      { "GO",    "3.10H", "https://homolog.sefaz.go.gov.br/nfe/services/v2/CadConsultaCadastro2?wsdl" }, ;
      { "MA",    "3.10H", "https://sistemas.sefaz.ma.gov.br/wscadastro/CadConsultaCadastro2?wsdl" }, ;
      { "MG",    "3.10H", "https://hnfe.fazenda.mg.gov.br/nfe2/services/cadconsultacadastro2" }, ;
      { "MS",    "3.10H", "https://homologacao.nfe.ms.gov.br/homologacao/services2/CadConsultaCadastro2" }, ;
      { "MT",    "3.10H", "https://homologacao.sefaz.mt.gov.br/nfews/v2/services/CadConsultaCadastro2?wsdl" }, ;
      { "PE",    "3.10H", "https://nfe.sefaz.pe.gov.br/nfe-service/services/NfeConsulta2" }, ;
      { "PR",    "3.10H", "https://homologacao.nfe.fazenda.pr.gov.br/nfe/CadConsultaCadastro2?wsdl" }, ;
      { "RS",    "3.10H", "https://cad.sefazrs.rs.gov.br/ws/cadconsultacadastro/cadconsultacadastro2.asmx" }, ;
      { "SP",    "3.10H", "https://homologacao.nfe.fazenda.sp.gov.br/ws/cadconsultacadastro2.asmx" }, ;
      { "SVRS",  "3.10H", "https://cad.svrs.rs.gov.br/ws/cadconsultacadastro/cadconsultacadastro2.asmx" }, ;
      { "AC",    "3.10H", "https://cad.svrs.rs.gov.br/ws/cadconsultacadastro/cadconsultacadastro2.asmx" }, ;
      { "RN",    "3.10H", "https://cad.svrs.rs.gov.br/ws/cadconsultacadastro/cadconsultacadastro2.asmx" }, ;
      { "PB",    "3.10H", "https://cad.svrs.rs.gov.br/ws/cadconsultacadastro/cadconsultacadastro2.asmx" }, ;
      { "SC",    "3.10H", "https://cad.svrs.rs.gov.br/ws/cadconsultacadastro/cadconsultacadastro2.asmx" }, ;
      ;
      { "SP",    "4.00P", "https://nfe.fazenda.sp.gov.br/ws/cadconsultacadastro4.asmx" }, ;
      ;
      { "SP",    "4.00H", "https://homologacao.nfe.fazenda.sp.gov.br/ws/cadconsultacadastro4.asmx" } }
   ::Setup( cUF, cCertificado, cAmbiente )
   IF ::cVersao == "3.10"
      ::cSoapAction  := "CadConsultaCadastro2"
      ::cSoapService := "http://www.portalfiscal.inf.br/nfe/wsdl/CadConsultaCadastro2"
   ELSE
      ::cSoapAction := "CadConsultaCadastro4"
      ::cSoapService := "http://www.portalfiscal.inf.br/nfe/wsdl/CadConsultaCadastro"
   ENDIF

   ::cXmlEnvio    := [<ConsCad versao="2.00" ] + WS_XMLNS_NFE + [>]
   ::cXmlEnvio    +=    [<infCons>]
   ::cXmlEnvio    +=       XmlTag( "xServ", "CONS-CAD" )
   ::cXmlEnvio    +=       XmlTag( "UF", ::cUF )
   ::cXmlEnvio    +=       XmlTag( "CNPJ", cCNPJ )
   ::cXmlEnvio    +=    [</infCons>]
   ::cXmlEnvio    += [</ConsCad>]
   ::XmlSoapPost()

   RETURN ::cXmlRetorno

   /* Iniciado apenas 2015.07.31.1400 */

METHOD NFeConsultaDest( cCnpj, cUltNsu, cIndNFe, cIndEmi, cUf, cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_NFE )
   hb_Default( @::cVersao, "3.10" )
   hb_Default( @cUltNSU, "0" )
   hb_Default( @cIndNFe, "0" )
   hb_Default( @cIndEmi, "0" )

   ::aSoapUrlList := { ;
      { "RS",    "3.10P", "https://nfe.sefazrs.rs.gov.br/ws/nfeConsultaDest/nfeConsultaDest.asmx" }, ;
      { "AN",    "3.10P", "https://www.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx" }, ;
      ;
      { "RS",    "3.10H", "https://nfe-homologacao.sefazrs.rs.gov.br/ws/nfeConsultaDest/nfeConsultaDest.asmx" } }
   ::Setup( cUF, cCertificado, cAmbiente )
   ::cSoapAction := "nfeConsultaNFDest"
   ::cSoapService := "http://www.portalfiscal.inf.br/nfe/wsdl/NfeConsultaDest/nfeConsultaNFDest"

   ::cXmlEnvio    := [<consNFeDest versao="] + ::cVersao + [">]
   ::cXmlEnvio    +=    XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlEnvio    +=    XmlTag( "xServ", "CONSULTAR NFE DEST" )
   ::cXmlEnvio    +=    XmlTag( "CNPJ", SoNumeros( cCnpj ) )
   ::cXmlEnvio    +=    XmlTag( "indNFe", "0" ) // 0=todas,1=sem manif,2=sem nada
   ::cXmlEnvio    +=    XmlTag( "indEmi", "0" ) // 0=todas, 1=sem cnpj raiz(sem matriz/filial)
   ::cXmlEnvio    +=    XmlTag( "ultNSU", cUltNsu )
   ::cXmlEnvio    += [</consNFeDest>]

   ::XmlSoapPost()

   RETURN ::cXmlRetorno

METHOD NFeConsultaProtocolo( cChave, cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_NFE )
   hb_Default( @::cVersao, "3.10" )
   ::cNFCe := iif( DfeModFis( cChave ) == "65", "S", "N" )
   ::aSoapUrlList := { ;
      { "AM",    "3.10P", "https://nfe.sefaz.am.gov.br/services2/services/NfeConsulta2" }, ;
      { "BA",    "3.10P", "https://nfe.sefaz.ba.gov.br/webservices/NfeConsulta/NfeConsulta.asmx" }, ;
      { "CE",    "3.10P", "https://nfe.sefaz.ce.gov.br/nfe2/services/NfeConsulta2?wsdl" }, ;
      { "GO",    "3.10P", "https://nfe.sefaz.go.gov.br/nfe/services/v2/NfeConsulta2?wsdl" }, ;
      { "MG",    "3.10P", "https://nfe.fazenda.mg.gov.br/nfe2/services/NfeConsulta2" }, ;
      { "MS",    "3.10P", "https://nfe.fazenda.ms.gov.br/producao/services2/NfeConsulta2" }, ;
      { "MT",    "3.10P", "https://nfe.sefaz.mt.gov.br/nfews/v2/services/NfeConsulta2?wsdl" }, ;
      { "PE",    "3.10P", "https://nfe.sefaz.pe.gov.br/nfe-service/services/NfeConsulta2" }, ;
      { "PR",    "3.10P", "https://nfe.fazenda.pr.gov.br/nfe/NFeConsulta3?wsdl" }, ;
      { "RS",    "3.10P", "https://nfe.sefazrs.rs.gov.br/ws/NfeConsulta/NfeConsulta2.asmx" }, ;
      { "SP",    "3.10P", "https://nfe.fazenda.sp.gov.br/ws/nfeconsulta2.asmx" }, ;
      { "SVRS",  "3.10P", "https://nfe.svrs.rs.gov.br/ws/NfeConsulta/NfeConsulta2.asmx" }, ;
      { "SCAN",  "3.10P", "https://www.scan.fazenda.gov.br/NfeConsulta2/NfeConsulta2.asmx" }, ;
      { "SVAN",  "3.10P", "https://www.sefazvirtual.fazenda.gov.br/NfeConsulta2/NfeConsulta2.asmx" }, ;
      { "SCVAN", "3.10P", "https://www.svc.fazenda.gov.br/NfeConsulta2/NfeConsulta2.asmx" }, ;
      ;
      { "AM",    "3.10H", "https://homnfe.sefaz.am.gov.br/services2/services/NfeConsulta2" }, ;
      { "BA",    "3.10H", "https://hnfe.sefaz.ba.gov.br/webservices/nfenw/NfeConsulta2.asmx" }, ;
      { "CE",    "3.10H", "https://nfeh.sefaz.ce.gov.br/nfe2/services/NfeConsulta2?wsdl" }, ;
      { "GO",    "3.10H", "https://homolog.sefaz.go.gov.br/nfe/services/v2/NfeConsulta2?wsdl" }, ;
      { "MG",    "3.10H", "https://hnfe.fazenda.mg.gov.br/nfe2/services/NfeConsulta2" }, ;
      { "MT",    "3.10H", "https://homologacao.sefaz.mt.gov.br/nfews/v2/services/NfeConsulta2?wsdl" }, ;
      { "MS",    "3.10H", "https://homologacao.nfe.ms.gov.br/homologacao/services2/NfeConsulta2" }, ;
      { "PE",    "3.10H", "https://nfehomolog.sefaz.pe.gov.br/nfe-service/services/NfeConsulta2" }, ;
      { "PR",    "3.10H", "https://homologacao.nfe.fazenda.pr.gov.br/nfe/NFeConsulta3?wsdl" }, ;
      { "RS",    "3.10H", "https://nfe-homologacao.sefazrs.rs.gov.br/ws/NfeConsulta/NfeConsulta2.asmx" }, ;
      { "SP",    "3.10H", "https://homologacao.nfe.fazenda.sp.gov.br/ws/nfeconsulta2.asmx" }, ;
      { "SVRS",  "3.10H", "https://nfe-homologacao.svrs.rs.gov.br/ws/NfeConsulta/NfeConsulta2.asmx" }, ;
      { "SCAN",  "3.10H", "https://hom.nfe.fazenda.gov.br/SCAN/NfeConsulta2/NfeConsulta2.asmx" }, ;
      { "SVAN",  "3.10H", "https://hom.sefazvirtual.fazenda.gov.br/NfeConsulta2/NfeConsulta2.asmx" }, ;
      ;
      { "PR",   "3.10PC", "https://nfce.fazenda.pr.gov.br/nfce/NFeConsulta3" }, ;
      { "SVRS", "3.10PC", "https://nfce.svrs.rs.gov.br/ws/NfeConsulta/NfeConsulta2.asmx" }, ;
      ;
      { "PR",   "3.10HC", "https://homologacao.nfce.fazenda.pr.gov.br/nfce/NFeConsulta3" }, ;
      { "SVRS", "3.10HC", "https://nfce-homologacao.svrs.rs.gov.br/ws/NfeConsulta/NfeConsulta2.asmx" }, ;
      ;
      { "MG",   "4.00P", "https://nfe.fazenda.mg.gov.br/nfe2/services/NFeConsultaProtocolo4" }, ;
      { "SP",   "4.00P", "https://nfe.fazenda.sp.gov.br/ws/nfeconsultaprotocolo4.asmx" }, ;
      ;
      { "MG",   "4.00H", "https://hnfe.fazenda.mg.gov.br/nfe2/services/NFeConsultaProtocolo4" }, ;
      { "SP",   "4.00H", "https://homologacao.nfe.fazenda.sp.gov.br/ws/nfeconsultaprotocolo4.asmx" } }
   ::Setup( cChave, cCertificado, cAmbiente )
   IF ::cVersao == "3.10"
      DO CASE
      CASE ::cUF == "BA"
         ::cSoapAction  := "nfeConsultaNF"
         ::cSoapService := "http://www.portalfiscal.inf.br/nfe/wsdl/NfeConsulta"
      CASE ::cUF $ "AC,AL,AP,DF,ES,PB,RJ,RN,RO,RR,SC,SE,TO"
         ::cSoapAction  := "nfeConsultaNF2"
         ::cSoapService := "http://www.portalfiscal.inf.br/nfe/wsdl/NfeConsulta2"
      OTHERWISE
         ::cSoapAction  := "NfeConsulta2"
         ::cSoapService := "http://www.portalfiscal.inf.br/nfe/wsdl/NfeConsulta2"
      ENDCASE
   ELSE
      ::cSoapAction := "NfeConsulta4"
      ::cSoapService := "http://www.portalfiscal.inf.br/nfe/wsdl/NfeConsulta"
   ENDIF

   ::cXmlEnvio    := [<consSitNFe versao="] + ::cVersao + [" ] + WS_XMLNS_NFE + [>]
   ::cXmlEnvio    +=    XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlEnvio    +=    XmlTag( "xServ", "CONSULTAR" )
   ::cXmlEnvio    +=    XmlTag( "chNFe", cChave )
   ::cXmlEnvio    += [</consSitNFe>]
   IF ! DfeModFis( cChave ) $ "55,65"
      ::cXmlRetorno := [<erro text="*ERRO* NfeConsultaProtocolo() Chave n�o se refere a NFE" />]
   ELSE
      ::XmlSoapPost()
   ENDIF
   ::cStatus := XmlNode( ::cXmlRetorno, "cStat" )
   ::cMotivo := XmlNode( ::cXmlRetorno, "xMotivo" )

   RETURN ::cXmlRetorno

   /* 2015.07.31.1400 Iniciado apenas */

METHOD NFeDistribuicaoDFe( cCnpj, cUltNSU, cNSU, cUF, cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_NFE )
   hb_Default( @::cVersao, "3.10" )
   hb_Default( @cUltNSU, "0" )
   hb_Default( @cNSU, "" )

   ::aSoapUrlList := { ;
      { "AN",    "3.10P", "https://www1.nfe.fazenda.gov.br/NFeDistribuicaoDFe/NFeDistribuicaoDFe.asmx" } }
   ::Setup( cUF, cCertificado, cAmbiente )
   ::cSoapAction  := "nfeDistDFeInteresse"
   ::cSoapService := "http://www.portalfiscal.inf.br/nfe/wsdl/NFeDistribuicaoDFe"

   ::cXmlEnvio    := [<distDFeInt versao="] + ::cVersao + [" ] + WS_XMLNS_NFE + [>]
   ::cXmlEnvio    +=    XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlEnvio    +=    XmlTag( "cUFAutor", ::UFCodigo( ::cUF ) )
   ::cXmlEnvio    +=    XmlTag( "CNPJ", cCnpj ) // ou CPF
   IF Empty( cNSU )
      ::cXmlEnvio +=   [<distNSU>]
      ::cXmlEnvio +=      XmlTag( "ultNSU", cUltNSU )
      ::cXmlEnvio +=   [</distNSU>]
   ELSE
      ::cXmlEnvio +=   [<consNSU>]
      ::cXmlEnvio +=      XmlTag( "NSU", cNSU )
      ::cXmlEnvio +=   [</consNSU>]
   ENDIF
   ::cXmlEnvio   += [</distDFeInt>]
   ::XmlSoapPost()

   RETURN ::cXmlRetorno

METHOD NFeEventoSoapList() CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_NFE )
   hb_Default( @::cVersao, "3.10" )
   ::aSoapUrlList := { ;
      { "AM",    "3.10P", "https://nfe.sefaz.am.gov.br/services2/services/RecepcaoEvento" }, ;
      { "BA",    "3.10P", "https://nfe.sefaz.ba.gov.br/webservices/sre/RecepcaoEvento.asmx" }, ;
      { "CE",    "3.10P", "https://nfe.sefaz.ce.gov.br/nfe2/services/RecepcaoEvento?wsdl" }, ;
      { "GO",    "3.10P", "https://nfe.sefaz.go.gov.br/nfe/services/v2/RecepcaoEvento?wsdl" }, ;
      { "MG",    "3.10P", "https://nfe.fazenda.mg.gov.br/nfe2/services/RecepcaoEvento" }, ;
      { "MS",    "3.10P", "https://nfe.fazenda.ms.gov.br/producao/services2/RecepcaoEvento" }, ;
      { "MT",    "3.10P", "https://nfe.sefaz.mt.gov.br/nfews/v2/services/RecepcaoEvento?wsdl" }, ;
      { "PE",    "3.10P", "https://nfe.sefaz.pe.gov.br/nfe-service/services/RecepcaoEvento" }, ;
      { "PR",    "3.10P", "https://nfe2.fazenda.pr.gov.br/nfe-evento/NFeRecepcaoEvento?wsdl" }, ;
      { "RS",    "3.10P", "https://nfe.sefazrs.rs.gov.br/ws/recepcaoevento/recepcaoevento.asmx" }, ;
      { "SP",    "3.10P", "https://nfe.fazenda.sp.gov.br/ws/recepcaoevento.asmx" }, ;
      { "SVRS",  "3.10P", "https://nfe.svrs.rs.gov.br/ws/recepcaoevento/recepcaoevento.asmx" }, ;
      { "SCAN",  "3.10P", "https://www.scan.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx" }, ;
      { "SVAN",  "3.10P", "https://www.sefazvirtual.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx" }, ;
      { "SCVAN", "3.10P", "https://www.svc.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx" }, ;
      { "AN",    "3.10P", "https://www.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx" }, ;
      ;
      { "AM",    "3.10H", "https://homnfe.sefaz.am.gov.br/services2/services/RecepcaoEvento" }, ;
      { "BA",    "3.10H", "https://hnfe.sefaz.ba.gov.br/webservices/sre/RecepcaoEvento.asmx" }, ;
      { "CE",    "3.10H", "https://nfeh.sefaz.ce.gov.br/nfe2/services/RecepcaoEvento?wsdl" }, ;
      { "GO",    "3.10H", "https://homolog.sefaz.go.gov.br/nfe/services/v2/NfeRecepcaoEvento?wsdl" }, ;
      { "MG",    "3.10H", "https://hnfe.fazenda.mg.gov.br/nfe2/services/RecepcaoEvento" }, ;
      { "MS",    "3.10H", "https://homologacao.nfe.ms.gov.br/homologacao/services2/RecepcaoEvento" }, ;
      { "MT",    "3.10H", "https://homologacao.sefaz.mt.gov.br/nfews/v2/services/RecepcaoEvento?wsdl" }, ;
      { "PE",    "3.10H", "https://nfehomolog.sefaz.pe.gov.br/nfe-service/services/RecepcaoEvento" }, ;
      { "PR",    "3.10H", "https://homologacao.nfe.fazenda.pr.gov.br/nfe/NFeRecepcaoEvento?wsdl" }, ;
      { "RS",    "3.10H", "https://nfe-homologacao.sefazrs.rs.gov.br/ws/recepcaoevento/recepcaoevento.asmx" }, ;
      { "SP",    "3.10H", "https://homologacao.nfe.fazenda.sp.gov.br/ws/recepcaoevento.asmx" }, ;
      { "SVRS",  "3.10H", "https://nfe-homologacao.svrs.rs.gov.br/ws/recepcaoevento/recepcaoevento.asmx" }, ;
      { "SVAN",  "3.10H", "https://hom.sefazvirtual.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx" }, ;
      ;
      { "PR",   "3.10PC", "https://nfce.fazenda.pr.gov.br/nfce/NFeRecepcaoEvento" }, ;
      { "SVRS", "3.10PC", "https://nfce.svrs.rs.gov.br/ws/recepcaoevento/recepcaoevento.asmx" }, ;
      ;
      { "PR",   "3.10HC", "https://homologacao.nfce.fazenda.pr.gov.br/nfce/NFeRecepcaoEvento" }, ;
      { "SVRS", "3.10HC", "https://nfce-homologacao.svrs.rs.gov.br/ws/recepcaoevento/recepcaoevento.asmx" }, ;
      ;
      { "MG",   "4.00P", "https://nfe.fazenda.mg.gov.br/nfe2/services/NFeRecepcaoEvento4 " }, ;
      { "SP",   "4.00P", "https://nfe.fazenda.sp.gov.br/ws/nferecepcaoevento4.asmx" }, ;
      ;
      { "MG",   "4.00H", "https://hnfe.fazenda.mg.gov.br/nfe2/services/NFeRecepcaoEvento4 " }, ;
      { "SP",   "4.00H", "https://homologacao.nfe.fazenda.sp.gov.br/ws/nferecepcaoevento4.asmx" } }
   IF ::cVersao == "3.10"
      ::cSoapAction  := "nfeRecepcaoEvento"
      ::cSoapService := "http://www.portalfiscal.inf.br/nfe/wsdl/RecepcaoEvento"
   ELSE
      ::cSoapAction  := "NfeRecepcaoEvento4"
      ::cSoapService := "http://www.portalfiscal.inf.br/nfe/wsdl/NfeRecepcaoEvento"
   ENDIF

   RETURN NIL

METHOD NFeEventoCarta( cChave, nSequencia, cTexto, cCertificado, cAmbiente ) CLASS SefazClass

   LOCAL cVersaoEvento

   hb_Default( @::cProjeto, WS_PROJETO_NFE )
   hb_Default( @::cVersao, "3.10" )
   hb_Default( @nSequencia, 1 )
   ::cNFCe := iif( DfeModFis( cChave ) == "65", "S", "N" )
   ::NFeEventoSoapList()
   ::Setup( cChave, cCertificado, cAmbiente )
   cVersaoEvento := iif( ::cVersao == "3.10", "1.00", "4.00" )
   ::cXmlDocumento := [<evento versao="] + cVersaoEvento + [" ] + WS_XMLNS_NFE + [>]
   ::cXmlDocumento +=    [<infEvento Id="ID110110] + cChave + StrZero( nSequencia, 2 ) + [">]
   ::cXmlDocumento +=       XmlTag( "cOrgao", Substr( cChave, 1, 2 ) )
   ::cXmlDocumento +=       XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlDocumento +=       XmlTag( "CNPJ", DfeEmitente( cChave ) )
   ::cXmlDocumento +=       XmlTag( "chNFe", cChave )
   ::cXmlDocumento +=       XmlTag( "dhEvento", ::DateTimeXml() )
   ::cXmlDocumento +=       XmlTag( "tpEvento", "110110" )
   ::cXmlDocumento +=       XmlTag( "nSeqEvento", LTrim( Str( nSequencia, 4 ) ) )
   ::cXmlDocumento +=       XmlTag( "verEvento", cVersaoEvento )
   ::cXmlDocumento +=       [<detEvento versao="] + cVersaoEvento + [">]
   ::cXmlDocumento +=          XmlTag( "descEvento", "Carta de Correcao" )
   ::cXmlDocumento +=          XmlTag( "xCorrecao", cTexto )
   ::cXmlDocumento +=          [<xCondUso>]
   ::cXmlDocumento +=          "A Carta de Correcao e disciplinada pelo paragrafo 1o-A do art. 7o do Convenio S/N, "
   ::cXmlDocumento +=          "de 15 de dezembro de 1970 e pode ser utilizada para regularizacao de erro ocorrido na "
   ::cXmlDocumento +=          "emissao de documento fiscal, desde que o erro nao esteja relacionado com: "
   ::cXmlDocumento +=          "I - as variaveis que determinam o valor do imposto tais como: base de calculo, aliquota, "
   ::cXmlDocumento +=          "diferenca de preco, quantidade, valor da operacao ou da prestacao; "
   ::cXmlDocumento +=          "II - a correcao de dados cadastrais que implique mudanca do remetente ou do destinatario; "
   ::cXmlDocumento +=          "III - a data de emissao ou de saida."
   ::cXmlDocumento +=         [</xCondUso>]
   ::cXmlDocumento +=       [</detEvento>]
   ::cXmlDocumento +=    [</infEvento>]
   ::cXmlDocumento += [</evento>]
   IF ::AssinaXml() == "OK"
      ::cXmlEnvio := [<envEvento versao="] + cVersaoEvento + [" xmlns="http://www.portalfiscal.inf.br/nfe">]
      ::cXmlEnvio +=    XmlTag( "idLote", DfeNumero( cChave ) ) // usado numero da nota
      ::cXmlEnvio +=    ::cXmlDocumento
      ::cXmlEnvio += [</envEvento>]
      ::XmlSoapPost()
      ::cXmlProtocolo := ::cXmlRetorno
      ::NfeGeraEventoAutorizado( ::cXmlDocumento, ::cXmlProtocolo )
   ENDIF

   RETURN ::cXmlRetorno

METHOD NFeEventoCancela( cChave, nSequencia, nProt, xJust, cCertificado, cAmbiente ) CLASS SefazClass

   LOCAL cVersaoEvento

   hb_Default( @::cProjeto, WS_PROJETO_NFE )
   hb_Default( @::cVersao, "3.10" )
   hb_Default( @nSequencia, 1 )
   ::cNFCe := iif( DfeModFis( cChave ) == "65", "S", "N" )
   ::NFeEventoSoapList()
   ::Setup( cChave, cCertificado, cAmbiente )
   cVersaoEvento := iif( ::cVersao == "3.10", "1.00", "4.00" )

   ::cXmlDocumento := [<evento versao="] + cVersaoEvento + [" ] + WS_XMLNS_NFE + [>]
   ::cXmlDocumento +=    [<infEvento Id="ID110111] + cChave + StrZero( nSequencia, 2 ) + [">]
   ::cXmlDocumento +=       XmlTag( "cOrgao", Substr( cChave, 1, 2 ) )
   ::cXmlDocumento +=       XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlDocumento +=       XmlTag( "CNPJ", DfeEmitente( cChave ) )
   ::cXmlDocumento +=       XmlTag( "chNFe", cChave )
   ::cXmlDocumento +=       XmlTag( "dhEvento", ::DateTimeXml() )
   ::cXmlDocumento +=       XmlTag( "tpEvento", "110111" )
   ::cXmlDocumento +=       XmlTag( "nSeqEvento", Ltrim( Str( nSequencia, 4 ) ) )
   ::cXmlDocumento +=       XmlTag( "verEvento", cVersaoEvento )
   ::cXmlDocumento +=       [<detEvento versao="] + cVersaoEvento + [">]
   ::cXmlDocumento +=          XmlTag( "descEvento", "Cancelamento" )
   ::cXmlDocumento +=          XmlTag( "nProt", Ltrim( Str( nProt ) ) )
   ::cXmlDocumento +=          XmlTag( "xJust", xJust )
   ::cXmlDocumento +=       [</detEvento>]
   ::cXmlDocumento +=    [</infEvento>]
   ::cXmlDocumento += [</evento>]
   IF ::AssinaXml() == "OK"
      ::cXmlEnvio := [<envEvento versao="] + cVersaoEvento + [" ] + WS_XMLNS_NFE + [>]
      ::cXmlEnvio +=    XmlTag( "idLote", DfeNumero( cChave ) ) // usado numero da nota
      ::cXmlEnvio +=    ::cXmlDocumento
      ::cXmlEnvio += [</envEvento>]
      ::XmlSoapPost()
      ::cXmlProtocolo := ::cXmlRetorno
      ::NFeGeraEventoAutorizado( ::cXmlDocumento, ::cXmlProtocolo )
   ENDIF

   RETURN ::cXmlRetorno

METHOD NFeEventoManifestacao( cChave, nSequencia, xJust, cCodigoEvento, cCertificado, cAmbiente ) CLASS SefazClass

   LOCAL cDescEvento, cVersaoEvento

   hb_Default( @::cProjeto, WS_PROJETO_NFE )
   hb_Default( @::cVersao, "3.10" )
   hb_Default( @nSequencia, 1 )
   ::cNFCe := iif( DfeModFis( cChave ) == "65", "S", "N" )
   ::NFeEventoSoapList()
   ::Setup( cChave, cCertificado, cAmbiente )
   cVersaoEvento := iif( ::cVersao == "3.10", "1.00", "4.00" )

   DO CASE
   CASE cCodigoEvento == "210200" ; cDescEvento := "Confirmacao da Operacao"
   CASE cCodigoEvento == "210210" ; cDescEvento := "Ciencia da Operacao"
   CASE cCodigoEvento == "210220" ; cDescEvento := "Desconhecimento da Operacao"
   CASE cCodigoEvento == "210240" ; cDescEvento := "Operacao Nao Realizada"
   ENDCASE

   ::cXmlDocumento := [<evento versao="] + cVersaoEvento + [" ] + WS_XMLNS_NFE + [>]
   ::cXmlDocumento +=    [<infEvento Id="ID] + cCodigoEvento + cChave + StrZero( nSequencia, 2 ) + [">]
   ::cXmlDocumento +=       XmlTag( "cOrgao", Substr( cChave, 1, 2 ) )
   ::cXmlDocumento +=       XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlDocumento +=       XmlTag( "CNPJ", DfeEmitente( cChave ) )
   ::cXmlDocumento +=       XmlTag( "chNFe", cChave )
   ::cXmlDocumento +=       XmlTag( "dhEvento", ::DateTimeXml() )
   ::cXmlDocumento +=       XmlTag( "tpEvento", cCodigoEvento )
   ::cXmlDocumento +=       XmlTag( "nSeqEvento", StrZero( 1, 2 ) )
   ::cXmlDocumento +=       XmlTag( "verEvento", cVersaoEvento )
   ::cXmlDocumento +=       [<detEvento versao="] + cVersaoEvento + [">]
   ::cXmlDocumento +=          XmlTag( "descEvento", cDescEvento )
   IF cCodigoEvento == "210240"
      ::cXmlDocumento +=          XmlTag( "xJust", xJust )
   ENDIF
   ::cXmlDocumento +=       [</detEvento>]
   ::cXmlDocumento +=    [</infEvento>]
   ::cXmlDocumento += [</evento>]
   IF ::AssinaXml() == "OK"
      ::cXmlEnvio := [<envEvento versao="] + cVersaoEvento + [" ] + WS_XMLNS_NFE + [>]
      ::cXmlEnvio +=    XmlTag( "idLote", DfeNumero( cChave ) ) // usado numero da nota
      ::cXmlEnvio +=    ::cXmlDocumento
      ::cXmlEnvio += [</envEvento>]
      ::XmlSoapPost()
      ::cXmlProtocolo := ::cXmlRetorno
      ::NFeGeraEventoAutorizado( ::cXmlDocumento, ::cXmlProtocolo )
   ENDIF

   RETURN ::cXmlRetorno

METHOD NFeInutiliza( cAno, cCnpj, cMod, cSerie, cNumIni, cNumFim, cJustificativa, cUF, cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_NFE )
   hb_Default( @::cVersao, "3.10" )
   ::aSoapUrlList := { ;
      { "AM",    "3.10P", "https://nfe.sefaz.am.gov.br/services2/services/NfeInutilizacao2" }, ;
      { "BA",    "3.10P", "https://nfe.sefaz.ba.gov.br/webservices/NfeInutilizacao/NfeInutilizacao.asmx" }, ;
      { "CE",    "3.10P", "https://nfe.sefaz.ce.gov.br/nfe2/services/NfeInutilizacao2?wsdl" }, ;
      { "GO",    "3.10P", "https://nfe.sefaz.go.gov.br/nfe/services/v2/NfeInutilizacao2?wsdl" }, ;
      { "MG",    "3.10P", "https://nfe.fazenda.mg.gov.br/nfe2/services/NfeInutilizacao2" }, ;
      { "MS",    "3.10P", "https://nfe.fazenda.ms.gov.br/producao/services2/NfeInutilizacao2" }, ;
      { "MT",    "3.10P", "https://nfe.sefaz.mt.gov.br/nfews/v2/services/NfeInutilizacao2?wsdl" }, ;
      { "PE",    "3.10P", "https://nfe.sefaz.pe.gov.br/nfe-service/services/NfeInutilizacao2" }, ;
      { "PR",    "3.10P", "https://nfe.fazenda.pr.gov.br/nfe/NFeInutilizacao3?wsdl" }, ;
      { "RS",    "3.10P", "https://nfe.sefazrs.rs.gov.br/ws/nfeinutilizacao/nfeinutilizacao2.asmx" }, ;
      { "SP",    "3.10P", "https://nfe.fazenda.sp.gov.br/ws/nfeinutilizacao2.asmx" }, ;
      { "SVRS",  "3.10P", "https://nfe.svrs.rs.gov.br/ws/nfeinutilizacao/nfeinutilizacao2.asmx" }, ;
      { "SCAN",  "3.10P", "https://www.scan.fazenda.gov.br/NfeInutilizacao2/NfeInutilizacao2.asmx" }, ;
      { "SVAN",  "3.10P", "https://www.sefazvirtual.fazenda.gov.br/NfeInutilizacao2/NfeInutilizacao2.asmx" }, ;
      ;
      { "AM",    "3.10H", "https://homnfe.sefaz.am.gov.br/services2/services/NfeInutilizacao2" }, ;
      { "BA",    "3.10H", "https://hnfe.sefaz.ba.gov.br/webservices/nfenw/NfeInutilizacao2.asmx" }, ;
      { "CE",    "3.10H", "https://nfeh.sefaz.ce.gov.br/nfe2/services/NfeInutilizacao2?wsdl" }, ;
      { "GO",    "3.10H", "https://homolog.sefaz.go.gov.br/nfe/services/v2/NfeInutilizacao2?wsdl" }, ;
      { "MG",    "3.10H", "https://hnfe.fazenda.mg.gov.br/nfe2/services/NfeInutilizacao2" }, ;
      { "MS",    "3.10H", "https://homologacao.nfe.ms.gov.br/homologacao/services2/NfeInutilizacao2" }, ;
      { "MT",    "3.10H", "https://homologacao.sefaz.mt.gov.br/nfews/v2/services/NfeInutilizacao2?wsdl" }, ;
      { "PE",    "3.10H", "https://nfehomolog.sefaz.pe.gov.br/nfe-service/services/NfeInutilizacao2" }, ;
      { "PR",    "3.10H", "https://homologacao.nfe.fazenda.pr.gov.br/nfe/NFeInutilizacao3?wsdl" }, ;
      { "RS",    "3.10H", "https://nfe-homologacao.sefazrs.rs.gov.br/ws/nfeinutilizacao/nfeinutilizacao2.asmx" }, ;
      { "SP",    "3.10H", "https://homologacao.nfe.fazenda.sp.gov.br/ws/nfeinutilizacao2.asmx" }, ;
      { "SVRS",  "3.10H", "https://nfe-homologacao.svrs.rs.gov.br/ws/nfeinutilizacao/nfeinutilizacao2.asmx" }, ;
      { "SCAN",  "3.10H", "https://hom.nfe.fazenda.gov.br/SCAN/NfeInutilizacao2/NfeInutilizacao2.asmx" }, ;
      { "SVAN",  "3.10H", "https://hom.sefazvirtual.fazenda.gov.br/NfeInutilizacao2/NfeInutilizacao2.asmx" }, ;
      ;
      { "PR",   "3.10PC", "https://nfce.fazenda.pr.gov.br/nfce/NFeInutilizacao3" }, ;
      { "SVRS", "3.10PC", "https://nfce.svrs.rs.gov.br/ws/nfeinutilizacao/nfeinutilizacao2.asmx" }, ;
      ;
      { "PR",   "3.10HC", "https://homologacao.nfce.fazenda.pr.gov.br/nfce/NFeInutilizacao3" }, ;
      { "SVRS", "3.10HC", "https://nfce-homologacao.svrs.rs.gov.br/ws/nfeinutilizacao/nfeinutilizacao2.asmx" }, ;
      ;
      { "MG", "4.00P", "https://nfe.fazenda.mg.gov.br/nfe2/services/NFeInutilizacao4" }, ;
      { "SP", "4.00P", "https://nfe.fazenda.sp.gov.br/ws/nfeinutilizacao4.asmx" }, ;
      ;
      { "MG", "4.00H", "https://hnfe.fazenda.mg.gov.br/nfe2/services/NFeInutilizacao4" }, ;
      { "SP", "4.00H", "https://homologacao.nfe.fazenda.sp.gov.br/ws/nfeinutilizacao4.asmx" } }
   ::Setup( cUF, cCertificado, cAmbiente )
   IF ::cVersao == "3.10"
      ::cSoapAction  := "NfeInutilizacaoNF2"
      ::cSoapService := "http://www.portalfiscal.inf.br/nfe/wsdl/NfeInutilizacao2"
   ELSE
      ::cSoapAction  := "Nfeinutilizacao4"
      ::cSoapService := "http://www.portalfiscal.inf.br/nfe/wsdl/NfeInutilizacao"
   ENDIF

   ::cXmlDocumento := [<inutNFe versao="] + ::cVersao + [" ] + WS_XMLNS_NFE + [>]
   ::cXmlDocumento +=    [<infInut Id="ID] + ::UFCodigo( ::cUF ) + Right( cAno, 2 ) + cCnpj + cMod + StrZero( Val( cSerie ), 3 )
   ::cXmlDocumento +=    StrZero( Val( cNumIni ), 9 ) + StrZero( Val( cNumFim ), 9 ) + [">]
   ::cXmlDocumento +=       XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlDocumento +=       XmlTag( "xServ", "INUTILIZAR" )
   ::cXmlDocumento +=       XmlTag( "cUF", ::UFCodigo( ::cUF ) )
   ::cXmlDocumento +=       XmlTag( "ano", Right( cAno, 2 ) )
   ::cXmlDocumento +=       XmlTag( "CNPJ", SoNumeros( cCnpj ) )
   ::cXmlDocumento +=       XmlTag( "mod", cMod )
   ::cXmlDocumento +=       XmlTag( "serie", cSerie )
   ::cXmlDocumento +=       XmlTag( "nNFIni", cNumIni )
   ::cXmlDocumento +=       XmlTag( "nNFFin", cNumFim )
   ::cXmlDocumento +=       XmlTag( "xJust", cJustificativa )
   ::cXmlDocumento +=    [</infInut>]
   ::cXmlDocumento += [</inutNFe>]

   IF ::AssinaXml() == "OK"
      ::cXmlEnvio := ::cXmlDocumento
      ::XmlSoapPost()
      ::cStatus := Pad( XmlNode( ::cXmlRetorno, "cStat" ), 3 )
      ::cMotivo := XmlNode( ::cXmlRetorno, "xMotivo" )
      IF ::cStatus == "102"
         ::cXmlAutorizado := XML_UTF8
         ::cXmlAutorizado += [<ProcInutNFe versao="] + ::cVersao + [" ] + WS_XMLNS_NFE + [>]
         ::cXmlAutorizado += ::cXmlDocumento
         ::cXmlAutorizado += XmlNode( ::cXmlRetorno, "retInutNFe", .T. )
         ::cXmlAutorizado += [</ProcInutNFe>]
      ENDIF
   ENDIF

   RETURN ::cXmlRetorno

METHOD NFeLoteEnvia( cXml, cLote, cUF, cCertificado, cAmbiente, cIndSinc ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_NFE )
   hb_Default( @::cVersao, "3.10" )
   hb_Default( @cIndSinc, ::cIndSinc )

   ::aSoapUrlList := { ;
      { "AM",    "3.10P", "https://nfe.sefaz.am.gov.br/services2/services/NfeAutorizacao" }, ;
      { "BA",    "3.10P", "https://nfe.sefaz.ba.gov.br/webservices/NfeAutorizacao/NfeAutorizacao.asmx" }, ;
      { "CE",    "3.10P", "https://nfe.sefaz.ce.gov.br/nfe2/services/NfeAutorizacao?wsdl" }, ;
      { "GO",    "3.10P", "https://nfe.sefaz.go.gov.br/nfe/services/v2/NfeAutorizacao?wsdl" }, ;
      { "MG",    "3.10P", "https://nfe.fazenda.mg.gov.br/nfe2/services/NfeAutorizacao" }, ;
      { "MS",    "3.10P", "https://nfe.fazenda.ms.gov.br/producao/services2/NfeAutorizacao" }, ;
      { "MT",    "3.10P", "https://nfe.sefaz.mt.gov.br/nfews/v2/services/NfeAutorizacao?wsdl" }, ;
      { "PE",    "3.10P", "https://nfe.sefaz.pe.gov.br/nfe-service/services/NfeAutorizacao?wsdl" }, ;
      { "PR",    "3.10P", "https://nfe.fazenda.pr.gov.br/nfe/NFeAutorizacao3?wsdl" }, ;
      { "RS",    "3.10P", "https://nfe.sefazrs.rs.gov.br/ws/NfeAutorizacao/NFeAutorizacao.asmx" }, ;
      { "SP",    "3.10P", "https://nfe.fazenda.sp.gov.br/ws/nfeautorizacao.asmx" }, ;
      { "SVRS",  "3.10P", "https://nfe.svrs.rs.gov.br/ws/NfeAutorizacao/NFeAutorizacao.asmx" }, ;
      { "SCAN",  "3.10P", "https://www.scan.fazenda.gov.br/NfeAutorizacao/NfeAutorizacao.asmx" }, ;
      { "SCVAN", "3.10P", "https://www.svc.fazenda.gov.br/NfeAutorizacao/NfeAutorizacao.asmx" }, ;
      { "SVAN",  "3.10P", "https://www.sefazvirtual.fazenda.gov.br/NfeAutorizacao/NfeAutorizacao.asmx" }, ;
      ;
      { "CE",    "3.10H", "https://nfeh.sefaz.ce.gov.br/nfe2/services/NfeAutorizacao?wsdl" }, ;
      { "MG",    "3.10H", "https://hnfe.fazenda.mg.gov.br/nfe2/services/NfeAutorizacao" }, ;
      { "PR",    "3.10H", "https://homologacao.nfe.fazenda.pr.gov.br/nfe/NFeAutorizacao3?wsdl" }, ;
      { "RS",    "3.10H", "https://nfe-homologacao.sefazrs.rs.gov.br/ws/NfeAutorizacao/NFeAutorizacao.asmx" }, ;
      { "SP",    "3.10H", "https://homologacao.nfe.fazenda.sp.gov.br/ws/nfeautorizacao.asmx" }, ;
      { "SVRS",  "3.10H", "https://nfe-homologacao.svrs.rs.gov.br/ws/NfeAutorizacao/NFeAutorizacao.asmx" }, ;
   ;
      { "PR",   "3.10PC", "https://nfce.fazenda.pr.gov.br/nfce/NFeAutorizacao3" }, ;
      { "SVRS", "3.10PC", "https://nfce.svrs.rs.gov.br/ws/NfeAutorizacao/NFeAutorizacao.asmx" }, ;
      ;
      { "PR",   "3.10HC", "https://homologacao.nfce.fazenda.pr.gov.br/nfce/NFeAutorizacao3" }, ;
      { "SVRS", "3.10HC", "https://nfce-homologacao.svrs.rs.gov.br/ws/NfeAutorizacao/NFeAutorizacao.asmx" }, ;
   ;
      { "MG", "4.00P", "https://nfe.fazenda.mg.gov.br/nfe2/services/NFeAutorizacao4" }, ;
      { "SP", "4.00P", "https://nfe.fazenda.sp.gov.br/ws/nfeautorizacao4.asmx" }, ;
      ;
      { "MG", "4.00H", "https://hnfe.fazenda.mg.gov.br/nfe2/services/NFeAutorizacao4" }, ;
      { "SP", "4.00H", "https://homologacao.nfe.fazenda.sp.gov.br/ws/nfeautorizacao4.asmx" } }
   ::Setup( cUF, cCertificado, cAmbiente )
   IF ::cVersao == "3.10"
      IF ::cUF $ "AC,AL,AP,DF,ES,PB,PR,RJ,RN,RO,RR,SC,SE,TO"
         ::cSoapAction := "nfeAutorizacaoLote"
         ::cSoapService := "http://www.portalfiscal.inf.br/nfe/wsdl/NfeAutorizacao"
      ELSE
         ::cSoapAction := "NfeAutorizacao"
         ::cSoapService := "http://www.portalfiscal.inf.br/nfe/wsdl/NfeAutorizacao"
      ENDIF
   ELSE
      ::cSoapAction  := "NfeAutorizacao4"
      ::cSoapService := "http://www.portalfiscal.inf.br/nfe/wsdl/NfeAutorizacao"
   ENDIF

   IF Empty( cLote )
      cLote := "1"
   ENDIF
   IF cXml != NIL
      ::cXmlDocumento := cXml
   ENDIF
   IF ::AssinaXml() != "OK"
      RETURN ::cXmlRetorno
   ENDIF
   IF ::cNFCe == "S"
      GeraQRCode( @::cXmlDocumento, ::cIdToken, ::cCSC, ::cVersao )
   ENDIF

   ::cXmlEnvio    := [<enviNFe versao="] + ::cVersao + [" ] + WS_XMLNS_NFE + [>]
   // FOR EACH cXmlNota IN aXmlNotas
   ::cXmlEnvio    += XmlTag( "idLote", cLote )
   ::cXmlEnvio    += XmlTag( "indSinc", cIndSinc )
   ::cXmlEnvio    += ::cXmlDocumento
   // NEXT
   ::cXmlEnvio    += [</enviNFe>]
   ::XmlSoapPost()
   IF cIndSinc == WS_RETORNA_RECIBO
      ::cXmlRecibo := ::cXmlRetorno
      ::cRecibo    := XmlNode( ::cXmlRecibo, "nRec" )
      ::cStatus    := Pad( XmlNode( ::cXmlRecibo, "cStat" ), 3 )
      ::cMotivo    := XmlNode( ::cXmlRecibo, "xMotivo" )
      IF ! Empty( ::cRecibo )
         Inkey( ::nTempoEspera )
         ::NfeConsultaRecibo()
         ::NfeGeraAutorizado( ::cXmlDocumento, ::cXmlProtocolo )
      ENDIF
   ELSE
      ::cXmlRecibo := ::cXmlRetorno
      ::cRecibo    := XmlNode( ::cXmlRecibo, "nRec" )
      ::cStatus    := Pad( XmlNode( ::cXmlRecibo, "cStat" ), 3 )
      ::cMotivo    := XmlNode( ::cXmlRecibo, "xMotivo" )
      IF ! Empty( ::cRecibo )
         ::cXmlProtocolo := ::cXmlRetorno
         ::cXmlRetorno   := ::NfeGeraAutorizado( ::cXmlDocumento, ::cXmlProtocolo )
      ENDIF
   ENDIF

   RETURN ::cXmlRetorno

METHOD NFeConsultaRecibo( cRecibo, cUF, cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_NFE )
   hb_Default( @::cVersao, "3.10" )
   IF cRecibo != NIL
      ::cRecibo := cRecibo
   ENDIF

   ::aSoapUrlList := { ;
      { "AM",    "3.10P", "https://nfe.sefaz.am.gov.br/services2/services/NfeRetAutorizacao" }, ;
      { "BA",    "3.10P", "https://nfe.sefaz.ba.gov.br/webservices/NfeRetAutorizacao/NfeRetAutorizacao.asmx" }, ;
      { "CE",    "3.10P", "https://nfe.sefaz.ce.gov.br/nfe2/services/NfeRetAutorizacao?wsdl" }, ;
      { "GO",    "3.10P", "https://nfe.sefaz.go.gov.br/nfe/services/v2/NfeRetAutorizacao?wsdl" }, ;
      { "MG",    "3.10P", "https://nfe.fazenda.mg.gov.br/nfe2/services/NfeRetAutorizacao" }, ;
      { "MS",    "3.10P", "https://nfe.fazenda.ms.gov.br/producao/services2/NfeRetAutorizacao" }, ;
      { "MT",    "3.10P", "https://nfe.sefaz.mt.gov.br/nfews/v2/services/NfeRetAutorizacao?wsdl" }, ;
      { "PE",    "3.10P", "https://nfe.sefaz.pe.gov.br/nfe-service/services/NfeRetAutorizacao?wsdl" }, ;
      { "PR",    "3.10P", "https://nfe.fazenda.pr.gov.br/nfe/NFeRetAutorizacao3?wsdl" }, ;
      { "RS",    "3.10P", "https://nfe.sefazrs.rs.gov.br/ws/NfeRetAutorizacao/NFeRetAutorizacao.asmx" }, ;
      { "SP",    "3.10P", "https://nfe.fazenda.sp.gov.br/ws/nferetautorizacao.asmx" }, ;
      { "SCAN",  "3.10P", "https://www.scan.fazenda.gov.br/NfeRetAutorizacao/NfeRetAutorizacao.asmx" }, ;
      { "SVRS",  "3.10P", "https://nfe.svrs.rs.gov.br/ws/NfeRetAutorizacao/NFeRetAutorizacao.asmx" }, ;
      { "SVAN",  "3.10P", "https://www.sefazvirtual.fazenda.gov.br/NfeRetAutorizacao/NfeRetAutorizacao.asmx" }, ;
      { "SCVAN", "3.10P", "https://www.svc.fazenda.gov.br/NfeRetAutorizacao/NfeRetAutorizacao.asmx" }, ;
      ;
      { "CE",    "3.10H", "https://nfeh.sefaz.ce.gov.br/nfe2/services/NfeRetAutorizacao?wsdl" }, ;
      { "MG",    "3.10H", "https://hnfe.fazenda.mg.gov.br/nfe2/services/NfeRetAutorizacao" }, ;
      { "PR",    "3.10H", "https://homologacao.nfe.fazenda.pr.gov.br/nfe/NFeRetAutorizacao3?wsdl" }, ;
      { "RS",    "3.10H", "https://nfe-homologacao.sefazrs.rs.gov.br/ws/NfeRetAutorizacao/NFeRetAutorizacao.asmx" }, ;
      { "SP",    "3.10H", "https://homologacao.nfe.fazenda.sp.gov.br/ws/nferetautorizacao.asmx" }, ;
      { "SVRS",  "3.10H", "https://nfe-homologacao.svrs.rs.gov.br/ws/NfeRetAutorizacao/NFeRetAutorizacao.asmx" }, ;
      ;
      { "PR",   "3.10PC", "https://nfce.fazenda.pr.gov.br/nfce/NFeRetAutorizacao3" }, ;
      { "SVRS", "3.10PC", "https://nfce.svrs.rs.gov.br/ws/NfeRetAutorizacao/NFeRetAutorizacao.asmx" }, ;
      ;
      { "PR",   "3.10HC", "https://homologacao.nfce.fazenda.pr.gov.br/nfce/NFeRetAutorizacao3" }, ;
      { "SVRS", "3.10HC", "https://nfce-homologacao.svrs.rs.gov.br/ws/NfeRetAutorizacao/NFeRetAutorizacao.asmx" }, ;
      ;
      { "MG", "4.00P", "https://nfe.fazenda.mg.gov.br/nfe2/services/NFeRetAutorizacao4" }, ;
      { "SP", "4.00P", "https://nfe.fazenda.sp.gov.br/ws/nferetautorizacao4.asmx" }, ;
      ;
      { "MG", "4.00H", "https://hnfe.fazenda.mg.gov.br/nfe2/services/NFeRetAutorizacao4" }, ;
      { "SP", "4.00H", "https://homologacao.nfe.fazenda.sp.gov.br/ws/nferetautorizacao4.asmx" } }
   ::Setup( cUF, cCertificado, cAmbiente )
   IF ::cVersao == "3.10"
      DO CASE
      CASE ::cUF == "PR"
         ::cSoapAction  := "NfeRetAutorizacaoLote"
         ::cSoapService := "http://www.portalfiscal.inf.br/nfe/wsdl/NfeRetAutorizacao3"
      OTHERWISE
         ::cSoapAction  := "NfeRetAutorizacao"
         ::cSoapService := "http://www.portalfiscal.inf.br/nfe/wsdl/NfeRetAutorizacao"
      ENDCASE
   ELSE
      ::cSoapAction  := "NfeRetAutorizacao4"
      ::cSoapService := "http://www.portalfiscal.inf.br/nfe/wsdl/NfeRetAutorizacao"
   ENDIF

   ::cXmlEnvio     := [<consReciNFe versao="] + ::cVersao + [" ] + WS_XMLNS_NFE + [>]
   ::cXmlEnvio     +=    XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlEnvio     +=    XmlTag( "nRec", ::cRecibo )
   ::cXmlEnvio     += [</consReciNFe>]
   ::XmlSoapPost()
   ::cXmlProtocolo := ::cXmlRetorno
   ::cMotivo       := XmlNode( XmlNode( ::cXmlRetorno, "infProt" ), "xMotivo" )

   RETURN ::cXmlRetorno

METHOD NFeStatusServico( cUF, cCertificado, cAmbiente ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_NFE )
   hb_Default( @::cVersao, "3.10" )
   ::aSoapUrlList := { ;
      { "AM",    "3.10P", "https://nfe.sefaz.am.gov.br/services2/services/NfeStatusServico2" }, ;
      { "BA",    "3.10P", "https://nfe.sefaz.ba.gov.br/webservices/NfeStatusServico/NfeStatusServico.asmx" }, ;
      { "CE",    "3.10P", "https://nfe.sefaz.ce.gov.br/nfe2/services/NfeStatusServico2?wsdl" }, ;
      { "GO",    "3.10P", "https://nfe.sefaz.go.gov.br/nfe/services/v2/NfeStatusServico2?wsdl" }, ;
      { "MG",    "3.10P", "https://nfe.fazenda.mg.gov.br/nfe2/services/NfeStatus2" }, ;
      { "MS",    "3.10P", "https://nfe.fazenda.ms.gov.br/producao/services2/NfeStatusServico2" }, ;
      { "MT",    "3.10P", "https://nfe.sefaz.mt.gov.br/nfews/v2/services/NfeStatusServico2?wsdl" }, ;
      { "PE",    "3.10P", "https://nfe.sefaz.pe.gov.br/nfe-service/services/NfeStatusServico2" }, ;
      { "PR",    "3.10P", "https://nfe.fazenda.pr.gov.br/nfe/NFeStatusServico3?wsdl" }, ;
      { "RS",    "3.10P", "https://nfe.sefazrs.rs.gov.br/ws/NfeStatusServico/NfeStatusServico2.asmx" }, ;
      { "SP",    "3.10P", "https://nfe.fazenda.sp.gov.br/ws/nfestatusservico2.asmx" }, ;
      { "SVRS",  "3.10P", "https://nfe.svrs.rs.gov.br/ws/nfeStatusServico/NfeStatusServico2.asmx" }, ;
      { "SCAN",  "3.10P", "https://www.scan.fazenda.gov.br/NfeStatusServico2/NfeStatusServico2.asmx" }, ;
      { "SVAN",  "3.10P", "https://www.sefazvirtual.fazenda.gov.br/NfeStatusServico2/NfeStatusServico2.asmx" }, ;
      { "SCVAN", "3.10P", "https://www.svc.fazenda.gov.br/NfeStatusServico2/NfeStatusServico2.asmx" }, ;
      ;
      { "AM",    "3.10H", "https://homnfe.sefaz.am.gov.br/services2/services/NfeStatusServico2" }, ;
      { "BA",    "3.10H", "https://hnfe.sefaz.ba.gov.br/webservices/NfeStatusServico/NfeStatusServico.asmx" }, ;
      { "CE",    "3.10H", "https://nfeh.sefaz.ce.gov.br/nfe2/services/NfeStatusServico2?wsdl" }, ;
      { "GO",    "3.10H", "https://homolog.sefaz.go.gov.br/nfe/services/v2/NfeStatusServico2?wsdl" }, ;
      { "MG",    "3.10H", "https://hnfe.fazenda.mg.gov.br/nfe2/services/NfeStatusServico2" }, ;
      { "MS",    "3.10H", "https://homologacao.nfe.ms.gov.br/homologacao/services2/NfeStatusServico2" }, ;
      { "MT",    "3.10H", "https://homologacao.sefaz.mt.gov.br/nfews/v2/services/NfeStatusServico2?wsdl" }, ;
      { "PE",    "3.10H", "https://nfehomolog.sefaz.pe.gov.br/nfe-service/services/NfeStatusServico2" }, ;
      { "PR",    "3.10H", "https://homologacao.nfe.fazenda.pr.gov.br/nfe/NFeStatusServico3?wsdl" }, ;
      { "RS",    "3.10H", "https://nfe-homologacao.sefazrs.rs.gov.br/ws/NfeStatusServico/NfeStatusServico2.asmx" }, ;
      { "SP",    "3.10H", "https://homologacao.nfe.fazenda.sp.gov.br/ws/nfestatusservico2.asmx" }, ;
      { "SVRS",  "3.10H", "https://nfe-homologacao.svrs.rs.gov.br/ws/NfeStatusServico/NfeStatusServico2.asmx" }, ;
      { "SCAN",  "3.10H", "https://hom.nfe.fazenda.gov.br/SCAN/NfeStatusServico2/NfeStatusServico2.asmx" }, ;
      { "SVAN",  "3.10H", "https://hom.sefazvirtual.fazenda.gov.br/NfeStatusServico2/NfeStatusServico2.asmx" }, ;
      ;
      { "PR",   "3.10PC", "https://nfce.fazenda.pr.gov.br/nfce/NFeStatusServico3" }, ;
      { "SVRS", "3.10PC", "https://nfce.svrs.rs.gov.br/ws/NfeStatusServico/NfeStatusServico2.asmx" }, ;
      ;
      { "PR",   "3.10HC", "https://homologacao.nfce.fazenda.pr.gov.br/nfce/NFeStatusServico3" }, ;
      { "SVRS", "3.10HC", "https://nfce-homologacao.svrs.rs.gov.br/ws/NfeStatusServico/NfeStatusServico2.asmx" }, ;
      ;
      { "MG", "4.00P", "https://nfe.fazenda.mg.gov.br/nfe2/services/NFeStatusServico4" }, ;
      { "SP", "4.00P", "https://nfe.fazenda.sp.gov.br/ws/nfestatusservico4.asmx" }, ;
      ;
      { "MG", "4.00H", "https://hnfe.fazenda.mg.gov.br/nfe2/services/NFeStatusServico4" }, ;
      { "SP", "4.00H", "https://homologacao.nfe.fazenda.sp.gov.br/ws/nfestatusservico4.asmx" } }
   ::Setup( cUF, cCertificado, cAmbiente )
   IF ::cVersao == "3.10"
      DO CASE
      CASE ::cUF == "BA"
         ::cSoapAction  := "nfeStatusServicoNF"
         ::cSoapService := "http://www.portalfiscal.inf.br/nfe/wsdl/NfeStatusServico"
      OTHERWISE
         ::cSoapAction  := "nfeStatusServicoNF2"
         ::cSoapService := "http://www.portalfiscal.inf.br/nfe/wsdl/NfeStatusServico2"
      ENDCASE
   ELSE
      ::cSoapAction  := "nfeStatusServicoNF"
      ::cSoapService := "http://www.portalfiscal.inf.br/nfe/wsdl/NFeStatusServico4"
   ENDIF

   ::cXmlEnvio    := [<consStatServ versao="] + ::cVersao + [" ] + WS_XMLNS_NFE + [>]
   ::cXmlEnvio    +=    XmlTag( "tpAmb", ::cAmbiente )
   ::cXmlEnvio    +=    XmlTag( "cUF", ::UFCodigo( ::cUF ) )
   ::cXmlEnvio    +=    XmlTag( "xServ", "STATUS" )
   ::cXmlEnvio    += [</consStatServ>]
   ::XmlSoapPost()

   RETURN ::cXmlRetorno

METHOD NFeGeraAutorizado( cXmlAssinado, cXmlProtocolo ) CLASS SefazClass

   hb_Default( @::cProjeto, WS_PROJETO_NFE )
   hb_Default( @::cVersao, "3.10" )
   cXmlAssinado  := iif( cXmlAssinado == NIL, ::cXmlDocumento, cXmlAssinado )
   cXmlProtocolo := iif( cXmlProtocolo == NIL, ::cXmlProtocolo, cXmlProtocolo )

   ::cStatus := Pad( XmlNode( XmlNode( cXmlProtocolo, "protNFe" ), "cStat" ), 3 ) // Pad() garante 3 caracteres
   IF ! ::cStatus $ "100,101,150,301,302"
      ::cXmlRetorno := [<erro text="*ERRO* NFeGeraAutorizado() N�o autorizado" />] + ::cXmlProtocolo
      RETURN NIL
   ENDIF
   ::cXmlAutorizado := XML_UTF8
   ::cXmlAutorizado += [<nfeProc versao="] + ::cVersao + [" ] + WS_XMLNS_NFE + [>]
   ::cXmlAutorizado +=    cXmlAssinado
   ::cXmlAutorizado +=    XmlNode( cXmlProtocolo, "protNFe", .T. ) // hb_UTF8ToStr()
   ::cXmlAutorizado += [</nfeProc>]

   RETURN NIL

METHOD NFeGeraEventoAutorizado( cXmlAssinado, cXmlProtocolo ) CLASS SefazClass // runner

   LOCAL cVersaoEvento

   hb_Default( @::cProjeto, WS_PROJETO_NFE )
   hb_Default( @::cVersao, "3.10" )
   cVersaoEvento := iif( ::cVersao == "3.10", "1.00", "4.00" )

   cXmlAssinado  := iif( cXmlAssinado == NIL, ::cXmlDocumento, cXmlAssinado )
   cXmlProtocolo := iif( cXmlProtocolo == NIL, ::cXmlProtocolo, cXmlProtocolo )

   ::cStatus := Pad( XmlNode( XmlNode( cXmlProtocolo, "retEvento" ), "cStat" ), 3 )
   ::cMotivo := XmlNode( XmlNode( cXmlProtocolo, "retEvento" ), "xMotivo" ) // runner
   IF ! ::cStatus $ "135,155"
      ::cXmlRetorno := [<erro text="*ERRO* NFEGeraEventoAutorizado() Status inv�lido pra autoriza��o" />] + ::cXmlRetorno
      RETURN NIL
   ENDIF
   ::cXmlAutorizado := XML_UTF8
   ::cXmlAutorizado += [<procEventoNFe versao="] + cVersaoEvento + [" ] + WS_XMLNS_NFE + [>]
   ::cXmlAutorizado +=    cXmlAssinado
   ::cXmlAutorizado += [<retEvento versao="] + cVersaoEvento + [">]
   ::cXmlAutorizado +=    XmlNode( cXmlProtocolo, "retEvento" ) // hb_UTF8ToStr()
   ::cXmlAutorizado += [</retEvento>] // runner
   ::cXmlAutorizado += [</procEventoNFe>]
   ::cMotivo := XmlNode( XmlNode( cXmlProtocolo, "infEvento" ), "xMotivo" ) // hb_UTF8ToStr()

   RETURN NIL

METHOD Setup( cUF, cCertificado, cAmbiente ) CLASS SefazClass

   DO CASE
   CASE cUF == NIL
   CASE Len( SoNumeros( cUF ) ) != 0
      ::cUF := ::UFSigla( Left( cUF, 2 ) )
   OTHERWISE
      ::cUF := cUF
   ENDCASE
   ::cCertificado := iif( cCertificado == NIL, ::cCertificado, cCertificado )
   ::cAmbiente    := iif( cAmbiente == NIL, ::cAmbiente, cAmbiente )

   ::SetSoapURL()

   RETURN NIL

METHOD SetSoapURL() CLASS SefazClass

   LOCAL cAmbiente, cUF, cProjeto, cNFCe, cScan, cVersao

   ::cSoapURL := ""
   cAmbiente  := ::cAmbiente
   cUF        := ::cUF
   cProjeto   := ::cProjeto
   cNFCE      := ::cNFCE
   cScan      := ::cScan
   cVersao    := ::cVersao + iif( cAmbiente == WS_AMBIENTE_PRODUCAO, "P", "H" )
   DO CASE
   CASE cProjeto == WS_PROJETO_BPE
      ::cSoapUrl := SoapUrlBpe( ::aSoapUrlList, cUF, cVersao )
   CASE cProjeto == WS_PROJETO_CTE
      IF cScan == "SVCAN"
         IF cUF $ "MG,PR,RS," + "AC,AL,AM,BA,CE,DF,ES,GO,MA,PA,PB,PI,RJ,RN,RO,RS,SC,SE,TO"
            ::cSoapURL := SoapURLCTe( ::aSoapUrlList, "SVSP", cVersao ) // SVC_SP n�o existe
         ELSEIF cUF $ "MS,MT,SP," + "AP,PE,RR"
            ::cSoapURL := SoapUrlCTe( ::aSoapUrlList, "SVRS", cVersao ) // SVC_RS n�o existe
         ENDIF
      ELSE
         ::cSoapUrl := SoapUrlCTe( ::aSoapUrlList, cUF, cVersao )
      ENDIF
   CASE cProjeto == WS_PROJETO_MDFE
      ::cSoapURL := SoapURLMDFe( ::aSoapUrlList, "SVRS", cVersao )
   CASE cProjeto == WS_PROJETO_NFE
      DO CASE
      CASE cNFCe == "S"
         ::cSoapUrl := SoapUrlNFCe( ::aSoapUrlList, cUF, cVersao )
         IF Empty( ::cSoapUrl )
            ::cSoapUrl := SoapUrlNfe( ::aSoapUrlList, cUF, cVersao )
         ENDIF
      CASE cScan == "SCAN"
         ::cSoapURL := SoapUrlNFe( ::aSoapUrlList, "SCAN", cVersao )
      CASE cScan == "SVAN"
         ::cSoapUrl := SoapUrlNFe( ::aSoapUrlList, "SVAN", cVersao )
      CASE cScan == "SVCAN"
         IF cUF $ "AM,BA,CE,GO,MA,MS,MT,PA,PE,PI,PR"
            ::cSoapURL := SoapURLNfe( ::aSoapUrlList, "SVRS", cVersao ) // svc-rs n�o existe
         ELSE
            ::cSoapURL := SoapUrlNFe( ::aSoapUrlList, "SVAN", cVersao ) // svc-an n�o existe
         ENDIF
      OTHERWISE
         ::cSoapUrl := SoapUrlNfe( ::aSoapUrlList, cUF, cVersao )
      ENDCASE
   ENDCASE

   RETURN NIL

METHOD XmlSoapPost() CLASS SefazClass

   DO CASE
   CASE Empty( ::cSoapURL )
      ::cXmlRetorno := [<erro text="*ERRO* XmlSoapPost(): N�o h� endere�o de webservice" />]
      RETURN NIL
   CASE Empty( ::cSoapService )
      ::cXmlRetorno := [<erro text="*ERRO* XmlSoapPost(): N�o h� nome do servi�o" />]
      RETURN NIL
   CASE Empty( ::cSoapAction )
      ::cXmlRetorno := [<erro text="*ERRO* XmlSoapPost(): N�o h� endere�o de SOAP Action" />]
      RETURN NIL
   ENDCASE
   ::XmlSoapEnvelope()
   ::MicrosoftXmlSoapPost()
   IF "*ERRO*" $ Upper( ::cXmlRetorno )
      RETURN NIL
   ENDIF

   RETURN NIL

METHOD XmlSoapEnvelope() CLASS SefazClass

   LOCAL cXmlns := ;
      [xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ] + ;
      [xmlns:xsd="http://www.w3.org/2001/XMLSchema" ] + ;
      [xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"]
   LOCAL cSoapVersion

   cSoapVersion := ::cVersao
   IF "CadConsultaCadastro" $ ::cSoapAction
      cSoapVersion := "2.00"
   ENDIF
   ::cXmlSoap    := XML_UTF8
   ::cXmlSoap    += [<soap12:Envelope ] + cXmlns + [>]
   IF ::cSoapAction != "nfeDistDFeInteresse"
      ::cXmlSoap +=    [<soap12:Header>]
      ::cXmlSoap +=       [<] + ::cProjeto + [CabecMsg xmlns="] + ::cSoapService + [">]
      ::cXmlSoap +=          [<cUF>] + ::UFCodigo( ::cUF ) + [</cUF>]
      ::cXmlSoap +=          [<versaoDados>] + cSoapVersion + [</versaoDados>]
      ::cXmlSoap +=       [</] + ::cProjeto + [CabecMsg>]
      ::cXmlSoap +=    [</soap12:Header>]
   ENDIF
   ::cXmlSoap    +=    [<soap12:Body>]
   IF ::cSoapAction == "nfeDistDFeInteresse"
      ::cXmlSoap += [<nfeDistDFeInteresse xmlns="] + ::cSoapService + [">]
      ::cXmlSoap +=       [<] + ::cProjeto + [DadosMsg>]
   ELSE
      ::cXmlSoap +=       [<] + ::cProjeto + [DadosMsg xmlns="] + ::cSoapService + [">]
   ENDIF
   ::cXmlSoap    += ::cXmlEnvio
   ::cXmlSoap    +=    [</] + ::cProjeto + [DadosMsg>]
   IF ::cSoapAction == "nfeDistDFeInteresse"
      ::cXmlSoap += [</nfeDistDFeInteresse>]
   ENDIF
   ::cXmlSoap    +=    [</soap12:Body>]
   ::cXmlSoap    += [</soap12:Envelope>]

   RETURN NIL

METHOD MicrosoftXmlSoapPost() CLASS SefazClass

   LOCAL oServer, nCont, cRetorno
   LOCAL cSoapAction

   //IF ::cSoapAction == "nfeDistDFeInteresse" .OR. ::cSoapAction == "nfeConsultaNFDest"
   //cSoapAction := ::cSoapService + "/" + ::cSoapAction
   //ELSE
   cSoapAction := ::cSoapAction
   //ENDIF
   BEGIN SEQUENCE WITH __BreakBlock()
      ::cXmlRetorno := [<erro text="*ERRO* Erro: Criando objeto MSXML2.ServerXMLHTTP" />]
#ifdef __XHARBOUR__
      //IF ::cUF == "GO" .AND. ::cAmbiente == "2"
      ::cXmlRetorno := [<erro text="*ERRO* Erro: Criando objeto MSXML2.ServerXMLHTTP.5.0" /?]
      oServer := win_OleCreateObject( "MSXML2.ServerXMLHTTP.5.0" )
      //ELSE
      //   ::cXmlRetorno := "Erro: Criando objeto MSXML2.ServerXMLHTTP.6.0"
      //   oServer := win_OleCreateObject( "MSXML2.ServerXMLHTTP.6.0" )
      //ENDIF
#else
      oServer := win_OleCreateObject( "MSXML2.ServerXMLHTTP" )
#endif
      ::cXmlRetorno := [erro text="*ERRO* Erro: No uso do objeto MSXML2.ServerXmlHTTP" />]
      IF ::cCertificado != NIL
         oServer:setOption( 3, "CURRENT_USER\MY\" + ::cCertificado )
      ENDIF
      ::cXmlRetorno := [erro text="*ERRO* Erro: Na conex�o com webservice ] + ::cSoapURL + [" />]
      oServer:Open( "POST", ::cSoapURL, .F. )
      IF cSoapAction != NIL .AND. ! Empty( cSoapAction )
         oServer:SetRequestHeader( "SOAPAction", cSoapAction )
      ENDIF
      oServer:SetRequestHeader( "Content-Type", "application/soap+xml; charset=utf-8" )
      oServer:Send( ::cXmlSoap )
      oServer:WaitForResponse( 500 )
      cRetorno := oServer:ResponseBody()
      IF ValType( cRetorno ) == "C"
         ::cXmlRetorno := cRetorno
      ELSEIF cRetorno == NIL
         ::cXmlRetorno := "Sem retorno do webservice"
      ELSE
         ::cXmlRetorno := ""
         FOR nCont = 1 TO Len( cRetorno )
            ::cXmlRetorno += Chr( cRetorno[ nCont ] )
         NEXT
      ENDIF
   END SEQUENCE
   IF "<soap:Body>" $ ::cXmlRetorno .AND. "</soap:Body>" $ ::cXmlRetorno
      ::cXmlRetorno := XmlNode( ::cXmlRetorno, "soap:Body" ) // hb_UTF8ToStr()
   ELSEIF "<soapenv:Body>" $ ::cXmlRetorno .AND. "</soapenv:Body>" $ ::cXmlRetorno
      ::cXmlRetorno := XmlNode( ::cXmlRetorno, "soapenv:Body" ) // hb_UTF8ToStr()
   ELSE
      // teste usando procname(2)
      ::cXmlRetorno := [<erro text="*ERRO* Erro SOAP: ] + ProcName(2) + [ XML retorno n�o cont�m soapenv:Body" />] + ::cXmlRetorno
   ENDIF

   RETURN NIL

METHOD CTeAddCancelamento( cXmlAssinado, cXmlCancelamento ) CLASS SefazClass

   LOCAL cDigVal, cXmlAutorizado

   cDigVal := XmlNode( cXmlAssinado , "Signature" )
   cDigVal := XmlNode( cDigVal , "SignedInfo" )
   cDigVal := XmlNode( cDigVal , "Reference" )
   cDigVal := XmlNode( cDigVal , "DigestValue" )

   cXmlAutorizado := XML_UTF8
   cXmlAutorizado += [<cteProc versao="] + ::cVersao + [" ] + WS_XMLNS_CTE + [>]
   cXmlAutorizado +=    cXmlAssinado
   cXmlAutorizado +=    [<protCTe versao="] + ::cVersao + [">]
   cXmlAutorizado +=       [<infProt>]
   cXmlAutorizado +=          XmlTag( "tpAmb" , XmlNode( XmlNode( XmlNode( cXmlCancelamento, "retEventoCTe" ) , "infEvento" ), "tpAmb" ) ) // runner
   cXmlAutorizado +=          XmlTag( "verAplic", XmlNode( XmlNode( XmlNode( cXmlCancelamento, "retEventoCTe" ) , "infEvento" ), "verAplic" ) )
   cXmlAutorizado +=          XmlTag( "chCTe" , XmlNode( XmlNode( XmlNode( cXmlCancelamento, "retEventoCTe" ) , "infEvento" ), "chCTe" ) ) // runner
   cXmlAutorizado +=          XmlTag( "dhRecbto" , XmlNode( XmlNode( XmlNode( cXmlCancelamento, "retEventoCTe" ) , "infEvento" ), "dhRegEvento" ) ) // runner
   cXmlAutorizado +=          XmlTag( "nProt" , XmlNode( XmlNode( XmlNode( cXmlCancelamento, "retEventoCTe" ) , "infEvento" ), "nProt" ) ) // runner
   cXmlAutorizado +=          XmlTag( "digVal", cDigVal)
   cXmlAutorizado +=          XmlTag( "cStat", XmlNode( XmlNode( XmlNode( cXmlCancelamento, "retEventoCTe" ) , "infEvento" ), "cStat" ) )
   cXmlAutorizado +=          XmlTag( "xMotivo", 'Cancelamento do CTe homologado')
   cXmlAutorizado +=       [</infProt>]
   cXmlAutorizado +=    [</protNFe>]
   cXmlAutorizado += [</cteProc>]

   RETURN cXmlAutorizado

METHOD NFeAddCancelamento( cXmlAssinado, cXmlCancelamento ) CLASS SefazClass

   LOCAL cDigVal, cXmlAutorizado

   cDigVal := XmlNode( cXmlAssinado , "Signature" )
   cDigVal := XmlNode( cDigVal , "SignedInfo" )
   cDigVal := XmlNode( cDigVal , "Reference" )
   cDigVal := XmlNode( cDigVal , "DigestValue" )

   cXmlAutorizado := XML_UTF8
   cXmlAutorizado += [<nfeProc versao="] + ::cVersao + [" ] + WS_XMLNS_NFE + [>]
   cXmlAutorizado +=    cXmlAssinado
   cXmlAutorizado +=    [<protNFe versao="] = ::cVersao + [">]
   cXmlAutorizado +=       [<infProt>]
   cXmlAutorizado +=          XmlTag( "tpAmb" , XmlNode( XmlNode( XmlNode( cXmlCancelamento, "retEvento" ) , "infEvento" ), "tpAmb" ) ) // runner
   cXmlAutorizado +=          XmlTag( "verAplic", 'SP_NFE_PL_008i2')
   cXmlAutorizado +=          XmlTag( "chNFe" , XmlNode( XmlNode( XmlNode( cXmlCancelamento, "retEvento" ) , "infEvento" ), "chNFe" ) ) // runner
   cXmlAutorizado +=          XmlTag( "dhRecbto" , XmlNode( XmlNode( XmlNode( cXmlCancelamento, "retEvento" ) , "infEvento" ), "dhRegEvento" ) ) // runner
   cXmlAutorizado +=          XmlTag( "nProt" , XmlNode( XmlNode( XmlNode( cXmlCancelamento, "retEvento" ) , "infEvento" ), "nProt" ) ) // runner
   cXmlAutorizado +=          XmlTag( "digVal", cDigVal)
   cXmlAutorizado +=          XmlTag( "cStat", '101')
   cXmlAutorizado +=          XmlTag( "xMotivo", 'Cancelamento da NFe homologado')
   cXmlAutorizado +=       [</infProt>]
   cXmlAutorizado +=    [</protNFe>]
   cXmlAutorizado += [</nfeProc>]

   RETURN cXmlAutorizado

STATIC FUNCTION UFCodigo( cSigla )

   LOCAL cUFs, cCodigo, nPosicao

   IF Val( cSigla ) > 0
      RETURN cSigla
   ENDIF
   cUFs := "AC,12,AL,27,AM,13,AP,16,BA,29,CE,23,DF,53,ES,32,GO,52,MG,31,MS,50,MT,51,MA,21,PA,15,PB,25,PE,26,PI,22,PR,41,RJ,33,RO,11,RN,24,RR,14,RS,43,SC,42,SE,28,SP,35,TO,17,"
   nPosicao := At( cSigla, cUfs )
   IF nPosicao < 1
      cCodigo := "99"
   ELSE
      cCodigo := Substr( cUFs, nPosicao + 3, 2 )
   ENDIF

   RETURN cCodigo

STATIC FUNCTION UFSigla( cCodigo )

   LOCAL cUFs, cSigla, nPosicao

   cCodigo := Left( cCodigo, 2 ) // pode ser chave NFE
   IF Val( cCodigo ) == 0 // n�o � n�mero
      RETURN cCodigo
   ENDIF
   cUFs := "AC,12,AL,27,AM,13,AP,16,BA,29,CE,23,DF,53,ES,32,GO,52,MG,31,MS,50,MT,51,MA,21,PA,15,PB,25,PE,26,PI,22,PR,41,RJ,33,RO,11,RN,24,RR,14,RS,43,SC,42,SE,28,SP,35,TO,17,"
   nPosicao := At( cCodigo, cUfs )
   IF nPosicao < 1
      cSigla := "XX"
   ELSE
      cSigla := Substr( cUFs, nPosicao - 3, 2 )
   ENDIF

   RETURN cSigla

STATIC FUNCTION TipoXml( cXml )

   LOCAL aTipos, cTipoXml, cTipoEvento, oElemento

   aTipos := { ;
      { [<infMDFe],   [MDFE] }, ;  // primeiro, pois tem nfe e cte
      { [<cancMDFe],  [MDFEC] }, ;
      { [<infCte],    [CTE]  }, ;  // segundo, pois tem nfe
      { [<cancCTe],   [CTEC] }, ;
      { [<infNFe],    [NFE]  }, ;
      { [<infCanc],   [NFEC] }, ;
      { [<infInut],   [INUT] }, ;
      { [<infEvento], [EVEN] } }

   cTipoXml := "XX"
   FOR EACH oElemento IN aTipos
      IF Upper( oElemento[ 1 ] ) $ Upper( cXml )
         cTipoXml := oElemento[ 2 ]
         IF cTipoXml == "EVEN"
            cTipoEvento := XmlTag( cXml, "tpEvento" )
            DO CASE
            CASE cTipoEvento == "110111"
               IF "<chNFe" $ cXml
                  cTipoXml := "NFEC"
               ENDIF
            CASE cTipoEvento == "110110"
               cTipoXml := "CCE"
            OTHERWISE
               cTipoXml := "OUTROEVENTO"
            ENDCASE
         ENDIF
         EXIT
      ENDIF
   NEXT

   RETURN cTipoXml

STATIC FUNCTION DomDocValidaXml( cXml, cFileXsd )

   LOCAL oXmlDomDoc, oXmlSchema, oXmlErro, cRetorno := "ERRO"

   hb_Default( @cFileXsd, "" )

   IF " <" $ cXml .OR. "> " $ cXml
      RETURN "Espa�os inv�lidos no XML entre as tags"
   ENDIF

   IF Empty( cFileXsd )
      RETURN "OK"
   ENDIF
   IF ! File( cFileXSD )
      RETURN "Erro n�o encontrado arquivo " + cFileXSD
   ENDIF

   BEGIN SEQUENCE WITH __BreakBlock()

      cRetorno   := "Erro Carregando MSXML2.DomDocument.6.0"
      oXmlDomDoc := win_OleCreateObject( "MSXML2.DomDocument.6.0" )
      oXmlDomDoc:aSync            := .F.
      oXmlDomDoc:ResolveExternals := .F.
      oXmlDomDoc:ValidateOnParse  := .T.

      cRetorno   := "Erro Carregando XML"
      oXmlDomDoc:LoadXml( cXml )
      IF oXmlDomDoc:ParseError:ErrorCode <> 0
         cRetorno := "Erro XML inv�lido " + ;
            " Linha: "   + AllTrim( Transform( oXmlDomDoc:ParseError:Line, "" ) ) + ;
            " coluna: "  + AllTrim( Transform( oXmlDomDoc:ParseError:LinePos, "" ) ) + ;
            " motivo: "  + AllTrim( Transform( oXmlDomDoc:ParseError:Reason, "" ) ) + ;
            " errcode: " + AllTrim( Transform( oXmlDomDoc:ParseError:ErrorCode, "" ) )
         BREAK
      ENDIF

      cRetorno   := "Erro Carregando MSXML2.XMLSchemaCache.6.0"
      oXmlSchema := win_OleCreateObject( "MSXML2.XMLSchemaCache.6.0" )

      cRetorno   := "Erro carregando " + cFileXSD
      DO CASE
      CASE "mdfe" $ Lower( cFileXsd )
         oXmlSchema:Add( "http://www.portalfiscal.inf.br/mdfe", cFileXSD )
      CASE "cte"  $ Lower( cFileXsd )
         oXmlSchema:Add( "http://www.portalfiscal.inf.br/cte", cFileXSD )
      CASE "nfe"  $ Lower( cFileXsd )
         oXmlSchema:Add( "http://www.portalfiscal.inf.br/nfe", cFileXSD )
      ENDCASE

      oXmlDomDoc:Schemas := oXmlSchema
      oXmlErro := oXmlDomDoc:Validate()
      IF oXmlErro:ErrorCode <> 0
         cRetorno := "Erro: " + AllTrim( Transform( oXmlErro:ErrorCode, "" ) ) + " " + ConverteErroValidacao( oXmlErro:Reason, "" )
         BREAK
      ENDIF
      cRetorno := "OK"

   END SEQUENCE

   RETURN cRetorno

STATIC FUNCTION ConverteErroValidacao( cTexto )

   LOCAL nPosIni, nPosFim

   cTexto := AllTrim( Transform( cTexto, "" ) )
   DO WHILE .T.
      IF ! "{" $ cTexto .OR. ! "}" $ cTexto
         EXIT
      ENDIF
      nPosIni := At( "{", cTexto ) - 1
      nPosFim := At( "}", cTexto ) + 1
      IF nPosIni > nPosFim
         EXIT
      ENDIF
      cTexto := Substr( cTexto, 1, nPosIni ) + Substr( cTexto, nPosFim )
   ENDDO

   RETURN cTexto

#ifdef LIBCURL // pra nao compilar, apenas anotado
   // Pode ser usada a LibCurl pra comunica��o

METHOD CurlSoapPost() CLASS SefazClass

   LOCAL aHeader := Array(3)

   aHeader[ 1 ] := [Content-Type: application/soap+xml;charset=utf-8;action="] + ::cSoapService + ["]
   aHeader[ 2 ] := [SOAPAction: "] + ::cSoapAction + ["]
   aHeader[ 3 ] := [Content-length: ] + AllTrim( Str( Len( ::cXml ) ) )
   curl_global_init()
   oCurl := curl_easy_init()
   curl_easy_setopt( oCurl, HB_CURLOPT_URL, ::cSoapURL )
   curl_easy_setopt( oCurl, HB_CURLOPT_PORT , 443 )
   curl_easy_setopt( oCurl, HB_CURLOPT_VERBOSE, .F. ) // 1
   curl_easy_setopt( oCurl, HB_CURLOPT_HEADER, 1 ) //retorna o cabecalho de resposta
   curl_easy_setopt( oCurl, HB_CURLOPT_SSLVERSION, 3 ) // Algumas UFs come�aram a usar vers�o 4
   curl_easy_setopt( oCurl, HB_CURLOPT_SSL_VERIFYHOST, 0 )
   curl_easy_setopt( oCurl, HB_CURLOPT_SSL_VERIFYPEER, 0 )
   curl_easy_setopt( oCurl, HB_CURLOPT_SSLCERT, ::cCertificadoPublicKeyFile ) // Falta na classe
   curl_easy_setopt( oCurl, HB_CURLOPT_KEYPASSWD, ::cCertificadoPassword )    // Falta na classe
   curl_easy_setopt( oCurl, HB_CURLOPT_SSLKEY, ::cCertificadoPrivateKeyFile ) // Falta na classe
   curl_easy_setopt( oCurl, HB_CURLOPT_POST, 1 )
   curl_easy_setopt( oCurl, HB_CURLOPT_POSTFIELDS, ::cXml )
   curl_easy_setopt( oCurl, HB_CURLOPT_WRITEFUNCTION, 1 )
   curl_easy_setopt( oCurl, HB_CURLOPT_DL_BUFF_SETUP )
   curl_easy_setopt( oCurl, HB_CURLOPT_HTTPHEADER, aHeader )
   curl_easy_perform( oCurl )
   retHTTP := curl_easy_getinfo( oCurl, HB_CURLINFO_RESPONSE_CODE )
   ::cXmlRetorno := ""
   IF retHTTP == 200 // OK
      curl_easy_setopt( ocurl, HB_CURLOPT_DL_BUFF_GET, @::cXmlRetorno )
      cXMLResp := Substr( cXMLResp, AT( '<?xml', ::cXmlRetorno ) )
   ENDIF
   curl_easy_cleanup( oCurl )
   curl_global_cleanup()

   RETURN NIL
#endif

STATIC FUNCTION SoapUrlBpe( aSoapList, cUF, cVersao )

   LOCAL nPos, cUrl

   nPos := AScan( aSoapList, { | e | cUF == e[ 1 ] .AND. cVersao == e[ 2 ] } )
   IF nPos != 0
      cUrl := aSoapList[ nPos, 3 ]
   ENDIF

   RETURN cUrl

STATIC FUNCTION SoapUrlNfe( aSoapList, cUF, cVersao )

   LOCAL nPos, cUrl

   nPos := AScan( aSoapList, { | e | cUF == e[ 1 ] .AND. cVersao == e[ 2 ] } )
   IF nPos != 0
      cUrl := aSoapList[ nPos, 3 ]
   ENDIF
   DO CASE
   CASE ! Empty( cUrl )
   CASE cUf $ "AC,AL,AP,DF,ES,PB,RJ,RN,RO,RR,SC,SE,TO"
      cURL := SoapURLNFe( aSoapList, "SVRS", cVersao )
   CASE cUf $ "MA,PA,PI"
      cURL := SoapUrlNFe( aSoapList, "SVAN", cVersao )
   ENDCASE

   RETURN cUrl

STATIC FUNCTION SoapUrlCte( aSoapList, cUF, cVersao )

   LOCAL nPos, cUrl

   nPos := AScan( aSoapList, { | e | cUF == e[ 1 ] .AND. cVersao == e[ 2 ] } )
   IF nPos != 0
      cUrl := aSoapList[ nPos, 3 ]
   ENDIF
   IF Empty( cUrl )
      IF cUF $ "AP,PE,RR"
         cUrl := SoapUrlCTe( aSoapList, "SVSP", cVersao )
      ELSEIF cUF $ "AC,AL,AM,BA,CE,DF,ES,GO,MA,PA,PB,PI,RJ,RN,RO,RS,SC,SE,TO"
         cUrl := SoapUrlCTe( aSoapList, "SVRS", cVersao )
      ENDIF
   ENDIF

   RETURN cUrl

STATIC FUNCTION SoapUrlMdfe( aSoapList, cUF, cVersao )

   LOCAL cUrl, nPos

   nPos := AScan( aSoapList, { | e | cVersao == e[ 2 ] } )
   IF nPos != 0
      cUrl := aSoapList[ nPos, 3 ]
   ENDIF
   HB_SYMBOL_UNUSED( cUF )

   RETURN cUrl

STATIC FUNCTION SoapUrlNFCe( aSoapList, cUf, cVersao )

   LOCAL cUrl, nPos

   IF cUF $ "AC,RR"
      cUrl := SoapUrlNFCe( aSoapList, "SVRS", cVersao  )
   ELSE
      nPos := AScan( aSoapList, { | e | cUF == e[ 1 ] .AND. cVersao + "C" == e[ 2 ] } )
      IF nPos != 0
         cUrl := aSoapList[ nPos, 3 ]
      ENDIF
   ENDIF
   IF Empty( cUrl )
      cUrl := SoapUrlNFe( aSoapList, cUF, cVersao )
   ENDIF

   RETURN cUrl

STATIC FUNCTION GeraQRCode( cXmlAssinado, cIdToken, cCSC, cVersao )

   LOCAL QRCODE_cTag, QRCODE_Url, QRCODE_chNFe, QRCODE_nVersao, QRCODE_tpAmb
   LOCAL QRCODE_cDest, QRCODE_dhEmi, QRCODE_vNF, QRCODE_vICMS, QRCODE_digVal
   LOCAL QRCODE_cIdToken, QRCODE_cCSC, QRCODE_cHash
   LOCAL cInfNFe, cSignature, cAmbiente, cUF, nPos
   LOCAL aUrlList

   hb_Default( @cIdToken, StrZero( 0, 6 ) )
   hb_Default( @cCsc, StrZero( 0, 36 ) )

   IF cVersao == "3.10"
      aUrlList := { ;
         { "AC", "3.10", WS_AMBIENTE_PRODUCAO,    "http://www.sefaznet.ac.gov.br/nfce/qrcode?" }, ;
         { "AL", "3.10", WS_AMBIENTE_PRODUCAO,    "http://nfce.sefaz.al.gov.br/QRCode/consultarNFCe.jsp?" }, ;
         { "AP", "3.10", WS_AMBIENTE_PRODUCAO,    "https://www.sefaz.ap.gov.br/nfce/nfcep.php?" }, ;
         { "AM", "3.10", WS_AMBIENTE_PRODUCAO,    "http://sistemas.sefaz.am.gov.br/nfceweb/consultarNFCe.jsp?" }, ;
         { "BA", "3.10", WS_AMBIENTE_PRODUCAO,    "http://nfe.sefaz.ba.gov.br/servicos/nfce/modulos/geral/NFCEC_consulta_chave_acesso.aspx" }, ;
         { "CE", "3.10", WS_AMBIENTE_PRODUCAO,    "http://nfce.sefaz.ce.gov.br/pages/ShowNFCe.html" }, ;
         { "DF", "3.10", WS_AMBIENTE_PRODUCAO,    "http://dec.fazenda.df.gov.br/ConsultarNFCe.aspx" }, ;
         { "ES", "3.10", WS_AMBIENTE_PRODUCAO,    "http://app.sefaz.es.gov.br/ConsultaNFCe/qrcode.aspx?" }, ;
         { "GO", "3.10", WS_AMBIENTE_PRODUCAO,    "http://nfe.sefaz.go.gov.br/nfeweb/sites/nfce/danfeNFCe" }, ;
         { "MA", "3.10", WS_AMBIENTE_PRODUCAO,    "http://www.nfce.sefaz.ma.gov.br/portal/consultarNFCe.jsp?" }, ;
         { "MT", "3.10", WS_AMBIENTE_PRODUCAO,    "http://www.sefaz.mt.gov.br/nfce/consultanfce?" }, ;
         { "MS", "3.10", WS_AMBIENTE_PRODUCAO,    "http://www.dfe.ms.gov.br/nfce/qrcode?" }, ;
         { "MG", "3.10", WS_AMBIENTE_PRODUCAO,    "" }, ;
         { "PA", "3.10", WS_AMBIENTE_PRODUCAO,    "https://appnfc.sefa.pa.gov.br/portal/view/consultas/nfce/nfceForm.seam?" }, ;
         { "PB", "3.10", WS_AMBIENTE_PRODUCAO,    "http://www.receita.pb.gov.br/nfce?" }, ;
         { "PR", "3.10", WS_AMBIENTE_PRODUCAO,    "http://www.dfeportal.fazenda.pr.gov.br/dfe-portal/rest/servico/consultaNFCe?" }, ;
         { "PE", "3.10", WS_AMBIENTE_PRODUCAO,    "http://nfce.sefaz.pe.gov.br/nfce-web/consultarNFCe?" }, ;
         { "PI", "3.10", WS_AMBIENTE_PRODUCAO,    "http://webas.sefaz.pi.gov.br/nfceweb/consultarNFCe.jsf?" }, ;
         { "RJ", "3.10", WS_AMBIENTE_PRODUCAO,    "http://www4.fazenda.rj.gov.br/consultaNFCe/QRCode?" }, ;
         { "RN", "3.10", WS_AMBIENTE_PRODUCAO,    "http://nfce.set.rn.gov.br/consultarNFCe.aspx?" }, ;
         { "RS", "3.10", WS_AMBIENTE_PRODUCAO,    "https://www.sefaz.rs.gov.br/NFCE/NFCE-COM.aspx?" }, ;
         { "RO", "3.10", WS_AMBIENTE_PRODUCAO,    "http://www.nfce.sefin.ro.gov.br/consultanfce/consulta.jsp?" }, ;
         { "RR", "3.10", WS_AMBIENTE_PRODUCAO,    "https://www.sefaz.rr.gov.br/nfce/servlet/qrcode?" }, ;
         { "SC", "3.10", WS_AMBIENTE_PRODUCAO,    "" }, ;
         { "SP", "3.10", WS_AMBIENTE_PRODUCAO,    "https://www.nfce.fazenda.sp.gov.br/NFCeConsultaPublica/Paginas/ConsultaQRCode.aspx?" }, ;
         { "SE", "3.10", WS_AMBIENTE_PRODUCAO,    "http://www.nfce.se.gov.br/portal/consultarNFCe.jsp?" }, ;
         { "TO", "3.10", WS_AMBIENTE_PRODUCAO,    "" }, ;
         ;
         { "AC", "3.10", WS_AMBIENTE_HOMOLOGACAO, "http://www.hml.sefaznet.ac.gov.br/nfce/qrcode?" }, ;
         { "AL", "3.10", WS_AMBIENTE_HOMOLOGACAO, "http://nfce.sefaz.al.gov.br/QRCode/consultarNFCe.jsp?" }, ;
         { "AP", "3.10", WS_AMBIENTE_HOMOLOGACAO, "https://www.sefaz.ap.gov.br/nfcehml/nfce.php?" }, ;
         { "AM", "3.10", WS_AMBIENTE_HOMOLOGACAO, "http://homnfce.sefaz.am.gov.br/nfceweb/consultarNFCe.jsp?" }, ;
         { "BA", "3.10", WS_AMBIENTE_HOMOLOGACAO, "http://hnfe.sefaz.ba.gov.br/servicos/nfce/modulos/geral/NFCEC_consulta_chave_acesso.aspx" }, ;
         { "CE", "3.10", WS_AMBIENTE_HOMOLOGACAO, "http://nfceh.sefaz.ce.gov.br/pages/ShowNFCe.html" }, ;
         { "DF", "3.10", WS_AMBIENTE_HOMOLOGACAO, "http://dec.fazenda.df.gov.br/ConsultarNFCe.aspx" }, ;
         { "ES", "3.10", WS_AMBIENTE_HOMOLOGACAO, "http://homologacao.sefaz.es.gov.br/ConsultaNFCe/qrcode.aspx?" }, ;
         { "GO", "3.10", WS_AMBIENTE_HOMOLOGACAO, "" }, ;
         { "MA", "3.10", WS_AMBIENTE_HOMOLOGACAO, "http://www.hom.nfce.sefaz.ma.gov.br/portal/consultarNFCe.jsp?" }, ;
         { "MT", "3.10", WS_AMBIENTE_HOMOLOGACAO, "http://homologacao.sefaz.mt.gov.br/nfce/consultanfce?" }, ;
         { "MS", "3.10", WS_AMBIENTE_HOMOLOGACAO, "http://www.dfe.ms.gov.br/nfce/qrcode?" }, ;
         { "MG", "3.10", WS_AMBIENTE_HOMOLOGACAO, "" }, ;
         { "PA", "3.10", WS_AMBIENTE_HOMOLOGACAO, "https://appnfc.sefa.pa.gov.br/portal-homologacao/view/consultas/nfce/nfceForm.seam" }, ;
         { "PB", "3.10", WS_AMBIENTE_HOMOLOGACAO, "http://www.receita.pb.gov.br/nfcehom" }, ;
         { "PR", "3.10", WS_AMBIENTE_HOMOLOGACAO, "http://www.dfeportal.fazenda.pr.gov.br/dfe-portal/rest/servico/consultaNFCe?" }, ;
         { "PE", "3.10", WS_AMBIENTE_HOMOLOGACAO, "http://nfcehomolog.sefaz.pe.gov.br/nfce-web/consultarNFCe?" }, ;
         { "PI", "3.10", WS_AMBIENTE_HOMOLOGACAO, "http://webas.sefaz.pi.gov.br/nfceweb-homologacao/consultarNFCe.jsf?" }, ;
         { "RJ", "3.10", WS_AMBIENTE_HOMOLOGACAO, "http://www4.fazenda.rj.gov.br/consultaNFCe/QRCode?" }, ;
         { "RN", "3.10", WS_AMBIENTE_HOMOLOGACAO, "http://hom.nfce.set.rn.gov.br/consultarNFCe.aspx?" }, ;
         { "RS", "3.10", WS_AMBIENTE_HOMOLOGACAO, "https://www.sefaz.rs.gov.br/NFCE/NFCE-COM.aspx?" }, ;
         { "RO", "3.10", WS_AMBIENTE_HOMOLOGACAO, "http://www.nfce.sefin.ro.gov.br/consultanfce/consulta.jsp?" }, ;
         { "RR", "3.10", WS_AMBIENTE_HOMOLOGACAO, "http://200.174.88.103:8080/nfce/servlet/qrcode?" }, ;
         { "SC", "3.10", WS_AMBIENTE_HOMOLOGACAO, "" }, ;
         { "SP", "3.10", WS_AMBIENTE_HOMOLOGACAO, "https://www.homologacao.nfce.fazenda.sp.gov.br/NFCeConsultaPublica/Paginas/ConsultaQRCode.aspx" }, ;
         { "SE", "3.10", WS_AMBIENTE_HOMOLOGACAO, "http://www.hom.nfe.se.gov.br/portal/consultarNFCe.jsp?" }, ;
         { "TO", "3.10", WS_AMBIENTE_HOMOLOGACAO, "" } }
   ELSE
      aUrlList := {}
   ENDIF

   cInfNFe    := XmlNode( cXmlAssinado, "infNFe", .T. )
   cSignature := XmlNode( cXmlAssinado, "Signature", .T. )

   cAmbiente  := XmlNode( XmlNode( cInfNFe, "ide" ), "tpAmb" )
   cUF        := UFSigla( XmlNode( XmlNode( cInfNFe, "ide" ), "cUF" ) )

   // 1� Parte ( Endereco da Consulta - Fonte: http://nfce.encat.org/desenvolvedor/qrcode/ )
   nPos       := AScan( aUrlList, { | e | e[ 1 ] == cUF .AND. e[ 3 ] == cAmbiente } )
   QRCode_Url := iif( nPos == 0, "", aUrlList[ nPos, 4 ] )

   // 2� Parte (Parametros)
   QRCODE_chNFe    := AllTrim( Substr( XmlElement( cInfNFe, "Id" ), 4 ) )
   QRCODE_nVersao  := "100"
   QRCODE_tpAmb    := cAmbiente
   QRCODE_cDest    := XmlNode( XmlNode( cInfNFe, "dest" ), "CPF" )
   IF Empty( QRCODE_cDest )
      QRCODE_cDest := XmlNode( XmlNode( cInfNFe, "dest" ), "CNPJ" )
   ENDIF
   QRCODE_dhEmi    := hb_StrToHex( XmlNode( XmlNode( cInfNFe, "ide" ), "dhEmi" ) )
   QRCODE_vNF      := XmlNode( XmlNode( XmlNode( cInfNFe, "total" ), "ICMSTot" ), "vNF" )
   QRCODE_vICMS    := XmlNode( XmlNode( XmlNode( cInfNFe, "total" ), "ICMSTot" ), "vICMS" )
   QRCODE_digVal   := hb_StrToHex( XmlNode( XmlNode( XmlNode( cSignature, "SignedInfo" ), "Reference" ), "DigestValue" ) )
   QRCODE_cIdToken := cIdToken
   QRCODE_cCSC     := cCsc

   IF ! Empty( QRCODE_chNFe ) .AND. ! Empty( QRCODE_nVersao ) .AND. ! Empty( QRCODE_tpAmb ) .AND. ! Empty( QRCODE_dhEmi ) .AND. !Empty( QRCODE_vNF ) .AND.;
         ! Empty( QRCODE_vICMS ) .AND. ! Empty( QRCODE_digVal  ) .AND. ! Empty( QRCODE_cIdToken ) .AND. ! Empty( QRCODE_cCSC  )

      QRCODE_chNFe    := "chNFe="    + QRCODE_chNFe    + "&"
      QRCODE_nVersao  := "nVersao="  + QRCODE_nVersao  + "&"
      QRCODE_tpAmb    := "tpAmb="    + QRCODE_tpAmb    + "&"
      // Na hipotese do consumidor nao se identificar na NFC-e, nao existira o parametro cDest no QR Code
      // e tambem nao devera ser incluido o parametro cDest na sequencia sobre a qual sera aplicado o hash do QR Code
      IF !Empty( QRCODE_cDest )
         QRCODE_cDest := "cDest="    + QRCODE_cDest    + "&"
      ENDIF
      QRCODE_dhEmi    := "dhEmi="    + QRCODE_dhEmi    + "&"
      QRCODE_vNF      := "vNF="      + QRCODE_vNF      + "&"
      QRCODE_vICMS    := "vICMS="    + QRCODE_vICMS    + "&"
      QRCODE_digVal   := "digVal="   + QRCODE_digVal   + "&"
      QRCODE_cIdToken := "cIdToken=" + QRCODE_cIdToken

      // 3� Parte (cHashQRCode)
      QRCODE_cHash := ( "&cHashQRCode=" +;
         hb_SHA1( QRCODE_chNFe + QRCODE_nVersao + QRCODE_tpAmb + QRCODE_cDest + QRCODE_dhEmi + QRCODE_vNF + QRCODE_vICMS + QRCODE_digVal + QRCODE_cIdToken + QRCODE_cCSC ) )

      // Resultado da URL formada a ser incluida na imagem QR Code
      QRCODE_cTag  := "<![CDATA[" + QRCODE_Url + QRCODE_chNFe + QRCODE_nVersao + QRCODE_tpAmb + QRCODE_cDest + ;
         QRCODE_dhEmi + QRCODE_vNF + QRCODE_vICMS + QRCODE_digVal + QRCODE_cIdToken + QRCODE_cHash + "]]>"
      // XML com a Tag do QRCode
      cXmlAssinado := [<NFe xmlns="http://www.portalfiscal.inf.br/nfe">]
      cXmlAssinado += cInfNFe
      cXmlAssinado += [<] + "infNFeSupl"+[>]
      cXmlAssinado += [<] + "qrCode"+[>] + QRCODE_cTag + [</] + "qrCode" + [>]
      cXmlAssinado += [</] + "infNFeSupl"+[>]
      cXmlAssinado += cSignature
      cXmlAssinado += [</NFe>]
   ELSE
      RETURN "Erro na geracao do QRCode"
   ENDIF

   RETURN "OK"
