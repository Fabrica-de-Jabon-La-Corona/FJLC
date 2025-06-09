*----------------------------------------------------------------------*
*      Print of a delivery note by SAPscript SMART FORMS               *
*----------------------------------------------------------------------*
REPORT zrle_delnote.

* declaration of data
INCLUDE rle_delnote_data_declare.
* definition of forms
INCLUDE zrle_delnote_forms.
*INCLUDE RLE_DELNOTE_FORMS.
INCLUDE zrle_print_forms.
*INCLUDE RLE_PRINT_FORMS.

*---------------------------------------------------------------------*
*       FORM ENTRY
*---------------------------------------------------------------------*
FORM entry USING return_code us_screen.

  IF cl_shp_delivery_outputs=>is_enabled( ).
    MESSAGE e006(vld) WITH nast-kschl INTO DATA(lv_message).
    CALL FUNCTION 'NAST_PROTOCOL_UPDATE'
      EXPORTING
        msg_arbgb = sy-msgid
        msg_nr    = sy-msgno
        msg_ty    = sy-msgty
        msg_v1    = sy-msgv1
        msg_v2    = sy-msgv2
        msg_v3    = sy-msgv3
        msg_v4    = sy-msgv4
      EXCEPTIONS
        OTHERS    = 1.
    return_code = 1.
    RETURN.
  ENDIF.

  DATA: lf_retcode TYPE sy-subrc.
  xscreen = us_screen.
  PERFORM processing USING    us_screen
                     CHANGING lf_retcode.
  IF lf_retcode NE 0.
    return_code = 1.
  ELSE.
    return_code = 0.
  ENDIF.

ENDFORM.
*---------------------------------------------------------------------*
*       FORM PROCESSING                                               *
*---------------------------------------------------------------------*
FORM processing USING    proc_screen
                CHANGING cf_retcode.

  DATA: ls_print_data_to_read TYPE ledlv_print_data_to_read.
  DATA: ls_dlv_delnote        TYPE ledlv_delnote.
  DATA: lf_fm_name            TYPE rs38l_fnam.
  DATA: ls_control_param      TYPE ssfctrlop.
  DATA: ls_composer_param     TYPE ssfcompop.
  DATA: ls_recipient          TYPE swotobjid.
  DATA: ls_sender             TYPE swotobjid.
  DATA: lf_formname           TYPE tdsfname.
  DATA: ls_addr_key           LIKE addr_key.
  DATA: lt_items_data         TYPE zsd_tt_delivery_note.
  DATA: lv_totaltax    TYPE kwert,
        lv_subtotal    TYPE kwert,
        lv_total       TYPE kwert,
        lv_discount    TYPE kwert,
        lv_doc_number  TYPE vbeln,
        lv_po_number   TYPE bstkd,
        lv_so_date     TYPE audat,
        lv_name1_ag    TYPE name1,
        lv_name2_ag    TYPE name2,
        lv_housenum_ag TYPE ad_hsnm1,
        lv_street_ag   TYPE ad_street,
        lv_city_ag     TYPE ad_city1,
        lv_city2_ag    TYPE ad_city2,
        lv_regio_ag    TYPE regio,
        lv_postl_ag    TYPE ad_pstcd1,
        lv_land_ag     TYPE land1,
        lv_name1_we    TYPE name1,
        lv_name2_we    TYPE name2,
        lv_housenum_we TYPE ad_hsnm1,
        lv_street_we   TYPE ad_street,
        lv_city_we     TYPE ad_city1,
        lv_city2_we    TYPE ad_city2,
        lv_regio_we    TYPE regio,
        lv_postl_we    TYPE ad_pstcd1,
        lv_land_we     TYPE land1,
        lv_terms       TYPE vtext,
        lv_observ      TYPE string,
        lv_waerk       TYPE waerk,
        lv_numviaje    TYPE string,
        lv_canttotal   TYPE lfimg,
        lv_nickname    TYPE nickname.

  IF cl_shp_delivery_outputs=>is_enabled( ).
    MESSAGE e006(vld) WITH nast-kschl INTO DATA(lv_message).
    CALL FUNCTION 'NAST_PROTOCOL_UPDATE'
      EXPORTING
        msg_arbgb = sy-msgid
        msg_nr    = sy-msgno
        msg_ty    = sy-msgty
        msg_v1    = sy-msgv1
        msg_v2    = sy-msgv2
        msg_v3    = sy-msgv3
        msg_v4    = sy-msgv4
      EXCEPTIONS
        OTHERS    = 1.
    cf_retcode = 1.
    RETURN.
  ENDIF.

* SmartForm from customizing table TNAPR
  lf_formname = tnapr-sform.

* determine print data
  PERFORM set_print_data_to_read USING    lf_formname
                                 CHANGING ls_print_data_to_read
                                 cf_retcode.

  IF cf_retcode = 0.
* select print data
    PERFORM get_data TABLES   lt_items_data
                     USING    ls_print_data_to_read
                     CHANGING ls_addr_key
                              ls_dlv_delnote
                              lv_totaltax
                              lv_discount
                              lv_total
                              lv_subtotal
                              lv_doc_number
                              lv_po_number
                              lv_so_date
                              lv_name1_ag
                              lv_name2_ag
                              lv_housenum_ag
                              lv_street_ag
                              lv_city_ag
                              lv_city2_ag
                              lv_regio_ag
                              lv_postl_ag
                              lv_land_ag
                              lv_name1_we
                              lv_name2_we
                              lv_housenum_we
                              lv_street_we
                              lv_city_we
                              lv_city2_we
                              lv_regio_we
                              lv_postl_we
                              lv_land_we
                              lv_terms
                              lv_observ
                              lv_waerk
                              lv_numviaje
                              lv_canttotal
                              lv_nickname
                              cf_retcode.
  ENDIF.

  IF cf_retcode = 0.
    PERFORM set_print_param USING    ls_addr_key
                            CHANGING ls_control_param
                                     ls_composer_param
                                     ls_recipient
                                     ls_sender
                                     cf_retcode.
  ENDIF.

  IF cf_retcode = 0.
* determine smartform function module for delivery note
    CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
      EXPORTING
        formname           = lf_formname
*       variant            = ' '
*       direct_call        = ' '
      IMPORTING
        fm_name            = lf_fm_name
      EXCEPTIONS
        no_form            = 1
        no_function_module = 2
        OTHERS             = 3.
    IF sy-subrc <> 0.
*   error handling
      cf_retcode = sy-subrc.
      PERFORM protocol_update.
    ENDIF.
  ENDIF.

  IF cf_retcode = 0.
*   call smartform delivery note
    CALL FUNCTION lf_fm_name
      EXPORTING
        archive_index      = toa_dara
        archive_parameters = arc_params
        control_parameters = ls_control_param
*       mail_appl_obj      =
        mail_recipient     = ls_recipient
        mail_sender        = ls_sender
        output_options     = ls_composer_param
        user_settings      = ' '
        iv_doc_number      = lv_doc_number
        iv_cust_id         = ls_dlv_delnote-hd_gen-sold_to_party
        iv_po_number       = lv_po_number
        iv_so_date         = lv_so_date
        iv_dlv_date        = ls_dlv_delnote-hd_gen-dlv_date
        iv_shipto_id       = ls_dlv_delnote-hd_gen-ship_to_party
        iv_name1_ag        = lv_name1_ag
        iv_name2_ag        = lv_name2_ag
        iv_housenum_ag     = lv_housenum_ag
        iv_street_ag       = lv_street_ag
        iv_city_ag         = lv_city_ag
        iv_city2_ag        = lv_city2_ag
        iv_regio_ag        = lv_regio_ag
        iv_postl_ag        = lv_postl_ag
        iv_land_ag         = lv_land_ag
        iv_name1_we        = lv_name1_we
        iv_name2_we        = lv_name2_we
        iv_housenum_we     = lv_housenum_we
        iv_street_we       = lv_street_we
        iv_city_we         = lv_city_we
        iv_city2_we        = lv_city2_we
        iv_regio_we        = lv_regio_we
        iv_postl_we        = lv_postl_we
        iv_land_we         = lv_land_we
        iv_terms           = lv_terms
        iv_grossw          = ls_dlv_delnote-hd_gen-brt_weight
        iv_netw            = ls_dlv_delnote-hd_gen-net_weight
        iv_gewei           = ls_dlv_delnote-hd_gen-unit_of_weight
        iv_inco1           = ls_dlv_delnote-hd_gen-incoterms1
        iv_inco2           = ls_dlv_delnote-hd_gen-incoterms2
        iv_subtotal        = lv_subtotal
        iv_taxporc         = '0.00'
        iv_taxbase         = '0.00'
        iv_totaltax        = lv_totaltax
        iv_total           = lv_total
        iv_dlv_number      = ls_dlv_delnote-hd_gen-deliv_numb
        iv_volumen         = ls_dlv_delnote-hd_gen-tot_volume
        iv_discount        = lv_discount
        iv_observ          = lv_observ
        iv_waerk           = lv_waerk
        iv_numviaje        = lv_numviaje
        iv_canttotal       = lv_canttotal
        iv_nickname        = lv_nickname
*      IMPORTING
*       document_output_info =
*       job_output_info    =
*       job_output_options =
      TABLES
        it_items           = lt_items_data
      EXCEPTIONS
        formatting_error   = 1
        internal_error     = 2
        send_error         = 3
        user_canceled      = 4
        OTHERS             = 5.
    IF sy-subrc <> 0.
*   error handling
      cf_retcode = sy-subrc.
      PERFORM protocol_update.
*     get SmartForm protocoll and store it in the NAST protocoll
      PERFORM add_smfrm_prot.                  "INS_HP_335958
    ENDIF.
  ENDIF.
* get SmartForm protocoll and store it in the NAST protocoll
* PERFORM ADD_SMFRM_PROT.                       DEL_HP_335958

ENDFORM.
