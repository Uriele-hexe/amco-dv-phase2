/*{
    "Program": "dwh_011_data_acquisition_report.sas"
	"Descrizione": "Produce a report about import and mapping of the  source data",
	"Parametri": ["Table trace"
	],
	"Return": ["A report"
			   ]
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
    "Note": [ "Checks will be run by functions" ]
}*/

proc sql;
create table Max_Data as
select  phase,
		tablename,
		max(timestamp) format=datetime20. as max_data
from DATITRC.tabletrace
where upcase(phase) in ('EXTRACTION','MAPPING')
group by phase,
		tablename
order by phase,
		tablename
;
quit;

proc sql;
create table tabletrace_max_dt as
select a.phase,
	   a.tablename, 
	   a.recno,
	   a.varsno,
	   a.timestamp
from DATITRC.tabletrace as a 
inner join Max_Data as b
	on a.phase = b.phase and 
	   a.tablename = b.tablename and 
	   a.timestamp = b.max_data;
quit;

data tabletrace_extr 
	 tabletrace_mapp;
set tabletrace_max_dt;
	if upcase(phase) = 'EXTRACTION' then output tabletrace_extr;
	else if upcase(phase) = 'MAPPING' then output tabletrace_mapp;
run;

proc sort data=tabletrace_extr out=tabletrace_extraction(drop=phase rename =(recno=recno_extr varsno=varsno_extr)); 
by tablename;
run;

proc sort data=tabletrace_mapp out=tabletrace_mapping(drop=phase rename =(recno=recno_mapp varsno=varsno_mapp)); 
by tablename;
run;

proc sql;
create table confronto as
select a.tablename as tabella,
	   /*a.timestamp as data_extraction, */
	   a.recno_extr as record_extraction,
	   b.recno_mapp as record_mapping,
	   case when a.recno_extr ne b.recno_mapp then 'Numero Record non coincidenti' else 'OK' end as Check_Record,
	   a.varsno_extr as variabili_extraction,
	   /*b.timestamp as data_mapping,*/
	   b.varsno_mapp as variabili_mapping,
	   case when a.varsno_extr ne b.varsno_mapp then 'Numero Variabili non coincidenti' else 'OK' end as Check_Variabili	   
from tabletrace_extraction as a
inner join tabletrace_mapping as b
	  on a.tablename=b.tablename;
quit;

ods pdf file="&publishfolder./confronto_Extraction_Mapping.pdf" style=Sapphire;

Option nodate nonumber orientation=landscape papersize=A4 topMargin=.1cm bottommargin=.1cm leftmargin=.1cm rightmargin=.1cm;

title "Differenze nei dati delle fasi Extraction e Mapping";
proc print data=confronto  noobs;
run;
 
ods pdf close;


