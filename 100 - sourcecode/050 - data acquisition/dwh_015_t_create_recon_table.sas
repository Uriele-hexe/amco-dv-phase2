
%macro dwh_010_t_create_recon_table;

	%local 
		_check_filiale_ptf_dsname_ _dscheck_match_ 
		_ds_recon_name_ _ds_source_tab_name 
		_nobs_out_recon _nobs_out_src_tab 
		i _ds_intermediate_recon
	;

	%let _check_filiale_ptf_dsname_ = datichk.check_filiali_ptf;
	%let _dscheck_match_ = datichk.check_match_recons;

	%* Prima join per creare tabella di raccordo totale;
	%hx_join_from_mtd(&meta_dslkp_name., RECON.TABLE.1);

	%**
	* 1. Controllo che siano stati agganciati tutti i record tramite il flag creato automaticamente dalla macro di join.
	*    Se il valore del flag equivale a N allora non abbiamo agganciato.
	*    In questo caso mando in errore.
	;
	%let _ds_recon_name_ = %get_value(&meta_dslkp_name., Target_Out, %bquote(Id_lookup = 'RECON.TABLE.1'));
	%let _ds_source_tab_name = %get_value(&meta_dslkp_name., Source_Table, %bquote(Id_lookup = 'RECON.TABLE.1'));

	proc sql;
		create table &_check_filiale_ptf_dsname_. as
		select distinct 
			cod_filiale
			,cod_portafoglio_gest
			,des_portafoglio_gest
			,flglkp_RECON_TABLE_1
		from &_ds_recon_name_.
		where flglkp_RECON_TABLE_1 = 'N'
		;
	quit;
	data _null_;
		set &_check_filiale_ptf_dsname_. (keep = flglkp_RECON_TABLE_1);
		if flglkp_RECON_TABLE_1 = 'N' then do;
			call execute('%log(level=E, msg=Non sono stati agganciati alcuni codici portafoglio durante la creazione della tabella di raccordo totale. Controllare tabella &_check_filiale_ptf_dsname_.)');
			stop;
		end;
	run;

	%**
	* 2. Controllo che non siano aumentati i record rispetto alla tabella di origine (rapporti).
	*    Se cosi fosse significa che per almeno un codice filiale presente nella tabella di origine
	*    abbiamo trovato più di una associazione con due o più portafogli diversi nella tabella delle filiali.
	*    Anche in questo caso mando in errore.
	;
	%let _nobs_out_recon = %attrn(&_ds_recon_name_., NOBS);
	%let _nobs_out_src_tab = %attrn(&_ds_source_tab_name., NOBS);

	%if %sysevalf(&_nobs_out_recon. > &_nobs_out_src_tab., boolean) %then %do;
		%log(level=E, msg= Trovate multiple associazioni tra codice filiale e codice portafoglio. 
			Num record post join in tabella &_ds_recon_name_.:&_nobs_out_recon.
			Num record input in tabella &_ds_source_tab_name.:&_nobs_out_src_tab.
		);
		%return;
	%end;

	%do i=1 %to 7;
		%* Seconda join per creare tabella di raccordo totale;
		%hx_join_from_mtd(&meta_dslkp_name., RECON.TABLE.&i.);

		%* Aggiorno tabella di controllo con le statistiche di aggancio di ogni singola join;
		%let _ds_intermediate_recon = %get_value(&meta_dslkp_name., Target_Out, %bquote(Id_lookup = "RECON.TABLE.&i."));

		proc sql;
			create table flglkp_recon_&i. as
			select 
				"&DTA_REFERENCE."d 			as dta_riferimento 	length=8	format=date9.
				,&COD_IST.					as cod_istituto		length=8	format=20.
				,"flglkp_RECON_TABLE_&i."	as flag_match_name 	length=32 	format=$32.
				,flglkp_RECON_TABLE_&i.		as flg_match_value 	length=1 	format=$1.
				,count(*) 					as num_record		length=8	format=comma12.
			from &_ds_intermediate_recon.
			group by 1,2,3,4
			;
		quit;
		%if %sysfunc(exist(&_dscheck_match_.)) %then %do;
			proc sql;
				delete from &_dscheck_match_.
				where dta_riferimento="&DTA_REFERENCE."d and cod_istituto=&COD_IST. and flag_match_name = "flglkp_RECON_TABLE_&i."
				;
			quit;
		%end;
		proc append 
			base=&_dscheck_match_.
			data=flglkp_recon_&i.;
		run;
	%end;

%mend;
%dwh_010_t_create_recon_table;
%Let tableOutName = %sysfunc(fx_get_dsname_outjoin(&meta_dslkp_name.,RECON.TABLE,msgFunction));
%Put &=tableOutName;
%hx_create_formats (libout		  = work
	 				,dsSourceFmt  = &tableOutName.
	 			    ,startV	      = cod_portafoglio_gest
	 				,descriptionV = des_portafoglio_gest
	 				,fmtName 	  = portafoglio);

