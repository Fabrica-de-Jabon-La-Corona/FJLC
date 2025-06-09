*&---------------------------------------------------------------------*
*& Report ZSD_CREA_NCR_DPP
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zsd_crea_ncr_dpp.

CLASS lcl_main DEFINITION.

  PUBLIC SECTION.

    TYPES: BEGIN OF gs_vbeln,
             vbeln TYPE vbrk-vbeln,
             kunag TYPE vbrk-kunag,
             uuid  TYPE zsd_cfdi_return-uuid,
             kwert TYPE prcd_elements-kwert,
             waerk TYPE prcd_elements-waerk,
           END OF gs_vbeln.
    DATA: gt_vbeln TYPE STANDARD TABLE OF gs_vbeln.

    TYPES: BEGIN OF gs_ncr,
             vbeln TYPE vbrk-vbeln,
             kunag TYPE vbrk-kunag,
             name  TYPE string,
             uuid  TYPE zsd_cfdi_return-uuid,
             kwert TYPE prcd_elements-kwert,
             waerk TYPE prcd_elements-waerk,
             vbncr TYPE vbrk-vbeln,
           END OF gs_ncr.
    DATA: gt_ncr TYPE STANDARD TABLE OF gs_ncr.

    TYPES: BEGIN OF gs_findncr,
             vbelv TYPE vbrk-vbeln,
             vbeln TYPE vbrk-vbeln,
             vbtyp TYPE vbrk-vbtyp,
           END OF gs_findncr.
    DATA: gt_findncr TYPE STANDARD TABLE OF gs_findncr.

    TYPES: BEGIN OF gs_credit,
             credit    TYPE vbrk-vbeln,
             credreq   TYPE vbak-vbeln,
             reference TYPE vbrk-vbeln,
           END OF gs_credit.
    DATA: gt_credit TYPE STANDARD TABLE OF gs_credit.

    TYPES: BEGIN OF gs_documento,
             docto TYPE vbrk-vbeln,
           END OF gs_documento.
    DATA: gt_documento TYPE STANDARD TABLE OF gs_documento.

    DATA: gt_vbrk TYPE STANDARD TABLE OF vbrk.

    METHODS:

      get_invoices   IMPORTING date            TYPE vbrk-fkdat
                               canal           TYPE vbrk-vtweg
                               condicion       TYPE konv-kschl
                     EXPORTING VALUE(invoices) TYPE ANY TABLE,

      get_ncr        IMPORTING facturas           TYPE ANY TABLE
                               condicion          TYPE konv-kschl
                     EXPORTING VALUE(credit_memo) TYPE ANY TABLE,

      get_documents  IMPORTING facturas          TYPE ANY TABLE
                               credit_memo       TYPE ANY TABLE
                     EXPORTING VALUE(documentos) TYPE ANY TABLE,

      create_ncr_dpp IMPORTING documentos    TYPE ANY TABLE
                               condicion     TYPE konv-kschl
                     EXPORTING VALUE(ncrdpp) TYPE ANY TABLE,

      send_email     IMPORTING notas     TYPE ANY TABLE
                               condicion TYPE konv-kschl
                               fecha     TYPE vbrk-fkdat.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.

CLASS lcl_main IMPLEMENTATION.

  METHOD get_invoices.
    "Búsqueda de facturas que tengan descuento pronto pago y que estén timbradas
    SELECT a~vbeln, a~kunag, c~uuid FROM vbrk AS a
      INNER JOIN prcd_elements AS b ON b~knumv EQ a~knumv
      INNER JOIN zsd_cfdi_return AS c ON c~nodocu EQ a~vbeln
      WHERE a~fkdat EQ @date
      AND a~vtweg EQ @canal
      AND a~fksto EQ ''
      AND b~kschl EQ @condicion
      AND c~uuid NE ''
      AND b~kstat EQ 'X'
      INTO TABLE @gt_vbeln.

    SORT gt_vbeln ASCENDING BY vbeln kunag.
    DELETE ADJACENT DUPLICATES FROM gt_vbeln COMPARING vbeln.

    IF lines( gt_vbeln ) GT 0.
      invoices = gt_vbeln.
    ENDIF.
    REFRESH gt_vbeln.

  ENDMETHOD.

  METHOD get_ncr.

    DATA: ls_credit    TYPE lcl_main=>gs_credit,
          ls_findncr   TYPE lcl_main=>gs_findncr,
          lt_findncr   TYPE STANDARD TABLE OF gs_findncr,
          lt_credit    TYPE STANDARD TABLE OF gs_credit,
          lv_ordreason TYPE c LENGTH 3.

    CASE condicion.
      WHEN 'ZDPP'.
        lv_ordreason = 'Z68'.
      WHEN 'ZDPR'.
        lv_ordreason = 'Z69'.
      WHEN 'ZDTM'.
        lv_ordreason = 'Z70'.
      WHEN 'ZDLO'.
        lv_ordreason = 'Z73'.
      WHEN 'ZDLB'.
        lv_ordreason = 'Z73'.
    ENDCASE.

    MOVE-CORRESPONDING facturas[] TO gt_vbeln[].

    SELECT a~vbelv, a~vbeln, a~vbtyp_n FROM vbfa AS a
      FOR ALL ENTRIES IN @gt_vbeln
      WHERE a~vbelv EQ @gt_vbeln-vbeln
      AND a~vbtyp_v EQ 'M'
      AND a~vbtyp_n EQ 'K'
      INTO TABLE @DATA(lt_ncreq).

    IF lines( lt_ncreq ) GT 0.
      SELECT a~vbelv, a~vbeln, a~vbtyp_n FROM vbfa AS a
        INNER JOIN vbrk AS b ON b~vbeln EQ a~vbeln
        INNER JOIN vbrp AS c ON c~vbeln EQ a~vbeln
        FOR ALL ENTRIES IN @lt_ncreq
        WHERE a~vbelv EQ @lt_ncreq-vbeln
        AND a~vbtyp_v EQ 'K'
        AND a~vbtyp_n EQ 'O'
        AND b~fksto EQ ''
        AND c~augru_auft EQ @lv_ordreason
        INTO TABLE @lt_findncr.

      IF lines( lt_findncr ) GT 0.
        LOOP AT lt_findncr ASSIGNING FIELD-SYMBOL(<fs_findncr>).
          READ TABLE lt_ncreq ASSIGNING FIELD-SYMBOL(<fs_ncreq>) WITH KEY vbeln = <fs_findncr>-vbelv.
          ls_credit-credit   = <fs_findncr>-vbeln.
          ls_credit-credreq  = <fs_findncr>-vbelv.
          ls_credit-reference = <fs_ncreq>-vbelv.
          APPEND ls_credit TO lt_credit.
        ENDLOOP.
        UNASSIGN <fs_findncr>.

        credit_memo = lt_credit.

      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD get_documents.
    DATA: ls_credit  TYPE lcl_main=>gs_credit,
          lt_credit  TYPE STANDARD TABLE OF gs_credit,
          ls_invoice TYPE lcl_main=>gs_vbeln,
          lt_invoice TYPE STANDARD TABLE OF gs_vbeln,
          ls_doctos  TYPE lcl_main=>gs_documento,
          lt_doctos  TYPE STANDARD TABLE OF gs_documento.

    MOVE-CORRESPONDING facturas[] TO lt_invoice[].
    MOVE-CORRESPONDING credit_memo[] TO lt_credit.

    LOOP AT lt_invoice ASSIGNING FIELD-SYMBOL(<fs_invo>).
      IF NOT line_exists( lt_credit[ reference = <fs_invo>-vbeln ] ).
        ls_doctos-docto = <fs_invo>-vbeln.
        APPEND ls_doctos TO lt_doctos.
        CLEAR: ls_doctos.
      ENDIF.
    ENDLOOP.

    SORT lt_doctos ASCENDING BY docto.
    DELETE ADJACENT DUPLICATES FROM lt_doctos.

    UNASSIGN <fs_invo>.

    documentos = lt_doctos.

  ENDMETHOD.

  METHOD create_ncr_dpp.
    DATA: ls_doctos     TYPE lcl_main=>gs_documento,
          lt_doctos     TYPE STANDARD TABLE OF gs_documento,
          ls_header_in  TYPE bapisdhd1,
          ls_header_inx TYPE bapisdhd1x,
          ls_items_in   TYPE bapisditm,
          lt_items_in   TYPE STANDARD TABLE OF bapisditm,
          ls_items_inx  TYPE bapisditmx,
          lt_items_inx  TYPE STANDARD TABLE OF bapisditmx,
          ls_partners   TYPE bapiparnr,
          lt_partners   TYPE STANDARD TABLE OF bapiparnr,
          ls_sched_in   TYPE bapischdl,
          lt_sched_in   TYPE STANDARD TABLE OF bapischdl,
          ls_sched_inx  TYPE bapischdlx,
          lt_sched_inx  TYPE STANDARD TABLE OF bapischdlx,
          ls_cond_in    TYPE bapicond,
          lt_cond_in    TYPE STANDARD TABLE OF bapicond,
          ls_cond_inx   TYPE bapicondx,
          lt_cond_inx   TYPE STANDARD TABLE OF bapicondx,
          ls_return     TYPE bapiret2,
          lt_return     TYPE STANDARD TABLE OF bapiret2,
          lt_vbrk       TYPE STANDARD TABLE OF vbrk,
          lt_vbrp       TYPE STANDARD TABLE OF vbrp,
          lt_prcd       TYPE STANDARD TABLE OF prcd_elements,
          ls_ncr        TYPE lcl_main=>gs_ncr,
          lt_ncr        TYPE STANDARD TABLE OF gs_ncr,
          lt_timbre     TYPE STANDARD TABLE OF zsd_cfdi_return,
          lt_vbkd       TYPE STANDARD TABLE OF vbkd,
          lv_ncr        TYPE bapivbeln-vbeln,
          lv_ordreason  TYPE c LENGTH 3,
          lv_kwert      TYPE kwert.

    CONSTANTS: lc_true    TYPE c LENGTH 1 VALUE 'X',
               lc_bobj    TYPE bapiusw01-objtype VALUE 'BUS2094',
               lc_doctype TYPE c LENGTH 4 VALUE 'ZNTC',
               lc_ctdpp   TYPE c LENGTH 4 VALUE 'ZNDP',
               lc_ctdpr   TYPE c LENGTH 4 VALUE 'ZNPR',
               lc_ctdtm   TYPE c LENGTH 4 VALUE 'ZNTM',
               lc_ctdlo   TYPE c LENGTH 4 VALUE 'ZNLO'.

    MOVE-CORRESPONDING documentos[] TO lt_doctos[].
    SORT lt_doctos[] ASCENDING BY docto.

    "Se obtienen datos de cabecera y posición de la factura.
    SELECT * FROM vbrk
      FOR ALL ENTRIES IN @lt_doctos
      WHERE vbeln EQ @lt_doctos-docto
      AND fksto EQ ''
      INTO TABLE @lt_vbrk.

    SORT lt_vbrk[] ASCENDING BY vbeln.

    SELECT * FROM prcd_elements
      FOR ALL ENTRIES IN @lt_vbrk
      WHERE knumv EQ @lt_vbrk-knumv
      AND kschl EQ @condicion
      INTO TABLE @lt_prcd.

    SORT lt_prcd[] ASCENDING BY knumv kposn.

    SELECT * FROM vbrp
      FOR ALL ENTRIES IN @lt_prcd
      WHERE knumv_ana EQ @lt_prcd-knumv
      AND posnr EQ @lt_prcd-kposn
      INTO TABLE @lt_vbrp.

    SORT lt_vbrp[] ASCENDING BY vbeln posnr.

    SELECT * FROM zsd_cfdi_return
      FOR ALL ENTRIES IN @lt_doctos
      WHERE nodocu EQ @lt_doctos-docto
      INTO TABLE @lt_timbre.

    SORT lt_timbre[] ASCENDING BY nodocu.

    SELECT * FROM vbkd
      FOR ALL ENTRIES IN @lt_vbrp
      WHERE vbeln EQ @lt_vbrp-aubel
      INTO TABLE @lt_vbkd.

    SORT lt_vbkd[] ASCENDING BY vbeln.

    SELECT * FROM kna1
      FOR ALL ENTRIES IN @lt_vbrk
      WHERE kunnr EQ @lt_vbrk-kunag
      INTO TABLE @DATA(lt_kna1).

    SORT lt_kna1[] ASCENDING BY kunnr.

    CASE condicion.
      WHEN 'ZDPP'.
        lv_ordreason = 'Z68'.
      WHEN 'ZDPR'.
        lv_ordreason = 'Z69'.
      WHEN 'ZDTM'.
        lv_ordreason = 'Z70'.
      WHEN 'ZDLO'.
        lv_ordreason = 'Z73'.
      WHEN 'ZDLB'.
        lv_ordreason = 'Z73'.
    ENDCASE.

    LOOP AT lt_doctos ASSIGNING FIELD-SYMBOL(<fs_doctos>).
      "Se leen las tablas internas LT_VBRK y LT_VBRP para llenar las tablas y estructuras de la BAPI.
      READ TABLE lt_vbrk ASSIGNING FIELD-SYMBOL(<fs_vbrk>) WITH KEY vbeln = <fs_doctos>-docto.
      READ TABLE lt_vbrp ASSIGNING FIELD-SYMBOL(<fs_vbrp>) WITH KEY vbeln = <fs_doctos>-docto.
      READ TABLE lt_vbkd ASSIGNING FIELD-SYMBOL(<fs_vbkd>) WITH KEY vbeln = <fs_vbrp>-aubel.
      "Se llenan estructuras HEADER_IN y HEADER_INX.
      ls_header_in-doc_type   = lc_doctype.
      ls_header_in-sales_org  = <fs_vbrk>-vkorg.
      ls_header_in-distr_chan = <fs_vbrk>-vtweg.
      ls_header_in-division   = <fs_vbrk>-spart.
      ls_header_in-sales_grp  = <fs_vbrp>-vkgrp.
      ls_header_in-sales_off  = <fs_vbrp>-vkbur.
      ls_header_in-purch_date = sy-datum.
      ls_header_in-ord_reason = lv_ordreason.
      ls_header_in-purch_no_c = <fs_vbkd>-bstkd.
      ls_header_in-ref_doc    = <fs_vbrk>-vbeln.
      ls_header_in-refdoc_cat = <fs_vbrk>-vbtyp.
      "ls_header_in-ref_1     = <fs_vbrk>-vbeln.
      ls_header_in-ref_doc_l  = <fs_vbrk>-vbeln.
      ls_header_in-ass_number = <fs_vbrk>-vbeln.

      ls_header_inx-doc_type   = lc_true.
      ls_header_inx-sales_org  = lc_true.
      ls_header_inx-distr_chan = lc_true.
      ls_header_inx-division   = lc_true.
      ls_header_inx-sales_grp  = lc_true.
      ls_header_inx-sales_off  = lc_true.
      ls_header_inx-purch_date = lc_true.
      ls_header_inx-ord_reason = lc_true.
      ls_header_inx-purch_no_c = lc_true.
      ls_header_inx-ref_doc    = lc_true.
      ls_header_inx-refdoc_cat = lc_true.
      "ls_header_inx-ref_1     = lc_true.
      ls_header_inx-ref_doc_l  = lc_true.
      ls_header_inx-ass_number = lc_true.

      "Se llena estructura y tabla interna LS_PARTNERS y LT_PARTNERS.
      ls_partners-partn_role = 'AG'.
      ls_partners-partn_numb = <fs_vbrk>-kunag.
      APPEND ls_partners TO lt_partners.
      UNASSIGN: <fs_vbrp>, <fs_vbkd>.

      LOOP AT lt_vbrp ASSIGNING <fs_vbrp> WHERE vbeln EQ <fs_doctos>-docto.
        "Se llenan estructuras y tablas internas para ITEMS_IN y ITEMS_INX
        ls_items_in-itm_number = <fs_vbrp>-posnr.
        ls_items_in-material   = <fs_vbrp>-matnr.
        ls_items_in-plant      = <fs_vbrp>-werks.
        ls_items_in-target_qty = '1.000'.
        ls_items_in-target_qu  = <fs_vbrp>-vrkme.

        ls_items_inx-itm_number = <fs_vbrp>-posnr.
        ls_items_inx-material   = lc_true.
        ls_items_inx-plant      = lc_true.
        ls_items_inx-target_qty = lc_true.
        ls_items_inx-target_qu  = lc_true.

        APPEND: ls_items_in  TO lt_items_in,
                ls_items_inx TO lt_items_inx.

        CLEAR: ls_items_in, ls_items_inx.

        "Se llenan estructuras y tablas internas para SCHEDULES_IN y SCHEDULES_INX
        ls_sched_in-itm_number = <fs_vbrp>-posnr.
        ls_sched_in-req_qty    = '1.000'.

        ls_sched_inx-itm_number = <fs_vbrp>-posnr.
        ls_sched_inx-req_qty    = lc_true.

        APPEND: ls_sched_in  TO lt_sched_in,
                ls_sched_inx TO lt_sched_inx.

        CLEAR: ls_sched_in, ls_sched_inx.

        "Se llenan estructuras y tablas internas para CONDITIONS_IN y CONDITIONS_INX
        READ TABLE lt_prcd ASSIGNING FIELD-SYMBOL(<fs_prcd>) WITH KEY knumv = <fs_vbrk>-knumv kschl = condicion kposn = <fs_vbrp>-posnr.
        IF <fs_prcd> IS ASSIGNED.
          ls_cond_in-itm_number = <fs_vbrp>-posnr.
          CASE condicion.
            WHEN 'ZDPP'.
              ls_cond_in-cond_type  = lc_ctdpp.
            WHEN 'ZDPR'.
              ls_cond_in-cond_type  = lc_ctdpr.
            WHEN 'ZDTM'.
              ls_cond_in-cond_type  = lc_ctdtm.
            WHEN 'ZDLO'.
              ls_cond_in-cond_type  = lc_ctdlo.
            WHEN 'ZDLB'.
              ls_cond_in-cond_type  = lc_ctdlo.
            WHEN OTHERS.
              ls_cond_in-cond_type  = 'ZNC1'.
          ENDCASE.
          ls_cond_in-cond_value = <fs_prcd>-kwert * -1.
          ls_cond_in-currency   = <fs_prcd>-waerk.
          ls_cond_in-cond_unit  = <fs_vbrp>-vrkme.
          ls_cond_in-cond_p_unt = '1'.

          ls_cond_inx-itm_number = <fs_vbrp>-posnr.
          CASE condicion.
            WHEN 'ZDPP'.
              ls_cond_inx-cond_type  = lc_ctdpp.
            WHEN 'ZDPR'.
              ls_cond_inx-cond_type  = lc_ctdpr.
            WHEN 'ZDTM'.
              ls_cond_inx-cond_type  = lc_ctdtm.
            WHEN 'ZDLO'.
              ls_cond_inx-cond_type  = lc_ctdlo.
            WHEN 'ZDLB'.
              ls_cond_inx-cond_type  = lc_ctdlo.
            WHEN OTHERS.
              ls_cond_inx-cond_type  = 'ZNC1'.
          ENDCASE.
          ls_cond_inx-cond_value = lc_true.
          ls_cond_inx-currency   = lc_true.
          ls_cond_inx-cond_unit  = lc_true.
          ls_cond_inx-cond_p_unt = lc_true.

          lv_kwert = lv_kwert + ls_cond_in-cond_value.

          APPEND: ls_cond_in  TO lt_cond_in,
                  ls_cond_inx TO lt_cond_inx.

          CLEAR: ls_cond_in, ls_cond_inx.
          UNASSIGN <fs_prcd>.
        ENDIF.
      ENDLOOP.
      UNASSIGN <fs_vbrp>.

      "Se ejecuta la BAPI para crear la solicitud de nota de crédito con referencia a la factura.
      CALL FUNCTION 'SD_SALESDOCUMENT_CREATE'
        EXPORTING
*         salesdocument         =
          sales_header_in       = ls_header_in
          sales_header_inx      = ls_header_inx
*         sender                =
*         binary_relationshiptype = space
*         int_number_assignment = space
*         behave_when_error     = space
*         logic_switch          = space
          business_object       = lc_bobj
*         testrun               =
*         convert_parvw_auart   = space
          status_buffer_refresh = 'X'
*         call_active           = space
*         i_without_init        = space
          i_refresh_v45i        = 'X'
*         i_testrun_extended    = space
          i_check_ag            = 'X'
        IMPORTING
          salesdocument_ex      = lv_ncr
*         sales_header_out      =
*         sales_header_status   =
        TABLES
          return                = lt_return
          sales_items_in        = lt_items_in
          sales_items_inx       = lt_items_inx
          sales_partners        = lt_partners
          sales_schedules_in    = lt_sched_in
          sales_schedules_inx   = lt_sched_inx
          sales_conditions_in   = lt_cond_in
          sales_conditions_inx  = lt_cond_inx
*         sales_cfgs_ref        =
*         sales_cfgs_inst       =
*         sales_cfgs_part_of    =
*         sales_cfgs_value      =
*         sales_cfgs_blob       =
*         sales_cfgs_vk         =
*         sales_cfgs_refinst    =
*         sales_ccard           =
*         sales_text            =
*         sales_keys            =
*         sales_contract_in     =
*         sales_contract_inx    =
*         extensionin           =
*         partneraddresses      =
*         sales_sched_conf_in   =
*         items_ex              =
*         schedule_ex           =
*         business_ex           =
*         incomplete_log        =
*         extensionex           =
*         conditions_ex         =
*         partners_ex           =
*         textheaders_ex        =
*         textlines_ex          =
*         batch_charc           =
*         campaign_asgn         =
        .

      IF lv_ncr NE ''.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
*          EXPORTING
*            wait   =
*          IMPORTING
*            return =
          .
        REFRESH: lt_return, lt_items_in, lt_items_inx, lt_partners, lt_sched_in, lt_sched_inx, lt_cond_in, lt_cond_inx.
        DATA: lt_billdatain TYPE STANDARD TABLE OF bapivbrk,
              ls_billdatain TYPE bapivbrk,
              lt_success    TYPE STANDARD TABLE OF bapivbrksuccess,
              lv_factura    TYPE vbrk-vbeln.

        lv_ncr = |{ lv_ncr ALPHA = IN }|.

        ls_billdatain-doc_number = lv_ncr.
        ls_billdatain-ref_doc = lv_ncr.
        ls_billdatain-ref_doc_ca = 'C'.

        APPEND ls_billdatain TO lt_billdatain.

        WAIT UP TO 3 SECONDS.

        CALL FUNCTION 'BAPI_BILLINGDOC_CREATEMULTIPLE'
          EXPORTING
            posting       = 'C'
          TABLES
            billingdatain = lt_billdatain
            return        = lt_return
            success       = lt_success.

        LOOP AT lt_success ASSIGNING FIELD-SYMBOL(<fs_success>).
          lv_factura = <fs_success>-bill_doc.
        ENDLOOP.
        IF lv_factura NE ''.
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
*              EXPORTING
*                wait   =
*              IMPORTING
*                return =
            .
        ELSE.
          CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'
*          IMPORTING
*            return =
            .
        ENDIF.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'
*          IMPORTING
*            return =
          .
      ENDIF.

      "Se llena tabla para mostrar el resultado.
      READ TABLE lt_timbre ASSIGNING FIELD-SYMBOL(<fs_timbre>) WITH KEY nodocu = <fs_doctos>-docto.
      ls_ncr-vbeln = <fs_vbrk>-vbeln.
      ls_ncr-uuid  = <fs_timbre>-uuid.
      ls_ncr-kunag = <fs_vbrk>-kunag.
      ls_ncr-vbncr = lv_factura.
      ls_ncr-kwert = lv_kwert.

      IF <fs_prcd> IS ASSIGNED.
        ls_ncr-waerk = <fs_prcd>-waerk.
      ENDIF.

      READ TABLE lt_kna1 ASSIGNING FIELD-SYMBOL(<fs_kna1>) WITH KEY kunnr = <fs_vbrk>-kunag.

      IF <fs_kna1> IS ASSIGNED.
        CONCATENATE <fs_kna1>-name1 <fs_kna1>-name2 <fs_kna1>-name3 <fs_kna1>-name4 INTO ls_ncr-name.
        CONDENSE ls_ncr-name.
      ENDIF.

      APPEND ls_ncr TO lt_ncr.
      CLEAR: ls_ncr, lv_kwert, lv_factura.

      UNASSIGN: <fs_prcd>, <fs_timbre>, <fs_vbrk>, <fs_vbrp>, <fs_vbkd>.
    ENDLOOP.

    SORT lt_ncr ASCENDING BY vbeln.
    UNASSIGN <fs_doctos>.

    ncrdpp = lt_ncr.

  ENDMETHOD.

  METHOD send_email.

    DATA: ls_ncr TYPE lcl_main=>gs_ncr,
          lt_ncr TYPE STANDARD TABLE OF gs_ncr.

    DATA: lv_kwert       TYPE c LENGTH 25,
          lv_string_text TYPE string,
          lt_text        TYPE bcsy_text,
          lv_subject     TYPE so_obj_des,
          lv_recipient   TYPE adr6-smtp_addr,
          lv_sent_to_all TYPE os_boolean,
          lv_clcond      TYPE string,
          lv_clcondsub   TYPE string.

    DATA: lo_bcs         TYPE REF TO cl_bcs,
          lo_doc_bcs     TYPE REF TO cl_document_bcs,
          lo_recep       TYPE REF TO if_recipient_bcs,
          lo_sapuser_bcs TYPE REF TO cl_sapuser_bcs,
          lo_cx_bcx      TYPE REF TO cx_bcs.

    MOVE-CORRESPONDING notas[] TO lt_ncr[].

    TRY.
        lo_bcs = cl_bcs=>create_persistent( ).
      CATCH cx_send_req_bcs.
    ENDTRY.

    TRY.

        CONCATENATE 'Buen día,' cl_abap_char_utilities=>newline INTO lv_string_text.
        APPEND lv_string_text TO lt_text.
        CLEAR lv_string_text.

        CASE condicion.
          WHEN 'ZDPP'.
            lv_clcond = 'por descuento pronto pago:'.
          WHEN 'ZDPR'.
            lv_clcond = 'por descuento fijo a cadena'.
          WHEN 'ZDTM'.
            lv_clcond = 'por descuento temporal'.
          WHEN 'ZDLO'.
            lv_clcond = 'por descuento logístico'.
          WHEN 'ZDLB'.
            lv_clcond = 'por descuento logístico'.
          WHEN OTHERS.
            lv_clcond = ':'.
        ENDCASE.

        CONCATENATE 'Se crearon las siguientes notas de crédito' lv_clcond cl_abap_char_utilities=>newline INTO lv_string_text SEPARATED BY space.
        APPEND lv_string_text TO lt_text.
        CLEAR lv_string_text.

        LOOP AT lt_ncr ASSIGNING FIELD-SYMBOL(<fs_ncr>).
          DATA: lv_signo TYPE c LENGTH 1.

          CASE <fs_ncr>-waerk.
            WHEN 'USD'.
              lv_signo = '$'.
            WHEN 'MXN'.
              lv_signo = '$'.
            WHEN 'EUR'.
              lv_signo = '€'.
          ENDCASE.

          lv_kwert = <fs_ncr>-kwert.
          CONDENSE lv_kwert.

          CONCATENATE 'Factura:' <fs_ncr>-vbeln 'UUID:' <fs_ncr>-uuid 'Cliente:' <fs_ncr>-kunag 'Nombre:' <fs_ncr>-name 'NCR:' <fs_ncr>-vbncr 'Importe:' lv_signo lv_kwert <fs_ncr>-waerk cl_abap_char_utilities=>newline INTO lv_string_text SEPARATED BY
space.
          APPEND lv_string_text TO lt_text.
          CLEAR lv_string_text.
        ENDLOOP.

        CONCATENATE 'Saludos cordiales.' cl_abap_char_utilities=>newline INTO lv_string_text.
        APPEND lv_string_text TO lt_text.
        CLEAR lv_string_text.

        CASE condicion.
          WHEN 'ZDPP'.
            lv_clcondsub = 'DPP del día'.
          WHEN 'ZDPR'.
            lv_clcondsub = 'dto. cadena día'.
          WHEN 'ZDTM'.
            lv_clcondsub = 'dto. temporal día'.
          WHEN 'ZDLO'.
            lv_clcondsub = 'dto. logístico día'.
          WHEN 'ZDLB'.
            lv_clcondsub = 'dto. logístico día'.
          WHEN OTHERS.
            lv_clcond = ':'.
        ENDCASE.

        CONCATENATE fecha+6(2) '.' fecha+4(2) '.' fecha(4) INTO DATA(lv_fechacrea).
        CONCATENATE 'Creación automática NCR' lv_clcondsub lv_fechacrea INTO lv_subject SEPARATED BY space.

        lo_doc_bcs = cl_document_bcs=>create_document(
          i_type    = 'RAW'
          i_text    = lt_text[]
          i_length  = '12'
          i_subject = lv_subject ).

        CALL METHOD lo_bcs->set_document( lo_doc_bcs ).

*-----------------------------------------------------------------------
*Coloca Emisor de correo. Si no se coloca, se toma el valor de sy-uname-
*-----------------------------------------------------------------------
*    lo_sapuser_bcs = cl_sapuser_bcs=>create( sy-uname ).
*    CALL METHOD lo_bcs->set_sender
*      EXPORTING
*        i_sender = lo_sapuser_bcs.

        "Obtenemos la lista de destinatarios de la tabal ZPRAMGLOB.
        SELECT * FROM zparamglob
          WHERE programa EQ 'ZSD_CREA_NCR_DPP'
          AND parametro EQ '1'
          INTO TABLE @DATA(lt_param).

        DATA: lv_copy       TYPE boolean,
              lv_blind_copy TYPE boolean.

        LOOP AT lt_param ASSIGNING FIELD-SYMBOL(<fs_param>).
          lv_recipient  = <fs_param>-valor1.
          lv_copy       = <fs_param>-valor2.
          lv_blind_copy = <fs_param>-valor3.

          lo_recep = cl_cam_address_bcs=>create_internet_address( lv_recipient ).

          CALL METHOD lo_bcs->add_recipient
            EXPORTING
              i_recipient  = lo_recep
              i_express    = 'X'
              i_copy       = lv_copy
              i_blind_copy = lv_blind_copy.
        ENDLOOP.
        UNASSIGN <fs_param>.

*        SELECT SINGLE smtp_addr INTO lv_recipient
*          FROM adr6 AS a
*          INNER JOIN usr21 AS b ON a~addrnumber EQ b~addrnumber
*          AND a~persnumber EQ b~persnumber
*        WHERE bname = sy-uname.

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

    UNASSIGN <fs_ncr>.
  ENDMETHOD.

ENDCLASS.

TABLES: vbrk.

*Parámetros de selección
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-002 .

  PARAMETERS: p_kschl TYPE t685a-kschl OBLIGATORY,
              p_fecha TYPE vbrk-fkdat OBLIGATORY,
              p_canal TYPE vbrk-vtweg OBLIGATORY.

  "SELECT-OPTIONS: p_canal FOR vbrk-vtweg OBLIGATORY.

SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.

  DATA: gt_vbeln  TYPE STANDARD TABLE OF lcl_main=>gs_vbeln,
        gt_ncr    TYPE STANDARD TABLE OF lcl_main=>gs_credit,
        gt_ncrnew TYPE STANDARD TABLE OF lcl_main=>gs_ncr,
        gt_docs   TYPE STANDARD TABLE OF lcl_main=>gs_documento,
        lv_string TYPE string,
        lv_fecha  TYPE c LENGTH 10.

  DATA: obj_dpp TYPE REF TO lcl_main.  "Objeto

  CREATE OBJECT obj_dpp.  "Se crea la instancia al objeto

  "Se obtienen facturas de la fecha indicada en el parámetro que contengan condición ZDPP
  CALL METHOD obj_dpp->get_invoices
    EXPORTING
      date      = p_fecha
      canal     = p_canal
      condicion = p_kschl
    IMPORTING
      invoices  = gt_vbeln.

  IF lines( gt_vbeln ) GT 0.
    "Busca existencia de notas de crédito por DPP previas.
    CALL METHOD obj_dpp->get_ncr
      EXPORTING
        facturas    = gt_vbeln
        condicion   = p_kschl
      IMPORTING
        credit_memo = gt_ncr.

    "Deja en GT_DOCS los números de factura que no tienen NCR por DPP creada.
    CALL METHOD obj_dpp->get_documents
      EXPORTING
        facturas    = gt_vbeln
        credit_memo = gt_ncr
      IMPORTING
        documentos  = gt_docs.

    IF lines( gt_docs ) GT 0.
      "Se crean las notas de crédito por DPP de las facturas seleccionadas
      CALL METHOD obj_dpp->create_ncr_dpp
        EXPORTING
          documentos = gt_docs
          condicion  = p_kschl
        IMPORTING
          ncrdpp     = gt_ncrnew.
    ENDIF.
  ENDIF.

  IF lines( gt_ncrnew ) GT 0.
    "Se envía correo electrónico con las notas de crédito creadas
    CALL METHOD obj_dpp->send_email
      EXPORTING
        notas     = gt_ncrnew
        condicion = p_kschl
        fecha     = p_fecha.
  ELSE.
    CONCATENATE p_fecha+6(2) '.' p_fecha+4(2) '.' p_fecha(4) INTO lv_fecha.
    CONCATENATE 'No existen facturas con descuento pronto pago que estén timbradas en fecha' lv_fecha INTO lv_string SEPARATED BY space.
    WRITE: / lv_string.
  ENDIF.
