/*
ze_spedxmlvalida - Valida��o de XML
2016.07.28.1620 - Jos� Quintas
*/

FUNCTION ValidaXml( cXml, cFileXsd )

   LOCAL oXmlDomDoc, oXmlSchema, oXmlErro, cRetorno := "ERRO"

   hb_Default( @cFileXsd, "" )

   IF " <" $ cXml .OR. "> " $ cXml
      cRetorno := "Espa�os inv�lidos no XML entre as tags"
      RETURN cRetorno
   ENDIF

   IF Empty( cFileXsd )
      cRetorno := "OK"
      BREAK
   ENDIF
   IF ! File( cFileXSD )
      cRetorno := "Erro n�o encontrado arquivo " + cFileXSD
      BREAK
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
      oXmlSchema:Add( "http://www.portalfiscal.inf.br/nfe", cFileXSD )

      oXmlDomDoc:Schemas := oXmlSchema
      oXmlErro := oXmlDomDoc:Validate()
      IF oXmlErro:ErrorCode <> 0
         cRetorno := "Erro: " + AllTrim( Transform( oXmlErro:ErrorCode, "" ) ) + " " + AllTrim( Transform( oXmlErro:Reason, "" ) )
         BREAK
      ENDIF
      cRetorno := "OK"

   END SEQUENCE

   RETURN cRetorno
