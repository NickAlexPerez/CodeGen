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
    l_output.add_line(p_line => '/****************  GENERATING TRIGGER ****************/');
    
    l_columns := pkg_util.get_all_columns_aat(p_owner => p_owner,
                                              p_table => p_view);

    l_output.add_line(p_line => 'CREATE OR REPLACE TRIGGER ' || l_owner || '.' || l_view || '_ioiud');
    l_output.add_line(p_line => '  INSTEAD OF INSERT OR UPDATE OR DELETE ON ' || l_owner || '.' || l_view);
    l_output.add_line(p_line => '  FOR EACH ROW');
    l_output.add_line(p_line => 'DECLARE');
    l_output.add_line(p_line => 'BEGIN');
    l_output.add_line(p_line => '  CASE');
    l_output.add_line(p_line => '    WHEN INSERTING THEN');
    l_output.add_line(p_line => '      ' || l_owner || '.' || p_pkg_name || '.ins_' || l_procedure_suffix);

    add_columns(p_pk_prefix  => 'NEW',
                p_include_non_pk => TRUE);

    l_output.add_line(p_line => '    WHEN UPDATING THEN');
    l_output.add_line(p_line => '      ' || l_owner || '.' || p_pkg_name || '.upd_' || l_procedure_suffix);

    add_columns(p_pk_prefix  => 'OLD',
                p_include_non_pk => TRUE);

    l_output.add_line(p_line => '    WHEN DELETING THEN');
    l_output.add_line(p_line => '      ' || l_owner || '.' || p_pkg_name || '.del_' || l_procedure_suffix);
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
    l_output.add_line(p_line => '/****************  GENERATING VIEW ****************/');
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

  PROCEDURE add_parameter_columns(p_owner            IN dba_tab_cols.owner%TYPE,
                                  p_table            IN dba_tab_cols.table_name%TYPE,
                                  p_include_non_pk IN BOOLEAN,
                                  p_columns        IN OUT NOCOPY pkg_rules.dba_tab_cols_aat,
                                  p_output         IN OUT NOCOPY output_ot)
  IS
  /********************************************************************************************************
  *   PURPOSE:
  *
  *   REVISIONS:
  *   Date        Author      Description
  *   ----------  ----------  -----------------------------------------------------------------------------
  *   99/99/9999  NICKP       Created.
  *********************************************************************************************************/ 
    l_is_pk_col BOOLEAN;
    l_table   dba_tab_cols.table_name%TYPE := LOWER(p_table);
    l_col_idx   pkg_rules.dba_tab_cols_idx;
  BEGIN
    l_col_idx := p_columns.first;

    WHILE l_col_idx IS NOT NULL
    LOOP
      IF pkg_util.is_pk_column(p_owner  => p_owner,
                               p_table  => p_table,
                               p_column => p_columns(l_col_idx).column_name) THEN
        l_is_pk_col := TRUE;
      ELSE
        l_is_pk_col := FALSE;
      END IF;
      IF (NOT l_is_pk_col AND p_include_non_pk) OR l_is_pk_col THEN
        p_output.add_line(p_line => CASE l_col_idx WHEN p_columns.first THEN NULL ELSE ',' END || 'p_'  || LTRIM(lower(p_columns(l_col_idx).column_name),'db') || ' IN ' ||
                                        LOWER(p_owner) || '.' || LOWER(l_table) || '.' || LOWER(p_columns(l_col_idx).column_name || '%TYPE'));
      END IF;
      l_col_idx := p_columns.next(l_col_idx);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_error.log(p_desc => 'add_parameter_columns');
      RAISE;
  END add_parameter_columns;

  ---------------------------------------------------------------------------------------------------------

  PROCEDURE gen_api(p_owner            IN dba_tab_cols.owner%TYPE,
                    p_table            IN dba_tab_cols.table_name%TYPE,
                    p_procedure_suffix IN pkg_rules.procedure_suffix_st)
  IS
  /********************************************************************************************************
  *   PURPOSE:
  *
  *   REVISIONS:
  *   Date        Author      Description
  *   ----------  ----------  -----------------------------------------------------------------------------
  *   99/99/9999  NICKP       Created.
  *********************************************************************************************************/
    l_owner   dba_tab_cols.owner%TYPE := LOWER(p_owner);
    l_table   dba_tab_cols.table_name%TYPE := LOWER(p_table);
    l_columns pkg_rules.dba_tab_cols_aat;
    l_output  output_ot := output_ot(lines => string_tab());
    l_procedure_suffix pkg_rules.procedure_suffix_st := LOWER(p_procedure_suffix);
    l_col_idx   pkg_rules.dba_tab_cols_idx;
  BEGIN
    l_output.add_line(p_line => '/****************  GENERATING API PROCEDURES ****************/');
    l_columns := pkg_util.get_all_columns_aat(p_owner => p_owner,
                                              p_table => p_table);

    l_output.add_line(p_line => 'PROCEDURE ' || 'ins_' || l_procedure_suffix || '(');
    add_parameter_columns(p_owner          => p_owner,
                          p_table          => p_table,
                          p_include_non_pk => TRUE,
                          p_columns        => l_columns,
                          p_output         => l_output);
    l_output.add_line(p_line => ') IS BEGIN');
    l_output.add_line(p_line => l_owner || '.pkg_' || l_table || '.ins(');
    l_col_idx := l_columns.first;
    WHILE l_col_idx IS NOT NULL
    LOOP
      l_output.add_line(CASE l_col_idx WHEN l_columns.first THEN NULL ELSE ',' END ||
                        'p_' || LTRIM(LOWER(l_columns(l_col_idx).column_name),'db') || ' => ' ||
                        'p_' || LTRIM(LOWER(l_columns(l_col_idx).column_name),'db'));
      l_col_idx := l_columns.next(l_col_idx);
    END LOOP;
    l_output.add_line(p_line => ');');
    l_output.add_line(p_line => 'END ins_' || l_procedure_suffix || ';');

    l_output.add_line(p_line => 'PROCEDURE ' || 'upd_' || l_procedure_suffix || '(');
    add_parameter_columns(p_owner          => p_owner,
                          p_table          => p_table,
                          p_include_non_pk => TRUE,
                          p_columns        => l_columns,
                          p_output         => l_output);
    l_output.add_line(p_line => ') IS BEGIN');
    l_output.add_line(p_line => l_owner || '.pkg_' || l_table || '.upd(');
    l_col_idx := l_columns.first;
    WHILE l_col_idx IS NOT NULL
    LOOP
      l_output.add_line(CASE l_col_idx WHEN l_columns.first THEN NULL ELSE ',' END || 
                        'p_' || LTRIM(LOWER(l_columns(l_col_idx).column_name),'db') || ' => ' ||
                        'p_' || LTRIM(LOWER(l_columns(l_col_idx).column_name),'db'));
      l_col_idx := l_columns.next(l_col_idx);
    END LOOP;
    l_output.add_line(p_line => ');');
    l_output.add_line(p_line => 'END upd_' || l_procedure_suffix || ';');

    l_output.add_line(p_line => 'PROCEDURE ' || 'del_' || l_procedure_suffix || '(');
    add_parameter_columns(p_owner          => p_owner,
                          p_table          => p_table,
                          p_include_non_pk => FALSE,
                          p_columns        => l_columns,
                          p_output         => l_output);
    l_output.add_line(p_line => ') IS BEGIN');
    l_output.add_line(p_line => l_owner || '.pkg_' || l_table || '.del(');
    l_col_idx := l_columns.first;
    DECLARE
      l_include_comma BOOLEAN := FALSE;
    BEGIN
      WHILE l_col_idx IS NOT NULL
      LOOP
        IF pkg_util.is_pk_column(p_owner  => p_owner,
                                 p_table  => p_table,
                                 p_column => l_columns(l_col_idx).column_name) THEN
          
          l_output.add_line(CASE l_include_comma WHEN TRUE THEN ',' END ||  
                            'p_' || LTRIM(LOWER(l_columns(l_col_idx).column_name),'db') || ' => ' ||
                            'p_' || LTRIM(LOWER(l_columns(l_col_idx).column_name),'db'));
          l_include_comma := TRUE;
        END IF;
        l_col_idx := l_columns.next(l_col_idx);
      END LOOP;
    END;
    l_output.add_line(p_line => ');');
    l_output.add_line(p_line => 'END del_' || l_procedure_suffix || ';');
  
    l_output.print;
  EXCEPTION
    WHEN OTHERS THEN
      pkg_error.log(p_desc   => 'gen_api',
                    p_name1  => NULL,
                    p_value1 => NULL,
                    p_name2  => NULL,
                    p_value2 => NULL,
                    p_name3  => NULL,
                    p_value3 => NULL,
                    p_name4  => NULL,
                    p_value4 => NULL,
                    p_name5  => NULL,
                    p_value5 => NULL);
      RAISE;
  END gen_api;
   
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
                p_table            => p_table,
                p_view             => p_view,
                p_pkg_name         => p_pkg_name,
                p_procedure_suffix => p_procedure_suffix);

    gen_api(p_owner            => p_owner,
            p_table            => p_table,
            p_procedure_suffix => p_procedure_suffix);
  END gen_all;
   
  ---------------------------------------------------------------------------------------------------------

END pkg_apex;
/
