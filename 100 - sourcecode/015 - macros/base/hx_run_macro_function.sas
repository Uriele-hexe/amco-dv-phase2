/*                                                                                                                                                                                                                                                              
Proc Fcmp outlib=hx_func.run_macro_function.run_macro_function;                                                                                                                                                                                                 
	function fx_get_packages(fxName $, fxLibname $, fxPackageList $ ) ;                                                                                                                                                                                            
		Attrib nPack Length=8                                                                                                                                                                                                                                         
					 dsid  Length=8                                                                                                                                                                                                                                            
			;                                                                                                                                                                                                                                                            
		Call Missing(nPack);                                                                                                                                                                                                                                          
 		rc = run_macro('hx_get_fx_package', fxName, fxLibname, fxPackageList);                                                                                                                                                                                       
		If exist(fxPackageList) Then Do;                                                                                                                                                                                                                              
			dsid  = open(fxPackageList);                                                                                                                                                                                                                                 
			nPack = AttrN(dsid,"NOBS");                                                                                                                                                                                                                                  
			dsid  = close(dsid);                                                                                                                                                                                                                                         
		End;                                                                                                                                                                                                                                                          
 	return(nPack);                                                                                                                                                                                                                                                
	endsub;                                                                                                                                                                                                                                                        
Run;                                                                                                                                                                                                                                                            
*/                                                                                                                                                                                                                                                              