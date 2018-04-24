REQUEST HB_CODEPAGE_PTISO

#include "inkey.ch"
#include "set.ch"
#include "hbgtinfo.ch"
#include "directry.ch"
#include "sefazclass.ch"

#ifndef WIN_SW_SHOWNORMAL
   #define WIN_SW_SHOWNORMAL 0
#endif

MEMVAR cVersao, cCertificado, cUF, cAmbiente

FUNCTION Main( cXmlDocumento, cLogoFile, cXmlAuxiliar )

   LOCAL nOpc := 1, GetList := {}, cTexto := "", nOpcTemp
   LOCAL cCnpj := Space(14), cChave := Space(44), cUF := "SP", cXmlRetorno
   LOCAL oSefaz, cXml, oDanfe, cTempFile, nHandle

   cVersao      := "3.10"
   cCertificado := ""
   cUF          := "SP"
   cAmbiente    := WS_AMBIENTE_HOMOLOGACAO

   SET DATE BRITISH
   SetupHarbour()
   SetMode( 33, 80 )
   Set( _SET_CODEPAGE, "PTISO" )
   SetColor( "W/B,N/W,,,W/B" )

   //? Extenso( Date(), .T. )
   //? Extenso( Date() )
   //? Extenso( 545454.54 )
   //? Extenso( 1000000 )
   //Inkey(0)
   IF cXmlDocumento != NIL
      IF File( cXmlDocumento )
         cXmlDocumento := MemoRead( cXmlDocumento )
      ENDIF
      IF cXmlAuxiliar != NIL
         IF File( cXmlAuxiliar )
            cXmlAuxiliar := MemoRead( cXmlAuxiliar )
         ENDIF
      ENDIF
      IF cLogoFile != NIL
         IF File( cLogoFile )
            cLogoFile := MemoRead( cLogoFile )
         ENDIF
      ENDIF
      nHandle := hb_FTempCreateEx( @cTempFile, hb_DirTemp(), "", ".PDF" )
      fClose( nHandle )
      oDanfe := hbNFeDaGeral():New()
      oDanfe:cDesenvolvedor := "Jos�Quintas"
      oDanfe:cLogoFile      := cLogoFile
      oDanfe:ToPDF( cXmlDocumento, cTempFile, cXmlAuxiliar )
      PDFOpen( cTempFile )
      RETURN NIL
   ENDIF

   DO WHILE .T.
      oSefaz              := SefazClass():New()
      oSefaz:cUF          := cUF
      oSefaz:cVersao      := cVersao
      oSefaz:cCertificado := cCertificado
      oSefaz:cAmbiente    := cAmbiente

      CLS
      @ Row() + 1, 5 PROMPT "Teste Danfe"
      @ Row() + 1, 5 PROMPT "Seleciona certificado"
      @ Row() + 1, 5 PROMPT "UF Default"
      @ Row() + 1, 5 PROMPT "Consulta Status NFE"
      @ Row() + 1, 5 PROMPT "Consulta Cadastro"
      @ Row() + 1, 5 PROMPT "Protocolo NFE"
      @ Row() + 1, 5 PROMPT "Protocolo CTE"
      @ Row() + 1, 5 PROMPT "Protocolo MDFE"
      @ Row() + 1, 5 PROMPT "Consulta Destinadas"
      @ Row() + 1, 5 PROMPT "Valida XML"
      @ Row() + 1, 5 PROMPT "Teste de assinatura"
      @ Row() + 1, 5 PROMPT "Consulta Status NFCE"
      @ Row() + 1, 5 PROMPT "Altera 3.10/4.00"
      @ Row() + 1, 5 PROMPT "Ambiente Produ��o/Homologa��o"
      @ Row() + 2, 5 SAY "Vers�o atual:" + cVersao
      @ Row() + 2, 5 SAY "Certificado atual:" + cCertificado
      @ Row() + 2, 5 SAY "Ambiente atual:" + iif( cAmbiente == WS_AMBIENTE_PRODUCAO, "Producao", "Homologacao" )
      MENU TO nOpc
      nOpcTemp := 1
      DO CASE
      CASE LastKey() == K_ESC
         EXIT

      CASE nOpc == nOpcTemp++
         TestDanfe()

      CASE nOpc == nOpcTemp++
         cCertificado := CapicomEscolheCertificado()
         wapi_MessageBox( , cCertificado )
         LOOP

      CASE nOpc == nOpcTemp++
         Scroll( 8, 0, MaxRow(), MaxCol(), 0 )
         @ 8, 0 SAY "Qual UF:" GET cUF PICTURE "@!"
         READ

      CASE nOpc == nOpcTemp++
         cXmlRetorno := oSefaz:NfeStatusServico()
         wapi_MessageBox( , oSefaz:cXmlSoap, "XML enviado" )
         wapi_MessageBox( , oSefaz:cXmlRetorno, "XML retornado" )
         cTexto := "Tipo Ambiente:"     + XmlNode( cXmlRetorno, "tpAmb" ) + hb_Eol()
         cTexto += "Vers�o Aplicativo:" + XmlNode( cXmlRetorno, "verAplic" ) + hb_Eol()
         cTexto += "Status:"            + XmlNode( cXmlRetorno, "cStat" ) + hb_Eol()
         cTexto += "Motivo:"            + XmlNode( cXmlRetorno, "xMotivo" ) + hb_Eol()
         cTexto += "UF:"                + XmlNode( cXmlRetorno, "cUF" ) + hb_Eol()
         cTexto += "Data/Hora:"         + XmlNode( cXmlRetorno, "dhRecbto" ) + hb_Eol()
         cTexto += "Tempo M�dio:"       + XmlNode( cXmlRetorno, "tMed" ) + hb_Eol()
         wapi_MessageBox( , cTexto, "Informa��o Extra�da" )

      CASE nOpc == nOpcTemp++
         Scroll( 8, 0, MaxRow(), MaxCol(), 0 )
         @ 8, 0 SAY "UF"   GET cUF PICTURE "@!"
         @ 9, 0 SAY "CNPJ" GET cCnpj PICTURE "@R 99.999.999/9999-99"
         READ
         IF LastKey() == K_ESC
            LOOP
         ENDIF
         Scroll( 8, 0, MaxRow(), MaxCol(), 0 )
         oSefaz:cProjeto := "nfe"
         cXmlRetorno := oSefaz:NfeConsultaCadastro( cCnpj, cUF )
         wapi_MessageBox( , oSefaz:cXmlSoap, "XML Enviado" )
         wapi_MessageBox( , oSefaz:cXmlRetorno, "XML Retornado" )
         cTexto := "versao:    " + XmlNode( cXmlRetorno, "versao" ) + hb_Eol()
         cTexto += "Aplicativo:" + XmlNode( cXmlRetorno, "verAplic" ) + hb_Eol()
         cTexto += "Status:    " + XmlNode( cXmlRetorno, "cStat" ) + hb_Eol()
         cTexto += "Motivo:    " + XmlNode( cXmlRetorno, "xMotivo" ) + hb_Eol()
         cTexto += "UF:        " + XmlNode( cXmlRetorno, "UF" ) + hb_Eol()
         cTexto += "IE:        " + XmlNode( cXmlRetorno, "IE" ) + hb_Eol()
         cTexto += "CNPJ:      " + XmlNode( cXmlRetorno, "CNPJ" ) + hb_Eol()
         cTexto += "CPF:       " + XmlNode( cXmlRetorno, "CPF" ) + hb_Eol()
         cTexto += "Data/Hora: " + XmlNode( cXmlRetorno, "dhCons" ) + hb_Eol()
         cTexto += "UF:        " + XmlNode( cXmlRetorno, "cUF" ) + hb_Eol()
         cTexto += "Nome(1):   " + XmlNode( cXmlRetorno, "xNome" ) + hb_Eol()
         cTexto += "CNAE(1):   " + XmlNode( cXmlRetorno, "CNAE" ) + hb_Eol()
         cTexto += "Lograd(1): " + XmlNode( cXmlRetorno, "xLgr" ) + hb_Eol()
         cTexto += "nro(1):    " + XmlNode( cXmlRetorno, "nro" ) + hb_Eol()
         cTexto += "Compl(1):  " + XmlNode( cXmlRetorno, "xCpl" ) + hb_Eol()
         cTexto += "Bairro(1): " + XmlNode( cXmlRetorno, "xBairro" ) + hb_Eol()
         cTexto += "Cod.Mun(1):" + XmlNode( cXmlRetorno, "cMun" ) + hb_Eol()
         cTexto += "Municip(1):" + XmlNode( cXmlRetorno, "xMun" ) + hb_Eol()
         cTexto += "CEP(1):    " + XmlNode( cXmlRetorno, "CEP" ) + hb_Eol()
         cTexto += "Etc pode ter v�rios endere�os..."
         wapi_MessageBox( , cTexto, "Informa��o Extra�da" )

      CASE nOpc == nOpcTemp++
         Scroll( 8, 0, MaxRow(), MaxCol(), 0 )
         @ 8, 1 GET cChave PICTURE "@R 99-99/99-99.999.999/9999-99.99.999.999999999.9.99999999.9"
         READ
         IF LastKey() == K_ESC
            EXIT
         ENDIF
         oSefaz:NfeConsultaProtocolo( cChave )
         wapi_MessageBox( , oSefaz:cXmlSoap )
         wapi_MessageBox( , oSefaz:cXmlRetorno )

      CASE nOpc == nOpcTemp++
         Scroll( 8, 0, MaxRow(), MaxCol(), 0 )
         @ 8, 1 GET cChave PICTURE "@R 99-99/99-99.999.999/9999-99.99.999.999999999.9.99999999.9"
         READ
         IF LastKey() == K_ESC
            EXIT
         ENDIF
         oSefaz:CteConsultaProtocolo( cChave, cCertificado )
         wapi_MessageBox( , oSefaz:cXmlSoap )
         wapi_MessageBox( , oSefaz:cXmlRetorno )

      CASE nOpc == nOpcTemp++
         Scroll( 8, 0, MaxRow(), MaxCol(), 0 )
         @ 8, 1 GET cChave PICTURE "@R 99-99/99-99.999.999/9999-99.99.999.999999999.9.99999999.9"
         READ
         IF LastKey() == K_ESC
            EXIT
         ENDIF
         oSefaz:MDFeConsultaProtocolo( cChave, cCertificado )
         wapi_MessageBox( , oSefaz:cXmlSoap )
         wapi_MessageBox( , oSefaz:cXmlRetorno )

      CASE nOpc == nOpcTemp++
         Scroll( 8, 0, MaxRow(), MaxCol(), 0 )
         @ 9, 1 GET cCnpj PICTURE "@9"
         READ
         IF LastKey() == K_ESC
            EXIT
         ENDIF
         oSefaz:nfeDistribuicaoDFe( cCnpj, "0" )
         wapi_MessageBox( , oSefaz:cXmlSoap )
         wapi_MessageBox( , oSefaz:cXmlRetorno )

         oSefaz:nfeConsultaDest( cCnpj, "0" )
         wapi_MessageBox( , oSefaz:cXmlSoap )
         wapi_MessageBox( , oSefaz:cXmlRetorno )

      CASE nOpc == nOpcTemp++
         cXml := MemoRead( "d:\temp\teste.xml" )
         // cXml := StrTran( cXml, "</NFe>", FakeSignature() + "</NFe>" )
         ? oSefaz:ValidaXml( cXml, "d:\cdrom\fontes\integra\schemmas\pl_008i2_cfop_externo\nfe_v3.10.xsd" )
         Inkey(0)

      CASE nOpc == nOpcTemp++
         oSefaz:cXmlDocumento := [<NFe><infNFe Id="Nfe0001"></infNFe></NFe>]
         oSefaz:AssinaXml()
         ? oSefaz:cXmlRetorno
         ? oSefaz:cXmlDocumento
         Inkey(0)

      CASE nOpc == nOpcTemp++
         wapi_MessageBox( , "NFCE" )
         oSefaz:cNFCE := "S"
         oSefaz:NfeStatusServico()
         wapi_MessageBox( , oSefaz:cXmlRetorno )

      CASE nOpc == nOpcTemp++
         cVersao := iif( cVersao == "3.10", "4.00", "3.10" )

      CASE nOpc == nOpcTemp++
         cAmbiente := iif( cAmbiente == WS_AMBIENTE_PRODUCAO, WS_AMBIENTE_HOMOLOGACAO, WS_AMBIENTE_PRODUCAO )

      CASE nOpc == nOpcTemp // pra n�o esquecer o ++, �ltimo n�o tem
      ENDCASE
   ENDDO

   RETURN NIL

FUNCTION SetupHarbour()

#ifndef __XHARBOUR__
   hb_gtInfo( HB_GTI_INKEYFILTER, { | nKey | MyInkeyFilter( nKey ) } ) // pra funcionar control-V
#endif
   SET( _SET_EVENTMASK, INKEY_ALL - INKEY_MOVE )
   SET CONFIRM ON

   RETURN NIL

#ifndef __XHARBOUR__
   // rotina do ctrl-v

FUNCTION MyInkeyFilter( nKey )

   LOCAL nBits, lIsKeyCtrl

   nBits := hb_GtInfo( HB_GTI_KBDSHIFTS )
   lIsKeyCtrl := ( nBits == hb_BitOr( nBits, HB_GTI_KBD_CTRL ) )
   SWITCH nKey
   CASE K_CTRL_V
      IF lIsKeyCtrl
         hb_GtInfo( HB_GTI_CLIPBOARDPASTE )
         RETURN 0
      ENDIF
   ENDSWITCH

   RETURN nKey
#endif

FUNCTION TestDanfe()

   LOCAL oDanfe, oFile, oFileList, cFilePdf

   oFileList := Directory( "*.xml" )
   FOR EACH oFile IN oFileList
      oDanfe := hbNfeDaGeral():New()
      cFilePdf := Substr( oFile[ F_NAME ], 1, At( ".", oFile[ F_NAME ] ) ) + "pdf"
      fErase( cFilePdf )
      //oDanfe:cLogoFile := JPEGImage()
      oDanfe:cDesenvolvedor := "www.josequintas.com.br"
      oDanfe:ToPDF( oFile[ F_NAME ], cFilePdf )
      ? oFile[ F_NAME ], oDanfe:cRetorno
      PDFOpen( cFilePdf )
   NEXT

   RETURN NIL

FUNCTION PDFOpen( cFile )

   IF File( cFile )
      WAPI_ShellExecute( NIL, "open", cFile, "",, WIN_SW_SHOWNORMAL )
      Inkey(1)
   ENDIF

   RETURN NIL

#ifndef __XHARBOUR__

FUNCTION JPEGImage()

#pragma __binarystreaminclude "jpatecnologia.jpg"        | RETURN %s

#endif
