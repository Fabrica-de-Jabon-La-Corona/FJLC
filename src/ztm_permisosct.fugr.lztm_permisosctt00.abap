*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTM_PERMISOSCT..................................*
DATA:  BEGIN OF STATUS_ZTM_PERMISOSCT                .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTM_PERMISOSCT                .
CONTROLS: TCTRL_ZTM_PERMISOSCT
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTM_PERMISOSCT                .
TABLES: ZTM_PERMISOSCT                 .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
