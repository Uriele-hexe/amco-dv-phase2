/*{                                                                                                                                                                                                                                                             
	"Descrizione": "Macro che importa i metadati ed effettua la configurazione di progetto.",                                                                                                                                                                      
	"Parametri": [                                                                                                                                                                                                                                                 
		{ "config_mtd": "Nome del metadato di configurazione." },                                                                                                                                                                                                     
		{ "whr_clause": "Clausola di where da applicare in fase di estrazione del metadato di configurazione (xlsx) di input." }                                                                                                                                      
	],                                                                                                                                                                                                                                                             
	"Return": "void: non ritorna alcun valore.",                                                                                                                                                                                                                   
	"Esempio": "<code>%config(%str(/&cfg_path./config.xlsx));",                                                                                                                                                                                                    
	"Autore": "Hexe S.p.A.",                                                                                                                                                                                                                                       
	"Sito web": "<http://www.hexeitalia.com>",                                                                                                                                                                                                                     
	"Email": "<info@hexeitalia.com>",                                                                                                                                                                                                                              
	"Manutentori": [ "Hexe S.p.A." ]                                                                                                                                                                                                                               
}*/                                                                                                                                                                                                                                                             
                                                                                                                                                                                                                                                                
%macro config(config_mtd, whr_clause=1 ) / store secure ;                                                                                                                                                                                                       
                                                                                                                                                                                                                                                                
    %import_xlsx_sheets(%bquote(&config_mtd.), work, whr_clause=%bquote(&whr_clause.));                                                                                                                                                                         
                                                                                                                                                                                                                                                                
    %set_params(global_params);                                                                                                                                                                                                                                 
    %set_options(options);                                                                                                                                                                                                                                      
    %set_libs(librefs);                                                                                                                                                                                                                                         
                                                                                                                                                                                                                                                                
    proc format library=work cntlin=formats;run;                                                                                                                                                                                                                
                                                                                                                                                                                                                                                                
%mend config;                                                                                                                                                                                                                                                   