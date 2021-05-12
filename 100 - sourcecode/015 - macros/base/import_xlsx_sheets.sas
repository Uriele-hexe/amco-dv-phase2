/*{                                                                                                                                                                                                                                                             
	"Descrizione": "Macro che importa tutti i fogli di un file xlsx.",                                                                                                                                                                                             
	"Parametri": [                                                                                                                                                                                                                                                 
		{ "xlsx": "Nome del file xlsx da importare." },                                                                                                                                                                                                               
        { "lib_out": "Libreria di output in cui creare i dataset ottenuti importando il file xlsx." },                                                                                                                                                          
        { "whr_clause": "Clausola di where da applicare in fase di estrazione del file xlsx di input." }                                                                                                                                                        
	],                                                                                                                                                                                                                                                             
	"Return": "void: non ritorna alcun valore.",                                                                                                                                                                                                                   
	"Esempio": "<code>%import_xlsx_sheets(%str(/path/to/file/excel.xlsx), work); %import_xlsx_sheets(%str(/path/to/file/excel.xlsx), myLib, whr_clause=%bquote(id='id.1'));",                                                                                      
	"Autore": "Hexe S.p.A.",                                                                                                                                                                                                                                       
	"Sito web": "<http://www.hexeitalia.com>",                                                                                                                                                                                                                     
	"Email": "<info@hexeitalia.com>",                                                                                                                                                                                                                              
	"Manutentori": [ "Hexe S.p.A." ]                                                                                                                                                                                                                               
}*/                                                                                                                                                                                                                                                             
                                                                                                                                                                                                                                                                
%macro import_xlsx_sheets(xlsx, lib_out, whr_clause=1 ) / store secure ;                                                                                                                                                                                        
                                                                                                                                                                                                                                                                
    %local _dsid _memname;                                                                                                                                                                                                                                      
                                                                                                                                                                                                                                                                
    libname _inp xlsx "%unquote(&xlsx.)";                                                                                                                                                                                                                       
    proc contents data = _inp._all_ out=_cnt_ (keep=memname) noprint; run;                                                                                                                                                                                      
    proc sort data=_cnt_ nodupkey; by memname; run;                                                                                                                                                                                                             
    %let _dsid = %sysfunc(open(_cnt_));                                                                                                                                                                                                                         
    %do %while(%sysfunc(fetch(&_dsid.))=0);                                                                                                                                                                                                                     
        %let _memname = %sysfunc(getvarc(&_dsid., %sysfunc(varnum(&_dsid., memname))));                                                                                                                                                                         
        data &lib_out.."&_memname."n;                                                                                                                                                                                                                           
            set _inp."&_memname."n (where=(%unquote(&whr_clause.)));                                                                                                                                                                                            
        run;                                                                                                                                                                                                                                                    
    %end;                                                                                                                                                                                                                                                       
    %let _dsid = %sysfunc(close(&_dsid.));                                                                                                                                                                                                                      
                                                                                                                                                                                                                                                                
    libname _inp clear;                                                                                                                                                                                                                                         
                                                                                                                                                                                                                                                                
%mend import_xlsx_sheets;                                                                                                                                                                                                                                       