CREATE OR REPLACE TYPE output_ot FORCE AS OBJECT (

  lines string_tab,

  ---------------------------------------------------------------------------------------------------------

  MEMBER PROCEDURE add_line(self   IN OUT NOCOPY output_ot,
                            p_line IN VARCHAR2),

  ---------------------------------------------------------------------------------------------------------

  MEMBER PROCEDURE print(SELF IN OUT NOCOPY output_ot)

  ---------------------------------------------------------------------------------------------------------

)
/
