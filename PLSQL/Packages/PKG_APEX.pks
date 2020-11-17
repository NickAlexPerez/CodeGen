CREATE OR REPLACE PACKAGE pkg_apex IS

  ---------------------------------------------------------------------------------------------------------

  PROCEDURE gen_trigger(p_owner            IN dba_tab_cols.owner%TYPE,
                        p_view             IN dba_tab_cols.table_name%TYPE,
                        p_pkg_name         IN VARCHAR2,
                        p_procedure_suffix IN pkg_util.procedure_suffix_st);

  ---------------------------------------------------------------------------------------------------------

END pkg_apex;
/
