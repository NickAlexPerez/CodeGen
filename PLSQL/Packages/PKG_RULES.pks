CREATE OR REPLACE PACKAGE pkg_rules IS

  ---------------------------------------------------------------------------------------------------------

  SUBTYPE dba_tab_cols_idx IS PLS_INTEGER;

  TYPE dba_tab_cols_aat IS TABLE OF dba_tab_cols%ROWTYPE INDEX BY dba_tab_cols_idx;

  SUBTYPE procedure_suffix_st IS VARCHAR2(128);
  SUBTYPE line_st IS VARCHAR2(4000);

  TYPE lines_ct IS TABLE OF line_st;

END pkg_rules;
/
