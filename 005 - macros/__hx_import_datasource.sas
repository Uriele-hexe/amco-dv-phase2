/*{
    "Program": "hx_import_datasource"
	"Descrizione": "Import in datiodd source data described in metadat npl_list",
	"Parametri": [
		"dataProvider":"Data provider"
	],
	"Return": "dataset on datiodd libname",
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
    "Note":"Macro needs to be call"
}*/

/*%Macro hx_check_dwh_datamodel (datamapping=prvmeta.dwh_data_model_raccordo
							   ,dsChecksList=&dsDWHMetaChecks.
							   ,listdwhtable=metadata.npl_sourcedata_list) 
				/ Des = "Check for any changes on the dwh table data model";
				*/
%Macro  hx_check_dwh_datamodel () / Des = "Check for any changes on the dwh table data model";
	%local _dttimeStamp 
	   ;
	%Let datamapping  = %sysfunc(dequote(&dsMetaRacc.));
    %Let dsChecksList = %sysfunc(dequote(&dsDWHMetaChecks.));
	%Let listdwhtable = %sysfunc(dequote(&nplsourcelist.));