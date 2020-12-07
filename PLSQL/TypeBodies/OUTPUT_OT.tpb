CREATE OR REPLACE TYPE BODY output_ot AS

  ---------------------------------------------------------------------------------------------------------

  MEMBER PROCEDURE add_line(self   IN OUT NOCOPY output_ot,
                            p_line IN VARCHAR2)
  IS
  BEGIN
    self.lines.extend;
    self.lines(self.lines.last) := p_line;
  END add_line;

  ---------------------------------------------------------------------------------------------------------

  MEMBER PROCEDURE print(SELF IN OUT NOCOPY output_ot)
  IS
    l_idx PLS_INTEGER;
  BEGIN
    l_idx := self.lines.first;
    WHILE l_idx IS NOT NULL
    LOOP
      dbms_output.put_line(a => self.lines(l_idx));
      l_idx := self.lines.next(l_idx);
    END LOOP;
  END print;

  ---------------------------------------------------------------------------------------------------------

END;
/
