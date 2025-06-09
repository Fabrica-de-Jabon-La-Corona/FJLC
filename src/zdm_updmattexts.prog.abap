*&---------------------------------------------------------------------*
*& Report ZDM_UPDMATTEXTS
*&---------------------------------------------------------------------*
*& Autor: Carlos Armando Olivas Gudiño
*& Fecha creación: 31.05.2024
*& Descr: Programa para carga masiva de textos comerciales en maestro
*& de materiales
*& Orden de Transporte: S4DK907034
*&---------------------------------------------------------------------*
REPORT zdm_updmattexts.

TYPES:
  BEGIN OF ls_textomatnr,
    material TYPE c LENGTH 18,
    idioma   TYPE spras,
    texto    TYPE string,
    texto1   TYPE c LENGTH 50,
    texto2   TYPE c LENGTH 50,
    texto3   TYPE c LENGTH 50,
    textoant TYPE string,
    orgvta   TYPE vkorg,
    canal    TYPE vtweg,
    result   TYPE string,
  END OF ls_textomatnr.
TYPES:
  lt_textomatnr TYPE STANDARD TABLE OF ls_textomatnr.

DATA: lt_arch      TYPE STANDARD TABLE OF alsmex_tabline,
      ls_arch      TYPE alsmex_tabline,
      lt_texto     TYPE lt_textomatnr,
      ls_texto     TYPE ls_textomatnr,
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
      g_exit       TYPE c.

CONSTANTS: lc_object  TYPE tdobject VALUE 'MVKE',
           gc_refresh TYPE syucomm VALUE '&REFRESH',
           c_x        TYPE c LENGTH 1 VALUE 'X',
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

  fieldcatalog-fieldname   = 'MATERIAL'.
  fieldcatalog-seltext_m   = 'Material'.
  fieldcatalog-col_pos     = 0.
  fieldcatalog-outputlen   = 18.
  fieldcatalog-key         = 'X'.
  fieldcatalog-hotspot     = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'ORGVTA'.
  fieldcatalog-seltext_m   = 'Org.Vtas.'.
  fieldcatalog-col_pos     = 1.
  fieldcatalog-outputlen   = 4.
  fieldcatalog-key         = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'CANAL'.
  fieldcatalog-seltext_m   = 'Canal'.
  fieldcatalog-col_pos     = 2.
  fieldcatalog-outputlen   = 2.
  fieldcatalog-key         = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'IDIOMA'.
  fieldcatalog-seltext_m   = 'Idioma'.
  fieldcatalog-col_pos     = 3.
  fieldcatalog-outputlen   = 1.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'TEXTOANT'.
  fieldcatalog-seltext_m   = 'Texto Anterior'.
  fieldcatalog-col_pos     = 4.
  fieldcatalog-outputlen   = 100.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'TEXTO'.
  fieldcatalog-seltext_m   = 'Texto Nuevo'.
  fieldcatalog-col_pos     = 5.
  fieldcatalog-outputlen   = 100.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.

  fieldcatalog-fieldname   = 'RESULT'.
  fieldcatalog-seltext_m   = 'Resultado'.
  fieldcatalog-col_pos     = 6.
  fieldcatalog-outputlen   = 50.
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
      t_outtab                 = lt_texto
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
        ls_texto-material = |{ ls_arch-value ALPHA = IN }|.
      WHEN 2.
        MOVE ls_arch-value TO ls_texto-idioma.
      WHEN 3.
        MOVE ls_arch-value TO ls_texto-texto1.
      WHEN 4.
        MOVE ls_arch-value TO ls_texto-texto2.
      WHEN 5.
        MOVE ls_arch-value TO ls_texto-texto3.
      WHEN 6.
        MOVE ls_arch-value TO ls_texto-orgvta.
      WHEN 7.
        MOVE ls_arch-value TO ls_texto-canal.
    ENDCASE.

    AT END OF row.
      APPEND ls_texto TO lt_texto.
      CLEAR: ls_texto.
    ENDAT.
    CLEAR: ls_arch, lv_matnr40.
  ENDLOOP.

  SORT lt_texto ASCENDING BY material.

*Manipulación de los datos del excel ya cargados y ordenados en la tabla interna.
  LOOP AT lt_texto INTO ls_texto.

    SELECT * FROM mvke
      WHERE matnr EQ @ls_texto-material
      AND vkorg EQ @ls_texto-orgvta
      AND vtweg EQ @ls_texto-canal
      INTO TABLE @DATA(lt_mvke).

    IF sy-subrc EQ 0.

      lv_matnr40 = ls_texto-material.
      CONCATENATE lv_matnr40 ls_texto-orgvta ls_texto-canal INTO lv_tdname RESPECTING BLANKS.

      SELECT * FROM stxl
        WHERE tdobject EQ 'MVKE'
        AND tdid EQ '0001'
        AND tdspras EQ @ls_texto-idioma
        AND tdname EQ @lv_tdname
        INTO TABLE @DATA(lt_stxl).

      IF sy-subrc EQ 0.
        CALL FUNCTION 'READ_TEXT'
          EXPORTING
            client   = sy-mandt
            id       = '0001'
            language = ls_texto-idioma
            name     = lv_tdname
            object   = 'MVKE'
          TABLES
            lines    = lt_linesread.

        IF sy-subrc EQ 0.
          LOOP AT lt_linesread INTO ls_linesread.
            CONCATENATE ls_linesread-tdline ' ' INTO ls_texto-textoant RESPECTING BLANKS.
          ENDLOOP.
        ENDIF.
      ENDIF.

      CONCATENATE ls_texto-texto1 ls_texto-texto2 ls_texto-texto3 INTO ls_texto-texto SEPARATED BY space.
      CONDENSE ls_texto-texto.

      ls_lines-tdline = ls_texto-texto.
      APPEND ls_lines TO lt_lines.
      CLEAR: ls_lines.

      CALL FUNCTION 'CREATE_TEXT'
        EXPORTING
          fid         = lc_id
          flanguage   = ls_texto-idioma
          fname       = lv_tdname
          fobject     = lc_object
          save_direct = 'X'
          fformat     = '*'
        TABLES
          flines      = lt_lines.

      IF sy-subrc EQ 0.
        ls_texto-result = 'El texto se actualizó correctamente'.
      ENDIF.

      MODIFY lt_texto FROM ls_texto.

    ELSEIF sy-subrc NE 0.
      ls_texto-texto = ''.
      DATA(lv_matout) = |{ ls_texto-material ALPHA = OUT }|.
      CONDENSE lv_matout NO-GAPS.
      CONCATENATE 'No existe el material' lv_matout 'en la org. de ventas' ls_texto-orgvta 'y el canal' ls_texto-canal INTO ls_texto-result SEPARATED BY space.
      MODIFY lt_texto FROM ls_texto.
    ENDIF.
    CLEAR: lt_lines, lt_mvke, lt_stxl, ls_texto, ls_lines.
  ENDLOOP.
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
      IF rs_selfield-fieldname EQ 'MATERIAL'.
        READ TABLE lt_texto INTO ls_texto WITH KEY material = rs_selfield-value.
        SET PARAMETER ID 'MAT' FIELD ls_texto-material.
        SET PARAMETER ID 'WRK' FIELD 'CXAL'.
        SET PARAMETER ID 'VKO' FIELD ls_texto-orgvta.
        SET PARAMETER ID 'VTW' FIELD ls_texto-canal.
        CALL TRANSACTION 'MM03' AND SKIP FIRST SCREEN.
      ENDIF.
  ENDCASE.

ENDFORM.                    " USER_COMMAND
