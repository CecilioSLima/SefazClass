/*
ZE_SPEDDAEVENTO - DOCUMENTO AUXILIAR DO EVENTO
Fontes originais do projeto hbnfe em https://github.com/fernandoathayde/hbnfe

2016.09.24.1100 - In�cio de altera��es pra qualquer documento
*/

#include "common.ch"
#include "hbclass.ch"
#include "harupdf.ch"
#ifndef __XHARBOUR__
#include "hbwin.ch"
#include "hbzebra.ch"
// #include "hbcompat.ch"
#endif
// #include "hbnfe.ch"
#define _LOGO_ESQUERDA        1
#define _LOGO_DIREITA         2
#define _LOGO_EXPANDIDO       3

CLASS hbnfeDaEvento

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
   VAR cLogoFile
   VAR nLogoStyle // 1-esquerda, 2-direita, 3-expandido

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
   ::cTelefoneEmitente := ::aEmit[ "fone" ]
   IF ! Empty( ::cTelefoneEmitente )
      ::cTelefoneEmitente := Transform( SoNumeros( ::cTelefoneEmitente ), "@R (99) 9999-9999" )
   END

   ::aDest := XmlToHash( XmlNode( ::cXmlDocumento, "dest" ), { "CNPJ", "CPF", "xNome", "xLgr", "nro", "xBairro", "cMun", "xMun", "UF", "CEP", "fone", "IE" } )
   ::aDest[ "xNome" ] := XmlToString( ::aDest[ "xNome" ] )
   IF Len( ::aDest[ "fone" ] ) <= 8
      ::aDest[ "fone" ] := "00" + ::aDest[ "fone" ]
   ENDIF

   RETURN .T.

METHOD GeraPDF( cFilePDF ) CLASS hbNfeDaEvento

   // /////////////////////////////////////// LOCAL nItem, nIdes, nItensNF, nItens1Folha
   LOCAL nAltura // ///////////////////////// nRadiano, nLargura, nAngulo

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

   LOCAL oImage, hZebra

   hbNFe_Box_Hpdf( ::oPdfPage, 30, ::nLinhaPDF -106,   535,  110, ::nLarguraBox )    // Quadro Cabe�alho

   // logo/dados empresa

   hbNFe_Box_Hpdf( ::oPdfPage, 290, ::nLinhaPDF -106,  275,  110, ::nLarguraBox )    // Quadro CC-e, Chave de Acesso e Codigo de Barras
   hbNFe_Texto_hpdf( ::oPdfPage, 30, ::nLinhaPdf + 2,     274, Nil, "IDENTIFICA��O DO EMITENTE", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 6 )
   // alert('nLogoStyle: ' + ::nLogoStyle +';_LOGO_ESQUERDA: ' + _LOGO_ESQUERDA)
   IF Empty( ::cLogoFile )
      hbNFe_Texto_hpdf( ::oPdfPage,  30, ::nLinhaPDF -6,  289, Nil, Trim( MemoLine( ::aEmit[ "xNome" ], 30, 1 ) ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 14 )
      hbNFe_Texto_hpdf( ::oPdfPage,  30, ::nLinhaPDF -20,  289, Nil, Trim( MemoLine( ::aEmit[ "xNome" ], 30, 2 ) ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 14 )
      hbNFe_Texto_hpdf( ::oPdfPage,  30, ::nLinhaPDF -42,  289, Nil, ::aEmit[ "xLgr" ] + " " + ::aEmit[ "nro" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 10 )
      hbNFe_Texto_hpdf( ::oPdfPage,  30, ::nLinhaPDF -52,  289, Nil, ::aEmit[ "xBairro" ] + " - " + Transform( ::aEmit[ "CEP" ], "@R 99999-999" ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 10 )
      hbNFe_Texto_hpdf( ::oPdfPage,  30, ::nLinhaPDF -62,  289, Nil, ::aEmit[ "xMun" ] + " - " + ::aEmit[ "UF" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 10 )
      hbNFe_Texto_hpdf( ::oPdfPage,  30, ::nLinhaPDF -72,  289, Nil, Trim( iif( ! Empty( ::cTelefoneEmitente ), "FONE: " + ::cTelefoneEmitente, "" ) ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 10 )
      hbNFe_Texto_hpdf( ::oPdfPage,  30, ::nLinhaPDF -82,  289, Nil, Trim( ::cSiteEmitente ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 10 )
      hbNFe_Texto_hpdf( ::oPdfPage,  30, ::nLinhaPDF -92,  289, Nil, Trim( ::cEmailEmitente ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 10 )
   ELSE
      IF ::nLogoStyle = _LOGO_EXPANDIDO
         oImage := HPDF_LoadJpegImageFromFile( ::oPdf, ::cLogoFile )
         HPDF_Page_DrawImage( ::oPdfPage, oImage, 55, ::nLinhaPdf - ( 82 + 18 ), 218, 92 )
      ELSEIF ::nLogoStyle = _LOGO_ESQUERDA
         oImage := HPDF_LoadJpegImageFromFile( ::oPdf, ::cLogoFile )
         HPDF_Page_DrawImage( ::oPdfPage, oImage, 36, ::nLinhaPdf - ( 62 + 18 ), 62, 62 )
         hbNFe_Texto_hpdf( ::oPdfPage,  100, ::nLinhaPDF -6,  289, Nil, Trim( MemoLine( ::aEmit[ "xNome" ], 30, 1 ) ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 10 )
         hbNFe_Texto_hpdf( ::oPdfPage,  100, ::nLinhaPDF -20, 289, Nil, Trim( MemoLine( ::aEmit[ "xNome" ], 30, 2 ) ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 10 )
         hbNFe_Texto_hpdf( ::oPdfPage,  100, ::nLinhaPDF -42,  289, Nil, ::aEmit[ "xLgr" ] + " " + ::aEmit[ "nro" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 8 )
         hbNFe_Texto_hpdf( ::oPdfPage,  100, ::nLinhaPDF -52,  289, Nil, ::aEmit[ "xBairro" ] + " - " + Transform( ::aEmit[ "CEP" ], "@R 99999-999" ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 8 )
         hbNFe_Texto_hpdf( ::oPdfPage,  100, ::nLinhaPDF -62,  289, Nil, ::aEmit[ "xMun" ] + " - " + ::aEmit[ "UF" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 8 )
         IF ! Empty( ::cTelefoneEmitente )
            hbNFe_Texto_hpdf( ::oPdfPage,  100, ::nLinhaPDF -72,  289, Nil, "FONE: " + ::cTelefoneEmitente, HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 8 )
         ENDIF
         hbNFe_Texto_hpdf( ::oPdfPage,  100, ::nLinhaPDF -82,  289, Nil, Trim( ::cSiteEmitente ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 8 )
         hbNFe_Texto_hpdf( ::oPdfPage,  100, ::nLinhaPDF -92,  289, Nil, Trim( ::cEmailEmitente ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 8 )

      ELSEIF ::nLogoStyle = _LOGO_DIREITA
         oImage := HPDF_LoadJpegImageFromFile( ::oPdf, ::cLogoFile )
         HPDF_Page_DrawImage( ::oPdfPage, oImage, 220, ::nLinhaPdf - ( 62 + 18 ), 62, 62 )
         hbNFe_Texto_hpdf( ::oPdfPage,  30, ::nLinhaPDF -6,  218, Nil, Trim( MemoLine( ::aEmit[ "xNome" ], 30, 1 ) ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 10 )
         hbNFe_Texto_hpdf( ::oPdfPage,  30, ::nLinhaPDF -20, 218, Nil, Trim( MemoLine( ::aEmit[ "xNome" ], 30, 2 ) ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 10 )
         hbNFe_Texto_hpdf( ::oPdfPage,  30, ::nLinhaPDF -42,  218, Nil, ::aEmit[ "xLgr" ] + " " + ::aEmit[ "nro" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 8 )
         hbNFe_Texto_hpdf( ::oPdfPage,  30, ::nLinhaPDF -52,  218, Nil, ::aEmit[ "xBairro" ] + " - " + Transform( ::aEmit[ "CEP" ], "@R 99999-999" ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 8 )
         hbNFe_Texto_hpdf( ::oPdfPage,  30, ::nLinhaPDF -62,  218, Nil, ::aEmit[ "xMun" ] + " - " + ::aEmit[ "UF" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 8 )
         hbNFe_Texto_hpdf( ::oPdfPage,  30, ::nLinhaPDF -72,  218, Nil, Trim( iif( ! Empty( ::cTelefoneEmitente ), "FONE: " + ::cTelefoneEmitente, "" ) ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 8 )
         hbNFe_Texto_hpdf( ::oPdfPage,  30, ::nLinhaPDF -82,  218, Nil, Trim( ::cSiteEmitente ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 8 )
         hbNFe_Texto_hpdf( ::oPdfPage,  30, ::nLinhaPDF -92,  218, Nil, Trim( ::cEmailEmitente ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 8 )
      ENDIF
   ENDIF

/*
      IF EMPTY( ::cLogoFile )
          hbNFe_Texto_hpdf( ::oPdfPage, 71, ::nLinhaPdf   , 399, Nil, "IDENTIFICA��O DO EMITENTE" , HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
          hbNFe_Texto_hpdf( ::oPdfPage, 71, ::nLinhaPDF - 6 , 399, Nil, TRIM( MemoLine( ::aEmit[ "xNome" ],30,1)) , HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 12 )
          hbNFe_Texto_hpdf( ::oPdfPage, 71, ::nLinhaPDF - 18, 399, Nil, TRIM( MemoLine( ::aEmit[ "xNome" ],30,2)), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 12 )
          hbNFe_Texto_hpdf( ::oPdfPage, 71, ::nLinhaPDF - 30, 399, Nil, ::aEmit[ "xLgr" ]+" "+::aEmit[ "nro" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
          hbNFe_Texto_hpdf( ::oPdfPage, 71, ::nLinhaPDF - 38, 399, Nil, ::aEmit[ "xBairro" ]+" - "+ Transform( ::aEmit[ "CEP" ], "@R 99999-999"), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
          hbNFe_Texto_hpdf( ::oPdfPage, 71, ::nLinhaPDF - 46, 399, Nil, ::aEmit[ "xMun" ]+" - "+::aEmit[ "UF" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
          hbNFe_Texto_hpdf( ::oPdfPage, 71, ::nLinhaPDF - 54, 399, Nil, TRIM(IF(! Empty(::cTelefoneEmitente),"FONE: "+::cTelefoneEmitente,"")), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
          hbNFe_Texto_hpdf( ::oPdfPage, 71, ::nLinhaPDF - 62, 399, Nil, TRIM(::cSiteEmitente), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
          hbNFe_Texto_hpdf( ::oPdfPage, 71, ::nLinhaPDF - 70, 399, Nil, TRIM(::cEmailEmitente), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
       ELSE
          IF ::nLogoStyle = _LOGO_EXPANDIDO
             oImage := HPDF_LoadJPEGImageFromFile( ::oPdf, ::cLogoFile )
             HPDF_Page_DrawImage( ::oPdfPage, oImage, 6, ::nLinhaPdf - (72+6), 328, 72 )
          ELSEIF ::nLogoStyle = _LOGO_ESQUERDA
             oImage := HPDF_LoadJPEGImageFromFile( ::oPdf, ::cLogoFile )
             HPDF_Page_DrawImage( ::oPdfPage, oImage,71, ::nLinhaPdf - (72+6), 62, 72 )
              hbNFe_Texto_hpdf( ::oPdfPage,135, ::nLinhaPDF - 6 , 399, Nil, TRIM( MemoLine( ::aEmit[ "xNome" ],30,1)) , HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 12 )
              hbNFe_Texto_hpdf( ::oPdfPage,135, ::nLinhaPDF - 18, 399, Nil, TRIM( MemoLine( ::aEmit[ "xNome" ],30,2)), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 12 )
              hbNFe_Texto_hpdf( ::oPdfPage,135, ::nLinhaPDF - 30, 399, Nil, ::aEmit[ "xLgr" ]+" "+::aEmit[ "nro" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
              hbNFe_Texto_hpdf( ::oPdfPage,135, ::nLinhaPDF - 38, 399, Nil, ::aEmit[ "xBairro" ]+" - "+ Transform( ::aEmit[ "CEP" ], "@R 99999-999"), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
              hbNFe_Texto_hpdf( ::oPdfPage,135, ::nLinhaPDF - 46, 399, Nil, ::aEmit[ "xMun" ]+" - "+::aEmit[ "UF" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
              hbNFe_Texto_hpdf( ::oPdfPage,135, ::nLinhaPDF - 54, 399, Nil, TRIM(IF(! Empty(::cTelefoneEmitente),"FONE: "+::cTelefoneEmitente,"")), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
              hbNFe_Texto_hpdf( ::oPdfPage,135, ::nLinhaPDF - 62, 399, Nil, TRIM(::cSiteEmitente), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
              hbNFe_Texto_hpdf( ::oPdfPage,135, ::nLinhaPDF - 70, 399, Nil, TRIM(::cEmailEmitente), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
          ELSEIF ::nLogoStyle = _LOGO_DIREITA
             oImage := HPDF_LoadJPEGImageFromFile( ::oPdf, ::cLogoFile )
             HPDF_Page_DrawImage( ::oPdfPage, oImage,337, ::nLinhaPdf - (72+6), 62, 72 )
            hbNFe_Texto_hpdf( ::oPdfPage, 71, ::nLinhaPDF - 6 , 335, Nil, TRIM( MemoLine( ::aEmit[ "xNome" ],30,1)) , HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 12 )
            hbNFe_Texto_hpdf( ::oPdfPage, 71, ::nLinhaPDF - 18, 335, Nil, TRIM( MemoLine( ::aEmit[ "xNome" ],30,2)), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 12 )
            hbNFe_Texto_hpdf( ::oPdfPage, 71, ::nLinhaPDF - 30, 335, Nil, ::aEmit[ "xLgr" ]+" "+::aEmit[ "nro" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
            hbNFe_Texto_hpdf( ::oPdfPage, 71, ::nLinhaPDF - 38, 335, Nil, ::aEmit[ "xBairro" ]+" - "+ Transform( ::aEmit[ "CEP" ], "@R 99999-999"), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
            hbNFe_Texto_hpdf( ::oPdfPage, 71, ::nLinhaPDF - 46, 335, Nil, ::aEmit[ "xMun" ]+" - "+::aEmit[ "UF" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
            hbNFe_Texto_hpdf( ::oPdfPage, 71, ::nLinhaPDF - 54, 335, Nil, TRIM(IF(! Empty(::cTelefoneEmitente),"FONE: "+::cTelefoneEmitente,"")), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
            hbNFe_Texto_hpdf( ::oPdfPage, 71, ::nLinhaPDF - 62, 335, Nil, TRIM(::cSiteEmitente), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
            hbNFe_Texto_hpdf( ::oPdfPage, 71, ::nLinhaPDF - 70, 335, Nil, TRIM(::cEmailEmitente), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 8 )
           ENDIF
      ENDIF
*/

   hbNFe_Texto_hpdf( ::oPdfPage, 292, ::nLinhaPDF -2, 554, Nil, "CC-e", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 18 )
   hbNFe_Texto_hpdf( ::oPdfPage, 296, ::nLinhaPDF -22, 554, Nil, "CARTA DE CORRE��O ELETR�NICA", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 14 )

   // chave de acesso
   hbNFe_Box_Hpdf( ::oPdfPage, 290, ::nLinhaPDF -61,  275,  20, ::nLarguraBox )
   hbNFe_Texto_hpdf( ::oPdfPage, 291, ::nLinhaPDF -42, 534, Nil, "CHAVE DE ACESSO", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 6 )
   IF ::cFonteEvento == "Times"
      hbNFe_Texto_hpdf( ::oPdfPage, 292, ::nLinhaPDF -49, 554, Nil, Transform( ::cChaveEvento, "@R 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999" ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 10 )
   ELSE
      hbNFe_Texto_hpdf( ::oPdfPage, 292, ::nLinhaPDF -50, 554, Nil, Transform( ::cChaveEvento, "@R 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999" ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 8 )
   ENDIF

   // codigo barras
#ifdef __XHARBOUR__
   hbNFe_Texto_hpdf( ::oPdfPage, 291, ::nLinhaPDF -65, 555, Nil, hbnfe_CodificaCode128c( ::cChaveNFe ), HPDF_TALIGN_CENTER, Nil, ::cFonteCode128F, 18 )
#else
   hZebra := hb_zebra_create_code128( ::cChaveEvento, Nil )
   hbNFe_Zebra_Draw_Hpdf( hZebra, ::oPdfPage, 300, ::nLinhaPDF -100, 0.9, 30 )
#endif

   ::nLinhaPdf -= 106

   // CNPJ
   hbNFe_Box_Hpdf( ::oPdfPage,  30, ::nLinhaPDF -20,   535,  20, ::nLarguraBox )    // Quadro CNPJ/INSCRI��O
   hbNFe_Texto_hpdf( ::oPdfPage, 32, ::nLinhaPdf,      160, Nil, "CNPJ", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
   hbNFe_Texto_hpdf( ::oPdfPage, 31, ::nLinhaPDF -6,    160, Nil, Transform( ::aEmit[ "CNPJ" ], "@R 99.999.999/9999-99" ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 11 )

   // I.E.
   hbNFe_Box_Hpdf(  ::oPdfPage, 160, ::nLinhaPDF -20,  130,  20, ::nLarguraBox )    // Quadro INSCRI��O
   hbNFe_Texto_hpdf( ::oPdfPage, 162, ::nLinhaPdf,     290, Nil, "INSCRI��O ESTADUAL", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
   hbNFe_Texto_hpdf( ::oPdfPage, 161, ::nLinhaPDF -6,   290, Nil, ::aEmit[ "IE" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 11 )

   // MODELO DO DOCUMENTO (NF-E)
   hbNFe_Texto_hpdf( ::oPdfPage, 291, ::nLinhaPdf,     340, Nil, "MODELO", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 6 )
   hbNFe_Texto_hpdf( ::oPdfPage, 291, ::nLinhaPDF -6,   340, Nil, ::aIde[ "mod" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 11 )

   // SERIE DOCUMENTO (NF-E)
   hbNFe_Box_Hpdf( ::oPdfPage,  340, ::nLinhaPDF -20,   50,  20, ::nLarguraBox )
   hbNFe_Texto_hpdf( ::oPdfPage, 341, ::nLinhaPdf,     390, Nil, "SERIE", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 6 )
   hbNFe_Texto_hpdf( ::oPdfPage, 341, ::nLinhaPDF -6,   390, Nil, ::aIde[ "serie" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 11 )

   IF At( "retEventoCTe",::cXmlEvento) > 0
      // NUMERO CTE
      hbNFe_Texto_hpdf( ::oPdfPage, 391, ::nLinhaPdf,     480, Nil, "NUMERO DO CT-e", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 6 )
      hbNFe_Texto_hpdf( ::oPdfPage, 391, ::nLinhaPDF -6,   480, Nil, SubStr( StrZero( Val( ::aIde[ "nNF" ] ), 9 ), 1, 3 ) + "." + SubStr( StrZero( Val( ::aIde[ "nNF" ] ), 9 ), 4, 3 ) + "." + SubStr( StrZero( Val( ::aIde[ "nNF" ] ), 9 ), 7, 3 ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 11 )
   ELSE
      // NUMERO NFE
      hbNFe_Texto_hpdf( ::oPdfPage, 391, ::nLinhaPdf,     480, Nil, "NUMERO DA NF-e", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 6 )
      hbNFe_Texto_hpdf( ::oPdfPage, 391, ::nLinhaPDF -6,   480, Nil, SubStr( StrZero( Val( ::aIde[ "nNF" ] ), 9 ), 1, 3 ) + "." + SubStr( StrZero( Val( ::aIde[ "nNF" ] ), 9 ), 4, 3 ) + "." + SubStr( StrZero( Val( ::aIde[ "nNF" ] ), 9 ), 7, 3 ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 11 )
   ENDIF
   // DATA DE EMISSAO DA NFE
   hbNFe_Box_Hpdf( ::oPdfPage,  480, ::nLinhaPDF -20,   85,  20, ::nLarguraBox )
   hbNFe_Texto_hpdf( ::oPdfPage, 481, ::nLinhaPdf,     565, Nil, "DATA DE EMISS�O", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 6 )
   hbNFe_Texto_hpdf( ::oPdfPage, 481, ::nLinhaPDF -6,   565, Nil, SubStr( ::aIde[ "dhEmi" ], 9, 2 ) + '/' + SubStr( ::aIde[ "dhEmi" ], 6, 2 ) + '/' + Left( ::aIde[ "dhEmi" ], 4 ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 11 )

   RETURN NIL

METHOD Destinatario() CLASS hbnfeDaEvento

   // REMETENTE / DESTINATARIO

   ::nLinhaPdf -= 24

   IF At( "retEventoCTe", ::cXmlEvento ) > 0  // runner
      hbNFe_Texto_hpdf( ::oPdfPage, 30, ::nLinhaPdf, 565, Nil, "DESTINAT�RIO", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 6 )
   ELSE
      hbNFe_Texto_hpdf( ::oPdfPage, 30, ::nLinhaPdf, 565, Nil, "DESTINAT�RIO/REMETENTE", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 6 )
   ENDIF
   ::nLinhaPdf -= 9
   // RAZAO SOCIAL
   hbNFe_Box_Hpdf( ::oPdfPage,  30, ::nLinhaPDF -20, 425, 20, ::nLarguraBox )
   hbNFe_Texto_hpdf( ::oPdfPage, 32, ::nLinhaPdf, 444, Nil, "NOME / RAZ�O SOCIAL", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
   hbNFe_Texto_hpdf( ::oPdfPage, 32, ::nLinhaPDF -6, 444, Nil, ::aDest[ "xNome" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 11 )
   // CNPJ/CPF
   hbNFe_Box_Hpdf( ::oPdfPage, 455, ::nLinhaPDF -20, 110, 20, ::nLarguraBox )
   hbNFe_Texto_hpdf( ::oPdfPage, 457, ::nLinhaPdf, 565, Nil, "CNPJ/CPF", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
   IF ! Empty( ::aDest[ "CNPJ" ] )
      hbNFe_Texto_hpdf( ::oPdfPage, 457, ::nLinhaPDF -6, 565, Nil, Transform( ::aDest[ "CNPJ" ], "@R 99.999.999/9999-99" ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 11 )
   ELSE
      IF ::aDest[ "CPF" ] <> Nil
         hbNFe_Texto_hpdf( ::oPdfPage, 457, ::nLinhaPDF -6, 565, Nil, Transform( ::aDest[ "CPF" ], "@R 999.999.999-99" ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 11 )
      ENDIF
   ENDIF

   ::nLinhaPdf -= 20

   // ENDERE�O
   hbNFe_Box_Hpdf( ::oPdfPage, 30, ::nLinhaPDF -20, 270, 20, ::nLarguraBox )
   hbNFe_Texto_hpdf( ::oPdfPage, 32, ::nLinhaPdf, 298, Nil, "ENDERE�O", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
   hbNFe_Texto_hpdf( ::oPdfPage, 32, ::nLinhaPDF -6, 298, Nil, ::aDest[ "xLgr" ] + " " + ::aDest[ "nro" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 9 )
   // BAIRRO
   hbNFe_Box_Hpdf( ::oPdfPage, 300, ::nLinhaPDF -20, 195, 20, ::nLarguraBox )
   hbNFe_Texto_hpdf( ::oPdfPage, 302, ::nLinhaPdf, 494, Nil, "BAIRRO", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
   hbNFe_Texto_hpdf( ::oPdfPage, 302, ::nLinhaPDF -6, 494, Nil, ::aDest[ "xBairro" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 11 )
   // CEP
   hbNFe_Box_Hpdf( ::oPdfPage, 495, ::nLinhaPDF -20, 70, 20, ::nLarguraBox )
   hbNFe_Texto_hpdf( ::oPdfPage, 497, ::nLinhaPdf, 564, Nil, "C.E.P.", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
   hbNFe_Texto_hpdf( ::oPdfPage, 497, ::nLinhaPDF -6, 564, Nil, Transform( ::aDest[ "CEP" ], "@R 99999-999" ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 11 )

   ::nLinhaPdf -= 20

   // MUNICIPIO
   hbNFe_Box_Hpdf( ::oPdfPage,  30, ::nLinhaPDF -20, 535, 20, ::nLarguraBox )
   hbNFe_Texto_hpdf( ::oPdfPage, 32, ::nLinhaPdf, 284, Nil, "MUNICIPIO", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
   hbNFe_Texto_hpdf( ::oPdfPage, 32, ::nLinhaPDF -6, 284, Nil, ::aDest[ "xMun" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 11 )
   // FONE/FAX
   hbNFe_Box_Hpdf( ::oPdfPage, 285, ::nLinhaPDF -20, 140, 20, ::nLarguraBox )
   hbNFe_Texto_hpdf( ::oPdfPage, 287, ::nLinhaPdf, 424, Nil, "FONE/FAX", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
   IF Len( ::aDest[ "fone" ] ) = 10
      hbNFe_Texto_hpdf( ::oPdfPage, 287, ::nLinhaPDF -6, 424, Nil, Transform( ::aDest[ "fone" ], "@R (99) 9999-9999" ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 11 )
   ELSEIF Len( ::aDest[ "fone" ] ) > 10
      hbNFe_Texto_hpdf( ::oPdfPage, 287, ::nLinhaPDF -6, 424, Nil, Transform( ::aDest[ "fone" ], "@R +99 (99) 9999-9999" ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 11 )
   ENDIF
   // ESTADO
   hbNFe_Texto_hpdf( ::oPdfPage, 427, ::nLinhaPdf, 454, Nil, "ESTADO", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
   hbNFe_Texto_hpdf( ::oPdfPage, 427, ::nLinhaPDF -6, 454, Nil, ::aDest[ "UF" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 11 )
   // INSC. EST.
   hbNFe_Box_Hpdf( ::oPdfPage, 455, ::nLinhaPDF -20, 110, 20, ::nLarguraBox )
   hbNFe_Texto_hpdf( ::oPdfPage, 457, ::nLinhaPdf, 564, Nil, "INSCRI��O ESTADUAL", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
   hbNFe_Texto_hpdf( ::oPdfPage, 457, ::nLinhaPDF -6, 564, Nil, ::aDest[ "IE" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 11 )

   ::nLinhaPdf -= 20

   RETURN NIL

METHOD Eventos() CLASS hbnfeDaEvento

   LOCAL cDataHoraReg, cMemo, nI, nCompLinha, oElement, cGrupo, cCampo, cValor

   // Eventos
   hbNFe_Texto_hpdf( ::oPdfPage, 30, ::nLinhaPDF -4, 565, Nil, "EVENTOS", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 6 )

   ::nLinhaPdf -= 12

   hbNFe_Box_Hpdf( ::oPdfPage,  30, ::nLinhaPDF -20,   535,  20, ::nLarguraBox )

   // ORGAO EMITENTE
   hbNFe_Texto_hpdf( ::oPdfPage, 32, ::nLinhaPdf,   90, Nil, "ORG�O", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 6 )
   hbNFe_Texto_hpdf( ::oPdfPage, 32, ::nLinhaPDF -6, 90, Nil, ::aInfEvento[ "cOrgao" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 11 )

   // TIPO DE EVENTO'
   hbNFe_Box_Hpdf( ::oPdfPage,  90, ::nLinhaPDF -20,   60,  20, ::nLarguraBox )
   hbNFe_Texto_hpdf( ::oPdfPage, 92, ::nLinhaPdf,     149, Nil, "TIPO EVENTO", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 6 )
   hbNFe_Texto_hpdf( ::oPdfPage, 92, ::nLinhaPDF -6,   149, Nil, ::aInfEvento[ "tpEvento" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 11 )

   // SEQUENCIA  EVENTO
   hbNFe_Texto_hpdf( ::oPdfPage, 152, ::nLinhaPdf,   209, Nil, "SEQ. EVENTO", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 6 )
   hbNFe_Texto_hpdf( ::oPdfPage, 152, ::nLinhaPDF -6, 209, Nil, ::aInfEvento[ "nSeqEvento" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 11 )

   // VERS�O DO EVENTO
   hbNFe_Box_Hpdf( ::oPdfPage,  210, ::nLinhaPDF -20,   60,  20, ::nLarguraBox )
   hbNFe_Texto_hpdf( ::oPdfPage, 212, ::nLinhaPdf,      269, Nil, "VERS�O EVENTO", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 6 )
   hbNFe_Texto_hpdf( ::oPdfPage, 212, ::nLinhaPDF -6,    269, Nil, ::aInfEvento[ "verEvento" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 11 )

   // DATA E HORA DO REGISTRO
   hbNFe_Texto_hpdf( ::oPdfPage, 272, ::nLinhaPdf,  429, Nil, "DATA DO REGISTRO", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 6 )
   cDataHoraReg := SubStr( ::aInfEvento[ "dhRegEvento" ], 9, 2 ) + '/'
   cDataHoraReg += SubStr( ::aInfEvento[ "dhRegEvento" ], 6, 2 ) + '/'
   cDataHoraReg += Left( ::aInfEvento[ "dhRegEvento" ], 4 ) + '  '
   cDataHoraReg += SubStr( ::aInfEvento[ "dhRegEvento" ], 12, 8 )
   hbNFe_Texto_hpdf( ::oPdfPage, 272, ::nLinhaPDF -6, 429, Nil, cDataHoraReg, HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 11 )

   // NUMERO DO PROTOCOLO
   hbNFe_Box_Hpdf( ::oPdfPage,  430, ::nLinhaPDF -20,    135,  20, ::nLarguraBox )
   hbNFe_Texto_hpdf( ::oPdfPage, 432, ::nLinhaPdf,       564, Nil, "NUMERO DO PROTOCOLO", HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 6 )
   hbNFe_Texto_hpdf( ::oPdfPage, 432, ::nLinhaPDF -6,     564, Nil, ::aInfEvento[ "nProt" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 11 )

   ::nLinhaPdf -= 20

   // STATUS DO EVENTO
   hbNFe_Box_Hpdf( ::oPdfPage,  30, ::nLinhaPDF -20,  535,  20, ::nLarguraBox )
   hbNFe_Texto_hpdf( ::oPdfPage, 32, ::nLinhaPdf,     564, Nil, "STATUS DO EVENTO", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 6 )
   hbNFe_Texto_hpdf( ::oPdfPage, 32, ::nLinhaPDF -6,    60, Nil, ::aInfEvento[ "cStat" ], HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalhoBold, 11 )
   hbNFe_Texto_hpdf( ::oPdfPage, 62, ::nLinhaPDF -6,    564, Nil, ::aInfEvento[ "xMotivo" ], HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 11 )

   ::nLinhaPdf -= 25

   // Corre��es

   hbNFe_Texto_hpdf( ::oPdfPage, 30, ::nLinhaPdf, 565, Nil, "CORRE��ES", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 6 )
   hbNFe_Box_Hpdf( ::oPdfPage,  30, ::nLinhaPDF -188,   535,  180, ::nLarguraBox )

   ::nLinhaPdf -= 12

	IF Len( ::aCorrecoes )

      FOR EACH oElement IN ::aCorrecoes
         cGrupo := XmlNode( oElement, 'grupoAlterado' )
         cCampo := XmlNode( oElement, 'campoAlterado' )
         cValor := XmlNode( oElement, 'valorAlterado' )
         hbNFe_Texto_hpdf( ::oPdfPage, 38, ::nLinhaPdf,564, Nil, 'Alterado = Grupo : '+cGrupo+' - Campo : '+cCampo+' - Valor : '+cValor , HPDF_TALIGN_LEFT, Nil, ::oPdfFontCorrecoes, 11 )
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
	      hbNFe_Texto_hpdf( ::oPdfPage, 38, ::nLinhaPdf,564, Nil, Upper( Trim( MemoLine( cMemo, nCompLinha, nI ) ) ), HPDF_TALIGN_LEFT, Nil, ::oPdfFontCorrecoes, 11 )
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
   hbNFe_Texto_hpdf( ::oPdfPage, 30, ::nLinhaPdf, 535, Nil, "CONDI��O DE USO", HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalhoBold, 6 )
   IF At("retEventoCTe",::cXmlEvento) > 0  // runner
      hbNFe_Box_Hpdf( ::oPdfPage,  30, ::nLinhaPDF -126 ,   535, 118 , ::nLarguraBox )
      cTextoCond := 'A Carta de Corre��o � disciplinada pelo Art. 58-B do CONV�NIO/SINIEF 06/89: Fica permitida a'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPdf -12,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := 'utiliza��o  de carta  de  corre��o, para  regulariza��o  de  erro  ocorrido  na  emiss�o  de'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPdf -24,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := 'documentos  fiscais  relativos � presta��o de servi�o  de  transporte, desde  que o erro n�o'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPdf -36,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := 'esteja relacionado com :'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPdf -48,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := 'I   - As vari�veis que determinam o valor  do imposto  tais como: base de c�lculo, al�quota,'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPdf -60,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := '      diferen�a de pre�o, quantidade, da presta��o;'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPdf -72,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, nTamFonte )
	   cTextoCond := 'II  - A corre��o de dados cadastrais que  implique mudan�a do emitente,  tomador,  remetente'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPdf -84,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, nTamFonte )
	   cTextoCond := '      ou do destinat�rio;'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPdf -96,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := 'III - A data de emiss�o ou de sa�da.'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPdf -108,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, nTamFonte )
      // Observa��es:
  	   ::nLinhaPdf -= 124
   ELSE
      hbNFe_Box_Hpdf( ::oPdfPage,  30, ::nLinhaPDF -102,   535,  94, ::nLarguraBox )
      cTextoCond := 'A Carta de Corre��o � disciplinada pelo � 1�-A do art. 7� do Conv�nio S/N, de 15 de dezembro de'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPdf -12,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := '1970,  e pode ser utilizada para regulariza��o de erro ocorrido na emiss�o de documento fiscal,'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPdf -24,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := 'desde que o erro n�o esteja relacionado com:'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPdf -36,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := 'I   - As vari�veis que determinam o valor do imposto tais como:  Base de c�lculo, al�quota,'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPdf -48,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := '      diferen�a de pre�o, quantidade, valor da opera��o ou da presta��o;'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPdf -60,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := 'II  - A corre��o de dados cadastrais que implique mudan�a do remetente ou do destinat�rio;'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPdf -72,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, nTamFonte )
      cTextoCond := 'III - A data de emiss�o ou de sa�da.'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPdf -84,564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, nTamFonte )
      // Observa��es:
  	   ::nLinhaPdf -= 100
   ENDIF

   IF ::cFonteEvento == "Times"
      cTextoCond := 'Para evitar-se  qualquer  sans�o fiscal, solicitamos acusarem o recebimento  desta,  na'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPDF -12, 564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 15 )
      cTextoCond := 'c�pia que acompanha, devendo  a  via  de  V.S(as) ficar juntamente com  a nota fiscal'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPDF -26, 564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 15 )
      cTextoCond := 'em quest�o.'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPDF -40, 564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 15 )
   ELSEIF ::cFonteEvento == "Helvetica"
      cTextoCond := 'Para evitar-se qualquer sans�o fiscal, solicitamos acusarem  o  recebimento desta, '
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPDF -12, 564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 14 )
      cTextoCond := 'na c�pia que acompanha, devendo a via  de  V.S(as) ficar juntamente com  a  nota '
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPDF -26, 564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 14 )
      cTextoCond := 'fiscal em quest�o.'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPDF -40, 564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 14 )
   ELSE
      cTextoCond := 'Para evitar-se qualquer sans�o fiscal, solicitamos acusarem o recebimento desta,'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPDF -12, 564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 11 )
      cTextoCond := 'na c�pia que acompanha, devendo a via  de  V.S(as) ficar juntamente com  a nota'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPDF -26, 564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 11 )
      cTextoCond := 'fiscal em quest�o.'
      hbNFe_Texto_hpdf( ::oPdfPage, 34, ::nLinhaPDF -40, 564, Nil, cTextoCond, HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 11 )
   ENDIF

   // Observa��es:

   ::nLinhaPdf -= 100

   hbNFe_Line_Hpdf( ::oPdfPage, 34, ::nLinhaPDF -12, 270, ::nLinhaPDF -12, ::nLarguraBox )

   hbNFe_Texto_hpdf( ::oPdfPage, 30,  ::nLinhaPDF -14, 284, Nil, 'Local e data', HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 9 )
   hbNFe_Texto_hpdf( ::oPdfPage, 304, ::nLinhaPDF -14, 574, Nil, 'Sem outro motivo para o momento subscrevemos-nos.', HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 9 )
   hbNFe_Texto_hpdf( ::oPdfPage, 304, ::nLinhaPDF -24, 574, Nil, 'Atenciosamente.', HPDF_TALIGN_LEFT, Nil, ::oPdfFontCabecalho, 9 )

   hbNFe_Line_Hpdf( ::oPdfPage, 34,  ::nLinhaPDF -92, 270, ::nLinhaPDF -92, ::nLarguraBox )
   hbNFe_Line_Hpdf( ::oPdfPage, 564, ::nLinhaPDF -92, 300, ::nLinhaPDF -92, ::nLarguraBox )

   hbNFe_Texto_hpdf( ::oPdfPage, 30,  ::nLinhaPDF -94, 284, Nil,  Trim( MemoLine( ::aDest[ "xNome" ], 40, 1 ) ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 9 )
   hbNFe_Texto_hpdf( ::oPdfPage, 30,  ::nLinhaPDF -108, 284, Nil, Trim( MemoLine( ::aDest[ "xNome" ], 40, 2 ) ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 9 )
   hbNFe_Texto_hpdf( ::oPdfPage, 300, ::nLinhaPDF -94,  574, Nil, Trim( MemoLine( ::aEmit[ "xNome" ], 40, 1 ) ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 9 )
   hbNFe_Texto_hpdf( ::oPdfPage, 300, ::nLinhaPDF -108, 574, Nil, Trim( MemoLine( ::aEmit[ "xNome" ], 40, 2 ) ), HPDF_TALIGN_CENTER, Nil, ::oPdfFontCabecalho, 9 )

   RETURN NIL
// Fun��es repetidas em NFE, CTE, MDFE e EVENTO
// STATIC pra permitir uso simult�neo com outras rotinas

STATIC FUNCTION hbNFe_Texto_Hpdf( oPdfPage2, x1, y1, x2, y2, cText, align, desconhecido, oFontePDF, nTamFonte, nAngulo )

   LOCAL nRadiano

   IF oFontePDF <> NIL
      HPDF_Page_SetFontAndSize( oPdfPage2, oFontePDF, nTamFonte )
   ENDIF
   IF x2 = NIL
      x2 := x1 - nTamFonte
   ENDIF
   HPDF_Page_BeginText( oPdfPage2 )
   IF nAngulo == NIL // horizontal normal
      HPDF_Page_TextRect ( oPdfPage2,  x1, y1, x2, y2, cText, align, NIL )
   ELSE
      nRadiano := nAngulo / 180 * 3.141592 /* Calcurate the radian value. */
      HPDF_Page_SetTextMatrix( oPdfPage2, Cos( nRadiano ), Sin( nRadiano ), -Sin( nRadiano ), Cos( nRadiano ), x1, y1 )
      HPDF_Page_ShowText( oPdfPage2, cText )
   ENDIF
   HPDF_Page_EndText  ( oPdfPage2 )

   HB_SYMBOL_UNUSED( desconhecido )

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
#else

STATIC FUNCTION hbNFe_Zebra_Draw_Hpdf( hZebra, page, ... )

   IF hb_zebra_geterror( hZebra ) != 0
      RETURN HB_ZEBRA_ERROR_INVALIDZEBRA
   ENDIF

   hb_zebra_draw( hZebra, {| x, y, w, h | HPDF_Page_Rectangle( page, x, y, w, h ) }, ... )

   HPDF_Page_Fill( page )

   RETURN 0

#endif

STATIC FUNCTION hbNFe_Line_Hpdf( oPdfPage2, x1, y1, x2, y2, nPen, FLAG )

   HPDF_Page_SetLineWidth( oPdfPage2, nPen )
   IF FLAG <> NIL
      HPDF_Page_SetLineCap( oPdfPage2, FLAG )
   ENDIF
   HPDF_Page_MoveTo( oPdfPage2, x1, y1 )
   HPDF_Page_LineTo( oPdfPage2, x2, y2 )
   HPDF_Page_Stroke( oPdfPage2 )
   IF FLAG <> NIL
      HPDF_Page_SetLineCap( oPdfPage2, HPDF_BUTT_END )
   ENDIF

   RETURN NIL

STATIC FUNCTION hbNFe_Box_Hpdf( oPdfPage2, x1, y1, x2, y2, nPen )

   HPDF_Page_SetLineWidth( oPdfPage2, nPen )
   HPDF_Page_Rectangle( oPdfPage2, x1, y1, x2, y2 )
   HPDF_Page_Stroke( oPdfPage2 )

   RETURN NIL
