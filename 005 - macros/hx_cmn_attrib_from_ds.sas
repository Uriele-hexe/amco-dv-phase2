/*{
    "Program": "hx_cmn_attrib_from_ds"
	"Descrizione": "Create attrib statment",
	"Parametri": [
		"dsName":"Dataset name"
	],
	"Return": "statment attrib",
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
}*/

%Macro hx_cmn_attrib_from_ds (dsname=_NULL_) / Store secure Des = "Create attrib statment";
	%local _dttimeStamp _dsid
	   ;
    %Let _dttimeStamp  = %sysfunc(datetime());
	%Put +----[Macro: &sysmacroname.] ------------------------------+;
	%Put | Create attrib statment dinamically                       |;
	%Put | Data model: &dsName.                                     |;
	%Put | .........................................................|;
	%Put | Started at : %Sysfunc(PutN(&_dttimeStamp.,datetime.))    |;
	%Put +----[Macro: &sysmacroname.] ------------------------------+;

    %If %sysfunc(exist(&dsname.))=0 %Then %Do; 
       %Put &dsName. not exists! Attrib statment stopped !!;
       %Goto uscita;
    %End;
    %Let _dsid = %sysfunc(Open(&dsname.));
    %Do _nvar=1 %To %sysfunc(AttrN(&_dsid.,NVARS));
      %Let _varname = %sysfunc(varname(&_dsid.,&_nvar.));
      %Let _vartype = %sysfunc(vartype(&_dsid.,&_nvar.));
      %Let _varlen  = %sysfunc(varlen(&_dsid.,&_nvar.));
      %Let _varlab  = %sysfunc(varlabel(&_dsid.,&_nvar.));
      %Let _varfmt  = %sysfunc(varfmt(&_dsid.,&_nvar.));
      
      %If &_vartype.=C %Then %Do;
        %Let _varType = $%UnQuote(&_varlen.);
      %End;
      %Else %Do;
        %Let _varType = 8;
      %End;
      %If "%UnQuote(&_varlab.)" ne "" And %length(&_varlab.) %Then %Do;
        %Let _varLab = %NrQuote(Label="&_varlab.");
      %End;
      %If "%UnQuote(&_varfmt.))" ne "" And %length(&_varfmt.)>0 %Then %Do;
        %Let _varfmt = %NrQuote(Format=&_varfmt.);
      %End;
      Attrib &_varname. Length=&_vartype. &_varlab. &_varfmt.;
    %End;
    %Let _dsid = %Sysfunc(Close(&_dsid.));

    %Uscita:
      %Let _dttimeStamp  = %sysfunc(datetime());
	  %Put +----[Macro: &sysmacroname.] ------------------------------+;
	  %Put | Create attrib statment dinamically                       |;
	  %Put | .........................................................|;
	  %Put | Ended at : %Sysfunc(PutN(&_dttimeStamp.,datetime.))      |;
	  %Put +----[Macro: &sysmacroname.] ------------------------------+;
%Mend;
