*&---------------------------------------------------------------------*
*& Report ZSD_DMCLIENTES_ALV
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zsd_dmclientes_alv.

TABLES : kna1, knvv, but000, adrc, adr6, tvgrt, /aif/t_mvmapval.
TYPE-POOLS : slis.

**Declaración de tablas internas
DATA : wa_kna1  TYPE kna1,
       it_kna1  TYPE STANDARD TABLE OF kna1,
       wa_knvv  TYPE knvv,
       it_knvv  TYPE STANDARD TABLE OF knvv,
       wa_adrc  TYPE adrc,
       it_adrc  TYPE STANDARD TABLE OF adrc,
       wa_adr6  TYPE adr6,
       it_adr6  TYPE STANDARD TABLE OF adr6,
       wa_tvgrt TYPE tvgrt,
       it_tvgrt TYPE STANDARD TABLE OF tvgrt,
       wa_taxn  TYPE dfkkbptaxnum,
       it_taxn  TYPE STANDARD TABLE OF dfkkbptaxnum,
       wa_but0  TYPE but0id,
       it_but0  TYPE STANDARD TABLE OF but0id,
       wa_bu000 TYPE but000,
       it_bu000 TYPE STANDARD TABLE OF but000,
       wa_vmap  TYPE /aif/t_mvmapval,
       it_vmap  TYPE STANDARD TABLE OF /aif/t_mvmapval.

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

  SELECT-OPTIONS: p_client FOR kna1-kunnr,
                  p_agente FOR tvgrt-vkgrp,
                  p_zonav  FOR knvv-bzirk,
                  p_cadena FOR knvv-kvgr1,
                  p_canal  FOR knvv-vtweg.

SELECTION-SCREEN END OF BLOCK b1.

**Declaración de estructura final
DATA:
  BEGIN OF tt_dmcte  OCCURS 0,
    cliente TYPE kunnr,
    glink   TYPE kunnr,
    nombre  TYPE c LENGTH 163,
    rfc     TYPE dfkkbptaxnum-taxnum,
    idtrib  TYPE dfkkbptaxnum-taxnum,
    canal   TYPE vtweg,
    agente  TYPE vkgrp,
    nombage TYPE bezei,
    zonav   TYPE bzirk,
    cadena  TYPE kvgr1,
    centro  TYPE werks,
    oficv   TYPE vkbur,
    moneda  TYPE waers,
    condex  TYPE vsbed,
    conpag  TYPE knvv-zterm,
    incot   TYPE inco1,
    gln     TYPE c LENGTH 15,
    idext   TYPE c LENGTH 15,
    calle   TYPE adrc-street,
    numero  TYPE adrc-house_num1,
    colonia TYPE adrc-city2,
    deleg   TYPE adrc-city1,
    pais    TYPE adrc-country,
    estado  TYPE adrc-region,
    codpos  TYPE adrc-post_code1,
    usocfdi TYPE /aif/t_mvmapval-ext_value,
    regfisc TYPE /aif/t_mvmapval-ext_value,
  END OF tt_dmcte.
DATA:
  ts_dmcte  LIKE tt_dmcte.

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

  fieldcatalog-fieldname   = 'CLIENTE'.
  fieldcatalog-seltext_m   = 'Cliente'.
  fieldcatalog-col_pos     = 0.
  fieldcatalog-outputlen   = 10.
  fieldcatalog-key         = 'X'.
  fieldcatalog-hotspot     = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'GLINK'.
  fieldcatalog-seltext_m   = 'Cte. G-Link'.
  fieldcatalog-col_pos     = 1.
  fieldcatalog-outputlen   = 11.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'NOMBRE'.
  fieldcatalog-seltext_m   = 'Nombre'.
  fieldcatalog-col_pos     = 2.
  fieldcatalog-outputlen   = 40.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'RFC'.
  fieldcatalog-seltext_m   = 'RFC'.
  fieldcatalog-col_pos     = 3.
  fieldcatalog-outputlen   = 13.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'IDTRIB'.
  fieldcatalog-seltext_m   = 'ID Tributario'.
  fieldcatalog-col_pos     = 4.
  fieldcatalog-outputlen   = 15.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'CANAL'.
  fieldcatalog-seltext_m   = 'Canal'.
  fieldcatalog-col_pos     = 5.
  fieldcatalog-outputlen   = 5.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'AGENTE'.
  fieldcatalog-seltext_m   = 'Agente'.
  fieldcatalog-col_pos     = 6.
  fieldcatalog-outputlen   = 3.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'NOMBAGE'.
  fieldcatalog-seltext_m   = 'Nombre Agente'.
  fieldcatalog-col_pos     = 7.
  fieldcatalog-outputlen   = 20.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'ZONAV'.
  fieldcatalog-seltext_m   = 'Zona de Ventas'.
  fieldcatalog-col_pos     = 8.
  fieldcatalog-outputlen   = 6.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'CADENA'.
  fieldcatalog-seltext_m   = 'Cadena'.
  fieldcatalog-col_pos     = 9.
  fieldcatalog-outputlen   = 3.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'OFICV'.
  fieldcatalog-seltext_m   = 'Oficina de Ventas'.
  fieldcatalog-col_pos     = 10.
  fieldcatalog-outputlen   = 4.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'CENTRO'.
  fieldcatalog-seltext_m   = 'Centro'.
  fieldcatalog-col_pos     = 11.
  fieldcatalog-outputlen   = 4.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'MONEDA'.
  fieldcatalog-seltext_m   = 'Moneda'.
  fieldcatalog-col_pos     = 12.
  fieldcatalog-outputlen   = 3.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'CONDEX'.
  fieldcatalog-seltext_m   = 'Cond. Exped.'.
  fieldcatalog-col_pos     = 13.
  fieldcatalog-outputlen   = 4.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'CONPAG'.
  fieldcatalog-seltext_m   = 'Cond. Pago'.
  fieldcatalog-col_pos     = 14.
  fieldcatalog-outputlen   = 4.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'INCOT'.
  fieldcatalog-seltext_m   = 'Incoterm'.
  fieldcatalog-col_pos     = 15.
  fieldcatalog-outputlen   = 3.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'GLN'.
  fieldcatalog-seltext_m   = 'GLN'.
  fieldcatalog-col_pos     = 16.
  fieldcatalog-outputlen   = 15.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'IDEXT'.
  fieldcatalog-seltext_m   = 'ID Externo'.
  fieldcatalog-col_pos     = 17.
  fieldcatalog-outputlen   = 15.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'CALLE'.
  fieldcatalog-seltext_m   = 'Calle'.
  fieldcatalog-col_pos     = 18.
  fieldcatalog-outputlen   = 60.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'NUMERO'.
  fieldcatalog-seltext_m   = 'No. Ext.'.
  fieldcatalog-col_pos     = 19.
  fieldcatalog-outputlen   = 10.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'COLONIA'.
  fieldcatalog-seltext_m   = 'Colonia'.
  fieldcatalog-col_pos     = 20.
  fieldcatalog-outputlen   = 40.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'DELEG'.
  fieldcatalog-seltext_m   = 'Delegación/Municipio'.
  fieldcatalog-col_pos     = 21.
  fieldcatalog-outputlen   = 40.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'PAIS'.
  fieldcatalog-seltext_m   = 'País'.
  fieldcatalog-col_pos     = 22.
  fieldcatalog-outputlen   = 3.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'ESTADO'.
  fieldcatalog-seltext_m   = 'Estado'.
  fieldcatalog-col_pos     = 23.
  fieldcatalog-outputlen   = 3.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'CODPOS'.
  fieldcatalog-seltext_m   = 'Cód.Postal'.
  fieldcatalog-col_pos     = 24.
  fieldcatalog-outputlen   = 10.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'USOCFDI'.
  fieldcatalog-seltext_m   = 'Uso CFDI'.
  fieldcatalog-col_pos     = 25.
  fieldcatalog-outputlen   = 3.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'REGFISC'.
  fieldcatalog-seltext_m   = 'Rég.Fiscal'.
  fieldcatalog-col_pos     = 26.
  fieldcatalog-outputlen   = 3.
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
      t_outtab                 = tt_dmcte
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
    BEGIN OF tt_clientes  OCCURS 0,
      cliente TYPE kunnr,
      canal   TYPE vtweg,
    END OF tt_clientes.
  DATA:
    ts_clientes  LIKE tt_clientes.

  DATA: lv_flag1     TYPE c LENGTH 1,
        lv_facrefer  TYPE vbeln,
        lv_facrefer1 TYPE vbeln,
        lv_pagos     TYPE wrbtr.

  "Selección de clientes tomando en cuenta los parámetros de selección introducidos por el usuario y sus posibles combinaciones
  SELECT kunnr, vtweg FROM knvv
    WHERE vkgrp IN @p_agente
    AND bzirk IN @p_zonav
    AND kvgr1 IN @p_cadena
    AND kunnr IN @p_client
    AND vtweg IN @p_canal
    AND loevm EQ ''
    AND aufsd EQ ''
    AND lifsd EQ ''
    AND faksd EQ ''
    INTO TABLE @tt_clientes.

  SORT tt_clientes ASCENDING BY cliente canal.
  DELETE ADJACENT DUPLICATES FROM tt_clientes.
  DESCRIBE TABLE tt_clientes LINES lv_lines.

  "Llenado de tablas internas a partir de las facturas seleccionadas.
  IF lv_lines GT 0.
    SELECT * FROM kna1
      FOR ALL ENTRIES IN @tt_clientes
      WHERE kunnr EQ @tt_clientes-cliente
      AND aufsd EQ ''
      INTO TABLE @it_kna1.

    SORT it_kna1 ASCENDING BY kunnr.

    SELECT * FROM knvv
      FOR ALL ENTRIES IN @tt_clientes
      WHERE kunnr EQ @tt_clientes-cliente
      AND vtweg EQ @tt_clientes-canal
      AND loevm EQ ''
      AND aufsd EQ ''
      AND lifsd EQ ''
      AND faksd EQ ''
      INTO TABLE @it_knvv.

    SORT it_knvv ASCENDING BY kunnr vtweg.

    SELECT * FROM tvgrt
      FOR ALL ENTRIES IN @it_knvv
      WHERE vkgrp EQ @it_knvv-vkgrp
      INTO TABLE @it_tvgrt.

    SORT it_tvgrt ASCENDING BY vkgrp.
    DELETE ADJACENT DUPLICATES FROM it_tvgrt COMPARING vkgrp.

    SELECT * FROM dfkkbptaxnum
      FOR ALL ENTRIES IN @it_kna1
      WHERE partner EQ @it_kna1-kunnr
      INTO TABLE @it_taxn.

    SORT it_taxn ASCENDING BY partner.
    DELETE ADJACENT DUPLICATES FROM it_taxn COMPARING partner taxtype.

    SELECT * FROM but0id
      FOR ALL ENTRIES IN @it_kna1
      WHERE partner EQ @it_kna1-kunnr
      INTO TABLE @it_but0.

    SORT it_but0 ASCENDING BY partner.

    SELECT * FROM adrc
      FOR ALL ENTRIES IN @it_kna1
      WHERE addrnumber EQ @it_kna1-adrnr
      INTO TABLE @it_adrc.

    SORT it_adrc ASCENDING BY addrnumber.

    SELECT * FROM but000
      FOR ALL ENTRIES IN @it_kna1
      WHERE partner EQ @it_kna1-kunnr
      INTO TABLE @it_bu000.

    SORT it_bu000 ASCENDING BY partner.

    "Llenado de estructura que se envia para el ALV
    LOOP AT it_knvv INTO wa_knvv.

      READ TABLE it_bu000 INTO wa_bu000 WITH KEY partner = wa_knvv-kunnr.
      READ TABLE it_kna1  INTO wa_kna1  WITH KEY kunnr = wa_knvv-kunnr.
      READ TABLE it_tvgrt INTO wa_tvgrt WITH KEY vkgrp = wa_knvv-vkgrp spras = 'S'.
      READ TABLE it_adrc  INTO wa_adrc  WITH KEY addrnumber = wa_kna1-adrnr.

      CONDENSE: wa_kna1-name1, wa_kna1-name2, wa_kna1-name3, wa_kna1-name4.

      ts_dmcte-cliente = wa_knvv-kunnr.
      ts_dmcte-glink   = wa_bu000-bpext.
      ts_dmcte-canal   = wa_knvv-vtweg.
      ts_dmcte-agente  = wa_knvv-vkgrp.
      ts_dmcte-nombage = wa_tvgrt-bezei.
      ts_dmcte-zonav   = wa_knvv-bzirk.
      ts_dmcte-cadena  = wa_knvv-kvgr1.
      ts_dmcte-oficv   = wa_knvv-vkbur.
      ts_dmcte-centro  = wa_knvv-vwerk.
      ts_dmcte-moneda  = wa_knvv-waers.
      ts_dmcte-condex  = wa_knvv-vsbed.
      ts_dmcte-conpag  = wa_knvv-zterm.
      ts_dmcte-incot   = wa_knvv-inco1.
      ts_dmcte-calle   = wa_adrc-street.
      ts_dmcte-numero  = wa_adrc-house_num1.
      ts_dmcte-colonia = wa_adrc-city1.
      ts_dmcte-deleg   = wa_adrc-city2.
      ts_dmcte-pais    = wa_adrc-country.
      ts_dmcte-estado  = wa_adrc-region.
      ts_dmcte-codpos  = wa_adrc-post_code1.


      LOOP AT it_but0 INTO wa_but0 WHERE partner EQ wa_knvv-kunnr.
        IF wa_but0-type EQ 'ZBUGLN' AND wa_but0-valid_date_to EQ '99991231'.
          ts_dmcte-gln = wa_but0-idnumber.
        ELSEIF wa_but0-type EQ 'ZBUEDI' AND wa_but0-valid_date_to EQ '99991231'.
          ts_dmcte-idext = wa_but0-idnumber.
        ENDIF.
        CLEAR wa_but0.
      ENDLOOP.

      CONCATENATE wa_kna1-name1 wa_kna1-name2 wa_kna1-name3 wa_kna1-name4 INTO ts_dmcte-nombre SEPARATED BY space.

      READ TABLE it_taxn INTO wa_taxn WITH KEY partner = wa_knvv-kunnr taxtype = 'MX1'.
      ts_dmcte-rfc = wa_taxn-taxnum.
      CLEAR wa_taxn.

      LOOP AT it_taxn INTO wa_taxn WHERE partner EQ wa_knvv-kunnr AND taxtype NE 'MX1'.
        ts_dmcte-idtrib = wa_taxn-taxnum.
        CLEAR wa_taxn.
      ENDLOOP.

      SELECT SINGLE ext_value INTO ts_dmcte-usocfdi
        FROM /aif/t_mvmapval
        WHERE int_value EQ wa_knvv-kunnr
        AND ns EQ '/EDOMX'
        AND vmapname EQ 'CFDI_USAGE'.

      SELECT SINGLE ext_value INTO ts_dmcte-regfisc
        FROM /aif/t_mvmapval
        WHERE int_value EQ wa_knvv-kunnr
        AND ns EQ '/EDOMX'
        AND vmapname EQ 'RECEIVER_TAX_REGIME'.

      APPEND ts_dmcte TO tt_dmcte.
      SORT tt_dmcte ASCENDING BY cliente canal.
      CLEAR: ts_dmcte, wa_knvv, wa_kna1, wa_tvgrt, wa_bu000.
    ENDLOOP.
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
  wa_header-info = 'Datos Maestros de Clientes'.
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
      IF rs_selfield-fieldname EQ 'CLIENTE'.
        READ TABLE it_kna1 INTO wa_kna1 WITH KEY kunnr = rs_selfield-value.
        IF sy-subrc EQ 0.
          SET PARAMETER ID 'BPA' FIELD wa_kna1-kunnr.
          CALL TRANSACTION 'BP' AND SKIP FIRST SCREEN.
        ENDIF.
        CLEAR wa_kna1.
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
