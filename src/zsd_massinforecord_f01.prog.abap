*&---------------------------------------------------------------------*
*& Include          ZSD_MASSINFORECORD_F01
*&---------------------------------------------------------------------*
FORM get_data.
  "Obtain inforecords customer material data.
  SELECT FROM knmt AS kh
    INNER JOIN makt AS mt ON mt~matnr EQ kh~matnr
    LEFT OUTER JOIN knmta AS kp ON kp~guid EQ kh~guid
    FIELDS kh~vkorg, kh~vtweg, kh~kunnr, kh~matnr, mt~maktx, kh~kdmat, kh~postx, kp~kdmat, kp~addpostx
    WHERE kh~vkorg IN @pa_vkorg
    AND kh~vtweg IN @pa_vtweg
    AND kh~kunnr IN @pa_kunnr
    AND kh~matnr IN @pa_matnr
    AND mt~spras EQ 'S'
    INTO TABLE @gt_inforecord.
ENDFORM.

*&---------------------------------------------------------------------*
*& CLASS cl_handler
*&---------------------------------------------------------------------*
CLASS cl_handler DEFINITION.
  PUBLIC SECTION.
    METHODS: on_user_command FOR EVENT added_function OF cl_salv_events
      IMPORTING e_salv_function,

      on_link_click FOR EVENT link_click OF cl_salv_events_table
        IMPORTING row column.
ENDCLASS.

CLASS cl_handler IMPLEMENTATION.
  METHOD on_link_click.
*   Obtenemos la informacion de esa linea
    READ TABLE gt_inforecord ASSIGNING FIELD-SYMBOL(<fs_inforecord>) INDEX row.
    CHECK sy-subrc = 0.
    CASE column.
      WHEN 'MATNR'.
        SET PARAMETER ID 'KUN' FIELD <fs_inforecord>-kunnr.
        SET PARAMETER ID 'VKO' FIELD <fs_inforecord>-vkorg.
        SET PARAMETER ID 'VTW' FIELD <fs_inforecord>-vtweg.
        SET PARAMETER ID 'MAT' FIELD <fs_inforecord>-matnr.
        CALL TRANSACTION 'VD53' WITHOUT AUTHORITY-CHECK AND SKIP FIRST SCREEN.
    ENDCASE.
    UNASSIGN: <fs_inforecord>.
  ENDMETHOD.
  METHOD on_user_command.
    CASE e_salv_function.
      WHEN '&UPL'.
        PERFORM load_excel.
      WHEN '&DEL'.
        PERFORM delete_info USING gt_inforecord.
      WHEN '&SAV'.
        PERFORM save_info TABLES gt_inforecord.
      WHEN '&REF'.
        PERFORM refresh_info USING gt_inforecord.
      WHEN '&EX'.
        PERFORM exit_alv.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.

FORM display_alv.
  DATA: lo_gr_alv        TYPE REF TO cl_salv_table,             "ALV Properties
        lo_gr_functions  TYPE REF TO cl_salv_functions_list,
        lo_event_handler TYPE REF TO cl_handler,                "ALV Handlers
        lo_events        TYPE REF TO cl_salv_events_table,
        lo_display       TYPE REF TO cl_salv_display_settings,  "ALV layout settings
        "lo_selections    TYPE REF TO cl_salv_selections,        "ALV column properties and selections
        lo_columns       TYPE REF TO cl_salv_columns,
        lo_columns2      TYPE REF TO cl_salv_columns_table,
        lo_column        TYPE REF TO cl_salv_column_table,
        lo_column2       TYPE REF TO cl_salv_column,
        ref_alv_table    TYPE REF TO gty_inforecord,
        cx_salv          TYPE REF TO cx_salv_msg,
        cx_not_found     TYPE REF TO cx_salv_not_found,
        lo_gr_layout     TYPE REF TO cl_salv_layout,
        key              TYPE salv_s_layout_key,
        gr_msg           TYPE string,
        gr_container     TYPE REF TO cl_gui_custom_container.

*  CREATE OBJECT gr_container
*    EXPORTING
*      container_name              = 'ZCONTENEDOR_ALV'
*    EXCEPTIONS
*      cntl_error                  = 1
*      cntl_system_error           = 2
*      create_error                = 3
*      lifetime_error              = 4
*      lifetime_dynpro_dynpro_link = 5
*      OTHERS                      = 6.
*
*  IF ( sy-subrc <> 0 ).
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*  ENDIF.

* Creacion ALV object
  TRY.
      CALL METHOD cl_salv_table=>factory(
        EXPORTING
          "r_container  = gr_container
          container_name = 'CONTAINER'
        IMPORTING
          r_salv_table   = lo_gr_alv
        CHANGING
          t_table        = gt_inforecord ).
    CATCH cx_salv_msg.
  ENDTRY.

  lo_gr_alv->set_screen_status(
    report        = sy-repid
    pfstatus      = 'ZSALV_STATUS'
    set_functions = cl_salv_model_base=>c_functions_all ).

*Se muestran todos los botones del ALV (modificar, grabar, seleccionar layout).
  lo_gr_layout = lo_gr_alv->get_layout( ).
  key-report = sy-repid.
  lo_gr_layout->set_key( key ).

  lo_gr_layout->set_save_restriction( if_salv_c_layout=>restrict_none ).
  lo_gr_layout->set_save_restriction( ).
  lo_gr_layout->set_initial_layout( p_layout ).

*Mostramos los botones ALV
  lo_gr_functions = lo_gr_alv->get_functions( ).
*  TRY.
*      lo_gr_functions->add_function(
*        name     = 'TEST1'
**    icon     =
**    text     =
*        tooltip  = 'TESTTOOL'
*        position = if_salv_c_function_position=>left_of_salv_functions ).
*    CATCH cx_salv_existing.
*    CATCH cx_salv_wrong_call.
*  ENDTRY.
  lo_gr_functions->set_all( abap_true ).

  TRY.
* Optimize
      lo_columns = lo_gr_alv->get_columns( ).
      lo_columns->set_optimize( 'X' ).

*Change field labels

      lo_column ?= lo_columns->get_column( columnname = 'MATNR' ).
      lo_column->set_short_text( 'Material' ).
      lo_column->set_medium_text( 'Material' ).
      lo_column->set_long_text( 'Material' ).
      lo_column->set_zero( value = if_salv_c_bool_sap=>false ).

      lo_column ?= lo_columns->get_column( columnname = 'KDMAT2' ).
      lo_column->set_short_text( 'Case Mat.' ).
      lo_column->set_medium_text( 'Case Material' ).
      lo_column->set_long_text( 'Case Material' ).

      lo_column ?= lo_columns->get_column( columnname = 'ADDPOSTX' ).
      lo_column->set_short_text( 'Case Descr' ).
      lo_column->set_medium_text( 'Case Descr.' ).
      lo_column->set_long_text( 'Case Description' ).

      lo_column ?= lo_columns->get_column( columnname = 'STATUS' ).
      lo_column->set_short_text( 'Status' ).
      lo_column->set_medium_text( 'Status' ).
      lo_column->set_long_text( 'Status' ).
      IF gv_paso EQ ''.
        lo_column->set_visible( value = if_salv_c_bool_sap=>false ).
      ENDIF.

      lo_column ?= lo_columns->get_column( columnname = 'MATNR' ).
      lo_column->set_cell_type( if_salv_c_cell_type=>hotspot ).

    CATCH cx_salv_msg INTO cx_salv.
      gr_msg = cx_salv->get_text( ).
      MESSAGE gr_msg TYPE 'E'.
    CATCH cx_salv_not_found INTO cx_not_found.
      gr_msg = cx_not_found->get_text( ).
      MESSAGE gr_msg TYPE 'E'..
  ENDTRY.

* Posiciones
  lo_columns->set_column_position( columnname = 'VKORG'    position = 1 ).   "Sales Organization
  lo_columns->set_column_position( columnname = 'VTWEG'    position = 2 ).   "Distribution Channel
  lo_columns->set_column_position( columnname = 'KUNNR'    position = 3 ).   "Customer
  lo_columns->set_column_position( columnname = 'MATNR'    position = 4 ).   "SAP Material
  lo_columns->set_column_position( columnname = 'MAKTX'    position = 5 ).   "SAP Material Description
  lo_columns->set_column_position( columnname = 'KDMAT'    position = 6 ).   "Customer Material
  lo_columns->set_column_position( columnname = 'POSTX'    position = 7 ).   "Customer Material Description
  lo_columns->set_column_position( columnname = 'KDMAT2'   position = 8 ).   "Case Material
  lo_columns->set_column_position( columnname = 'ADDPOSTX' position = 9 ).   "Case Material Description
  lo_columns->set_column_position( columnname = 'STATUS'    position = 10 ). "Status of inforecord

* Aplicando estilo zebra
  lo_display = lo_gr_alv->get_display_settings( ).
  lo_display->set_striped_pattern( cl_salv_display_settings=>true ).

* Eventos
  lo_events = lo_gr_alv->get_event( ).
  CREATE OBJECT lo_event_handler.
  SET HANDLER lo_event_handler->on_link_click FOR lo_events.

  SET HANDLER lo_event_handler->on_user_command FOR lo_events.

* Enable cell selection mode
  lo_selections = lo_gr_alv->get_selections( ).
  lo_selections->set_selection_mode( if_salv_c_selection_mode=>row_column ).

  lo_gr_alv->display( ).

  IF sy-subrc <> 0.
    MESSAGE 'Error to show ALV Report' TYPE 'X'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form load_excel
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM load_excel .
  DATA: lt_arch       TYPE STANDARD TABLE OF alsmex_tabline,
        ls_arch       TYPE alsmex_tabline,
        lt_lines      TYPE STANDARD TABLE OF tline,
        ls_lines      TYPE tline,
        lt_linesread  TYPE STANDARD TABLE OF tline,
        ls_linesread  TYPE tline,
        lv_tdname     TYPE stxh-tdname,
        lv_matnr40    TYPE c LENGTH 40,
        lv_len        TYPE i,
        lv_times      TYPE i,
        fieldcatalog  TYPE slis_t_fieldcat_alv WITH HEADER LINE,
        gd_layout     TYPE slis_layout_alv,
        gd_repid      LIKE sy-repid,
        g_save        TYPE c VALUE 'X',
        g_variant     TYPE disvariant,
        gx_variant    TYPE disvariant,
        g_exit        TYPE c,
        lv_uplpath    TYPE string,
        lv_dowpath    TYPE string,
        lt_filetable  TYPE filetable,
        lv_rc         TYPE i,
        lv_filename   TYPE rlgrap-filename,
        lt_inforecord TYPE TABLE OF gty_inforecord.

  IF gv_paso EQ 'X'.
    MESSAGE 'Please save the inforecods changes before upload another Excel file' TYPE 'E' DISPLAY LIKE 'E'.
  ENDIF.

  cl_gui_frontend_services=>file_open_dialog(
    EXPORTING
      window_title            = 'Open file'
      file_filter             = 'xlsx'
    CHANGING
      file_table              = lt_filetable
      rc                      = lv_rc
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      not_supported_by_gui    = 4
      OTHERS                  = 5
  ).
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_filetable ASSIGNING FIELD-SYMBOL(<fs_filetable>) INDEX 1.

  IF <fs_filetable> IS ASSIGNED.
    lv_filename = <fs_filetable>-filename.
    UNASSIGN: <fs_filetable>.
  ENDIF.

  CALL FUNCTION 'ALSM_EXCEL_TO_INTERNAL_TABLE'
    EXPORTING
      filename                = lv_filename
      i_begin_col             = 1
      i_begin_row             = 2
      i_end_col               = 8
      i_end_row               = 9999
    TABLES
      intern                  = lt_arch
    EXCEPTIONS
      inconsistent_parameters = 1
      upload_ole              = 2
      OTHERS                  = 3.

  "REFRESH lt_inforecord.

  LOOP AT lt_arch INTO ls_arch.
    CASE ls_arch-col.
      WHEN 1.
        MOVE ls_arch-value TO gs_inforecord-vkorg.
      WHEN 2.
        MOVE ls_arch-value TO gs_inforecord-vtweg.
      WHEN 3.
        gs_inforecord-kunnr = |{ ls_arch-value ALPHA = IN }|.
      WHEN 4.
        gs_inforecord-matnr = |{ ls_arch-value ALPHA = IN }|.
        SELECT SINGLE maktx INTO @gs_inforecord-maktx
          FROM makt
          WHERE matnr EQ @gs_inforecord-matnr
          AND spras EQ 'S'.
      WHEN 5.
        MOVE ls_arch-value TO gs_inforecord-kdmat.
      WHEN 6.
        MOVE ls_arch-value TO gs_inforecord-postx.
      WHEN 7.
        MOVE ls_arch-value TO gs_inforecord-kdmat2.
      WHEN 8.
        MOVE ls_arch-value TO gs_inforecord-addpostx.
    ENDCASE.

    AT END OF row.
      APPEND gs_inforecord TO lt_inforecord.
      CLEAR: gs_inforecord.
    ENDAT.
    CLEAR: ls_arch.
  ENDLOOP.

  SORT lt_inforecord ASCENDING BY kunnr matnr.

  LOOP AT lt_inforecord ASSIGNING FIELD-SYMBOL(<fs_inforecord>).
    IF line_exists( gt_inforecord[ kunnr = <fs_inforecord>-kunnr vkorg = <fs_inforecord>-vkorg vtweg = <fs_inforecord>-vtweg matnr = <fs_inforecord>-matnr ] ).
      <fs_inforecord>-status = 'Modify'.
    ELSE.
      <fs_inforecord>-status = 'New'.
    ENDIF.
    MODIFY lt_inforecord FROM <fs_inforecord>.
  ENDLOOP.

  IF lt_inforecord IS NOT INITIAL.
    gt_infopaso[] = gt_inforecord[].
    gt_inforecord[] = lt_inforecord[].
    gv_paso = 'X'.
* ALV Display
    PERFORM display_alv.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form delete_info
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GT_INFORECORD
*&---------------------------------------------------------------------*
FORM delete_info USING p_gt_inforecord.

  DATA: lv_confirm TYPE string,
        lv_lines   TYPE string,
        lv_answer  TYPE c LENGTH 1,
        lv_action  TYPE c LENGTH 1,
        lt_xknmt   TYPE TABLE OF vknmt,
        ls_xknmt   TYPE vknmt,
        lt_yknmt   TYPE TABLE OF vknmt,
        ls_yknmt   TYPE vknmt.

  IF gv_paso EQ 'X'.
    MESSAGE 'Please complete the upload you are performing before attempting to delete records.' TYPE 'W' DISPLAY LIKE 'E'.
  ELSE.

    lv_action = 'D'.

    "Read selected rows
    gt_rows = lo_selections->get_selected_rows( ).

    DESCRIBE TABLE gt_rows LINES lv_lines.

    IF lv_lines EQ 0.
      MESSAGE 'Please select the records that should be deleted' TYPE 'W' DISPLAY LIKE 'W'.
    ELSE.
      CONCATENATE 'Are you sure you want to delete the' lv_lines 'selected records?' INTO lv_confirm SEPARATED BY space.

      CALL FUNCTION 'FITP_POPUP_TO_CONFIRM'
        EXPORTING
          titlebar       = 'Please confirm the action'
          text_question  = lv_confirm
        IMPORTING
          answer         = lv_answer
        EXCEPTIONS
          text_not_found = 1
          OTHERS         = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      IF lv_answer EQ 'J'.

        SELECT * FROM knmt
          FOR ALL ENTRIES IN @gt_inforecord
          WHERE vkorg EQ @gt_inforecord-vkorg
          AND vtweg EQ @gt_inforecord-vtweg
          AND kunnr EQ @gt_inforecord-kunnr
          INTO TABLE @DATA(lt_knmt).

        SORT lt_knmt ASCENDING BY vkorg vtweg kunnr matnr.

        LOOP AT gt_rows INTO DATA(lv_index).
          READ TABLE gt_inforecord INDEX lv_index ASSIGNING FIELD-SYMBOL(<fs_inforecord>).
          IF <fs_inforecord> IS ASSIGNED.
            ls_yknmt-vkorg = <fs_inforecord>-vkorg.
            ls_yknmt-vtweg = <fs_inforecord>-vtweg.
            ls_yknmt-kunnr = <fs_inforecord>-kunnr.
            ls_yknmt-matnr = <fs_inforecord>-matnr.
            ls_yknmt-updkz = lv_action.

            ls_xknmt-vkorg = <fs_inforecord>-vkorg.
            ls_xknmt-vtweg = <fs_inforecord>-vtweg.
            ls_xknmt-kunnr = <fs_inforecord>-kunnr.
            ls_xknmt-matnr = <fs_inforecord>-matnr.
            ls_xknmt-updkz = ''.

            READ TABLE lt_knmt ASSIGNING FIELD-SYMBOL(<fs_knmt>) WITH KEY vkorg = <fs_inforecord>-vkorg vtweg = <fs_inforecord>-vtweg kunnr = <fs_inforecord>-kunnr matnr = <fs_inforecord>-matnr.
            IF <fs_knmt> IS ASSIGNED.
              ls_yknmt-guid = <fs_knmt>-guid.
              ls_xknmt-guid = <fs_knmt>-guid.
              UNASSIGN: <fs_knmt>.
            ENDIF.
            UNASSIGN <fs_inforecord>.
          ENDIF.

          APPEND: ls_yknmt TO lt_yknmt,
                  ls_xknmt TO lt_xknmt.
          CLEAR: ls_yknmt, ls_xknmt.
        ENDLOOP.

        "Delete inforecord routine
        PERFORM exec_inforecord TABLES lt_xknmt lt_yknmt USING lv_action.
      ENDIF.
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form save_info
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GT_INFORECORD
*&---------------------------------------------------------------------*
FORM save_info TABLES p_gt_inforecord.
  DATA: lv_action TYPE c LENGTH 1,
        lt_xknmt  TYPE TABLE OF vknmt,
        ls_xknmt  TYPE vknmt,
        lt_yknmt  TYPE TABLE OF vknmt,
        ls_yknmt  TYPE vknmt.

  LOOP AT gt_inforecord ASSIGNING FIELD-SYMBOL(<fs_inforecord>).
    ls_xknmt-vkorg = <fs_inforecord>-vkorg.
    ls_xknmt-vtweg = <fs_inforecord>-vtweg.
    ls_xknmt-kunnr = <fs_inforecord>-kunnr.
    ls_xknmt-matnr = <fs_inforecord>-matnr.
    ls_xknmt-kdmat = <fs_inforecord>-kdmat.
    ls_xknmt-postx = <fs_inforecord>-postx.

    CASE <fs_inforecord>-status.
      WHEN 'New'.
        ls_xknmt-updkz = 'I'.
        CALL FUNCTION 'GUID_CREATE'
          IMPORTING
            ev_guid_16 = ls_xknmt-guid.
      WHEN 'Modify'.
        ls_xknmt-updkz = 'U'.
        ls_xknmt-last_changed_by_user = sy-uname.
        GET TIME STAMP FIELD ls_xknmt-upd_tmstmp.

        SELECT SINGLE guid INTO @ls_xknmt-guid
          FROM knmt
          WHERE vkorg EQ @<fs_inforecord>-vkorg
          AND vtweg EQ @<fs_inforecord>-vtweg
          AND kunnr EQ @<fs_inforecord>-kunnr
          AND matnr EQ @<fs_inforecord>-matnr.

        "Fill YKNMT and YKNMTA tables when the action is update.
        SELECT * FROM knmt
          FOR ALL ENTRIES IN @gt_inforecord
          WHERE vkorg EQ @gt_inforecord-vkorg
          AND vtweg EQ @gt_inforecord-vtweg
          AND kunnr EQ @gt_inforecord-kunnr
          INTO TABLE @DATA(lt_knmt).

        SORT lt_knmt ASCENDING BY vkorg vtweg kunnr matnr.
        DELETE ADJACENT DUPLICATES FROM lt_knmt COMPARING vkorg vtweg kunnr matnr.

        READ TABLE lt_knmt ASSIGNING FIELD-SYMBOL(<fs_knmt>) WITH KEY vkorg = <fs_inforecord>-vkorg vtweg = <fs_inforecord>-vtweg kunnr = <fs_inforecord>-kunnr matnr = <fs_inforecord>-matnr.

        IF <fs_knmt> IS ASSIGNED.
          ls_yknmt-vkorg = <fs_knmt>-vkorg.
          ls_yknmt-vtweg = <fs_knmt>-vtweg.
          ls_yknmt-kunnr = <fs_knmt>-kunnr.
          ls_yknmt-matnr = <fs_knmt>-matnr.
          ls_yknmt-kdmat = <fs_knmt>-kdmat.
          ls_yknmt-postx = <fs_knmt>-postx.
          ls_yknmt-guid  = <fs_knmt>-guid.

          APPEND ls_yknmt TO lt_yknmt.
          CLEAR ls_yknmt.

          UNASSIGN: <fs_knmt>.
        ENDIF.

    ENDCASE.

    APPEND ls_xknmt TO lt_xknmt.
    CLEAR ls_xknmt.
  ENDLOOP.
  UNASSIGN: <fs_inforecord>.

  "Create and Modify inforecords routine
  lv_action = 'C'.
  PERFORM exec_inforecord TABLES lt_xknmt lt_yknmt USING lv_action.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_info
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GT_INFORECORD
*&---------------------------------------------------------------------*
FORM refresh_info USING p_gt_inforecord.
  IF gv_paso EQ 'X'.
    MESSAGE 'Please complete the upload you are performing before attempting to refresh the report.' TYPE 'W' DISPLAY LIKE 'E'.
  ELSE.
    PERFORM get_data.
    PERFORM display_alv.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form exec_inforecord
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LT_XKNMT
*&      --> LT_YKNMT
*&      --> LV_ACTION
*&---------------------------------------------------------------------*
FORM exec_inforecord  TABLES p_lt_xknmt STRUCTURE vknmt
                             p_lt_yknmt STRUCTURE vknmt
  USING p_lv_action TYPE c.

  DATA: lt_catalog TYPE TABLE OF tcatalog,
        lt_xknmta  TYPE TABLE OF vknmta,
        lt_yknmta  TYPE TABLE OF vknmta,
        ls_xknmta  TYPE vknmta,
        ls_yknmta  TYPE vknmta.

  CASE p_lv_action.
    WHEN 'D'.
      IF p_lt_xknmt[] IS NOT INITIAL.
        SELECT * FROM knmta
          FOR ALL ENTRIES IN @p_lt_xknmt
          WHERE guid EQ @p_lt_xknmt-guid
          INTO TABLE @DATA(lt_knmta).

        SORT lt_knmta ASCENDING BY guid.
        DELETE ADJACENT DUPLICATES FROM lt_knmta COMPARING guid.

        LOOP AT lt_knmta ASSIGNING FIELD-SYMBOL(<fs_knmta>).
          ls_xknmta-guid     = <fs_knmta>-guid.
          ls_xknmta-kdmat    = <fs_knmta>-kdmat.
          ls_xknmta-addpostx = <fs_knmta>-addpostx.
          ls_xknmta-kz       = p_lv_action.

          APPEND ls_xknmta TO lt_xknmta.
          CLEAR: ls_xknmta.
        ENDLOOP.
        UNASSIGN: <fs_knmta>.
      ENDIF.

      IF p_lt_yknmt[] IS NOT INITIAL.
        SELECT * FROM knmta
          FOR ALL ENTRIES IN @p_lt_yknmt
          WHERE guid EQ @p_lt_yknmt-guid
          INTO TABLE @lt_knmta.

        SORT lt_knmta ASCENDING BY guid.
        DELETE ADJACENT DUPLICATES FROM lt_knmta COMPARING guid.

        LOOP AT lt_knmta ASSIGNING <fs_knmta>.
          ls_yknmta-guid     = <fs_knmta>-guid.
          ls_yknmta-kdmat    = <fs_knmta>-kdmat.
          ls_yknmta-addpostx = <fs_knmta>-addpostx.
          ls_yknmta-kz       = p_lv_action.

          APPEND ls_yknmta TO lt_yknmta.
          CLEAR: ls_yknmta.
        ENDLOOP.
        UNASSIGN: <fs_knmta>.
      ENDIF.

      CALL FUNCTION 'RV_CUSTOMER_MATERIAL_UPDATE'
        TABLES
          xknmt_tab    = p_lt_xknmt
          yknmt_tab    = p_lt_yknmt
          tcatalog_tab = lt_catalog
          xknmta_tab   = lt_xknmta
          yknmta_tab   = lt_yknmta.

      IF sy-subrc EQ 0.
        PERFORM get_data.
        PERFORM display_alv.
      ENDIF.
    WHEN 'C'.
      LOOP AT p_lt_xknmt ASSIGNING FIELD-SYMBOL(<fs_xknmt>).
        CASE <fs_xknmt>-updkz.
          WHEN 'I'.
            ls_xknmta-mandt = sy-mandt.
            ls_xknmta-guid  = <fs_xknmt>-guid.
            ls_xknmta-kz  = <fs_xknmt>-updkz.

            READ TABLE gt_inforecord ASSIGNING FIELD-SYMBOL(<fs_info>) WITH KEY vkorg = <fs_xknmt>-vkorg vtweg = <fs_xknmt>-vtweg kunnr = <fs_xknmt>-kunnr matnr = <fs_xknmt>-matnr.
            IF <fs_info> IS ASSIGNED.
              ls_xknmta-kdmat    = <fs_info>-kdmat2.
              ls_xknmta-addpostx = <fs_info>-addpostx.
            ENDIF.
            APPEND ls_xknmta TO lt_xknmta.
            CLEAR: ls_xknmta.
          WHEN 'U'.
            SELECT * FROM knmta
              FOR ALL ENTRIES IN @p_lt_xknmt
              WHERE guid EQ @p_lt_xknmt-guid
              INTO TABLE @lt_knmta.

            READ TABLE lt_knmta ASSIGNING <fs_knmta> WITH KEY guid = <fs_xknmt>-guid.

            IF <fs_knmta> IS ASSIGNED.
              ls_xknmta-mandt = sy-mandt.
              ls_xknmta-guid  = <fs_xknmt>-guid.
              ls_xknmta-kz  = 'D'.
              ls_xknmta-kdmat    = <fs_knmta>-kdmat.
              ls_xknmta-addpostx = <fs_knmta>-addpostx.

              APPEND ls_xknmta TO lt_xknmta.
              CLEAR: ls_xknmta.
              UNASSIGN: <fs_knmta>.
            ENDIF.

            ls_xknmta-mandt = sy-mandt.
            ls_xknmta-guid  = <fs_xknmt>-guid.
            ls_xknmta-kz  = 'I'.

            READ TABLE gt_inforecord ASSIGNING <fs_info> WITH KEY vkorg = <fs_xknmt>-vkorg vtweg = <fs_xknmt>-vtweg kunnr = <fs_xknmt>-kunnr matnr = <fs_xknmt>-matnr.
            IF <fs_info> IS ASSIGNED.
              ls_xknmta-kdmat    = <fs_info>-kdmat2.
              ls_xknmta-addpostx = <fs_info>-addpostx.
            ENDIF.
            APPEND ls_xknmta TO lt_xknmta.
            CLEAR: ls_xknmta.
        ENDCASE.
      ENDLOOP.

      CALL FUNCTION 'RV_CUSTOMER_MATERIAL_UPDATE'
        TABLES
          xknmt_tab    = p_lt_xknmt
          yknmt_tab    = p_lt_yknmt
          tcatalog_tab = lt_catalog
          xknmta_tab   = lt_xknmta
          yknmta_tab   = lt_yknmta.

      IF sy-subrc EQ 0.
        gv_paso = ''.
        PERFORM get_data.
        PERFORM display_alv.
      ENDIF.
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form exit_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM exit_alv .

  DATA: lv_answer TYPE c LENGTH 1.

  IF gv_paso EQ 'X'.
    CALL FUNCTION 'FITP_POPUP_TO_CONFIRM'
      EXPORTING
        titlebar       = 'Please confirm the action'
        text_question  = 'An update is pending. Are you sure you want to exit the program?'
      IMPORTING
        answer         = lv_answer
      EXCEPTIONS
        text_not_found = 1
        OTHERS         = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDIF.

  IF lv_answer EQ 'J' OR gv_paso EQ ''.
    LEAVE PROGRAM.
  ENDIF.
ENDFORM.
