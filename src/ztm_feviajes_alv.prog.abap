*&---------------------------------------------------------------------*
*& Report ZTM_FEVIAJES_ALV
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztm_feviajes_alv.

INCLUDE ztm_feviajes_alv_top.
INCLUDE ztm_feviajes_alv_sel.
INCLUDE ztm_feviajes_alv_f01.

START-OF-SELECTION.

* Obtenemos los lotes de inspeccion
  PERFORM get_data.

* Validamos si existen datos
  IF gt_viajes IS NOT INITIAL.
* Desplegamos ALV
    PERFORM display_alv.
  ELSE.
    MESSAGE 'No existen viajes con los parámetros indicados.' TYPE 'I' DISPLAY LIKE 'W'.
  ENDIF.
