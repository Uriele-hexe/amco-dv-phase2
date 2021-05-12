Option mstored sasmstore=hx_macro;
Libname hx_macro "d:\DataQuality\05_SourceCode\01_Macro\project";

Filename macros 'd:\DataQuality\05_SourceCode\01_Macro\base\nv';
%inc macros("attrn.sas");
%inc macros("check_rc.sas");
%inc macros("config.sas");
%inc macros("create_dset_struct_from_mtd.sas");
%inc macros("data_cleanup.sas");
%inc macros("delete_before_append.sas");
%inc macros("get_value.sas");
%inc macros("has_variable.sas");
%inc macros("hx_copy_file.sas");
%inc macros("hx_create_data_structure.sas");
%inc macros("hx_get_fx_package.sas");
%inc macros("hx_get_list_columns.sas");
%inc macros("hx_run_macro_function.sas");
%inc macros("import_xlsx_sheets.sas");
%inc macros("is_empty.sas");
%inc macros("log.sas");
%inc macros("replace_spec_chars.sas");
%inc macros("send_mail.sas");
%inc macros("set_libs.sas");
%inc macros("set_options.sas");
%inc macros("set_params.sas");
%inc macros("translate.sas");
%inc macros("translate.sas");
%inc macros("hx_import_cmn_metadata.sas");
%inc macros("hx_import_parameters.sas");
%inc macros("hx_declare_ht_pr.sas");