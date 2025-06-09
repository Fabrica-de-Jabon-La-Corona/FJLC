*&---------------------------------------------------------------------*
*& Include          ZTM_FEVIAJES_ALV_SEL
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK bloque1.
* & ------------------------------------------------------------*
* & Filtros de viajes
* & ------------------------------------------------------------*
  SELECTION-SCREEN BEGIN OF BLOCK bloque2 WITH FRAME TITLE TEXT-001.
    SELECT-OPTIONS: pa_vkgrp FOR vbak-vkgrp OBLIGATORY,   " Grupo de vendedores (agente/broker).
                    pa_pedid FOR vbak-vbeln,              "Número de pedido.
                    pa_viaje FOR /scmtms/d_torrot-tor_id, "Número de viaje.
                    "pa_fechp FOR vbak-audat,              "Fecha de documento (pedido).
                    pa_feche FOR vbak-vdatu,              "Fecha preferente de entrega.
                    pa_ruta  FOR vbap-route,              "Ruta.
                    pa_werks FOR vbap-werks,              "Centro.
                    pa_lgort FOR vbap-lgort,              "Almacen.
                    pa_statu FOR vbak-gbstk.              "Status Global de Pedido
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
