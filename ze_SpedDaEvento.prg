/*
ZE_SPEDDAEVENTO - Documento auxiliar de Eventos
Fontes originais do projeto hbnfe em https://github.com/fernandoathayde/hbnfe
*/

#include "common.ch"
#include "hbclass.ch"
#include "harupdf.ch"
#ifndef __XHARBOUR__
#include "hbwin.ch"
// #include "hbcompat.ch"
#endif
// #include "hbnfe.ch"
#define _LOGO_ESQUERDA        1
#define _LOGO_DIREITA         2
#define _LOGO_EXPANDIDO       3

CREATE CLASS hbnfeDaEvento INHERIT hbNFeDaGeral

   METHOD Execute( cXmlEvento, cXmlDocumento, cFilePDF )
   METHOD BuscaDadosXML()
   METHOD GeraPDF( cFilePDF )
   METHOD Cabecalho()
   METHOD Destinatario()
   METHOD Eventos()
   METHOD Rodape()

   VAR cTelefoneEmitente INIT ""
   VAR cSiteEmitente     INIT ""
   VAR cEmailEmitente    INIT ""
   VAR cXmlDocumento     INIT ""
   VAR cXmlEvento
   VAR cChaveNFe
   VAR cChaveEvento
   VAR cDesenvolvedor    INIT ""

   VAR aCorrecoes
   VAR aInfEvento
   VAR aIde
   VAR aEmit
   VAR aDest

   VAR cFonteEvento      INIT "Times"
   VAR cFonteCorrecoes   INIT "Courier"
   VAR cFonteCode128
   VAR cFonteCode128F
   VAR oPdf
   VAR oPdfPage
   VAR oPdfFontCabecalho
   VAR oPdfFontCabecalhoBold
   VAR oPdfFontCorrecoes
   VAR nLinhaPDF

   VAR nLarguraBox INIT 0.7
   VAR lLaser      INIT .T.
   VAR lPaisagem
   VAR cLogoFile  INIT ""
   VAR nLogoStyle INIT _LOGO_ESQUERDA // 1-esquerda, 2-direita, 3-expandido

   VAR cRetorno

ENDCLASS

METHOD Execute( cXmlEvento, cXmlDocumento, cFilePDF ) CLASS hbnfeDaEvento

   IF Empty( cXmlEvento )
      ::cRetorno := "N�o tem conte�do do XML da carta de corre��o"
      RETURN ::cRetorno
   ENDIF
   // IF Empty( cXmlDocumento )
   // ::cRetorno := "N�o tem conte�do do XML da nota"
   // RETURN ::cRetorno
   // ENDIF

   ::cXmlEvento   := cXmlEvento
   ::cChaveEvento := SubStr( ::cXmlEvento, At( "Id=", ::cXmlEvento ) + 3 + 9, 44 )

   IF ! Empty( cXmlDocumento )
      ::cXmlDocumento   := cXmlDocumento
      ::cChaveNFe := SubStr( ::cXmlDocumento, At( "Id=", ::cXmlDocumento ) + 3 + 4, 44 )
      IF ::cChaveEvento != ::cChaveNFe
         ::cRetorno := "Arquivos XML com Chaves diferentes. Chave Doc: " + ::cChaveNFe + " Chave Evento: " + ::cChaveEvento
         RETURN ::cRetorno
      ENDIF
   ENDIF

   IF ! ::BuscaDadosXML()
      RETURN ::cRetorno
   ENDIF

   IF ! ::GeraPDF( cFilePDF )
      ::cRetorno := "Problema ao gerar o PDF da Carta de Corre��o"
      RETURN ::cRetorno
   ENDIF
   ::cRetorno := "OK"

   RETURN ::cRetorno

METHOD BuscaDadosXML() CLASS hbnfeDaEvento

   ::aCorrecoes := XmlNode( ::cXmlEvento, "infEvento" )
   ::aCorrecoes := XmlNode( ::aCorrecoes , "evCCeCTe" )
   ::aCorrecoes := MultipleNodeToArray( ::aCorrecoes, "infCorrecao" )

   ::aInfEvento := XmlToHash( XmlNode( ::cXmlEvento, "infEvento" ), { "tpEvento", "nSeqEvento", "verEvento", "xCorrecao" } )
   ::aInfEvento[ "cOrgao" ] := Left( ::cChaveEvento, 2 )

   IF At( "retEventoCTe", ::cXmlEvento ) > 0
      ::aInfEvento := XmlToHash( XmlNode( ::cXmlEvento, "retEventoCTe" ), { "cStat", "xMotivo", "dhRegEvento", "nProt" }, ::aInfEvento )
   ELSE
      ::aInfEvento := XmlToHash( XmlNode( ::cXmlEvento, "retEvento" ), { "cStat", "xMotivo", "dhRegEvento", "nProt" }, ::aInfEvento )
   ENDIF
   ::aIde := hb_Hash()
   ::aIde[ "mod" ]   := SubStr( ::cChaveEvento, 21, 2 ) // XmlNode( cIde, "mod" )
   ::aIde[ "serie" ] := SubStr( ::cChaveEvento, 23, 3 ) // XmlNode( cIde, "serie" )
   ::aIde[ "nNF" ]   := SubStr( ::cChaveEvento, 26, 9 ) // XmlNode( cIde, "nNF" )
   ::aIde[ "dhEmi" ] := XmlNode( XmlNode( ::cXmlDocumento, "ide" ), "dhEmi" )

   ::aEmit := XmlToHash( XmlNode( ::cXmlDocumento, "emit" ), { "xNome", "xFant", "xLgr", "nro", "xBairro", "cMun", "xMun", "UF", "CEP", "fone", "IE" } )
   ::aEmit[ "CNPJ" ] := SubStr( ::cChaveEvento, 7, 14 )
   ::aEmit[ "xNome" ]   := XmlToString( ::aEmit[ "xNome" ] )
   ::cTelefoneEmitente := FormatTelefone( ::aEmit[ "fone" ] )

   ::aDest := XmlToHash( XmlNode( ::cXmlDocumento, "dest" ), { "CNPJ", "CPF", "xNome", "xLgr", "nro", "xBairro", "cMun", "xMun", "UF", "CEP", "fone", "IE" } )
   ::aDest[ "xNome" ] := XmlToString( ::aDest[ "xNome" ] )

   RETURN .T.

METHOD GeraPDF( cFilePDF ) CLASS hbNfeDaEvento

   LOCAL nAltura

   // criacao objeto pdf
   ::oPdf := HPDF_New()
   IF ::oPdf == NIL
      ::cRetorno := "Falha da cria��o do objeto PDF da Carta de Corre��o!"
      RETURN ::cRetorno
   ENDIF

   /* set compression mode */
   HPDF_SetCompressionMode( ::oPdf, HPDF_COMP_ALL )

   /* setando fonte */
   DO CASE
   CASE ::cFonteEvento == "Times" ;           ::oPdfFontCabecalho := HPDF_GetFont( ::oPdf, "Times-Roman",     "CP1252" ) ; ::oPdfFontCabecalhoBold := HPDF_GetFont( ::oPdf, "Times-Bold",          "CP1252" )
   CASE ::cFonteEvento == "Helvetica" ;       ::oPdfFontCabecalho := HPDF_GetFont( ::oPdf, "Helvetica",       "CP1252" ) ; ::oPdfFontCabecalhoBold := HPDF_GetFont( ::oPdf, "Helvetica-Bold",      "CP1252" )
   CASE ::cFonteEvento == "Courier-Oblique" ; ::oPdfFontCabecalho := HPDF_GetFont( ::oPdf, "Courier-Oblique", "CP1252" ) ; ::oPdfFontCabecalhoBold := HPDF_GetFont( ::oPdf, "Courier-BoldOblique", "CP1252" )
   OTHERWISE ;                                ::oPdfFontCabecalho := HPDF_GetFont( ::oPdf, "Courier",         "CP1252" ) ; ::oPdfFontCabecalhoBold := HPDF_GetFont( ::oPdf, "Courier-Bold",        "CP1252" )
   ENDCASE

   DO CASE
   CASE ::cFonteCorrecoes == "Times" ;           ::oPdfFontCorrecoes := HPDF_GetFont( ::oPdf, "Times-Roman",     "CP1252" )
   CASE ::cFonteCorrecoes == "Helvetica" ;       ::oPdfFontCorrecoes := HPDF_GetFont( ::oPdf, "Helvetica",       "CP1252" )
   CASE ::cFonteCorrecoes == "Courier-Oblique" ; ::oPdfFontCorrecoes := HPDF_GetFont( ::oPdf, "Courier-Oblique", "CP1252" )
   CASE ::cFonteCorrecoes == "Courier-Bold" ;    ::oPdfFontCorrecoes := HPDF_GetFont( ::oPdf, "Courier-Bold",    "CP1252" )
   OTHERWISE ;                                   ::oPdfFontCorrecoes := HPDF_GetFont( ::oPdf, "Courier",         "CP1252" )
   ENDCASE

#ifdef __XHARBOUR__
   IF ! File( 'fontes\Code128bWinLarge.afm' ) .OR. ! File( 'fontes\Code128bWinLarge.pfb' )
      ::cRetorno := "Arquivos: fontes\Code128bWinLarge, nao encontrados"
      RETURN cRetorno
   ENDIF
   ::cFonteCode128  := HPDF_LoadType1FontFromFile( ::oPdf, 'fontes\Code128bWinLarge.afm', 'fontes\Code128bWinLarge.pfb' )   // Code 128
   ::cFonteCode128F := HPDF_GetFont( ::oPdf, ::cFonteCode128, "WinAnsiEncoding" )
#endif

   // final da criacao e definicao do objeto pdf

   ::oPdfPage := HPDF_AddPage( ::oPdf )

   HPDF_Page_SetSize( ::oPdfPage, HPDF_PAGE_SIZE_A4, HPDF_PAGE_PORTRAIT )
   nAltura := HPDF_Page_GetHeight( ::oPdfPage )    // = 841,89
   // ///////////////////nLargura := HPDF_Page_GetWidth( ::oPdfPage )    &&  = 595,28

   ::nLinhaPdf := nAltura -25   // Margem Superior

   // ///////////////////nAngulo := 45                   /* A rotation of 45 degrees. */
   // //////////////////nRadiano := nAngulo / 180 * 3.141592 /* Calcurate the radian value. */

   ::Cabecalho()
   ::Destinatario()
   ::Eventos()
   ::Rodape()

   HPDF_SaveToFile( ::oPdf, cFilePDF )
   HPDF_Free( ::oPdf )

   RETURN .T.

METHOD Cabecalho() CLASS hbnfeDaEvento

   LOCAL oImage

   ::DrawBox( 30, ::nLinhaPDF -106,   535,  110, ::nLarguraBox )    // Quadro Cabe�alho

   // logo/dados empresa

   ::DrawBox( 290, ::nLinhaPDF -106,  275,  110, ::nLarguraBox )    // Quadro CC-e, Chave de Acesso e Codigo de Barras
   ::DrawTexto( 30, ::nLinhaPdf + 2,     274, Nil, "IDENTIFICA��O DO EMITENTE", HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 6 )
   // alert('nLogoStyle: ' + ::nLogoStyle +';_LOGO_ESQUERDA: ' + _LOGO_ESQUERDA)
   IF ::cLogoFile == NIL .OR. Empty( ::cLogoFile )
      ::DrawTexto( 30, ::nLinhaPDF -6,  289, Nil, Trim( MemoLine( ::aEmit[ "xNome" ], 30, 1 ) ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 14 )
      ::DrawTexto( 30, ::nLinhaPDF -20,  289, Nil, Trim( MemoLine( ::aEmit[ "xNome" ], 30, 2 ) ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 14 )
      ::DrawTexto( 30, ::nLinhaPDF -42,  289, Nil, ::aEmit[ "xLgr" ] + " " + ::aEmit[ "nro" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 10 )
      ::DrawTexto( 30, ::nLinhaPDF -52,  289, Nil, ::aEmit[ "xBairro" ] + " - " + Transform( ::aEmit[ "CEP" ], "@R 99999-999" ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 10 )
      ::DrawTexto( 30, ::nLinhaPDF -62,  289, Nil, ::aEmit[ "xMun" ] + " - " + ::aEmit[ "UF" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 10 )
      ::DrawTexto( 30, ::nLinhaPDF -72,  289, Nil, iif( Empty( ::cTelefoneEmitente ), "", "FONE: " + ::cTelefoneEmitente ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 10 )
      ::DrawTexto( 30, ::nLinhaPDF -82,  289, Nil, Trim( ::cSiteEmitente ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 10 )
      ::DrawTexto( 30, ::nLinhaPDF -92,  289, Nil, Trim( ::cEmailEmitente ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 10 )
   ELSE
      oImage := ::LoadJPEGImage( ::oPDF, ::cLogoFile )
      IF ::nLogoStyle = _LOGO_EXPANDIDO
         HPDF_Page_DrawImage( ::oPdfPage, oImage, 55, ::nLinhaPdf - ( 82 + 18 ), 218, 92 )
      ELSEIF ::nLogoStyle = _LOGO_ESQUERDA
         HPDF_Page_DrawImage( ::oPdfPage, oImage, 36, ::nLinhaPdf - ( 62 + 18 ), 62, 62 )
         ::DrawTexto( 100, ::nLinhaPDF -6,  289, Nil, Trim( MemoLine( ::aEmit[ "xNome" ], 30, 1 ) ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 10 )
         ::DrawTexto( 100, ::nLinhaPDF -20, 289, Nil, Trim( MemoLine( ::aEmit[ "xNome" ], 30, 2 ) ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 10 )
         ::DrawTexto( 100, ::nLinhaPDF -42,  289, Nil, ::aEmit[ "xLgr" ] + " " + ::aEmit[ "nro" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 8 )
         ::DrawTexto( 100, ::nLinhaPDF -52,  289, Nil, ::aEmit[ "xBairro" ] + " - " + Transform( ::aEmit[ "CEP" ], "@R 99999-999" ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 8 )
         ::DrawTexto( 100, ::nLinhaPDF -62,  289, Nil, ::aEmit[ "xMun" ] + " - " + ::aEmit[ "UF" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 8 )
         ::DrawTexto( 100, ::nLinhaPDF -72,  289, Nil, iif( Empty( ::cTelefoneEmitente ), "", "FONE: " + ::cTelefoneEmitente ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 8 )
         ::DrawTexto( 100, ::nLinhaPDF -82,  289, Nil, Trim( ::cSiteEmitente ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 8 )
         ::DrawTexto( 100, ::nLinhaPDF -92,  289, Nil, Trim( ::cEmailEmitente ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 8 )

      ELSEIF ::nLogoStyle = _LOGO_DIREITA
         HPDF_Page_DrawImage( ::oPdfPage, oImage, 220, ::nLinhaPdf - ( 62 + 18 ), 62, 62 )
         ::DrawTexto( 30, ::nLinhaPDF -6,  218, Nil, Trim( MemoLine( ::aEmit[ "xNome" ], 30, 1 ) ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 10 )
         ::DrawTexto( 30, ::nLinhaPDF -20, 218, Nil, Trim( MemoLine( ::aEmit[ "xNome" ], 30, 2 ) ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 10 )
         ::DrawTexto( 30, ::nLinhaPDF -42,  218, Nil, ::aEmit[ "xLgr" ] + " " + ::aEmit[ "nro" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 8 )
         ::DrawTexto( 30, ::nLinhaPDF -52,  218, Nil, ::aEmit[ "xBairro" ] + " - " + Transform( ::aEmit[ "CEP" ], "@R 99999-999" ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 8 )
         ::DrawTexto( 30, ::nLinhaPDF -62,  218, Nil, ::aEmit[ "xMun" ] + " - " + ::aEmit[ "UF" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 8 )
         ::DrawTexto( 30, ::nLinhaPDF -72,  218, Nil, iif( Empty( ::cTelefoneEmitente ), "", "FONE: " + ::cTelefoneEmitente ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 8 )
         ::DrawTexto( 30, ::nLinhaPDF -82,  218, Nil, Trim( ::cSiteEmitente ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 8 )
         ::DrawTexto( 30, ::nLinhaPDF -92,  218, Nil, Trim( ::cEmailEmitente ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 8 )
      ENDIF
   ENDIF

/*
      IF EMPTY( ::cLogoFile )
          ::DrawTexto( 71, ::nLinhaPdf   , 399, Nil, "IDENTIFICA��O DO EMITENTE" , HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 6 )
          ::DrawTexto( 71, ::nLinhaPDF - 6 , 399, Nil, TRIM( MemoLine( ::aEmit[ "xNome" ],30,1)) , HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 12 )
          ::DrawTexto( 71, ::nLinhaPDF - 18, 399, Nil, TRIM( MemoLine( ::aEmit[ "xNome" ],30,2)), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 12 )
          ::DrawTexto( 71, ::nLinhaPDF - 30, 399, Nil, ::aEmit[ "xLgr" ]+" "+::aEmit[ "nro" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 8 )
          ::DrawTexto( 71, ::nLinhaPDF - 38, 399, Nil, ::aEmit[ "xBairro" ]+" - "+ Transform( ::aEmit[ "CEP" ], "@R 99999-999"), HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 8 )
          ::DrawTexto( 71, ::nLinhaPDF - 46, 399, Nil, ::aEmit[ "xMun" ]+" - "+::aEmit[ "UF" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 8 )
          ::DrawTexto( 71, ::nLinhaPDF - 54, 399, Nil, IF( Empty(::cTelefoneEmitente),"", "FONE: "+::cTelefoneEmitente), HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 8 )
          ::DrawTexto( 71, ::nLinhaPDF - 62, 399, Nil, TRIM(::cSiteEmitente), HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 8 )
          ::DrawTexto( 71, ::nLinhaPDF - 70, 399, Nil, TRIM(::cEmailEmitente), HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 8 )
       ELSE
          IF ::nLogoStyle = _LOGO_EXPANDIDO
             oImage := ::LoadJPEGImage( ::oPDF, ::cLogoFile )
             HPDF_Page_DrawImage( ::oPdfPage, oImage, 6, ::nLinhaPdf - (72+6), 328, 72 )
          ELSEIF ::nLogoStyle = _LOGO_ESQUERDA
             oImage := ::LoadJPEGImage( ::oPDF, ::cLogoFile )
             HPDF_Page_DrawImage( ::oPdfPage, oImage,71, ::nLinhaPdf - (72+6), 62, 72 )
              ::DrawTexto( 135, ::nLinhaPDF - 6 , 399, Nil, TRIM( MemoLine( ::aEmit[ "xNome" ],30,1)) , HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 12 )
              ::DrawTexto( 135, ::nLinhaPDF - 18, 399, Nil, TRIM( MemoLine( ::aEmit[ "xNome" ],30,2)), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 12 )
              ::DrawTexto( 135, ::nLinhaPDF - 30, 399, Nil, ::aEmit[ "xLgr" ]+" "+::aEmit[ "nro" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 8 )
              ::DrawTexto( 135, ::nLinhaPDF - 38, 399, Nil, ::aEmit[ "xBairro" ]+" - "+ Transform( ::aEmit[ "CEP" ], "@R 99999-999"), HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 8 )
              ::DrawTexto( 135, ::nLinhaPDF - 46, 399, Nil, ::aEmit[ "xMun" ]+" - "+::aEmit[ "UF" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 8 )
              ::DrawTexto( 135, ::nLinhaPDF - 54, 399, Nil, IF( Empty(::cTelefoneEmitente),"","FONE: "+::cTelefoneEmitente), HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 8 )
              ::DrawTexto( 135, ::nLinhaPDF - 62, 399, Nil, TRIM(::cSiteEmitente), HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 8 )
              ::DrawTexto( 135, ::nLinhaPDF - 70, 399, Nil, TRIM(::cEmailEmitente), HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 8 )
          ELSEIF ::nLogoStyle = _LOGO_DIREITA
             oImage := ::LoadJPEGImage( ::oPDF, ::cLogoFile )
             HPDF_Page_DrawImage( ::oPdfPage, oImage,337, ::nLinhaPdf - (72+6), 62, 72 )
            ::DrawTexto( 71, ::nLinhaPDF - 6 , 335, Nil, TRIM( MemoLine( ::aEmit[ "xNome" ],30,1)) , HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 12 )
            ::DrawTexto( 71, ::nLinhaPDF - 18, 335, Nil, TRIM( MemoLine( ::aEmit[ "xNome" ],30,2)), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 12 )
            ::DrawTexto( 71, ::nLinhaPDF - 30, 335, Nil, ::aEmit[ "xLgr" ]+" "+::aEmit[ "nro" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 8 )
            ::DrawTexto( 71, ::nLinhaPDF - 38, 335, Nil, ::aEmit[ "xBairro" ]+" - "+ Transform( ::aEmit[ "CEP" ], "@R 99999-999"), HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 8 )
            ::DrawTexto( 71, ::nLinhaPDF - 46, 335, Nil, ::aEmit[ "xMun" ]+" - "+::aEmit[ "UF" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 8 )
            ::DrawTexto( 71, ::nLinhaPDF - 54, 335, Nil, IF( Empty(::cTelefoneEmitente),"","FONE: "+::cTelefoneEmitente), HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 8 )
            ::DrawTexto( 71, ::nLinhaPDF - 62, 335, Nil, TRIM(::cSiteEmitente), HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 8 )
            ::DrawTexto( 71, ::nLinhaPDF - 70, 335, Nil, TRIM(::cEmailEmitente), HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 8 )
           ENDIF
      ENDIF
*/

   IF ::aInfEvento[ "tpEvento" ] == "110110"
      ::DrawTexto( 292, ::nLinhaPDF -2, 554, Nil, "CC-e", HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 18 )
      ::DrawTexto( 296, ::nLinhaPDF -22, 554, Nil, "CARTA DE CORRE��O ELETR�NICA", HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 14 )
   ELSE
      ::DrawTexto( 292, ::nLinhaPDF -2, 554, Nil, "EVENTO", HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 18 )
      DO CASE
      CASE ::aInfEvento[ "tpEvento" ] == "110111"
         ::DrawTexto( 296, ::nLinhaPDF -22, 554, Nil, "CANCELAMENTO", HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 14 )
      OTHERWISE
         ::DrawTexto( 296, ::nLinhaPDF -22, 554, Nil, "EVENTO " + ::aInfEvento[ "tpEvento" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 14 )
      ENDCASE
   ENDIF

   // chave de acesso
   ::DrawBox( 290, ::nLinhaPDF -61,  275,  20, ::nLarguraBox )
   ::DrawTexto( 291, ::nLinhaPDF -42, 534, Nil, "CHAVE DE ACESSO", HPDF_TALIGN_LEFT, ::oPdfFontCabecalhoBold, 6 )
   IF ::cFonteEvento == "Times"
      ::DrawTexto( 292, ::nLinhaPDF -49, 554, Nil, Transform( ::cChaveEvento, "@R 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999" ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 10 )
   ELSE
      ::DrawTexto( 292, ::nLinhaPDF -50, 554, Nil, Transform( ::cChaveEvento, "@R 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999" ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 8 )
   ENDIF

   // codigo barras
#ifdef __XHARBOUR__
   ::DrawTexto( 291, ::nLinhaPDF -65, 555, Nil, hbnfe_CodificaCode128c( ::cChaveNFe ), HPDF_TALIGN_CENTER, Nil, ::cFonteCode128F, 18 )
#else
   ::DrawBarcode128( ::cChaveEvento, 300, ::nLinhaPDF -100, 0.9, 30 )
#endif

   ::nLinhaPdf -= 106

   // CNPJ
   ::DrawBox( 30, ::nLinhaPDF -20,   535,  20, ::nLarguraBox )    // Quadro CNPJ/INSCRI��O
   ::DrawTexto( 32, ::nLinhaPdf,      160, Nil, "CNPJ", HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 6 )
   ::DrawTexto( 31, ::nLinhaPDF -6,    160, Nil, Transform( ::aEmit[ "CNPJ" ], "@R 99.999.999/9999-99" ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 11 )

   // I.E.
   ::DrawBox( 160, ::nLinhaPDF -20,  130,  20, ::nLarguraBox )    // Quadro INSCRI��O
   ::DrawTexto( 162, ::nLinhaPdf,     290, Nil, "INSCRI��O ESTADUAL", HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 6 )
   ::DrawTexto( 161, ::nLinhaPDF -6,   290, Nil, ::aEmit[ "IE" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 11 )

   // MODELO DO DOCUMENTO (NF-E)
   ::DrawTexto( 291, ::nLinhaPdf,     340, Nil, "MODELO", HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 6 )
   ::DrawTexto( 291, ::nLinhaPDF -6,   340, Nil, ::aIde[ "mod" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 11 )

   // SERIE DOCUMENTO (NF-E)
   ::DrawBox( 340, ::nLinhaPDF -20,   50,  20, ::nLarguraBox )
   ::DrawTexto( 341, ::nLinhaPdf,     390, Nil, "SERIE", HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 6 )
   ::DrawTexto( 341, ::nLinhaPDF -6,   390, Nil, ::aIde[ "serie" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 11 )

   IF Substr( ::cChaveEvento, 21, 2 ) == "57" // At( "retEventoCTe",::cXmlEvento) > 0
      // NUMERO CTE
      ::DrawTexto( 391, ::nLinhaPdf,     480, Nil, "NUMERO DO CT-e", HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 6 )
      ::DrawTexto( 391, ::nLinhaPDF -6,   480, Nil, SubStr( StrZero( Val( ::aIde[ "nNF" ] ), 9 ), 1, 3 ) + "." + SubStr( StrZero( Val( ::aIde[ "nNF" ] ), 9 ), 4, 3 ) + "." + SubStr( StrZero( Val( ::aIde[ "nNF" ] ), 9 ), 7, 3 ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 11 )
   ELSE
      // NUMERO NFE
      ::DrawTexto( 391, ::nLinhaPdf,     480, Nil, "NUMERO DA NF-e", HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 6 )
      ::DrawTexto( 391, ::nLinhaPDF -6,   480, Nil, SubStr( StrZero( Val( ::aIde[ "nNF" ] ), 9 ), 1, 3 ) + "." + SubStr( StrZero( Val( ::aIde[ "nNF" ] ), 9 ), 4, 3 ) + "." + SubStr( StrZero( Val( ::aIde[ "nNF" ] ), 9 ), 7, 3 ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 11 )
   ENDIF
   // DATA DE EMISSAO DA NFE
   ::DrawBox( 480, ::nLinhaPDF -20,   85,  20, ::nLarguraBox )
   ::DrawTexto( 481, ::nLinhaPdf,     565, Nil, "DATA DE EMISS�O", HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 6 )
   ::DrawTexto( 481, ::nLinhaPDF -6,   565, Nil, SubStr( ::aIde[ "dhEmi" ], 9, 2 ) + '/' + SubStr( ::aIde[ "dhEmi" ], 6, 2 ) + '/' + Left( ::aIde[ "dhEmi" ], 4 ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 11 )

   RETURN NIL

METHOD Destinatario() CLASS hbnfeDaEvento

   // REMETENTE / DESTINATARIO

   ::nLinhaPdf -= 24

   IF At( "retEventoCTe", ::cXmlEvento ) > 0  // runner
      ::DrawTexto( 30, ::nLinhaPdf, 565, Nil, "DESTINAT�RIO", HPDF_TALIGN_LEFT, ::oPdfFontCabecalhoBold, 6 )
   ELSE
      ::DrawTexto( 30, ::nLinhaPdf, 565, Nil, "DESTINAT�RIO/REMETENTE", HPDF_TALIGN_LEFT, ::oPdfFontCabecalhoBold, 6 )
   ENDIF
   ::nLinhaPdf -= 9
   // RAZAO SOCIAL
   ::DrawBox( 30, ::nLinhaPDF -20, 425, 20, ::nLarguraBox )
   ::DrawTexto( 32, ::nLinhaPdf, 444, Nil, "NOME / RAZ�O SOCIAL", HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 6 )
   ::DrawTexto( 32, ::nLinhaPDF -6, 444, Nil, ::aDest[ "xNome" ], HPDF_TALIGN_LEFT, ::oPdfFontCabecalhoBold, 11 )
   // CNPJ/CPF
   ::DrawBox( 455, ::nLinhaPDF -20, 110, 20, ::nLarguraBox )
   ::DrawTexto( 457, ::nLinhaPdf, 565, Nil, "CNPJ/CPF", HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 6 )
   IF ! Empty( ::aDest[ "CNPJ" ] )
      ::DrawTexto( 457, ::nLinhaPDF -6, 565, Nil, Transform( ::aDest[ "CNPJ" ], "@R 99.999.999/9999-99" ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 11 )
   ELSE
      IF ::aDest[ "CPF" ] <> Nil
         ::DrawTexto( 457, ::nLinhaPDF -6, 565, Nil, Transform( ::aDest[ "CPF" ], "@R 999.999.999-99" ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 11 )
      ENDIF
   ENDIF

   ::nLinhaPdf -= 20

   // ENDERE�O
   ::DrawBox( 30, ::nLinhaPDF -20, 270, 20, ::nLarguraBox )
   ::DrawTexto( 32, ::nLinhaPdf, 298, Nil, "ENDERE�O", HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 6 )
   ::DrawTexto( 32, ::nLinhaPDF -6, 298, Nil, ::aDest[ "xLgr" ] + " " + ::aDest[ "nro" ], HPDF_TALIGN_LEFT, ::oPdfFontCabecalhoBold, 9 )
   // BAIRRO
   ::DrawBox( 300, ::nLinhaPDF -20, 195, 20, ::nLarguraBox )
   ::DrawTexto( 302, ::nLinhaPdf, 494, Nil, "BAIRRO", HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 6 )
   ::DrawTexto( 302, ::nLinhaPDF -6, 494, Nil, ::aDest[ "xBairro" ], HPDF_TALIGN_LEFT, ::oPdfFontCabecalhoBold, 11 )
   // CEP
   ::DrawBox( 495, ::nLinhaPDF -20, 70, 20, ::nLarguraBox )
   ::DrawTexto( 497, ::nLinhaPdf, 564, Nil, "C.E.P.", HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 6 )
   ::DrawTexto( 497, ::nLinhaPDF -6, 564, Nil, Transform( ::aDest[ "CEP" ], "@R 99999-999" ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 11 )

   ::nLinhaPdf -= 20

   // MUNICIPIO
   ::DrawBox( 30, ::nLinhaPDF -20, 535, 20, ::nLarguraBox )
   ::DrawTexto( 32, ::nLinhaPdf, 284, Nil, "MUNICIPIO", HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 6 )
   ::DrawTexto( 32, ::nLinhaPDF -6, 284, Nil, ::aDest[ "xMun" ], HPDF_TALIGN_LEFT, ::oPdfFontCabecalhoBold, 11 )
   // FONE/FAX
   ::DrawBox( 285, ::nLinhaPDF -20, 140, 20, ::nLarguraBox )
   ::DrawTexto( 287, ::nLinhaPdf, 424, Nil, "FONE/FAX", HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 6 )
   ::DrawTexto( 287, ::nLinhaPDF -6, 424, Nil, FormatTelefone( ::aDest[ "fone" ] ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 11 )
   // ESTADO
   ::DrawTexto( 427, ::nLinhaPdf, 454, Nil, "ESTADO", HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 6 )
   ::DrawTexto( 427, ::nLinhaPDF -6, 454, Nil, ::aDest[ "UF" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 11 )
   // INSC. EST.
   ::DrawBox( 455, ::nLinhaPDF -20, 110, 20, ::nLarguraBox )
   ::DrawTexto( 457, ::nLinhaPdf, 564, Nil, "INSCRI��O ESTADUAL", HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 6 )
   ::DrawTexto( 457, ::nLinhaPDF -6, 564, Nil, ::aDest[ "IE" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 11 )

   ::nLinhaPdf -= 20

   RETURN NIL

METHOD Eventos() CLASS hbnfeDaEvento

   LOCAL cDataHoraReg, cMemo, nI, nCompLinha, oElement, cGrupo, cCampo, cValor

   // Eventos
   ::DrawTexto( 30, ::nLinhaPDF -4, 565, Nil, "EVENTOS", HPDF_TALIGN_LEFT, ::oPdfFontCabecalhoBold, 6 )

   ::nLinhaPdf -= 12

   ::DrawBox( 30, ::nLinhaPDF -20,   535,  20, ::nLarguraBox )

   // ORGAO EMITENTE
   ::DrawTexto( 32, ::nLinhaPdf,   90, Nil, "ORG�O", HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 6 )
   ::DrawTexto( 32, ::nLinhaPDF -6, 90, Nil, ::aInfEvento[ "cOrgao" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 11 )

   // TIPO DE EVENTO'
   ::DrawBox( 90, ::nLinhaPDF -20,   60,  20, ::nLarguraBox )
   ::DrawTexto( 92, ::nLinhaPdf,     149, Nil, "TIPO EVENTO", HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 6 )
   ::DrawTexto( 92, ::nLinhaPDF -6,   149, Nil, ::aInfEvento[ "tpEvento" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 11 )

   // SEQUENCIA  EVENTO
   ::DrawTexto( 152, ::nLinhaPdf,   209, Nil, "SEQ. EVENTO", HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 6 )
   ::DrawTexto( 152, ::nLinhaPDF -6, 209, Nil, ::aInfEvento[ "nSeqEvento" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 11 )

   // VERS�O DO EVENTO
   ::DrawBox( 210, ::nLinhaPDF -20,   60,  20, ::nLarguraBox )
   ::DrawTexto( 212, ::nLinhaPdf,      269, Nil, "VERS�O EVENTO", HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 6 )
   ::DrawTexto( 212, ::nLinhaPDF -6,    269, Nil, ::aInfEvento[ "verEvento" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 11 )

   // DATA E HORA DO REGISTRO
   ::DrawTexto( 272, ::nLinhaPdf,  429, Nil, "DATA DO REGISTRO", HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 6 )
   cDataHoraReg := SubStr( ::aInfEvento[ "dhRegEvento" ], 9, 2 ) + '/'
   cDataHoraReg += SubStr( ::aInfEvento[ "dhRegEvento" ], 6, 2 ) + '/'
   cDataHoraReg += Left( ::aInfEvento[ "dhRegEvento" ], 4 ) + '  '
   cDataHoraReg += SubStr( ::aInfEvento[ "dhRegEvento" ], 12, 8 )
   ::DrawTexto( 272, ::nLinhaPDF -6, 429, Nil, cDataHoraReg, HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 11 )

   // NUMERO DO PROTOCOLO
   ::DrawBox( 430, ::nLinhaPDF -20,    135,  20, ::nLarguraBox )
   ::DrawTexto( 432, ::nLinhaPdf,       564, Nil, "NUMERO DO PROTOCOLO", HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 6 )
   ::DrawTexto( 432, ::nLinhaPDF -6,     564, Nil, ::aInfEvento[ "nProt" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 11 )

   ::nLinhaPdf -= 20

   // STATUS DO EVENTO
   ::DrawBox( 30, ::nLinhaPDF -20,  535,  20, ::nLarguraBox )
   ::DrawTexto( 32, ::nLinhaPdf,     564, Nil, "STATUS DO EVENTO", HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 6 )
   ::DrawTexto( 32, ::nLinhaPDF -6,    60, Nil, ::aInfEvento[ "cStat" ], HPDF_TALIGN_CENTER, ::oPdfFontCabecalhoBold, 11 )
   ::DrawTexto( 62, ::nLinhaPDF -6,    564, Nil, ::aInfEvento[ "xMotivo" ], HPDF_TALIGN_LEFT, ::oPdfFontCabecalhoBold, 11 )

   ::nLinhaPdf -= 25

   // Corre��es

   ::DrawTexto( 30, ::nLinhaPdf, 565, Nil, "CORRE��ES", HPDF_TALIGN_LEFT, ::oPdfFontCabecalhoBold, 6 )
   ::DrawBox( 30, ::nLinhaPDF -188,   535,  180, ::nLarguraBox )

   ::nLinhaPdf -= 12

   IF Len( ::aCorrecoes ) > 0

      FOR EACH oElement IN ::aCorrecoes
         cGrupo := XmlNode( oElement, 'grupoAlterado' )
         cCampo := XmlNode( oElement, 'campoAlterado' )
         cValor := XmlNode( oElement, 'valorAlterado' )
         ::DrawTexto( 38, ::nLinhaPdf,564, Nil, 'Alterado = Grupo : '+cGrupo+' - Campo : '+cCampo+' - Valor : '+cValor , HPDF_TALIGN_LEFT, ::oPdfFontCorrecoes, 11 )
         ::nLinhaPdf -= 12
      NEXT
      FOR nI = ( Len( ::aCorrecoes ) + 1 ) TO 14
         ::nLinhaPdf -= 12
      NEXT

   ELSE

      cMemo := ::aInfEvento[ "xCorrecao" ]

      cMemo := StrTran( cMemo, ";", Chr( 13 ) + Chr( 10 ) )
      nCompLinha := 77
      IF ::cFonteCorrecoes == "Helvetica"
         nCompLinha := 75
      ENDIF

      FOR nI = 1 TO MLCount( cMemo, nCompLinha )
         ::DrawTexto( 38, ::nLinhaPdf,564, Nil, Upper( Trim( MemoLine( cMemo, nCompLinha, nI ) ) ), HPDF_TALIGN_LEFT, ::oPdfFontCorrecoes, 11 )
         ::nLinhaPdf -= 12
      NEXT

      FOR nI = ( MLCount( cMemo, nCompLinha ) + 1 ) TO 14
         ::nLinhaPdf -= 12
      NEXT
   ENDIF
   RETURN NIL

METHOD Rodape() CLASS hbnfeDaEvento

   LOCAL cTextoCond, nTamFonte

   ::nLinhaPdf -= 13

   IF ::cFonteEvento == "Times"
      nTamFonte = 13
   ELSEIF ::cFonteEvento == "Helvetica"
      nTamFonte = 12
   ELSEIF ::cFonteEvento == "Courier-Oblique"
      nTamFonte = 9
   ELSE
      nTamFonte = 9
   ENDIF

   // Condi��o de USO
   ::DrawTexto( 30, ::nLinhaPdf, 535, Nil, "CONDI��O DE USO", HPDF_TALIGN_LEFT, ::oPdfFontCabecalhoBold, 6 )
   IF At("retEventoCTe",::cXmlEvento) > 0  // runner
      ::DrawBox( 30, ::nLinhaPDF -126 ,   535, 118 , ::nLarguraBox )
      cTextoCond := 'A Carta de Corre��o � disciplinada pelo Art. 58-B do CONV�NIO/SINIEF 06/89: Fica permitida a'
      ::DrawTexto( 34, ::nLinhaPdf -12,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := 'utiliza��o  de carta  de  corre��o, para  regulariza��o  de  erro  ocorrido  na  emiss�o  de'
      ::DrawTexto( 34, ::nLinhaPdf -24,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := 'documentos  fiscais  relativos � presta��o de servi�o  de  transporte, desde  que o erro n�o'
      ::DrawTexto( 34, ::nLinhaPdf -36,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := 'esteja relacionado com :'
      ::DrawTexto( 34, ::nLinhaPdf -48,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := 'I   - As vari�veis que determinam o valor  do imposto  tais como: base de c�lculo, al�quota,'
      ::DrawTexto( 34, ::nLinhaPdf -60,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := '      diferen�a de pre�o, quantidade, da presta��o;'
      ::DrawTexto( 34, ::nLinhaPdf -72,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := 'II  - A corre��o de dados cadastrais que  implique mudan�a do emitente,  tomador,  remetente'
      ::DrawTexto( 34, ::nLinhaPdf -84,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := '      ou do destinat�rio;'
      ::DrawTexto( 34, ::nLinhaPdf -96,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := 'III - A data de emiss�o ou de sa�da.'
      ::DrawTexto( 34, ::nLinhaPdf -108,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, nTamFonte )
      // Observa��es:
        ::nLinhaPdf -= 124
   ELSE
      ::DrawBox( 30, ::nLinhaPDF -102,   535,  94, ::nLarguraBox )
      cTextoCond := 'A Carta de Corre��o � disciplinada pelo � 1�-A do art. 7� do Conv�nio S/N, de 15 de dezembro de'
      ::DrawTexto( 34, ::nLinhaPdf -12,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := '1970,  e pode ser utilizada para regulariza��o de erro ocorrido na emiss�o de documento fiscal,'
      ::DrawTexto( 34, ::nLinhaPdf -24,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := 'desde que o erro n�o esteja relacionado com:'
      ::DrawTexto( 34, ::nLinhaPdf -36,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := 'I   - As vari�veis que determinam o valor do imposto tais como:  Base de c�lculo, al�quota,'
      ::DrawTexto( 34, ::nLinhaPdf -48,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := '      diferen�a de pre�o, quantidade, valor da opera��o ou da presta��o;'
      ::DrawTexto( 34, ::nLinhaPdf -60,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := 'II  - A corre��o de dados cadastrais que implique mudan�a do remetente ou do destinat�rio;'
      ::DrawTexto( 34, ::nLinhaPdf -72,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := 'III - A data de emiss�o ou de sa�da.'
      ::DrawTexto( 34, ::nLinhaPdf -84,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, nTamFonte )
      // Observa��es:
        ::nLinhaPdf -= 100
   ENDIF

   IF ::cFonteEvento == "Times"
      cTextoCond := 'Para evitar-se  qualquer  sans�o fiscal, solicitamos acusarem o recebimento  desta,  na'
      ::DrawTexto( 34, ::nLinhaPDF -12, 564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 15 )
      cTextoCond := 'c�pia que acompanha, devendo  a  via  de  V.S(as) ficar juntamente com  a nota fiscal'
      ::DrawTexto( 34, ::nLinhaPDF -26, 564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 15 )
      cTextoCond := 'em quest�o.'
      ::DrawTexto( 34, ::nLinhaPDF -40, 564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 15 )
   ELSEIF ::cFonteEvento == "Helvetica"
      cTextoCond := 'Para evitar-se qualquer sans�o fiscal, solicitamos acusarem  o  recebimento desta, '
      ::DrawTexto( 34, ::nLinhaPDF -12, 564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 14 )
      cTextoCond := 'na c�pia que acompanha, devendo a via  de  V.S(as) ficar juntamente com  a  nota '
      ::DrawTexto( 34, ::nLinhaPDF -26, 564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 14 )
      cTextoCond := 'fiscal em quest�o.'
      ::DrawTexto( 34, ::nLinhaPDF -40, 564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 14 )
   ELSE
      cTextoCond := 'Para evitar-se qualquer sans�o fiscal, solicitamos acusarem o recebimento desta,'
      ::DrawTexto( 34, ::nLinhaPDF -12, 564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 11 )
      cTextoCond := 'na c�pia que acompanha, devendo a via  de  V.S(as) ficar juntamente com  a nota'
      ::DrawTexto( 34, ::nLinhaPDF -26, 564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 11 )
      cTextoCond := 'fiscal em quest�o.'
      ::DrawTexto( 34, ::nLinhaPDF -40, 564, Nil, cTextoCond, HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 11 )
   ENDIF

   // Observa��es:

   ::nLinhaPdf -= 100

   ::DrawLine( 34, ::nLinhaPDF -12, 270, ::nLinhaPDF -12, ::nLarguraBox )

   ::DrawTexto( 30,  ::nLinhaPDF -14, 284, Nil, 'Local e data', HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 9 )
   ::DrawTexto( 304, ::nLinhaPDF -14, 574, Nil, 'Sem outro motivo para o momento subscrevemos-nos.', HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 9 )
   ::DrawTexto( 304, ::nLinhaPDF -24, 574, Nil, 'Atenciosamente.', HPDF_TALIGN_LEFT, ::oPdfFontCabecalho, 9 )

   ::DrawLine( 34,  ::nLinhaPDF -92, 270, ::nLinhaPDF -92, ::nLarguraBox )
   ::DrawLine( 564, ::nLinhaPDF -92, 300, ::nLinhaPDF -92, ::nLarguraBox )

   ::DrawTexto( 30,  ::nLinhaPDF -94, 284, Nil,  Trim( MemoLine( ::aDest[ "xNome" ], 40, 1 ) ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 9 )
   ::DrawTexto( 30,  ::nLinhaPDF -108, 284, Nil, Trim( MemoLine( ::aDest[ "xNome" ], 40, 2 ) ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 9 )
   ::DrawTexto( 300, ::nLinhaPDF -94,  574, Nil, Trim( MemoLine( ::aEmit[ "xNome" ], 40, 1 ) ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 9 )
   ::DrawTexto( 300, ::nLinhaPDF -108, 574, Nil, Trim( MemoLine( ::aEmit[ "xNome" ], 40, 2 ) ), HPDF_TALIGN_CENTER, ::oPdfFontCabecalho, 9 )

   RETURN NIL

#ifdef __XHARBOUR__
STATIC FUNCTION hbnfe_Codifica_Code128c( pcCodigoBarra )

   // Parameters de entrada : O codigo de barras no formato Code128C "somente numeros" campo tipo caracter
   // Retorno               : Retorna o c�digo convertido e com o caracter de START e STOP mais o checksum
   // : para impress�o do c�digo de barras utilizando a fonte Code128bWin, � necess�rio
   // : para utilizar essa fonte os arquivos Code128bWin.ttf, Code128bWin.afm e Code128bWin.pfb
   // Autor                  : Anderson Camilo
   // Data                   : 19/03/2012

   LOCAL nI := 0, checksum := 0, nValorCar, cCode128 := '', cCodigoBarra

   cCodigoBarra = pcCodigoBarra
   IF Len( cCodigoBarra ) > 0    // Verifica se os caracteres s�o v�lidos (somente n�meros)
      IF Int( Len( cCodigoBarra ) / 2 ) = Len( cCodigoBarra ) / 2    // Tem ser par o tamanho do c�digo de barras
         FOR nI = 1 TO Len( cCodigoBarra )
            IF ( Asc( SubStr( cCodigoBarra, nI, 1 ) ) < 48 .OR. Asc( SubStr( cCodigoBarra, nI, 1 ) ) > 57 )
               nI = 0
               EXIT
            ENDIF
         NEXT
      ENDIF
      IF nI > 0
         nI = 1 // nI � o �ndice da cadeia
         cCode128 = Chr( 155 )
         DO WHILE nI <= Len( cCodigoBarra )
            nValorCar = Val( SubStr( cCodigoBarra, nI, 2 ) )
            IF nValorCar = 0
               nValorCar += 128
            ELSEIF nValorCar < 95
               nValorCar += 32
            ELSE
               nValorCar +=  50
            ENDIF
            cCode128 += Chr( nValorCar )
            nI = nI + 2
         ENDDO
         // Calcula o checksum
         FOR nI = 1 TO Len( cCode128 )
            nValorCar = Asc ( SubStr( cCode128, nI, 1 ) )
            IF nValorCar = 128
               nValorCar = 0
            ELSEIF nValorCar < 127
               nValorCar -= 32
            ELSE
               nValorCar -=  50
            ENDIF
            IF nI = 1
               checksum = nValorCar
            ENDIF
            checksum = Mod( ( checksum + ( nI -1 ) * nValorCar ), 103 )
         NEXT
         // C�lculo c�digo ASCII do checkSum
         IF checksum = 0
            checksum += 128
         ELSEIF checksum < 95
            checksum += 32
         ELSE
            checksum +=  50
         ENDIF
         // Adiciona o checksum e STOP
         cCode128 = cCode128 + Chr( checksum ) +  Chr( 156 )
      ENDIF
   ENDIF

   RETURN cCode128
#endif

STATIC FUNCTION FormatTelefone( cTelefone )

   LOCAL cPicture := ""

   cTelefone := iif( ValType( cTelefone ) == "N", Ltrim( Str( cTelefone ) ), cTelefone )
   cTelefone := SoNumeros( cTelefone )
   DO CASE
   CASE Len( cTelefone ) == 8  ; cPicture := "@R 9999-9999"
   CASE Len( cTelefone ) == 9  ; cPicture := "@R 99999-9999"
   CASE Len( cTelefone ) == 10 ; cPicture := "@R (99) 9999-9999"
   CASE Len( cTelefone ) == 11 ; cPicture := "@R (99) 99999-9999"
   CASE Len( cTelefone ) == 12 ; cPicture := "@R +99 (99) 9999-9999"
   CASE Len( cTelefone ) == 13 ; cPicture := "@R +99 (99) 99999-9999"
   ENDCASE

   RETURN Transform( cTelefone, cPicture )
