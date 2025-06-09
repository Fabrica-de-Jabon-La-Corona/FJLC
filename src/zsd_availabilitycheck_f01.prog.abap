*&---------------------------------------------------------------------*
*& Include          ZSD_AVAILABILITYCHECK_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form get_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_data .

  DATA: lv_message TYPE string,
        lt_wmdvsx  TYPE TABLE OF bapiwmdvs,
        lt_wmdvex  TYPE TABLE OF bapiwmdve,
        lv_matnr   TYPE matnr18,
        lv_qtyumv  TYPE fkimg.

  "Verifica autorización para centro.
  AUTHORITY-CHECK OBJECT 'M_BEST_WRK'
      ID 'WERKS' FIELD pa_werks-low
      ID 'ACTVT' FIELD '03'.

  IF sy-subrc NE 0.
    CONCATENATE 'No posee autorización para ver inforación del centro:' pa_werks INTO lv_message SEPARATED BY space.
    MESSAGE lv_message TYPE 'E' DISPLAY LIKE 'E'.
  ENDIF.

  IF pa_vtweg EQ ''.
    pa_vtweg = '01'.
  ENDIF.

  SELECT SINGLE atinn INTO @DATA(lv_atinn)
    FROM cabn
    WHERE atnam EQ 'TIPO_DISTRIBUCION'.

  SELECT FROM mard AS md
    LEFT JOIN mara AS ma ON ma~matnr EQ md~matnr
    LEFT JOIN mvke AS mv ON mv~matnr EQ md~matnr
    LEFT JOIN mchb AS mh ON mh~matnr EQ md~matnr AND mh~werks EQ md~werks AND mh~lgort EQ md~lgort
    LEFT JOIN mch1 AS mc ON mc~matnr EQ md~matnr AND mc~charg EQ mh~charg
    "LEFT JOIN ausp AS au ON au~objek EQ mc~cuobj_bm
    LEFT JOIN makt AS mk ON mk~matnr EQ md~matnr
    LEFT JOIN t001w AS tw ON tw~werks EQ md~werks
    LEFT JOIN t001l AS tl ON tl~werks EQ md~werks AND tl~lgort EQ md~lgort
    FIELDS md~matnr, mk~maktx, md~werks, tw~name1, md~lgort, tl~lgobe, mh~charg, ma~meins, mv~vrkme, mc~cuobj_bm, mh~clabs", au~atwrt
    WHERE md~matnr IN @pa_matnr
    AND md~werks IN @pa_werks
    AND md~lgort IN @pa_lgort
    AND mh~charg IN @pa_charg
    AND mk~spras EQ 'S'
    AND mv~vkorg EQ '1000'
    AND mv~vtweg EQ @pa_vtweg
    "AND au~atinn EQ @lv_atinn
    "AND au~mafid EQ 'O'
    "AND au~klart EQ '023'
    INTO TABLE @DATA(lt_mard).

  SORT lt_mard ASCENDING BY matnr charg.
  DELETE ADJACENT DUPLICATES FROM lt_mard COMPARING matnr werks lgort charg.

  IF p_stock EQ 'X'.
    DELETE lt_mard WHERE clabs LE 0.
  ENDIF.

  LOOP AT lt_mard ASSIGNING FIELD-SYMBOL(<fs_mard>).

    lv_matnr = <fs_mard>-matnr.

    CALL FUNCTION 'BAPI_MATERIAL_AVAILABILITY'
      EXPORTING
        plant      = <fs_mard>-werks
        material   = lv_matnr
        unit       = 'PZA'
        check_rule = 'B'
        stge_loc   = <fs_mard>-lgort
        batch      = <fs_mard>-charg
      TABLES
        wmdvsx     = lt_wmdvsx
        wmdvex     = lt_wmdvex.

    READ TABLE lt_wmdvex ASSIGNING FIELD-SYMBOL(<fs_wmdevx>) INDEX 1.

    IF <fs_wmdevx> IS ASSIGNED.
      IF <fs_wmdevx>-com_qty GT 0.
        gs_dispo-qtumb = <fs_wmdevx>-com_qty.

        IF <fs_mard>-vrkme EQ ''.
          <fs_mard>-vrkme = <fs_mard>-meins.
        ENDIF.

        CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
          EXPORTING
            i_matnr              = <fs_mard>-matnr
            i_in_me              = <fs_mard>-meins
            i_out_me             = <fs_mard>-vrkme
            i_menge              = <fs_wmdevx>-com_qty
          IMPORTING
            e_menge              = lv_qtyumv
          EXCEPTIONS
            error_in_application = 1
            error                = 2
            OTHERS               = 3.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

        lv_qtyumv = round( val = lv_qtyumv dec = 0 ).
        UNASSIGN: <fs_wmdevx>.
        "ENDIF.
        "ENDIF.

        gs_dispo-matnr = <fs_mard>-matnr.
        gs_dispo-maktx = <fs_mard>-maktx.
        gs_dispo-werks = <fs_mard>-werks.
        gs_dispo-name1 = <fs_mard>-name1.
        gs_dispo-lgort = <fs_mard>-lgort.
        gs_dispo-lgobe = <fs_mard>-lgobe.
        gs_dispo-charg = <fs_mard>-charg.
        "gs_dispo-comer =
        "gs_dispo-comed =
        gs_dispo-umb   = <fs_mard>-meins.
        gs_dispo-qtumv = lv_qtyumv.
        gs_dispo-umv   = <fs_mard>-vrkme.

        APPEND gs_dispo TO gt_dispo.
        CLEAR: lv_matnr, lv_qtyumv, gs_dispo.
      ENDIF.
    ENDIF.
  ENDLOOP.

  IF p_stock EQ 'X'.
    DELETE gt_dispo WHERE qtumb LE 0.
  ENDIF.
  UNASSIGN: <fs_mard>.

ENDFORM.

*&---------------------------------------------------------------------*
*& CLASS cl_handler
*&---------------------------------------------------------------------*
CLASS cl_handler DEFINITION.
  PUBLIC SECTION.
    METHODS on_double_click FOR EVENT double_click OF cl_salv_events_table
      IMPORTING row column.
ENDCLASS.

CLASS cl_handler IMPLEMENTATION.
  METHOD on_double_click.
*   Obtenemos la informacion de esa linea
    READ TABLE gt_dispo INTO DATA(wa_st_data) INDEX row.
    CHECK sy-subrc = 0.
    CASE column.
      WHEN 'MATNR'.
        SET PARAMETER ID 'MAT' FIELD wa_st_data-matnr.
        SET PARAMETER ID 'WRK' FIELD wa_st_data-werks.
        SET PARAMETER ID 'PRR' FIELD 'B'.
        CALL TRANSACTION 'CO09' AND SKIP FIRST SCREEN.
    ENDCASE.

  ENDMETHOD.
ENDCLASS.

*&---------------------------------------------------------------------*
*& Form display_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv .
  DATA: lo_gr_alv        TYPE REF TO cl_salv_table,             " Variable para propiedades ALV
        lo_gr_functions  TYPE REF TO cl_salv_functions_list,
        lo_event_handler TYPE REF TO cl_handler,                " Variables para eventos
        lo_events        TYPE REF TO cl_salv_events_table,
        lo_display       TYPE REF TO cl_salv_display_settings,  " Variable para layout settings
        lo_selections    TYPE REF TO cl_salv_selections,        " Variables para modo de seleccion y propiedades de la columna
        lo_columns       TYPE REF TO cl_salv_columns,
        lo_columns2      TYPE REF TO cl_salv_columns_table,
        lo_column        TYPE REF TO cl_salv_column_table,
        lo_column2       TYPE REF TO cl_salv_column,
        ref_alv_table    TYPE REF TO gty_dispo,
        cx_salv          TYPE REF TO cx_salv_msg,
        cx_not_found     TYPE REF TO cx_salv_not_found,
        lo_gr_layout     TYPE REF TO cl_salv_layout,
        key              TYPE salv_s_layout_key,
        gr_msg           TYPE string,
        lo_grid          TYPE REF TO cl_salv_form_layout_grid, " Variables for header
        lo_layout_logo   TYPE REF TO cl_salv_form_layout_logo,
        lo_content       TYPE REF TO cl_salv_form_element,
        lv_title         TYPE string,
        lv_rows          TYPE string.

  IF sy-subrc <> 0.
*   MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*     WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

* Creacion ALV object
  TRY.
      CALL METHOD cl_salv_table=>factory(
        EXPORTING
*         r_container    = lo_container
          container_name = 'CONTAINER'
        IMPORTING
          r_salv_table   = lo_gr_alv
        CHANGING
          t_table        = gt_dispo ).
    CATCH cx_salv_msg.
  ENDTRY.

*Se muestran todos los botones del ALV (modificar, grabar, seleccionar layout).
  lo_gr_layout = lo_gr_alv->get_layout( ).
  key-report = sy-repid.
  lo_gr_layout->set_key( key ).

  lo_gr_layout->set_save_restriction( if_salv_c_layout=>restrict_none ).
  lo_gr_layout->set_save_restriction( ).
  lo_gr_layout->set_initial_layout( p_layout ).

*Mostramos los botones ALV
  lo_gr_functions = lo_gr_alv->get_functions( ).
  lo_gr_functions->set_all( abap_true ).

  TRY.
* Optimize
      lo_columns = lo_gr_alv->get_columns( ).
      lo_columns->set_optimize( 'X' ).
*Cambiamos descripción de columna COMER (Tipo de comercialización).
      lo_column ?= lo_columns->get_column( columnname = 'COMER' ).
      lo_column->set_short_text( 'Tp.Com' ).
      lo_column->set_medium_text( 'Tipo Comerc.' ).
      lo_column->set_long_text( 'Tipo de Comercialización' ).
      lo_column->set_visible( abap_false ).          "Columna no visible en el layout estándar

*Cambiamos descripción de columna COMED (Descripción del tipo de comercialización).
      lo_column ?= lo_columns->get_column( columnname = 'COMED' ).
      lo_column->set_short_text( 'Desc.' ).
      lo_column->set_medium_text( 'Desc.' ).
      lo_column->set_long_text( 'Descripción' ).
      lo_column->set_visible( abap_false ).          "Columna no visible en el layout estándar

*Colocamos columnas pedido, entrega, factura Y punto GPS como HotSpot.
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
  lo_columns->set_column_position( columnname = 'MATNR'  position = 1 ).  "Material
  lo_columns->set_column_position( columnname = 'MAKTX'  position = 2 ).  "Descripción del material
  lo_columns->set_column_position( columnname = 'WERKS'  position = 3 ).  "Centro
  lo_columns->set_column_position( columnname = 'NAME1'  position = 4 ).  "Nombre del centro
  lo_columns->set_column_position( columnname = 'LGORT'  position = 5 ).  "Almacén
  lo_columns->set_column_position( columnname = 'LGOBE'  position = 6 ).  "Descripción de almacén
  lo_columns->set_column_position( columnname = 'CHARG'  position = 7 ).  "Lote
  lo_columns->set_column_position( columnname = 'COMER'  position = 8 ).  "Comercialización
  lo_columns->set_column_position( columnname = 'COMED'  position = 9 ).  "Desripción de comercialización
  lo_columns->set_column_position( columnname = 'QTUMB'  position = 10 ). "Cantidad en UMB
  lo_columns->set_column_position( columnname = 'UMB'    position = 11 ). "Unidad de medida base
  lo_columns->set_column_position( columnname = 'QTUMV'  position = 12 ). "Cantidad en UMV
  lo_columns->set_column_position( columnname = 'UMV'    position = 13 ). "Unidad de medida de venta

* Create header
  DESCRIBE TABLE gt_dispo LINES lv_rows.

  CREATE OBJECT lo_grid.
  CREATE OBJECT lo_layout_logo.

  CONCATENATE 'Usuario: ' sy-uname INTO lv_title SEPARATED BY space.
  lo_grid->create_label( row = 1 column = 1 text = lv_title tooltip = lv_title ).
  CLEAR: lv_title.

  CONCATENATE sy-datum+6(2) '.' sy-datum+4(2) '.' sy-datum(4) INTO DATA(lv_fecha).
  CONCATENATE 'Fecha:' lv_fecha INTO lv_title SEPARATED BY space.
  lo_grid->create_label( row = 2 column = 1 text = lv_title tooltip = lv_title ).
  CLEAR: lv_title.

  CONCATENATE sy-uzeit(2) ':' sy-uzeit+2(2) ':' sy-uzeit+4(2) INTO DATA(lv_hora).
  CONCATENATE 'Hora:' lv_hora INTO lv_title SEPARATED BY space.
  lo_grid->create_label( row = 3 column = 1 text = lv_title tooltip = lv_title ).
  CLEAR: lv_title.

  CONCATENATE 'Cantidad de registros: ' lv_rows INTO lv_title SEPARATED BY space.
  lo_grid->create_label( row = 6 column = 1 text = lv_title tooltip = lv_title ).
  CLEAR: lv_title.

  lo_layout_logo->set_left_content( lo_grid ).
  lo_layout_logo->set_right_logo( 'ZLOGO_FJLC_COLOR' ).
  lo_content = lo_layout_logo.
  lo_gr_alv->set_top_of_list( lo_content ).

* Aplicando estilo zebra
  lo_display = lo_gr_alv->get_display_settings( ).
  lo_display->set_striped_pattern( cl_salv_display_settings=>true ).

* Eventos
  lo_events = lo_gr_alv->get_event( ).
  CREATE OBJECT lo_event_handler.
  SET HANDLER lo_event_handler->on_double_click FOR lo_events.

* Enable cell selection mode
  lo_selections = lo_gr_alv->get_selections( ).
  lo_selections->set_selection_mode( if_salv_c_selection_mode=>row_column ).

  lo_gr_alv->display( ).

  IF sy-subrc <> 0.
    MESSAGE 'ERROR AL MOSTRAR LISTADO' TYPE 'X'.
  ENDIF.
ENDFORM.
