*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZPARAMGLOB......................................*
DATA:  BEGIN OF STATUS_ZPARAMGLOB                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZPARAMGLOB                    .
CONTROLS: TCTRL_ZPARAMGLOB
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZPARAMGLOB                    .
TABLES: ZPARAMGLOB                     .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
