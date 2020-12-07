CREATE OR REPLACE PACKAGE BODY pkg_util IS

  ---------------------------------------------------------------------------------------------------------

  FUNCTION get_all_columns_aat(p_owner IN dba_tab_cols.owner%TYPE,
                               p_table IN dba_tab_cols.table_name%TYPE)
    RETURN pkg_rules.dba_tab_cols_aat
  IS
  /********************************************************************************************************
  *   PURPOSE: Returns a collection of rowtypes of the columns that are on a table
  *
  *   REVISIONS:
  *   Date        Author      Description
  *   ----------  ----------  -----------------------------------------------------------------------------
  *   99/99/9999  NICKP       Created.
  *********************************************************************************************************/
    l_return pkg_rules.dba_tab_cols_aat;
  BEGIN
    FOR i IN
      (SELECT *
        FROM dba_tab_cols
       WHERE owner = UPPER(p_owner)
         AND table_name = UPPER(p_table)
         AND hidden_column = 'NO'
         AND virtual_column = 'NO'
       ORDER BY column_id)
    LOOP
      l_return(i.column_id) := i;
    END LOOP;
    RETURN l_return;
  END get_all_columns_aat;

  --------------------------------------------------------------------------------------------------------

  FUNCTION is_pk_column(p_owner  IN dba_tab_cols.owner%TYPE,
                        p_table  IN dba_tab_cols.table_name%TYPE,
                        p_column IN dba_tab_cols.column_name%TYPE) RETURN BOOLEAN
  IS
    l_dummy PLS_INTEGER;
  BEGIN
     SELECT 1
       INTO l_dummy
       FROM dba_cons_columns col
       JOIN dba_constraints  con
         ON con.owner = col.owner
        AND con.table_name = col.table_name
        AND con.constraint_name = col.constraint_name
        AND con.constraint_type = 'P'
       JOIN dba_tab_cols all_cols
         ON all_cols.owner = col.owner
        AND all_cols.table_name = col.table_name
        AND all_cols.column_name = col.column_name
      WHERE UPPER(col.owner) = UPPER(p_owner)
        AND col.table_name = UPPER(p_table)
        AND col.COLUMN_NAME = UPPER(p_column);
    RETURN TRUE;
  EXCEPTION 
    WHEN no_data_found THEN 
      RETURN FALSE;
  END is_pk_column;

  ---------------------------------------------------------------------------------------------------------

  END pkg_util;
/
