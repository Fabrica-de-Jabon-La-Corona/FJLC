*&---------------------------------------------------------------------*
*& Report ZSD_FACTDETALLE_ALV
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zsd_factdetalle_alv.

TABLES : vbrp, vbrk, tvgrt, knvv.
TYPE-POOLS : slis.

**Declaración de tablas internas
DATA : it_vbrp  TYPE STANDARD TABLE OF vbrp,
       wa_vbrk  TYPE vbrk,
       it_vbrk  TYPE STANDARD TABLE OF vbrk,
       wa_kna1  TYPE kna1,
       it_kna1  TYPE STANDARD TABLE OF kna1,
       wa_makt  TYPE makt,
       it_makt  TYPE STANDARD TABLE OF makt,
       wa_tvgrt TYPE tvgrt,
       it_tvgrt TYPE STANDARD TABLE OF tvgrt,
       wa_bsid  TYPE bsid_view,
       it_bsid  TYPE STANDARD TABLE OF bsid_view,
       wa_bsad  TYPE bsad_view,
       it_bsad  TYPE STANDARD TABLE OF bsad_view.

**Declaración de datos
DATA: fieldcatalog TYPE slis_t_fieldcat_alv WITH HEADER LINE,
      gd_layout    TYPE slis_layout_alv,
      gd_repid     LIKE sy-repid,
      g_save       TYPE c VALUE 'X',
      g_variant    TYPE disvariant,
      gx_variant   TYPE disvariant,
      g_exit       TYPE c,
      lv_prog      TYPE c LENGTH 19,
      lv_lines     TYPE i.

**Declaración de constantes
CONSTANTS: gc_refresh TYPE syucomm VALUE '&REFRESH',
           c_x        TYPE c LENGTH 1 VALUE 'X'.

**Parámetros de selección
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-002 .

  SELECT-OPTIONS: p_fecha  FOR vbrk-fkdat OBLIGATORY,
                  p_agente FOR tvgrt-vkgrp,
                  p_cadena FOR knvv-kvgr1,
                  p_zonav  FOR knvv-bzirk,
                  p_client FOR vbrk-kunag.

SELECTION-SCREEN END OF BLOCK b1.

**Declaración de estructura final
DATA:
  BEGIN OF tt_factudet  OCCURS 0,
    fecfact    TYPE fkdat,
    factura    TYPE vbeln,
    uuid       TYPE zsd_cfdi_return-uuid,
    cliente    TYPE kunnr,
    nombrecte  TYPE maktx,
    pais       TYPE land1,
    canal      TYPE vtweg,
    agente     TYPE vkgrp,
    nombreage  TYPE bezei,
    zonavta    TYPE bzirk,
    cadena     TYPE kvgr1,
    oficinavta TYPE vkbur,
    material   TYPE matnr,
    descrip    TYPE maktx,
    cantidad   TYPE fkimg,
    unimed     TYPE vrkme,
    pesoneto   TYPE ntgew,
    pesobruto  TYPE brgew,
    unipeso    TYPE gewei,
    importe    TYPE netwr,
    moneda     TYPE waerk,
    tipocam    TYPE kursk,
    fecpago    TYPE cpudt,
    saldo      TYPE wrbtr,
    importeml  TYPE wrbtr,
    cenben     TYPE prctr,
    indimp     TYPE vbrp-mwsk1,
    tasa       TYPE kbetr,
    impimpue   TYPE kwert,
  END OF tt_factudet.
DATA:
  ts_factudet  LIKE tt_factudet.

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

  fieldcatalog-fieldname   = 'FECFACT'.
  fieldcatalog-seltext_m   = 'Fecha Factura'.
  fieldcatalog-col_pos     = 0.
  fieldcatalog-outputlen   = 10.
  fieldcatalog-key         = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'FACTURA'.
  fieldcatalog-seltext_m   = 'Factura'.
  fieldcatalog-col_pos     = 1.
  fieldcatalog-outputlen   = 10.
  fieldcatalog-key         = 'X'.
  fieldcatalog-hotspot     = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'UUID'.
  fieldcatalog-seltext_m   = 'Folio Fiscal'.
  fieldcatalog-col_pos     = 2.
  fieldcatalog-outputlen   = 40.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'CLIENTE'.
  fieldcatalog-seltext_m   = 'Cliente'.
  fieldcatalog-col_pos     = 3.
  fieldcatalog-outputlen   = 10.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'NOMBRECTE'.
  fieldcatalog-seltext_m   = 'Nombre Cliente'.
  fieldcatalog-col_pos     = 4.
  fieldcatalog-outputlen   = 40.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'PAIS'.
  fieldcatalog-seltext_m   = 'País'.
  fieldcatalog-col_pos     = 5.
  fieldcatalog-outputlen   = 4.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'CANAL'.
  fieldcatalog-seltext_m   = 'Canal'.
  fieldcatalog-col_pos     = 6.
  fieldcatalog-outputlen   = 2.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'AGENTE'.
  fieldcatalog-seltext_m   = 'Agente'.
  fieldcatalog-col_pos     = 7.
  fieldcatalog-outputlen   = 3.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'NOMBREAGE'.
  fieldcatalog-seltext_m   = 'Nombre Agente'.
  fieldcatalog-col_pos     = 8.
  fieldcatalog-outputlen   = 20.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'ZONAVTA'.
  fieldcatalog-seltext_m   = 'Zona de Ventas'.
  fieldcatalog-col_pos     = 9.
  fieldcatalog-outputlen   = 6.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'CADENA'.
  fieldcatalog-seltext_m   = 'Cadena'.
  fieldcatalog-col_pos     = 10.
  fieldcatalog-outputlen   = 3.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'OFICINAVTA'.
  fieldcatalog-seltext_m   = 'Oficina de Ventas'.
  fieldcatalog-col_pos     = 11.
  fieldcatalog-outputlen   = 4.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'MATERIAL'.
  fieldcatalog-seltext_m   = 'Material'.
  fieldcatalog-col_pos     = 12.
  fieldcatalog-outputlen   = 18.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'DESCRIP'.
  fieldcatalog-seltext_m   = 'Descripción'.
  fieldcatalog-col_pos     = 13.
  fieldcatalog-outputlen   = 40.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'CANTIDAD'.
  fieldcatalog-seltext_m   = 'Cantidad'.
  fieldcatalog-col_pos     = 14.
  fieldcatalog-outputlen   = 20.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'UNIMED'.
  fieldcatalog-seltext_m   = 'UMV'.
  fieldcatalog-col_pos     = 15.
  fieldcatalog-outputlen   = 3.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'PESONETO'.
  fieldcatalog-seltext_m   = 'Peso Neto'.
  fieldcatalog-col_pos     = 16.
  fieldcatalog-outputlen   = 20.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'PESOBRUTO'.
  fieldcatalog-seltext_m   = 'Peso Bruto'.
  fieldcatalog-col_pos     = 17.
  fieldcatalog-outputlen   = 20.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'UNIPESO'.
  fieldcatalog-seltext_m   = 'Uni. Peso'.
  fieldcatalog-col_pos     = 18.
  fieldcatalog-outputlen   = 3.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'IMPORTE'.
  fieldcatalog-seltext_m   = 'Importe'.
  fieldcatalog-col_pos     = 19.
  fieldcatalog-outputlen   = 20.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'MONEDA'.
  fieldcatalog-seltext_m   = 'Moneda'.
  fieldcatalog-col_pos     = 20.
  fieldcatalog-outputlen   = 3.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'TIPOCAM'.
  fieldcatalog-seltext_m   = 'Tipo de Cambio'.
  fieldcatalog-col_pos     = 21.
  fieldcatalog-outputlen   = 10.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'IMPORTEML'.
  fieldcatalog-seltext_m   = 'Importe ML Venta'.
  fieldcatalog-col_pos     = 22.
  fieldcatalog-outputlen   = 20.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'FECPAGO'.
  fieldcatalog-seltext_m   = 'Fecha de Pago'.
  fieldcatalog-col_pos     = 23.
  fieldcatalog-outputlen   = 10.
  fieldcatalog-no_out      = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'SALDO'.
  fieldcatalog-seltext_m   = 'Saldo'.
  fieldcatalog-col_pos     = 24.
  fieldcatalog-outputlen   = 20.
  fieldcatalog-no_out      = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'CENBEN'.
  fieldcatalog-seltext_m   = 'Centro Beneficio'.
  fieldcatalog-col_pos     = 25.
  fieldcatalog-outputlen   = 10.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'INDIMP'.
  fieldcatalog-seltext_m   = 'Indicador de Impuesto'.
  fieldcatalog-col_pos     = 26.
  fieldcatalog-outputlen   = 3.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'TASA'.
  fieldcatalog-seltext_m   = 'Tasa'.
  fieldcatalog-col_pos     = 27.
  fieldcatalog-outputlen   = 6.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'IMPIMPUE'.
  fieldcatalog-seltext_m   = 'Impuesto'.
  fieldcatalog-col_pos     = 28.
  fieldcatalog-outputlen   = 6.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

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
      t_outtab                 = tt_factudet
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
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

  DATA:
    BEGIN OF tt_facturas  OCCURS 0,
      factura TYPE vbeln,
    END OF tt_facturas.
  DATA:
    ts_facturas  LIKE tt_facturas.

  DATA: lv_flag1     TYPE c LENGTH 1,
        lv_facrefer  TYPE vbeln,
        lv_facrefer1 TYPE vbeln,
        lv_pagos     TYPE wrbtr.

  DATA: it_tvkgr TYPE STANDARD TABLE OF tvkgr,
        wa_tvkgr TYPE tvkgr,
        it_t171  TYPE STANDARD TABLE OF t171,
        wa_t171  TYPE t171,
        it_tvv1  TYPE STANDARD TABLE OF tvv1,
        wa_tvv1  TYPE tvv1,
        it_prcd  TYPE STANDARD TABLE OF prcd_elements,
        wa_prcd  TYPE prcd_elements,
        it_cfdi  TYPE STANDARD TABLE OF zsd_cfdi_return,
        wa_cfdi  TYPE zsd_cfdi_return.

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

  "Selección de facturas tomando en cuenta los parámetros de selección introducidos por el usuario y sus posibles combinaciones
  IF p_agente EQ '' AND p_cadena EQ '' AND p_zonav EQ '' AND p_client EQ ''.
    SELECT vbeln FROM vbrk
      WHERE fkdat IN @p_fecha
      AND fksto EQ ''
      AND vbtyp EQ 'M'
      AND belnr NE ''
      INTO TABLE @tt_facturas.
  ELSEIF p_agente NE '' AND p_cadena EQ '' AND p_zonav EQ '' AND p_client EQ ''.
    SELECT a~vbeln FROM vbrk AS a
      INNER JOIN vbrp AS b ON b~vbeln EQ a~vbeln
      WHERE a~fkdat IN @p_fecha
      AND b~vkgrp IN @p_agente
      AND a~fksto EQ ''
      AND a~vbtyp EQ 'M'
      AND a~belnr NE ''
      INTO TABLE @tt_facturas.
  ELSEIF p_agente EQ '' AND p_cadena NE '' AND p_zonav EQ '' AND p_client EQ ''.
    SELECT a~vbeln FROM vbrk AS a
      INNER JOIN vbrp AS b ON b~vbeln EQ a~vbeln
      WHERE a~fkdat IN @p_fecha
      AND b~kvgr1 IN @p_cadena
      AND a~fksto EQ ''
      AND a~vbtyp EQ 'M'
      AND a~belnr NE ''
      INTO TABLE @tt_facturas.
  ELSEIF p_agente EQ '' AND p_cadena EQ '' AND p_zonav NE '' AND p_client EQ ''.
    SELECT vbeln FROM vbrk
      WHERE fkdat IN @p_fecha
      AND bzirk IN @p_zonav
      AND fksto EQ ''
      AND vbtyp EQ 'M'
      AND belnr NE ''
      INTO TABLE @tt_facturas.
  ELSEIF p_agente EQ '' AND p_cadena EQ '' AND p_zonav EQ '' AND p_client NE ''.
    SELECT vbeln FROM vbrk
      WHERE fkdat IN @p_fecha
      AND kunrg IN @p_client
      AND fksto EQ ''
      AND vbtyp EQ 'M'
      AND belnr NE ''
      INTO TABLE @tt_facturas.
  ELSEIF p_agente NE '' AND p_cadena NE '' AND p_zonav EQ '' AND p_client EQ ''.
    SELECT a~vbeln FROM vbrk AS a
      INNER JOIN vbrp AS b ON b~vbeln EQ a~vbeln
      WHERE a~fkdat IN @p_fecha
      AND b~vkgrp IN @p_agente
      AND b~kvgr1 IN @p_cadena
      AND a~fksto EQ ''
      AND a~vbtyp EQ 'M'
      AND a~belnr NE ''
      INTO TABLE @tt_facturas.
  ELSEIF p_agente EQ '' AND p_cadena EQ '' AND p_zonav NE '' AND p_client NE ''.
    SELECT vbeln FROM vbrk
      WHERE fkdat IN @p_fecha
      AND bzirk IN @p_zonav
      AND kunrg IN @p_client
      AND fksto EQ ''
      AND vbtyp EQ 'M'
      AND belnr NE ''
      INTO TABLE @tt_facturas.
  ELSEIF p_agente NE '' AND p_cadena EQ '' AND p_zonav NE '' AND p_client EQ ''.
    SELECT a~vbeln FROM vbrk AS a
      INNER JOIN vbrp AS b ON b~vbeln EQ a~vbeln
      WHERE a~fkdat IN @p_fecha
      AND b~vkgrp IN @p_agente
      AND a~bzirk IN @p_zonav
      AND a~fksto EQ ''
      AND a~vbtyp EQ 'M'
      AND a~belnr NE ''
      INTO TABLE @tt_facturas.
  ELSEIF p_agente EQ '' AND p_cadena NE '' AND p_zonav EQ '' AND p_client NE ''.
    SELECT a~vbeln FROM vbrk AS a
      INNER JOIN vbrp AS b ON b~vbeln EQ a~vbeln
      WHERE a~fkdat IN @p_fecha
      AND a~kunrg IN @p_client
      AND b~kvgr1 IN @p_cadena
      AND a~fksto EQ ''
      AND a~vbtyp EQ 'M'
      AND a~belnr NE ''
      INTO TABLE @tt_facturas.
  ELSEIF p_agente NE '' AND p_cadena EQ '' AND p_zonav EQ '' AND p_client NE ''.
    SELECT a~vbeln FROM vbrk AS a
      INNER JOIN vbrp AS b ON b~vbeln EQ a~vbeln
      WHERE a~fkdat IN @p_fecha
      AND a~kunrg IN @p_client
      AND b~vkgrp IN @p_agente
      AND a~fksto EQ ''
      AND a~vbtyp EQ 'M'
      AND a~belnr NE ''
      INTO TABLE @tt_facturas.
  ELSEIF p_agente EQ '' AND p_cadena NE '' AND p_zonav NE '' AND p_client EQ ''.
    SELECT a~vbeln FROM vbrk AS a
      INNER JOIN vbrp AS b ON b~vbeln EQ a~vbeln
      WHERE a~fkdat IN @p_fecha
      AND a~bzirk IN @p_zonav
      AND b~kvgr1 IN @p_cadena
      AND a~fksto EQ ''
      AND a~vbtyp EQ 'M'
      AND a~belnr NE ''
      INTO TABLE @tt_facturas.
  ELSEIF p_agente EQ '' AND p_cadena NE '' AND p_zonav NE '' AND p_client NE ''.
    SELECT a~vbeln FROM vbrk AS a
      INNER JOIN vbrp AS b ON b~vbeln EQ a~vbeln
      WHERE a~fkdat IN @p_fecha
      AND a~bzirk IN @p_zonav
      AND a~kunrg IN @p_client
      AND b~kvgr1 IN @p_cadena
      AND a~fksto EQ ''
      AND a~vbtyp EQ 'M'
      AND a~belnr NE ''
      INTO TABLE @tt_facturas.
  ELSEIF p_agente NE '' AND p_cadena NE '' AND p_zonav NE '' AND p_client EQ ''.
    SELECT a~vbeln FROM vbrk AS a
      INNER JOIN vbrp AS b ON b~vbeln EQ a~vbeln
      WHERE a~fkdat IN @p_fecha
      AND a~bzirk IN @p_zonav
      AND b~vkgrp IN @p_agente
      AND b~kvgr1 IN @p_cadena
      AND a~fksto EQ ''
      AND a~vbtyp EQ 'M'
      AND a~belnr NE ''
      INTO TABLE @tt_facturas.
  ELSEIF p_agente NE '' AND p_cadena EQ '' AND p_zonav NE '' AND p_client NE ''.
    SELECT a~vbeln FROM vbrk AS a
      INNER JOIN vbrp AS b ON b~vbeln EQ a~vbeln
      WHERE a~fkdat IN @p_fecha
      AND a~bzirk IN @p_zonav
      AND b~vkgrp IN @p_agente
      AND a~kunrg IN @p_client
      AND a~fksto EQ ''
      AND a~vbtyp EQ 'M'
      AND a~belnr NE ''
      INTO TABLE @tt_facturas.
  ELSEIF p_agente NE '' AND p_cadena NE '' AND p_zonav EQ '' AND p_client NE ''.
    SELECT a~vbeln FROM vbrk AS a
      INNER JOIN vbrp AS b ON b~vbeln EQ a~vbeln
      WHERE a~fkdat IN @p_fecha
      AND b~kvgr1 IN @p_cadena
      AND b~vkgrp IN @p_agente
      AND a~kunrg IN @p_client
      AND a~fksto EQ ''
      AND a~vbtyp EQ 'M'
      AND a~belnr NE ''
      INTO TABLE @tt_facturas.
  ELSEIF p_agente NE '' AND p_cadena NE '' AND p_zonav NE '' AND p_client NE ''.
    SELECT a~vbeln FROM vbrk AS a
      INNER JOIN vbrp AS b ON b~vbeln EQ a~vbeln
      WHERE a~fkdat IN @p_fecha
      AND b~kvgr1 IN @p_cadena
      AND b~vkgrp IN @p_agente
      AND a~kunrg IN @p_client
      AND a~bzirk IN @p_zonav
      AND a~fksto EQ ''
      AND a~vbtyp EQ 'M'
      AND a~belnr NE ''
      INTO TABLE @tt_facturas.
  ENDIF.

  SORT tt_facturas ASCENDING.
  DELETE ADJACENT DUPLICATES FROM tt_facturas.
  DESCRIBE TABLE tt_facturas LINES lv_lines.

  "Llenado de tablas internas a partir de las facturas seleccionadas.
  IF lv_lines GT 0.
    SELECT * FROM vbrk
      FOR ALL ENTRIES IN @tt_facturas
      WHERE vbeln EQ @tt_facturas-factura
      AND fksto EQ ''
      AND vbtyp EQ 'M'
      AND belnr NE ''
      INTO TABLE @it_vbrk.

    SORT it_vbrk ASCENDING BY vbeln.

    SELECT * FROM vbrp
      FOR ALL ENTRIES IN @it_vbrk
      WHERE vbeln EQ @it_vbrk-vbeln
      INTO TABLE @it_vbrp.

    SORT it_vbrp ASCENDING BY vbeln posnr.

    SELECT * FROM kna1
      FOR ALL ENTRIES IN @it_vbrk
      WHERE kunnr EQ @it_vbrk-kunrg
      INTO TABLE @it_kna1.

    SORT it_kna1 ASCENDING BY kunnr.
    DELETE ADJACENT DUPLICATES FROM it_kna1 COMPARING kunnr.

    SELECT * FROM makt
      FOR ALL ENTRIES IN @it_vbrp
      WHERE matnr EQ @it_vbrp-matnr
      INTO TABLE @it_makt.

    SORT it_makt ASCENDING BY matnr.
    DELETE ADJACENT DUPLICATES FROM it_makt COMPARING matnr.

    SELECT * FROM tvgrt
      FOR ALL ENTRIES IN @it_vbrp
      WHERE vkgrp EQ @it_vbrp-vkgrp
      INTO TABLE @it_tvgrt.

    SORT it_tvgrt ASCENDING BY vkgrp.
    DELETE ADJACENT DUPLICATES FROM it_tvgrt COMPARING vkgrp.

    SELECT * FROM bsid_view
      FOR ALL ENTRIES IN @it_vbrk
      WHERE vbeln EQ @it_vbrk-vbeln
      INTO TABLE @it_bsid.

    SORT it_bsid ASCENDING BY bukrs gjahr belnr.

    SELECT * FROM bsad_view
      FOR ALL ENTRIES IN @it_vbrk
      WHERE vbeln EQ @it_vbrk-vbeln
      INTO TABLE @it_bsad.

    SORT it_bsad ASCENDING BY bukrs gjahr belnr.

    SELECT * FROM prcd_elements
      FOR ALL ENTRIES IN @it_vbrk
      WHERE knumv EQ @it_vbrk-knumv
      INTO TABLE @it_prcd.

    SORT it_prcd ASCENDING BY knumv kposn.

    SELECT * FROM zsd_cfdi_return
      FOR ALL ENTRIES IN @it_vbrk
      WHERE nodocu EQ @it_vbrk-vbeln
      INTO TABLE @it_cfdi.

    SORT it_cfdi ASCENDING BY serie nodocu.

    "Llenado de estructura que se envia para el ALV
    LOOP AT it_vbrp ASSIGNING FIELD-SYMBOL(<wa_vbrp>).

      READ TABLE it_vbrk INTO wa_vbrk WITH KEY vbeln = <wa_vbrp>-vbeln.
      READ TABLE it_cfdi INTO wa_cfdi WITH KEY nodocu = <wa_vbrp>-vbeln.
      READ TABLE it_prcd INTO wa_prcd WITH KEY knumv = wa_vbrk-knumv kposn = <wa_vbrp>-posnr kschl = 'MWST'.

      ts_factudet-fecfact    = wa_vbrk-fkdat.
      ts_factudet-factura    = wa_vbrk-vbeln.
      ts_factudet-cliente    = |{ wa_vbrk-kunrg ALPHA = OUT }|.
      ts_factudet-canal      = wa_vbrk-vtweg.
      ts_factudet-zonavta    = wa_vbrk-bzirk.
      ts_factudet-uuid       = wa_cfdi-uuid.

      ts_factudet-agente     = <wa_vbrp>-vkgrp.
      ts_factudet-cadena     = <wa_vbrp>-kvgr1.
      ts_factudet-oficinavta = <wa_vbrp>-vkbur.
      ts_factudet-material   = |{ <wa_vbrp>-matnr ALPHA = OUT }|.
      ts_factudet-cantidad   = <wa_vbrp>-fkimg.
      ts_factudet-unimed     = |{ <wa_vbrp>-vrkme ALPHA = OUT }|.
      ts_factudet-pesoneto   = <wa_vbrp>-ntgew.
      ts_factudet-pesobruto  = <wa_vbrp>-brgew.
      ts_factudet-unipeso    = |{ <wa_vbrp>-gewei ALPHA = OUT }|.
      ts_factudet-importe    = <wa_vbrp>-netwr.
      ts_factudet-moneda     = <wa_vbrp>-waerk.
      ts_factudet-tipocam    = wa_vbrk-kurrf.
      ts_factudet-importeml  = <wa_vbrp>-netwr * wa_vbrk-kurrf.
      ts_factudet-cenben     = <wa_vbrp>-prctr.
      ts_factudet-indimp     = <wa_vbrp>-mwsk1.
      ts_factudet-tasa       = wa_prcd-kbetr.
      ts_factudet-impimpue   = wa_prcd-kwert * wa_vbrk-kurrf.

      READ TABLE it_kna1 INTO wa_kna1 WITH KEY kunnr = wa_vbrk-kunrg.

      CONDENSE: wa_kna1-name1, wa_kna1-name2, wa_kna1-name3, wa_kna1-name4.
      CONCATENATE wa_kna1-name1 wa_kna1-name2 wa_kna1-name3 wa_kna1-name4 INTO ts_factudet-nombrecte SEPARATED BY space.

      ts_factudet-pais       = wa_kna1-land1.

      READ TABLE it_tvgrt INTO wa_tvgrt WITH KEY vkgrp = <wa_vbrp>-vkgrp spras = 'S'.

      ts_factudet-nombreage  = wa_tvgrt-bezei.

      READ TABLE it_makt INTO wa_makt WITH KEY matnr = <wa_vbrp>-matnr spras = 'S'.

      ts_factudet-descrip    = wa_makt-maktx.

      "Lógica para buscar saldos y fechas de pago en tablas BSID y BSAD.

      lv_facrefer = wa_vbrk-vbeln.

      IF lv_facrefer EQ lv_facrefer1 AND lv_flag1 NE 'X'.
        MOVE 'X' TO lv_flag1.
        LOOP AT it_bsid INTO wa_bsid WHERE vbeln EQ wa_vbrk-vbeln AND blart EQ 'DZ'.
          lv_pagos = lv_pagos + wa_bsid-wrbtr.
          MOVE lv_facrefer TO lv_facrefer1.
        ENDLOOP.
      ENDIF.

      "ts_factudet-saldo      =

      APPEND ts_factudet TO tt_factudet.
      SORT tt_factudet ASCENDING BY factura.
      CLEAR: ts_factudet, wa_vbrk, wa_kna1, wa_tvgrt, wa_makt, lv_facrefer, wa_prcd, wa_cfdi.
    ENDLOOP.
    UNASSIGN <wa_vbrp>.
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
  wa_header-info = 'Relación de Facturas'.
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

  CASE r_ucomm.
    WHEN '&IC1'.           "Doble Clcik
      IF rs_selfield-fieldname EQ 'FACTURA'.
        READ TABLE it_vbrk INTO wa_vbrk WITH KEY vbeln = rs_selfield-value.
        IF sy-subrc EQ 0.
          SET PARAMETER ID 'VF' FIELD wa_vbrk-vbeln.
          CALL TRANSACTION 'VF03' AND SKIP FIRST SCREEN.
        ENDIF.
        CLEAR wa_vbrk.
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
