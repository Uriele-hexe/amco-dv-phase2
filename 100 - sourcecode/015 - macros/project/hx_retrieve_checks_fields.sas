/*{                                                                                                                                                                                                                                                             
    "Title": "hx_retrieve_checks_fields"                                                                                                                                                                                                                        
	"Descrizione": "Use ldt tassonomia as Starting point. Retrieve list of fields from  perimeter and tecnical fields",                                                                                                                                            
	"Parametri": [                                                                                                                                                                                                                                                 
		{ "idAmbito": "Id.Ambito" },                                                                                                                                                                                                                                  
	],                                                                                                                                                                                                                                                             
	"Return": "Dataset by dsNameOut parameter",                                                                                                                                                                                                                    
	"Autore": "Hexe S.p.A.",                                                                                                                                                                                                                                       
	"Sito web": "<http://www.hexeitalia.com>",                                                                                                                                                                                                                     
	"Email": "<info@hexeitalia.com>",                                                                                                                                                                                                                              
	"Manutentori": [ "Hexe S.p.A." ]                                                                                                                                                                                                                               
}*/                                                                                                                                                                                                                                                             
                                                                                                                                                                                                                                                                
                                                                                                                                                                                                                                                                
%macro hx_retrieve_checks_fields (idAmbito=G,dsNameOut=hx_retrieve_checks_fields ) / store secure ;                                                                                                                                                             
  %Local _tmpStamp                                                                                                                                                                                                                                              
	;                                                                                                                                                                                                                                                              
  %Let _tmpStamp = %sysfunc(putn(%sysfunc(datetime()),datetime.));                                                                                                                                                                                              
  %Put +---[Macro: &sysmacroname.] -----------------+;                                                                                                                                                                                                          
  %Put | Retrieve fields.	    	        	    |;                                                                                                                                                                                                                  
  %Put | About idAmbito : &idAmbito.    			|;                                                                                                                                                                                                                   
  %Put |............................................|;                                                                                                                                                                                                          
  %Put | Started at: &_tmpStamp.;                                                                                                                                                                                                                               
  %Put +--------------------------------------------+;                                                                                                                                                                                                          
                                                                                                                                                                                                                                                                
  Data _null_;                                                                                                                                                                                                                                                  
    Attrib campoTecnico Length=$80                                                                                                                                                                                                                              
           CampiTecnici Length=$1000                                                                                                                                                                                                                            
		   perimetro    Length=$1000                                                                                                                                                                                                                                  
       ;                                                                                                                                                                                                                                                        
    Declare hash ht(ordered:'yes');                                                                                                                                                                                                                             
      ht.defineKey("campoTecnico");                                                                                                                                                                                                                             
      ht.defineData("campoTecnico");                                                                                                                                                                                                                            
      ht.defineDone();                                                                                                                                                                                                                                          
                                                                                                                                                                                                                                                                
    dsDwhMetaChecks = "&dsDwhMetaChecks.";                                                                                                                                                                                                                      
    Put dsDwhMetaChecks=;                                                                                                                                                                                                                                       
    _dsid           = open(catx(' ',dsDwhMetaChecks,cats("(Where=(id_Ambito='",Symget("idAmbito"),"'))")));                                                                                                                                                     
    Do While(Fetch(_dsid)=0);                                                                                                                                                                                                                                   
      CampiTecnici = GetvarC(_dsid,Varnum(_dsid,"Campi_Tecnici"));                                                                                                                                                                                              
	   perimetro   = GetvarC(_dsid,Varnum(_dsid,"Perimetro_di_applicabilita"));                                                                                                                                                                                    
      _rc          = count(CampiTecnici,'-')+1;                                                                                                                                                                                                                 
      Do _i=1 To _rc;                                                                                                                                                                                                                                           
        campoTecnico = Strip(Scan(CampiTecnici,_i,'-'));                                                                                                                                                                                                        
        _rcAdd       = ht.add();                                                                                                                                                                                                                                
      End;                                                                                                                                                                                                                                                      
      flgInfoPerimetro = 'Y';                                                                                                                                                                                                                                   
      Do While(flgInfoPerimetro='Y' and not missing(perimetro));                                                                                                                                                                                                
        whereIsField = prxmatch("/#/i",perimetro);                                                                                                                                                                                                              
        flgInfoPerimetro = ifc(whereIsField>0,'Y','N');                                                                                                                                                                                                         
        if flgInfoPerimetro='Y' then do;                                                                                                                                                                                                                        
          perimetro    = substr(perimetro,whereIsField+1);                                                                                                                                                                                                      
          campoTecnico = strip(scan(perimetro,1,'#'));                                                                                                                                                                                                          
          _rcAdd       = ht.add();                                                                                                                                                                                                                              
          whereIsField = prxmatch("/#/i",perimetro);                                                                                                                                                                                                            
          if whereIsField>0 then perimetro = substr(perimetro,whereIsField+1);                                                                                                                                                                                  
        end;                                                                                                                                                                                                                                                    
      End;                                                                                                                                                                                                                                                      
    End;                                                                                                                                                                                                                                                        
    _dsid  = close(_dsid);                                                                                                                                                                                                                                      
    _rcOut = ht.output(dataset:"&dsNameOut.");                                                                                                                                                                                                                  
  Run;                                                                                                                                                                                                                                                          
%Mend;                                                                                                                                                                                                                                                          
