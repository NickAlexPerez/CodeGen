CREATE OR REPLACE PACKAGE pkg_util IS

  ---------------------------------------------------------------------------------------------------------

  SUBTYPE dba_tab_cols_idx IS PLS_INTEGER;

  TYPE dba_tab_cols_aat IS TABLE OF dba_tab_cols%ROWTYPE INDEX BY dba_tab_cols_idx;

  SUBTYPE procedure_suffix_st IS VARCHAR2(128);
  SUBTYPE line_st IS VARCHAR2(4000);

  TYPE lines_ct IS TABLE OF line_st;

  ---------------------------------------------------------------------------------------------------------

  FUNCTION get_all_columns_aat(p_owner IN dba_tab_cols.owner%TYPE,
                               p_table IN dba_tab_cols.table_name%TYPE) RETURN pkg_util.dba_tab_cols_aat;

  --------------------------------------------------------------------------------------------------------

  FUNCTION is_pk_column(p_owner  IN dba_tab_cols.owner%TYPE,
                        p_table  IN dba_tab_cols.table_name%TYPE,
                        p_column IN dba_tab_cols.column_name%TYPE) RETURN BOOLEAN;

---------------------------------------------------------------------------------------------------------

END pkg_util;
/
