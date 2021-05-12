/*{                                                                                                                                                                                                                                                             
	"Descrizione": "Macro che setta dinamicamente opzioni di sessione inserite in un metadato specifico (Colonne obbligatorie: [OPTION]).",                                                                                                                        
	"Parametri": [                                                                                                                                                                                                                                                 
		{ "dset": "Nome del dataset metadato contenente le opzioni da settare." },                                                                                                                                                                                    
		{ "whr_clause": "Clausola di where da applicare in fase di estrazione del metadato di input." }                                                                                                                                                               
	],                                                                                                                                                                                                                                                             
	"Return": "void: non ritorna alcun valore.",                                                                                                                                                                                                                   
	"Esempio": "<code>%set_options(mtd_options);",                                                                                                                                                                                                                 
	"Autore": "Hexe S.p.A.",                                                                                                                                                                                                                                       
	"Sito web": "<http://www.hexeitalia.com>",                                                                                                                                                                                                                     
	"Email": "<info@hexeitalia.com>",                                                                                                                                                                                                                              
	"Manutentori": [ "Hexe S.p.A." ]                                                                                                                                                                                                                               
}*/                                                                                                                                                                                                                                                             
                                                                                                                                                                                                                                                                
%macro set_options(dset, whr_clause=1 ) / store secure ;                                                                                                                                                                                                        
                                                                                                                                                                                                                                                                
	%local _options;                                                                                                                                                                                                                                               
                                                                                                                                                                                                                                                                
	data _null_;                                                                                                                                                                                                                                                   
		set &dset. (where=(%unquote(&whr_clause.))) end=eof;                                                                                                                                                                                                          
		length _opt $1000;                                                                                                                                                                                                                                            
		retain _opt "";                                                                                                                                                                                                                                               
                                                                                                                                                                                                                                                                
		_opt = catx(' ', _opt, strip(option));                                                                                                                                                                                                                        
                                                                                                                                                                                                                                                                
		if eof then call symput('_options', strip(_opt));                                                                                                                                                                                                             
	run;                                                                                                                                                                                                                                                           
                                                                                                                                                                                                                                                                
	%log(msg = Setting options: [&_options.]);                                                                                                                                                                                                                     
                                                                                                                                                                                                                                                                
	options &_options.;                                                                                                                                                                                                                                            
                                                                                                                                                                                                                                                                
%mend set_options;                                                                                                                                                                                                                                              