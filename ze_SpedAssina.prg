/*
ZE_SPEDASSINA - Assinatura SPED

2017.01.09.1730 - Teste adicional de assinatura
2017.01.11.1200 - Nota de servi�o usando id ao inv�s de Id
2017.01.11.2020 - Errado acima, obrigat�rio Id com i mai�sculo
2017.05.25.1330 - Remove declara��o de XML
2017.05.25.1510 - Fonte reorganizado
*/

#define _CAPICOM_STORE_OPEN_READ_ONLY                 0           // Somente Smart Card em Modo de Leitura

#define _CAPICOM_MEMORY_STORE                         0
#define _CAPICOM_LOCAL_MACHINE_STORE                  1
#define _CAPICOM_CURRENT_USER_STORE                   2
#define _CAPICOM_ACTIVE_DIRECTORY_USER_STORE          3
#define _CAPICOM_SMART_CARD_USER_STORE                4

#define _CAPICOM_STORE_OPEN_MAXIMUM_ALLOWED           2
#define _CAPICOM_CERTIFICATE_FIND_SHA1_HASH           0           // Retorna os Dados Criptografados com Hash SH1
#define _CAPICOM_CERTIFICATE_FIND_EXTENDED_PROPERTY   6
#define _CAPICOM_CERTIFICATE_FIND_TIME_VALID          9           // Retorna Certificados V�lidos
#define _CAPICOM_CERTIFICATE_FIND_KEY_USAGE           12          // Retorna Certificados que cont�m dados.
#define _CAPICOM_DIGITAL_SIGNATURE_KEY_USAGE          0x00000080  // Permitir o uso da Chave Privada para assinatura Digital
#define _CAPICOM_AUTHENTICATED_ATTRIBUTE_SIGNING_TIME 0           // Este atributo cont�m o tempo em que a assinatura foi criada.
#define _CAPICOM_INFO_SUBJECT_SIMPLE_NAME             0           // Retorna o nome de exibi��o do certificado.
#define _CAPICOM_ENCODE_BASE64                        0           // Os dados s�o guardados como uma string base64-codificado.
#define _CAPICOM_E_CANCELLED                          -2138568446 // A opera��o foi cancelada pelo usu�rio.
#define _CERT_KEY_SPEC_PROP_ID                        6
#define _CAPICOM_CERT_INFO_ISSUER_EMAIL_NAME          0
#define _SIG_KEYINFO                                  2

#include "common.ch"
#include "hbclass.ch"

FUNCTION CapicomAssinaXml( cTxtXml, cCertCN, lRemoveAnterior )

   LOCAL oDOMDocument, xmldsig, oCert, oCapicomStore
   LOCAL SIGNEDKEY, DSIGKEY
   LOCAL cXmlTagInicial, cXmlTagFinal, cRetorno := ""
   LOCAL cDllFile, acDllList := { "msxml5.dll", "msxml5r.dll", "capicom.dll" }

   hb_Default( @lRemoveAnterior, .T. )

   AssinaRemoveAssinatura( @cTxtXml, lRemoveAnterior )

   AssinaRemoveDeclaracao( @cTxtXml )

   IF ! AssinaAjustaInformacao( @cTxtXml, @cXmlTagInicial, @cXmlTagFinal, @cRetorno )
      RETURN cRetorno
   ENDIF

   IF ! AssinaLoadXml( @oDOMDocument, cTxtXml, @cRetorno )
      RETURN cRetorno
   ENDIF

   IF ! AssinaLoadCertificado( cCertCN, @ocert, @oCapicomStore, cRetorno )
      RETURN cRetorno
   ENDIF

   BEGIN SEQUENCE WITH __BreakBlock()

      cRetorno := "Erro Assinatura: N�o carregado MSXML2.MXDigitalSignature.5.0"
      xmldsig := Win_OleCreateObject( "MSXML2.MXDigitalSignature.5.0" )

      cRetorno := "Erro Assinatura: Template de assinatura n�o encontrado"
      xmldsig:signature := oDOMDocument:selectSingleNode(".//ds:Signature")

      cRetorno := "Erro assinatura: Certificado pra assinar XmlDSig:Store"
      xmldsig:store := oCapicomStore

      dsigKey  := xmldsig:CreateKeyFromCSP( oCert:PrivateKey:ProviderType, oCert:PrivateKey:ProviderName, oCert:PrivateKey:ContainerName, 0 )
      IF ( dsigKey = NIL )
         cRetorno := "Erro assinatura: Ao criar a chave do CSP."
         BREAK
      ENDIF
      cRetorno := "Erro assinatura: assinar XmlDSig:Sign()"
      SignedKey := XmlDSig:Sign( DSigKey, 2 )

      IF signedKey == NIL
         cRetorno := "Erro Assinatura: Assinatura Falhou."
         BREAK
      ENDIF
      cTxtXml  := AssinaAjustaAssinado( oDOMDocument:Xml )
      cRetorno := "OK"

   END SEQUENCE

   IF cRetorno != "OK" .OR. ! "<Signature" $ cTxtXml
      IF Empty( cRetorno )
         cRetorno := "Erro Assinatura "
      ENDIF
      FOR EACH cDllFile IN acDllList
         IF ! File( "c:\windows\system32\" + cDllFile ) .AND. ! File( "c:\windows\syswow64\" + cDllFile )
            cRetorno += ", verifique " + cDllFile
         ENDIF
      NEXT
   ENDIF

   RETURN cRetorno

STATIC FUNCTION AssinaBlocoAssinatura( cUri )

   LOCAL cSignatureNode := ""

   cSignatureNode += [<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">]
   cSignatureNode +=    [<SignedInfo>]
   cSignatureNode +=       [<CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>]
   cSignatureNode +=       [<SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1" />]
   cSignatureNode +=       [<Reference URI="#] + cURI + [">]
   cSignatureNode +=       [<Transforms>]
   cSignatureNode +=          [<Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" />]
   cSignatureNode +=          [<Transform Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315" />]
   cSignatureNode +=       [</Transforms>]
   cSignatureNode +=       [<DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1" />]
   cSignatureNode +=       [<DigestValue>]
   cSignatureNode +=       [</DigestValue>]
   cSignatureNode +=       [</Reference>]
   cSignatureNode +=    [</SignedInfo>]
   cSignatureNode +=    [<SignatureValue>]
   cSignatureNode +=    [</SignatureValue>]
   cSignatureNode +=    [<KeyInfo>]
   cSignatureNode +=    [</KeyInfo>]
   cSignatureNode += [</Signature>]

   RETURN cSignatureNode

STATIC FUNCTION AssinaRemoveAssinatura( cTxtXml, lRemoveAnterior )

   LOCAL nPosIni, nPosFim

   // Remove assinatura anterior - aten��o pra NFS que usa multiplas assinaturas
   IF lRemoveAnterior
      DO WHILE "<Signature" $ cTxtXml .AND. "</Signature>" $ cTxtXml
         nPosIni := At( "<Signature", cTxtXml ) - 1
         nPosFim := At( "</Signature>", cTxtXml ) + 12
         cTxtXml := Substr( cTxtXml, 1, nPosIni ) + Substr( cTxtXml, nPosFim )
      ENDDO
   ENDIF

   RETURN cTxtXml

STATIC FUNCTION AssinaRemoveDeclaracao( cTxtXml )

   IF "<?XML" $ Upper( cTxtXml ) .AND. "?>" $ cTxtXml
      cTxtXml := Substr( cTxtXml, At( "?>", cTxtXml ) + 2 )
      DO WHILE Substr( cTxtXml, 1, 1 ) $ hb_Eol()
         cTxtXml := Substr( cTxtXml, 2 )
      ENDDO
   ENDIF

   RETURN cTxtXml

STATIC FUNCTION AssinaAjustaInformacao( cTxtXml, cXmlTagInicial, cXmlTagFinal, cRetorno )

   LOCAL aDelimitadores, nPos, nPosIni, nPosFim, cURI

   aDelimitadores := { ;
      { "<enviMDFe",              "</MDFe></enviMDFe>" }, ;
      { "<eventoMDFe",            "</eventoMDFe>" }, ;
      { "<eventoCTe",             "</eventoCTe>" }, ;
      { "<infMDFe",               "</MDFe>" }, ;
      { "<infCte",                "</CTe>" }, ;
      { "<infNFe",                "</NFe>" }, ;
      { "<infDPEC",               "</envDPEC>" }, ;
      { "<infInut",               "<inutNFe>" }, ;
      { "<infCanc",               "</cancNFe>" }, ;
      { "<infInut",               "</inutNFe>" }, ;
      { "<infInut",               "</inutCTe>" }, ;
      { "<infEvento",             "</evento>" }, ;
      { "<infPedidoCancelamento", "</Pedido>" }, ;               // NFSE ABRASF Cancelamento
      { "<LoteRps",               "</EnviarLoteRpsEnvio>" }, ;   // NFSE ABRASF Lote
      { "<infRps",                "</Rps>" } }                   // NFSE ABRASF RPS

   // Define Tipo de Documento
   IF ( nPos := AScan( aDelimitadores, { | oElement | oElement[ 1 ] $ cTxtXml .AND. oElement[ 2 ] $ cTxtXml } ) ) == 0
      cRetorno := "Erro Assinatura: N�o identificado documento"
      RETURN .F.
   ENDIF
   cXmlTagFinal   := aDelimitadores[ nPos, 2 ]
   // Pega URI
   nPosIni := At( [Id=], cTxtXml )
   IF nPosIni = 0
      cRetorno := "Erro Assinatura: N�o encontrado in�cio do URI: Id= (com I mai�sculo)"
      RETURN .F.
   ENDIF
   nPosIni := hb_At( ["], cTxtXml, nPosIni + 2 )
   IF nPosIni = 0
      cRetorno := "Erro Assinatura: N�o encontrado in�cio do URI: aspas inicial"
      RETURN .F.
   ENDIF
   nPosFim := hb_At( ["], cTxtXml, nPosIni + 1 )
   IF nPosFim = 0
      cRetorno := "Erro Assinatura: N�o encontrado in�cio do URI: aspas final"
      RETURN .F.
   ENDIF
   cURI := Substr( cTxtXml, nPosIni + 1, nPosFim - nPosIni - 1 )

   // Adiciona bloco de assinatura no local apropriado
   IF cXmlTagFinal $ cTxtXml
      cTxtXml := Substr( cTxtXml, 1, At( cXmlTagFinal, cTxtXml ) - 1 ) + AssinaBlocoAssinatura( cURI ) + cXmlTagFinal
   ENDIF

   IF ! "</Signature>" $ cTxtXml
      cRetorno := "Erro Assinatura: Bloco Assinatura n�o encontrado"
      RETURN .F.
   ENDIF

   HB_SYMBOL_UNUSED( cXmlTagInicial )

   RETURN .T.

STATIC FUNCTION AssinaLoadXml( oDomDocument, cTxtXml, cRetorno )

   LOCAL lOk := .F.

   BEGIN SEQUENCE WITH __BreakBlock()

      oDOMDocument := Win_OleCreateObject( "MSXML2.DOMDocument.5.0" )
      oDOMDocument:async              := .F.
      oDOMDocument:resolveExternals   := .F.
      oDOMDocument:validateOnParse    := .T.
      oDOMDocument:preserveWhiteSpace := .T.
      lOk := .T.

   END SEQUENCE

   IF ! lOk
      cRetorno := "Erro Assinatura: N�o carregado MSXML2.DomDocument"
      RETURN .F.
   ENDIF

   lOk := .F.

   BEGIN SEQUENCE WITH __BreakBlock()

      oDOMDocument:LoadXML( cTxtXml )
      oDOMDocument:setProperty( "SelectionNamespaces", [xmlns:ds="http://www.w3.org/2000/09/xmldsig#"] )
      lOk := .T.

   END SEQUENCE

   IF ! lOk
      IF oDOMDocument:parseError:errorCode <> 0 // XML n�o carregado
         cRetorno := "Erro Assinatura: N�o foi possivel carregar o documento pois ele n�o corresponde ao seu Schema" + HB_EOL()
         cRetorno += " Linha: "              + Str( oDOMDocument:parseError:line )    + HB_EOL()
         cRetorno += " Caractere na linha: " + Str( oDOMDocument:parseError:linepos ) + HB_EOL()
         cRetorno += " Causa do erro: "      + oDOMDocument:parseError:reason         + HB_EOL()
         cRetorno += "code: "                + Str( oDOMDocument:parseError:errorCode )
         RETURN .F.
      ENDIF
      cRetorno := "Erro Assinatura: N�o foi poss�vel carregar documento"
      RETURN .F.
   ENDIF

   RETURN .T.

STATIC FUNCTION AssinaLoadCertificado( cCertCN, oCert, oCapicomStore, cRetorno )

   LOCAL lOk := .F.

   oCert := CapicomCertificado( cCertCn )
   IF oCert == NIL
      cRetorno := "Erro Assinatura: Certificado n�o encontrado ou vencido"
      RETURN .F.
   ENDIF

   BEGIN SEQUENCE WITH __BreakBlock()

      oCapicomStore := Win_OleCreateObject( "CAPICOM.Store" )
      oCapicomStore:open( _CAPICOM_MEMORY_STORE, 'Memoria', _CAPICOM_STORE_OPEN_MAXIMUM_ALLOWED )
      oCapicomStore:Add( oCert )

      lOk := .T.
   END SEQUENCE
   IF ! lOk
      cRetorno := "Erro assinatura: Problemas no uso do certificado"
      RETURN .F.
   ENDIF

   RETURN .T.

STATIC FUNCTION AssinaAjustaAssinado( cXml )

   LOCAL nPosIni, nPosFim, nP, nResult

      cXml := StrTran( cXml, Chr(10), "" )
      cXml := StrTran( cXml, Chr(13), "" )
      nPosIni     := At( [<SignatureValue>], cXml ) + Len( [<SignatureValue>] )
      cXml := Substr( cXml, 1, nPosIni - 1 ) + StrTran( Substr( cXml, nPosIni, Len( cXml ) ), " ", "" )
      nPosIni     := At( [<X509Certificate>], cXml ) - 1
      nP          := At( [<X509Certificate>], cXml )
      nResult     := 0
      DO WHILE nP <> 0
         nResult := nP
         nP      := hb_At( [<X509Certificate>], cXml, nP + 1 )
      ENDDO
      nPosFim     := nResult
      cXml := Substr( cXml, 1, nPosIni ) + Substr( cXml, nPosFim, Len( cXml ) )

      RETURN cXml
