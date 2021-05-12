*============================================================================================
* Client Name: AMCO SpA
* Project    : Framework di Data Verification
*--------------------------------------------------------------------------------------------
* Program name: hx_import_cmn_metadata
* Author      : Uriele De Piano Hexe SpA 02 October 2020
* Description : Import Common Metadata
*--------------------------------------------------------------------------------------------
* NOTE: Use two global macro variable
*============================================================================================
;

%Macro hx_import_cmn_metadata(wkbFolder=_NULL_,wkbName=_NULL_,dsMeta=_NULL_,wbkSheet=_NULL_) / store secure;
	%local dsid
	   ;
	Data _null_;
		Attrib folder    		Length=$256
				   wkbFile   		Length=$256
					 slash		 		Length=$1
					 attrFile	 		Length=$256
					 tmtStampWkb	Length=8		format=datetime.
					 tmtStampData	Length=8		format=datetime.
					 toBeCreated  Length=$1
				;
		%*-- Retrieve timestampa Excel;
		slash   = ifc(symget("sysscp")=:"WIN",'\','/');
		folder = ifc(Upcase(symget("wkbFolder"))="_NULL_"
		  					 ,Symget("metaCommonFolder")||strip(slash)||"excel"
						     ,"&wkbFolder."
								 );
	    *--folder  = "&metaCommonFolder.&slash.excel";
		wkbFile = symget("wkbName");
		Link getTmpStamp;
		_tmtStampWkbFile = tmtStampWkb;

		%*-- Retrieve timestamp Metadata;
		dsMeta  = Symget("dsMeta");
		folder  = pathName(Scan(dsMeta,1,'.'));
		wkbFile = catx('.',Scan(dsMeta,2,'.'),"sas7bdat");
		Link getTmpStamp;
		tmtStampData = tmtStampWkb;
		toBeCreated = 'Y';
		toBeCreated = ifc(_tmtStampWkbFile>tmtStampData,'Y','N');

		Put _tmtStampWkbFile=datetime. tmtStampData=datetime.;

        Call SymputX("toBeCreated",toBeCreated,'L');

		%*-- Write Process Trace;
		%hx_declare_ht_pr;

		idTransaction = symget("idTrasaction");
		timeStamp     = datetime();
		dataProvider  = symget("dataProvider");
		sourceCode    = symget("sysmacroname");
		stepCode      = catx(' ',"Creazione metadato:",scan(dsMeta,2,'.'),"su folder",folder);
		rc            = ht.add();
		rc            = ht.output(dataset:"work._processTrace");
		Return;

		GETTMPSTAMP:
			Call Missing(tmtStampWkb);
			put folder=;
			cmdWin = cats('dir "',strip(folder)||strip(slash)||strip(wkbFile),'"');
			rc  = filename("dlist",cmdWin,"pipe");
			fid = fopen("dlist",'s');
			Do While (fread(fid)=0);
				rc = fget(fid,attrFile,256);
				if prxmatch(cats('/',wkbFile,"/i"),attrFile) Then do;
					_tmtStampWkb = input(scan(compbl(attrFile),1,' '),anydtdte21.);
					_htm  		 	 = scan(compbl(attrFile),2,' ');
					tmtStampWkb  = dhms(_tmtStampWkb,Input(scan(_htm,1,':'),2.),Input(Scan(_htm,2,':'),2.),0);
				end;
			End;
			fid = fclose(fid);
			Put wkbFile= tmtStampWkb=datetime.;
		RETURN;
	Run;
	%Put &=toBeCreated;
    %if &toBeCreated.=Y %then %do;
		%If %Upcase(&wkbFolder.)=_NULL_ %Then %Do;
			%Let wkbFolder = &metaCommonFolder.&slash.excel;
		%End;
		%If %sysfunc(exist(&dsMeta.)) %then %do;
			Proc Delete data=&&dsMeta.; Run ;
		%End;
		%hx_import_sheet (wkbFolder = &wkbFolder.
								  		,wkbName  = &wkbName.
 											,wkbSheet = &wbkSheet.
									 		,dsImport = &dsMeta.);
		%if &syserr.<=4 %then %do;
			Proc Sql;
				Update work._processTrace Set rcCode = &syserr.
				                          ,msgCode="Metadata created"
						where idTransaction = "&idTrasaction."
						;
				Insert Into &processTrace.
					Select *
					From work._processTrace
					;
			Quit;
			%hx_update_tabletrace(%Qscan(&dsMeta.,1,%NrQuote(.))
							,cmn-metadata
							,whrcl=%NrQuote(lowcase%(memname%)="%lowcase(%Qscan(&dsMeta.,2,%NrQuote(.)))")
							);
		%end;
	%End;
%Mend;
%*hx_import_cmn_metadata(wkbName = npl_cmn_data_model.xlsx
												,dsMeta = metadata.npl_cmn_data_model);
