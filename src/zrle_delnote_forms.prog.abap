*----------------------------------------------------------------------*
***INCLUDE RLE_DELNOTE_FORMS .
*----------------------------------------------------------------------*
*---------------------------------------------------------------------*
*       FORM GET_DATA                                                 *
*---------------------------------------------------------------------*
*       General provision of data for the form                        *
*---------------------------------------------------------------------*
FORM get_data
     TABLES   ct_item_data          TYPE zsd_tt_delivery_note
     USING    is_print_data_to_read TYPE ledlv_print_data_to_read
     CHANGING cs_addr_key           LIKE addr_key
              cs_dlv_delnote        TYPE ledlv_delnote
              cv_totaltax           TYPE kwert
              cv_discount           TYPE kwert
              cv_total              TYPE kwert
              cv_subtotal           TYPE kwert
              cv_doc_number         TYPE vbeln
              cv_po_number          TYPE bstkd
              cv_so_date            TYPE audat
              cv_name1_ag           TYPE name1
              cv_name2_ag           TYPE name2
              cv_housenum_ag        TYPE ad_hsnm1
              cv_street_ag          TYPE ad_street
              cv_city_ag            TYPE ad_city1
              cv_city2_ag           TYPE ad_city2
              cv_regio_ag           TYPE regio
              cv_postl_ag           TYPE ad_pstcd1
              cv_land_ag            TYPE land1
              cv_name1_we           TYPE name1
              cv_name2_we           TYPE name2
              cv_housenum_we        TYPE ad_hsnm1
              cv_street_we          TYPE ad_street
              cv_city_we            TYPE ad_city1
              cv_city2_we           TYPE ad_city2
              cv_regio_we           TYPE regio
              cv_postl_we           TYPE ad_pstcd1
              cv_land_we            TYPE land1
              cv_terms              TYPE vtext
              cv_observ             TYPE string
              cv_waerk              TYPE waerk
              cv_numviaje           TYPE string
              cv_canttotal          TYPE lfimg
              cv_nickname           TYPE nickname
              cf_retcode.

  DATA: ls_delivery_key TYPE  leshp_delivery_key.
  ls_delivery_key-vbeln = nast-objky.

  CALL FUNCTION 'LE_SHP_DLV_OUTP_READ_PRTDATA'
    EXPORTING
      is_delivery_key       = ls_delivery_key
      is_print_data_to_read = is_print_data_to_read
      if_parvw              = nast-parvw
      if_parnr              = nast-parnr
      if_language           = nast-spras
    IMPORTING
      es_dlv_delnote        = cs_dlv_delnote
    EXCEPTIONS
      records_not_found     = 1
      records_not_requested = 2
      OTHERS                = 3.
  IF sy-subrc <> 0.
*  error handling
    cf_retcode = sy-subrc.
    PERFORM protocol_update.
  ENDIF.

* get nast partner adress for communication strategy
  PERFORM get_addr_key USING    cs_dlv_delnote-hd_adr
                       CHANGING cs_addr_key.

* get header data
  PERFORM get_header_data USING cs_dlv_delnote-hd_gen
                                cs_dlv_delnote-hd_adr
                          CHANGING cv_doc_number
                                   cv_po_number
                                   cv_so_date
                                   cv_name1_ag
                                   cv_name2_ag
                                   cv_housenum_ag
                                   cv_street_ag
                                   cv_city_ag
                                   cv_city2_ag
                                   cv_regio_ag
                                   cv_postl_ag
                                   cv_land_ag
                                   cv_name1_we
                                   cv_name2_we
                                   cv_housenum_we
                                   cv_street_we
                                   cv_city_we
                                   cv_city2_we
                                   cv_regio_we
                                   cv_postl_we
                                   cv_land_we
                                   cv_terms
                                   cv_observ
                                   cv_waerk
                                   cv_numviaje
                                   cv_nickname.


* get items data.
  PERFORM get_items_data TABLES ct_item_data
                         USING  cs_dlv_delnote-hd_gen
                         CHANGING cv_totaltax
                                  cv_subtotal
                                  cv_total
                                  cv_discount
                                  cv_canttotal.

ENDFORM.
*---------------------------------------------------------------------*
*       FORM SET_PRINT_DATA_TO_READ                                   *
*---------------------------------------------------------------------*
*       General provision of data for the form                        *
*---------------------------------------------------------------------*
FORM set_print_data_to_read
         USING    if_formname LIKE tnapr-sform
         CHANGING cs_print_data_to_read TYPE ledlv_print_data_to_read
                  cf_retcode.

  FIELD-SYMBOLS: <fs_print_data_to_read> TYPE xfeld.
  DATA: lt_fieldlist TYPE tsffields.
  DATA: ls_fieldlist TYPE LINE OF tsffields.
  DATA: lf_field1 TYPE LINE OF tsffields.
  DATA: lf_field2 TYPE LINE OF tsffields.
  DATA: lf_field3 TYPE LINE OF tsffields.

  CALL FUNCTION 'SSF_FIELD_LIST'
    EXPORTING
      formname           = if_formname
*     VARIANT            = ' '
    IMPORTING
      fieldlist          = lt_fieldlist
    EXCEPTIONS
      no_form            = 1
      no_function_module = 2
      OTHERS             = 3.
  IF sy-subrc <> 0.
*  error handling
    cf_retcode = sy-subrc.
    PERFORM protocol_update.
    CLEAR lt_fieldlist.
  ELSE.
* set print data requirements
    LOOP AT lt_fieldlist INTO ls_fieldlist.
      SPLIT ls_fieldlist AT '-' INTO lf_field1 lf_field2 lf_field3.
* <<<< START_OF_INSERTION_HP_350342 >>>>
      IF lf_field1 = 'IS_DLV_DELNOTE' AND lf_field2 = 'IT_SERNR'.
        lf_field2 = 'IT_SERNO'.
      ENDIF.
* <<<< END_OF_INSERTION_HP_350342 >>>>
      ASSIGN COMPONENT lf_field2 OF STRUCTURE
                       cs_print_data_to_read TO <fs_print_data_to_read>.
      IF sy-subrc = 0.
        <fs_print_data_to_read> = 'X'.
      ENDIF.
    ENDLOOP.

* header data is always required
    cs_print_data_to_read-hd_gen = 'X'.
* adress is always required for print param
    cs_print_data_to_read-hd_adr = 'X'.
* organisational data is always required for include texts
    cs_print_data_to_read-hd_org = 'X'.
*organisational data address is always required       "n_520906
    cs_print_data_to_read-hd_org_adr  = 'X'.                "n_520906

  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  get_addr_key
*&---------------------------------------------------------------------*
FORM get_addr_key USING    it_hd_adr   TYPE ledlv_delnote-hd_adr
                  CHANGING cs_addr_key LIKE addr_key.

  FIELD-SYMBOLS <fs_hd_adr> TYPE LINE OF ledlv_delnote-hd_adr.

  READ TABLE it_hd_adr ASSIGNING <fs_hd_adr>
                       WITH KEY deliv_numb = nast-objky
                                partn_role = nast-parvw.
  IF sy-subrc = 0.
    cs_addr_key-addrnumber = <fs_hd_adr>-addr_no.
    cs_addr_key-persnumber = <fs_hd_adr>-person_numb.
    cs_addr_key-addr_type  = <fs_hd_adr>-address_type.
  ENDIF.

ENDFORM.                               " get_addr_key
*&---------------------------------------------------------------------*
*& Form get_items_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> CS_DLV_DELNOTE_HD_GEN
*&      <-- CT_ITEM_DATA
*&---------------------------------------------------------------------*
FORM get_items_data  TABLES   ct_item_data          TYPE zsd_tt_delivery_note
                     USING    it_hd_gen   TYPE ledlv_delnote-hd_gen
                     CHANGING cv_totaltax
                              cv_subtotal
                              cv_total
                              cv_discount
                              cv_canttotal.

  DATA: ls_item_data TYPE zsd_st_delivery_notes,
        lv_posant    TYPE kposn.

  SELECT * FROM lips
    WHERE vbeln = @it_hd_gen-deliv_numb
    INTO TABLE @DATA(lt_lips).

  READ TABLE lt_lips ASSIGNING FIELD-SYMBOL(<fs_lips>) INDEX 1.

  IF <fs_lips> IS ASSIGNED.
    IF <fs_lips>-vgbel NE ''.
      SELECT * FROM vbak
        WHERE vbeln = @<fs_lips>-vgbel
        INTO TABLE @DATA(lt_vbak).
    ENDIF.
  ENDIF.

  READ TABLE lt_vbak ASSIGNING FIELD-SYMBOL(<fs_vbak>) WITH KEY vbeln = <fs_lips>-vgbel.
  IF <fs_vbak> IS ASSIGNED.
    SELECT * FROM prcd_elements
      WHERE knumv = @<fs_vbak>-knumv
      INTO TABLE @DATA(lt_prcd).
    UNASSIGN: <fs_vbak>.
  ENDIF.

  LOOP AT lt_lips ASSIGNING <fs_lips> WHERE vbeln = it_hd_gen-deliv_numb AND uecha = ''.
    ls_item_data-kposn = <fs_lips>-posnr.
    ls_item_data-matnr = <fs_lips>-matnr.
    ls_item_data-arktx = <fs_lips>-arktx.
    ls_item_data-prodh = <fs_lips>-prodh.        "Se añade jerarquía

    LOOP AT lt_lips ASSIGNING FIELD-SYMBOL(<fs_batch>) WHERE ( pstyv = 'ZCCU' OR pstyv = 'ZB99' ) AND uecha = <fs_lips>-posnr.
      ls_item_data-lfimg = ls_item_data-lfimg + <fs_batch>-lfimg.
    ENDLOOP.
    UNASSIGN <fs_batch>.

    IF ls_item_data-lfimg EQ '0.000' OR ls_item_data-lfimg EQ ''.
      ls_item_data-lfimg = <fs_lips>-lfimg.
    ENDIF.
    ls_item_data-vrkme = <fs_lips>-vrkme.

    "Determinación de precio unitario.
    "Se valida que las cadenas 175 y 331 (Lecaroz y Esperanza) no consulten precio para enviar en ceros la nota de entreg.
    IF <fs_lips>-kvgr1 EQ '175' OR <fs_lips>-kvgr1 EQ '331'.
      ls_item_data-netpr = '0.00'.
      ls_item_data-waerk = 'MXN'.
      ls_item_data-kwipt = '0.00'.
      ls_item_data-kwdto = '0.00'.
    ELSE.
      READ TABLE lt_prcd ASSIGNING FIELD-SYMBOL(<fs_prcd>) WITH KEY kposn = <fs_lips>-vgpos koaid = 'B' kstat = ''.
      IF <fs_prcd> IS ASSIGNED.
        ls_item_data-netpr = <fs_prcd>-kbetr.
        ls_item_data-waerk = <fs_prcd>-waers.
        UNASSIGN <fs_prcd>.
      ENDIF.

      "Determinación de Impuesto
      READ TABLE lt_prcd ASSIGNING <fs_prcd> WITH KEY kposn = <fs_lips>-vgpos koaid = 'D' kstat = ''.
      IF <fs_prcd> IS ASSIGNED.
        ls_item_data-kwipt = <fs_prcd>-kwert.
        UNASSIGN <fs_prcd>.
      ENDIF.

      "Determinación de descuentos
      LOOP AT lt_prcd ASSIGNING <fs_prcd> WHERE kposn = <fs_lips>-vgpos AND koaid = 'A' AND kstat = ''.
        ls_item_data-kwdto = ls_item_data-kwdto + abs( <fs_prcd>-kwert ).
      ENDLOOP.
      UNASSIGN <fs_prcd>.
    ENDIF.

    ls_item_data-netwr = ( ls_item_data-lfimg * ls_item_data-netpr ) + ls_item_data-kwipt - ls_item_data-kwdto.
    cv_subtotal  = cv_subtotal + ( ls_item_data-lfimg * ls_item_data-netpr ).
    cv_discount  = cv_discount + ls_item_data-kwdto.
    cv_totaltax  = cv_totaltax + ls_item_data-kwipt.
    cv_total     = cv_total + ls_item_data-netwr.
    cv_canttotal = cv_canttotal + ls_item_data-lfimg.

    APPEND ls_item_data TO ct_item_data.
    SORT ct_item_data ASCENDING BY prodh matnr.
    CLEAR ls_item_data.
  ENDLOOP.
  UNASSIGN: <fs_lips>.

  "Recalcula el número de posición.
  LOOP AT ct_item_data ASSIGNING FIELD-SYMBOL(<fs_item_data>).
    IF sy-tabix EQ 1.
      lv_posant = '10'.
      <fs_item_data>-kposn = lv_posant.
    ELSE.
      lv_posant = lv_posant + 10.
      <fs_item_data>-kposn = lv_posant.
    ENDIF.
    MODIFY ct_item_data FROM <fs_item_data>.
  ENDLOOP.
  UNASSIGN: <fs_item_data>.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_header_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> CS_DLV_DELNOTE_HD_GEN
*&---------------------------------------------------------------------*
FORM get_header_data  USING  it_hd_gen   TYPE ledlv_delnote-hd_gen
                             it_hd_adr   TYPE ledlv_delnote-hd_adr
                      CHANGING cv_doc_number         TYPE vbeln
                               cv_po_number          TYPE bstkd
                               cv_so_date            TYPE audat
                               cv_name1_ag           TYPE name1
                               cv_name2_ag           TYPE name2
                               cv_housenum_ag        TYPE ad_hsnm1
                               cv_street_ag          TYPE ad_street
                               cv_city_ag            TYPE ad_city1
                               cv_city2_ag           TYPE ad_city2
                               cv_regio_ag           TYPE regio
                               cv_postl_ag           TYPE ad_pstcd1
                               cv_land_ag            TYPE land1
                               cv_name1_we           TYPE name1
                               cv_name2_we           TYPE name2
                               cv_housenum_we        TYPE ad_hsnm1
                               cv_street_we          TYPE ad_street
                               cv_city_we            TYPE ad_city1
                               cv_city2_we           TYPE ad_city2
                               cv_regio_we           TYPE regio
                               cv_postl_we           TYPE ad_pstcd1
                               cv_land_we            TYPE land1
                               cv_terms              TYPE vtext
                               cv_observ             TYPE string
                               cv_waerk              TYPE waerk
                               cv_numviaje           TYPE string
                               cv_nickname           TYPE nickname.

  DATA: lt_lines TYPE TABLE OF tline.

  SELECT SINGLE FROM tvsbt
    FIELDS vtext
    WHERE vsbed = @it_hd_gen-ship_cond
    AND spras = 'S'
    INTO @cv_terms.

*Obtiene número de viaje*

  DATA lv_base TYPE /scmtms/base_btd_id.

  lv_base = |{ it_hd_gen-deliv_numb ALPHA = IN }|.

  SELECT SINGLE th~tor_id INTO @cv_numviaje
    FROM /scmtms/d_torrot AS th
    INNER JOIN /scmtms/d_torite AS ti ON th~db_key = ti~parent_key
    WHERE ti~base_btd_id = @lv_base
    AND th~tor_cat = 'TO'
    AND th~lifecycle NE '10'
    AND ti~item_type = 'PRD'.

  cv_numviaje = |{ cv_numviaje ALPHA = OUT }|.

  SELECT * FROM lips
    WHERE vbeln = @it_hd_gen-deliv_numb
    INTO TABLE @DATA(lt_lips).

  READ TABLE lt_lips ASSIGNING FIELD-SYMBOL(<fs_lips>) INDEX 1.

  IF <fs_lips> IS ASSIGNED.
    IF <fs_lips>-vgbel NE ''.
      SELECT * FROM vbak
        WHERE vbeln = @<fs_lips>-vgbel
        INTO TABLE @DATA(lt_vbak).

      IF NOT lt_vbak[] IS INITIAL.
        SELECT * FROM vbkd
          FOR ALL ENTRIES IN @lt_vbak
          WHERE vbeln = @lt_vbak-vbeln
          INTO TABLE @DATA(lt_vbkd).
      ENDIF.
    ENDIF.
  ENDIF.

  READ TABLE lt_vbak ASSIGNING FIELD-SYMBOL(<fs_vbak>) WITH KEY vbeln = <fs_lips>-vgbel.

  IF <fs_vbak> IS ASSIGNED.

    cv_doc_number = <fs_vbak>-vbeln.
    cv_so_date    = <fs_vbak>-audat.
    cv_waerk      = <fs_vbak>-waerk.

    READ TABLE lt_vbkd ASSIGNING FIELD-SYMBOL(<fs_vbkd>) WITH KEY vbeln = <fs_vbak>-vbeln.

    IF <fs_vbkd> IS ASSIGNED.
      cv_po_number = <fs_vbkd>-bstkd.
      UNASSIGN <fs_vbkd>.
    ENDIF.
    UNASSIGN <fs_vbak>.
  ENDIF.

* get sold-to and ship-to address data.
  READ TABLE it_hd_adr ASSIGNING FIELD-SYMBOL(<fs_hd_adr>) WITH KEY deliv_numb = it_hd_gen-deliv_numb partn_role = 'AG'.
  IF <fs_hd_adr> IS ASSIGNED.
    SELECT SINGLE FROM adrc
      FIELDS name1, name2, house_num1, street, city1, city2, region, post_code1, country
      WHERE addrnumber = @<fs_hd_adr>-addr_no
      INTO ( @cv_name1_ag, @cv_name2_ag, @cv_housenum_ag, @cv_street_ag, @cv_city_ag, @cv_city2_ag, @cv_regio_ag, @cv_postl_ag, @cv_land_ag ).

    SELECT SINGLE FROM but000
      FIELDS nickname
      WHERE partner = @<fs_hd_adr>-partn_numb
      INTO @cv_nickname.

    UNASSIGN <fs_hd_adr>.
  ENDIF.

  READ TABLE it_hd_adr ASSIGNING <fs_hd_adr> WITH KEY deliv_numb = it_hd_gen-deliv_numb partn_role = 'WE'.
  IF <fs_hd_adr> IS ASSIGNED.
    SELECT SINGLE FROM adrc
      FIELDS name1, name2, house_num1, street, city1, city2, region, post_code1, country
      WHERE addrnumber = @<fs_hd_adr>-addr_no
      INTO ( @cv_name1_we, @cv_name2_we, @cv_housenum_we, @cv_street_we, @cv_city_we, @cv_city2_we, @cv_regio_we, @cv_postl_we, @cv_land_we ).

    SELECT SINGLE FROM but000
      FIELDS nickname
      WHERE partner = @<fs_hd_adr>-partn_numb
      INTO @cv_nickname.

    UNASSIGN <fs_hd_adr>.
  ENDIF.

  DATA lv_name TYPE thead-tdname.

  lv_name = cv_doc_number.

  CALL FUNCTION 'READ_TEXT'
    EXPORTING
      id                      = 'ZINS'              " ID del texto a leer
      language                = 'S'                 " Idioma del texto a leer
      name                    = lv_name             " Nombre del texto a leer
      object                  = 'VBBK'              " Objeto del texto a leer
    TABLES
      lines                   = lt_lines            " Líneas del texto leído
    EXCEPTIONS
      id                      = 1                " ID de texto no válida
      language                = 2                " Idioma no válido
      name                    = 3                " Nombre de texto no válido
      not_found               = 4                " El texto no existe.
      object                  = 5                " Objeto de texto no válido
      reference_check         = 6                " Cadena de referencia interrumpida
      wrong_access_to_archive = 7                " Archive handle no permitido para el acceso
      OTHERS                  = 8.
  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  LOOP AT lt_lines ASSIGNING FIELD-SYMBOL(<fs_lines>).
    CONCATENATE cv_observ <fs_lines>-tdline INTO cv_observ SEPARATED BY space.
  ENDLOOP.

  CONDENSE cv_observ.

ENDFORM.
