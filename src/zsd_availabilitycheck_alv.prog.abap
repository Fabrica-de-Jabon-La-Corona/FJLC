*&---------------------------------------------------------------------*
*& Report ZSD_AVAILABILITYCHECK_ALV
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zsd_availabilitycheck_alv.

INCLUDE zsd_availabilitycheck_alv_top.
INCLUDE zsd_availabilitycheck_sel.
INCLUDE zsd_availabilitycheck_f01.

START-OF-SELECTION.

* Obtenemos los lotes de inspeccion
  PERFORM get_data.

* Validamos si existen datos
  IF gt_dispo IS NOT INITIAL.
* Desplegamos ALV
    PERFORM display_alv.
  ELSE.
    MESSAGE 'No existen registros con los parámetros indicados.' TYPE 'I' DISPLAY LIKE 'W'.
  ENDIF.
