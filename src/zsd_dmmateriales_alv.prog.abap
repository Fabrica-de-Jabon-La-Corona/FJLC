*&---------------------------------------------------------------------*
*& Report ZSD_DMMATERIALES_ALV
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zsd_dmmateriales_alv.

TABLES : mara, mvke, mean, makt, /aif/t_mvmapval, /sapsll/clsnr, marc.
TYPE-POOLS : slis.

**Declaración de tablas internas
DATA : wa_mara   TYPE mara,
       it_mara   TYPE STANDARD TABLE OF mara,
       wa_mvke   TYPE mvke,
       it_mvke   TYPE STANDARD TABLE OF mvke,
       wa_vmap   TYPE /aif/t_mvmapval,
       it_vmap   TYPE STANDARD TABLE OF /aif/t_mvmapval,
       wa_maritc TYPE /sapsll/maritc,
       it_maritc TYPE STANDARD TABLE OF /sapsll/maritc,
       wa_clsnr  TYPE /sapsll/clsnr,
       it_clsnr  TYPE STANDARD TABLE OF /sapsll/clsnr,
       wa_mean   TYPE mean,
       it_mean   TYPE STANDARD TABLE OF mean,
       wa_makt   TYPE makt,
       it_makt   TYPE STANDARD TABLE OF makt.

**Declaración de datos
DATA: fieldcatalog TYPE slis_t_fieldcat_alv WITH HEADER LINE,
      gd_layout    TYPE slis_layout_alv,
      gd_repid     LIKE sy-repid,
      g_save       TYPE c VALUE 'X',
      g_variant    TYPE disvariant,
      gx_variant   TYPE disvariant,
      g_exit       TYPE c.

**Declaración de estructura final
DATA:
  BEGIN OF tt_datosmaterial OCCURS 0,
    matnr TYPE matnr,
    maktx TYPE maktx,
    vkorg TYPE vkorg,
    vtweg TYPE vtweg,
    bismt TYPE bismt,
    meins TYPE meins,
    vrkme TYPE vrkme,
    brgew TYPE brgew,
    ntgew TYPE ntgew,
    gewei TYPE gewei,
    volum TYPE volum,
    voleh TYPE voleh,
    ean11 TYPE ean11,
    extva TYPE ext_value,
    ccngn TYPE /sapsll/maritc-ccngn,
    cuom1 TYPE /sapsll/clsnr-cuom1,
    werks TYPE werks,
    prctr TYPE prctr,
  END OF tt_datosmaterial.
DATA:
  ts_datosmaterial LIKE tt_datosmaterial.

**Parámetros de selección
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-002 .
  PARAMETERS: p_vkorg TYPE vkorg OBLIGATORY,
              p_vtweg TYPE vtweg OBLIGATORY,
              p_werks TYPE werks_d OBLIGATORY.

  SELECT-OPTIONS: p_matnr FOR mvke-matnr.

SELECTION-SCREEN END OF BLOCK b1.
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

  fieldcatalog-fieldname   = 'MATNR'.
  fieldcatalog-seltext_m   = 'No. Material'.
  fieldcatalog-col_pos     = 0.
  fieldcatalog-outputlen   = 18.
  fieldcatalog-key         = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'MAKTX'.
  fieldcatalog-seltext_m   = 'Descripción'.
  fieldcatalog-col_pos     = 1.
  fieldcatalog-outputlen   = 40.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'VKORG'.
  fieldcatalog-seltext_m   = 'Org. Vtas.'.
  fieldcatalog-col_pos     = 2.
  fieldcatalog-outputlen   = 9.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'VTWEG'.
  fieldcatalog-seltext_m   = 'Canal'.
  fieldcatalog-col_pos     = 3.
  fieldcatalog-outputlen   = 5.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'BISMT'.
  fieldcatalog-seltext_m   = 'Material G-Link'.
  fieldcatalog-col_pos     = 4.
  fieldcatalog-outputlen   = 15.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'MEINS'.
  fieldcatalog-seltext_m   = 'UMB'.
  fieldcatalog-col_pos     = 5.
  fieldcatalog-outputlen   = 4.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'VRKME'.
  fieldcatalog-seltext_m   = 'UMV'.
  fieldcatalog-col_pos     = 6.
  fieldcatalog-outputlen   = 4.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'BRGEW'.
  fieldcatalog-seltext_m   = 'Peso Bruto'.
  fieldcatalog-col_pos     = 7.
  fieldcatalog-outputlen   = 10.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'NTGEW'.
  fieldcatalog-seltext_m   = 'Peso Neto'.
  fieldcatalog-col_pos     = 8.
  fieldcatalog-outputlen   = 10.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'GEWEI'.
  fieldcatalog-seltext_m   = 'Unidad Peso'.
  fieldcatalog-col_pos     = 9.
  fieldcatalog-outputlen   = 11.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'VOLUM'.
  fieldcatalog-seltext_m   = 'Volumen'.
  fieldcatalog-col_pos     = 10.
  fieldcatalog-outputlen   = 7.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'VOLEH'.
  fieldcatalog-seltext_m   = 'Unidad Volumen'.
  fieldcatalog-col_pos     = 11.
  fieldcatalog-outputlen   = 14.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'EAN11'.
  fieldcatalog-seltext_m   = 'Código EAN'.
  fieldcatalog-col_pos     = 12.
  fieldcatalog-outputlen   = 13.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'EXTVA'.
  fieldcatalog-seltext_m   = 'Clave Prod. y Ser.'.
  fieldcatalog-col_pos     = 13.
  fieldcatalog-outputlen   = 18.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'CCNGN'.
  fieldcatalog-seltext_m   = 'Fracción Arancelaria'.
  fieldcatalog-col_pos     = 14.
  fieldcatalog-outputlen   = 20.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'CUOM1'.
  fieldcatalog-seltext_m   = 'Unidad Aduana'.
  fieldcatalog-col_pos     = 15.
  fieldcatalog-outputlen   = 13.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'WERKS'.
  fieldcatalog-seltext_m   = 'Centro'.
  fieldcatalog-col_pos     = 16.
  fieldcatalog-outputlen   = 10.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'PRCTR'.
  fieldcatalog-seltext_m   = 'Ce.Be.'.
  fieldcatalog-col_pos     = 17.
  fieldcatalog-outputlen   = 10.
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
  gd_repid = sy-repid.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program      = gd_repid
      i_callback_top_of_page  = 'TOP-OF-PAGE'  "see FORM
      i_callback_user_command = 'USER_COMMAND'
      it_fieldcat             = fieldcatalog[]
      i_save                  = 'X'
      is_variant              = g_variant
    TABLES
      t_outtab                = tt_datosmaterial
    EXCEPTIONS
      program_error           = 1
      OTHERS                  = 2.
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

  IF p_matnr EQ ''.
    SELECT * FROM mvke
      WHERE vkorg EQ @p_vkorg
      AND vtweg EQ @p_vtweg
      AND lvorm EQ ''
      INTO TABLE @it_mvke.
  ELSEIF p_matnr NE ''.
    SELECT * FROM mvke
      WHERE vkorg EQ @p_vkorg
      AND vtweg EQ @p_vtweg
      AND matnr IN @p_matnr
      AND lvorm EQ ''
      INTO TABLE @it_mvke.
  ENDIF.

  SELECT * FROM mara
    FOR ALL ENTRIES IN @it_mvke
    WHERE matnr EQ @it_mvke-matnr
    AND lvorm EQ ''
    INTO TABLE @it_mara.

  SELECT * FROM mean
    FOR ALL ENTRIES IN @it_mara
    WHERE matnr EQ @it_mara-matnr
    AND eantp EQ 'HE'
    INTO TABLE @it_mean.

  SELECT * FROM makt
    FOR ALL ENTRIES IN @it_mara
    WHERE matnr EQ @it_mara-matnr
    AND spras EQ 'S'
    INTO TABLE @it_makt.

  SELECT * FROM /sapsll/maritc
    FOR ALL ENTRIES IN @it_mara
    WHERE matnr EQ @it_mara-matnr
    AND stcts EQ 'ZSD_FRARAN'
    AND datbi EQ '99991231'
    INTO TABLE @it_maritc.

  SELECT * FROM /sapsll/clsnr
    FOR ALL ENTRIES IN @it_maritc
    WHERE nosct EQ @it_maritc-stcts
    AND ccngn EQ @it_maritc-ccngn
    AND datbi EQ '99991231'
    INTO TABLE @it_clsnr.

  SELECT * FROM marc
    FOR ALL ENTRIES IN @it_mara
    WHERE matnr EQ @it_mara-matnr
    AND werks EQ @p_werks
    INTO TABLE @DATA(lt_marc).


  LOOP AT it_mvke INTO wa_mvke.
    ts_datosmaterial-matnr = |{ wa_mvke-matnr ALPHA = OUT }|.
    ts_datosmaterial-vkorg = wa_mvke-vkorg.
    ts_datosmaterial-vtweg = wa_mvke-vtweg.
    ts_datosmaterial-vrkme = wa_mvke-vrkme.

    READ TABLE it_makt INTO wa_makt WITH KEY matnr = wa_mvke-matnr.

    ts_datosmaterial-maktx = wa_makt-maktx.

    READ TABLE it_mara INTO wa_mara WITH KEY matnr = wa_mvke-matnr.

    ts_datosmaterial-bismt = wa_mara-bismt.
    ts_datosmaterial-meins = wa_mara-meins.
    ts_datosmaterial-brgew = wa_mara-brgew.
    ts_datosmaterial-ntgew = wa_mara-ntgew.
    ts_datosmaterial-gewei = wa_mara-gewei.
    ts_datosmaterial-volum = wa_mara-volum.
    ts_datosmaterial-voleh = wa_mara-voleh.

    READ TABLE it_mean INTO wa_mean WITH KEY matnr = wa_mvke-matnr.

    ts_datosmaterial-ean11 = wa_mean-ean11.

    READ TABLE it_maritc INTO wa_maritc WITH KEY matnr = wa_mvke-matnr.

    ts_datosmaterial-ccngn = wa_maritc-ccngn.

    READ TABLE it_clsnr INTO wa_clsnr WITH KEY ccngn = wa_maritc-ccngn.

    ts_datosmaterial-cuom1 = wa_clsnr-cuom1.

    SELECT SINGLE ext_value INTO ts_datosmaterial-extva
      FROM /aif/t_mvmapval
      WHERE int_value EQ wa_mvke-matnr
      AND ns EQ '/EDOMX'
      AND vmapname EQ 'PRODUCT_CODE'.

    READ TABLE lt_marc ASSIGNING FIELD-SYMBOL(<fs_marc>) WITH KEY matnr = wa_mvke-matnr werks = p_werks.

    IF <fs_marc> IS ASSIGNED.
      ts_datosmaterial-werks = <fs_marc>-werks.
      ts_datosmaterial-prctr = <fs_marc>-prctr.
      UNASSIGN <fs_marc>.
    ENDIF.

    APPEND ts_datosmaterial TO tt_datosmaterial.
    CLEAR: ts_datosmaterial, wa_mara, wa_makt, wa_mean, wa_maritc, wa_clsnr.
  ENDLOOP.
  CLEAR wa_mvke.
  SORT tt_datosmaterial BY matnr ASCENDING.
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
  wa_header-info = 'Listado de Materiales'.
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

  DATA: lv_message TYPE c LENGTH 100.

  CASE r_ucomm.
    WHEN '&IC1'.           "Doble Clcik
  ENDCASE.
ENDFORM.                    " USER_COMMAND
