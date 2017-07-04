/*
ZE_SPEDDACTE - Documento Auxiliar de Conhecimento Eletr�nico
Fontes originais do projeto hbnfe em https://github.com/fernandoathayde/hbnfe
Contribui��o DaCTE: MSouzaRunner
*/

#include "common.ch"
#include "hbclass.ch"
#include "harupdf.ch"
#ifndef __XHARBOUR__
#include "hbwin.ch"
#endif
#define LAYOUT_LOGO_ESQUERDA        1      /* apenas anotado, mas n�o usado */
#define LAYOUT_LOGO_DIREITA         2
#define LAYOUT_LOGO_EXPANDIDO       3

CREATE CLASS hbnfeDacte INHERIT hbNFeDaGeral

   METHOD ToPDF( cXmlCTE, cFilePDF, cXmlCancel )
   METHOD BuscaDadosXML()
   METHOD GeraPDF( cFilePDF )
   METHOD NovaPagina()
   METHOD Cabecalho()

   VAR nLarguraDescricao
   VAR nLarguraCodigo
   VAR cTelefoneEmitente INIT ""
   VAR cSiteEmitente     INIT ""
   VAR cEmailEmitente    INIT ""
   VAR cXML
   VAR cXmlCancel        INIT ""
   VAR cChave
   VAR aIde
   VAR aCompl
   VAR aObsCont
   VAR aEmit
   VAR aRem
   VAR ainfNF
   VAR ainfNFe
   VAR ainfOutros
   VAR aDest
   VAR aLocEnt
   VAR aPrest
   VAR aComp
   VAR aIcms00
   VAR aIcms20
   VAR aIcms45
   VAR aIcms60
   VAR aIcms90
   VAR aIcmsUF
   VAR aIcmsSN
   VAR vTotTrib
   VAR cAdfisco
   VAR aInfCarga
   VAR aInfQ
   VAR aSeg
   VAR aRodo
   VAR aMoto
   VAR aProp
   VAR aValePed
   VAR aVeiculo
   VAR aInfProt
   VAR aExped
   VAR aReceb
   VAR aToma

   VAR aICMSTotal
   VAR aISSTotal
   VAR aRetTrib
   VAR aTransp
   VAR aVeicTransp
   VAR aReboque
   VAR cCobranca
   VAR aInfAdic
   VAR aObsFisco
   VAR aExporta
   VAR aCompra
   VAR aInfCanc

   VAR aItem
   VAR aItemDI
   VAR aItemAdi
   VAR aItemICMS
   VAR aItemICMSPart
   VAR aItemICMSST
   VAR aItemICMSSN101
   VAR aItemICMSSN102
   VAR aItemICMSSN201
   VAR aItemICMSSN202
   VAR aItemICMSSN500
   VAR aItemICMSSN900
   VAR aItemIPI
   VAR aItemII
   VAR aItemPIS
   VAR aItemPISST
   VAR aItemCOFINS
   VAR aItemCOFINSST
   VAR aItemISSQN

   VAR cFonteNFe      INIT "Times"
   VAR cFonteCode128            // Inserido por Anderson Camilo em 04/04/2012
   VAR cFonteCode128F           // Inserido por Anderson Camilo em 04/04/2012
   VAR oPdf
   VAR oPdfPage
   VAR oPDFFontNormal
   VAR oPDFFontBold
   VAR nLinhaPDF
   VAR nLarguraBox INIT 0.5
   VAR lLaser INIT .T.
   VAR lPaisagem
   VAR cLogoFile  INIT ""
   VAR nLogoStyle INIT LAYOUT_LOGO_ESQUERDA

   VAR nItensFolha
   VAR nLinhaFolha
   VAR nFolhas
   VAR nFolha

   VAR lValorDesc INIT .F.
   VAR nCasasQtd INIT 2
   VAR nCasasVUn INIT 2
   VAR cRetorno

   ENDCLASS

METHOD ToPDF( cXmlCTE, cFilePDF, cXmlCancel ) CLASS hbnfeDaCte

   IF cXmlCTE == NIL
      ::cRetorno := "N�o informado texto do XML"
      RETURN ::cRetorno
   ENDIF
   ::cXmlCancel := iif( cXmlCancel == NIL, "", cXmlCancel )

   ::cXml   := cXmlCTE
   ::cChave := SubStr( ::cXML, At( "Id=", ::cXML ) + 3 + 4, 44 )

   ::buscaDadosXML()

   ::lPaisagem          := .F.
   ::nLarguraDescricao  := 39
   ::nLarguraCodigo     := 13

   IF ! ::GeraPdf( cFilePDF )
      ::cRetorno := "Problema ao gerar o PDF !"
      RETURN ::cRetorno
   ENDIF

   ::cRetorno := "OK"

   RETURN ::cRetorno

METHOD BuscaDadosXML() CLASS hbnfeDaCte

   LOCAL cIde, cCompl, cEmit, cDest, cPrest, cImp, cinfCTeNorm, cRodo, cExped, cReceb, oElement

   cIde := XmlNode( ::cXml, "ide" )
   ::aIde := XmlToHash( cIde, { "cUF", "cCT", "CFOP", "natOp", "forPag", "mod", "serie", "nCT", "dhEmi", "tpImp", "tpEmis", ;
             "cDV", "tpAmb", "tpCTe", "procEmi", "verProc", "cMunEnv", "xMunEnv", "UFEnv", "modal", "tpServ", "cMunIni", ;
             "xMunIni", "UFIni", "cMunFim", "xMunFim", "UFFim", "retira", "xDetRetira" } )
   ::aIde[ "toma" ] := XmlNode( XmlNode( cIde, "toma03" ), "toma" )

   cCompl := XmlNode( ::cXml, "compl" )
   ::aCompl := hb_Hash()
   ::aCompl[ "xObs" ] := XmlNode( cCompl, "xObs" )
   ::aObsCont := hb_Hash()
   ::aObsCont[ "xTexto" ] := XmlNode( cCompl, "xTexto" )

   cEmit := XmlNode( ::cXml, "emit" )
   ::aEmit := XmlToHash( cEmit, { "CNPJ", "IE", "xNome", "xFant", "fone" } )
   ::aEmit[ "xNome" ] := XmlToString( ::aEmit[ "xNome" ] )
   ::cTelefoneEmitente  := ::FormataTelefone( ::aEmit[ "fone" ] )
   cEmit := XmlNode( cEmit, "enderEmit" )
   FOR EACH oElement IN { "xLgr", "nro", "xCpl", "xBairro", "cMun", "xMun", "CEP", "UF" }
      ::aEmit[ oElement ] := XmlNode( cEmit, oElement )
   NEXT

   ::aRem            := XmlToHash( XmlNode( ::cXml, "rem" ), { "CNPJ", "CPF", "IE", "xNome", "xFant", "fone", "xLgr", "nro", "xCpl", "xBairro", "cMun", "xMun", "CEP", "UF", "cPais", "xPais" } )
   ::aRem[ "xNome" ] := XmlToString( ::aRem[ "xNome" ] )

   ::ainfNF := MultipleNodeToArray( XmlNode( ::cXml, "infDoc" ), "infNF" )
   FOR EACH oElement IN ::ainfNF
      oElement := { ;
         XmlNode( oElement, "nRoma" ), ;
         XmlNode( oElement, "nPed" ), ;
         XmlNode( oElement, "mod" ), ;
         XmlNode( oElement, "serie" ), ;
         XmlNode( oElement, "nDoc" ), ;
         XmlNode( oElement, "dEmi" ), ;
         XmlNode( oElement, "vBC" ), ;
         XmlNode( oElement, "vICMS" ), ;
         XmlNode( oElement, "vBCST" ), ;
         XmlNode( oElement, "vST" ), ;
         XmlNOde( oElement, "vProd" ), ;
         XmlNode( oElement, "vNF" ), ;
         XmlNode( oElement, "nCFOP" ), ;
         XmlNode( oElement, "nPeso" ), ;
         XmlNode( oElement, "PIN" ) }
   NEXT

   ::ainfNFe := MultipleNodeToArray( XmlNode( ::cXml, "infDoc" ), "infNFe" )
   FOR EACH oElement IN ::ainfNFe
      oElement := { XmlNode( oElement, "chave" ), XmlNode( oElement, "PIN" ) }
   NEXT

   ::ainfOutros := MultipleNodeToArray( XmlNode( ::cXml, "infDoc" ), "infOutros" )
   FOR EACH oElement IN ::ainfOutros
      oElement := { ;
         XmlNode( oElement, "tpDoc" ), ;
         XmlNode( oElement, "descOutros" ), ;
         XmlNode( oElement, "nDoc" ), ;
         XmlNode( oElement, "dEmi" ), ;
         XmlNode( oElement, "vDocFisc" ) }
   NEXT

   cDest := XmlNode( ::cXml, "dest" )
   ::aDest := XmlToHash( cDest, { "CNPJ", "CPF", "IE", "xNome", "fone", "ISUF", "email" } )
   ::aDest[ "xNome" ] := XmlToString( ::aDest[ "xNome" ] )
   ::aDest[ "email" ] := XmlToString( ::aDest[ "email" ] )
   ::aDest := XmlToHash( XmlNode( cDest, "enderDest" ), { "xLgr", "nro", "xCpl", "xBairro", "cMun", "xMun", "UF", "CEP", "cPais", "xPais" }, ::aDest )

   ::alocEnt := XmlToHash( XmlNode( cDest, "locEnt" ), { "CNPJ", "CPF", "xNome", "xLgr", "nro", "xCpl", "xBairro", "xMun", "UF" } )

   cExped := XmlNode( ::cXml, "exped" )
   ::aExped := XmlToHash( cExped, { "CNPJ", "CPF", "IE", "xNome", "fone", "email" } )
   ::aExped[ "xNome" ] := XmlToString( ::aExped[ "xNome" ] )
   ::aExped[ "email" ] := XmlToString( ::aExped[ "email" ] )
   ::aExped:= XmlToHash( XmlNode( cExped, "enderExped" ), { "xLgr", "nro", "xCpl", "xBairro", "cMun", "xMun", "UF", "CEP", "cPais", "xPais" }, ::aExped )

   cReceb := XmlNode( ::cXml, "receb" )
   ::aReceb := XmlToHash( cReceb, { "CNPJ", "CPF", "IE", "xNome", "fone", "email" } )
   ::aReceb[ "xNome" ] := XmlToString( ::aReceb[ "xNome" ] )
   ::aReceb[ "email" ] := XmlToString( ::aReceb[ "email" ] )
   ::aReceb := XmlToHash( XmlNode( cReceb, "enderReceb" ), { "xLgr", "nro", "xCpl", "xBairro", "cMun", "xMun", "UF", "CEP", "cPais", "xPais" }, ::aReceb )

   ::aPrest := XmlToHash( XmlNode( ::cXml, "vPrest" ), { "vTPrest", "vRec" } )

   ::aComp := {}
   cPrest  := XmlNode( ::cXml, "vPrest" )
   ::aComp := MultipleNodeToArray( cPrest, "Comp" )
   FOR EACH oElement IN ::aComp
      oElement := { XmlNode( oElement, "xNome" ), XmlNode( oElement, "vComp" ) }
   NEXT

   cImp        := XmlNode( ::cXml, "imp" )
   ::aIcms00   := XmlToHash( XmlNode( cImp, "ICMS00" ), { "CST", "vBC", "pICMS", "vICMS" } )
   ::aIcms20   := XmlToHash( XmlNode( cImp, "ICMS20" ), { "CST", "vBC", "pRedBC", "pICMS", "vICMS" } )
   ::aIcms45   := XmlToHash( XmlNode( cImp, "ICMS45" ), { "CST" } )
   ::aIcms60   := XmlToHash( XmlNode( cImp, "ICMS60" ), { "CST", "vBCSTRet", "vICMSSTRet", "pICMSSTRet", "vCred" } )
   ::aIcms90   := XmlToHash( XmlNode( cImp, "ICMS90" ), { "CST", "pRedBC", "vBC", "pICMS", "vICMS", "vCred" } )
   ::aIcmsUF   := XmlToHash( XmlNode( cImp, "ICMSOutraUF" ), { "CST", "pRedBCOutraUF", "vBCOutraUF", "pICMSOutraUF", "vICMSOutraUF" } )
   ::aIcmsSN   := XmlToHash( XmlNode( cImp, "ICMSSN" ), { "indSN" } )
   ::cAdFisco  := XmlNode( cImp, "infAdFisco" )
   ::vTotTrib  := XmlNode( ::cXml, "vTotTrib" )
   cinfCTeNorm := XmlNode( ::cXml, "infCTeNorm" )
   ::aInfCarga := XmlToHash( XmlNode( cinfCteNorm, "infCarga" ), { "vCarga", "proPred", "xOutCat" } )

   ::aInfQ := MultipleNodeToArray( XmlNode( cinfCteNorm, "infCarga" ), "infQ" )
   FOR EACH oElement IN ::aInfQ
      oElement := { XmlNode( oElement, "cUnid" ), XmlNode( oElement, "tpMed" ), XmlNode( oElement, "qCarga" ) }
   NEXT

   ::aSeg     := XmlToHash( XmlNode( cInfCteNorm, "seg" ), { "respSeg", "xSeg", "nApol", "nAver", "vCarga" } )
   ::aMoto    := XmlToHash( XmlNode( cInfCteNorm, "moto" ), { "xNome", "CPF" } )
   cRodo      := XmlNode( cInfCteNorm, "rodo" )
   ::aRodo    := XmlToHash( cRodo, { "RNTRC", "dPrev", "lota", "CIOT", "nLacre" } )
   ::aValePed := XmlToHash( XmlNode( cRodo, "valePed" ), { "CNPJForn", "nCompra", "CNPJPg" } )
   ::aProp    := XmlToHash( XmlNode( cRodo, "prop" ), { "CPF", "CNPJ", "RNTRC", "xNome", "IE", "UF", "tpProp" } )

   ::aVeiculo := MultipleNodeToArray( XmlNode( cinfCteNorm, "rodo" ), "veic" )
   FOR EACH oElement IN ::aVeiculo
      oElement := { XmlNode( oElement, "cInt" ),   XmlNode( oElement, "RENAVAM" ), XmlNode( oElement, "placa" ), ;
                    XmlNode( oElement, "tara" ),   XmlNode( oElement, "capKG" ),   XmlNode( oElement, "capM3" ), ;
                    XmlNode( oElement, "tpProp" ), XmlNode( oElement, "tpVeic" ),  XmlNode( oElement, "tpRod" ), ;
                    XmlNode( oElement, "tpCar" ),  XmlNode( oElement, "UF" ) }
   NEXT

   ::aInfProt   := XmlToHash( XmlNode( ::cXml, "infProt" ), { "nProt", "dhRecbto", "digVal", "cStat", "xMotivo" } )
   ::aInfCanc   := XmlToHash( XmlNode( iif( Empty( ::cXmlCancel ), ::cXml, ::cXmlCancel ), "infProt" ), { "nProt", "dhRecbto", "digVal", "cStat", "xMotivo" } )

   DO CASE
   CASE ::aIde[ 'toma' ] = '0' ; ::aToma := ::aRem
   CASE ::aIde[ 'toma' ] = '1' ; ::aToma := ::aExped
   CASE ::aIde[ 'toma' ] = '2' ; ::aToma := ::aReceb
   CASE ::aIde[ 'toma' ] = '3' ; ::aToma := ::aDest
   ENDCASE

   RETURN NIL

METHOD GeraPDF( cFilePDF ) CLASS hbnfeDaCte

   ::oPdf := HPDF_New()
   If ::oPdf == NIL
      ::cRetorno := "Falha da cria��o do objeto PDF !"
      RETURN .F.
   ENDIF
   HPDF_SetCompressionMode( ::oPdf, HPDF_COMP_ALL )
   ::oPDFFontNormal     := HPDF_GetFont( ::oPdf, "Times-Roman", "CP1252" )
   ::oPDFFontBold := HPDF_GetFont( ::oPdf, "Times-Bold",  "CP1252" )

#ifdef __XHARBOUR__
   // Inserido por Anderson Camilo em 04/04/2012
   ::cFonteCode128  := HPDF_LoadType1FontFromFile( ::oPdf, 'fontes\Code128bWinLarge.afm', 'fontes\Code128bWinLarge.pfb' )   // Code 128
   ::cFonteCode128F := HPDF_GetFont( ::oPdf, ::cFonteCode128, "WinAnsiEncoding" )
#endif

   ::nFolha := 1
   ::novaPagina()
   ::cabecalho()

   HPDF_SaveToFile( ::oPdf, cFilePDF )
   HPDF_Free( ::oPdf )

   RETURN .T.

METHOD NovaPagina() CLASS hbnfeDaCte

   LOCAL nRadiano, nAngulo

   ::oPdfPage := HPDF_AddPage( ::oPdf )

   HPDF_Page_SetSize( ::oPdfPage, HPDF_PAGE_SIZE_A4, HPDF_PAGE_PORTRAIT )

   ::nLinhaPdf := HPDF_Page_GetHeight( ::oPDFPage ) - 3     // Margem Superior
   nAngulo := 45                   /* A rotation of 45 degrees. */

   nRadiano := nAngulo / 180 * 3.141592 /* Calcurate the radian value. */

   IF ::aIde[ "tpAmb" ] = "2" .OR. Empty( ::ainfProt[ "nProt" ] )
      ::DrawHomologacao()
   ENDIF

   IF ! Empty( ::aInfCanc[ "nProt" ] ) .AND. ::aInfCanc[ "cStat" ] $ "101,135,302" // 302=denegada

       HPDF_Page_SetFontAndSize( ::oPdfPage, ::oPDFFontBold, 30 )
       HPDF_Page_BeginText(::oPdfPage)
       HPDF_Page_SetTextMatrix(::oPdfPage, cos(nRadiano), sin(nRadiano), -sin(nRadiano), cos(nRadiano), 15, 150)
       HPDF_Page_SetRGBFill(::oPdfPage, 1, 0, 0)
       HPDF_Page_ShowText(::oPdfPage, ::aInfCanc[ "xMotivo" ])
       HPDF_Page_EndText(::oPdfPage)

       HPDF_Page_SetRGBStroke(::oPdfPage, 0.75, 0.75, 0.75)
       IF ::lPaisagem
          ::DrawLine( 15, 95, 675, 475, 2.0)
       ELSE
          ::DrawLine( 15, 95, 550, 630, 2.0)
       ENDIF

       HPDF_Page_SetRGBStroke(::oPdfPage, 0, 0, 0) // reseta cor linhas

       HPDF_Page_SetRGBFill(::oPdfPage, 0, 0, 0) // reseta cor fontes

   ENDIF

   RETURN NIL

METHOD Cabecalho() CLASS hbnfeDaCte

   LOCAL aModal     := { 'Rodovi�rio', 'A�reo', 'Aquavi�rio', 'Ferrovi�rio', 'Dutovi�rio' }
   LOCAL aTipoCte   := { 'Normal', 'Compl.Val', 'Anul.Val.', 'Substituto' }
   LOCAL aTipoServ  := { 'Normal', 'Subcontrata��o', 'Redespacho', 'Redesp. Int.' }
   LOCAL aTomador   := { 'Remetente', 'Expedidor', 'Recebedor', 'Destinat�rio' }
   LOCAL aPagto     := { 'Pago', 'A pagar', 'Outros' }
   LOCAL aUnid      := { 'M3', 'KG', 'TON', 'UN', 'LI', 'MMBTU' }
   LOCAL aResp      := { 'Remetente', 'Expedidor', 'Recebedor', 'Destinat�rio', 'Emitente do CT-e', 'Tomador de Servi�o' }
   LOCAL aTipoCar   := { 'n�o aplic�vel', 'Aberta', 'Fechada/Ba�', 'Granelera', 'Porta Container', 'Sider' }
   LOCAL cOutros    := ''
   LOCAL cEntrega   := ''
   LOCAL aObserv    := {}
   LOCAL cMensa
   LOCAL nLinha
   LOCAL nBase      := ''
   LOCAL nAliq      := ''
   LOCAL nValor     := ''
   LOCAL nReduc     := ''
   LOCAL nST        := ''
   LOCAL DASH_MODE3 := { 8, 7, 2, 7 }
   LOCAL nCont, oElement, cTexto

   // box do logotipo e dados do emitente
   ::DrawBox( 003, ::nLinhaPdf - 119, 295, 119, ::nLarguraBox )

   ::DrawJPEGImage( ::cLogoFile, 115, ::nLinhaPdf - ( 52 + 1 ), 100, 052 )
   IF Len( ::aEmit[ "xNome" ] ) <= 25
      ::DrawTexto( 3, ::nLinhaPdf - 056, 295, Nil, ::aEmit[ "xNome" ], HPDF_TALIGN_CENTER, ::oPDFFontBold, 12 )
   ELSE
      ::DrawTexto( 3, ::nLinhaPdf - 056, 295, Nil, ::aEmit[ "xNome" ], HPDF_TALIGN_CENTER, ::oPDFFontBold, 10 )
   ENDIF
   ::DrawTexto( 6, ::nLinhaPdf - 070, 295, Nil, ::aEmit[ "xLgr" ] + " " + ::aEmit[ "nro" ] + " " + ::aEmit[ "xCpl" ], HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   ::DrawTexto( 6, ::nLinhaPdf - 078, 295, Nil, ::aEmit[ "xBairro" ] + " - " + Transform( ::aEmit[ "CEP" ], "@R 99999-999" ), HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   ::DrawTexto( 6, ::nLinhaPdf - 086, 295, Nil, ::aEmit[ "xMun" ] + " - " + ::aEmit[ "UF" ], HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   ::DrawTexto( 6, ::nLinhaPdf - 094, 295, Nil, iif( Empty( ::aEmit[ "fone" ] ), "", "Fone/Fax:" + ::FormataTelefone( ::aEmit[ "fone" ] ) ), HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   ::DrawTexto( 6, ::nLinhaPdf - 107, 295, Nil, 'CNPJ/CPF:' + Transform( ::aEmit[ "CNPJ" ], "@R 99.999.999/9999-99" ) + '       Inscr.Estadual:' + ::FormataIE( ::aEmit[ "IE" ], ::aEmit[ "UF" ] ), HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )

   // box do nome do documento
   ::DrawBox( 303, ::nLinhaPdf - 032, 145, 032, ::nLarguraBox )
   ::DrawTexto( 303, ::nLinhaPdf - 001, 448, Nil, "DACTE", HPDF_TALIGN_CENTER, ::oPDFFontBold, 12 )
   ::DrawTexto( 303, ::nLinhaPdf - 010, 448, Nil, "Documento Auxiliar do", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   ::DrawTexto( 303, ::nLinhaPdf - 016, 448, Nil, "Conhecimento de Transporte", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   ::DrawTexto( 303, ::nLinhaPdf - 022, 448, Nil, "Eletr�nico", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )

   // box do modal
   ::DrawBox( 453, ::nLinhaPdf - 032, 140, 032, ::nLarguraBox )
   ::DrawTexto( 453, ::nLinhaPdf - 001, 588, Nil, "MODAL", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 10 )
   ::DrawTexto( 453, ::nLinhaPdf - 015, 588, Nil, aModal[ Val( ::aIde[ "modal" ] ) ], HPDF_TALIGN_CENTER, ::oPDFFontBold, 12 )

   // box do modelo
   ::DrawBox( 303, ::nLinhaPdf - 060, 035, 025, ::nLarguraBox )
   ::DrawTexto( 303, ::nLinhaPdf - 040, 338, Nil, "Modelo", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   ::DrawTexto( 303, ::nLinhaPdf - 047, 338, Nil, ::aIde[ "mod" ], HPDF_TALIGN_CENTER, ::oPDFFontBold, 10 )

   // box da serie
   ::DrawBox( 338, ::nLinhaPdf - 060, 035, 025, ::nLarguraBox )
   ::DrawTexto( 338, ::nLinhaPdf - 040, 373, Nil, "S�rie", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   ::DrawTexto( 338, ::nLinhaPdf - 047, 373, Nil, ::aIde[ "serie" ], HPDF_TALIGN_CENTER, ::oPDFFontBold, 10 )

   // box do numero
   ::DrawBox( 373, ::nLinhaPdf - 060, 060, 025, ::nLarguraBox )
   ::DrawTexto( 373, ::nLinhaPdf - 040, 433, Nil, "N�mero", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   ::DrawTexto( 373, ::nLinhaPdf - 047, 433, Nil, ::aIde[ "nCT" ], HPDF_TALIGN_CENTER, ::oPDFFontBold, 10 )

   // box do fl
   ::DrawBox( 433, ::nLinhaPdf - 060, 035, 025, ::nLarguraBox )
   ::DrawTexto( 433, ::nLinhaPdf - 040, 468, Nil, "FL", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   ::DrawTexto( 433, ::nLinhaPdf - 047, 468, Nil, "1/1", HPDF_TALIGN_CENTER, ::oPDFFontBold, 10 )

   // box do data e hora
   ::DrawBox( 468, ::nLinhaPdf - 060, 125, 025, ::nLarguraBox )
   ::DrawTexto( 468, ::nLinhaPdf - 040, 588, Nil, "Data e Hora de Emiss�o", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   ::DrawTexto( 468, ::nLinhaPdf - 047, 588, Nil, SubStr( ::aIde[ "dhEmi" ], 9, 2 ) + "/" + SubStr( ::aIde[ "dhEmi" ], 6, 2 ) + "/" + SubStr( ::aIde[ "dhEmi" ], 1, 4 ) + ' ' + SubStr( ::aIde[ "dhEmi" ], 12 ), HPDF_TALIGN_CENTER, ::oPDFFontBold, 10 )

   // box do controle do fisco
   ::DrawBox( 303, ::nLinhaPdf - 129, 290, 066, ::nLarguraBox )
   ::DrawTexto( 303, ::nLinhaPdf - 065, 588, Nil, "CONTROLE DO FISCO", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 09 )
#ifdef __XHARBOUR__
   ::DrawTexto( 303, ::nLinhaPdf - 075, 588, Nil, ::xHarbourCode128c( ::cChave ), HPDF_TALIGN_CENTER, ::cFonteCode128F, 17 )
#else
   // aten��o - chute inicial
   ::DrawBarcode128( ::cChave, 320, ::nLinhaPDF -110, 0.9, 30 )
#endif
   ::DrawTexto( 303, ::nLinhaPdf - 110, 588, Nil, "Chave de acesso para consulta de autenticidade no site www.cte.fazenda.gov.br", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   ::DrawTexto( 303, ::nLinhaPdf - 119, 588, Nil, TRANSF( ::cChave, "@R 99.9999.99.999.999/9999-99-99-999-999.999.999-999.999.999-9" ), HPDF_TALIGN_CENTER, ::oPDFFontBold, 8 )

   // box do tipo do cte
   ::DrawBox( 003, ::nLinhaPdf - 154, 060, 032, ::nLarguraBox )
   ::DrawTexto( 003, ::nLinhaPdf - 125, 060, Nil, "Tipo do CTe", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   ::DrawTexto( 003, ::nLinhaPdf - 135, 060, Nil, aTipoCte[ Val( ::aIde[ "tpCTe" ] ) + 1 ], HPDF_TALIGN_CENTER, ::oPDFFontBold, 10 )

   // box do tipo do servico
   ::DrawBox( 063, ::nLinhaPdf - 154, 070, 032, ::nLarguraBox )
   ::DrawTexto( 063, ::nLinhaPdf - 125, 133, Nil, "Tipo Servi�o", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   ::DrawTexto( 063, ::nLinhaPdf - 135, 133, Nil, aTipoServ[ Val( ::aIde[ "tpServ" ] ) + 1 ], HPDF_TALIGN_CENTER, ::oPDFFontBold, 10 )

   // box do tipo do Tomador do Servico
   ::DrawBox( 133, ::nLinhaPdf - 154, 070, 032, ::nLarguraBox )
   ::DrawTexto( 133, ::nLinhaPdf - 125, 203, Nil, "Tomador", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   ::DrawTexto( 133, ::nLinhaPdf - 135, 203, Nil, aTomador[ Val( ::aIde[ "toma" ] ) + 1 ], HPDF_TALIGN_CENTER, ::oPDFFontBold, 10 )

   // box do tipo Forma de Pagamento
   ::DrawBox( 203, ::nLinhaPdf - 154, 095, 032, ::nLarguraBox )
   ::DrawTexto( 203, ::nLinhaPdf - 125, 298, Nil, "Forma de Pagamento", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   ::DrawTexto( 203, ::nLinhaPdf - 135, 298, Nil, aPagto[ Val( ::aIde[ "forPag" ] ) + 1 ], HPDF_TALIGN_CENTER, ::oPDFFontBold, 10 )
   // box do No. do Protocolo
   ::DrawBox( 303, ::nLinhaPdf - 154, 165, 022, ::nLarguraBox )
   ::DrawTexto( 303, ::nLinhaPdf - 135, 468, Nil, "No. PROTOCOLO", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   IF ! Empty( ::aInfProt[ "nProt" ] )
      ::DrawTexto( 303, ::nLinhaPdf - 143, 468, Nil, ::aInfProt[ "nProt" ] + ' - ' + SubStr( ::aInfProt[ "dhRecbto" ], 9, 2 ) + "/" + SubStr( ::aInfProt[ "dhRecbto" ], 6, 2 ) + "/" + SubStr( ::aInfProt[ "dhRecbto" ], 1, 4 ) + ' ' + SubStr( ::aInfProt[ "dhRecbto" ], 12 ), HPDF_TALIGN_CENTER, ::oPDFFontBold, 9 )
   ENDIF

   // box da Insc. da Suframa
   ::DrawBox( 468, ::nLinhaPdf - 154, 125, 022, ::nLarguraBox )
   ::DrawTexto( 468, ::nLinhaPdf - 135, 588, Nil, "INSC. SUFRAMA DO DEST.", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   // ::DrawTexto( 468 , ::nLinhaPdf-145 , 568, Nil, ::aDest[ "ISUF" ] , HPDF_TALIGN_CENTER, ::oPDFFontBold, 6 )
   ::DrawTexto( 468, ::nLinhaPdf - 143, 588, Nil, 'xxxxx xxxxxxxxxxxxxxx', HPDF_TALIGN_CENTER, ::oPDFFontBold, 9 )

   ::DrawBoxTituloTexto( 003, ::nLinhaPdf - 157, 590, 022, "CFOP - Natureza da Presta��o", ::aIde[ "CFOP" ] + ' - ' + ::aIde[ "natOp" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )

   ::DrawBoxTituloTexto( 003, ::nLinhaPdf - 182, 295, 022, "Origem da Presta��o", ::aIde[ "xMunIni" ] + ' - ' + ::aIde[ "UFIni" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )

   ::DrawBoxTituloTexto( 303, ::nLinhaPdf - 182, 290, 022, "Destino da Presta��o", ::aIde[ "xMunFim" ] + ' - ' + ::aIde[ "UFFim" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )

   // Box do Remetente
   ::DrawBox( 003, ::nLinhaPdf - 261, 295, 054, ::nLarguraBox )
   ::DrawTexto( 005, ::nLinhaPdf - 207, 040, Nil, "Remetente ", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 042, ::nLinhaPdf - 208, 295, Nil, ::aRem[ "xNome" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 005, ::nLinhaPdf - 215, 040, Nil, "Endere�o", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 042, ::nLinhaPdf - 216, 295, Nil, ::aRem[ "xLgr" ] + " " + ::aRem[ "nro" ] + " " + ::aRem[ "xCpl" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 042, ::nLinhaPdf - 224, 295, Nil, ::aRem[ "xBairro" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 005, ::nLinhaPdf - 232, 040, Nil, "Munic�pio", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 042, ::nLinhaPdf - 233, 240, Nil, ::aRem[ "xMun" ] + " " + ::aRem[ "UF" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 240, ::nLinhaPdf - 232, 260, Nil, "CEP", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 260, ::nLinhaPdf - 233, 295, Nil, SubStr( ::aRem[ "CEP" ], 1, 5 ) + '-' + SubStr( ::aRem[ "CEP" ], 6, 3 ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 005, ::nLinhaPdf - 240, 042, Nil, "CNPJ/CPF", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   IF ! Empty( ::aRem[ "CNPJ" ] )
      ::DrawTexto( 042, ::nLinhaPdf - 241, 150, Nil, Transform( ::aRem[ "CNPJ" ], "@R 99.999.999/9999-99" ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ENDIF
   IF ! Empty( ::aRem[ "CPF" ] )
      ::DrawTexto( 042, ::nLinhaPdf - 241, 150, Nil, Transform( ::aRem[ "CPF" ], "@R 999.999.999-99" ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ENDIF
   ::DrawTexto( 150, ::nLinhaPdf - 240, 250, Nil, "INSCRI��O ESTADUAL", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 245, ::nLinhaPdf - 241, 295, Nil, ::FormataIE( ::aRem[ "IE" ], ::aRem[ "UF" ] ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 005, ::nLinhaPdf - 248, 042, Nil, "Pais", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 042, ::nLinhaPdf - 249, 150, Nil, ::aRem[ "xPais" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 225, ::nLinhaPdf - 248, 250, Nil, "FONE", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 250, ::nLinhaPdf - 249, 295, Nil, ::FormataTelefone( ::aRem[ "fone" ] ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )

   // Box do Destinatario
   ::DrawBox( 303, ::nLinhaPdf - 261, 290, 054, ::nLarguraBox )
   ::DrawTexto( 305, ::nLinhaPdf - 207, 340, Nil, "Destinat�rio", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 7 )
   ::DrawTexto( 342, ::nLinhaPdf - 208, 595, Nil, ::aDest[ "xNome" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 305, ::nLinhaPdf - 215, 340, Nil, "Endere�o", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 342, ::nLinhaPdf - 216, 588, Nil, ::aDest[ "xLgr" ] + " " + ::aDest[ "nro" ] + " " + ::aDest[ "xCpl" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 342, ::nLinhaPdf - 224, 588, Nil, ::aDest[ "xBairro" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 305, ::nLinhaPdf - 232, 340, Nil, "Munic�pio", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 342, ::nLinhaPdf - 233, 540, Nil, ::aDest[ "xMun" ] + " " + ::aDest[ "UF" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 535, ::nLinhaPdf - 232, 555, Nil, "CEP", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 555, ::nLinhaPdf - 233, 588, Nil, SubStr( ::aDest[ "CEP" ], 1, 5 ) + '-' + SubStr( ::aDest[ "CEP" ], 6, 3 ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 305, ::nLinhaPdf - 240, 342, Nil, "CNPJ/CPF", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   IF ! Empty( ::aDest[ "CNPJ" ] )
      ::DrawTexto( 342, ::nLinhaPdf - 241, 450, Nil, Transform( ::aDest[ "CNPJ" ], "@R 99.999.999/9999-99" ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ENDIF
   IF ! Empty( ::aDest[ "CPF" ] )
      ::DrawTexto( 342, ::nLinhaPdf - 241, 450, Nil, Transform( ::aDest[ "CPF" ], "@R 999.999.999-99" ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ENDIF
   ::DrawTexto( 430, ::nLinhaPdf - 240, 530, Nil, "INSCRI��O ESTADUAL", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )

   ::DrawTexto( 530, ::nLinhaPdf - 241, 595, Nil, AllTrim( ::aDest[ "IE" ], ::aDest[ "UF" ] ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 305, ::nLinhaPdf - 248, 342, Nil, "Pais", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 342, ::nLinhaPdf - 249, 450, Nil, ::aDest[ "xPais" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 520, ::nLinhaPdf - 248, 545, Nil, "FONE", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 545, ::nLinhaPdf - 249, 595, Nil, ::FormataTelefone( ::aDest[ "fone" ] ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   // Box do Expedidor
   ::DrawBox( 003, ::nLinhaPdf - 318, 295, 054, ::nLarguraBox )

   ::DrawTexto( 005, ::nLinhaPdf - 264, 040, Nil, "Expedidor", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   If ! Empty( ::aExped[ "xNome" ] )
      ::DrawTexto( 042, ::nLinhaPdf - 265, 295, Nil, ::aExped[ "xNome" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ENDIF
   ::DrawTexto( 005, ::nLinhaPdf - 272, 040, Nil, "Endere�o", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   If ! Empty( ::aExped[ "xLgr" ] )
      ::DrawTexto( 042, ::nLinhaPdf - 273, 295, Nil, ::aExped[ "xLgr" ] + " " + ::aExped[ "nro" ] + " " + ::aExped[ "xCpl" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ENDIF
   If ! Empty( ::aExped[ "xBairro" ] )
      ::DrawTexto( 042, ::nLinhaPdf - 280, 295, Nil, ::aExped[ "xBairro" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ENDIF
   ::DrawTexto( 005, ::nLinhaPdf - 288, 040, Nil, "Munic�pio", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   If ! Empty( ::aExped[ "xMun" ] )
      ::DrawTexto( 042, ::nLinhaPdf - 289, 240, Nil, ::aExped[ "xMun" ] + " " + ::aExped[ "UF" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ENDIF
   ::DrawTexto( 240, ::nLinhaPdf - 288, 260, Nil, "CEP", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   If ! Empty( ::aExped[ "CEP" ] )
      ::DrawTexto( 260, ::nLinhaPdf - 289, 295, Nil, SubStr( ::aExped[ "CEP" ], 1, 5 ) + '-' + SubStr( ::aExped[ "CEP" ], 6, 3 ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ENDIF
   ::DrawTexto( 005, ::nLinhaPdf - 296, 042, Nil, "CNPJ/CPF", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   If ! Empty( ::aExped[ "CNPJ" ] )
      ::DrawTexto( 042, ::nLinhaPdf - 297, 150, Nil, TRANSF( ::aExped[ "CNPJ" ], "@R 99.999.999/9999-99" ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ENDIF
   If ! Empty( ::aExped[ "CPF" ] )
      ::DrawTexto( 042, ::nLinhaPdf - 297, 150, Nil, TRANSF( ::aExped[ "CPF" ], "@R 999.999.999-99" ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ENDIF
   ::DrawTexto( 150, ::nLinhaPdf - 296, 250, Nil, "INSCRI��O ESTADUAL", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 245, ::nLinhaPdf - 297, 295, Nil, AllTrim( ::aExped[ "IE" ] ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 005, ::nLinhaPdf - 304, 042, Nil, "Pais", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   If ! Empty( ::aExped[ "xPais" ] )
      ::DrawTexto( 042, ::nLinhaPdf - 305, 150, Nil, ::aExped[ "xPais" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ENDIF
   ::DrawTexto( 225, ::nLinhaPdf - 304, 250, Nil, "FONE", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 250, ::nLinhaPdf - 305, 295, Nil, ::FormataTelefone( ::aExped[ "fone" ] ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )

   // Box do Recebedor
   ::DrawBox( 303, ::nLinhaPdf - 318, 290, 054, ::nLarguraBox )
   ::DrawTexto( 305, ::nLinhaPdf - 264, 340, Nil, "Recebedor", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 7 )
   If ! Empty( ::aReceb[ "xNome" ] )
      ::DrawTexto( 342, ::nLinhaPdf - 265, 595, Nil, ::aReceb[ "xNome" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ENDIF
   ::DrawTexto( 305, ::nLinhaPdf - 272, 340, Nil, "Endere�o", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   If ! Empty( ::aReceb[ "xLgr" ] )
      ::DrawTexto( 342, ::nLinhaPdf - 273, 588, Nil, ::aReceb[ "xLgr" ] + " " + ::aReceb[ "nro" ] + " " + ::aReceb[ "xCpl" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ENDIF
   If ! Empty( ::aReceb[ "xBairro" ] )
      ::DrawTexto( 342, ::nLinhaPdf - 280, 588, Nil, ::aReceb[ "xBairro" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ENDIF
   ::DrawTexto( 305, ::nLinhaPdf - 288, 340, Nil, "Munic�pio", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   If ! Empty( ::aReceb[ "xMun" ] )
      ::DrawTexto( 342, ::nLinhaPdf - 289, 540, Nil, ::aReceb[ "xMun" ] + " " + ::aReceb[ "UF" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ENDIF
   ::DrawTexto( 535, ::nLinhaPdf - 288, 555, Nil, "CEP", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   If ! Empty( ::aReceb[ "CEP" ] )
      ::DrawTexto( 555, ::nLinhaPdf - 289, 588, Nil, SubStr( ::aReceb[ "CEP" ], 1, 5 ) + '-' + SubStr( ::aReceb[ "CEP" ], 6, 3 ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ENDIF
   ::DrawTexto( 305, ::nLinhaPdf - 296, 342, Nil, "CNPJ/CPF", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   If ! Empty( ::aReceb[ "CNPJ" ] )
      ::DrawTexto( 342, ::nLinhaPdf - 297, 450, Nil, TRANSF( ::aReceb[ "CNPJ" ], "@R 99.999.999/9999-99" ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ENDIF
   If ! Empty( ::aReceb[ "CPF" ] )
      ::DrawTexto( 342, ::nLinhaPdf - 297, 450, Nil, TRANSF( ::aReceb[ "CPF" ], "@R 999.999.999-99" ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ENDIF
   ::DrawTexto( 440, ::nLinhaPdf - 296, 540, Nil, "INSCRI��O ESTADUAL", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 540, ::nLinhaPdf - 297, 590, Nil, ::FormataIE( ::aReceb[ "IE" ], ::aReceb[ "UF" ] ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 305, ::nLinhaPdf - 304, 342, Nil, "Pais", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   If ! Empty( ::aReceb[ "xPais" ] )
      ::DrawTexto( 342, ::nLinhaPdf - 305, 450, Nil, ::aReceb[ "xPais" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ENDIF
   ::DrawTexto( 520, ::nLinhaPdf - 304, 545, Nil, "FONE", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 545, ::nLinhaPdf - 305, 595, Nil, ::FormataTelefone( ::aReceb[ "fone" ] ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )

   // Box do Tomador
   ::DrawBox( 003, ::nLinhaPdf - 347, 590, 026, ::nLarguraBox )
   ::DrawTexto( 005, ::nLinhaPdf - 321, 075, Nil, "Tomador do Servi�o", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 077, ::nLinhaPdf - 322, 330, Nil, ::aToma[ "xNome" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 337, ::nLinhaPdf - 321, 372, Nil, "Munic�pio", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 373, ::nLinhaPdf - 322, 460, Nil, ::aToma[ "xMun" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 495, ::nLinhaPdf - 321, 510, Nil, "UF", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 512, ::nLinhaPdf - 322, 534, Nil, ::aToma[ "UF" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 530, ::nLinhaPdf - 321, 550, Nil, "CEP", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 552, ::nLinhaPdf - 322, 590, Nil, SubStr( ::aToma[ "CEP" ], 1, 5 ) + '-' + SubStr( ::aToma[ "CEP" ], 6, 3 ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 005, ::nLinhaPdf - 329, 040, Nil, "Endere�o", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 042, ::nLinhaPdf - 330, 590, Nil, ::aToma[ "xLgr" ] + " " + ::aToma[ "nro" ] + " " + ::aToma[ "xCpl" ] + ' - ' + ::aToma[ "xBairro" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 005, ::nLinhaPdf - 337, 042, Nil, "CNPJ/CPF", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )

   IF ! Empty( ::aToma[ "CNPJ" ] )
      ::DrawTexto( 042, ::nLinhaPdf - 338, 150, Nil, TRANSF( ::aToma[ "CNPJ" ], "@R 99.999.999/9999-99" ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ENDIF
   IF ! Empty( ::aToma[ "CPF" ] )
      ::DrawTexto( 042, ::nLinhaPdf - 338, 150, Nil, TRANSF( ::aToma[ "CPF" ], "@R 999.999.999-99" ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ENDIF

   ::DrawTexto( 150, ::nLinhaPdf - 337, 250, Nil, "INSCRI��O ESTADUAL", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 245, ::nLinhaPdf - 338, 295, Nil, ::FormataIE( ::aToma[ "IE" ], ::aToma[ "UF" ] ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 425, ::nLinhaPdf - 337, 465, Nil, "Pais", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 442, ::nLinhaPdf - 338, 500, Nil, ::aToma[ "xPais" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawTexto( 520, ::nLinhaPdf - 337, 560, Nil, "FONE", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 542, ::nLinhaPdf - 338, 590, Nil, ::FormataTelefone( ::aToma[ "fone" ] ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )

   // Box do Produto Predominante
   ::DrawBox( 003, ::nLinhaPdf - 373, 340, 023, ::nLarguraBox )
   ::DrawTexto( 005, ::nLinhaPdf - 350, 150, Nil, "Produto Predominante", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 005, ::nLinhaPdf - 360, 330, Nil, ::aInfCarga[ "proPred" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 10 )
   ::DrawBox( 343, ::nLinhaPdf - 373, 125, 023, ::nLarguraBox )
   ::DrawTexto( 348, ::nLinhaPdf - 350, 470, Nil, "Outras Caracter�sticas da Carga", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 348, ::nLinhaPdf - 360, 470, Nil, ::aInfCarga[ "xOutCat" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 10 )
   ::DrawBox( 468, ::nLinhaPdf - 373, 125, 023, ::nLarguraBox )
   ::DrawTexto( 473, ::nLinhaPdf - 350, 590, Nil, "Valot Total da Mercadoria", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 473, ::nLinhaPdf - 358, 580, Nil, Transform( Val( ::aInfCarga[ "vCarga" ] ), '@E 9,999,999.99' ), HPDF_TALIGN_RIGHT, ::oPDFFontBold, 12 )

   // Box das Quantidades
   cTexto := iif( ! Len( ::aInfQ ) > 0, "", AllTrim( Transform( Val( ::aInfQ[ 1, 3 ] ), '@E 999,999.999' ) ) + '/' + aUnid[ Val( ::aInfQ[ 1, 1 ] ) + 1 ] + '/' + ::aInfQ[ 1, 2 ] )
   ::DrawBoxTituloTexto( 003, ::nLinhaPdf - 373, 090, 025, "QT./UN./Medida", cTexto, HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   cTexto := iif( ! Len( ::aInfQ ) > 1, "", AllTrim( Transform( Val( ::aInfQ[ 2, 3 ] ), '@E 999,999.999' ) ) + '/' + aUnid[ Val( ::aInfQ[ 2, 1 ] ) + 1 ] + '/' + ::aInfQ[ 2, 2 ] )
   ::DrawBoxTituloTexto( 093, ::nLinhaPdf - 373, 090, 025, "QT./UN./Medida", cTexto, HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   cTexto := iif( ! Len( ::aInfQ ) > 2, "", AllTrim( Transform( Val( ::aInfQ[ 3, 3 ] ), '@E 999,999.999' ) ) + '/' + aUnid[ Val( ::aInfQ[ 3, 1 ] ) + 1 ] + '/' + ::aInfQ[ 3, 2 ] )
   ::DrawBoxTituloTexto( 183, ::nLinhaPdf - 373, 090, 025, "QT./UN./Medida", cTexto, HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )

   // Box da Seguradora
   ::DrawBox( 273, ::nLinhaPdf - 383, 320, 010, ::nLarguraBox )
   ::DrawTexto( 278, ::nLinhaPdf - 373, 400, Nil, "Nome da Seguradora", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 7 )
   ::DrawTexto( 405, ::nLinhaPdf - 373, 580, Nil, ::aSeg[ "xSeg" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawBox( 273, ::nLinhaPdf - 398, 097, 015, ::nLarguraBox )
   ::DrawTexto( 278, ::nLinhaPdf - 383, 370, Nil, "Respons�vel", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 7 )
   ::DrawTexto( 278, ::nLinhaPdf - 389, 370, Nil, aResp[ Val( ::aSeg[ "respSeg" ] ) + 1 ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawBox( 370, ::nLinhaPdf - 398, 098, 015, ::nLarguraBox )
   ::DrawTexto( 375, ::nLinhaPdf - 383, 465, Nil, "N�mero da Ap�lice", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 7 )
   ::DrawTexto( 375, ::nLinhaPdf - 389, 468, Nil, ::aSeg[ "nApol" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )
   ::DrawBox( 468, ::nLinhaPdf - 398, 125, 015, ::nLarguraBox )
   ::DrawTexto( 473, ::nLinhaPdf - 383, 590, Nil, "N�mero da Averba��o", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 7 )
   ::DrawTexto( 473, ::nLinhaPdf - 389, 590, Nil, ::aSeg[ "nAver" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 7 )

   // Box dos Componentes do Valor da Presta��o do Servi�o
   ::DrawBox( 003, ::nLinhaPdf - 410, 590, 009, ::nLarguraBox )
   ::DrawTexto( 003, ::nLinhaPdf - 400, 590, Nil, "Componentes do Valor da Presta��o do Servi�o", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   // Box de Servicos e Valores
   ::DrawBox( 003, ::nLinhaPdf - 475, 165, 062, ::nLarguraBox )
   ::DrawTexto( 005, ::nLinhaPdf - 413, 085, Nil, "Nome", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 085, ::nLinhaPdf - 413, 165, Nil, "Valor", HPDF_TALIGN_RIGHT, ::oPDFFontNormal, 8 )
   ::DrawBox( 168, ::nLinhaPdf - 475, 165, 062, ::nLarguraBox )
   ::DrawTexto( 171, ::nLinhaPdf - 413, 251, Nil, "Nome", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 251, ::nLinhaPdf - 413, 330, Nil, "Valor", HPDF_TALIGN_RIGHT, ::oPDFFontNormal, 8 )
   ::DrawBox( 333, ::nLinhaPdf - 475, 165, 062, ::nLarguraBox )
   ::DrawTexto( 338, ::nLinhaPdf - 413, 418, Nil, "Nome", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ::DrawTexto( 418, ::nLinhaPdf - 413, 495, Nil, "Valor", HPDF_TALIGN_RIGHT, ::oPDFFontNormal, 8 )
   ::DrawBox( 498, ::nLinhaPdf - 444, 095, 031, ::nLarguraBox )
   ::DrawTexto( 498, ::nLinhaPdf - 417, 590, Nil, "Valor Total do Servi�o", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   ::DrawTexto( 498, ::nLinhaPdf - 427, 580, Nil, Transform( Val( ::aPrest[ "vTPrest" ] ), '@E 999,999.99' ), HPDF_TALIGN_RIGHT, ::oPDFFontBold, 12 )
   ::DrawBox( 498, ::nLinhaPdf - 475, 095, 031, ::nLarguraBox )
   ::DrawTexto( 498, ::nLinhaPdf - 447, 590, Nil, "Valor a Receber", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   ::DrawTexto( 498, ::nLinhaPdf - 457, 580, Nil, Transform( Val( ::aPrest[ "vRec" ] ), '@E 999,999.99' ), HPDF_TALIGN_RIGHT, ::oPDFFontBold, 12 )

   nLinha := 423
   FOR nCont = 1 TO Len( ::aComp ) STEP 3
      ::DrawTexto( 005, ::nLinhaPdf - nLinha, 165, Nil, ::aComp[ nCont, 1 ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
      ::DrawTexto( 085, ::nLinhaPdf - nlinha, 165, Nil, Transform( Val( ::aComp[ nCont, 2 ] ), '@E 999,999.99' ), HPDF_TALIGN_RIGHT, ::oPDFFontBold, 8 )

      ::DrawTexto( 171, ::nLinhaPdf - nLinha, 251, Nil, ::aComp[ nCont + 1, 1 ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
      ::DrawTexto( 251, ::nLinhaPdf - nLinha, 330, Nil, Transform( Val( ::aComp[ nCont + 1, 2 ] ), '@E 999,999.99' ), HPDF_TALIGN_RIGHT, ::oPDFFontBold, 8 )

      ::DrawTexto( 338, ::nLinhaPdf - nLinha, 418, Nil, ::aComp[ nCont + 2, 1 ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
      ::DrawTexto( 418, ::nLinhaPdf - nLinha, 495, Nil, Transform( Val( ::aComp[ nCont + 2, 2 ] ), '@E 999,999.99' ), HPDF_TALIGN_RIGHT, ::oPDFFontBold, 8 )
      nLinha += 10
   NEXT

   // Box das Informa��es Relativas ao Imposto
   ::DrawBox( 003, ::nLinhaPdf - 487, 590, 009, ::nLarguraBox )
   ::DrawTexto( 003, ::nLinhaPdf - 478, 590, Nil, "Informa��es Relativas ao Imposto", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   DO CASE
   CASE ! Empty( ::aIcmsSN[ "indSN" ] )
      cTexto := "SIMPLES NACIONAL"
   CASE ! Empty( ::aIcms00[ "CST" ] )
      cTexto := "00 - Tributa��o normal do ICMS"
      nBase := ::aIcms00[ "vBC" ]
      nAliq := ::aIcms00[ "pICMS" ]
      nValor := ::aIcms00[ "vICMS" ]
      nReduc := ''
      nST := ''
   CASE ! Empty( ::aIcms20[ "CST" ] )
      cTexto := "20 - Tributa��o com BC reduzida do ICMS"
      nBase := ::aIcms20[ "vBC" ]
      nAliq := ::aIcms20[ "pICMS" ]
      nValor := ::aIcms20[ "vICMS" ]
      nReduc := ::aIcms20[ "pRedBC" ]
      nST := ''
   CASE ! Empty( ::aIcms45[ "CST" ] )
      IF ::aIcms45[ "CST" ] = '40'
         cTexto := "40 - ICMS isen��o"
      ELSEIF ::aIcms45[ "CST" ] = '41'
         cTexto := "41 - ICMS n�o tributada"
      ELSEIF ::aIcms45[ "CST" ] = '51'
         cTexto := "51 - ICMS diferido"
      ENDIF
   CASE ! Empty( ::aIcms60[ "CST" ] )
      cTexto := "60 - ICMS cobrado anteriormente por substitui��o tribut�ria"
      nBase := ::aIcms60[ "vBCSTRet" ]
      nAliq := ::aIcms60[ "pICMSSTRet" ]
      nValor := ::aIcms60[ "vICMSSTRet" ]
      nReduc := ''
      nST := ::aIcms60[ "vCred" ]
   CASE ! Empty( ::aIcms90[ "CST" ] )
      cTexto := "90 - ICMS Outros"
      nBase := ::aIcms60[ "vBC" ]
      nAliq := ::aIcms60[ "pICMS" ]
      nValor := ::aIcms60[ "vICMS" ]
      nReduc := ::aIcms90[ "pRedBC" ]
      nST := ::aIcms60[ "vCred" ]
   CASE ! Empty( ::aIcmsUF[ "CST" ] )
      cTexto := "90 - ICMS Outros"
      nBase := ::aIcmsUF[ "vBCOutraUF" ]
      nAliq := ::aIcmsUF[ "pICMSOutraUF" ]
      nValor := ::aIcmsUF[ "vICMSOutraUF" ]
      nReduc := ::aIcmsUF[ "pRedBCOutraUF" ]
      nST := ''
   OTHERWISE
      cTexto := "Sem Imposto de ICMS"
   ENDCASE
   ::DrawBoxTituloTexto( 003, ::nLinhaPdf - 487, 155, 027, "Situa��o Tribut�ria", cTexto, HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
   ::DrawBoxTituloTexto( 158, ::nLinhaPdf - 487, 080, 027, "Base De Calculo", Transform( Val( nBase ), '@E 999,999.99' ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
   ::DrawBoxTituloTexto( 238, ::nLinhaPdf - 487, 080, 027, "Al�q ICMS", Transform( Val( nAliq ), '@E 999,999.99' ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
   ::DrawBoxTituloTexto( 318, ::nLinhaPdf - 487, 080, 027, "Valor ICMS", Transform( Val( nValor ), '@E 999,999.99' ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
   ::DrawBoxTituloTexto( 398, ::nLinhaPdf - 487, 080, 027, "% Red. BC ICMS", Transform( Val( nReduc ), '@E 999,999.99' ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
   ::DrawBoxTituloTexto( 478, ::nLinhaPdf - 487, 115, 027, "ICMS ST", Transform( Val( nSt ), '@E 999,999.99' ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )

   // Box dos Documentos Origin�rios
   ::DrawBox( 003, ::nLinhaPdf - 526, 590, 009, ::nLarguraBox )
   ::DrawTexto( 003, ::nLinhaPdf - 517, 590, Nil, "Documentos Origin�rios", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   // Box dos documentos a esquerda
   ::DrawBox( 003, ::nLinhaPdf - 626, 295, 100, ::nLarguraBox )
   ::DrawTexto( 005, ::nLinhaPdf - 526, 050, Nil, "Tipo DOC", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   IF Len( ::aInfNF ) > 0
      ::DrawTexto( 050, ::nLinhaPdf - 526, 240, Nil, "CNPJ/CPF Emitente", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ELSEIF Len( ::aInfOutros ) > 0
      ::DrawTexto( 170, ::nLinhaPdf - 526, 240, Nil, "CNPJ/CPF Emitente", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ELSEIF Len( ::aInfNFe ) > 0
      ::DrawTexto( 050, ::nLinhaPdf - 526, 240, Nil, "CHAVE DE ACESSO DA NF-e", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ELSE
      ::DrawTexto( 050, ::nLinhaPdf - 526, 240, Nil, "CNPJ/CPF Emitente", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ENDIF
   ::DrawTexto( 240, ::nLinhaPdf - 526, 295, Nil, "S�rie/Nro. Doc.", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )

   // Box dos documentos a direita
   ::DrawBox( 298, ::nLinhaPdf - 626, 295, 100, ::nLarguraBox )
   ::DrawTexto( 300, ::nLinhaPdf - 526, 345, Nil, "Tipo DOC", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   IF Len( ::aInfNF ) > 0
      ::DrawTexto( 345, ::nLinhaPdf - 526, 535, Nil, "CNPJ/CPF Emitente", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ELSEIF Len( ::aInfOutros ) > 0
      ::DrawTexto( 465, ::nLinhaPdf - 526, 535, Nil, "CNPJ/CPF Emitente", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ELSEIF Len( ::aInfNFe ) > 0
      ::DrawTexto( 345, ::nLinhaPdf - 526, 535, Nil, "CHAVE DE ACESSO DA NF-e", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ELSE
      ::DrawTexto( 345, ::nLinhaPdf - 526, 535, Nil, "CNPJ/CPF Emitente", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   ENDIF
   ::DrawTexto( 535, ::nLinhaPdf - 526, 590, Nil, "S�rie/Nro. Doc.", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )

   IF Len( ::aInfNFe ) > 0
      nLinha := 536
      FOR nCont = 1 TO Len( ::aInfNFe ) STEP 2
         IF ! Empty( ::aInfNFe[ nCont, 1 ] )
            ::DrawTexto( 005, ::nLinhaPdf - nLinha, 353, Nil, "NF-E", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
            ::DrawTexto( 050, ::nLinhaPdf - nLinha, 240, Nil, ::aInfNFe[ nCont, 1 ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
            ::DrawTexto( 240, ::nLinhaPdf - nLinha, 295, Nil, SubStr( ::aInfNFe[ nCont, 1 ], 23, 3 ) + '/' + SubStr( ::aInfNFe[ nCont, 1 ], 26, 9 ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
         ENDIF
         IF nCont + 1 <= Len( ::aInfNFe )
            ::DrawTexto( 300, ::nLinhaPdf - nLinha, 353, Nil, "NF-E", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
            ::DrawTexto( 345, ::nLinhaPdf - nLinha, 535, Nil, ::aInfNFe[ nCont + 1, 1 ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
            ::DrawTexto( 535, ::nLinhaPdf - nLinha, 590, Nil, SubStr( ::aInfNFe[ nCont + 1, 1 ], 23, 3 ) + '/' + SubStr( ::aInfNFe[ nCont + 1, 1 ], 26, 9 ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
         ENDIF
         nLinha += 10
      NEXT
   ENDIF

   IF Len( ::aInfNF ) > 0
      nLinha := 536
      FOR nCont = 1 TO Len( ::aInfNF ) STEP 2
         IF !Empty( ::aInfNF[ nCont, 4 ] )
            ::DrawTexto( 005, ::nLinhaPdf - nLinha - 2, 353, Nil, "NOTA FISCAL", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 6 )
            IF Val( ::aRem[ "CNPJ" ] ) > 0
               ::DrawTexto( 050, ::nLinhaPdf - nLinha, 240, Nil, TRANSF( ::aRem[ "CNPJ" ], "@R 99.999.999/9999-99" ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
            ENDIF
            IF Val( ::aRem[ "CPF" ] ) > 0
               ::DrawTexto( 050, ::nLinhaPdf - nLinha, 240, Nil, TRANSF( ::aRem[ "CPF" ], "@R 999.999.999-99" ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
            ENDIF
            ::DrawTexto( 240, ::nLinhaPdf - nLinha, 295, Nil, ::aInfNF[ nCont, 4 ] + '/' + ::aInfNF[ nCont, 5 ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
         ENDIF
         IF nCont + 1 <= Len( ::aINfNF )
            ::DrawTexto( 300, ::nLinhaPdf - nLinha - 2, 353, Nil, "NOTA FISCAL", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 6 )
            IF Val( ::aRem[ "CNPJ" ] ) > 0
               ::DrawTexto( 345, ::nLinhaPdf - nLinha, 535, Nil, TRANSF( ::aRem[ "CNPJ" ], "@R 99.999.999/9999-99" ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
            ENDIF
            IF Val( ::aRem[ "CPF" ] ) > 0
               ::DrawTexto( 345, ::nLinhaPdf - nLinha, 535, Nil, TRANSF( ::aRem[ "CPF" ], "@R 999.999.999-99" ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
            ENDIF
            ::DrawTexto( 535, ::nLinhaPdf - nLinha, 590, Nil, ::aInfNF[ nCont + 1, 4 ] + '/' + ::aInfNF[ nCont + 1, 5 ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
         ENDIF
         nLinha += 10
      NEXT
   ENDIF
   IF Len( ::aInfOutros ) > 0
      nLinha := 536
      FOR nCont = 1 TO Len( ::aInfOutros ) STEP 2
         If ::aInfOutros[ nCont, 1 ] = '00'
            cOutros := 'DECLARA��O'
         ElseIf ::aInfOutros[ nCont, 1 ] = '10'
            cOutros := 'DUTOVI�RIO'
         ElseIf ::aInfOutros[ nCont, 1 ] = '99'
            cOutros := ::aInfOutros[ nCont, 2 ]
         ENDIF
         ::DrawTexto( 005, ::nLinhaPdf - nLinha, 240, Nil, cOutros, HPDF_TALIGN_LEFT, ::oPDFFontNormal, 6 )
         IF Val( ::aRem[ "CNPJ" ] ) > 0
            ::DrawTexto( 170, ::nLinhaPdf - nLinha, 240, Nil, TRANSF( ::aRem[ "CNPJ" ], "@R 99.999.999/9999-99" ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
         ENDIF
         IF Val( ::aRem[ "CPF" ] ) > 0
            ::DrawTexto( 170, ::nLinhaPdf - nLinha, 240, Nil, TRANSF( ::aRem[ "CPF" ], "@R 999.999.999-99" ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
         ENDIF
         ::DrawTexto( 240, ::nLinhaPdf - nLinha, 295, Nil, ::aInfOutros[ nCont, 3 ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
         IF nCont + 1 <= Len( ::aInfOutros )
            If ::aInfOutros[ nCont + 1, 1 ] = '00'
               cOutros := 'DECLARA��O'
            ElseIf ::aInfOutros[ nCont + 1, 1 ] = '10'
               cOutros := 'DUTOVI�RIO'
            ElseIf ::aInfOutros[ nCont + 1, 1 ] = '99'
               cOutros := ::aInfOutros[ nCont + 1, 2 ]
            ENDIF
            ::DrawTexto( 300, ::nLinhaPdf - nLinha, 535, Nil, cOutros, HPDF_TALIGN_LEFT, ::oPDFFontNormal, 6 )
            IF Val( ::aRem[ "CNPJ" ] ) > 0
               ::DrawTexto( 465, ::nLinhaPdf - nLinha, 535, Nil, TRANSF( ::aRem[ "CNPJ" ], "@R 99.999.999/9999-99" ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
            ENDIF
            IF Val( ::aRem[ "CPF" ] ) > 0
               ::DrawTexto( 465, ::nLinhaPdf - nLinha, 535, Nil, TRANSF( ::aRem[ "CPF" ], "@R 999.999.999-99" ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
            ENDIF
            ::DrawTexto( 535, ::nLinhaPdf - nLinha, 590, Nil, ::aInfOutros[ nCont + 1, 3 ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
         ENDIF
         nLinha += 10
      NEXT
   ENDIF

   // Box das Observa��es Gerais
   ::DrawBox( 003, ::nLinhaPdf - 638, 590, 009, ::nLarguraBox )
   ::DrawTexto( 003, ::nLinhaPdf - 629, 590, Nil, "Observa��es Gerais", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   ::DrawBox( 003, ::nLinhaPdf - 668, 590, 030, ::nLarguraBox )
   /*
   ::aCompl[ "xObs" ]:=Upper('Este documento tem por objetivo a defini��o das especifica��es e crit�rios t�cnicos necess�rios' +;
   ' para a integra��o entre os Portais das Secretarias de Fazendas dos Estados e os sistemas de' +;
   ' informa��es das empresas emissoras de Conhecimento de Transporte eletr�nico - CT-e.')
   */
   IF ! Empty( ::aCompl[ "xObs" ] )
      AAdd( aObserv, ::aCompl[ "xObs" ] )
   ENDIF
   IF ! Empty( ::cAdFisco )
      AAdd( aObserv, ::cAdFisco )
   ENDIF
   If ! Empty( ::alocEnt[ 'xNome' ] )
      cEntrega := 'Local de Entrega : '
      If ! Empty( ::alocEnt[ "CNPJ" ] )
         cEntrega += 'CNPJ:' + ::alocEnt[ "CNPJ" ]
      ENDIF
      If ! Empty( ::alocEnt[ "CNPJ" ] )
         cEntrega += 'CPF:' + ::alocEnt[ "CPF" ]
      ENDIF
      If ! Empty( ::alocEnt[ "xNome" ] )
         cEntrega += ' - ' + ::alocEnt[ "xNome" ]
      ENDIF
      If ! Empty( ::alocEnt[ "xLgr" ] )
         cEntrega += ' - ' + ::alocEnt[ "xLgr" ]
      ENDIF
      If ! Empty( ::alocEnt[ "nro" ] )
         cEntrega += ',' + ::alocEnt[ "nro" ]
      ENDIF
      If ! Empty( ::alocEnt[ "xCpl" ] )
         cEntrega += ::alocEnt[ "xCpl" ]
      ENDIF
      If ! Empty( ::alocEnt[ "xBairro" ] )
         cEntrega += ::alocEnt[ "xBairro" ]
      ENDIF
      If ! Empty( ::alocEnt[ "xMun" ] )
         cEntrega += ::alocEnt[ "xMun" ]
      ENDIF
      If ! Empty( ::alocEnt[ "UF" ] )
         cEntrega += ::alocEnt[ "UF" ]
      ENDIF
      AAdd( aObserv, cEntrega )
   ENDIF
   nLinha := 638
   FOR EACH oElement IN aObserv
      DO WHILE Len( oElement ) > 0
         ::DrawTexto( 005, ::nLinhaPdf - nLinha, 590, Nil, Pad( oElement, 120 ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
         oElement := SubStr( oElement, 121 )
         nLinha += 10
      ENDDO
   NEXT
   /*
   If ! Empty( ::vTotTrib )
    ::DrawTexto( 005 , ::nLinhaPdf-675 , 590, Nil, 'Valor aproximado total de tributos federais, estaduais e municipais conf. Disposto na Lei n� 12741/12 : R$ '+Alltrim(Transform( Val(::vTotTrib) , '@E 999,999.99' )) , HPDF_TALIGN_LEFT , ::oPDFFontBold, 8 )
   Endif
   */
   // Box dos DADOS ESPEC�FICOS DO MODAL RODOVI�RIO - CARGA FRACIONADA
   ::DrawBox( 003, ::nLinhaPdf - 680, 590, 009, ::nLarguraBox )
   ::DrawTexto( 003, ::nLinhaPdf - 671, 590, Nil, "DADOS ESPEC�FICOS DO MODAL RODOVI�RIO - CARGA FRACIONADA", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   // Box do RNTRC Da Empresa
   ::DrawBoxTituloTexto( 003, ::nLinhaPdf - 680, 140, 018, "RNTRC Da Empresa", ::aRodo[ "RNTRC" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
   // Box do CIOT
   ::DrawBoxTituloTexto( 143, ::nLinhaPdf - 680, 070, 018, "CIOT", ::aRodo[ "CIOT" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
   // Box do Lota��o
   ::DrawBoxTituloTexto( 213, ::nLinhaPdf - 680, 030, 018, "Lota��o", iif( Val( ::aRodo[ "lota" ] ) = 0, 'N�o', 'Sim' ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
   // Box do Data Prevista de Entrega
   ::DrawBoxTituloTexto( 243, ::nLinhaPdf - 680, 115, 018, "Data Prevista de Entrega", SubStr( ::aRodo[ "dPrev" ], 9, 2 ) + "/" + SubStr( ::aRodo[ "dPrev" ], 6, 2 ) + "/" + SubStr( ::aRodo[ "dPrev" ], 1, 4 ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
   // Box da Legisla��o
   ::DrawBox( 358, ::nLinhaPdf - 698, 235, 018, ::nLarguraBox )
   ::DrawTexto( 360, ::nLinhaPdf - 680, 590, Nil, "ESTE CONHECIMENTO DE TRANSPORTE ATENDE", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   ::DrawTexto( 360, ::nLinhaPdf - 688, 590, Nil, "� LEGISLA��O DE TRANSPORTE RODOVI�RIO EM VIGOR", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )

   // Box da IDENTIFICA��O DO CONJUNTO TRANSPORTADOR
   ::DrawBox( 003, ::nLinhaPdf - 706, 260, 008, ::nLarguraBox )
   ::DrawTexto( 003, ::nLinhaPdf - 698, 260, Nil, "IDENTIFICA��O DO CONJUNTO TRANSPORTADOR", HPDF_TALIGN_CENTER, ::oPDFFontBold, 6 )
   // Box das INFORMA��ES RELATIVAS AO VALE PED�GIO
   ::DrawBox( 263, ::nLinhaPdf - 706, 330, 008, ::nLarguraBox )
   ::DrawTexto( 263, ::nLinhaPdf - 698, 590, Nil, "INFORMA��ES RELATIVAS AO VALE PED�GIO", HPDF_TALIGN_CENTER, ::oPDFFontBold, 6 )

   // Box do Tipo
   ::DrawBox( 003, ::nLinhaPdf - 714, 055, 008, ::nLarguraBox )
   ::DrawTexto( 005, ::nLinhaPdf - 707, 055, Nil, "TIPO", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 6 )
   // Box do PLACA
   ::DrawBox( 058, ::nLinhaPdf - 714, 055, 008, ::nLarguraBox )
   ::DrawTexto( 060, ::nLinhaPdf - 707, 115, Nil, "PLACA", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 6 )
   // Box da UF
   ::DrawBox( 113, ::nLinhaPdf - 714, 020, 008, ::nLarguraBox )
   ::DrawTexto( 115, ::nLinhaPdf - 707, 133, Nil, "UF", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 6 )
   // Box da RNTRC
   ::DrawBox( 133, ::nLinhaPdf - 714, 130, 008, ::nLarguraBox )
   ::DrawTexto( 135, ::nLinhaPdf - 707, 260, Nil, "RNTRC", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 6 )
   // Box dos Dados acima
   ::DrawBox( 003, ::nLinhaPdf - 736, 260, 022, ::nLarguraBox )
   nLinha := 714
   FOR nCont = 1 TO Len( ::aVeiculo )
      ::DrawTexto( 005, ::nLinhaPdf - nLinha, 055, Nil, aTipoCar[ Val( ::aVeiculo[ nCont, 10 ] ) + 1 ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 6 )
      ::DrawTexto( 060, ::nLinhaPdf - nlinha, 115, Nil, ::aVeiculo[ nCont, 03 ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 6 )
      ::DrawTexto( 115, ::nLinhaPdf - nlinha, 133, Nil, ::aVeiculo[ nCont, 11 ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 6 )
      ::DrawTexto( 135, ::nLinhaPdf - nlinha, 260, Nil, ::aProp[ "RNTRC" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 6 )
      ::DrawTexto( 135, ::nLinhaPdf - nlinha, 260, Nil, ::aRodo[ "RNTRC" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 6 )
      nLinha += 05
   NEXT

   // Box do CNPJ EMPRESA FORNECEDORA
   ::DrawBox( 263, ::nLinhaPdf - 736, 110, 030, ::nLarguraBox )
   ::DrawTexto( 265, ::nLinhaPdf - 707, 373, Nil, "CNPJ EMPRESA FORNECEDORA", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 6 )
   ::DrawTexto( 265, ::nLinhaPdf - 717, 373, Nil, ::aValePed[ "CNPJForn" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
   // Box do CNPJ EMPRESA FORNECEDORA
   ::DrawBox( 373, ::nLinhaPdf - 736, 110, 030, ::nLarguraBox )
   ::DrawTexto( 375, ::nLinhaPdf - 707, 483, Nil, "N�MERO DO COMPROVANTE", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 6 )
   ::DrawTexto( 375, ::nLinhaPdf - 717, 483, Nil, ::aValePed[ "nCompra" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
   // Box do CNPJ RESPONSAVEL PAGAMENTO
   ::DrawBox( 483, ::nLinhaPdf - 736, 110, 030, ::nLarguraBox )
   ::DrawTexto( 485, ::nLinhaPdf - 707, 590, Nil, "CNPJ RESPONSAVEL PAGAMENTO", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 6 )
   ::DrawTexto( 375, ::nLinhaPdf - 717, 483, Nil, ::aValePed[ "CNPJPg" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
   // Box do Nome do Motorista
   ::DrawBox( 003, ::nLinhaPdf - 744, 260, 008, ::nLarguraBox )
   ::DrawTexto( 005, ::nLinhaPdf - 737, 050, Nil, "MOTORISTA:", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 6 )
   ::DrawTexto( 060, ::nLinhaPdf - 737, 260, Nil, ::aMoto[ "xNome" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 6 )
   // Box do CPF do Motorista
   ::DrawBox( 263, ::nLinhaPdf - 744, 120, 008, ::nLarguraBox )
   ::DrawTexto( 265, ::nLinhaPdf - 737, 325, Nil, "CPF MOTORISTA:", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 6 )
   ::DrawTexto( 330, ::nLinhaPdf - 737, 383, Nil, Transform( ::aMoto[ "CPF" ], "@R 999.999.999-99" ), HPDF_TALIGN_LEFT, ::oPDFFontBold, 6 )
   // Box do IDENT. LACRE EM TRANSP:
   ::DrawBox( 383, ::nLinhaPdf - 744, 210, 008, ::nLarguraBox )
   ::DrawTexto( 385, ::nLinhaPdf - 737, 495, Nil, "IDENT. LACRE EM TRANSP.", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 6 )
   ::DrawTexto( 500, ::nLinhaPdf - 737, 590, Nil, ::aRodo[ "nLacre" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 6 )
   // Box do USO EXCLUSIVO DO EMISSOR DO CT-E
   ::DrawBox( 003, ::nLinhaPdf - 752, 380, 008, ::nLarguraBox )
   ::DrawTexto( 005, ::nLinhaPdf - 745, 385, Nil, "USO EXCLUSIVO DO EMISSOR DO CT-E", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 6 )
   ::DrawTexto( 005, ::nLinhaPdf - 753, 385, Nil, ::aObsCont[ "xTexto" ], HPDF_TALIGN_LEFT, ::oPDFFontBold, 8 )
   // Box do RESERVADO AO FISCO
   ::DrawBox( 383, ::nLinhaPdf - 752, 210, 008, ::nLarguraBox )
   ::DrawTexto( 385, ::nLinhaPdf - 745, 495, Nil, "RESERVADO AO FISCO", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 6 )

   ::DrawBox( 003, ::nLinhaPdf - 762, 380, 010, ::nLarguraBox )
   ::DrawBox( 383, ::nLinhaPdf - 762, 210, 010, ::nLarguraBox )

   ::Desenvolvedor( 77 )

   // linha tracejada
   HPDF_Page_SetDash( ::oPdfPage, DASH_MODE3, 4, 0 )
   HPDF_Page_SetLineWidth( ::oPdfPage, 0.5 )
   HPDF_Page_MoveTo( ::oPdfPage, 003, ::nLinhaPdf - 769 )
   HPDF_Page_LineTo( ::oPdfPage, 595, ::nLinhaPdf - 769 )
   HPDF_Page_Stroke( ::oPdfPage )
   HPDF_Page_SetDash( ::oPdfPage, NIL, 0, 0 )

   cMensa := 'DECLARO QUE RECEBI OS VOLUMES DESTE CONHECIMENTO EM PERFEITO ESTADO PELO QUE DOU POR CUMPRIDO O PRESENTE CONTRATO DE TRANSPORTE'
   ::DrawBox( 003, ::nLinhaPdf - 782, 590, 009, ::nLarguraBox )
   ::DrawTexto( 003, ::nLinhaPdf - 773, 590, Nil, cMensa, HPDF_TALIGN_CENTER, ::oPDFFontBold, 7 )
   // Box do Nome
   ::DrawBox( 003, ::nLinhaPdf - 807, 160, 025, ::nLarguraBox )
   ::DrawTexto( 005, ::nLinhaPdf - 782, 163, Nil, "Nome", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   // Box do RG
   ::DrawBox( 003, ::nLinhaPdf - 832, 160, 025, ::nLarguraBox )
   ::DrawTexto( 005, ::nLinhaPdf - 807, 163, Nil, "RG", HPDF_TALIGN_LEFT, ::oPDFFontNormal, 8 )
   // Box da ASSINATURA / CARIMBO
   ::DrawBox( 163, ::nLinhaPdf - 832, 160, 050, ::nLarguraBox )
   ::DrawTexto( 165, ::nLinhaPdf - 822, 323, Nil, "ASSINATURA / CARIMBO", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   // Box da CHEGADA DATA/HORA
   ::DrawBox( 323, ::nLinhaPdf - 807, 120, 025, ::nLarguraBox )
   ::DrawTexto( 325, ::nLinhaPdf - 782, 443, Nil, "CHEGADA DATA/HORA", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 6 )
   // Box da SA�DA DATA/HORA
   ::DrawBox( 323, ::nLinhaPdf - 832, 120, 025, ::nLarguraBox )
   ::DrawTexto( 325, ::nLinhaPdf - 807, 443, Nil, "SA�DA DATA/HORA", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 6 )
   // Box do N�mero da CTe / S�rie
   ::DrawBox( 443, ::nLinhaPdf - 807, 150, 025, ::nLarguraBox )
   ::DrawTexto( 445, ::nLinhaPdf - 782, 593, Nil, "N�mero da CTe / S�rie", HPDF_TALIGN_CENTER, ::oPDFFontNormal, 8 )
   ::DrawTexto( 445, ::nLinhaPdf - 792, 593, Nil, ::aIde[ "nCT" ] + ' / ' + ::aIde[ "serie" ], HPDF_TALIGN_CENTER, ::oPDFFontBold, 10 )
   // Box do nome do emitente
   ::DrawBox( 443, ::nLinhaPdf - 832, 150, 025, ::nLarguraBox )
   // Razao Social do Emitente
   IF Len( ::aEmit[ "xNome" ] ) <= 40
      ::DrawTexto( 445, ::nLinhaPdf - 813, 593, Nil, SubStr( ::aEmit[ "xNome" ], 1, 20 ), HPDF_TALIGN_CENTER, ::oPDFFontBold, 8 )
      ::DrawTexto( 445, ::nLinhaPdf - 820, 593, Nil, SubStr( ::aEmit[ "xNome" ], 21, 20 ), HPDF_TALIGN_CENTER, ::oPDFFontBold, 8 )
   ELSE
      ::DrawTexto( 445, ::nLinhaPdf - 808, 593, Nil, SubStr( ::aEmit[ "xNome" ], 1, 30 ), HPDF_TALIGN_CENTER, ::oPDFFontBold, 6 )
      ::DrawTexto( 445, ::nLinhaPdf - 815, 593, Nil, SubStr( ::aEmit[ "xNome" ], 31, 30 ), HPDF_TALIGN_CENTER, ::oPDFFontBold, 6 )
      ::DrawTexto( 445, ::nLinhaPdf - 822, 593, Nil, SubStr( ::aEmit[ "xNome" ], 61, 30 ), HPDF_TALIGN_CENTER, ::oPDFFontBold, 6 )
   ENDIF

   RETURN NIL

