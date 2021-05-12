/*{                                                                                                                                                                                                                                                             
    "title": "data_cleanup.sas",                                                                                                                                                                                                                                
    "desc": "Macrofunzione che svecchia una tabella in base a un intervallo di tempo e un numero di periodi indicato.",                                                                                                                                         
    "params": [                                                                                                                                                                                                                                                 
        { "dsname": "Nome tabella da svecchiare." },                                                                                                                                                                                                            
        { "trash_dset": "Nome tabella in cui smistare i record vecchi." },                                                                                                                                                                                      
        { "date_variable": "Nome variabile di tipo data sas del dataset da usare come criterio di svecchiamento." },                                                                                                                                            
        { "num_per": "Numero di periodi da mantenere sulla tabella." },                                                                                                                                                                                         
        { "interval": "Intervallo che indica i periodi (day, month, year)" }                                                                                                                                                                                    
    ],                                                                                                                                                                                                                                                          
    "return": "void: non ritorna alcun valore.",                                                                                                                                                                                                                
    "example": "%data_cleanup(dsname=dw_class, trash_dset=dw_class_old,	date_variable=data_rif,	num_per=12,	interval=month);",                                                                                                                                  
    "author": "Hexe S.p.A.",                                                                                                                                                                                                                                    
    "website": "http://www.hexeitalia.com",                                                                                                                                                                                                                     
	"email": "info@hexeitalia.com",                                                                                                                                                                                                                                
	"mantainers": [ "Hexe S.p.A." ]                                                                                                                                                                                                                                
}*/                                                                                                                                                                                                                                                             
                                                                                                                                                                                                                                                                
%macro data_cleanup(dsname=, trash_dset=, date_variable=, num_per=, interval= ) / store secure ;                                                                                                                                                                
                                                                                                                                                                                                                                                                
    %local _max_dt;                                                                                                                                                                                                                                             
                                                                                                                                                                                                                                                                
    proc sql noprint;                                                                                                                                                                                                                                           
        select max(&date_variable.) into :_max_dt                                                                                                                                                                                                               
        from &dsname.;                                                                                                                                                                                                                                          
    quit;                                                                                                                                                                                                                                                       
                                                                                                                                                                                                                                                                
    data &dsname. &trash_dset.;                                                                                                                                                                                                                                 
        set &dsname.;                                                                                                                                                                                                                                           
        if &date_variable. <= intnx("&interval.", &_max_dt., -&num_per., 's') then output &trash_dset.;                                                                                                                                                         
        else output &dsname.;                                                                                                                                                                                                                                   
    run;                                                                                                                                                                                                                                                        
                                                                                                                                                                                                                                                                
%mend data_cleanup;                                                                                                                                                                                                                                             