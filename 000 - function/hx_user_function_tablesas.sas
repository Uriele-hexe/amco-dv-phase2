*=======================================================================================
* Macro       : hx_user_function_tablesas
* Description : It contains function regarding dataset sas
* --------------------------------------------------------------------------------------
* Created by    : Uriele De Piano Hexe (SpA)
* Creation date : 31 October 2020
*=======================================================================================
;
*--Libname hx_func "E:\progetti\Utility\hx_functions";

Proc fcmp outlib=hx_func.tablesas.package encrypt;
  function hx_get_nobs(dsName $) ;
    Attrib dsid			 Length=8	
					 recNumber Length=8
	       ;
		recNumber = -9999999;
		If exist(dsName) Then Do;
			dsid = Open(dsName);
			recNumber = Attrn(dsid,"NOBS");
			dsid = Close(dsid);
		End;
  return (recNumber);
  endsub;

  function hx_get_nvars(dsName $) ;
    Attrib dsid			  Length=8	
					 varsNumber Length=8
	       ;
		varsNumber = -9999999;
		If exist(dsName) Then Do;
			dsid 			 = Open(dsName);
			varsNumber = Attrn(dsid,"NVARS");
			dsid 			 = Close(dsid);
		End;  
  return (varsNumber);
  endsub;

  function hx_get_crdte(dsName $) ;
    Attrib dsid		Length=8	
					 crtDte Length=8
	       ;
		Call Missing(crtDte);
		If exist(dsName) Then Do;
			dsid 	 = Open(dsName);
			crtDte = Attrn(dsid,"MODTE");
			dsid 	 = Close(dsid);
		End;  
  return (crtDte);
  endsub;

	function fx_retrieve_first_array_value(arrayVariable $) $ ;
    Attrib arrayValue			Length=$5000	
					 fx_firstValue	Length=$256
					 nElementi			Length=8
	       ;
		Call Missing(fx_firstValue);
		arrayValue = substr(scan(strip(arrayVariable),1,']','b'),2); 
		nElementi  = count(arrayValue,',')+1;
		*Put arrayValue=;
		Do _i=1 To nElementi;
			fx_firstValue = scan(arrayValue,_i,',',"mqr");
			If not missing(fx_firstValue) Then _i = Sum(nElementi,1);
		End;
		/*If missing(fx_firstValue) Then fx_firstValue = "N.D";*/
  return (fx_firstValue);
  endsub;

Quit;
