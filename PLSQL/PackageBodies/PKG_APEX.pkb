CREATE OR REPLACE PACKAGE BODY pkg_apex IS

  ---------------------------------------------------------------------------------------------------------

  PROCEDURE gen_trigger(p_owner            IN dba_tab_cols.owner%TYPE,
                        p_table            IN dba_tab_cols.table_name%TYPE,
                        p_view             IN dba_tab_cols.table_name%TYPE,
                        p_pkg_name         IN VARCHAR2,
                        p_procedure_suffix IN pkg_rules.procedure_suffix_st)
  IS
    l_owner            dba_tab_cols.owner%TYPE := LOWER(p_owner);
    l_view             dba_tab_cols.table_name%TYPE := LOWER(p_view);
    l_procedure_suffix pkg_rules.procedure_suffix_st := LOWER(p_procedure_suffix);
    l_columns          pkg_rules.dba_tab_cols_aat;
    l_col_idx          pkg_rules.dba_tab_cols_idx;
    l_output           output_ot := output_ot(lines => string_tab());

    PROCEDURE add_columns(p_pk_prefix      IN VARCHAR2,
                          p_include_non_pk IN BOOLEAN) IS
      l_prefix    CHAR(3);
      l_is_pk_col BOOLEAN;
    BEGIN
      l_col_idx := l_columns.first;

      IF l_col_idx IS NOT NULL THEN
        IF pkg_util.is_pk_column(p_owner  => p_owner,
                                 p_table  => p_table,
                                 p_column => l_columns(l_col_idx).column_name) THEN
          l_prefix := p_pk_prefix;
          l_is_pk_col := TRUE;
        ELSE
          l_prefix := 'NEW';
          l_is_pk_col := FALSE;
        END IF;
        IF (NOT l_is_pk_col AND p_include_non_pk) OR l_is_pk_col THEN
          l_output.add_line(p_line => '        (p_'  || lower(l_columns(l_col_idx).column_name) || ' => :' ||
                                          UPPER(l_prefix) || '.' || LOWER(l_columns(l_col_idx).column_name));
        END IF;
        l_col_idx := l_columns.next(l_col_idx);
      END IF;

      WHILE l_col_idx IS NOT NULL
      LOOP
        IF pkg_util.is_pk_column(p_owner  => p_owner,
                                 p_table  => p_table,
                                 p_column => l_columns(l_col_idx).column_name) THEN
          l_prefix := p_pk_prefix;
          l_is_pk_col := TRUE;
        ELSE
          l_prefix := 'NEW';
          l_is_pk_col := FALSE;
        END IF;
        IF (NOT l_is_pk_col AND p_include_non_pk) OR l_is_pk_col THEN
          l_output.add_line(p_line => '        ,p_'  || lower(l_columns(l_col_idx).column_name) || ' => :' ||
                                          UPPER(l_prefix) || '.' || LOWER(l_columns(l_col_idx).column_name));
        END IF;
        l_col_idx := l_columns.next(l_col_idx);
      END LOOP;
      l_output.add_line(p_line => '            );');
    END;
  BEGIN
    l_columns := pkg_util.get_all_columns_aat(p_owner => p_owner,
                                              p_table => p_view);

    l_output.add_line(p_line => 'CREATE OR REPLACE TRIGGER ' || l_owner || '.' || l_view || '_ioiud');
    l_output.add_line(p_line => '  INSTEAD OF INSERT OR UPDATE OR DELETE ON ' || l_owner || '.' || l_view);
    l_output.add_line(p_line => '  FOR EACH ROW');
    l_output.add_line(p_line => 'DECLARE');
    l_output.add_line(p_line => 'BEGIN');
    l_output.add_line(p_line => '  CASE');
    l_output.add_line(p_line => '    WHEN INSERTING THEN');
    l_output.add_line(p_line => '      ' || l_owner || '.' || p_pkg_name || '.insert_' || l_procedure_suffix);

    add_columns(p_pk_prefix  => 'NEW',
                p_include_non_pk => TRUE);

    l_output.add_line(p_line => '    WHEN UPDATING THEN');
    l_output.add_line(p_line => '      ' || l_owner || '.' || p_pkg_name || '.update_' || l_procedure_suffix);

    add_columns(p_pk_prefix  => 'OLD',
                p_include_non_pk => TRUE);

    l_output.add_line(p_line => '    WHEN DELETING THEN');
    l_output.add_line(p_line => '      ' || l_owner || '.' || p_pkg_name || '.delete_' || l_procedure_suffix);
    add_columns(p_pk_prefix  => 'OLD',
                p_include_non_pk => FALSE);
    
    l_output.add_line(p_line => '  ELSE');
    l_output.add_line(p_line => '      raise_application_error(pkg_exp.c_custom_error, ''Unimplemented DML operation.'');');
    l_output.add_line(p_line => '  END CASE;');
    l_output.add_line(p_line => 'END;');
    
    l_output.print;
  END gen_trigger;

  ---------------------------------------------------------------------------------------------------------

  PROCEDURE gen_view(p_owner IN dba_tab_cols.owner%TYPE,
                     p_table IN dba_tab_cols.table_name%TYPE,
                     p_view IN dba_tab_cols.table_name%TYPE)
  IS
    l_owner   dba_tab_cols.owner%TYPE := LOWER(p_owner);
    l_table   dba_tab_cols.table_name%TYPE := LOWER(p_table);
    l_view    dba_tab_cols.table_name%TYPE := LOWER(p_view);
    l_columns pkg_rules.dba_tab_cols_aat;
    l_col_idx pkg_rules.dba_tab_cols_idx;
    l_output  output_ot := output_ot(lines => string_tab());
  BEGIN
    l_columns := pkg_util.get_all_columns_aat(p_owner => p_owner,
                                              p_table => p_table);

    IF l_columns.count > 0 THEN
      l_output.add_line(p_line => 'CREATE OR REPLACE VIEW ' || l_view || ' AS');
      l_col_idx := l_columns.first;
      l_output.add_line(p_line => 'SELECT ' || l_columns(l_col_idx).column_name);

      l_col_idx := l_columns.next(l_col_idx);
      WHILE l_col_idx IS NOT NULL
      LOOP
        l_output.add_line(p_line => ',' || l_columns(l_col_idx).column_name);
        l_col_idx := l_columns.next(l_col_idx);
      END LOOP;

      l_output.add_line('  FROM ' || l_owner || '.' || l_table || ';');

      l_output.print;
    END IF;
  END gen_view;

  ---------------------------------------------------------------------------------------------------------
  
  PROCEDURE gen_all(p_owner            IN dba_tab_cols.owner%TYPE,
                    p_table            IN dba_tab_cols.table_name%TYPE,
                    p_view             IN dba_tab_cols.table_name%TYPE,
                    p_pkg_name         IN VARCHAR2,
                    p_procedure_suffix IN pkg_rules.procedure_suffix_st)
  IS
  BEGIN
    gen_view(p_owner => p_owner,
             p_table => p_table,
             p_view  => p_view);

    gen_trigger(p_owner            => p_owner,
                p_table => p_table,
                p_view             => p_view,
                p_pkg_name         => p_pkg_name,
                p_procedure_suffix => p_procedure_suffix);
  END gen_all;
   
  ---------------------------------------------------------------------------------------------------------

END pkg_apex;
/
