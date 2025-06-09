*&---------------------------------------------------------------------*
*& Report ZSD_CREAFUNCINTERLCLIENTES
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zsd_creafuncinterlclientes.

TYPES:
  BEGIN OF ls_ficliente,
    kunnr   TYPE kunnr,
    vkorg   TYPE vkorg,
    vtweg   TYPE vtweg,
    ztm001  TYPE c LENGTH 1,
    flcu00  TYPE c LENGTH 1,
    bukrs   TYPE bukrs,
    akont   TYPE akont,
    zterm   TYPE knb1-zterm,
    zwels   TYPE knb1-zwels,
    natpers TYPE but000-natpers,
    result  TYPE string,
  END OF ls_ficliente.
TYPES:
  lt_ficliente TYPE STANDARD TABLE OF ls_ficliente.

DATA: lt_arch      TYPE STANDARD TABLE OF alsmex_tabline,
      ls_arch      TYPE alsmex_tabline,
      lt_cliente   TYPE lt_ficliente,
      ls_cliente   TYPE ls_ficliente,
      lt_lines     TYPE STANDARD TABLE OF tline,
      ls_lines     TYPE tline,
      lt_linesread TYPE STANDARD TABLE OF tline,
      ls_linesread TYPE tline,
      lv_tdname    TYPE stxh-tdname,
      lv_matnr40   TYPE c LENGTH 40,
      lv_len       TYPE i,
      lv_times     TYPE i,
      fieldcatalog TYPE slis_t_fieldcat_alv WITH HEADER LINE,
      gd_layout    TYPE slis_layout_alv,
      gd_repid     LIKE sy-repid,
      g_save       TYPE c VALUE 'X',
      g_variant    TYPE disvariant,
      gx_variant   TYPE disvariant,
      g_exit       TYPE c,
      lt_return    TYPE STANDARD TABLE OF bapiret2.

DATA: ls_cmpydata  TYPE cmds_ei_company,
      ls_company   TYPE cmds_ei_cmd_company,
      ls_customer  TYPE cmds_ei_extern,
      ls_customers TYPE cmds_ei_main,
      ls_error     TYPE cvis_message.

CONSTANTS: lc_object  TYPE tdobject VALUE 'MVKE',
           gc_refresh TYPE syucomm VALUE '&REFRESH',
           c_x        TYPE c LENGTH 1 VALUE 'X',
           lc_task    TYPE cmd_ei_object_task VALUE 'M',
           lc_id      TYPE tdid VALUE '0001'.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.

  PARAMETERS: p_arch LIKE rlgrap-filename OBLIGATORY.

SELECTION-SCREEN END OF BLOCK b1.

*Búsqueda del archivo a cargar
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_arch.
  CALL FUNCTION 'KD_GET_FILENAME_ON_F4'
    EXPORTING
      mask          = ',todos los archivos,*.*'
    CHANGING
      file_name     = p_arch
    EXCEPTIONS
      mask_too_long = 1.

*Carga contenido de archivo xls a tabla interna
  CALL FUNCTION 'ALSM_EXCEL_TO_INTERNAL_TABLE'
    EXPORTING
      filename                = p_arch
      i_begin_col             = 1
      i_begin_row             = 2
      i_end_col               = 7
      i_end_row               = 1001
    TABLES
      intern                  = lt_arch
    EXCEPTIONS
      inconsistent_parameters = 1
      upload_ole              = 2
      OTHERS                  = 3.


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

  fieldcatalog-fieldname   = 'KUNNR'.
  fieldcatalog-seltext_m   = 'Cliente'.
  fieldcatalog-col_pos     = 0.
  fieldcatalog-outputlen   = 10.
  fieldcatalog-key         = 'X'.
  fieldcatalog-hotspot     = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'VKORG'.
  fieldcatalog-seltext_m   = 'Org.Vtas.'.
  fieldcatalog-col_pos     = 1.
  fieldcatalog-outputlen   = 4.
  fieldcatalog-key         = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'VTWEG'.
  fieldcatalog-seltext_m   = 'Canal'.
  fieldcatalog-col_pos     = 2.
  fieldcatalog-outputlen   = 2.
  fieldcatalog-key         = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'ZTM001'.
  fieldcatalog-seltext_m   = 'Machetero'.
  fieldcatalog-col_pos     = 3.
  fieldcatalog-outputlen   = 1.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'FLCU00'.
  fieldcatalog-seltext_m   = 'Cliente (Dat.Fin)'.
  fieldcatalog-col_pos     = 4.
  fieldcatalog-outputlen   = 1.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'BUKRS'.
  fieldcatalog-seltext_m   = 'Sociedad'.
  fieldcatalog-col_pos     = 5.
  fieldcatalog-outputlen   = 4.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'AKONT'.
  fieldcatalog-seltext_m   = 'Cuenta Asociada'.
  fieldcatalog-col_pos     = 5.
  fieldcatalog-outputlen   = 10.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'ZTERM'.
  fieldcatalog-seltext_m   = 'Cond.Pago'.
  fieldcatalog-col_pos     = 6.
  fieldcatalog-outputlen   = 4.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'ZWELS'.
  fieldcatalog-seltext_m   = 'Vía de Pago'.
  fieldcatalog-col_pos     = 7.
  fieldcatalog-outputlen   = 4.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'NATPERS'.
  fieldcatalog-seltext_m   = 'Persona Física'.
  fieldcatalog-col_pos     = 6.
  fieldcatalog-outputlen   = 1.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'RESULT'.
  fieldcatalog-seltext_m   = 'Resultado'.
  fieldcatalog-col_pos     = 9.
  fieldcatalog-outputlen   = 100.
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
      t_outtab                 = lt_cliente
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

*Se llena la tabla interna con los datos acomodados con la estructura del excel.
  LOOP AT lt_arch INTO ls_arch.
    CASE ls_arch-col.
      WHEN 1.
        ls_cliente-kunnr = |{ ls_arch-value ALPHA = IN }|.
      WHEN 2.
        MOVE ls_arch-value TO ls_cliente-bukrs.
      WHEN 3.
        MOVE ls_arch-value TO ls_cliente-akont.
      WHEN 4.
        MOVE ls_arch-value TO ls_cliente-zterm.
      WHEN 5.
        MOVE ls_arch-value TO ls_cliente-zwels.
      WHEN 6.
        MOVE ls_arch-value TO ls_cliente-natpers.
    ENDCASE.

    AT END OF row.
      APPEND ls_cliente TO lt_cliente.
      CLEAR: ls_cliente.
    ENDAT.
    CLEAR: ls_arch.
  ENDLOOP.

  SORT lt_cliente ASCENDING BY kunnr.

  SELECT * FROM but000
    FOR ALL ENTRIES IN @lt_cliente
    WHERE partner = @lt_cliente-kunnr
    INTO TABLE @DATA(lt_but000).

  SELECT * FROM but100
    FOR ALL ENTRIES IN @lt_cliente
    WHERE partner = @lt_cliente-kunnr
    INTO TABLE @DATA(lt_but100).

  SELECT * FROM knvv
    FOR ALL ENTRIES IN @lt_cliente
    WHERE kunnr = @lt_cliente-kunnr
    AND vkorg = '1000'
    AND vtweg = '01'
    INTO TABLE @DATA(lt_knvv).

*Manipulación de los datos del excel ya cargados y ordenados en la tabla interna.
  LOOP AT lt_cliente ASSIGNING FIELD-SYMBOL(<fs_cliente>).

    READ TABLE lt_but000 ASSIGNING FIELD-SYMBOL(<fs_but000>) WITH KEY partner = <fs_cliente>-kunnr.

    IF <fs_but000> IS ASSIGNED.
      READ TABLE lt_knvv ASSIGNING FIELD-SYMBOL(<fs_knvv>) WITH KEY kunnr = <fs_cliente>-kunnr vkorg = '1000' vtweg = '01'.
      IF <fs_knvv> IS ASSIGNED.
        <fs_cliente>-vkorg = <fs_knvv>-vkorg.
        <fs_cliente>-vtweg = <fs_knvv>-vtweg.

        READ TABLE lt_but100 ASSIGNING FIELD-SYMBOL(<fs_but100>) WITH KEY partner = <fs_cliente>-kunnr rltyp = 'ZTM001'.
        IF <fs_but100> IS ASSIGNED.
          <fs_cliente>-ztm001 = 'X'.
          UNASSIGN <fs_but100>.
        ELSE.
          CALL FUNCTION 'BAPI_BUPA_ROLE_ADD_2'
            EXPORTING
              businesspartner     = <fs_cliente>-kunnr
              businesspartnerrole = 'ZTM001'
              validfromdate       = sy-datum
              validuntildate      = '99991231'
            TABLES
              return              = lt_return.

          IF sy-subrc EQ 0.
            CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
            <fs_cliente>-ztm001 = 'X'.
            <fs_cliente>-result = 'Se activó la F.I. ZTM001'.
          ENDIF.
        ENDIF.

        WAIT UP TO 1 SECONDS.

        READ TABLE lt_but100 ASSIGNING <fs_but100> WITH KEY partner = <fs_cliente>-kunnr rltyp = 'FLCU00'.
        IF <fs_but100> IS ASSIGNED.
          <fs_cliente>-flcu00 = 'X'.
          UNASSIGN <fs_but100>.
        ELSE.
          CALL FUNCTION 'BAPI_BUPA_ROLE_ADD_2'
            EXPORTING
              businesspartner     = <fs_cliente>-kunnr
              businesspartnerrole = 'FLCU00'
              validfromdate       = sy-datum
              validuntildate      = '99991231'
            TABLES
              return              = lt_return.

          IF sy-subrc EQ 0.
            CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.

            WAIT UP TO 2 SECONDS.

            ls_cmpydata-data_key-bukrs = |{ <fs_cliente>-bukrs ALPHA = IN }|.
            ls_cmpydata-task       = lc_task.
            ls_cmpydata-data-akont = |{ <fs_cliente>-akont ALPHA = IN }|.
            ls_cmpydata-data-zterm = |{ <fs_cliente>-zterm ALPHA = IN }|.
            ls_cmpydata-data-zwels = |{ <fs_cliente>-zwels ALPHA = IN }|.

            APPEND ls_cmpydata TO ls_company-company.

            ls_customer-company_data = ls_company.
            ls_customer-header-object_instance-kunnr = |{ <fs_cliente>-kunnr ALPHA = IN }|.
            ls_customer-header-object_task = lc_task.

            APPEND ls_customer TO ls_customers-customers.

            CALL METHOD cmd_ei_api=>maintain
              EXPORTING
*               iv_test_run    = space
                is_master_data = ls_customers
*               iv_manual_memory_init =
              IMPORTING
                es_error       = ls_error.

            IF line_exists( ls_error-messages[ type = 'E' ] ).
              IF <fs_cliente>-result EQ ''.
                <fs_cliente>-result = 'No se actualizaron los datos de FLCU00'.
              ELSE.
                CONCATENATE <fs_cliente>-result ', no se actualizaron los datos de FLCU00' INTO <fs_cliente>-result.
              ENDIF.
            ELSE.
              CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
            ENDIF.

          ENDIF.

          IF <fs_cliente>-result EQ ''.
            <fs_cliente>-result = 'Se activó la F.I. FLCU00'.
          ELSE.
            CONCATENATE <fs_cliente>-result ', se activó la F.I. FLCU00' INTO <fs_cliente>-result.
          ENDIF.
          <fs_cliente>-flcu00 = 'X'.
        ENDIF.

        UNASSIGN: <fs_knvv>.
      ELSE.
        <fs_cliente>-result = 'El cliente no está extendido al área de ventas 1000 / 01'.
      ENDIF.

      MODIFY lt_cliente FROM <fs_cliente>.
      UNASSIGN: <fs_but000>.
    ELSE.
      <fs_cliente>-result = 'El cliente no existe en la BD'.
      MODIFY lt_cliente FROM <fs_cliente>.
    ENDIF.

  ENDLOOP.
  UNASSIGN: <fs_cliente>.
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
  wa_header-info = 'Actualización de Textos Comerciales'.
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
      IF rs_selfield-fieldname EQ 'KUNNR'.
        READ TABLE lt_cliente INTO ls_cliente WITH KEY kunnr = rs_selfield-value.
        SET PARAMETER ID 'BPA' FIELD ls_cliente-kunnr.
        CALL TRANSACTION 'BP' AND SKIP FIRST SCREEN.
      ENDIF.
  ENDCASE.

ENDFORM.                    " USER_COMMAND
