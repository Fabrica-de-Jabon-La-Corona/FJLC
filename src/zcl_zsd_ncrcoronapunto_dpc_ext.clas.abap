class ZCL_ZSD_NCRCORONAPUNTO_DPC_EXT definition
  public
  inheriting from ZCL_ZSD_NCRCORONAPUNTO_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CREATE_DEEP_ENTITY
    redefinition .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ZSD_NCRCORONAPUNTO_DPC_EXT IMPLEMENTATION.


  METHOD /iwbep/if_mgw_appl_srv_runtime~create_deep_entity.
    DATA: ls_de_cliente TYPE zcl_zsd_ncrcoronapunto_mpc_ext=>ts_de_cliente,
          ls_notacred   TYPE zcl_zsd_ncrcoronapunto_mpc_ext=>ts_notacred,
          lt_notacred   TYPE zcl_zsd_ncrcoronapunto_mpc_ext=>tt_notacred,
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
          lv_ncr        TYPE bapivbeln-vbeln,
          lv_posnr      TYPE vbap-posnr,
          lv_subtotal   TYPE prcd_elements-kwert,
          lv_descuento  TYPE prcd_elements-kwert,
          lv_iva        TYPE prcd_elements-kwert,
          lv_totfac     TYPE p LENGTH 9 DECIMALS 2,
          lv_baseiva0   TYPE prcd_elements-kawrt,
          lv_baseiva8   TYPE prcd_elements-kawrt,
          lv_baseiva16  TYPE prcd_elements-kawrt,
          lv_porcbase0  TYPE p LENGTH 9 DECIMALS 14,
          lv_porcbase8  TYPE p LENGTH 9 DECIMALS 14,
          lv_porcbase16 TYPE p LENGTH 9 DECIMALS 14,
          lv_matnr0     TYPE c LENGTH 18,
          lv_matnriva   TYPE c LENGTH 18.

    CONSTANTS: lc_true      TYPE c LENGTH 1 VALUE 'X',
               lc_bobj      TYPE bapiusw01-objtype VALUE 'BUS2094',
               lc_doctype   TYPE c LENGTH 4 VALUE 'ZNTC',
               lv_ordreason TYPE c LENGTH 3 VALUE 'Z72'.


    DATA: lo_msg TYPE REF TO /iwbep/if_message_container.

    CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
      RECEIVING
        ro_message_container = lo_msg.

*Asignación de propiedades de navegación

    DATA: lo_tech_request TYPE REF TO /iwbep/cl_mgw_request.

    lo_tech_request ?= io_tech_request_context.
    DATA(lv_expand) = lo_tech_request->/iwbep/if_mgw_req_entityset~get_expand( ).
    TRANSLATE lv_expand TO UPPER CASE.
    SPLIT lv_expand AT ',' INTO TABLE DATA(et_expanded_tech_clauses).

    IF lv_expand EQ 'TO_NOTACRED'.
      "Lectura del request recibido en el método POST.
      TRY.
          CALL METHOD io_data_provider->read_entry_data
            IMPORTING
              es_data = ls_de_cliente.
        CATCH /iwbep/cx_mgw_tech_exception.
      ENDTRY.

      SORT ls_de_cliente-to_notacred ASCENDING BY factura.

      lt_notacred[] = ls_de_cliente-to_notacred.

      SELECT vbeln, vkorg, vtweg, spart, vbtyp, kunag, knumv FROM vbrk AS vb
        INNER JOIN zsd_cfdi_return AS cf ON cf~nodocu EQ vb~vbeln
        FOR ALL ENTRIES IN @lt_notacred
        WHERE vb~vbeln EQ @lt_notacred-factura
        AND vb~fksto EQ ''  "Solo facturas que no estén anuladas
        AND cf~uuid NE ''   "Solo facturas timbradas
        INTO TABLE @DATA(lt_vbrk).

      SORT lt_vbrk BY vbeln ASCENDING.

      IF lt_vbrk[] IS NOT INITIAL.
        SELECT * FROM vbrp
          FOR ALL ENTRIES IN @lt_vbrk
          WHERE vbeln EQ @lt_vbrk-vbeln
          INTO TABLE @DATA(lt_vbrp).

        SELECT * FROM prcd_elements
          FOR ALL ENTRIES IN @lt_vbrk
          WHERE knumv EQ @lt_vbrk-knumv
          INTO TABLE @DATA(lt_prcd).
      ENDIF.

      "Selección de materiales al sin IVA y con IVA.
      IF sy-sysid EQ 'S4D'.
        "Material sin IVA
        SELECT SINGLE valor2 INTO @lv_matnr0
          FROM zparamglob
          WHERE programa EQ 'ZSD_NCRCORONAPUNTOS'
          AND parametro EQ '1'
          AND subparametro EQ '1'
          AND valor1 EQ @sy-sysid.

        "Material con IVA
        SELECT SINGLE valor2 INTO @lv_matnriva
          FROM zparamglob
          WHERE programa EQ 'ZSD_NCRCORONAPUNTOS'
          AND parametro EQ '1'
          AND subparametro EQ '2'
          AND valor1 EQ @sy-sysid.

      ELSEIF sy-sysid EQ 'S4Q'.
        "Material sin IVA
        SELECT SINGLE valor2 INTO @lv_matnr0
          FROM zparamglob
          WHERE programa EQ 'ZSD_NCRCORONAPUNTOS'
          AND parametro EQ '2'
          AND subparametro EQ '1'
          AND valor1 EQ @sy-sysid.

        "Material con IVA
        SELECT SINGLE valor2 INTO @lv_matnriva
          FROM zparamglob
          WHERE programa EQ 'ZSD_NCRCORONAPUNTOS'
          AND parametro EQ '2'
          AND subparametro EQ '2'
          AND valor1 EQ @sy-sysid.

      ELSEIF sy-sysid EQ 'S4P'.
        "Material sin IVA
        SELECT SINGLE valor2 INTO @lv_matnr0
          FROM zparamglob
          WHERE programa EQ 'ZSD_NCRCORONAPUNTOS'
          AND parametro EQ '3'
          AND subparametro EQ '1'
          AND valor1 EQ @sy-sysid.

        "Material con IVA
        SELECT SINGLE valor2 INTO @lv_matnriva
          FROM zparamglob
          WHERE programa EQ 'ZSD_NCRCORONAPUNTOS'
          AND parametro EQ '3'
          AND subparametro EQ '2'
          AND valor1 EQ @sy-sysid.
      ENDIF.
      lv_matnr0 = |{ lv_matnr0 ALPHA = IN }|.
      lv_matnriva = |{ lv_matnriva ALPHA = IN }|.

      LOOP AT lt_notacred ASSIGNING FIELD-SYMBOL(<fs_notacred>).
        READ TABLE lt_vbrk ASSIGNING FIELD-SYMBOL(<fs_vbrk>) WITH KEY vbeln = <fs_notacred>-factura.
        READ TABLE lt_vbrp ASSIGNING FIELD-SYMBOL(<fs_vbrp>) WITH KEY vbeln = <fs_notacred>-factura.

        IF <fs_vbrk> IS ASSIGNED.
          "Se llenan estructuras HEADER_IN y HEADER_INX.
          ls_header_in-doc_type   = lc_doctype.
          ls_header_in-sales_org  = <fs_vbrk>-vkorg.
          ls_header_in-distr_chan = <fs_vbrk>-vtweg.
          ls_header_in-division   = <fs_vbrk>-spart.
          ls_header_in-sales_grp  = <fs_vbrp>-vkgrp.
          ls_header_in-sales_off  = <fs_vbrp>-vkbur.
          ls_header_in-purch_date = sy-datum.
          ls_header_in-ord_reason = lv_ordreason.
          ls_header_in-purch_no_c = 'NCR Corona Puntos'.
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

          IF lt_prcd[] IS NOT INITIAL.
            "Subtotal de la factura.
            LOOP AT lt_prcd ASSIGNING FIELD-SYMBOL(<fs_prcd>) WHERE knumv EQ <fs_vbrk>-knumv AND kstat NE 'X' AND koaid EQ 'B' AND kinak EQ '' AND ( kschl EQ 'ZPR1' OR kschl EQ 'ZPR0' ).
              lv_subtotal = lv_subtotal + <fs_prcd>-kwert.
            ENDLOOP.
            UNASSIGN <fs_prcd>.

            "Obtenemos el monto de descuentos.
            LOOP AT lt_prcd ASSIGNING <fs_prcd> WHERE knumv EQ <fs_vbrk>-knumv AND kstat NE 'X' AND koaid EQ 'A' AND kwert LT 0 AND kinak EQ ''.
              lv_descuento = lv_descuento + <fs_prcd>-kwert.
            ENDLOOP.
            UNASSIGN <fs_prcd>.

            "Obtenemos el monto de IVA total
            LOOP AT lt_prcd ASSIGNING <fs_prcd> WHERE knumv EQ <fs_vbrk>-knumv AND kschl EQ 'MWST' AND  kstat NE 'X' AND koaid EQ 'D' AND kinak EQ ''.
              lv_iva = lv_iva + <fs_prcd>-kwert.
            ENDLOOP.
            UNASSIGN <fs_prcd>.
          ENDIF.

          "lv_totfac = lv_subtotal + lv_iva + lv_descuento.
          lv_totfac = lv_subtotal + lv_descuento.

          "Obtener Montos de IVA por Tasa

          "Total Traslados Base IVA 0
          LOOP AT lt_prcd ASSIGNING <fs_prcd> WHERE knumv EQ <fs_vbrk>-knumv AND kschl EQ 'MWST' AND  kstat NE 'X' AND koaid EQ 'D' AND kinak EQ '' AND ( mwsk1 EQ 'A0' OR mwsk1 EQ 'B0' OR mwsk1 EQ 'A3' OR mwsk1 EQ 'B3').
            lv_baseiva0 = ( lv_baseiva0 + <fs_prcd>-kawrt ).
          ENDLOOP.
          UNASSIGN <fs_prcd>.

          "Total Traslados Base IVA 8
          LOOP AT lt_prcd ASSIGNING <fs_prcd> WHERE knumv EQ <fs_vbrk>-knumv AND kschl EQ 'MWST' AND  kstat NE 'X' AND koaid EQ 'D' AND kinak EQ '' AND ( mwsk1 EQ 'A1' OR mwsk1 EQ 'A4' OR mwsk1 EQ 'B1' OR mwsk1 EQ 'B4').
            lv_baseiva8 = ( lv_baseiva8 + <fs_prcd>-kawrt ).
          ENDLOOP.
          UNASSIGN <fs_prcd>.

          "Total Traslados Base IVA 16
          LOOP AT lt_prcd ASSIGNING <fs_prcd> WHERE knumv EQ <fs_vbrk>-knumv AND kschl EQ 'MWST' AND  kstat NE 'X' AND koaid EQ 'D' AND kinak EQ '' AND ( mwsk1 EQ 'A2' OR mwsk1 EQ 'B2').
            lv_baseiva16 = ( lv_baseiva16 + <fs_prcd>-kawrt ).
          ENDLOOP.
          UNASSIGN <fs_prcd>.

          "Determina porcentajes de Bases de IVA vs Total Factura (Subtotal menos descuentos)
          lv_porcbase0  = round( val = ( lv_baseiva0 / lv_totfac ) dec = 14 ).
          lv_porcbase8  = round( val = ( lv_baseiva8 / lv_totfac ) dec = 14 ).
          lv_porcbase16 = round( val = ( lv_baseiva16 / lv_totfac ) dec = 14 ).

          "ENDIF.

          "Se captura material con IVA al 0%
          IF lv_porcbase0 NE '0.00000000000000'.
            "Obtenemos número de posición.
            IF line_exists( lt_items_in[ itm_number = '000010' ] ).
              SORT lt_items_in DESCENDING BY itm_number.
              READ TABLE lt_items_in ASSIGNING FIELD-SYMBOL(<fs_items>) INDEX 1.
              lv_posnr = <fs_items>-itm_number + 10.
              CONDENSE lv_posnr.
              lv_posnr = |{ lv_posnr ALPHA = IN }|.
            ELSE.
              lv_posnr = '000010'.
            ENDIF.
            UNASSIGN: <fs_items>.

            "Se llenan estructuras y tablas internas para ITEMS_IN y ITEMS_INX
            ls_items_in-itm_number = lv_posnr.
            ls_items_in-material   = lv_matnr0.
            ls_items_in-plant      = <fs_vbrp>-werks.
            ls_items_in-target_qty = '1.000'.
            ls_items_in-target_qu  = 'SER'.

            ls_items_inx-itm_number = lv_posnr.
            ls_items_inx-material   = lc_true.
            ls_items_inx-plant      = lc_true.
            ls_items_inx-target_qty = lc_true.
            ls_items_inx-target_qu  = lc_true.

            APPEND: ls_items_in  TO lt_items_in,
                    ls_items_inx TO lt_items_inx.

            CLEAR: ls_items_in, ls_items_inx.


            "Se llenan estructuras y tablas internas para SCHEDULES_IN y SCHEDULES_INX
            ls_sched_in-itm_number = lv_posnr.
            ls_sched_in-req_qty    = '1.000'.

            ls_sched_inx-itm_number = lv_posnr.
            ls_sched_inx-req_qty    = lc_true.

            APPEND: ls_sched_in  TO lt_sched_in,
                    ls_sched_inx TO lt_sched_inx.

            CLEAR: ls_sched_in, ls_sched_inx.

            "Se llenan estructuras y tablas internas para CONDITIONS_IN y CONDITIONS_INX
            ls_cond_in-itm_number = lv_posnr.
            ls_cond_in-cond_type  = 'ZNC1'.
            IF lv_porcbase0 LT '1'.
              ls_cond_in-cond_value = round( val = ( <fs_notacred>-importe * lv_porcbase0 ) dec = 2 ).
            ELSE.
              ls_cond_in-cond_value = <fs_notacred>-importe.
            ENDIF.
            ls_cond_in-currency   = 'MXN'.
            ls_cond_in-cond_unit  = 'SER'.
            ls_cond_in-cond_p_unt = '1'.

            ls_cond_inx-itm_number = lv_posnr.
            ls_cond_inx-cond_type  = 'ZNC1'.
            ls_cond_inx-cond_value = lc_true.
            ls_cond_inx-currency   = lc_true.
            ls_cond_inx-cond_unit  = lc_true.
            ls_cond_inx-cond_p_unt = lc_true.

            APPEND: ls_cond_in  TO lt_cond_in,
                    ls_cond_inx TO lt_cond_inx.

            CLEAR: ls_cond_in, ls_cond_inx.
          ENDIF.

          "Se captura material con IVA al 8%
          IF lv_porcbase8 NE '0.00000000000000'.
            "Obtenemos número de posición.
            IF line_exists( lt_items_in[ itm_number = '000010' ] ).
              SORT lt_items_in DESCENDING BY itm_number.
              READ TABLE lt_items_in ASSIGNING <fs_items> INDEX 1.
              lv_posnr = <fs_items>-itm_number + 10.
              CONDENSE lv_posnr.
              lv_posnr = |{ lv_posnr ALPHA = IN }|.
            ELSE.
              lv_posnr = '000010'.
            ENDIF.
            UNASSIGN: <fs_items>.

            "Se llenan estructuras y tablas internas para ITEMS_IN y ITEMS_INX
            ls_items_in-itm_number = lv_posnr.
            ls_items_in-material   = lv_matnriva.
            ls_items_in-plant      = <fs_vbrp>-werks.
            ls_items_in-target_qty = '1.000'.
            ls_items_in-target_qu  = 'SER'.

            ls_items_inx-itm_number = lv_posnr.
            ls_items_inx-material   = lc_true.
            ls_items_inx-plant      = lc_true.
            ls_items_inx-target_qty = lc_true.
            ls_items_inx-target_qu  = lc_true.

            APPEND: ls_items_in  TO lt_items_in,
                    ls_items_inx TO lt_items_inx.

            CLEAR: ls_items_in, ls_items_inx.


            "Se llenan estructuras y tablas internas para SCHEDULES_IN y SCHEDULES_INX
            ls_sched_in-itm_number = lv_posnr.
            ls_sched_in-req_qty    = '1.000'.

            ls_sched_inx-itm_number = lv_posnr.
            ls_sched_inx-req_qty    = lc_true.

            APPEND: ls_sched_in  TO lt_sched_in,
                    ls_sched_inx TO lt_sched_inx.

            CLEAR: ls_sched_in, ls_sched_inx.

            "Se llenan estructuras y tablas internas para CONDITIONS_IN y CONDITIONS_INX
            ls_cond_in-itm_number = lv_posnr.
            ls_cond_in-cond_type  = 'ZNC1'.
            IF lv_porcbase8 LT '1'.
              ls_cond_in-cond_value = round( val = ( ( <fs_notacred>-importe * lv_porcbase8 ) / '1.08' ) dec = 2 ).
            ELSE.
              ls_cond_in-cond_value = ( <fs_notacred>-importe / '1.08' ).
            ENDIF.
            ls_cond_in-currency   = 'MXN'.
            ls_cond_in-cond_unit  = 'SER'.
            ls_cond_in-cond_p_unt = '1'.

            ls_cond_inx-itm_number = lv_posnr.
            ls_cond_inx-cond_type  = 'ZNC1'.
            ls_cond_inx-cond_value = lc_true.
            ls_cond_inx-currency   = lc_true.
            ls_cond_inx-cond_unit  = lc_true.
            ls_cond_inx-cond_p_unt = lc_true.

            APPEND: ls_cond_in  TO lt_cond_in,
                    ls_cond_inx TO lt_cond_inx.

            CLEAR: ls_cond_in, ls_cond_inx.
          ENDIF.

          "Se captura material con IVA al 16%
          IF lv_porcbase16 NE '0.00000000000000'.
            "Obtenemos número de posición.
            IF line_exists( lt_items_in[ itm_number = '000010' ] ).
              SORT lt_items_in DESCENDING BY itm_number.
              READ TABLE lt_items_in ASSIGNING <fs_items> INDEX 1.
              lv_posnr = <fs_items>-itm_number + 10.
              CONDENSE lv_posnr.
              lv_posnr = |{ lv_posnr ALPHA = IN }|.
            ELSE.
              lv_posnr = '000010'.
            ENDIF.
            UNASSIGN: <fs_items>.

            "Se llenan estructuras y tablas internas para ITEMS_IN y ITEMS_INX
            ls_items_in-itm_number = lv_posnr.
            ls_items_in-material   = lv_matnriva.
            ls_items_in-plant      = <fs_vbrp>-werks.
            ls_items_in-target_qty = '1.000'.
            ls_items_in-target_qu  = 'SER'.

            ls_items_inx-itm_number = lv_posnr.
            ls_items_inx-material   = lc_true.
            ls_items_inx-plant      = lc_true.
            ls_items_inx-target_qty = lc_true.
            ls_items_inx-target_qu  = lc_true.

            APPEND: ls_items_in  TO lt_items_in,
                    ls_items_inx TO lt_items_inx.

            CLEAR: ls_items_in, ls_items_inx.


            "Se llenan estructuras y tablas internas para SCHEDULES_IN y SCHEDULES_INX
            ls_sched_in-itm_number = lv_posnr.
            ls_sched_in-req_qty    = '1.000'.

            ls_sched_inx-itm_number = lv_posnr.
            ls_sched_inx-req_qty    = lc_true.

            APPEND: ls_sched_in  TO lt_sched_in,
                    ls_sched_inx TO lt_sched_inx.

            CLEAR: ls_sched_in, ls_sched_inx.

            "Se llenan estructuras y tablas internas para CONDITIONS_IN y CONDITIONS_INX
            ls_cond_in-itm_number = lv_posnr.
            ls_cond_in-cond_type  = 'ZNC1'.
            IF lv_porcbase16 LT '1'.
              ls_cond_in-cond_value = round( val = ( ( <fs_notacred>-importe * lv_porcbase16 ) / '1.16' ) dec = 2 ).
            ELSE.
              ls_cond_in-cond_value = ( <fs_notacred>-importe / '1.16' ).
            ENDIF.
            ls_cond_in-currency   = 'MXN'.
            ls_cond_in-cond_unit  = 'SER'.
            ls_cond_in-cond_p_unt = '1'.

            ls_cond_inx-itm_number = lv_posnr.
            ls_cond_inx-cond_type  = 'ZNC1'.
            ls_cond_inx-cond_value = lc_true.
            ls_cond_inx-currency   = lc_true.
            ls_cond_inx-cond_unit  = lc_true.
            ls_cond_inx-cond_p_unt = lc_true.

            APPEND: ls_cond_in  TO lt_cond_in,
                    ls_cond_inx TO lt_cond_inx.

            CLEAR: ls_cond_in, ls_cond_inx.
          ENDIF.

          "Se ejecuta la BAPI para crear la solicitud de nota de crédito con referencia a la factura.
          CALL FUNCTION 'SD_SALESDOCUMENT_CREATE'
            EXPORTING
              sales_header_in       = ls_header_in
              sales_header_inx      = ls_header_inx
              business_object       = lc_bobj
              status_buffer_refresh = 'X'
              i_refresh_v45i        = 'X'
              i_check_ag            = 'X'
            IMPORTING
              salesdocument_ex      = lv_ncr
            TABLES
              return                = lt_return
              sales_items_in        = lt_items_in
              sales_items_inx       = lt_items_inx
              sales_partners        = lt_partners
              sales_schedules_in    = lt_sched_in
              sales_schedules_inx   = lt_sched_inx
              sales_conditions_in   = lt_cond_in
              sales_conditions_inx  = lt_cond_inx.

          IF lv_ncr NE ''.
            CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.

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
            UNASSIGN: <fs_success>.
            IF lv_factura NE ''.
              CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
              "Regresa número de NCR en el response.
              <fs_notacred>-ncr = lv_factura.
            ELSE.
              CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
            ENDIF.
          ELSE.
            CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
          ENDIF.
          UNASSIGN: <fs_vbrk>.
        ENDIF.
        CLEAR: lv_subtotal, lv_descuento, lv_iva, lv_totfac, lv_baseiva0, lv_baseiva8, lv_baseiva16 ,lv_porcbase0, lv_porcbase8, lv_porcbase16, lv_ncr, lv_factura, lv_posnr.
      ENDLOOP.
      UNASSIGN: <fs_notacred>.

      ls_de_cliente-to_notacred[] = lt_notacred[].

      me->copy_data_to_ref(
     EXPORTING
       is_data = ls_de_cliente
     CHANGING
       cr_data = er_deep_entity
     ).

    ENDIF.

  ENDMETHOD.
ENDCLASS.
