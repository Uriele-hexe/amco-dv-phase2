*============================================================================================                                                                                                                                                                   
* Client Name: AMCO SpA                                                                                                                                                                                                                                         
* Project    : Framework di Data Verification                                                                                                                                                                                                                   
*--------------------------------------------------------------------------------------------                                                                                                                                                                   
* Program name: hx_set_flag_distinct                                                                                                                                                                                                                            
* Author      : Uriele De Piano Hexe SpA 02 October 2020                                                                                                                                                                                                        
* Description : The macro creates a flag valued in Y in the corresponding first key, N for the                                                                                                                                                                  
*						    other cases                                                                                                                                                                                                                                          
*								                                                                                                                                                                                                                                                       
*--------------------------------------------------------------------------------------------                                                                                                                                                                   
* NOTE:                                                                                                                                                                                                                                                         
*--------------------------------------------------------------------------------------------                                                                                                                                                                   
* CHANGE HISTORY     
*   Code        : FLG_PORT_ALL
*   Description : Duplicate primary key to assign cod_portafoglio_gest=_ALL_
*   Date        : 12 May 2021
*   Onwner      : Hexe S.p.A (Uriele De Piano)                                                                                                                                                                                                                                          
*============================================================================================                                                                                                                                                                   
;                                                                                                                                                                                                                                                               
                                                                                                                                                                                                                                                                
%Macro hx_set_flag_distinct(tableOut = _NULL_                                                                                                                                                                                                                
                           ,Keys     = _NULL_                                                                                                                                                                                                                            
                           ,flagVarName = flg) / /*store secure*/; 
                                                                                                                                                                                                                                                                
	%Local checkOnKeys tableNameOut checkMessage lastKey _timeStamp _allkeys                                                                                                                                                                                                 
			;                                                                                                                                                                                                                                                            

    %Let _timeStamp = %sysfunc(datetime());
	%Let checkOnKeys  = OK;                                                                                                                                                                                                                                        
	%Let checkMessage = Preliminary checks: OK;                                                                                                                                                                                                                    
	%Let lastKey      =;                                                                                                                                                                                                                                           

	%*+----------------------------------------------------------------------------+;
	%*| Preliminary Checks. Verify that all key fields are contained in sas table. |;
	%*+----------------------------------------------------------------------------+;

	Data _null_;                                                                                                                                                                                                                                                   
		keys 				 = Strip(Symget("Keys"));                                                                                                                                                                                                                            
		tableNameOut = Strip(Symget("tableOut"));                                                                                                                                                                                                                     
		dsid         = 0;                                                                                                                                                                                                                                             
                                                                                                                                                                                                                                                                
		%*-- Declare hash table regarding process trace;                                                                                                                                                                                                              
		%hx_declare_ht_pr(htTable=&processTrace.);                                                                                                                                                                                                                    
		sourceCode    = symget("sysmacroname");                                                                                                                                                                                                                       
		stepCode      = catx(' ',"Creation distinct record flag on",tableNameOut);                                                                                                                                                                                    
		Call Missing(rcCode,msgCode);	                                                                                                                                                                                                                                
                                                                                                                                                                                                                                                                
		If not exist(tableNameOut) Then Do;                                                                                                                                                                                                                           
			rcCode  = 255;                                                                                                                                                                                                                                               
			msgCode = catx(' ',tableNameOut,"not exists!!");                                                                                                                                                                                                             
			Link esci;                                                                                                                                                                                                                                                   
		End;                                                                                                                                                                                                                                                          
		%*-- Check fields;                                                                                                                                                                                                                                            
		dsid  = open(tableNameOut);                                                                                                                                                                                                                                   
		nKeys = count(strip(keys),' ')+1;                                                                                                                                                                                                                             
		Do _v=1 To nKeys;                                                                                                                                                                                                                                             
			nomeCampo = scan(keys,_v,' ');                                                                                                                                                                                                                               
			If varnum(dsid,nomeCampo)=0 Then Do;                                                                                                                                                                                                                         
				rcCode  = 254;                                                                                                                                                                                                                                              
				msgCode = catx(' ',nomeCampo,"not exists in",dsname(dsid));                                                                                                                                                                                                 
				Link esci;                                                                                                                                                                                                                                                  
			End;                                                                                                                                                                                                                                                         
		End;                                                                                                                                                                                                                                                          
		rcCode  = 1;                                                                                                                                                                                                                                                  
		msgCode = "Preliminary checks ok";                                                                                                                                                                                                                            
		Call Symput("lastKey",scan(keys,nKeys,' '));                                                                                                                                                                                                                  
		Link esci;                                                                                                                                                                                                                                                    
		Return;                                                                                                                                                                                                                                                       
		ESCI:                                                                                                                                                                                                                                                         
			If rcCode ^= 1 Then Call Symput("checkOnKeys","KO");                                                                                                                                                                                                         
			Call Symput("checkMessage",msgCode);                                                                                                                                                                                                                         
			rc = ht.add();                                                                                                                                                                                                                                               
			rc = ht.output(dataset:"&processtrace.");                                                                                                                                                                                                                    
			If dsid>0 Then dsid = close(dsid);                                                                                                                                                                                                                           
			Stop;                                                                                                                                                                                                                                                        
		RETURN;                                                                                                                                                                                                                                                       
	Run;                                                                                                                                                                                                                                                           
                                                                                                                                                                                                                                                                
	%Put &=checkOnKeys;                                                                                                                                                                                                                                            
	%Put &=lastKey;                                                                                                                                                                                                                                                
	%If &checkOnKeys. = KO %Then %Do;                                                                                                                                                                                                                              
	  %log(level = E, msg = &checkMessage.);                                                                                                                                                                                                                       
    %return;                                                                                                                                                                                                                                                    
	%End;                                                                                                                                                                                                                                                          
                                                                                                                                                                                                                                                                
	%*+------------------------------------------+;
	%*| Creates distinct flag for each portfolio |;
	%*+------------------------------------------+;
	Proc Sort data=&tableOut.;                                                                                                                                                                                                                                     
		by &keys.;                                                                                                                                                                                                                                                    
	Run;                                                                                                                                                                                                                                                           
	Data &tableOut.;                                                                                                                                                                                                                                               
		Attrib &flagVarName. Length=$1	Label="Flag first distinct key";                                                                                                                                                                                               
		Set &tableOut.;                                                                                                                                                                                                                                               
		by &keys.;                                                                                                                                                                                                                                                    
		&flagVarName. = ifc(first.&lastKey.,'Y','N');                                                                                                                                                                                                                 
	Run;                                                                                                                                                                                                                                                           
                                                                                                                                                                                                                                                                
	Data _null_;                                                                                                                                                                                                                                                   
		keys 	     = Strip(Symget("Keys"));                                                                                                                                                                                                                            
		tableNameOut = Strip(Symget("tableOut"));                                                                                                                                                                                                                     
		%*-- Declare hash table regarding process trace;                                                                                                                                                                                                              
		%hx_declare_ht_pr(htTable=&processTrace.);                                                                                                                                                                                                                    
		sourceCode    = symget("sysmacroname");                                                                                                                                                                                                                       
		stepCode      = catx(' ',"Creation distinct record flag on",tableNameOut);                                                                                                                                                                                    
		Call Missing(rcCode,msgCode);	                                                                                                                                                                                                                                
		dsid         = open(tableNameOut);                                                                                                                                                                                                                            
		If varnum(dsid,"&flagVarName.")<=0 Then Do;                                                                                                                                                                                                                   
			rcCode  = 253;                                                                                                                                                                                                                                               
			msgCode = catx(' ',"&flagVarName.","was not created !");                                                                                                                                                                                                     
		End;                                                                                                                                                                                                                                                          
		Else Do;                                                                                                                                                                                                                                                      
			rcCode  = 253;                                                                                                                                                                                                                                               
			msgCode = catx(' ',"&flagVarName.","created !");                                                                                                                                                                                                             
		End;                                                                                                                                                                                                                                                          
		dsid = Close(dsid);                                                                                                                                                                                                                                           
		rc = ht.add();                                                                                                                                                                                                                                                
		rc = ht.output(dataset:"&processtrace.");                                                                                                                                                                                                                     
	Run;           

	%*+-[Change: FLG_PORT_ALL]----------------------------+;
	%*| Delete field cod_portafoglio_gest from macro keys |;
	%*+---------------------------------------------------+;
	%Let _allkeys =;
    data _null_;
      detailskeys = "&keys.";
      summkeys    = compbl(prxchange("s/cod_portafoglio_gest/ /",-1,detailskeys));
      Call Symput("_allkeys",Strip(summkeys));
    run;
	Proc Sort data=&tableOut.;                                                                                                                                                                                                                                     
		by &_allkeys.;                                                                                                                                                                                                                                                    
	Run;                                                                                                                                                                                                                                                           
	Data _allPortfolios;                                                                                                                                                                                                                                               
		Attrib &flagVarName. Length=$1	Label="Flag first distinct key";                                                                                                                                                                                               
		Set &tableOut.;                                                                                                                                                                                                                                               
		by &_allkeys.;                                                                                                                                                                                                                                                    
		&flagVarName. = ifc(first.&lastKey.,'Y','N'); 
		If &flagVarName.='Y' Then Do;
		  cod_portafoglio_gest = "_ALL_";
		  Output;
		End;
	Run;                                                                                                                                                                                                                                                           
    Proc Append data=_allPortfolios base=&tableOut.;
	Run;

	%*+--------------------------+;
	%*| Summarize distinct keys  |;
	%*+--------------------------+;
    Proc Sql;
      Create Table work.&sysmacroname. As
        Select cod_portafoglio_gest
		      ,count(distinct &lastKey.) as nrec
	    From &tableOut.
        group by 1
		;
    Quit;

	%*+------------------------------------------+;
	%*| Update Perimeters Staging Table [Start]  |;
	%*+------------------------------------------+;

	Proc Contents data=&dsDWHPerimeter. out=_perim_ (Keep=NAME VARNUM) noprint;
	Run;
	%Let _dsStaging = %lowcase(%Qscan(&tableOut.,2,%NrQuote(.)));
	%Let _fperim=;

	%*-- Historicize perimeteres;
	Proc Sql Noprint;
	  Select cats('"',NAME,'"') into :_fperim separated by ',' from _perim_ order by VARNUM;
	  Delete From &dsDWHPerimeter. Where 1
	  %if %symexist(cod_ist) %then %do;
	    And cod_ist=&cod_ist.
	  %end;
	    And dta_reference = "&dta_reference."D
		And stagingtable  = "&_dsStaging."
		;
	Quit;

    Data _null_;
	  %hx_cmn_attrib_from_ds(dsname=&dsDWHPerimeter.);
	  Declare hash ht(dataset:"&dsDWHPerimeter.",ordered:"yes");
	    ht.defineKey("cod_ist","dta_reference","stagingtable","cod_portafoglio_gest");
		ht.defineData(&_fperim.);
		ht.defineDone();
	  Retain idTransaction "&idTrasaction." dta_reference "&dta_reference."d
	         stagingtable "&_dsStaging." timeStamp &_timeStamp.
	         %if %symexist(cod_ist) %then %do;
		       cod_ist &cod_ist.
		     %end;
              ;
		_dsid = open("work.&sysmacroname.");
		Do While (Fetch(_dsid)=0);
		  cod_portafoglio_gest = GetvarC(_dsid,Varnum(_dsid,"cod_portafoglio_gest"));
		  nrecord              = GetvarN(_dsid,Varnum(_dsid,"nrec"));
		  rc                   = ht.add();
		End;
		_dsid = Close(_dsid);
		rc = ht.output(dataset:"&dsDWHPerimeter.");
	Run;
	%*+------------------------------------------+;
	%*| Update Perimeters Staging Table [End]    |;
	%*+------------------------------------------+;
%Mend;                                                                                                                                                                                                                                                          
