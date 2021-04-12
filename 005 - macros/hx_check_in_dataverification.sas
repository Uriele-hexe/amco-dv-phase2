/*{
    "Program": "hx_check_in_dataverification"
	"Descrizione": "For any changes check if there are impact on data verification engine",
	"Parametri": [
		"dsDMchecked":"Output macro hx_check_dwh_datamodel"
		"dsDataChecks":"List of checks" 
	],
	"Return": "dataset named: work.hx_check_in_dataverification",
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
}*/

%Macro hx_check_in_dataverification (dsDMchecked=work.hx_check_dwh_datamodel
							   ,dsDataChecks=metadata.DWH_TASSONOMIA_CONTROLLI) 
				/ Des = "For any changes check if there are impact on data verification engine";
	%local _dttimeStamp _dsOutCheckDM
	   ;

	%Let _dttimeStamp  = %sysfunc(datetime());
	%Put +----[Macro: &sysmacroname.] --------------------------+;
	%Put | Check for any impact on the data verification engine |;
	%Put | .................................................... |;
	%Put | Started at : %Sysfunc(PutN(&_dttimeStamp.,datetime.));
	%Put +----[Macro: &sysmacroname.] --------------------------+;

    Data _null_; 
      Set &dsDMchecked. end=fine;
      Attrib flgInPerimeter length=$1  label="Field is used in perimeter (Y/N)"
             flgInTecnical  length=$1  label="It is a tecnical field (Y/N)"
             idRule         length=$40 label="Id rule impacted"
           ;
      Retain _dsDataVerification "&dsDataChecks."
         ;
      Declare hash ht(multidata:'yes');
        ht.defineKey("idRecord");
        ht.defineData("idRecord","dsDwhTable","dwhFieldName","flgInPerimeter","flgInTecnical","idRule");
        ht.defineDone();

      flgInPerimeter = 'N';
      flgInTecnical  = 'N';
      _dsid          = open(_dsDataVerification);
      Do While (fetch(_dsid)=0);
        IdRule          = Getvarc(_dsid,varnum(_dsid,"idRule"));
        _PA             = Getvarc(_dsid,varnum(_dsid,"Perimetro_di_applicabilita"));
        _CT             = Getvarc(_dsid,varnum(_dsid,"Campi_Tecnici")); 
        flgInPerimeter  = ifc(prxmatch(cats("/",dwhFieldName,"/i"),_PA)>0,'Y','N');
        flgInTecnical   = ifc(prxmatch(cats("/",dwhFieldName,"/i"),_CT)>0,'Y','N');
        _rcadd          = ht.add();
      End;
      _dsid = Close(_dsid);
      if fine then _rcout = ht.output(dataset:"work.&sysmacroname.");
    Run;

    %Uscita:
	  %Let _dttimeStamp  = %sysfunc(datetime());
	  %Put +----[Macro: &sysmacroname.] --------------------------+;
	  %Put | Check for any impact on the data verification engine |;
	  %Put | .................................................... |;
	  %Put | Ended at : %Sysfunc(PutN(&_dttimeStamp.,datetime.));
	  %Put +----[Macro: &sysmacroname.] --------------------------+;
%Mend;
%hx_check_in_dataverification();
