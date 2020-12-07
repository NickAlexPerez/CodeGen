CREATE OR REPLACE PACKAGE pkg_util IS

  ---------------------------------------------------------------------------------------------------------

  FUNCTION get_all_columns_aat(p_owner IN dba_tab_cols.owner%TYPE,
                               p_table IN dba_tab_cols.table_name%TYPE) RETURN pkg_rules.dba_tab_cols_aat;

  --------------------------------------------------------------------------------------------------------

  FUNCTION is_pk_column(p_owner  IN dba_tab_cols.owner%TYPE,
                        p_table  IN dba_tab_cols.table_name%TYPE,
                        p_column IN dba_tab_cols.column_name%TYPE) RETURN BOOLEAN;

---------------------------------------------------------------------------------------------------------

END pkg_util;
/
