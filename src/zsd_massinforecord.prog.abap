*&---------------------------------------------------------------------*
*& Report ZSD_MASSINFORECORD
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZSD_MASSINFORECORD.

INCLUDE zsd_massinforecord_top.
INCLUDE zsd_massinforecord_sel.
INCLUDE zsd_massinforecord_f01.

START-OF-SELECTION.

* Obtenemos los lotes de inspeccion
  PERFORM get_data.

* Validamos si existen datos
  "IF gt_inforecord IS NOT INITIAL.
* Desplegamos ALV
    PERFORM display_alv.
  "ELSE.
   " MESSAGE 'No existen inforecords con los parámetros indicados.' TYPE 'I' DISPLAY LIKE 'W'.
  "ENDIF.
