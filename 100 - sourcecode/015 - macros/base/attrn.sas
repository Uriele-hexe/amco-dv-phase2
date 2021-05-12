/*{                                                                                                                                                                                                                                                             
	"Descrizione": "Macro per gestire la funzione attrn.",                                                                                                                                                                                                         
	"Parametri": [                                                                                                                                                                                                                                                 
		{ "ds": "Nome della tabella." },                                                                                                                                                                                                                              
		{ "attrib": "Nome dell' attributo numerico che si vuole cercare." }                                                                                                                                                                                           
	],                                                                                                                                                                                                                                                             
	"Return": "Il valore numerico dell'attributo richiesto attraverso il parametro attrib.",                                                                                                                                                                       
	"Esempio": "<code>%let nr_obs_tab = %attrn(sashelp.class, nobs);",                                                                                                                                                                                             
	"Autore": "Hexe S.p.A.",                                                                                                                                                                                                                                       
	"Sito web": "<http://www.hexeitalia.com>",                                                                                                                                                                                                                     
	"Email": "<info@hexeitalia.com>",                                                                                                                                                                                                                              
	"Manutentori": [ "Hexe S.p.A." ]                                                                                                                                                                                                                               
}*/                                                                                                                                                                                                                                                             
                                                                                                                                                                                                                                                                
%macro attrn(dsname, attrib ) / store secure ;                                                                                                                                                                                                                  
                                                                                                                                                                                                                                                                
	%local _dsid _rc;                                                                                                                                                                                                                                              
                                                                                                                                                                                                                                                                
	%if %is_empty(&dsname.) %then %do;                                                                                                                                                                                                                             
		%log(level = E, msg = Empty parameter dsname in macrofunction &sysmacroname..);                                                                                                                                                                               
		%return;                                                                                                                                                                                                                                                      
	%end;                                                                                                                                                                                                                                                          
	%if %is_empty(&attrib.) %then %do;                                                                                                                                                                                                                             
		%log(level = E, msg = Empty parameter attrib in macrofunction &sysmacroname..);                                                                                                                                                                               
		%return;                                                                                                                                                                                                                                                      
	%end;                                                                                                                                                                                                                                                          
	%if %sysfunc(exist(&dsname.)) = 0 %then %do;                                                                                                                                                                                                                   
	 	%log(level = E, msg = Dataset &dsname. does not exist.);                                                                                                                                                                                                     
		%return;                                                                                                                                                                                                                                                      
	%end;                                                                                                                                                                                                                                                          
                                                                                                                                                                                                                                                                
	%let _dsid = %sysfunc(open(&dsname, is));                                                                                                                                                                                                                      
	%if &_dsid. eq 0 %then %do;                                                                                                                                                                                                                                    
		%log(level = E, msg = Cannot open dataset &dsname.);                                                                                                                                                                                                          
		%goto exit;                                                                                                                                                                                                                                                   
	%end;                                                                                                                                                                                                                                                          
	%else %do;                                                                                                                                                                                                                                                     
	  %sysfunc(attrn(&_dsid., &attrib.))                                                                                                                                                                                                                           
	%end;                                                                                                                                                                                                                                                          
                                                                                                                                                                                                                                                                
%exit:                                                                                                                                                                                                                                                          
	%let _dsid = %sysfunc(close(&_dsid.));                                                                                                                                                                                                                         
	                                                                                                                                                                                                                                                               
%mend attrn;                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                