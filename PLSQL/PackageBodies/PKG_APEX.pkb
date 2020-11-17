CREATE OR REPLACE PACKAGE BODY pkg_apex IS

  ---------------------------------------------------------------------------------------------------------

  PROCEDURE print(p_lines IN pkg_util.lines_ct)
  IS
    l_idx PLS_INTEGER;
  BEGIN
    l_idx := p_lines.first;
    WHILE l_idx IS NOT NULL
    LOOP
      dbms_output.put_line(a => p_lines(l_idx));
      l_idx := p_lines.next(l_idx);
    END LOOP;
  END print;

  ---------------------------------------------------------------------------------------------------------

  PROCEDURE gen_trigger(p_owner            IN dba_tab_cols.owner%TYPE,
                        p_view             IN dba_tab_cols.table_name%TYPE,
                        p_pkg_name         IN VARCHAR2,
                        p_procedure_suffix IN pkg_util.procedure_suffix_st)
  IS
    l_owner            dba_tab_cols.owner%TYPE := LOWER(p_owner);
    l_view             dba_tab_cols.table_name%TYPE := LOWER(p_view);
    l_procedure_suffix pkg_util.procedure_suffix_st := LOWER(p_procedure_suffix);
    l_columns          pkg_util.dba_tab_cols_aat;
    l_col_idx          pkg_util.dba_tab_cols_idx;
    l_lines            pkg_util.lines_ct := pkg_util.lines_ct();

    PROCEDURE add_line(p_line IN pkg_util.line_st) IS
    BEGIN
      l_lines.extend;
      l_lines(l_lines.last) := p_line;
    END;
    
    PROCEDURE add_columns(p_prefix IN VARCHAR2) IS
    BEGIN
      l_col_idx := l_columns.first;

      IF l_col_idx IS NOT NULL THEN
        add_line(p_line => '        (p_'  || LTRIM(lower(l_columns(l_col_idx).column_name),'db') || ' => :' ||
                                        UPPER(p_prefix) || '.' || LOWER(l_columns(l_col_idx).column_name));
        l_col_idx := l_columns.next(l_col_idx);
      END IF;

      WHILE l_col_idx IS NOT NULL
      LOOP
        add_line(p_line => '        ,p_'  || LTRIM(lower(l_columns(l_col_idx).column_name),'db') || ' => :' ||
                                        UPPER(p_prefix) || '.' || LOWER(l_columns(l_col_idx).column_name));

        l_col_idx := l_columns.next(l_col_idx);
      END LOOP;
      add_line(p_line => '            );');
    END;
  BEGIN
    l_columns := pkg_util.get_all_columns_aat(p_owner => p_owner,
                                              p_table => p_view);

    add_line(p_line => 'CREATE OR REPLACE TRIGGER ' || l_owner || '.' || l_view || '_ioiud');
    add_line(p_line => '  INSTEAD OF INSERT OR UPDATE OR DELETE ON ' || l_owner || '.' || l_view);
    add_line(p_line => '  FOR EACH ROW');
    add_line(p_line => 'DECLARE');
    add_line(p_line => 'BEGIN');
    add_line(p_line => '  CASE');
    add_line(p_line => '    WHEN INSERTING THEN');
    add_line(p_line => '      ' || l_owner || '.' || p_pkg_name || '.insert_' || l_procedure_suffix);

    add_columns(p_prefix => 'NEW');

    add_line(p_line => '    WHEN UPDATING THEN');
    add_line(p_line => '      ' || l_owner || '.' || p_pkg_name || '.update_' || l_procedure_suffix);
    add_line(p_line => '        -- TODO: PK columns should use OLD for update role');

    add_columns(p_prefix => 'NEW');

    add_line(p_line => '    WHEN DELETING THEN');
    add_line(p_line => '      ' || l_owner || '.' || p_pkg_name || '.delete_' || l_procedure_suffix);
    add_line(p_line => '        -- TODO: remove any non pk columns');
    add_columns(p_prefix => 'OLD');
    
    add_line(p_line => '  ELSE');
    add_line(p_line => '      raise_application_error(pkg_exp.c_custom_error, ''Unimplemented DML operation.'');');
    add_line(p_line => '  END CASE;');
    add_line(p_line => 'END;');
    
    print(p_lines => l_lines);
  EXCEPTION
    WHEN OTHERS THEN
      pkg_error.log(p_desc   => 'gen_trigger',
                    p_name1  => 'p_owner',
                    p_value1 => p_owner,
                    p_name2  => 'p_view',
                    p_value2 => p_view,
                    p_name3  => 'p_pkg_name',
                    p_value3 => p_pkg_name);
      RAISE;
  END gen_trigger;

  ---------------------------------------------------------------------------------------------------------

END pkg_apex;
/
