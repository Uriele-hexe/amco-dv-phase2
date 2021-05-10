*=======================================================================================
* Macro       : hx_user_function_dataverification_dwh
* Description : It contains any user function regarding data verification
* --------------------------------------------------------------------------------------
* Created by    : Uriele De Piano Hexe (SpA)
* Creation date : 21 October 2020
*=======================================================================================
;
*--Libname hx_func "E:\progetti\Utility\hx_functions";

Proc fcmp outlib=hx_func.dataverification_dwh.package encrypt;
  function fx_check_value_missing(field_check $) $;
    Attrib fx_Rc Length=$5
	       ;
		fx_Rc = ifc(missing(field_check),'Y','N');
		/* CORREZIONE: NOTA 04/05/2021: Testare il flag di aggancio con il rapporto */
		/* Nuova modifica da implementare quando si chiuderà la fase 1
		  fx_Rc = ifc(missing(field_check) or strip(field_check)='.','Y','N');
		*/
		
		/* CORREZIONE: La funzione è richiamata dalla G.4.2 che però deve essere rivista come regola di aggancio.
		               Si esegue la inner join tra collateral e 
		*/
		
  return (fx_Rc);
  endsub;

	function fx_check_imm_collatarel(codCollateral $, flag_field $) $;
    Attrib fx_Rc Length=$5
	       ;
		fx_Rc = ifc(flag_field='N','Y','N');
  return (fx_Rc);
	endsub;

	function fx_check_gara_collateral(codGara $, flag_field $) $;
    Attrib fx_Rc Length=$5
	       ;
		   
		/* CORREZIONE: modifica il perimetro aggiungendo il test su cod_tipo='R' */
		   
		fx_Rc = ifc(flag_field='N','Y','N');
  return (fx_Rc);
	endsub;

	function fx_check_gara_in_fidi(codGara $, codCollateral $, flagLookup $) $;
    Attrib fx_Rc Length=$5
	       ;
		fx_Rc = ifc(flagLookup='N','Y','N');
  return (fx_Rc);
	endsub;

	function fx_check_lookup_perizie (flgLookup $) $;
    Attrib fx_Rc Length=$5
	       ;
		   
	/* CORREZIONE: Attenzione la funzione è applicata alla tabella delle Garanzie arricchita con le Perizie	  
                   Dovrebbe andare direttamente sulle Perizie capire come fare */
		   		   
		fx_Rc = ifc(flgLookup='N','Y','N');
  return (fx_Rc);
	endsub;

	function fx_check_grado_sost(grado_sost) $;
    Attrib fx_Rc Length=$5
	       ;
		   
	/* CORREZIONE: Attenzione deve testare anche che il grado sostanziale non sia superiore al parametro del grado inammisibile impostato come parametro*/
				   
		fx_Rc = ifc(missing(grado_sost),'Y','N');
  return (fx_Rc);
	endsub;

	function fx_grado_ipoteca_valido(grado_ipoteca, grado_ammesso) $;
    Attrib fx_Rc Length=$5
	       ;
		fx_Rc = ifc(Not missing(grado_ipoteca) And grado_ipoteca > grado_ammesso,'Y','N');
  return (fx_Rc);
	endsub;

	function fx_check_stato_gara(dtaIscrGara,dtaScadenza,dtaRifer) $;
    Attrib fx_Rc	  Length=$5
					 tipoGara Length=$15
	       ;
		   
    /* CORREZIONE: Implementazione della logica che battezza lo stato dela Garanzia. Il nuovo algoritmo è da portare nella fase di 
                   arricchimento
    */				   
		   
		tipoGara = "_ND_";
		if dtaIscrGara <= dtaRifer And dtaScadenza >= dtaRifer Then tipoGara="VALIDA";
		else if dtaIscrGara <= dtaRifer And dtaScadenza < dtaRifer Then tipoGara="SCADUTA";
		else if dtaIscrGara > dtaRifer Or missing(dtaScadenza) Then tipoGara="NON VALIDA";

		fx_Rc = ifc(missing(tipoGara) Or tipoGara In ("_ND_"),'Y','N');
  return (fx_Rc);
	endsub;

	function fx_check_is_pegno(codGara $, codCollateral $,des_tipo_collateral $,flgLkpColl $) $;
    Attrib fx_Rc	  Length=$5
	       ;
		fx_Rc = ifc(not missing(codCollateral) and flgLkpColl='N','Y','N');
  return (fx_Rc);
	endsub;

	function fx_check_datore_ipoteca(codGara $, desTipoGara $,ndgGarante $, flgInAnag $) $;
    Attrib fx_Rc	  Length=$5
	       ;
		/*-- Il desTipoGara è gestito nel perimetro, serve per essere pubblicato automaticamente
				 nei flussi Cedacri --*/
		fx_Rc = ifc(not missing(codGara) and (missing(ndgGarante) or flgInAnag='N'),'Y','N');
  return (fx_Rc);
	endsub;

	/*-- Start Function Anagafe --*/
	function fx_check_cod_fiscale_priv (cod_fiscIva $, sae $) $;
    Attrib fx_Rc 			 Length=$5
					 saePrivato  Length=$1
					 typeCodFisc Length=$4
	       ;

		fx_rc 		  = '*';
		saePrivato  = fx_get_sae_privato(put(sae,12.));
		typeCodFisc = fx_get_codfisc(cod_fiscIva);
		%*-- set violation, if fiscal code is assigned at not private sae;
		
	    /* CORREZIONE: NOTA 04/05/2021: Aggiungere il test sulla lunghezza a 16 */

		
		fx_rc = Ifc(strip(typeCodFisc)="CF" And saePrivato ^= 'Y','Y','N');
  return (fx_Rc);
	endsub;

	function fx_check_len_priva (cod_fiscIva $) $;
    Attrib fx_Rc 			 Length=$5
					 saePrivato  Length=$1
					 typeCodFisc Length=$4
	       ;

		fx_rc 		  = '*';
		saePrivato  = fx_get_sae_privato(put(sae,12.));
		typeCodFisc = fx_get_codfisc(cod_fiscIva);
		%*-- set violation, if fiscal code is assigned at private sae;
		
		/* CORREZIONE: NOTA 04/05/2021: Aggiungere il test sulla lunghezza a 11*/
		
		fx_rc = Ifc(strip(typeCodFisc)="PIVA" And saePrivato = 'Y','Y','N');
		If fx_rc = 'N' Then 
  return (fx_Rc);
	endsub;

	function fx_stato_debitore(statoDebitore $) $;
	  Attrib fx_Rc 			 Length=$5
					 saePrivato  Length=$1
					 typeCodFisc Length=$4
	       ;
		fx_Rc = Ifc(Upcase(statoDebitore) not in ("PD","UTP","SO","BO"),'Y','N');
  return (fx_Rc);
	endsub;

	function fx_check_gara_senza_fido (codGara $,codFido  $) $;
    Attrib fx_Rc Length=$5;
		fx_rc = ifc(not missing(codGara) And missing(codFido),'Y','N');
  return (fx_Rc);
	endsub;

	function fx_passagio_deb_def(statoDebitore $ ,dtaPassDef,refDate) $;
    Attrib fx_Rc Length=$5;
		fx_rc = N;
		If Upcase(statoDebitore) in ("PD","UTP") Then 
			fx_rc = ifc(missing(dtaPassDef) Or dtaPassDef>refDate,'Y','N');
  return (fx_Rc);
	endsub;

	function fx_passagio_deb_soff(statoDebitore $ ,dtaPassDef,refDate) $;
    Attrib fx_Rc Length=$5;
		fx_rc = N;
		If Upcase(statoDebitore) in ("SO") Then 
			fx_rc = ifc(missing(dtaPassDef) Or dtaPassDef>refDate,'Y','N');
  return (fx_Rc); 
	endsub;

	function fx_dta_status_missing(statoDebitore $ ,dtaPassDef) $;
	Attrib fx_Rc Length=$5;
		fx_rc = N;
		If Not missing(statoDebitore) Then 
			fx_rc = ifc(missing(dtaPassDef),'Y','N');
  return (fx_Rc);
	endsub;

	function fx_dta_status_valid(statoDebitore $ ,dtaPassDef,refDate) $;
	Attrib fx_Rc Length=$5;
		fx_rc = N;
		If Not missing(statoDebitore) Then 
			fx_rc = ifc(missing(dtaPassDef) Or dtaPassDef>refDate,'Y','N');
  return (fx_Rc);
	endsub;
	/*-- End Function about Anagrafe --*/

	/*-- Start Function about Immobili --*/
	function fx_check_immobile_vs_gara(codColl $, flgLkpGara $) $;
	Attrib fx_Rc Length=$5;
		fx_rc = N;
		fx_rc = ifc(not missing(codColl) and flgLkpGara='N','Y','N');
  return (fx_Rc);
	endsub;

	/* Versione rivista function fx_check_immobile_vs_aste(codColl $, codSubColl $, impCtu , flgLkpAsta $) $;*/
	/* Versione non corretta */
	function fx_check_immobile_vs_aste(codColl $, codSubColl $, codLotto $, flgLkpAsta $) $;
	Attrib fx_Rc Length=$5;
		fx_rc = ifc(not missing(codColl) and flgLkpAsta='N','Y','N');
  return (fx_Rc);
	endsub;

	function fx_check_ctu_fake (codColl $, codSubColl $, flgLkpPer $, codCatastale $, impPerizia) $;
	Attrib fx_Rc 			Length=$5
				 fakeValInf Length=8
				 fakeValSup Length=8
			;
		fakeValInf = 100000;
		fakeValSup = 10000000;
		fx_rc = ifc(not missing(codColl) and flgLkpPer='Y' and not (impPerizia>=fakeValInf And impPerizia<=fakeValSup),'Y','N');
  return (fx_Rc);
	endsub;

	function fx_check_ndgproc_pba (codColl $, codSubColl $, ndgDebitore, impPBA) $;
	Attrib fx_Rc 			Length=$5
			;
		fx_rc = ifc(not missing(codColl) and not missing(codSubColl) and not missing(ndgDebitore) and missing(impPBA),'Y','N');
  return (fx_Rc);
	endsub;

	/*-- End Function about Immobili --*/
  
	/*-- Start Function about Fidi --*/
	function fx_check_fidi_vs_rapporti (flgLkp $,codFido $,codRapporto $) $;
    Attrib fx_Rc Length=$5;
	
	/* CORREZIONE: NOTA 04/05/2021: Testare il flag di aggancio con il rapporto */
		fx_rc = ifc(flgLkp='Y' And not missing(codFido) And missing(codRapporto),'Y','N');
  return (fx_Rc);
	endsub;

	function fx_check_ndg_fido(codFido $, ndg, flgLkpRapp $) $;
    Attrib fx_Rc Length=$5;
		*-- Exists a record joined with relation fidi / rapporto;
		fx_rc = ifc(flgLkpRapp='Y' And not missing(codFido) And missing(ndg),'Y','N');
  return (fx_Rc);
	endsub;

	function fx_check_fido_gara (codFido $,flgLkpGara $) $;
	 Attrib fx_Rc Length=$5;
		*-- The param named codStatoRapporto will not be used, because of it used in perimeter;
		fx_rc = ifc(not missing(codFido) and flgLkpGara='N','Y','N');
  return (fx_Rc);
	endsub;

	function fx_check_fido_collateral (codFido $,codGara $, flgLkpColl $) $;
	 Attrib fx_Rc Length=$5;
		*-- The param named codStatoRapporto will not be used, because of it used in perimeter;
		fx_rc = ifc(not missing(codFido) and not missing(codGara) and flgLkpColl='N','Y','N');
  return (fx_Rc);
	endsub;

	/*-- Last Function about Fidi --*/

	/*-- Start Function about Rapporti --*/
	function fx_rapporto_vs_ndgdeb (codRapporto $,ndg,flglkpAnag $) $;
	 Attrib fx_Rc Length=$5;
		*-- Exists a record joined with relation fidi / rapporto;
		fx_rc = ifc(flglkpAnag='N' And not missing(codRapporto) And not missing(ndg),'Y','N');
  return (fx_Rc);
	endsub;

	function fx_check_rapporti_chiusi (codStatoRapporto $, dtaCessRapporto , dta_riferimento) $;
	 Attrib fx_Rc Length=$5;
		*-- The param named codStatoRapporto will not be used, because of it used in perimeter;
		fx_rc = ifc(missing(dtaCessRapporto) or (dtaCessRapporto>dta_riferimento),'Y','N');
  return (fx_Rc);
	endsub;

	function fx_check_rapp_no_soff_vs_fido (codRapporto $,codStatoRapporto $, flgLkp_racc $) $;
	 Attrib fx_Rc Length=$5;
		*-- The param named codStatoRapporto will not be used, because of it used in perimeter;
		fx_rc = ifc(not missing(codRapporto)and flgLkp_racc='N','Y','N');
  return (fx_Rc);
	endsub;

	function fx_check_rapp_soff_vs_fido_orig (codRapporto $,flgSofferenza $, codFidoOrig $) $;
	 Attrib fx_Rc Length=$5;
		*-- The param named codStatoRapporto will not be used, because of it used in perimeter;
		fx_rc = ifc(not missing(codRapporto)and flgSofferenza='Y' and missing(codFidoOrig),'Y','N');
  return (fx_Rc);
	endsub;

	/*-- End Function about Rapporti --*/

	/*-- Start Function about Aste e Lotti --*/
	function fx_check_aste_vs_lotti (codAsta , codLotto $, flgLkpLotti $) $;
	 Attrib fx_Rc Length=$5;
		*-- The param named codStatoRapporto will not be used, because of it used in perimeter;
		fx_rc = ifc(flgLkpLotti='N' And not missing(codAsta),'Y','N');
  return (fx_Rc);
	endsub;

	function fx_check_lotti_vs_collateral (codAsta, codLotto $, codCollateral $, flgLkpImm $) $;
	 Attrib fx_Rc Length=$5;
		*-- The param named codStatoRapporto will not be used, because of it used in perimeter;
		fx_rc = ifc(flgLkpImm='N' And not missing(codAsta) And not missing(codLotto),'Y','N');
  return (fx_Rc);
	endsub;

	function fx_check_pba_fake (flgLkpImm $, codAsta, impAsta, impPerizia , numAste, codCollateral $, codScollateral $) $;
	 Attrib fx_Rc					Length=$5
					pctBase				Length=8
					basePerizia      Length=8
					;
		pctBase  = 25;
		*-- The param named codStatoRapporto will not be used, because of it used in perimeter;
	 	fx_Rc = 'N';
	 	if flgLkpImm='Y' Then Do;
			basePerizia = impPerizia;
			%*-- Decreasing Base Asta;
			do _i=1 To numAste;
				basePerizia = basePerizia-(basePerizia*(pctBase/100));
			end;
			fx_rc = ifc((impAsta<basePerizia) or (impAsta>impPerizia*(1+(pctBase/100))),'Y','N');
		end;
  return (fx_Rc);
	endsub;

	function fx_check_vendita_asta (codAsta, dtaAsta , impVendita, impBaseAsta) $;
	 Attrib fx_Rc					Length=$5
					pctBase				Length=8
					;
		pctBase  = 25;
		if not missing(dtaAsta) then Do;
			_baseAstaInf = impBaseAsta - (impBaseAsta*(pctBase/100));
			_baseAstaSup = impBaseAsta * (1+(pctBase/100));
			fx_rc = ifc(impVendita<=_baseAstaInf or impVendita>_baseAstaSup,'Y','N');
		end;
  return (fx_Rc);
	endsub;

	/*-- End Function about Aste e Lotti --*/

	/*-- Start Function about Collegamenti --*/
	function fx_check_garante_in_coll (ndgGarante, flglkpCoint $) $;
	 Attrib fx_Rc Length=$5;
		*-- The param named codStatoRapporto will not be used, because of it used in perimeter;
		fx_rc = ifc(flglkpCoint='N' And not missing(ndgGarante),'Y','N');
  return (fx_Rc);
	endsub;

	function fx_check_garante_in_anag (ndgGarante, flglkpAnag $) $;
	 Attrib fx_Rc Length=$5;
		*-- The param named codStatoRapporto will not be used, because of it used in perimeter;
		fx_rc = ifc(flglkpAnag='N' And not missing(ndgGarante),'Y','N');
  return (fx_Rc);
	endsub;
	/*-- End Function about Collegamenti --*/

	/*-- Start Function about Lotti --*/
	function fx_check_lotto_vs_bene (codLotto $, codCollateral $, flgLkpImm $) $;
	 Attrib fx_Rc Length=$5;
		*-- The param named codStatoRapporto will not be used, because of it used in perimeter;
		fx_rc = ifc(not missing(codLotto) And flgLkpImm='N','Y','N');
  return (fx_Rc);
	endsub;

	function fx_check_lotto_vs_ctu (codLotto $, codCollateral $, codSubColl $, flgLkpAste $, impPerizia) $;
	 Attrib fx_Rc Length=$5;
		*-- The param named codStatoRapporto will not be used, because of it used in perimeter;
		fx_rc = ifc(not missing(codLotto) And flgLkpAste='N','Y','N');
  return (fx_Rc);
	endsub;

	/*-- End Function about Lotti --*/

Quit;
