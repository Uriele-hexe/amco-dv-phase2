*============================================================================================                                                                                                                                                                   
* Client Name: AMCO SpA                                                                                                                                                                                                                                         
* Project    : Framework di Data Verification                                                                                                                                                                                                                   
*--------------------------------------------------------------------------------------------                                                                                                                                                                   
* Program name: hx_create_table_trace                                                                                                                                                                                                                           
* Author      : Uriele De Piano Hexe SpA 02 October 2020                                                                                                                                                                                                        
* Description : Creation of table trace                                                                                                                                                                                                                         
*--------------------------------------------------------------------------------------------                                                                                                                                                                   
* NOTE: Use two global macro variable                                                                                                                                                                                                                           
*============================================================================================                                                                                                                                                                   
;                                                                                                                                                                                                                                                               
                                                                                                                                                                                                                                                                
%Macro hx_create_table_trace(dataTrace=_NULL_ ) / store secure ;                                                                                                                                                                                                
	%local folderTrace                                                                                                                                                                                                                                             
	   ;                                                                                                                                                                                                                                                           
	%Let folderTrace = %sysfunc(pathName(%qscan(&dataTrace.,1,%NrQuote(.))));                                                                                                                                                                                      
	%Let tmpStamp = %sysfunc(putn(%sysfunc(datetime()),datetime.));                                                                                                                                                                                                
                                                                                                                                                                                                                                                                
	%if %sysfunc(exist(&dataTrace.))=0 %then %do;                                                                                                                                                                                                                  
		%Put +-- [Macro: &sysmacroname.] --------------------------------------------------;                                                                                                                                                                          
		%Put | Create Table Trace                                           							 ;                                                                                                                                                                                 
  	%Put |   Data trace : &dataProvider. 		     		                                   ;                                                                                                                                                                           
		%Put |   Folder     : &folderTrace.                                                ;                                                                                                                                                                          
		%Put |.............................................................................;                                                                                                                                                                          
		%Put | Starting at: &tmpStamp.																										 ;                                                                                                                                                                                                    
		%Put +-----------------------------------------------------------------------------;                                                                                                                                                                          
                                                                                                                                                                                                                                                                
		data &dataTrace. ;                                                                                                                                                                                                                                            
			Attrib idTransaction 	Length=$25 	Label="Id transaction"                                                                                                                                                                                                     
						  timeStamp			Length=8		Label="Timestamp" 				format=datetime.                                                                                                                                                                                            
							cod_ist				Length=8  	Label="Code Istitute"     format=Z5.                                                                                                                                                                                               
							dataProvider  Length=$15 	Label="Data provider"                                                                                                                                                                                                          
							phase					Length=$15	Label="ETL's phase"                                                                                                                                                                                                                 
							tableName			Length=$50	Label="Table name"                                                                                                                                                                                                                
							libname 			Length=$10	Label="Libname"                                                                                                                                                                                                                    
							dtaCreate			Length=8		Label="Creation date timestamp" format=datetime.                                                                                                                                                                                   
							recNo					Length=8		Label="Total obs"				format=commax18.                                                                                                                                                                                                
							varsNo				Length=8		Label="Total columns" 			format=commax12.                                                                                                                                                                                            
							;                                                                                                                                                                                                                                                        
			Delete;                                                                                                                                                                                                                                                      
		run;                                                                                                                                                                                                                                                          
	%end;                                                                                                                                                                                                                                                          
%mend;                                                                                                                                                                                                                                                          