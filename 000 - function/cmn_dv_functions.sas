/*{
    "Program": "cmn_dv_functions.sas"
	"Descrizione": "Define all functions regarding data acquisition engine",
	"Parametri": [
		"hx_func":"Libname containing functions"
	],
	"Return": [
	   "dataset named : ",
	   ],
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
	"Note":"All parameters used in macro was declared in global macro variable"
}*/

Proc Fcmp outlib=hx_func.cmn_dv_function.package encrypt;
  function fx_retrieve_first_array_value(a_values $) $;
    Length a_string $255
           n_elemn  8
        ;
    Call Missing(a_string);   
    _a_values = prxchange('s/\[|\]|\"//',-1,a_values);
    n_elemn   = count(_a_values,',')+1;
    Do _e=1 To n_elemn;
      if not missing(scan(_a_values,_e,',')) then 
        a_string = catx(',',a_string,scan(_a_values,_e,','));
    End;
  return (a_string);
  endsub;

  function fx_get_dsname_outjoin(dsMeta $, lkpGroup $,  msgFx $) $;
		Outargs msgFx;
		Attrib 	tableName 	Length=$80
						dsid				Length=8
						vLookupGrp 	Length=$40
						vTableOut		Length=$40
				;
		vLookupGrp = "id_Lookup_Group";
		vTableOut	 = "Target_Out";
		Call missing(tableName,msgFx);
		If not exist(dsMeta) Then msgFx = catx(' ',dsMeta,"not exists!");
		Else Do;
			dsid    = open(dsMeta);
			posVlkp = varnum(dsid,vLookupGrp);
			posVtab = varnum(dsid,vTableOut);

			If posVlkp<=0 Then msgFx = catx(' ',vLookupGrp,"not exists in",dsMeta);
			Else If posVtab<=0 Then msgFx = catx(' ',vTableOut,"not exists in",dsMeta);
			Else Do;
				Do While (fetch(dsid)=0 And missing(tableName));
					If Strip(Upcase(getvarc(dsid,posVlkp))) = Strip(Upcase(lkpGroup)) Then Do;
						If count(getvarc(dsid,posVtab),'.')=1 then
							tableName = ifc(upcase(scan(getvarc(dsid,posVtab),1,'.')) ^= "WORK"
															,getvarc(dsid,posVtab)
															,' ');
					End;
				End;
			End;
			dsid = Close(dsid);
		End;
	return (tableName);
	endsub;
Run;