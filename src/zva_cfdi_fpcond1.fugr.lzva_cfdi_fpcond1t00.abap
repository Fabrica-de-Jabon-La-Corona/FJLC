*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZSD_CFDI_FPCOND1................................*
DATA:  BEGIN OF STATUS_ZSD_CFDI_FPCOND1              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZSD_CFDI_FPCOND1              .
CONTROLS: TCTRL_ZSD_CFDI_FPCOND1
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZSD_CFDI_FPCOND1              .
TABLES: ZSD_CFDI_FPCOND1               .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
