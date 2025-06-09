*&---------------------------------------------------------------------*
*& Include          ZSD_AVAILABILITYCHECK_SEL
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK bloque1.
* & ------------------------------------------------------------*
* & Filtros de dsiponibilidad de materiales
* & ------------------------------------------------------------*
  SELECTION-SCREEN BEGIN OF BLOCK bloque2 WITH FRAME TITLE TEXT-001.
    SELECT-OPTIONS: pa_werks FOR mard-werks OBLIGATORY,    "Centro.
                    pa_lgort FOR mard-lgort OBLIGATORY,    "Almacén.
                    pa_matnr FOR mard-matnr,               "Material.
                    pa_charg FOR mchb-charg.               "Lote.

    PARAMETERS:     pa_vtweg TYPE mvke-vtweg DEFAULT '01'. "Canal de distribución
  SELECTION-SCREEN END OF BLOCK bloque2.

* & ------------------------------------------------------------*
* & Parametrizacion de lista
* & ------------------------------------------------------------*
  SELECTION-SCREEN BEGIN OF BLOCK bloque3 WITH FRAME TITLE TEXT-002.
    PARAMETERS: p_stock AS CHECKBOX DEFAULT 'X'.
  SELECTION-SCREEN END OF BLOCK bloque3.

* & ------------------------------------------------------------*
* & Parametrizacion de lista
* & ------------------------------------------------------------*
  SELECTION-SCREEN BEGIN OF BLOCK bloque4 WITH FRAME TITLE TEXT-003.
    "PARAMETERS: p_status AS CHECKBOX DEFAULT 'X'.
    PARAMETERS: p_layout TYPE slis_vari.
  SELECTION-SCREEN END OF BLOCK bloque4.
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
