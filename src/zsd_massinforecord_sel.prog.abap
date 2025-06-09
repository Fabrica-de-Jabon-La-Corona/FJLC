*&---------------------------------------------------------------------*
*& Include          ZSD_MASSINFORECORD_SEL
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK bloque1.
* & ------------------------------------------------------------*
* & Inforecords filters
* & ------------------------------------------------------------*
  SELECTION-SCREEN BEGIN OF BLOCK bloque2 WITH FRAME TITLE TEXT-001.
    SELECT-OPTIONS: pa_vkorg FOR knmt-vkorg OBLIGATORY, "Sales Organization
                    pa_vtweg FOR knmt-vtweg,            "Distribution Channel
                    pa_kunnr FOR knmt-kunnr,            "Sold to Party
                    pa_matnr FOR knmt-matnr.            "SAP Material
  SELECTION-SCREEN END OF BLOCK bloque2.

* & ------------------------------------------------------------*
* & Parametrizacion de lista
* & ------------------------------------------------------------*
  SELECTION-SCREEN BEGIN OF BLOCK bloque3 WITH FRAME TITLE TEXT-002.
    "PARAMETERS: p_status AS CHECKBOX DEFAULT 'X'.
    PARAMETERS p_layout TYPE slis_vari.
  SELECTION-SCREEN END OF BLOCK bloque3.
SELECTION-SCREEN END OF BLOCK bloque1.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_layout.
  PERFORM select_layout.

FORM select_layout.

  DATA: ls_layout_key  TYPE salv_s_layout_key,
        ls_layout_info TYPE salv_s_layout_info.

  ls_layout_key-report = sy-repid.
  ls_layout_info = cl_salv_layout_service=>f4_layouts( ls_layout_key ).
  p_layout = ls_layout_info-layout.

ENDFORM.
