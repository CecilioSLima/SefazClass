/*
ZE_MISCFUNC - Miscel�nea de fun��es
*/

FUNCTION SoNumeros( cTxt )

   LOCAL cSoNumeros := "", cChar

   FOR EACH cChar IN cTxt
      IF cChar $ "0123456789"
         cSoNumeros += cChar
      ENDIF
   NEXT

   RETURN cSoNumeros

FUNCTION FormatNumber( nValor, nTamanho, nDecimais )

   LOCAL cPicture

   hb_Default( @nDecimais, 2 )
   hb_Default( @nTamanho, 15 )

   IF ValType( nValor ) == "C" // ser� perigoso ??
      nValor := Val( nValor )
   ENDIF

   cPicture := Replicate( "9", nTamanho - iif( nDecimais == 0, 0, nDecimais + 1 ) )
   cPicture := Ltrim( Transform( Val( cPicture ), "999,999,999,999,999" ) )
   IF nDecimais != 0
      cPicture += "." + Replicate( "9", nDecimais )
   ENDIF

   RETURN Transform( nValor, "@E " + cPicture )

FUNCTION ze_Feriado( dDate, cUF )

   LOCAL cFeriado := "", nPos, oElement
   LOCAL aList := { ;
      { "0101", "BR", "Ano Novo" }, ;
      { "0104", "RO", "RO Cria��o de RO" }, ;
      { "0123", "AC", "AC Dia do Evang�lico" }, ;
      { "0125", "SP", "SP Funda��o de SP" }, ; //
      { "0306", "PE", "PE Revolu��o Pernambucana de 1817" }, ;
      { "0308", "AC", "AC Alusivo ao Dia Internacional da Mulher" }, ;
      { "0318", "TO", "TO Autonomia de TO" }, ;
      { "0319", "AP", "AP e CE Dia de S Jos�" }, ;
      { "0325", "CE", "CE Aboli��o de escravos" }, ;
      { "0421", "BR,DF,MG", "Tiradentes, Funda��o de Bras�lia, Carta Magna MG" }, ;
      { "0423", "RJ", "RJ Dia de S Jorge" }, ;
      { "0501", "BR", "Dia do Trabalho" }, ;
      { "0524", "GO", "GO Dia de N Sra Auxiliadora" }, ;
      { "0615", "AC", "AC Anivers�rio do Estado" }, ;
      { "0618", "RO", "RO Dia do evang�lico" }, ;
      { "0624", "AL", "AL S�o Jo�o" }, ;
      { "0624", "PE", "PE Revolu��o Pernambucana de 1817" }, ;
      { "0629", "AL", "AL S�o Pedro" }, ;
      { "0702", "BA", "BA Independ�ncia da BA" }, ;
      { "0708", "SE", "SE Emancipa��o pol�tica de SE" }, ;
      { "0709", "SP", "SP Revolu��o Constitucionalista de 1932" }, ;
      { "0716", "PE", "PE Dia de N Sra do Carmo - Feriado Municipal" }, ;
      { "0726", "PB", "PB Homenagem � mem�ria do ex-presidente Jo�o Pessoa" }, ;
      { "0728", "MA", "MA Ades�o do Maranh�o � independ�ncia do Brasil" }, ;
      { "0805", "PB", "PB Funda��o do Estado e dia de N Sra das Neves" }, ;
      { "0811", "SC", "SC Dia de Sta Catarina" }, ;
      { "0815", "CE", "CE Dia de N Sra da Assun��o, PA Ades�o � independ�ncia do Brasil" }, ;
      { "0905", "AC,AM", "AC,AM Dia da Amaz�nia" }, ;
      { "0907", "BR", "Independ�ncia" }, ;
      { "0908", "TO", "TO N Sra da Natividade" }, ;
      { "0913", "AP", "AP Cria��o do Territ�rio Federal" }, ;
      { "0916", "AL", "AL Emancipa��o pol�tica" }, ;
      { "0920", "RS", "RS Proclama��o da Rep�blica RS" }, ;
      { "1005", "RR,TO", "RR,TO Cria��o do estado" }, ;
      { "1011", "MS", "MS Cria��o do estado" }, ;
      { "1012", "BR", "N S Aparecida" }, ;
      { "1003", "RN", "RN M�rtires de Cunha� e Urua�u" }, ;
      { "1019", "PI", "PI Dia do Piau�" }, ;
      { "1024", "GO", "GO Pedra Fundamental de Goi�nia" }, ;
      { "1102", "BR", "Finados" }, ;
      { "1115", "BR", "Proclama��o da Rep�blica" }, ;
      { "1117", "AC", "AC Assinatura do Tratado de Petr�polis" }, ;
      { "1120", "MT,RJ,SP,AM,AL", "Dia da Consci�ncia Negra, AL Morte de Zumbi dos Palmares" }, ;
      { "1125", "SC", "SC Dia de Sta Catarina de Alexandria" }, ;
      { "1130", "DF", "DF Dia do evang�lico" }, ;
      { "1208", "AM,PE", "AM/PE N Sra da Concei��o" }, ; //
      { "1219", "PR", "PR Emancipa��o pol�tica do estado do PR" }, ;
      { "1225", "BR", "Natal" } }

   LOCAL aEclesiasticos := { ; // baseados no domingo de p�scoa
      {  0,  "BR", "Domingo de P�scoa" }, ;
      { -2,  "BR", "Paixao de Cristo" }, ;
      { -47, "BR", "Ter�a de Carnaval" }, ;
      { -46, "BR", "Quarta Feira de Cinzas" }, ;
      {  60, "BR", "Corpus Christi" } }

   hb_Default( @cUF, "BR" )
   FOR EACH oElement IN aEclesiasticos
      AAdd( aList, { Right( Dtos( DomingoDePascoa( Year( dDate ) ) + oElement[ 1 ] ), 4 ), oElement[ 2 ], oElement[ 3 ] } )
   NEXT
   nPos := hb_AScan( aList, { | e | ( "BR" $ e[ 2 ] .OR. cUF $ e[ 2 ] ) .AND. e[ 1 ] == Right( Dtos( dDate ), 4 ) } )
   IF nPos != 0
      cFeriado := aList[ nPos, 3 ]
   ENDIF

   RETURN cFeriado

FUNCTION ze_DateAdd( dDate, nValue, cType )

   LOCAL nDay, nMonth, nYear

   hb_Default( @cType, "D" )
   cType := iif( cType $ "DMY", cType, "D" )

   DO CASE
   CASE cType == "D"
      dDate += nValue
   CASE cType == "Y"
      dDate := Stod( StrZero( Year( dDate ) + nValue, 4 ) + Substr( Dtos( dDate ), 5 ) )
   CASE cType == "M"
      nDay   := Day( dDate )
      nMonth := Month( dDate ) + nValue
      nYear  := Year( dDate )
      IF nMonth < 1
         nYear -= Int( Abs( nMonth ) / 12 ) + 1
         nMonth += ( Int( Abs( nMonth ) / 12 ) + 1 ) * 12
      ENDIF
      IF nMonth > 12
         nYear  += Int( ( nMonth - 1 ) / 12 )
         nMonth := Mod( ( nMonth - 1 ), 12 )
      ENDIF
      dDate := Stod( StrZero( nYear, 4 ) + StrZero( nMonth, 2 ) + "01" ) + nDay - 1
      IF Month( dDate ) != nMonth
         dDate := dDate - Day( dDate )
      ENDIF
   ENDCASE

   RETURN dDate



