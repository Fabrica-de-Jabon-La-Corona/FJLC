*&---------------------------------------------------------------------*
*& Report ZSD_TIMBRECFDI_ALV
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zsd_timbrecfdi_alv.

TABLES : vbrk, kna1, knvv, tvgrt, bkpf.
TYPE-POOLS : slis.

**Declaración de tablas internas
DATA : wa_cfdi       TYPE zsd_cfdi_return,
       it_cfdi       TYPE STANDARD TABLE OF zsd_cfdi_return,
       wa_cfdi_pagos TYPE zfi_pagos_return,
       it_cfdi_pagos TYPE STANDARD TABLE OF zfi_pagos_return,
       it_cfdi_porte TYPE STANDARD TABLE OF ztm_cfdiccp,
       wa_cfdi_porte TYPE ztm_cfdiccp.

**Declaración de datos
DATA: fieldcatalog TYPE slis_t_fieldcat_alv WITH HEADER LINE,
      gd_layout    TYPE slis_layout_alv,
      gd_repid     LIKE sy-repid,
      g_save       TYPE c VALUE 'X',
      g_variant    TYPE disvariant,
      gx_variant   TYPE disvariant,
      lv_fini      TYPE vbrk-fkdat,
      gv_count     TYPE i,
      g_exit       TYPE c,
      lv_prog      TYPE c LENGTH 19.

lv_fini = sy-datum - 30.

**Declaración de constantes
CONSTANTS: lc_prinvo  TYPE c LENGTH 13 VALUE 'ZCFDI_MONITOR',
           lc_prpago  TYPE c LENGTH 19 VALUE 'ZCFDI_MONITOR_PAGOS',
           lc_prporte TYPE c LENGTH 14 VALUE 'ZTM_CARTAPORTE',
           gc_refresh TYPE syucomm VALUE '&REFRESH',
           c_x        TYPE c LENGTH 1 VALUE 'X'.

**Parámetros de selección
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-002 .

  PARAMETERS: p_serie  TYPE zserie DEFAULT 'FAXA' OBLIGATORY,
              p_socied TYPE bukrs DEFAULT 'LACN' OBLIGATORY MODIF ID a01,
              p_ejerci TYPE gjahr DEFAULT sy-datum(4) OBLIGATORY MODIF ID a01.


  SELECT-OPTIONS: p_folio  FOR vbrk-vbeln,
                  p_client FOR kna1-kunnr,
                  p_agente FOR tvgrt-vkgrp,
                  p_zonav  FOR knvv-bzirk,
                  p_cadena FOR knvv-kvgr1,
                  p_uuid   FOR bkpf-glo_ref1_hd,
                  p_fecha  FOR vbrk-fkdat.

SELECTION-SCREEN END OF BLOCK b1.

" delimitacion fecha factura/pago 30 dias antes a la fecha del dia 19-07-2024

INITIALIZATION.
  lv_fini = sy-datum - 1.
  p_fecha-low = lv_fini.
  p_fecha-high = sy-datum.
  p_fecha-sign = 'I'.
  APPEND p_fecha.

**Declaración de estructura final
  IF lv_prog EQ lc_prpago.
    DATA:
      BEGIN OF tt_timbrecfdip  OCCURS 0,
        sociedad       TYPE bukrs,
        serie          TYPE serie,
        nodocu         TYPE vbeln,
        agente         TYPE vbrp-vkgrp,
        zona           TYPE vbrk-bzirk,
        cliente        TYPE vbrk-kunag,
        cadena         TYPE vbrp-kvgr1,
        ejercicio      TYPE gjahr,
        uuid           TYPE zuuid32,
        fectimbre      TYPE zfectimccp,
        rfcproovcertif TYPE zrfcprov,
        certificadosat TYPE zcertisat,
        cancelado      TYPE zcancelado,
        pdf            TYPE icon-id,
        xml            TYPE icon-id,
        email          TYPE icon-id,
        status         TYPE zstatus,
        noerror        TYPE znoerror,
        mensaje        TYPE zmensaje,
        docanula       TYPE vbeln,
        tcode          TYPE bkpf-tcode,
      END OF tt_timbrecfdip.
    DATA:
    ts_timbrecfdip  LIKE tt_timbrecfdip.

  ELSEIF lv_prog EQ lc_prporte.    "Colocar la constante con el nombre de programa en la tabla ZPARAMGLOB para carta porte.
    DATA:
      BEGIN OF tt_timbreporte  OCCURS 0,
        serie          TYPE zserie,
        notrans        TYPE /scmtms/tor_id,
        transportista  TYPE /scmtms/pty_carrier,      "TORROT
        desctransport  TYPE c LENGTH 160,
        chofer         TYPE /scmtms/res_name,         "TORITE
        nomchofer      TYPE c LENGTH 160,
        tracto         TYPE /scmtms/res_name,         "TORITE
        placatracto    TYPE /scmtms/resplatenr,       "TORITE
        remolque1      TYPE /scmtms/res_name,
        placarem1      TYPE /scmtms/resplatenr,
        remolque2      TYPE /scmtms/res_name,
        placarem2      TYPE /scmtms/resplatenr,
        uuid           TYPE zuuid32,
        fectimbre      TYPE zfectimccp,
        rfcproovcertif TYPE zrfcprov,
        certificadosat TYPE zcertisat,
        cancelado      TYPE zcancelado,
        pdf            TYPE icon-id,
        xml            TYPE icon-id,
        email          TYPE icon-id,
        status         TYPE zstatus,
        noerror        TYPE znoerror,
        mensaje        TYPE zmensaje,
      END OF tt_timbreporte.
    DATA:
    ts_timbreporte LIKE tt_timbreporte.
  ELSEIF lv_prog EQ lc_prinvo.
    DATA:
      BEGIN OF tt_timbrecfdi  OCCURS 0,
        serie          TYPE serie,
        nodocu         TYPE vbeln,
        cliente        TYPE kunnr,
        nombrecte      TYPE c LENGTH 163,
        pedcte         TYPE bstkd,
        uuid           TYPE zuuid32,
        fectimbre      TYPE zfectimccp,
        rfcproovcertif TYPE zrfcprov,
        certificadosat TYPE zcertisat,
        cancelado      TYPE zcancelado,
        pdf            TYPE icon-id,
        xml            TYPE icon-id,
        email          TYPE icon-id,
        status         TYPE zstatus,
        noerror        TYPE znoerror,
        mensaje        TYPE zmensaje,
        docanula       TYPE vbeln,
      END OF tt_timbrecfdi.
    DATA:
    ts_timbrecfdi  LIKE tt_timbrecfdi.
  ENDIF.

AT SELECTION-SCREEN OUTPUT.

**Se busca en ZPARAMGLOB a que tipo de documento pertenece la serie capturada.
  SELECT SINGLE programa INTO @lv_prog
    FROM zparamglob
    WHERE valor5  EQ @p_serie
    AND parametro EQ '2'
    AND programa  EQ 'ZCFDI_MONITOR'.

  IF sy-subrc NE 0.
    SELECT SINGLE programa INTO @lv_prog
      FROM zparamglob
      WHERE valor1  EQ @p_serie
      AND parametro EQ '3'
      AND programa  EQ 'ZCFDI_MONITOR_PAGOS'.
    IF sy-subrc NE 0.
      SELECT SINGLE programa INTO @lv_prog
        FROM zparamglob
        WHERE valor2 EQ @p_serie
        AND parametro EQ '5'
        AND programa EQ 'ZTM_CARTAPORTE'.
      IF sy-subrc NE 0.
        MESSAGE e002(zsd) WITH p_serie.
      ENDIF.
    ENDIF.
  ENDIF.

  LOOP AT SCREEN.
    IF lv_prog EQ lc_prpago AND screen-group1 EQ 'A01'.
      screen-active = '1'.
      MODIFY SCREEN.
      CONTINUE.
    ELSEIF lv_prog EQ lc_prinvo AND screen-group1 EQ 'A01'.
      screen-active = '0'.
      MODIFY SCREEN.
      CONTINUE.
    ELSEIF lv_prog EQ lc_prporte AND screen-group1 EQ 'A01'.
      screen-active = '0'.
      MODIFY SCREEN.
      CONTINUE.
    ENDIF.
  ENDLOOP.

**Se obtiene variante por defecto
INITIALIZATION.
  gx_variant-report = sy-repid.
  CALL FUNCTION 'REUSE_ALV_VARIANT_DEFAULT_GET'
    EXPORTING
      i_save     = g_save
    CHANGING
      cs_variant = gx_variant
    EXCEPTIONS
      not_found  = 2.

  IF sy-subrc = 0.
*    variant = gx_variant-variant.
  ENDIF.

**Declaraciones de "PERFORMS"
START-OF-SELECTION.
  PERFORM data_retrivel.

END-OF-SELECTION.
  PERFORM build_fieldcatalog.
  PERFORM display_alv_report.

*&---------------------------------------------------------------------*
*&      Form  BUILD_FIELDCATALOG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_fieldcatalog .

  IF lv_prog EQ lc_prinvo.

    fieldcatalog-fieldname   = 'SERIE'.
    fieldcatalog-seltext_m   = 'Serie'.
    fieldcatalog-col_pos     = 0.
    fieldcatalog-outputlen   = 5.
    fieldcatalog-key         = 'X'.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'NODOCU'.
    fieldcatalog-seltext_m   = 'Folio'.
    fieldcatalog-col_pos     = 1.
    fieldcatalog-outputlen   = 10.
    fieldcatalog-key         = 'X'.
    fieldcatalog-hotspot     = 'X'.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'CLIENTE'.
    fieldcatalog-seltext_m   = 'Cliente'.
    fieldcatalog-col_pos     = 2.
    fieldcatalog-outputlen   = 10.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'NOMBRECTE'.
    fieldcatalog-seltext_m   = 'Nombre'.
    fieldcatalog-col_pos     = 3.
    fieldcatalog-outputlen   = 40..
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'PEDCTE'.
    fieldcatalog-seltext_m   = 'Pedido Cliente'.
    fieldcatalog-col_pos     = 4.
    fieldcatalog-outputlen   = 35..
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'UUID'.
    fieldcatalog-seltext_m   = 'UUID'.
    fieldcatalog-col_pos     = 5.
    fieldcatalog-outputlen   = 36.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'FECTIMBRE'.
    fieldcatalog-seltext_m   = 'Fecha de Timbrado'.
    fieldcatalog-col_pos     = 6.
    fieldcatalog-outputlen   = 18.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'RFCPROOVCERTIF'.
    fieldcatalog-seltext_m   = 'RFC Prov Cert'.
    fieldcatalog-col_pos     = 7.
    fieldcatalog-outputlen   = 13.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'CERTIFICADOSAT'.
    fieldcatalog-seltext_m   = 'Certificado SAT'.
    fieldcatalog-col_pos     = 8.
    fieldcatalog-outputlen   = 20.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'PDF'.
    fieldcatalog-seltext_m   = 'PDF'.
    fieldcatalog-col_pos     = 9.
    fieldcatalog-outputlen   = 3.
    fieldcatalog-icon        = 'X'.
    fieldcatalog-hotspot     = 'X'.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'XML'.
    fieldcatalog-seltext_m   = 'XML'.
    fieldcatalog-col_pos     = 10.
    fieldcatalog-outputlen   = 3.
    fieldcatalog-icon        = 'X'.
    fieldcatalog-hotspot     = 'X'.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'EMAIL'.
    fieldcatalog-seltext_m   = 'Correo'.
    fieldcatalog-col_pos     = 11.
    fieldcatalog-outputlen   = 6.
    fieldcatalog-icon        = 'X'.
    fieldcatalog-hotspot     = 'X'.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'CANCELADO'.
    fieldcatalog-seltext_m   = 'Cancelado'.
    fieldcatalog-col_pos     = 12.
    fieldcatalog-outputlen   = 9.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'STATUS'.
    fieldcatalog-seltext_m   = 'Estatus'.
    fieldcatalog-col_pos     = 13.
    fieldcatalog-outputlen   = 10.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'NOERROR'.
    fieldcatalog-seltext_m   = 'No. de Error'.
    fieldcatalog-col_pos     = 14.
    fieldcatalog-outputlen   = 8.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'MENSAJE'.
    fieldcatalog-seltext_m   = 'Mensaje'.
    fieldcatalog-col_pos     = 15.
    fieldcatalog-outputlen   = 200.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'DOCANULA'.
    fieldcatalog-seltext_m   = 'Doc. Anulación'.
    fieldcatalog-col_pos     = 16.
    fieldcatalog-outputlen   = 13.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

  ELSEIF lv_prog EQ lc_prpago.

    fieldcatalog-fieldname   = 'SOCIEDAD'.
    fieldcatalog-seltext_m   = 'Sociedad'.
    fieldcatalog-col_pos     = 0.
    fieldcatalog-outputlen   = 8.
    fieldcatalog-key         = 'X'.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'SERIE'.
    fieldcatalog-seltext_m   = 'Serie'.
    fieldcatalog-col_pos     = 1.
    fieldcatalog-outputlen   = 5.
    fieldcatalog-key         = 'X'.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'NODOCU'.
    fieldcatalog-seltext_m   = 'Folio'.
    fieldcatalog-col_pos     = 2.
    fieldcatalog-outputlen   = 10.
    fieldcatalog-key         = 'X'.
    fieldcatalog-hotspot     = 'X'.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'AGENTE'.
    fieldcatalog-seltext_m   = 'Agente'.
    fieldcatalog-col_pos     = 3.
    fieldcatalog-outputlen   = 5.
    fieldcatalog-key         = 'X'.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.
    fieldcatalog-fieldname   = 'ZONA'.
    fieldcatalog-seltext_m   = 'Zona'.
    fieldcatalog-col_pos     = 4.
    fieldcatalog-outputlen   = 8.
    fieldcatalog-key         = 'X'.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.
    fieldcatalog-fieldname   = 'CLIENTE'.
    fieldcatalog-seltext_m   = 'Cliente'.
    fieldcatalog-col_pos     = 5.
    fieldcatalog-outputlen   = 10.
    fieldcatalog-key         = 'X'.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.
    fieldcatalog-fieldname   = 'CADENA'.
    fieldcatalog-seltext_m   = 'Cadena'.
    fieldcatalog-col_pos     = 6.
    fieldcatalog-outputlen   = 8.
    fieldcatalog-key         = 'X'.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'EJERCICIO'.
    fieldcatalog-seltext_m   = 'Ejercicio'.
    fieldcatalog-col_pos     = 7.
    fieldcatalog-outputlen   = 9.
    fieldcatalog-key         = 'X'.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'UUID'.
    fieldcatalog-seltext_m   = 'UUID'.
    fieldcatalog-col_pos     = 8.
    fieldcatalog-outputlen   = 36.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'FECTIMBRE'.
    fieldcatalog-seltext_m   = 'Fecha de Timbrado'.
    fieldcatalog-col_pos     = 9.
    fieldcatalog-outputlen   = 18.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'RFCPROOVCERTIF'.
    fieldcatalog-seltext_m   = 'RFC Prov Cert'.
    fieldcatalog-col_pos     = 10.
    fieldcatalog-outputlen   = 13.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'CERTIFICADOSAT'.
    fieldcatalog-seltext_m   = 'Certificado SAT'.
    fieldcatalog-col_pos     = 11.
    fieldcatalog-outputlen   = 20.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'PDF'.
    fieldcatalog-seltext_m   = 'PDF'.
    fieldcatalog-col_pos     = 12.
    fieldcatalog-outputlen   = 3.
    fieldcatalog-icon        = 'X'.
    fieldcatalog-hotspot     = 'X'.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'XML'.
    fieldcatalog-seltext_m   = 'XML'.
    fieldcatalog-col_pos     = 13.
    fieldcatalog-outputlen   = 3.
    fieldcatalog-icon        = 'X'.
    fieldcatalog-hotspot     = 'X'.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'EMAIL'.
    fieldcatalog-seltext_m   = 'Correo'.
    fieldcatalog-col_pos     = 14.
    fieldcatalog-outputlen   = 6.
    fieldcatalog-icon        = 'X'.
    fieldcatalog-hotspot     = 'X'.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'CANCELADO'.
    fieldcatalog-seltext_m   = 'Cancelado'.
    fieldcatalog-col_pos     = 15.
    fieldcatalog-outputlen   = 9.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'STATUS'.
    fieldcatalog-seltext_m   = 'Estatus'.
    fieldcatalog-col_pos     = 16.
    fieldcatalog-outputlen   = 10.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'NOERROR'.
    fieldcatalog-seltext_m   = 'No. de Error'.
    fieldcatalog-col_pos     = 17.
    fieldcatalog-outputlen   = 8.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'MENSAJE'.
    fieldcatalog-seltext_m   = 'Mensaje'.
    fieldcatalog-col_pos     = 18.
    fieldcatalog-outputlen   = 200.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'DOCANULA'.
    fieldcatalog-seltext_m   = 'Doc. Anulación'.
    fieldcatalog-col_pos     = 19.
    fieldcatalog-outputlen   = 13.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

  ELSEIF lv_prog EQ lc_prporte.

    fieldcatalog-fieldname   = 'SERIE'.
    fieldcatalog-seltext_m   = 'Serie'.
    fieldcatalog-col_pos     = 1.
    fieldcatalog-outputlen   = 5.
    fieldcatalog-key         = 'X'.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'NOTRANS'.
    fieldcatalog-seltext_m   = 'Transporte'.
    fieldcatalog-col_pos     = 2.
    fieldcatalog-outputlen   = 10.
    fieldcatalog-key         = 'X'.
    fieldcatalog-hotspot     = 'X'.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'TRANSPORTISTA'.
    fieldcatalog-seltext_m   = 'Transportista'.
    fieldcatalog-col_pos     = 3.
    fieldcatalog-outputlen   = 10.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'DESCTRANSPORT'.
    fieldcatalog-seltext_m   = 'Nombre Trans.'.
    fieldcatalog-col_pos     = 4.
    fieldcatalog-outputlen   = 160.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'CHOFER'.
    fieldcatalog-seltext_m   = 'Chofer'.
    fieldcatalog-col_pos     = 5.
    fieldcatalog-outputlen   = 10.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'NOMCHOFER'.
    fieldcatalog-seltext_m   = 'Nombre Chofer'.
    fieldcatalog-col_pos     = 6.
    fieldcatalog-outputlen   = 160.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'TRACTO'.
    fieldcatalog-seltext_m   = 'Tracto'.
    fieldcatalog-col_pos     = 7.
    fieldcatalog-outputlen   = 10.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'PLACATRACTO'.
    fieldcatalog-seltext_m   = 'Placa Tracto'.
    fieldcatalog-col_pos     = 8.
    fieldcatalog-outputlen   = 10.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'REMOLQUE1'.
    fieldcatalog-seltext_m   = 'Remolque 1'.
    fieldcatalog-col_pos     = 9.
    fieldcatalog-outputlen   = 10.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'PLACAREM1'.
    fieldcatalog-seltext_m   = 'Placa Remolque 1'.
    fieldcatalog-col_pos     = 10.
    fieldcatalog-outputlen   = 10.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'REMOLQUE2'.
    fieldcatalog-seltext_m   = 'Remolque 2'.
    fieldcatalog-col_pos     = 11.
    fieldcatalog-outputlen   = 10.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'PLACAREM2'.
    fieldcatalog-seltext_m   = 'Placa Remolque 2'.
    fieldcatalog-col_pos     = 12.
    fieldcatalog-outputlen   = 10.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'UUID'.
    fieldcatalog-seltext_m   = 'UUID'.
    fieldcatalog-col_pos     = 13.
    fieldcatalog-outputlen   = 36.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'FECTIMBRE'.
    fieldcatalog-seltext_m   = 'Fecha de Timbrado'.
    fieldcatalog-col_pos     = 14.
    fieldcatalog-outputlen   = 18.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'RFCPROOVCERTIF'.
    fieldcatalog-seltext_m   = 'RFC Prov Cert'.
    fieldcatalog-col_pos     = 15.
    fieldcatalog-outputlen   = 13.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'CERTIFICADOSAT'.
    fieldcatalog-seltext_m   = 'Certificado SAT'.
    fieldcatalog-col_pos     = 16.
    fieldcatalog-outputlen   = 20.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'PDF'.
    fieldcatalog-seltext_m   = 'PDF'.
    fieldcatalog-col_pos     = 17.
    fieldcatalog-outputlen   = 3.
    fieldcatalog-icon        = 'X'.
    fieldcatalog-hotspot     = 'X'.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'XML'.
    fieldcatalog-seltext_m   = 'XML'.
    fieldcatalog-col_pos     = 18.
    fieldcatalog-outputlen   = 3.
    fieldcatalog-icon        = 'X'.
    fieldcatalog-hotspot     = 'X'.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'EMAIL'.
    fieldcatalog-seltext_m   = 'Correo'.
    fieldcatalog-col_pos     = 19.
    fieldcatalog-outputlen   = 6.
    fieldcatalog-icon        = 'X'.
    fieldcatalog-hotspot     = 'X'.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'CANCELADO'.
    fieldcatalog-seltext_m   = 'Cancelado'.
    fieldcatalog-col_pos     = 20.
    fieldcatalog-outputlen   = 9.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'STATUS'.
    fieldcatalog-seltext_m   = 'Estatus'.
    fieldcatalog-col_pos     = 21.
    fieldcatalog-outputlen   = 10.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'NOERROR'.
    fieldcatalog-seltext_m   = 'No. de Error'.
    fieldcatalog-col_pos     = 22.
    fieldcatalog-outputlen   = 8.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.

    fieldcatalog-fieldname   = 'MENSAJE'.
    fieldcatalog-seltext_m   = 'Mensaje'.
    fieldcatalog-col_pos     = 23.
    fieldcatalog-outputlen   = 200.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR  fieldcatalog.
  ENDIF.

ENDFORM.                    " BUILD_FIELDCATALOG

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ALV_REPORT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_alv_report .

  DATA: lt_event_exit TYPE slis_t_event_exit,
        ls_event_exit TYPE slis_event_exit,
        ls_layout     TYPE slis_layout_alv.


  CLEAR: ls_event_exit, ls_layout.
  ls_event_exit-ucomm = gc_refresh.    " Refresh
  ls_event_exit-after = c_x.
  APPEND ls_event_exit TO lt_event_exit.

  ls_layout-zebra = c_x.
  ls_layout-colwidth_optimize = c_x.
  gd_repid = sy-repid.


  IF lv_prog EQ lc_prinvo.

    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_callback_program       = gd_repid
        i_callback_top_of_page   = 'TOP-OF-PAGE'  "see FORM
        i_callback_pf_status_set = 'PF_STATUS_SET'
        i_callback_user_command  = 'USER_COMMAND'
        it_fieldcat              = fieldcatalog[]
        it_event_exit            = lt_event_exit
        i_save                   = 'X'
        is_variant               = g_variant
        is_layout                = ls_layout
      TABLES
        t_outtab                 = tt_timbrecfdi
      EXCEPTIONS
        program_error            = 1
        OTHERS                   = 2.
    IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.
  ELSEIF lv_prog EQ lc_prpago.

    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_callback_program       = gd_repid
        i_callback_top_of_page   = 'TOP-OF-PAGE'  "see FORM
        i_callback_pf_status_set = 'PF_STATUS_SET'
        i_callback_user_command  = 'USER_COMMAND'
        it_fieldcat              = fieldcatalog[]
        it_event_exit            = lt_event_exit
        i_save                   = 'X'
        is_variant               = g_variant
        is_layout                = ls_layout
      TABLES
        t_outtab                 = tt_timbrecfdip
      EXCEPTIONS
        program_error            = 1
        OTHERS                   = 2.
    IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.
  ELSEIF lv_prog EQ lc_prporte.

    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_callback_program       = gd_repid
        i_callback_top_of_page   = 'TOP-OF-PAGE'  "see FORM
        i_callback_pf_status_set = 'PF_STATUS_SET'
        i_callback_user_command  = 'USER_COMMAND'
        it_fieldcat              = fieldcatalog[]
        it_event_exit            = lt_event_exit
        i_save                   = 'X'
        is_variant               = g_variant
        is_layout                = ls_layout
      TABLES
        t_outtab                 = tt_timbreporte
      EXCEPTIONS
        program_error            = 1
        OTHERS                   = 2.
    IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.

  ENDIF.
ENDFORM.                    "DISPLAY_ALV_REPORT

*&---------------------------------------------------------------------*
*&      Form  DATA_RETRIVEL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM data_retrivel .

  gv_count = 0.

  IF lv_prog EQ lc_prinvo.

    DATA:
      BEGIN OF it_facturas OCCURS 0,
        vbeln TYPE vbrk-vbeln,
      END OF it_facturas.
    DATA:
    wa_facturas LIKE it_facturas.

    DATA: it_tvkgr TYPE STANDARD TABLE OF tvkgr,
          wa_tvkgr TYPE tvkgr,
          it_t171  TYPE STANDARD TABLE OF t171,
          wa_t171  TYPE t171,
          it_tvv1  TYPE STANDARD TABLE OF tvv1,
          wa_tvv1  TYPE tvv1.

    SELECT * FROM tvkgr
      WHERE vkgrp IN @p_agente
    INTO TABLE @it_tvkgr.

    LOOP AT it_tvkgr INTO wa_tvkgr.
      AUTHORITY-CHECK OBJECT 'ZSD_VKGRP'
      ID 'VKGRP' FIELD wa_tvkgr-vkgrp
      ID 'ACTVT' FIELD '03'.

      IF sy-subrc NE 0.
        MESSAGE e003(zsd) WITH wa_tvkgr-vkgrp.
      ENDIF.
    ENDLOOP.

    SELECT * FROM tvv1
      WHERE kvgr1 IN @p_cadena
    INTO TABLE @it_tvv1.

    LOOP AT it_tvv1 INTO wa_tvv1.
      AUTHORITY-CHECK OBJECT 'ZSD_KVGR1'
      ID 'KVGR1' FIELD wa_tvv1-kvgr1
      ID 'ACTVT' FIELD '03'.

      IF sy-subrc NE 0.
        MESSAGE e004(zsd) WITH wa_tvv1-kvgr1.
      ENDIF.
    ENDLOOP.

    SELECT * FROM t171
      WHERE bzirk IN @p_zonav
    INTO TABLE @it_t171.

    LOOP AT it_t171 INTO wa_t171.
      AUTHORITY-CHECK OBJECT 'ZSD_BZIRK'
      ID 'BZIRK' FIELD wa_t171-bzirk
      ID 'ACTVT' FIELD '03'.

      IF sy-subrc NE 0.
        MESSAGE e005(zsd) WITH wa_t171-bzirk.
      ENDIF.
    ENDLOOP.

    SELECT a~vbeln FROM vbrk AS a
      INNER JOIN vbrp AS b
      ON b~vbeln EQ a~vbeln
      WHERE a~vbeln IN @p_folio
      AND a~bzirk IN @p_zonav
      AND b~vkgrp IN @p_agente
      AND a~kunag IN @p_client
      AND b~kvgr1 IN @p_cadena
      AND a~fkdat IN @p_fecha
    INTO TABLE @it_facturas.

    IF sy-subrc EQ 0.
      SORT it_facturas ASCENDING BY vbeln.
      DELETE ADJACENT DUPLICATES FROM it_facturas COMPARING vbeln.

      IF p_folio EQ ''.
        SELECT * FROM zsd_cfdi_return
          FOR ALL ENTRIES IN @it_facturas
          WHERE serie EQ @p_serie
          AND nodocu EQ @it_facturas-vbeln
        INTO TABLE @it_cfdi.
      ELSEIF p_folio NE ''.
        SELECT * FROM zsd_cfdi_return
          WHERE serie EQ @p_serie
          AND nodocu IN @p_folio
        INTO TABLE @it_cfdi.
      ENDIF.
    ENDIF.

    SELECT a~vbeln, a~kunag, b~name1, b~name2, b~name3, b~name4 FROM vbrk AS a
      INNER JOIN kna1 AS b ON b~kunnr EQ a~kunag
      FOR ALL ENTRIES IN @it_cfdi
      WHERE a~vbeln EQ @it_cfdi-nodocu
      INTO TABLE @DATA(lt_clientes).

    SELECT a~vbeln, a~aubel, b~bstkd FROM vbrp AS a
      LEFT OUTER JOIN vbkd AS b ON b~vbeln EQ a~aubel
      FOR ALL ENTRIES IN @it_cfdi
      WHERE a~vbeln EQ @it_cfdi-nodocu
      INTO TABLE @DATA(lt_pedctes).

    SORT lt_pedctes ASCENDING BY vbeln.
    DELETE ADJACENT DUPLICATES FROM lt_pedctes COMPARING vbeln.

    LOOP AT it_cfdi INTO wa_cfdi.
      ts_timbrecfdi-serie          = wa_cfdi-serie.
      ts_timbrecfdi-nodocu         = wa_cfdi-nodocu.
      ts_timbrecfdi-uuid           = wa_cfdi-uuid.
      ts_timbrecfdi-fectimbre      = wa_cfdi-fectimbre.
      ts_timbrecfdi-rfcproovcertif = wa_cfdi-rfcproovcertif.
      ts_timbrecfdi-certificadosat = wa_cfdi-certificadosat.
      ts_timbrecfdi-cancelado      = wa_cfdi-cancelado.
      ts_timbrecfdi-status         = wa_cfdi-status.
      ts_timbrecfdi-noerror        = wa_cfdi-noerror.
      ts_timbrecfdi-mensaje        = wa_cfdi-mensaje.
      ts_timbrecfdi-docanula       = wa_cfdi-docanula.

      "Ini - CAOG - Se añade lógica para traer el documento de anulación de una factura cancelada - 01.04.2025 -
      SELECT SINGLE fksto INTO @DATA(lv_fksto)
        FROM vbrk
        WHERE vbeln EQ @wa_cfdi-nodocu.

      IF lv_fksto EQ 'X' AND wa_cfdi-docanula EQ ''.
        SELECT SINGLE vbeln INTO @ts_timbrecfdi-docanula
          FROM vbrk
          WHERE sfakn EQ @wa_cfdi-nodocu.
        CLEAR: lv_fksto.
      ENDIF.
      "Fin - CAOG - Se añade lógica para traer el documento de anulación de una factura cancelada - 01.04.2025 -

      READ TABLE lt_clientes ASSIGNING FIELD-SYMBOL(<fs_clientes>) WITH KEY vbeln = wa_cfdi-nodocu.

      IF <fs_clientes> IS ASSIGNED.
        ts_timbrecfdi-cliente = <fs_clientes>-kunag.

        CONCATENATE <fs_clientes>-name1 <fs_clientes>-name2 <fs_clientes>-name3 <fs_clientes>-name4 INTO ts_timbrecfdi-nombrecte SEPARATED BY space.
        CONDENSE ts_timbrecfdi-nombrecte.
      ENDIF.

      READ TABLE lt_pedctes ASSIGNING FIELD-SYMBOL(<fs_pedctes>) WITH KEY vbeln = wa_cfdi-nodocu.

      IF <fs_pedctes> IS ASSIGNED.
        ts_timbrecfdi-pedcte = <fs_pedctes>-bstkd.
      ENDIF.

      gv_count = gv_count + 1.

      IF wa_cfdi-uuid NE ''.
        ts_timbrecfdi-pdf   = '@IT@'.    "Icono PDF.
        ts_timbrecfdi-xml   = '@R4@'.    "Icono XML.
        ts_timbrecfdi-email = '@1S@'.    "Icono Correo.
      ENDIF.

      APPEND ts_timbrecfdi    TO tt_timbrecfdi.
      CLEAR: ts_timbrecfdi, <fs_clientes>, <fs_pedctes>.
    ENDLOOP.
    SORT tt_timbrecfdi BY serie nodocu ASCENDING.
    DELETE ADJACENT DUPLICATES FROM tt_timbrecfdi COMPARING serie nodocu.
    CLEAR wa_cfdi.

  ELSEIF lv_prog EQ lc_prpago.

*&---Modificacion para campos de seleccion 03-julio-2024------------------------------------------------------------------*

    SELECT z~* FROM zfi_pagos_return AS z
      LEFT OUTER JOIN bsad_view AS c ON ( c~belnr = z~nodocu OR c~augbl = z~nodocu ) AND c~belnr <> ''
      LEFT OUTER JOIN bsid_view AS d ON d~belnr = z~nodocu
      LEFT OUTER JOIN vbrp AS b ON ( b~vbeln = c~kidno OR b~vbeln = d~vbeln )
      LEFT OUTER JOIN vbrk AS a ON ( a~vbeln = c~kidno OR a~vbeln = d~vbeln )
     WHERE serie EQ @p_serie
       AND sociedad EQ @p_socied
       AND ejercicio EQ @p_ejerci
       AND z~nodocu IN @p_folio
       AND z~uuid IN @p_uuid
       AND a~bzirk IN @p_zonav
       AND b~vkgrp IN @p_agente
       AND a~kunag IN @p_client
       AND b~kvgr1 IN @p_cadena
       AND ( c~budat IN @p_fecha OR d~budat IN @p_fecha )
      INTO TABLE @it_cfdi_pagos.
*&---------------------------------------------------------------------*
    IF sy-subrc EQ 0.
      SORT it_cfdi_pagos ASCENDING BY nodocu.
      DELETE ADJACENT DUPLICATES FROM it_cfdi_pagos COMPARING nodocu.
    ENDIF.

    LOOP AT it_cfdi_pagos INTO wa_cfdi_pagos.
      ts_timbrecfdip-sociedad = wa_cfdi_pagos-sociedad.
      ts_timbrecfdip-serie = wa_cfdi_pagos-serie.
      ts_timbrecfdip-nodocu = wa_cfdi_pagos-nodocu.

      SELECT SINGLE stblg, tcode INTO ( @ts_timbrecfdip-docanula, @ts_timbrecfdip-tcode )
        FROM bkpf
      WHERE belnr = @ts_timbrecfdip-nodocu.

      IF ts_timbrecfdip-tcode EQ 'FBCJ'.
        SELECT SINGLE b~vkgrp, a~bzirk, a~kunag, b~kvgr1
         INTO (@ts_timbrecfdip-agente, @ts_timbrecfdip-zona, @ts_timbrecfdip-cliente, @ts_timbrecfdip-cadena)
         FROM zfi_pagos_return AS z
         LEFT OUTER JOIN bsad AS c ON c~belnr = z~nodocu
         LEFT OUTER JOIN bsid AS d ON d~belnr = z~nodocu
         LEFT OUTER JOIN vbrp AS b ON ( b~vbeln = c~xblnr OR b~vbeln = d~zuonr )
         LEFT OUTER JOIN vbrk AS a ON ( a~vbeln = c~xblnr OR a~vbeln = d~zuonr )
        WHERE z~nodocu = @ts_timbrecfdip-nodocu.
        " Modificacion para pagos parciales (bsig) desde la caja   5-feb-2025
        "INNER JOIN bsad AS c ON c~belnr = @ts_timbrecfdip-nodocu
        "LEFT OUTER JOIN vbrp AS b ON b~vbeln = c~xblnr
        "LEFT OUTER JOIN vbrk AS a ON a~vbeln = c~xblnr
      ELSE.
        SELECT SINGLE b~vkgrp, a~bzirk, a~kunag, b~kvgr1
          FROM zfi_pagos_return AS z
          LEFT OUTER JOIN bsad_view AS c ON ( c~belnr = z~nodocu OR c~augbl = z~nodocu ) AND c~belnr <> ''
          LEFT OUTER JOIN bsid_view AS d ON ( d~vbeln = c~kidno OR d~belnr = z~nodocu )
          LEFT OUTER JOIN vbrp AS b ON ( b~vbeln = c~kidno OR b~vbeln = d~vbeln OR b~vbeln = d~zuonr )
          LEFT OUTER JOIN vbrk AS a ON ( a~vbeln = c~kidno OR a~vbeln = d~vbeln OR a~vbeln = d~zuonr )
         WHERE z~nodocu = @ts_timbrecfdip-nodocu AND a~vbeln <> ''
        INTO (@ts_timbrecfdip-agente, @ts_timbrecfdip-zona, @ts_timbrecfdip-cliente, @ts_timbrecfdip-cadena).
      ENDIF.

      ts_timbrecfdip-ejercicio = wa_cfdi_pagos-ejercicio.
      ts_timbrecfdip-uuid = wa_cfdi_pagos-uuid.
      ts_timbrecfdip-fectimbre = wa_cfdi_pagos-fectimbre.
      ts_timbrecfdip-rfcproovcertif = wa_cfdi_pagos-rfcproovcertif.
      ts_timbrecfdip-certificadosat = wa_cfdi_pagos-certificadosat.
      ts_timbrecfdip-cancelado = wa_cfdi_pagos-cancelado.
      ts_timbrecfdip-status = wa_cfdi_pagos-status.
      ts_timbrecfdip-noerror = wa_cfdi_pagos-noerror.
      ts_timbrecfdip-mensaje = wa_cfdi_pagos-mensaje.

      gv_count = gv_count + 1.

      IF wa_cfdi_pagos-uuid NE ''.
        ts_timbrecfdip-pdf   = '@IT@'.    "Icono PDF.
        ts_timbrecfdip-xml   = '@R4@'.    "Icono XML.
        ts_timbrecfdip-email = '@1S@'.    "Icono Correo.
      ENDIF.

      APPEND ts_timbrecfdip    TO tt_timbrecfdip.
      CLEAR: ts_timbrecfdip.
    ENDLOOP.
    SORT tt_timbrecfdip BY serie nodocu ASCENDING.
    DELETE ADJACENT DUPLICATES FROM tt_timbrecfdip COMPARING sociedad serie nodocu ejercicio.
    CLEAR wa_cfdi_pagos.

  ELSEIF lv_prog EQ lc_prporte.

    DATA:
      BEGIN OF lt_fletes OCCURS 0,
        tor_id TYPE /scmtms/tor_id,
      END OF lt_fletes.
    DATA:
    ls_fetes LIKE lt_fletes.

    DATA: lt_torrot     TYPE STANDARD TABLE OF /scmtms/d_torrot,
          ls_torrot     TYPE /scmtms/d_torrot,
          lt_torite     TYPE STANDARD TABLE OF /scmtms/d_torite,
          ls_torite     TYPE /scmtms/d_torite,
          lt_torite_rem TYPE STANDARD TABLE OF /scmtms/d_torite,
          ls_torite_rem TYPE /scmtms/d_torite,
          lt_but000     TYPE STANDARD TABLE OF but000,
          ls_but000     TYPE but000.

    DATA: lv_fechacreaini TYPE /scmtms/dlv_created_on,
          lv_fechacreafin TYPE /scmtms/dlv_created_on,
          lv_fechaini     TYPE d,
          lv_fechafin     TYPE d,
          lv_horaini      TYPE t,
          lv_horafin      TYPE t.

    "Se hace la selección de documentos de acuerdo a los parámetros de selección introducidos por el usuario.

    lv_fechaini = p_fecha-low.
    lv_fechafin = p_fecha-high.
    lv_horaini  = '000000'.
    lv_horafin  = '235959'.

    CONVERT DATE lv_fechaini TIME lv_horaini DAYLIGHT SAVING TIME 'X' INTO TIME STAMP lv_fechacreaini TIME ZONE 'UTC'.
    CONVERT DATE lv_fechafin TIME lv_horafin DAYLIGHT SAVING TIME 'X' INTO TIME STAMP lv_fechacreafin TIME ZONE 'UTC'.

    SELECT tor_id FROM /scmtms/d_torrot
      "WHERE tor_cat IN ( 'Z100', 'Z101', 'Z102' )
      WHERE created_on GE @lv_fechacreaini
      AND created_on LE @lv_fechacreafin
      INTO TABLE @lt_fletes.

    "Búsqueda de documentos seleccionados en tablas TM

    SELECT * FROM /scmtms/d_torrot
      FOR ALL ENTRIES IN @lt_fletes
      WHERE tor_id EQ @lt_fletes-tor_id
      INTO TABLE @lt_torrot.

    SELECT * FROM /scmtms/d_torite
      FOR ALL ENTRIES IN @lt_torrot
      WHERE parent_key EQ @lt_torrot-db_key
      INTO TABLE @lt_torite.

    "Comienza llenado de work area para mostrar en el ALV.
    IF lt_fletes[] IS NOT INITIAL.
      SORT lt_fletes ASCENDING BY tor_id.
      DELETE ADJACENT DUPLICATES FROM lt_fletes COMPARING tor_id.

      IF p_folio EQ ''.
        SELECT * FROM ztm_cfdiccp
          FOR ALL ENTRIES IN @lt_fletes
          WHERE serie EQ @p_serie
          AND notrans EQ @lt_fletes-tor_id
        INTO TABLE @it_cfdi_porte.
      ELSEIF p_folio NE ''.
        SELECT * FROM ztm_cfdiccp
          WHERE serie EQ @p_serie
          AND notrans IN @p_folio
        INTO TABLE @it_cfdi_porte.
      ENDIF.

      IF it_cfdi_porte[] IS NOT INITIAL.
        LOOP AT it_cfdi_porte INTO wa_cfdi_porte.
          ts_timbreporte-serie          = wa_cfdi_porte-serie.
          ts_timbreporte-notrans        = |{ wa_cfdi_porte-notrans ALPHA = OUT }|.
          ts_timbreporte-uuid           = wa_cfdi_porte-uuid.
          ts_timbreporte-fectimbre      = wa_cfdi_porte-fectimbre.
          ts_timbreporte-rfcproovcertif = wa_cfdi_porte-rfcproovcertif.
          ts_timbreporte-certificadosat = wa_cfdi_porte-certificadosat.
          ts_timbreporte-cancelado      = wa_cfdi_porte-cancelado.
          ts_timbreporte-status         = wa_cfdi_porte-status.
          ts_timbreporte-noerror        = wa_cfdi_porte-noerror.
          ts_timbreporte-mensaje        = wa_cfdi_porte-mensaje.

          IF wa_cfdi_porte-uuid NE ''.
            ts_timbreporte-pdf   = '@IT@'.    "Icono PDF.
            ts_timbreporte-xml   = '@R4@'.    "Icono XML.
            ts_timbreporte-email = '@1S@'.    "Icono Correo.
          ENDIF.

          READ TABLE lt_torrot INTO ls_torrot WITH KEY tor_id = wa_cfdi_porte-notrans.

          ts_timbreporte-transportista = ls_torrot-tspid.

          SELECT SINGLE name_org1, name_org2, name_org3, name_org4 INTO ( @DATA(lv_name1), @DATA(lv_name2), @DATA(lv_name3), @DATA(lv_name4) )
            FROM but000
            WHERE partner EQ @ls_torrot-tspid.

          CONCATENATE lv_name1 lv_name2 lv_name3 lv_name4 INTO ts_timbreporte-desctransport SEPARATED BY space.
          CONDENSE ts_timbreporte-desctransport.

          READ TABLE lt_torite INTO ls_torite WITH KEY parent_key = ls_torrot-db_key item_cat = 'DRI'.

          ts_timbreporte-chofer = |{ ls_torite-res_id ALPHA = OUT }|.

          SELECT SINGLE name_first, name_last INTO ( @DATA(lv_namef), @DATA(lv_namel) )
            FROM but000
            WHERE partner EQ @ls_torite-res_id.

          CONCATENATE lv_namef lv_namel INTO ts_timbreporte-nomchofer SEPARATED BY space.
          CONDENSE ts_timbreporte-nomchofer.

          IF ts_timbreporte-nomchofer EQ ''.    "Si el chofer no está dado de alta como BP, entonces se coloca el nombre dirento en la FO.
            ts_timbreporte-nomchofer = ls_torite-item_descr.
          ENDIF.

          CLEAR: ls_torite.

          READ TABLE lt_torite INTO ls_torite WITH KEY parent_key = ls_torrot-db_key item_type = 'TRUC'.

          ts_timbreporte-tracto      = |{ ls_torite-res_id ALPHA = OUT }|.
          ts_timbreporte-placatracto = ls_torite-platenumber.

          CLEAR: ls_torite.

          SELECT * FROM /scmtms/d_torite
            WHERE parent_key EQ @ls_torrot-db_key
            AND item_type EQ 'TRL'
            INTO TABLE @lt_torite_rem.

          SORT lt_torite_rem ASCENDING BY item_id.

          DESCRIBE TABLE lt_torite_rem LINES DATA(lv_rem).

          CASE lv_rem.
            WHEN 1.   "1 Remolque
              READ TABLE lt_torite_rem INTO ls_torite_rem WITH KEY parent_key = ls_torrot-db_key.
              ts_timbreporte-remolque1 = |{ ls_torite_rem-res_id ALPHA = OUT }|.
              ts_timbreporte-placarem1 = ls_torite_rem-platenumber.
              CLEAR ls_torite_rem.
            WHEN 2.   "2 Remolques
              READ TABLE lt_torite_rem INTO ls_torite_rem WITH KEY parent_key = ls_torrot-db_key.
              ts_timbreporte-remolque1 = |{ ls_torite_rem-res_id ALPHA = OUT }|.
              ts_timbreporte-placarem1 = ls_torite_rem-platenumber.
              CLEAR ls_torite_rem.

              SORT lt_torite_rem DESCENDING BY item_id.

              READ TABLE lt_torite_rem INTO ls_torite_rem WITH KEY parent_key = ls_torrot-db_key.
              ts_timbreporte-remolque2 = |{ ls_torite_rem-res_id ALPHA = OUT }|.
              ts_timbreporte-placarem2 = ls_torite_rem-platenumber.
              CLEAR ls_torite_rem.
            WHEN OTHERS.
          ENDCASE.

          CLEAR: ls_torrot.

          APPEND ts_timbreporte TO tt_timbreporte.
          CLEAR: ts_timbreporte, wa_cfdi_porte, lv_rem, lv_namef, lv_namel,lv_name1, lv_name2, lv_name3, lv_name4.
        ENDLOOP.
      ENDIF.

    ENDIF.

  ENDIF.
ENDFORM.                    " DATA_RETRIVEL

*-------------------------------------------------------------------*
* Form  TOP-OF-PAGE                                                 *
*-------------------------------------------------------------------*
* ALV Report Header                                                 *
*-------------------------------------------------------------------*
FORM top-of-page.
*ALV Header declarations
  DATA: t_header      TYPE slis_t_listheader,
        wa_header     TYPE slis_listheader,
        t_line        LIKE wa_header-info,
        ld_lines      TYPE i,
        ld_linesc(10) TYPE c.

* Título
  wa_header-typ  = 'H'.
  wa_header-info = 'Log de Timbrado de CFDI'.
  APPEND wa_header TO t_header.
  CLEAR wa_header.

* Fecha de ejecución
  wa_header-typ  = 'S'.
  wa_header-key = 'Fecha: '.
  CONCATENATE  sy-datum+6(2) '.'
               sy-datum+4(2) '.'
               sy-datum(4) INTO wa_header-info.
  APPEND wa_header TO t_header.
  CLEAR: wa_header.

* Hora de ejecución
  wa_header-typ  = 'S'.
  wa_header-key = 'Hora: '.
  CONCATENATE  sy-uzeit(2) ':'
              sy-uzeit+2(2) ':'
               sy-uzeit+4(2) INTO wa_header-info.   "todays date
  APPEND wa_header TO t_header.
  CLEAR: wa_header.

* Usuario que ejecuta
  wa_header-typ  = 'S'.
  wa_header-key = 'Usuario: '.
  wa_header-info = sy-uname.
  APPEND wa_header TO t_header.
  CLEAR wa_header.

  " Cantidad de registros
  wa_header-typ  = 'S'.
  wa_header-key = 'Registros: '.
  wa_header-info = gv_count.
  APPEND wa_header TO t_header.
  CLEAR wa_header.


  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = t_header
      i_logo             = 'ZLOGO_FJLC_COLOR'.
ENDFORM.                    "top-of-page

*&---------------------------------------------------------------------*
*&      Form  USER_COMMAND
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM user_command USING r_ucomm LIKE sy-ucomm
                        rs_selfield TYPE slis_selfield.

  DATA: lv_message       TYPE c LENGTH 100,
        lv_pdfb64        TYPE string,
        lv_xmlb64        TYPE string,
        lv_pdfxstr       TYPE xstring,
        lv_xmlxstr       TYPE xstring,
        lv_xmlsize       TYPE i,
        lv_pdfsize       TYPE i,
        lv_url           TYPE c LENGTH 255,
        lv_contname      TYPE string,                             "c LENGTH 255,
        g_html_container TYPE REF TO cl_gui_custom_container,
        g_html_control   TYPE REF TO cl_gui_html_viewer,
        lt_pdfdata       TYPE solix_tab,
        lt_xmldata       TYPE solix_tab,
        lv_direxist      TYPE c LENGTH 1,
        lv_fileexist     TYPE c LENGTH 1,
        lv_rc            TYPE sy-subrc,
        lt_filetab       TYPE filetable,
        lv_filepdf       TYPE string,
        lv_filexml       TYPE string,
        lv_filedir       TYPE string,
        lv_platform      TYPE i,
        lv_usrname       TYPE string.
  "lt_pdfdata       TYPE STANDARD TABLE OF x255,
  "lt_xmldata       TYPE STANDARD TABLE OF x255.

*  CALL METHOD cl_gui_frontend_services=>get_user_name
*    CHANGING
*      user_name = lv_usrname.

  CALL METHOD cl_gui_frontend_services=>get_platform
    RECEIVING
      platform = lv_platform.

  CASE lv_platform.
      "Windows
    WHEN 1.                          "'PLATFORM_WINDOWS95'.
      lv_filedir = 'C:\tmp\'.
    WHEN 2.                          "'PLATFORM_WINDOWS98'.
      lv_filedir = 'C:\tmp\'.
    WHEN 3.                          "'PLATFORM_NT351'.
      lv_filedir = 'C:\tmp\'.
    WHEN 4.                          "'PLATFORM_NT40'.
      lv_filedir = 'C:\tmp\'.
    WHEN 5.                          "'PLATFORM_NT50'.
      lv_filedir = 'C:\tmp\'.
    WHEN 14.                         "'PLATFORM_WINDOWSXP'.
      lv_filedir = 'C:\tmp\'.
      "MAC OS
    WHEN 6.                          "'PLATFORM_MAC'.
      lv_filedir = '/sap/temp/'.
      "CONCATENATE '/Users/' lv_usrname '/temp/' INTO lv_filedir.
    WHEN 13.                         "'PLATFORM_MACOSX'.
      lv_filedir = '/sap/temp/'.
      "CONCATENATE '/Users/' lv_usrname '/temp/' INTO lv_filedir.
      "Linux
    WHEN 8.                          "'PLATFORM_LINUX'.
      lv_filedir = '/sap/temp/'.
      "CONCATENATE '/Users/' lv_usrname '/temp/' INTO lv_filedir.
  ENDCASE.

  CASE r_ucomm.
    WHEN '&IC1'.           "Doble Clcik
      IF rs_selfield-fieldname EQ 'NODOCU'.
        IF lv_prog EQ lc_prinvo.
          READ TABLE it_cfdi INTO wa_cfdi WITH KEY nodocu = rs_selfield-value.
          IF sy-subrc EQ 0.
            SET PARAMETER ID 'VF' FIELD wa_cfdi-nodocu.
            CALL TRANSACTION 'VF03' AND SKIP FIRST SCREEN.
          ENDIF.
          CLEAR wa_cfdi.
        ELSEIF lv_prog EQ lc_prpago.
          READ TABLE it_cfdi_pagos INTO wa_cfdi_pagos WITH KEY nodocu = rs_selfield-value.
          IF sy-subrc EQ 0.
            SET PARAMETER ID 'BLN' FIELD wa_cfdi_pagos-nodocu.
            SET PARAMETER ID 'BUK' FIELD wa_cfdi_pagos-sociedad.
            SET PARAMETER ID 'GJR' FIELD wa_cfdi_pagos-ejercicio.
            CALL TRANSACTION 'FB03' AND SKIP FIRST SCREEN.
          ENDIF.
          CLEAR wa_cfdi_pagos.
        ENDIF.
      ELSEIF rs_selfield-fieldname EQ 'PDF'.
        IF lv_prog EQ lc_prinvo.
          SORT it_cfdi BY serie nodocu ASCENDING.

          READ TABLE it_cfdi INDEX rs_selfield-tabindex INTO wa_cfdi.

          IF sy-subrc EQ 0.
            lv_pdfb64 = wa_cfdi-pdf.

            CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
              EXPORTING
                input  = lv_pdfb64
              IMPORTING
                output = lv_pdfxstr.

            CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
              EXPORTING
                buffer     = lv_pdfxstr
              TABLES
                binary_tab = lt_pdfdata.

            CALL METHOD cl_bcs_convert=>xstring_to_string
              EXPORTING
                iv_xstr   = lv_pdfxstr
                iv_cp     = 1100
              RECEIVING
                rv_string = lv_filepdf.

            lv_pdfsize = strlen( lv_filepdf ).

            CONCATENATE lv_filedir wa_cfdi-serie wa_cfdi-nodocu '.pdf' INTO lv_contname.

            CALL METHOD cl_gui_frontend_services=>directory_exist
              EXPORTING
                directory = lv_filedir
              RECEIVING
                result    = lv_direxist.

            IF lv_direxist NE 'X'.
              CALL METHOD cl_gui_frontend_services=>directory_create
                EXPORTING
                  directory = lv_filedir
                CHANGING
                  rc        = lv_rc.
            ENDIF.

            IF lv_rc EQ 0 OR lv_direxist EQ 'X'.

              CALL METHOD cl_gui_frontend_services=>file_exist
                EXPORTING
                  file   = lv_contname
                RECEIVING
                  result = lv_fileexist.

              IF lv_fileexist NE 'X'.
                CALL METHOD cl_gui_frontend_services=>gui_download
                  EXPORTING
                    filename             = lv_contname
                    filetype             = 'BIN'
                    bin_filesize         = lv_pdfsize
                  CHANGING
                    data_tab             = lt_pdfdata[]
                  EXCEPTIONS
                    file_not_found       = 1
                    file_write_error     = 2
                    filesize_not_allowed = 3
                    invalid_type         = 5
                    no_batch             = 6
                    unknown_error        = 7
                    OTHERS               = 8.
              ENDIF.

              CALL METHOD cl_gui_frontend_services=>execute
                EXPORTING
                  document  = lv_contname
                  maximized = 'X'.

            ENDIF.

          ENDIF.
          CLEAR wa_cfdi.
        ELSEIF lv_prog EQ lc_prpago.
          SORT it_cfdi_pagos BY sociedad serie nodocu ejercicio ASCENDING.

          READ TABLE it_cfdi_pagos INDEX rs_selfield-tabindex INTO wa_cfdi_pagos.

          IF sy-subrc EQ 0.
            lv_pdfb64 = wa_cfdi_pagos-pdf.

            CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
              EXPORTING
                input  = lv_pdfb64
              IMPORTING
                output = lv_pdfxstr.

            CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
              EXPORTING
                buffer     = lv_pdfxstr
              TABLES
                binary_tab = lt_pdfdata.

            CALL METHOD cl_bcs_convert=>xstring_to_string
              EXPORTING
                iv_xstr   = lv_pdfxstr
                iv_cp     = 1100
              RECEIVING
                rv_string = lv_filepdf.

            lv_pdfsize = strlen( lv_filepdf ).

            CONCATENATE lv_filedir wa_cfdi_pagos-serie wa_cfdi_pagos-nodocu wa_cfdi_pagos-ejercicio '.pdf' INTO lv_contname.

            CALL METHOD cl_gui_frontend_services=>directory_exist
              EXPORTING
                directory = lv_filedir
              RECEIVING
                result    = lv_direxist.

            IF lv_direxist NE 'X'.
              CALL METHOD cl_gui_frontend_services=>directory_create
                EXPORTING
                  directory = lv_filedir
                CHANGING
                  rc        = lv_rc.
            ENDIF.

            IF lv_rc EQ 0 OR lv_direxist EQ 'X'.

              CALL METHOD cl_gui_frontend_services=>file_exist
                EXPORTING
                  file   = lv_contname
                RECEIVING
                  result = lv_fileexist.

              IF lv_fileexist NE 'X'.
                CALL METHOD cl_gui_frontend_services=>gui_download
                  EXPORTING
                    filename             = lv_contname
                    filetype             = 'BIN'
                    bin_filesize         = lv_pdfsize
                  CHANGING
                    data_tab             = lt_pdfdata[]
                  EXCEPTIONS
                    file_not_found       = 1
                    file_write_error     = 2
                    filesize_not_allowed = 3
                    invalid_type         = 5
                    no_batch             = 6
                    unknown_error        = 7
                    OTHERS               = 8.
              ENDIF.

              CALL METHOD cl_gui_frontend_services=>execute
                EXPORTING
                  document  = lv_contname
                  maximized = 'X'.

            ENDIF.

          ENDIF.
          CLEAR wa_cfdi_pagos.
        ELSEIF lv_prog EQ lc_prporte.
          SORT it_cfdi_porte BY serie notrans ASCENDING.

          READ TABLE it_cfdi_porte INDEX rs_selfield-tabindex INTO wa_cfdi_porte.

          IF sy-subrc EQ 0.
            lv_pdfb64 = wa_cfdi_porte-pdf.

            CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
              EXPORTING
                input  = lv_pdfb64
              IMPORTING
                output = lv_pdfxstr.

            CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
              EXPORTING
                buffer     = lv_pdfxstr
              TABLES
                binary_tab = lt_pdfdata.

            CALL METHOD cl_bcs_convert=>xstring_to_string
              EXPORTING
                iv_xstr   = lv_pdfxstr
                iv_cp     = 1100
              RECEIVING
                rv_string = lv_filepdf.

            lv_pdfsize = strlen( lv_filepdf ).

            CONCATENATE lv_filedir wa_cfdi_porte-serie wa_cfdi_porte-notrans '.pdf' INTO lv_contname.

            CALL METHOD cl_gui_frontend_services=>directory_exist
              EXPORTING
                directory = lv_filedir
              RECEIVING
                result    = lv_direxist.

            IF lv_direxist NE 'X'.
              CALL METHOD cl_gui_frontend_services=>directory_create
                EXPORTING
                  directory = lv_filedir
                CHANGING
                  rc        = lv_rc.
            ENDIF.

            IF lv_rc EQ 0 OR lv_direxist EQ 'X'.

              CALL METHOD cl_gui_frontend_services=>file_exist
                EXPORTING
                  file   = lv_contname
                RECEIVING
                  result = lv_fileexist.

              IF lv_fileexist NE 'X'.
                CALL METHOD cl_gui_frontend_services=>gui_download
                  EXPORTING
                    filename             = lv_contname
                    filetype             = 'BIN'
                    bin_filesize         = lv_pdfsize
                  CHANGING
                    data_tab             = lt_pdfdata[]
                  EXCEPTIONS
                    file_not_found       = 1
                    file_write_error     = 2
                    filesize_not_allowed = 3
                    invalid_type         = 5
                    no_batch             = 6
                    unknown_error        = 7
                    OTHERS               = 8.
              ENDIF.

              CALL METHOD cl_gui_frontend_services=>execute
                EXPORTING
                  document  = lv_contname
                  maximized = 'X'.

            ENDIF.

          ENDIF.
          CLEAR wa_cfdi_porte.
        ENDIF.

      ELSEIF rs_selfield-fieldname EQ 'XML'.
        IF lv_prog EQ lc_prinvo.
          SORT it_cfdi BY serie nodocu ASCENDING.

          READ TABLE it_cfdi INDEX rs_selfield-tabindex INTO wa_cfdi.

          IF sy-subrc EQ 0.
            lv_xmlb64 = wa_cfdi-xml.

            CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
              EXPORTING
                input  = lv_xmlb64
              IMPORTING
                output = lv_xmlxstr.

            CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
              EXPORTING
                buffer     = lv_xmlxstr
              TABLES
                binary_tab = lt_xmldata.

            CALL METHOD cl_bcs_convert=>xstring_to_string
              EXPORTING
                iv_xstr   = lv_xmlxstr
                iv_cp     = 1100
              RECEIVING
                rv_string = lv_filexml.

            lv_xmlsize = strlen( lv_filexml ).

            CONCATENATE lv_filedir wa_cfdi-serie wa_cfdi-nodocu '.xml' INTO lv_contname.

            CALL METHOD cl_gui_frontend_services=>directory_exist
              EXPORTING
                directory = lv_filedir
              RECEIVING
                result    = lv_direxist.

            IF lv_direxist NE 'X'.
              CALL METHOD cl_gui_frontend_services=>directory_create
                EXPORTING
                  directory = lv_filedir
                CHANGING
                  rc        = lv_rc.
            ENDIF.

            IF lv_rc EQ 0 OR lv_direxist EQ 'X'.

              CALL METHOD cl_gui_frontend_services=>file_exist
                EXPORTING
                  file   = lv_contname
                RECEIVING
                  result = lv_fileexist.

              IF lv_fileexist NE 'X'.
                CALL METHOD cl_gui_frontend_services=>gui_download
                  EXPORTING
                    filename             = lv_contname
                    filetype             = 'BIN'
                    bin_filesize         = lv_xmlsize
                  CHANGING
                    data_tab             = lt_xmldata[]
                  EXCEPTIONS
                    file_not_found       = 1
                    file_write_error     = 2
                    filesize_not_allowed = 3
                    invalid_type         = 5
                    no_batch             = 6
                    unknown_error        = 7
                    OTHERS               = 8.
              ENDIF.

              CALL METHOD cl_gui_frontend_services=>execute
                EXPORTING
                  document  = lv_contname
                  maximized = 'X'.

            ENDIF.

          ENDIF.
          CLEAR wa_cfdi.
        ELSEIF lv_prog EQ lc_prpago.
          SORT it_cfdi_pagos BY serie nodocu ASCENDING.

          READ TABLE it_cfdi_pagos INDEX rs_selfield-tabindex INTO wa_cfdi_pagos.

          IF sy-subrc EQ 0.
            lv_xmlb64 = wa_cfdi_pagos-xml.

            CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
              EXPORTING
                input  = lv_xmlb64
              IMPORTING
                output = lv_xmlxstr.

            CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
              EXPORTING
                buffer     = lv_xmlxstr
              TABLES
                binary_tab = lt_xmldata.

            CALL METHOD cl_bcs_convert=>xstring_to_string
              EXPORTING
                iv_xstr   = lv_xmlxstr
                iv_cp     = 1100
              RECEIVING
                rv_string = lv_filexml.

            lv_xmlsize = strlen( lv_filexml ).

            CONCATENATE lv_filedir wa_cfdi_pagos-serie wa_cfdi_pagos-nodocu wa_cfdi_pagos-ejercicio '.xml' INTO lv_contname.

            CALL METHOD cl_gui_frontend_services=>directory_exist
              EXPORTING
                directory = lv_filedir
              RECEIVING
                result    = lv_direxist.

            IF lv_direxist NE 'X'.
              CALL METHOD cl_gui_frontend_services=>directory_create
                EXPORTING
                  directory = lv_filedir
                CHANGING
                  rc        = lv_rc.
            ENDIF.

            IF lv_rc EQ 0 OR lv_direxist EQ 'X'.

              CALL METHOD cl_gui_frontend_services=>file_exist
                EXPORTING
                  file   = lv_contname
                RECEIVING
                  result = lv_fileexist.

              IF lv_fileexist NE 'X'.
                CALL METHOD cl_gui_frontend_services=>gui_download
                  EXPORTING
                    filename             = lv_contname
                    filetype             = 'BIN'
                    bin_filesize         = lv_xmlsize
                  CHANGING
                    data_tab             = lt_xmldata[]
                  EXCEPTIONS
                    file_not_found       = 1
                    file_write_error     = 2
                    filesize_not_allowed = 3
                    invalid_type         = 5
                    no_batch             = 6
                    unknown_error        = 7
                    OTHERS               = 8.
              ENDIF.

              CALL METHOD cl_gui_frontend_services=>execute
                EXPORTING
                  document  = lv_contname
                  maximized = 'X'.

            ENDIF.

          ENDIF.
          CLEAR wa_cfdi_pagos.
        ELSEIF lv_prog EQ lc_prporte.
          SORT it_cfdi_porte BY serie notrans ASCENDING.

          READ TABLE it_cfdi_porte INDEX rs_selfield-tabindex INTO wa_cfdi_porte.

          IF sy-subrc EQ 0.
            lv_xmlb64 = wa_cfdi_porte-xml.

            CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
              EXPORTING
                input  = lv_xmlb64
              IMPORTING
                output = lv_xmlxstr.

            CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
              EXPORTING
                buffer     = lv_xmlxstr
              TABLES
                binary_tab = lt_xmldata.

            CALL METHOD cl_bcs_convert=>xstring_to_string
              EXPORTING
                iv_xstr   = lv_xmlxstr
                iv_cp     = 1100
              RECEIVING
                rv_string = lv_filexml.

            lv_xmlsize = strlen( lv_filexml ).

            CONCATENATE lv_filedir wa_cfdi_porte-serie wa_cfdi_porte-notrans '.xml' INTO lv_contname.

            CALL METHOD cl_gui_frontend_services=>directory_exist
              EXPORTING
                directory = lv_filedir
              RECEIVING
                result    = lv_direxist.

            IF lv_direxist NE 'X'.
              CALL METHOD cl_gui_frontend_services=>directory_create
                EXPORTING
                  directory = lv_filedir
                CHANGING
                  rc        = lv_rc.
            ENDIF.

            IF lv_rc EQ 0 OR lv_direxist EQ 'X'.

              CALL METHOD cl_gui_frontend_services=>file_exist
                EXPORTING
                  file   = lv_contname
                RECEIVING
                  result = lv_fileexist.

              IF lv_fileexist NE 'X'.
                CALL METHOD cl_gui_frontend_services=>gui_download
                  EXPORTING
                    filename             = lv_contname
                    filetype             = 'BIN'
                    bin_filesize         = lv_xmlsize
                  CHANGING
                    data_tab             = lt_xmldata[]
                  EXCEPTIONS
                    file_not_found       = 1
                    file_write_error     = 2
                    filesize_not_allowed = 3
                    invalid_type         = 5
                    no_batch             = 6
                    unknown_error        = 7
                    OTHERS               = 8.
              ENDIF.

              CALL METHOD cl_gui_frontend_services=>execute
                EXPORTING
                  document  = lv_contname
                  maximized = 'X'.

            ENDIF.

          ENDIF.
          CLEAR wa_cfdi_porte.
        ENDIF.
      ELSEIF rs_selfield-fieldname EQ 'EMAIL'.
        DATA: lo_bcs         TYPE REF TO cl_bcs,
              lo_doc_bcs     TYPE REF TO cl_document_bcs,
              lo_recep       TYPE REF TO if_recipient_bcs,
              lo_sapuser_bcs TYPE REF TO cl_sapuser_bcs,
              lo_cx_bcx      TYPE REF TO cx_bcs.

        DATA: lt_otfdata        TYPE ssfcrescl,
              lt_binary_content TYPE solix_tab,
              lt_text           TYPE bcsy_text,
              lt_pdf_tab        TYPE STANDARD TABLE OF tline,
              lt_otf            TYPE STANDARD TABLE OF itcoo.

        DATA: ls_ctrlop TYPE ssfctrlop,
              ls_outopt TYPE ssfcompop.

        DATA: lv_bin_filesize TYPE so_obj_len,
              lv_sent_to_all  TYPE os_boolean,
              lv_bin_xstr     TYPE xstring,
              lv_fname        TYPE rs38l_fnam,
              lv_string_text  TYPE string,
              lv_xmlsize2     TYPE sood-objlen,
              lv_pdfsize2     TYPE sood-objlen,
              lv_pdfatt       TYPE sood-objdes,
              lv_xmlatt       TYPE sood-objdes,
              lv_subject      TYPE so_obj_des,
              lv_recipient    TYPE adr6-smtp_addr.

        IF lv_prog EQ lc_prinvo.

          SORT it_cfdi BY serie nodocu ASCENDING.

          READ TABLE it_cfdi INDEX rs_selfield-tabindex INTO wa_cfdi.

          IF sy-subrc EQ 0.
            lv_pdfb64 = wa_cfdi-pdf.
            lv_xmlb64 = wa_cfdi-xml.

            CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
              EXPORTING
                input  = lv_pdfb64
              IMPORTING
                output = lv_pdfxstr.

            CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
              EXPORTING
                buffer     = lv_pdfxstr
              TABLES
                binary_tab = lt_pdfdata.

            CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
              EXPORTING
                input  = lv_xmlb64
              IMPORTING
                output = lv_xmlxstr.

            CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
              EXPORTING
                buffer     = lv_xmlxstr
              TABLES
                binary_tab = lt_xmldata.

            CALL METHOD cl_bcs_convert=>xstring_to_string
              EXPORTING
                iv_xstr   = lv_xmlxstr
                iv_cp     = 1100
              RECEIVING
                rv_string = lv_filexml.

            lv_xmlsize = strlen( lv_filexml ).
            MOVE lv_xmlsize TO lv_xmlsize2.

            CALL METHOD cl_bcs_convert=>xstring_to_string
              EXPORTING
                iv_xstr   = lv_pdfxstr
                iv_cp     = 1100
              RECEIVING
                rv_string = lv_filepdf.

            lv_pdfsize = strlen( lv_filepdf ).
            MOVE lv_pdfsize TO lv_pdfsize2.

            TRY.
                lo_bcs = cl_bcs=>create_persistent( ).

                CONCATENATE 'Buen día,' cl_abap_char_utilities=>newline INTO lv_string_text.
                APPEND lv_string_text TO lt_text.
                CLEAR lv_string_text.

                CONCATENATE 'Se envían los archivos PDF y XML de la factura' wa_cfdi-serie wa_cfdi-nodocu 'como datos adjuntos.' cl_abap_char_utilities=>newline INTO lv_string_text SEPARATED BY space.
                APPEND lv_string_text TO lt_text.
                CLEAR lv_string_text.

                CONCATENATE 'Saludos cordiales.' cl_abap_char_utilities=>newline INTO lv_string_text.
                APPEND lv_string_text TO lt_text.
                CLEAR lv_string_text.

                CONCATENATE 'Envío de factura' wa_cfdi-serie wa_cfdi-nodocu INTO lv_subject SEPARATED BY space.

                lo_doc_bcs = cl_document_bcs=>create_document(
                  i_type    = 'RAW'
                  i_text    = lt_text[]
                  i_length  = '12'
                  i_subject = lv_subject ).

                CONCATENATE wa_cfdi-serie wa_cfdi-nodocu INTO lv_pdfatt.
                CONCATENATE wa_cfdi-serie wa_cfdi-nodocu INTO lv_xmlatt.

                CALL METHOD lo_doc_bcs->add_attachment
                  EXPORTING
                    i_attachment_type    = 'PDF'
                    i_attachment_subject = lv_pdfatt
                    i_att_content_hex    = lt_pdfdata
                    i_attachment_size    = lv_pdfsize2.

                CALL METHOD lo_bcs->set_document( lo_doc_bcs ).

                CALL METHOD lo_doc_bcs->add_attachment
                  EXPORTING
                    i_attachment_type    = 'XML'
                    i_attachment_subject = lv_xmlatt
                    i_att_content_hex    = lt_xmldata
                    i_attachment_size    = lv_xmlsize2.

                CALL METHOD lo_bcs->set_document( lo_doc_bcs ).

*-----------------------------------------------------------------------
*Coloca Emisor de correo. Si no se coloca, se toma el valor de sy-uname-
*-----------------------------------------------------------------------
*    lo_sapuser_bcs = cl_sapuser_bcs=>create( sy-uname ).
*    CALL METHOD lo_bcs->set_sender
*      EXPORTING
*        i_sender = lo_sapuser_bcs.

                SELECT SINGLE smtp_addr INTO lv_recipient
                  FROM adr6 AS a
                  INNER JOIN usr21 AS b ON a~addrnumber EQ b~addrnumber
                  AND a~persnumber EQ b~persnumber
                WHERE bname = sy-uname.

                lo_recep = cl_cam_address_bcs=>create_internet_address( lv_recipient ).

                CALL METHOD lo_bcs->add_recipient
                  EXPORTING
                    i_recipient = lo_recep
                    i_express   = 'X'.

                CALL METHOD lo_bcs->set_send_immediately
                  EXPORTING
                    i_send_immediately = 'X'.

                CALL METHOD lo_bcs->send(
                  EXPORTING
                    i_with_error_screen = 'X'
                  RECEIVING
                    result              = lv_sent_to_all ).

                IF lv_sent_to_all IS NOT INITIAL.
                  COMMIT WORK.
                ENDIF.

              CATCH cx_bcs INTO lo_cx_bcx.
            ENDTRY.
          ENDIF.
          CLEAR wa_cfdi.

        ELSEIF lv_prog EQ lc_prpago.
          SORT it_cfdi_pagos BY sociedad serie nodocu ejercicio ASCENDING.

          READ TABLE it_cfdi_pagos INDEX rs_selfield-tabindex INTO wa_cfdi_pagos.

          IF sy-subrc EQ 0.
            lv_pdfb64 = wa_cfdi_pagos-pdf.
            lv_xmlb64 = wa_cfdi_pagos-xml.

            CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
              EXPORTING
                input  = lv_pdfb64
              IMPORTING
                output = lv_pdfxstr.

            CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
              EXPORTING
                buffer     = lv_pdfxstr
              TABLES
                binary_tab = lt_pdfdata.

            CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
              EXPORTING
                input  = lv_xmlb64
              IMPORTING
                output = lv_xmlxstr.

            CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
              EXPORTING
                buffer     = lv_xmlxstr
              TABLES
                binary_tab = lt_xmldata.

            CALL METHOD cl_bcs_convert=>xstring_to_string
              EXPORTING
                iv_xstr   = lv_xmlxstr
                iv_cp     = 1100
              RECEIVING
                rv_string = lv_filexml.

            lv_xmlsize = strlen( lv_filexml ).
            MOVE lv_xmlsize TO lv_xmlsize2.

            CALL METHOD cl_bcs_convert=>xstring_to_string
              EXPORTING
                iv_xstr   = lv_pdfxstr
                iv_cp     = 1100
              RECEIVING
                rv_string = lv_filepdf.

            lv_pdfsize = strlen( lv_filepdf ).
            MOVE lv_pdfsize TO lv_pdfsize2.

            TRY.
                lo_bcs = cl_bcs=>create_persistent( ).

                CONCATENATE 'Buen día,' cl_abap_char_utilities=>newline INTO lv_string_text.
                APPEND lv_string_text TO lt_text.
                CLEAR lv_string_text.

                CONCATENATE 'Se envían los archivos PDF y XML del complemento de pago' wa_cfdi_pagos-serie wa_cfdi_pagos-nodocu wa_cfdi_pagos-ejercicio 'como datos adjuntos.' cl_abap_char_utilities=>newline INTO lv_string_text SEPARATED BY space.
                APPEND lv_string_text TO lt_text.
                CLEAR lv_string_text.

                CONCATENATE 'Saludos cordiales.' cl_abap_char_utilities=>newline INTO lv_string_text.
                APPEND lv_string_text TO lt_text.
                CLEAR lv_string_text.

                CONCATENATE 'Envío de complemento de pago' wa_cfdi_pagos-serie wa_cfdi_pagos-nodocu wa_cfdi_pagos-ejercicio INTO lv_subject SEPARATED BY space.

                lo_doc_bcs = cl_document_bcs=>create_document(
                  i_type    = 'RAW'
                  i_text    = lt_text[]
                  i_length  = '12'
                  i_subject = lv_subject ).

                CONCATENATE wa_cfdi_pagos-serie wa_cfdi_pagos-nodocu wa_cfdi_pagos-ejercicio INTO lv_pdfatt.
                CONCATENATE wa_cfdi_pagos-serie wa_cfdi_pagos-nodocu wa_cfdi_pagos-ejercicio INTO lv_xmlatt.

                CALL METHOD lo_doc_bcs->add_attachment
                  EXPORTING
                    i_attachment_type    = 'PDF'
                    i_attachment_subject = lv_pdfatt
                    i_att_content_hex    = lt_pdfdata
                    i_attachment_size    = lv_pdfsize2.

                CALL METHOD lo_bcs->set_document( lo_doc_bcs ).

                CALL METHOD lo_doc_bcs->add_attachment
                  EXPORTING
                    i_attachment_type    = 'XML'
                    i_attachment_subject = lv_xmlatt
                    i_att_content_hex    = lt_xmldata
                    i_attachment_size    = lv_xmlsize2.

                CALL METHOD lo_bcs->set_document( lo_doc_bcs ).

*-----------------------------------------------------------------------
*Coloca Emisor de correo. Si no se coloca, se toma el valor de sy-uname-
*-----------------------------------------------------------------------
*    lo_sapuser_bcs = cl_sapuser_bcs=>create( sy-uname ).
*    CALL METHOD lo_bcs->set_sender
*      EXPORTING
*        i_sender = lo_sapuser_bcs.

                SELECT SINGLE smtp_addr INTO lv_recipient
                  FROM adr6 AS a
                  INNER JOIN usr21 AS b ON a~addrnumber EQ b~addrnumber
                  AND a~persnumber EQ b~persnumber
                WHERE bname = sy-uname.

                lo_recep = cl_cam_address_bcs=>create_internet_address( lv_recipient ).

                CALL METHOD lo_bcs->add_recipient
                  EXPORTING
                    i_recipient = lo_recep
                    i_express   = 'X'.

                CALL METHOD lo_bcs->set_send_immediately
                  EXPORTING
                    i_send_immediately = 'X'.

                CALL METHOD lo_bcs->send(
                  EXPORTING
                    i_with_error_screen = 'X'
                  RECEIVING
                    result              = lv_sent_to_all ).

                IF lv_sent_to_all IS NOT INITIAL.
                  COMMIT WORK.
                ENDIF.

              CATCH cx_bcs INTO lo_cx_bcx.
            ENDTRY.
          ENDIF.
          CLEAR wa_cfdi_pagos.
        ELSEIF lv_prog EQ lc_prporte.
          SORT it_cfdi_porte BY serie notrans ASCENDING.

          READ TABLE it_cfdi_porte INDEX rs_selfield-tabindex INTO wa_cfdi_porte.

          IF sy-subrc EQ 0.
            lv_pdfb64 = wa_cfdi_porte-pdf.
            lv_xmlb64 = wa_cfdi_porte-xml.

            CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
              EXPORTING
                input  = lv_pdfb64
              IMPORTING
                output = lv_pdfxstr.

            CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
              EXPORTING
                buffer     = lv_pdfxstr
              TABLES
                binary_tab = lt_pdfdata.

            CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
              EXPORTING
                input  = lv_xmlb64
              IMPORTING
                output = lv_xmlxstr.

            CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
              EXPORTING
                buffer     = lv_xmlxstr
              TABLES
                binary_tab = lt_xmldata.

            CALL METHOD cl_bcs_convert=>xstring_to_string
              EXPORTING
                iv_xstr   = lv_xmlxstr
                iv_cp     = 1100
              RECEIVING
                rv_string = lv_filexml.

            lv_xmlsize = strlen( lv_filexml ).
            MOVE lv_xmlsize TO lv_xmlsize2.

            CALL METHOD cl_bcs_convert=>xstring_to_string
              EXPORTING
                iv_xstr   = lv_pdfxstr
                iv_cp     = 1100
              RECEIVING
                rv_string = lv_filepdf.

            lv_pdfsize = strlen( lv_filepdf ).
            MOVE lv_pdfsize TO lv_pdfsize2.

            TRY.
                lo_bcs = cl_bcs=>create_persistent( ).

                CONCATENATE 'Buen día,' cl_abap_char_utilities=>newline INTO lv_string_text.
                APPEND lv_string_text TO lt_text.
                CLEAR lv_string_text.

                CONCATENATE 'Se envían los archivos PDF y XML del CFDI de traslado' wa_cfdi_porte-serie wa_cfdi_porte-notrans 'como datos adjuntos.' cl_abap_char_utilities=>newline INTO lv_string_text SEPARATED BY space.
                APPEND lv_string_text TO lt_text.
                CLEAR lv_string_text.

                CONCATENATE 'Saludos cordiales.' cl_abap_char_utilities=>newline INTO lv_string_text.
                APPEND lv_string_text TO lt_text.
                CLEAR lv_string_text.

                CONCATENATE 'Envío de CFDI de traslado' wa_cfdi_porte-serie wa_cfdi_porte-notrans INTO lv_subject SEPARATED BY space.

                lo_doc_bcs = cl_document_bcs=>create_document(
                  i_type    = 'RAW'
                  i_text    = lt_text[]
                  i_length  = '12'
                  i_subject = lv_subject ).

                CONCATENATE wa_cfdi_porte-serie wa_cfdi_porte-notrans INTO lv_pdfatt.
                CONCATENATE wa_cfdi_porte-serie wa_cfdi_porte-notrans INTO lv_xmlatt.

                CALL METHOD lo_doc_bcs->add_attachment
                  EXPORTING
                    i_attachment_type    = 'PDF'
                    i_attachment_subject = lv_pdfatt
                    i_att_content_hex    = lt_pdfdata
                    i_attachment_size    = lv_pdfsize2.

                CALL METHOD lo_bcs->set_document( lo_doc_bcs ).

                CALL METHOD lo_doc_bcs->add_attachment
                  EXPORTING
                    i_attachment_type    = 'XML'
                    i_attachment_subject = lv_xmlatt
                    i_att_content_hex    = lt_xmldata
                    i_attachment_size    = lv_xmlsize2.

                CALL METHOD lo_bcs->set_document( lo_doc_bcs ).

*-----------------------------------------------------------------------
*Coloca Emisor de correo. Si no se coloca, se toma el valor de sy-uname-
*-----------------------------------------------------------------------
*    lo_sapuser_bcs = cl_sapuser_bcs=>create( sy-uname ).
*    CALL METHOD lo_bcs->set_sender
*      EXPORTING
*        i_sender = lo_sapuser_bcs.

                SELECT SINGLE smtp_addr INTO lv_recipient
                  FROM adr6 AS a
                  INNER JOIN usr21 AS b ON a~addrnumber EQ b~addrnumber
                  AND a~persnumber EQ b~persnumber
                WHERE bname = sy-uname.

                lo_recep = cl_cam_address_bcs=>create_internet_address( lv_recipient ).

                CALL METHOD lo_bcs->add_recipient
                  EXPORTING
                    i_recipient = lo_recep
                    i_express   = 'X'.

                CALL METHOD lo_bcs->set_send_immediately
                  EXPORTING
                    i_send_immediately = 'X'.

                CALL METHOD lo_bcs->send(
                  EXPORTING
                    i_with_error_screen = 'X'
                  RECEIVING
                    result              = lv_sent_to_all ).

                IF lv_sent_to_all IS NOT INITIAL.
                  COMMIT WORK.
                ENDIF.

              CATCH cx_bcs INTO lo_cx_bcx.
            ENDTRY.
          ENDIF.
          CLEAR wa_cfdi_porte.
        ENDIF.
      ENDIF.
    WHEN gc_refresh.
      PERFORM data_retrivel.             " Refresh data
      rs_selfield-refresh    = c_x.
      rs_selfield-col_stable = c_x.
      rs_selfield-row_stable = c_x.
    WHEN OTHERS.
      RETURN.
  ENDCASE.
ENDFORM.                    " USER_COMMAND

*&---------------------------------------------------------------------*
*&      Form  PF_STATUS_SET
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM pf_status_set USING ut_extab TYPE slis_t_extab.        "#EC CALLED

  DELETE ut_extab WHERE fcode = gc_refresh.

  SET PF-STATUS 'STANDARD_FULLSCREEN' OF PROGRAM 'SAPLKKBL'
      EXCLUDING ut_extab.

ENDFORM.                    "pf_status_set
