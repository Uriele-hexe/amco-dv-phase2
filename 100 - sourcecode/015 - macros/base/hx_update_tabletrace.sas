%macro hx_update_tabletrace(libnm,phase,whrcl=1) / store secure;
	%local tmpStamp;
	%Let tmpStamp = %sysfunc(datetime());
	proc sql;
		insert into datitrc.tabletrace
			select 
				"&idTrasaction." as idTransaction
				,&tmpStamp. as timeStamp
				%If %Symexist(cod_ist) %Then %Do;
				,&cod_ist. as cod_ist 
				%End;
				%Else %Do;
				,. as cod_ist 
				%End;
				,"&dataProvider." as dataProvider		
				,"&phase." as phase
				,memname as tableName
				,libname as libname
				,crdate as dtaCreate
				,nobs as recNo
				,nvar as varsNo
			from sashelp.vtable
			where libname = upcase("&libnm.") and &whrcl.
		;
	quit;
%mend;

/*test
%hx_update_tabletrace(libnm=datiodd,phase=test);
*/

/*troncatura(per testing)*/
/*
data datitrc.tabletrace;
	set datitrc.tabletrace(obs=0);
run;
*/
