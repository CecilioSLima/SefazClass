/*
ZE_CAPICOM - ROTINAS PRA USO DA CAPICOM
Jos� Quintas
*/

#include "sefaz_capicom.ch"
#include "sefazclass.ch"
#include "hb2xhb.ch"

FUNCTION CapicomEscolheCertificado( dValidFrom, dValidTo )

   LOCAL oCertificado, oCapicomStore, cNomeCertificado := "NENHUM", oColecao

   oCapicomStore := win_oleCreateObject( "CAPICOM.Store" )
   oCapicomStore:Open( CAPICOM_CURRENT_USER_STORE, 'My', CAPICOM_STORE_OPEN_MAXIMUM_ALLOWED )
   oColecao := oCapicomStore:Certificates()
   DO CASE
   CASE oColecao:Count() == 1
      oCertificado     := oColecao:item(1)
      dValidFrom       := oCertificado:ValidFromDate
      dValidTo         := oCertificado:ValidToDate
      cNomeCertificado := oCertificado:SubjectName
   CASE oColecao:Count() > 1
      oCertificado     := oColecao:Select( "Selecione o certificado para uso da Nfe","Selecione o certificado", .F. )
      dValidFrom       := oCertificado:ValidFromDate
      dValidTo         := oCertificado:ValidToDate
      cNomeCertificado := oCertificado:SubjectName
   ENDCASE
   IF "CN=" $ cNomeCertificado
      cNomeCertificado := Substr( cNomeCertificado, At( "CN=", cNomeCertificado ) + 3 )
      IF "," $ cNomeCertificado
         cNomeCertificado := Substr( cNomeCertificado, 1, At( ",", cNomeCertificado ) - 1 )
      ENDIF
   ENDIF
   // oCapicomStore:Close()

   RETURN cNomeCertificado

FUNCTION CapicomCertificado( cNomeCertificado, dValidFrom, dValidTo )

   LOCAL oCapicomStore, oColecao, oCertificado, nCont

   oCapicomStore := Win_OleCreateObject( "CAPICOM.Store" )
   oCapicomStore:Open( CAPICOM_CURRENT_USER_STORE, "My", CAPICOM_STORE_OPEN_MAXIMUM_ALLOWED )
   oColecao := oCapicomStore:Certificates()
   FOR nCont = 1 TO oColecao:Count()
      IF cNomeCertificado $ oColecao:Item( nCont ):SubjectName
         oCertificado := oColecao:Item( nCont )
         dValidFrom   := oCertificado:ValidFromDate
         dValidTo     := oCertificado:ValidToDate
         EXIT
      ENDIF
   NEXT
   // oCapicomStore:Close()

   RETURN oCertificado

FUNCTION CapicomRemoveCertificado( cNomeCertificado )

   LOCAL oCertificado, oStore

   oCertificado := CapicomCertificado( cNomeCertificado )
   IF ValType( oCertificado ) == "O"
      oStore := win_OleCreateObject( "CAPICOM.Store" )
      oStore:open( CAPICOM_CURRENT_USER_STORE, CAPICOM_MY_STORE, CAPICOM_STORE_OPEN_READ_WRITE )
      oStore:Remove( oCertificado )
   ENDIF

   RETURN NIL

FUNCTION CapicomInstalaPFX( cFileName, cPassword, lREMOVER )

   LOCAL oCertificado, oStore, cID

   hb_Default( @lREMOVER, .F. )

   BEGIN SEQUENCE WITH __BreakBlock()

      oCertificado := win_OleCreateObject( "CAPICOM.Certificate" )
      oCertificado:Load( cFileName, cPassword, CAPICOM_KEY_STORAGE_DEFAULT, 0 )
      cID := oCertificado:SubjectName

      IF "CN=" $ cID
         cID := Substr( cID, At( "CN=", cID ) + 3 )
         IF "," $ cID
            cID := Substr( cID, 1, At( ",", cID ) - 1 )
         ENDIF
      ENDIF

      oStore := win_OleCreateObject( "CAPICOM.Store" )
      oStore:open( CAPICOM_CURRENT_USER_STORE, CAPICOM_MY_STORE, CAPICOM_STORE_OPEN_READ_WRITE )
      IF lREMOVER
         oStore:Remove( oCertificado )
      ELSE
         oStore:Add( oCertificado )
      ENDIF

   ENDSEQUENCE

   RETURN cID
