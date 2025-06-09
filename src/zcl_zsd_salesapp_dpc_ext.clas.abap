class ZCL_ZSD_SALESAPP_DPC_EXT definition
  public
  inheriting from ZCL_ZSD_SALESAPP_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CREATE_DEEP_ENTITY
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_EXPANDED_ENTITY
    redefinition .
protected section.

  methods MONITORTRASLADOS_GET_ENTITYSET
    redefinition .
  methods TRASLADORESULTSE_CREATE_ENTITY
    redefinition .
  methods TRASLADOSSET_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZSD_SALESAPP_DPC_EXT IMPLEMENTATION.


  METHOD /iwbep/if_mgw_appl_srv_runtime~create_deep_entity.
    DATA: gs_de_orders TYPE zcl_zsd_salesapp_mpc=>ts_de_header.

    DATA: gs_partners_data           TYPE zcl_zsd_salesapp_mpc=>ts_de_partners,
          gt_partners_data           TYPE zcl_zsd_salesapp_mpc=>tt_de_partners,
          gs_partneraddressesag_data TYPE zcl_zsd_salesapp_mpc=>ts_sopartneraddresses,
          gt_partneraddressesag_data TYPE zcl_zsd_salesapp_mpc=>tt_sopartneraddresses,
          gs_partneraddresseswe_data TYPE zcl_zsd_salesapp_mpc=>ts_sopartneraddresses,
          gt_partneraddresseswe_data TYPE zcl_zsd_salesapp_mpc=>tt_sopartneraddresses,
          gs_header_data             TYPE zcl_zsd_salesapp_mpc=>ts_soheader,
          gs_items_data              TYPE zcl_zsd_salesapp_mpc=>ts_de_items,
          gt_items_data              TYPE zcl_zsd_salesapp_mpc=>tt_de_items,
          gs_texts_data              TYPE zcl_zsd_salesapp_mpc=>ts_sotexts,
          gt_texts_data              TYPE zcl_zsd_salesapp_mpc=>tt_sotexts,
          gs_partnersitem_data       TYPE zcl_zsd_salesapp_mpc=>ts_sopartnersitem,
          gt_partnersitem_data       TYPE zcl_zsd_salesapp_mpc=>tt_sopartnersitem,
          gs_conditionsitem_data     TYPE zcl_zsd_salesapp_mpc=>ts_soconditionsitem,
          gt_conditionsitem_data     TYPE zcl_zsd_salesapp_mpc=>tt_soconditionsitem,
          gs_textsitem_data          TYPE zcl_zsd_salesapp_mpc=>ts_sotextsitem,
          gt_textsitem_data          TYPE zcl_zsd_salesapp_mpc=>tt_sotextsitem,
          ls_header_in               TYPE bapisdhd1,
          ls_header_inx              TYPE bapisdhd1x,
          ls_items_in                TYPE bapisditm,
          lt_items_in                TYPE STANDARD TABLE OF bapisditm,
          ls_items_inx               TYPE bapisditmx,
          lt_items_inx               TYPE STANDARD TABLE OF bapisditmx,
          ls_partners                TYPE bapiparnr,
          lt_partners                TYPE STANDARD TABLE OF bapiparnr,
          ls_schedules_in            TYPE bapischdl,
          lt_schedules_in            TYPE STANDARD TABLE OF bapischdl,
          ls_schedules_inx           TYPE bapischdlx,
          lt_schedules_inx           TYPE STANDARD TABLE OF bapischdlx,
          ls_conditions_in           TYPE bapicond,
          lt_conditions_in           TYPE STANDARD TABLE OF bapicond,
          ls_conditions_inx          TYPE bapicondx,
          lt_conditions_inx          TYPE STANDARD TABLE OF bapicondx,
          ls_partneraddresses        TYPE bapiaddr1,
          lt_partneraddresses        TYPE STANDARD TABLE OF bapiaddr1,
          ls_text                    TYPE bapisdtext,
          lt_text                    TYPE STANDARD TABLE OF bapisdtext,
          ls_return                  TYPE bapiret2,
          lt_return                  TYPE STANDARD TABLE OF bapiret2,
          lt_header                  TYPE thead,
          lt_lines                   TYPE STANDARD TABLE OF tline,
          lt_lines1                  TYPE STANDARD TABLE OF tdline.

    DATA: lv_vkorg     TYPE vkorg,
          lv_vtweg     TYPE vtweg,
          lv_spart     TYPE spart,
          lv_vkgrp     TYPE vkgrp,
          lv_vkbur     TYPE vkbur,
          lv_vsbed     TYPE vsbed,
          lv_vkorgwe   TYPE vkorg,
          lv_vtwegwe   TYPE vtweg,
          lv_spartwe   TYPE spart,
          lv_vkgrpwe   TYPE vkgrp,
          lv_vkburwe   TYPE vkbur,
          lv_vsbedwe   TYPE vsbed,
          lv_vbeln     TYPE vbeln,
          lv_vbeln_ret TYPE vbeln,
          lv_kunag     TYPE kunnr,
          lv_kunwe     TYPE kunwe,
          lv_cpd       TYPE xcpdk,
          lv_auart     TYPE auart,
          lv_datediff  TYPE erdat,
          lv_daysdiff  TYPE c LENGTH 6,
          lv_daysdiff1 TYPE dlydy,
          lv_daysadd   TYPE c LENGTH 6,
          lv_daysadd1  TYPE dlydy,
          lv_calcdate  TYPE erdat,
          lv_material  TYPE c LENGTH 18,
          lv_entrega   TYPE likp-vbeln,
          lv_error_msg TYPE bapi_msg,         "Variable para errores char 220.
          lv_error_msg1 TYPE bapi_msg,
          lv_error_msg2 TYPE bapi_msg.

    CONSTANTS: abap_true  TYPE c LENGTH 1 VALUE 'X'.

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

*PEDIDOS Y FACTURACION
    IF lv_expand EQ 'TO_ITEMS/TO_PARTNERSITEM,TO_ITEMS/TO_CONDITIONSITEM,TO_ITEMS/TO_TEXTSITEM,TO_PARTNERS/TO_PARTNERADRESSES,TO_TEXTS'.

*Lectura del request recibido en el método POST.
      TRY.
          CALL METHOD io_data_provider->read_entry_data
            IMPORTING
              es_data = gs_de_orders.
        CATCH /iwbep/cx_mgw_tech_exception.
      ENDTRY.
*Movemos la parte de cabecera al WA correspondiente, se hacen validaciones correspondientes y se agrega a la estructura ls_header_in para enviar en la BAPI de pedidos de venta.
      MOVE-CORRESPONDING gs_de_orders TO gs_header_data.
      IF NOT gs_header_data IS INITIAL.

        gt_partners_data[] = gs_de_orders-to_partners[].
        LOOP AT gt_partners_data INTO gs_partners_data WHERE partn_role EQ 'AG' OR partn_role EQ 'SO'.
*Se busca el número de cliente por GLN o número de identificación propio del cliente
          SELECT SINGLE partner INTO lv_kunag
            FROM but0id
            WHERE ( type  EQ 'ZBUEDI' OR type EQ 'ZBUGLN' )
            AND idnumber EQ gs_partners_data-partn_numb.
          IF sy-subrc NE 0.
            lv_kunag = |{ gs_partners_data-partn_numb ALPHA = IN }|.
          ENDIF.
          SELECT SINGLE vkorg, vtweg, spart, vkgrp, vkbur, vsbed
            INTO ( @lv_vkorg, @lv_vtweg, @lv_spart, @lv_vkgrp, @lv_vkbur, @lv_vsbed )
            FROM knvv
            WHERE kunnr EQ @lv_kunag
            AND vkorg EQ @gs_header_data-sales_org
            AND vtweg EQ @gs_header_data-distr_chan.
          IF sy-subrc NE 0.
*Regresar error indicando que se debe validar que el cliente exista en la base de datos de SAP y que esté extendido a un área de ventas.
            CONCATENATE 'Valide que el cliente' gs_partners_data-partn_numb 'exista en la BD de SAP y que este extendido a un area de ventas.' INTO lv_error_msg SEPARATED BY space.
            CALL METHOD lo_msg->add_message
              EXPORTING
                iv_msg_type   = /iwbep/cl_cos_logger=>error
                iv_msg_id     = 'ZSD_MSG'
                iv_msg_number = '001'
                iv_msg_text   = lv_error_msg.
            RETURN.
          ENDIF.
*Se valida si el cliente es CPD.
          SELECT SINGLE xcpdk INTO lv_cpd
            FROM kna1
            WHERE kunnr = lv_kunag.

*Si el cliente es CPD se toman los datos de dirección del request.
          IF lv_cpd EQ 'X'.
            gt_partneraddressesag_data[] = gs_partners_data-to_partneraddresses[].
          ENDIF.
        ENDLOOP.
        CLEAR gs_partners_data.

*Se valida que no exista un pedido de cliente duplicado creado previamente en el sistema en los últimos "N" meses.

        SELECT SINGLE valor1
          INTO @lv_daysdiff
          FROM zparamglob
          WHERE programa = 'ZSD_CARGAPEDIDOS'
          AND parametro = '6'
          AND subparametro = '1'.

        lv_daysdiff1 = lv_daysdiff.

        CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
          EXPORTING
            date      = sy-datum
            days      = lv_daysdiff1
            months    = 0
            signum    = '-' " para calcular fechas anteriores
            years     = 0
          IMPORTING
            calc_date = lv_datediff.

        SELECT SINGLE a~vbeln
          INTO lv_vbeln
          FROM vbkd AS a
          INNER JOIN vbak AS b
          ON a~vbeln EQ b~vbeln
          WHERE a~bstkd EQ gs_header_data-purch_no_c
          AND b~kunnr EQ lv_kunag
          AND b~erdat GE lv_datediff.
        IF sy-subrc EQ 0.
* Regresar error con número de pedido de cliente y número de pedido SAP creado previamente.
          CONCATENATE 'El pedido de cliente' gs_header_data-purch_no_c 'está previamente registrado con el número de pedido SAP: ' lv_vbeln INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZSD_MSG'
              iv_msg_number = '002'
              iv_msg_text   = lv_error_msg.
          RETURN.
        ELSE.

          LOOP AT gt_partners_data INTO gs_partners_data WHERE partn_role EQ 'WE' OR partn_role EQ 'DM'.
*Se busca el número de cliente por GLN o número de identificación propio del cliente
            SELECT SINGLE partner INTO lv_kunwe
              FROM but0id
              WHERE ( type  EQ 'ZBUEDI' OR type EQ 'ZBUGLN' )
              AND idnumber EQ gs_partners_data-partn_numb.
            IF sy-subrc NE 0.
              lv_kunwe = |{ gs_partners_data-partn_numb ALPHA = IN }|.
            ENDIF.
            SELECT SINGLE vkorg, vtweg, spart, vkgrp, vkbur, vsbed
              INTO ( @lv_vkorgwe, @lv_vtwegwe, @lv_spartwe, @lv_vkgrpwe, @lv_vkburwe, @lv_vsbedwe )
              FROM knvv
              WHERE kunnr EQ @lv_kunwe
              AND vkorg EQ @gs_header_data-sales_org
              AND vtweg EQ @gs_header_data-distr_chan..
            IF sy-subrc NE 0.
*Regresar error indicando que se debe validar que el cliente destinatario de mercancía exista en la base de datos de SAP y que esté extendido a un área de ventas.
              CONCATENATE 'Valide que el destinatario de mercancia' gs_partners_data-partn_numb 'exista en la BD de SAP y que este extendido a un area de ventas.' INTO lv_error_msg SEPARATED BY space.
              CALL METHOD lo_msg->add_message
                EXPORTING
                  iv_msg_type   = /iwbep/cl_cos_logger=>error
                  iv_msg_id     = 'ZSD_MSG'
                  iv_msg_number = '003'
                  iv_msg_text   = lv_error_msg.
              RETURN.
            ENDIF.

*Se valida si el cliente es CPD.
            SELECT SINGLE xcpdk INTO lv_cpd
              FROM kna1
              WHERE kunnr = lv_kunwe.

*Si el cliente es CPD se toman los datos de dirección del request.
            IF lv_cpd EQ 'X'.
              gt_partneraddresseswe_data[] = gs_partners_data-to_partneraddresses[].
            ENDIF.
          ENDLOOP.
          CLEAR gs_partners_data.

          IF gs_header_data-purch_date EQ '19700101'.
            gs_header_data-purch_date = sy-datum.
          ENDIF.

          IF gs_header_data-price_date EQ '19700101'.
            gs_header_data-price_date = sy-datum.
          ENDIF.

* Si la fecha preferente de entrega es menor a la fecha actual, se debe dejar para tratar pedidos antiguos cargados por intefaz en carga inicial.
*          IF gs_de_orders-req_date_h EQ '19700101' OR gs_de_orders-req_date_h LE sy-datum OR gs_de_orders-req_date_h EQ '00000000'.
          IF gs_de_orders-req_date_h EQ '19700101' OR gs_de_orders-req_date_h EQ '00000000'.
            SELECT SINGLE valor2
                   INTO @lv_daysadd
                   FROM zparamglob
                   WHERE programa = 'ZSD_CARGAPEDIDOS'
                   AND parametro = '6'
                   AND valor1 = @lv_vtweg.

            IF sy-subrc EQ 0.
*Calcula fecha preferente de entrega para canales dados de alta en la tabla zparamglob
              lv_daysadd1 = lv_daysadd.

              CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
                EXPORTING
                  date      = sy-datum
                  days      = lv_daysadd1
                  months    = 0
                  signum    = '+' " para calcular fechas posteriores
                  years     = 0
                IMPORTING
                  calc_date = lv_calcdate.
            ELSE.
*Calcula fecha preferente de entrega para canales que no estén registrados en la tabla zparamglob
              SELECT SINGLE valor1
                   INTO @lv_daysadd
                   FROM zparamglob
                   WHERE programa = 'ZSD_CARGAPEDIDOS'
                   AND parametro = '6'
                   AND subparametro = '5'.
              IF sy-subrc EQ 0.

                lv_daysadd1 = lv_daysadd.

                CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
                  EXPORTING
                    date      = sy-datum
                    days      = lv_daysadd1
                    months    = 0
                    signum    = '+' " para calcular fechas posteriores
                    years     = 0
                  IMPORTING
                    calc_date = lv_calcdate.
              ENDIF.
            ENDIF.
          ENDIF.
*Pasamos el valor de lv_calcdate a gs_header_data-req_date_h
          IF lv_calcdate NE '00000000'.
            gs_header_data-req_date_h = lv_calcdate.
          ELSE.
            gs_header_data-req_date_h = gs_de_orders-req_date_h.
          ENDIF.
*Se busca la clase de documento de ventas en la tabla de parámetros globales (una clase de documento de verntas por canal).
          SELECT SINGLE valor2
            INTO lv_auart
            FROM zparamglob
            WHERE programa EQ 'ZSD_CARGAPEDIDOS'
            AND parametro EQ '1'
            AND valor1 EQ lv_vtweg.

*Se llena la estructura para ORDER_HEADER_IN en la bapi.
          ls_header_in-doc_type = lv_auart.
          ls_header_in-sales_org = lv_vkorg.
          ls_header_in-distr_chan = lv_vtweg.
          ls_header_in-division = lv_spart.
          ls_header_in-sales_grp = lv_vkgrp.
          ls_header_in-sales_off = lv_vkbur.
          ls_header_in-req_date_h = gs_header_data-req_date_h.
          ls_header_in-purch_date = gs_header_data-purch_date.
          ls_header_in-po_method = gs_header_data-po_method.
          ls_header_in-incoterms1 = gs_header_data-incoterms1.
          ls_header_in-ord_reason = gs_header_data-ord_reason.
          ls_header_in-purch_no_c = gs_header_data-purch_no_c.
          ls_header_in-ship_cond = gs_header_data-ship_cond.
          ls_header_in-pymt_meth = gs_header_data-pymt_meth.
          ls_header_in-price_date = gs_header_data-price_date.
          ls_header_in-ref_1 = gs_header_data-ref_1.

*Se llena la estructura para ORDER_HEADER_INX en la bapi.
          ls_header_inx-doc_type = abap_true.
          ls_header_inx-sales_org = abap_true.
          ls_header_inx-distr_chan = abap_true.
          ls_header_inx-division = abap_true.
          ls_header_inx-sales_grp = abap_true.
          ls_header_inx-sales_off = abap_true.
          ls_header_inx-req_date_h = abap_true.
          ls_header_inx-purch_date = abap_true.
          ls_header_inx-po_method = abap_true.
          ls_header_inx-incoterms1 = abap_true.
          ls_header_inx-ord_reason = abap_true.
          ls_header_inx-purch_no_c = abap_true.
          ls_header_inx-ship_cond = abap_true.
          ls_header_inx-pymt_meth = abap_true.
          ls_header_inx-price_date = abap_true.
          ls_header_inx-ref_1 = abap_true.

*Se llena estructura para interlocutores comerciales a nivel cabecera y se pasará a la BAPI.
          LOOP AT gt_partners_data INTO gs_partners_data.
            IF lv_cpd EQ ''.
              CASE gs_partners_data-partn_role.
                WHEN 'AG' OR 'SO'.
                  ls_partners-partn_role = gs_partners_data-partn_role.
                  ls_partners-partn_numb = lv_kunag.
                WHEN 'WE' OR 'DM'.
                  ls_partners-partn_role = gs_partners_data-partn_role.
                  ls_partners-partn_numb = lv_kunwe.
                WHEN OTHERS.
                  ls_partners-partn_role = gs_partners_data-partn_role.
                  ls_partners-partn_numb = gs_partners_data-partn_numb.
              ENDCASE.
              APPEND ls_partners TO lt_partners.
            ENDIF.
            IF lv_cpd EQ 'X'.
              CASE gs_partners_data-partn_role.
                WHEN 'AG' OR 'SO'.
                  ls_partners-partn_role = gs_partners_data-partn_role.
                  ls_partners-partn_numb = lv_kunag.
                  ls_partners-addr_link  = gs_partners_data-addr_link.
                  LOOP AT gt_partneraddressesag_data INTO DATA(wa_partneraddressesag_data).

                    ls_partneraddresses-addr_no    = wa_partneraddressesag_data-addr_no.
                    ls_partneraddresses-name       = wa_partneraddressesag_data-name.
                    ls_partneraddresses-name_2     = wa_partneraddressesag_data-name_2.
                    ls_partneraddresses-name_3     = wa_partneraddressesag_data-name_3.
                    ls_partneraddresses-name_4     = wa_partneraddressesag_data-name_4.
                    ls_partneraddresses-city       = wa_partneraddressesag_data-city.
                    ls_partneraddresses-district   = wa_partneraddressesag_data-district.
                    ls_partneraddresses-postl_cod1 = wa_partneraddressesag_data-postl_cod1.
                    ls_partneraddresses-street     = wa_partneraddressesag_data-street.
                    ls_partneraddresses-street_no  = wa_partneraddressesag_data-street_no.
                    ls_partneraddresses-house_no   = wa_partneraddressesag_data-house_no.
                    ls_partneraddresses-country    = wa_partneraddressesag_data-country.
                    ls_partneraddresses-langu      = wa_partneraddressesag_data-langu.
                    ls_partneraddresses-region     = wa_partneraddressesag_data-region.
                    ls_partneraddresses-tel1_numbr = wa_partneraddressesag_data-tel1_numbr.
                    ls_partneraddresses-e_mail     = wa_partneraddressesag_data-e_mail.

                    APPEND ls_partneraddresses TO lt_partneraddresses.
                    CLEAR ls_partneraddresses.

                  ENDLOOP.
                WHEN 'WE' OR 'DM'.
                  ls_partners-partn_role = gs_partners_data-partn_role.
                  ls_partners-partn_numb = lv_kunwe.
                  ls_partners-addr_link  = gs_partners_data-addr_link.
                  LOOP AT gt_partneraddresseswe_data INTO DATA(wa_partneraddresseswe_data).

                    ls_partneraddresses-addr_no    = wa_partneraddresseswe_data-addr_no.
                    ls_partneraddresses-name       = wa_partneraddresseswe_data-name.
                    ls_partneraddresses-name_2     = wa_partneraddresseswe_data-name_2.
                    ls_partneraddresses-name_3     = wa_partneraddresseswe_data-name_3.
                    ls_partneraddresses-name_4     = wa_partneraddresseswe_data-name_4.
                    ls_partneraddresses-city       = wa_partneraddresseswe_data-city.
                    ls_partneraddresses-district   = wa_partneraddresseswe_data-district.
                    ls_partneraddresses-postl_cod1 = wa_partneraddresseswe_data-postl_cod1.
                    ls_partneraddresses-street     = wa_partneraddresseswe_data-street.
                    ls_partneraddresses-street_no  = wa_partneraddresseswe_data-street_no.
                    ls_partneraddresses-house_no   = wa_partneraddresseswe_data-house_no.
                    ls_partneraddresses-country    = wa_partneraddresseswe_data-country.
                    ls_partneraddresses-langu      = wa_partneraddresseswe_data-langu.
                    ls_partneraddresses-region     = wa_partneraddresseswe_data-region.
                    ls_partneraddresses-tel1_numbr = wa_partneraddresseswe_data-tel1_numbr.
                    ls_partneraddresses-e_mail     = wa_partneraddresseswe_data-e_mail.

                    APPEND ls_partneraddresses TO lt_partneraddresses.
                    CLEAR ls_partneraddresses.

                  ENDLOOP.
                WHEN OTHERS.
                  ls_partners-partn_role = gs_partners_data-partn_role.
                  ls_partners-partn_numb = gs_partners_data-partn_numb.
                  ls_partners-addr_link  = gs_partners_data-addr_link.
              ENDCASE.
              APPEND ls_partners TO lt_partners.
            ENDIF.
          ENDLOOP.

*Se llena estructura para textos comerciales a nivel cabecera y se pasará a la BAPI.
          gt_texts_data[] = gs_de_orders-to_texts[].
          LOOP AT gt_texts_data INTO gs_texts_data.
            ls_text-text_id = gs_texts_data-text_id.
            ls_text-langu = 'S'.
            ls_text-text_line = gs_texts_data-text_line.
            APPEND ls_text TO lt_text.
          ENDLOOP.

          gt_items_data[] = gs_de_orders-to_items[].
          LOOP AT gt_items_data INTO gs_items_data.
*Búsqueda de material SAP a partir del material recibido en el request.

            lv_material = gs_items_data-material.

            SELECT SINGLE matnr
              INTO @DATA(lv_matnr)
              FROM mean
              WHERE ean11 = @lv_material
              AND meinh = @gs_items_data-target_qu.
            IF sy-subrc NE 0.
              SELECT SINGLE matnr
                INTO @lv_matnr
                FROM knmt
                WHERE vkorg = @lv_vkorg
                AND vtweg = @lv_vtweg
                AND kunnr = @lv_kunag
                AND kdmat = @lv_material.
              IF sy-subrc NE 0.
                lv_material = |{ gs_items_data-material ALPHA = IN }|.
                SELECT SINGLE matnr
                  INTO @lv_matnr
                  FROM mvke
                  WHERE matnr = @lv_material
                  AND vkorg = @lv_vkorg
                  AND vtweg = @lv_vtweg.
                IF sy-subrc NE 0.
*Si no se encuentra el material, mandar error para que se valide que el material exista en SAP, que esté extendido al área de ventas del cliente, que tenga el EAN correcto o que el registro info exista.
                  CONCATENATE 'Valide que el material' gs_items_data-material 'esté dado de alta en SAP y que este extendido para el area de ventas: ' lv_vkorg '/' lv_vtweg '/' lv_spart INTO lv_error_msg SEPARATED BY space.
                  CALL METHOD lo_msg->add_message
                    EXPORTING
                      iv_msg_type   = /iwbep/cl_cos_logger=>error
                      iv_msg_id     = 'ZSD_MSG'
                      iv_msg_number = '004'
                      iv_msg_text   = lv_error_msg.
                  RETURN.
                ENDIF.
              ENDIF.
            ENDIF.

*Validar que el material no esté marcado para borrado a nivel general
            SELECT SINGLE lvorm
              INTO @DATA(lv_lvorm)
              FROM mara
              WHERE matnr = @lv_matnr.
            IF lv_lvorm EQ ''.
*Validar que el material no esté marcado para borrado en el área de ventas del cliente
              SELECT SINGLE lvorm
                INTO lv_lvorm
                FROM mvke
                WHERE matnr = lv_matnr
                AND vkorg = lv_vkorg
                AND vtweg = lv_vtweg.
              IF lv_lvorm NE ''.
*Mandar error indicando que el material está marcado para borrado.
                CONCATENATE 'El material ' lv_matnr ' esta marcado para borrado en la org. de ventas ' lv_vkorg ' y canal de distr. ' lv_vtweg INTO lv_error_msg SEPARATED BY space.
                CALL METHOD lo_msg->add_message
                  EXPORTING
                    iv_msg_type   = /iwbep/cl_cos_logger=>error
                    iv_msg_id     = 'ZSD_MSG'
                    iv_msg_number = '006'
                    iv_msg_text   = lv_error_msg.
                RETURN.
              ENDIF.
            ELSE.
              CONCATENATE 'El material ' lv_matnr ' esta marcado para borrado general' INTO lv_error_msg SEPARATED BY space.
              CALL METHOD lo_msg->add_message
                EXPORTING
                  iv_msg_type   = /iwbep/cl_cos_logger=>error
                  iv_msg_id     = 'ZSD_MSG'
                  iv_msg_number = '005'
                  iv_msg_text   = lv_error_msg.
              RETURN.
            ENDIF.

*Se llena tabla ITEMS para pasar en la BAPI
            ls_items_in-itm_number = gs_items_data-itm_number.
            ls_items_in-material   = lv_matnr.
            ls_items_in-reason_rej = gs_items_data-reason_rej.
            ls_items_in-prc_group4 = gs_items_data-norembalaje.
            APPEND ls_items_in TO lt_items_in.

*Se llena tabla ITEMS_INX para pasar en la BAPI
            ls_items_inx-itm_number = gs_items_data-itm_number.
            ls_items_inx-material   = abap_true.
            ls_items_inx-reason_rej = abap_true.
            ls_items_inx-prc_group4 = abap_true.
            APPEND ls_items_inx TO lt_items_inx.

            ls_schedules_in-itm_number = gs_items_data-itm_number.
            ls_schedules_in-req_qty    = gs_items_data-target_qty.
            APPEND ls_schedules_in TO lt_schedules_in.

            ls_schedules_inx-itm_number = gs_items_data-itm_number.
            ls_schedules_inx-req_qty    = abap_true.
            APPEND ls_schedules_inx TO lt_schedules_inx.

            gt_conditionsitem_data[] = gs_items_data-to_conditionsitem[].
            LOOP AT gt_conditionsitem_data INTO gs_conditionsitem_data.

              ls_conditions_in-itm_number = gs_items_data-itm_number.
              ls_conditions_in-cond_type  = gs_conditionsitem_data-cond_type.
              ls_conditions_in-cond_value = gs_conditionsitem_data-cond_value.
              ls_conditions_in-currency   = gs_conditionsitem_data-currency.
              ls_conditions_in-cond_unit  = gs_conditionsitem_data-cond_unit.
              ls_conditions_in-cond_p_unt = gs_conditionsitem_data-cond_p_unt.
              APPEND ls_conditions_in TO lt_conditions_in.

              ls_conditions_inx-itm_number = gs_items_data-itm_number.
              ls_conditions_inx-cond_type  = gs_conditionsitem_data-cond_type.
              ls_conditions_inx-cond_value = abap_true.
              ls_conditions_inx-currency   = abap_true.
              ls_conditions_inx-cond_unit  = abap_true.
              ls_conditions_inx-cond_p_unt = abap_true.
              APPEND ls_conditions_inx TO lt_conditions_inx.

            ENDLOOP.

            gt_partnersitem_data[] = gs_items_data-to_partnersitem[].
            LOOP AT gt_partnersitem_data INTO gs_partnersitem_data.



            ENDLOOP.

            gt_textsitem_data[] = gs_items_data-to_textsitem[].
            LOOP AT gt_textsitem_data INTO gs_textsitem_data.

              ls_text-itm_number = gs_items_data-itm_number.
              ls_text-text_id = gs_textsitem_data-text_id.
              ls_text-langu = 'S'.
              ls_text-text_line = gs_textsitem_data-text_line.
              APPEND ls_text TO lt_text.

            ENDLOOP.

          ENDLOOP.

*Se llama a la BAPI para la creación del pedido de ventas.
          TRY.
              CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
                EXPORTING
                  order_header_in      = ls_header_in
                  order_header_inx     = ls_header_inx
                IMPORTING
                  salesdocument        = lv_vbeln_ret
                TABLES
                  return               = lt_return
                  order_items_in       = lt_items_in
                  order_items_inx      = lt_items_inx
                  order_partners       = lt_partners
                  order_schedules_in   = lt_schedules_in
                  order_schedules_inx  = lt_schedules_inx
                  order_conditions_in  = lt_conditions_in
                  order_conditions_inx = lt_conditions_inx
                  order_text           = lt_text
                  partneraddresses     = lt_partneraddresses.
            CATCH /iwbep/cx_mgw_tech_exception.
          ENDTRY.
          IF lv_auart EQ 'ZPOS' OR lv_auart EQ 'ZWEB'.
            LOOP AT lt_return INTO ls_return WHERE type EQ 'S' AND id EQ 'V1' AND ( number EQ '260' OR number EQ '609' ).
              lv_entrega = |{ ls_return-message_v3 ALPHA = IN }|.
            ENDLOOP.
            IF sy-subrc NE 0.
              "El número de mensaje que contiene el número de entrega es distinto en DEV y QAS, para evitar que el programa no se ejecute correctamente
              "por que sea diferente en PRD, se hará una búsqueda en el flujo de documentos para validar la existencia de la entrega.
              SELECT SINGLE vbeln INTO lv_entrega
                FROM vbfa
                WHERE vbelv EQ lv_vbeln_ret
                AND vbtyp_v EQ 'C'
                AND vbtyp_n EQ 'J'.

              IF sy-subrc EQ 0.
                lv_entrega = |{ lv_entrega ALPHA = IN }|.
              ENDIF.
            ENDIF.
            IF lv_entrega EQ ''.
              CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
              lv_error_msg = 'No se creó la entrega correspondiente y tampoco el pedido, favor de validar'.
              CALL METHOD lo_msg->add_message
                EXPORTING
                  iv_msg_type   = /iwbep/cl_cos_logger=>error
                  iv_msg_id     = 'ZSD_MSG'
                  iv_msg_number = '006'
                  iv_msg_text   = lv_error_msg.
              RETURN.
            ELSE.
              IF NOT line_exists( lt_return[ type = 'E' ] ).
                CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
*Lectura del pedido recién creado para devolverlo en el response.
                gs_de_orders-salesdocumentin = lv_vbeln_ret.
              ELSE.
*Lectura de tabla return para enviar el motivo por el que se da error al tratar de crear el pedido.
                CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
                LOOP AT lt_return INTO ls_return.
                  CALL METHOD lo_msg->add_message_from_bapi
                    EXPORTING
                      is_bapi_message           = ls_return
                      iv_add_to_response_header = abap_true
                      iv_message_target         = CONV string( ls_return-field ).
                ENDLOOP.
                RETURN.
              ENDIF.
            ENDIF.
          ELSE.
            IF NOT line_exists( lt_return[ type = 'E' ] ).
              CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
*Lectura del pedido recién creado para devolverlo en el response.
              gs_de_orders-salesdocumentin = lv_vbeln_ret.
            ELSE.
*Lectura de tabla return para enviar el motivo por el que se da error al tratar de crear el pedido.
              CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
              LOOP AT lt_return INTO ls_return.
                CALL METHOD lo_msg->add_message_from_bapi
                  EXPORTING
                    is_bapi_message           = ls_return
                    iv_add_to_response_header = abap_true
                    iv_message_target         = CONV string( ls_return-field ).
              ENDLOOP.
              RETURN.
            ENDIF.
          ENDIF.
          IF lv_vbeln_ret NE '' AND lv_auart EQ 'ZPOS'. "Si se crea el pedido y es ZPOS (Punto de venta, se creará la SM y  Factura.
            DATA: ls_vbkok    TYPE vbkok,
                  lv_errormsg TYPE xfeld.

            LOOP AT lt_return INTO ls_return WHERE type EQ 'S' AND id EQ 'V1' AND number EQ '260'.
              lv_entrega = |{ ls_return-message_v3 ALPHA = IN }|.
            ENDLOOP.

            IF lv_entrega NE ''.  "Si se creó la entrega, generamos la salida de mercancía.
              CLEAR: ls_return, lt_return.

              ls_vbkok-vbeln_vl = lv_entrega.
              ls_vbkok-wabuc    = 'X'.

              WAIT UP TO 3 SECONDS.

              CALL FUNCTION 'WS_DELIVERY_UPDATE_2'
                EXPORTING
                  vbkok_wa = ls_vbkok
                  delivery = lv_entrega
                  commit   = 'X'.

              IF sy-subrc EQ 0. "Buscamos el documento de material generado con la SM.

                WAIT UP TO 2 SECONDS.

                SELECT SINGLE vbeln INTO @DATA(lv_documat)
                  FROM vbfa
                  WHERE vbelv EQ @lv_entrega
                  AND vbtyp_n EQ 'R'
                  AND vbtyp_v EQ 'J'
                  AND bwart   EQ '601'.

                IF lv_documat NE ''. "Si se creó el documento de material (Salida de mercancía), se creará la factura correspondiente.
                  DATA: lt_billdatain TYPE STANDARD TABLE OF bapivbrk,
                        ls_billdatain TYPE bapivbrk,
                        lt_success    TYPE STANDARD TABLE OF bapivbrksuccess,
                        ls_success    TYPE bapivbrksuccess,
                        lv_factura    TYPE vbrk-vbeln.

                  lv_vbeln_ret = |{ lv_vbeln_ret ALPHA = IN }|.

                  ls_billdatain-doc_number = lv_vbeln_ret.
                  ls_billdatain-ref_doc    = lv_vbeln_ret.
                  ls_billdatain-ref_doc_ca = 'C'.
                  ls_billdatain-bill_date  = sy-datum.

                  APPEND ls_billdatain TO lt_billdatain.

                  CALL FUNCTION 'BAPI_BILLINGDOC_CREATEMULTIPLE'
                    EXPORTING
                      posting       = 'C'
                    TABLES
                      billingdatain = lt_billdatain
                      return        = lt_return
                      success       = lt_success.

                  IF sy-subrc EQ 0.
                    LOOP AT lt_success INTO ls_success.
                      lv_factura = ls_success-bill_doc.
                    ENDLOOP.
                    IF lv_factura NE ''.
                      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.

                      SELECT SINGLE belnr INTO @DATA(lv_belnr)
                        FROM vbrk
                        WHERE vbeln EQ @lv_factura.
                    ENDIF.
                  ENDIF.
                ENDIF.
              ENDIF.
            ENDIF.
*Envío de correo con el número de pedido, entrega, salida de material, factura y documento contable de pedido ZPOS.
            DATA: lo_bcs         TYPE REF TO cl_bcs,
                  lo_doc_bcs     TYPE REF TO cl_document_bcs,
                  lo_recep       TYPE REF TO if_recipient_bcs,
                  lo_sapuser_bcs TYPE REF TO cl_sapuser_bcs,
                  lo_cx_bcx      TYPE REF TO cx_bcs.

            DATA: lv_sent_to_all TYPE os_boolean,
                  lv_string_text TYPE string,
                  lv_subject     TYPE so_obj_des,
                  lv_recipient   TYPE adr6-smtp_addr,
                  lt_textemail   TYPE bcsy_text.

            SELECT SINGLE lgort INTO @DATA(lv_lgort)
              FROM vbap
              WHERE vbeln EQ @lv_vbeln_ret.

            IF lv_lgort NE ''.
              SELECT valor2 FROM zparamglob
                WHERE programa EQ 'ZSD_CARGAPEDIDOS'
                AND parametro EQ '7'
                AND valor1 EQ @lv_lgort
                INTO TABLE @DATA(lt_userssmtp).
            ENDIF.

            LOOP AT lt_userssmtp INTO DATA(ls_userssmtp).

              TRY.

                  lo_bcs = cl_bcs=>create_persistent( ).

                  CONCATENATE 'Buen día,' cl_abap_char_utilities=>newline INTO lv_string_text.
                  APPEND lv_string_text TO lt_textemail.
                  CLEAR lv_string_text.

                  CONCATENATE 'Se han generado los siguientes documentos del pedido de Punto de Venta para el cliente' lv_kunag '.' cl_abap_char_utilities=>newline INTO lv_string_text SEPARATED BY space.
                  APPEND lv_string_text TO lt_textemail.
                  CLEAR lv_string_text.

                  CONCATENATE 'Pedido: ' lv_vbeln_ret cl_abap_char_utilities=>newline INTO lv_string_text SEPARATED BY space.
                  APPEND lv_string_text TO lt_textemail.
                  CLEAR lv_string_text.

                  CONCATENATE 'Entrega: ' lv_entrega cl_abap_char_utilities=>newline INTO lv_string_text SEPARATED BY space.
                  APPEND lv_string_text TO lt_textemail.
                  CLEAR lv_string_text.

                  CONCATENATE 'Documento de Material: ' lv_documat cl_abap_char_utilities=>newline INTO lv_string_text SEPARATED BY space.
                  APPEND lv_string_text TO lt_textemail.
                  CLEAR lv_string_text.

                  CONCATENATE 'Factura: ' lv_factura cl_abap_char_utilities=>newline INTO lv_string_text SEPARATED BY space.
                  APPEND lv_string_text TO lt_textemail.
                  CLEAR lv_string_text.

                  CONCATENATE 'Documento Contable: ' lv_belnr cl_abap_char_utilities=>newline INTO lv_string_text SEPARATED BY space.
                  APPEND lv_string_text TO lt_textemail.
                  CLEAR lv_string_text.

                  CONCATENATE 'Saludos cordiales.' cl_abap_char_utilities=>newline INTO lv_string_text SEPARATED BY space.
                  APPEND lv_string_text TO lt_textemail.
                  CLEAR lv_string_text.

                  CONCATENATE 'Creación de pedido POS del cliente: ' lv_kunag INTO lv_subject SEPARATED BY space.

                  lo_doc_bcs = cl_document_bcs=>create_document(
                    i_type    = 'RAW'
                    i_text    = lt_textemail[]
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

                  lv_recipient = ls_userssmtp-valor2.

                  lo_recep = cl_cam_address_bcs=>create_internet_address( lv_recipient ).

                  CALL METHOD lo_bcs->add_recipient
                    EXPORTING
                      i_recipient = lo_recep
                      i_express   = 'X'.

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
              CLEAR: lv_subject, lv_string_text, lt_textemail, lv_recipient, lv_sent_to_all.
            ENDLOOP.
          ELSEIF lv_vbeln_ret NE '' AND lv_auart EQ 'ZNAC'.  "Envío de correo para pedidos capturados por los agentes desde su tablet.
          ENDIF.
        ENDIF.
      ENDIF.

      me->copy_data_to_ref(
      EXPORTING
        is_data = gs_de_orders
      CHANGING
        cr_data = er_deep_entity
      ).
*------------------------------------------------------------------------
*                        APLICA PAGOS
*-----------------------------------------------------------------------
    ELSEIF lv_expand EQ 'TO_APLICAPAGOPOS'.

      DATA: gs_de_aplicapago TYPE zcl_zsd_salesapp_mpc_ext=>ts_de_aplicapago,
            gs_pagopos_data  TYPE zcl_zsd_salesapp_mpc=>ts_aplicapagopos,
            gt_pagopos_data  TYPE zcl_zsd_salesapp_mpc=>tt_aplicapagopos.

      DATA: ls_header    TYPE bapiache09,
            ls_items_cpd TYPE bapiacpa09,
            lt_items_cpd TYPE STANDARD TABLE OF bapiacpa09,
            ls_items_gl  TYPE bapiacgl09,
            lt_items_gl  TYPE STANDARD TABLE OF bapiacgl09,
            ls_items_re  TYPE bapiacar09,
            lt_items_re  TYPE STANDARD TABLE OF bapiacar09,
            ls_items_am  TYPE bapiaccr09,
            lt_items_am  TYPE STANDARD TABLE OF bapiaccr09,
            lw_bapiacextc TYPE bapiacextc,
            lt_bapiacextc TYPE STANDARD TABLE OF bapiacextc.

      DATA: lv_diferencia      TYPE p DECIMALS 5,
            lv_tot_pago_dif    TYPE p DECIMALS 5,
            lv_tot_pago_fact   TYPE p DECIMALS 5,
            lv_tot_pago_banco  TYPE p DECIMALS 5,
            lv_tot_dif_gral    TYPE p DECIMALS 5,
            lv_tot_gral        TYPE p DECIMALS 5,
            lv_pago_fact       TYPE p DECIMALS 5,
            lv_pago_banco      TYPE p DECIMALS 5,
            lv_suma            TYPE p DECIMALS 5,
            lv_dif_banco_suma  TYPE p DECIMALS 5,
            lv_tcambio_factura TYPE p DECIMALS 5,
            lv_tc_contabili    TYPE p DECIMALS 5,
            lv_cta_dife        TYPE bsid_view-saknr,
            lv_headtxt         TYPE bktxt,
            lv_itemtexto       TYPE sgtxt,
            lv_pagado          TYPE bsid_view-belnr,
            lv_docto_pago      TYPE bsid_view-belnr,
            lv_docto_ncr       TYPE bsid_view-belnr,
            lv_cuantos         TYPE i,
            lv_sin_diferencia  TYPE i,
            lv_cuantos_gl      TYPE i,
            lv_cuantos_am      TYPE i,
            lv_curr_type       TYPE c LENGTH 2,
            lv_paso            TYPE c LENGTH 2,
            lv_paso_saldo      TYPE c LENGTH 2,
            lv_direccion       TYPE vbpa-adrnr,
            lv_nombre          TYPE adrc-name1,
            lv_poblacion       TYPE adrc-city1,
            lv_pago            TYPE wrbtr.

      DATA: lv_gdatu TYPE c LENGTH 8.
      DATA: lt_bdcdata   TYPE bdcdata_tab.

      CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
        RECEIVING
          ro_message_container = lo_msg.

*Lectura del request recibido en el método POST.
      TRY.
          CALL METHOD io_data_provider->read_entry_data
            IMPORTING
              es_data = gs_de_aplicapago.
        CATCH /iwbep/cx_mgw_tech_exception.
      ENDTRY.

      MOVE-CORRESPONDING gs_de_aplicapago TO gs_pagopos_data.

      lv_paso = ''.
      lv_paso_saldo = ''.
      lv_cuantos = 1.
      lv_cuantos_gl = 1.
      lv_cuantos_am = 1.
      lv_tot_pago_dif = 0.
      lv_tot_pago_fact = 0.
      lv_tot_pago_banco = 0.
      lv_tot_dif_gral = 0.
      lv_tot_gral = 0.

      IF NOT gs_pagopos_data IS INITIAL.

        gt_pagopos_data[] = gs_de_aplicapago-to_aplicapagopos[].

*Se llena la estructura para DOCUMENTHEADER en la bapi.
        CONCATENATE 'PAGO CLIENTE ' gs_de_aplicapago-cliente INTO lv_headtxt SEPARATED BY space.
        ls_header-obj_type = 'BKPFF'.
        ls_header-username = sy-uname.
        ls_header-header_txt = lv_headtxt.
        ls_header-comp_code = 'LACN'.
        ls_header-doc_date = gs_de_aplicapago-FechaDocumento.
        ls_header-pstng_date = sy-datum.
        ls_header-fisc_year = sy-datum(4).
        ls_header-fis_period = sy-datum+4(2).
        ls_header-doc_type = 'DZ'.
        ls_header-ref_doc_no = gs_de_aplicapago-Cliente.

*       NT= No timbrar, es un traspaso de factura de saldo a favor de legado afectando una factura SAP
*       ST= SI timbrar, es una Nota de Caja con saldo a favor de legado afectando una factura SAP
        IF gs_de_aplicapago-tipopago EQ 'NT'.
           ls_header-ref_doc_no = 'NOTIMBRARPAGO'.
        ENDIF.

*Se llena la estructura para ACCOUNTGL en la bapi.              ---- BANCO
        CONCATENATE 'ABONO CLIENTE ' gs_de_aplicapago-cliente INTO lv_itemtexto SEPARATED BY space.
        ls_items_gl-itemno_acc = '0000000001'.
        ls_items_gl-gl_account = gs_de_aplicapago-CtaBanco.
        ls_items_gl-item_text = lv_itemtexto.
        ls_items_gl-value_date = gs_de_aplicapago-FechaDocumento.
        APPEND ls_items_gl TO lt_items_gl.

*       Saldo a Favor (legado) Genera estos 2 movimiento banco y cte no asociado
*       //////////   Saldo a Favor (legado)   ///////////////////
        IF gs_de_aplicapago-tipopago EQ 'NT' OR gs_de_aplicapago-tipopago EQ 'ST'.
*           GL  Banco
            CONCATENATE 'SALDO A FAVOR CTE' gs_de_aplicapago-cliente INTO lv_itemtexto SEPARATED BY space.
            ls_items_gl-itemno_acc = '0000000003'.
            ls_items_gl-gl_account = gs_de_aplicapago-CtaBanco.
            ls_items_gl-item_text = lv_itemtexto.
            ls_items_gl-value_date = gs_de_aplicapago-FechaDocumento.
            APPEND ls_items_gl TO lt_items_gl.
            CLEAR ls_items_gl.
*           GL Cte No asociada
            ls_items_gl-itemno_acc = '0000000004'.
            ls_items_gl-gl_account = '0000120000'.
            ls_items_gl-item_text = lv_itemtexto.
            ls_items_gl-value_date = gs_de_aplicapago-FechaDocumento.
            APPEND ls_items_gl TO lt_items_gl.
            CLEAR ls_items_gl.
        ENDIF.
*       //////////////////////////////////////////////////////////////////////////
*       Fin saldo a favor (legado)

*Se llena la estructura para CURRENCYAMOUNT en la bapi.       ------ MONEDA E IMPORTE DE LA POSICION DE BANCO  --> POSICION 1
*Posicion 1 importe total del banco  TOTAL PAGO campo cabecera
        ls_items_am-itemno_acc = lv_cuantos_am.
        ls_items_am-currency = gs_de_aplicapago-Moneda.
        ls_items_am-amt_doccur = gs_de_aplicapago-TotalPago.
        APPEND ls_items_am TO lt_items_am.
        CLEAR ls_items_am.

        LOOP AT gt_pagopos_data INTO gs_pagopos_data.
*Se llena la estructura para CUSTOMERCPD en la bapi.
          SELECT SINGLE adrnr
            INTO @lv_direccion
            FROM vbpa
           WHERE vbeln = @gs_pagopos_data-Factura
             AND parvw = 'AG'.
          SELECT SINGLE name1, city1
            INTO ( @lv_nombre, @lv_poblacion )
            FROM adrc
           WHERE addrnumber = @lv_direccion.

          ls_items_cpd-name = lv_nombre.
          ls_items_cpd-city = lv_poblacion.
          APPEND ls_items_cpd TO lt_items_cpd.

*Se llena la estructura para ACCOUNTRECEIVABLE en la bapi.   ------ CLIENTE
          lv_cuantos = lv_cuantos + 1.
          ls_items_re-itemno_acc = lv_cuantos.
          ls_items_re-customer = gs_de_aplicapago-Cliente.
          ls_items_re-ref_key_1 = gs_pagopos_data-Factura.
          ls_items_re-pymt_meth = gs_de_aplicapago-TipoPago.
          ls_items_re-paymt_ref = gs_pagopos_data-Factura.
          ls_items_re-alloc_nmbr = gs_pagopos_data-Factura.
          ls_items_re-item_text = lv_itemtexto.
          APPEND ls_items_re TO lt_items_re.
          CLEAR ls_items_re.

*Se llena la estructura para --EXTENSION1-- en la bapi.   ------ CLIENTE------FACTURA
*          lw_bapiacextc-field1 = '0000000002'.
*          lw_bapiacextc-field2 = '9400000388'.
*          lw_bapiacextc-field3 = '2025'.
*          lw_bapiacextc-field4 = '001 15 90000402 009000040200000 X'.
*          APPEND lw_bapiacextc TO lt_bapiacextc.
*         CLEAR ls_items_ext.

*Se llena la estructura para CURRENCYAMOUNT en la bapi. ------ MONEDA E IMPORTE DE CADA UNA DE LAS FACTURAS
          lv_pago = gs_pagopos_data-importepago * -1.
          ls_items_am-itemno_acc = lv_cuantos.
          ls_items_am-currency = gs_de_aplicapago-Moneda.
          ls_items_am-amt_doccur = lv_pago.
          APPEND ls_items_am TO lt_items_am.
          CLEAR ls_items_am.
*         Saldo a Favor (legado) Genera estos 2 movimiento cuando es un Saldo a favor
*         /////////////////////////////////////////////////////////////////////////////
          IF gs_de_aplicapago-tipopago EQ 'NT' OR gs_de_aplicapago-tipopago EQ 'ST'.
             IF lv_paso_saldo EQ ''.
*               AM  Banco
                lv_cuantos = lv_cuantos + 1.
                ls_items_am-itemno_acc = lv_cuantos.
                ls_items_am-currency = gs_de_aplicapago-Moneda.
                ls_items_am-amt_doccur = gs_de_aplicapago-TotalPago * -1.
                APPEND ls_items_am TO lt_items_am.
                CLEAR ls_items_am.
*               AM  Cte No Asociado
                lv_cuantos = lv_cuantos + 1.
                ls_items_am-itemno_acc = lv_cuantos.
                ls_items_am-currency = gs_de_aplicapago-Moneda.
                ls_items_am-amt_doccur = gs_de_aplicapago-TotalPago.
                APPEND ls_items_am TO lt_items_am.
                CLEAR ls_items_am.
                lv_paso_saldo = 'YA'.
             ENDIF.
          ENDIF.
*         /////////////////////////////////////////////////////////////////////////////
*         Fin saldo a favor

*         Tipo de cambio, Solo si es en Dolares
          IF gs_de_aplicapago-Moneda EQ 'USD'.
            SELECT SINGLE kurrf
              INTO @lv_tcambio_factura
              FROM vbrk
             WHERE bukrs = 'LACN' AND vkorg = '1000'
               AND vtweg = '02' AND spart = '10'
               AND waerk = @gs_de_aplicapago-Moneda
               AND vbeln = @gs_pagopos_data-Factura.

            lv_gdatu = '99999999' - gs_de_aplicapago-FechaConta.
            SELECT SINGLE ukurs
              INTO @lv_tc_contabili
              FROM tcurr
             WHERE fcurr EQ 'USD'
               AND tcurr EQ 'MXN'
               AND kurst EQ 'M'
               AND gdatu EQ @lv_gdatu.

            lv_sin_diferencia = 1.
            lv_diferencia = 0.
            lv_diferencia = lv_tcambio_factura - lv_tc_contabili.

*           si existe Diferencia en el tipo de cambio factura vs contabilizado
            lv_cuantos = lv_cuantos + 1.
            lv_cta_dife = '0000710002'.
            IF lv_diferencia EQ 0.
                lv_diferencia = 99999999.
                lv_sin_diferencia = 0.
            ELSE.
                lv_diferencia = lv_diferencia * gs_pagopos_data-importepago.
            ENDIF.
            lv_diferencia = round( val = ( lv_diferencia ) dec = 2 ).
            IF lv_diferencia < 0.
                lv_cta_dife = '0000700006'.
            ENDIF.
*           GL
            CONCATENATE 'ABONO CLIENTE ' gs_de_aplicapago-cliente INTO lv_itemtexto SEPARATED BY space.
            ls_items_gl-itemno_acc = lv_cuantos.
            ls_items_gl-gl_account = lv_cta_dife.
            ls_items_gl-item_text = lv_itemtexto.
            ls_items_gl-value_date = gs_de_aplicapago-FechaDocumento.
            APPEND ls_items_gl TO lt_items_gl.
*           AM         Una sola posicion con el total del pago vs banco en moneda nacional
            IF lv_paso EQ ''.
                ls_items_am-itemno_acc = '0000000001'.
                ls_items_am-currency = 'MXN'.
                ls_items_am-curr_type = '10'.
                ls_items_am-amt_doccur = round( val = ( lv_tc_contabili * gs_de_aplicapago-TotalPago ) dec = 2 ).
                lv_tot_pago_banco = ls_items_am-amt_doccur.
                APPEND ls_items_am TO lt_items_am.
                CLEAR ls_items_am.
                lv_paso = 'SI'.
            ENDIF.
*           AM
            ls_items_am-itemno_acc = lv_cuantos - 1.
            ls_items_am-curr_type = '10'.
            ls_items_am-currency = 'MXN'.
*           ls_items_am-amt_doccur = ( lv_tcambio_factura * gs_pagopos_data-importepago ) * -1.
            ls_items_am-amt_doccur = round( val = ( ( lv_tcambio_factura * gs_pagopos_data-importepago ) * -1 ) dec = 2 ).
            lv_pago_fact = ls_items_am-amt_doccur.
            lv_tot_pago_fact = lv_tot_pago_fact + lv_pago_fact.

*           Diferencia pago banco vs (pago factura mas diferencia tipo cambio)
            IF lv_diferencia NE 0.
                  lv_pago_banco = round( val = ( lv_tc_contabili * gs_pagopos_data-importepago ) dec = 2 ).
*                 lv_pago_banco = lv_tc_contabili * gs_pagopos_data-importepago.
                  IF lv_sin_diferencia EQ 0.
                      lv_diferencia = 0.
                      lv_dif_banco_suma = 0.
                  ELSE.
                      lv_suma = ( lv_pago_fact * -1 ) + ( lv_diferencia * -1 ).
                      lv_dif_banco_suma = lv_pago_banco - lv_suma.
                  ENDIF.
                  IF lv_dif_banco_suma > 0.
                      lv_diferencia = lv_diferencia - lv_dif_banco_suma.
                      ls_items_am-amt_doccur = lv_pago_fact.
                  ENDIF.
                  IF lv_dif_banco_suma < 0.
                     IF  lv_diferencia < 0.
                          lv_diferencia = lv_diferencia + lv_dif_banco_suma.
                     ENDIF.
                     IF  lv_diferencia > 0.
                          lv_diferencia = lv_diferencia - lv_dif_banco_suma.
                     ENDIF.
                     ls_items_am-amt_doccur = lv_pago_fact.
                  ENDIF.

            ENDIF.
            lv_tot_pago_dif = lv_tot_pago_dif + lv_diferencia.
            lv_tot_gral = lv_tot_pago_fact + lv_tot_pago_dif.
            lv_tot_dif_gral = lv_tot_pago_banco - ( lv_tot_gral * -1 ).
            IF lv_tot_dif_gral > 0 AND lv_tot_dif_gral < 3.
                lv_diferencia = lv_diferencia - lv_tot_dif_gral.
            ENDIF.
            IF lv_tot_dif_gral < 0 AND lv_tot_dif_gral > -3.
                lv_diferencia = lv_diferencia - lv_tot_dif_gral.
            ENDIF.
            APPEND ls_items_am TO lt_items_am.
            CLEAR ls_items_am.

*           Se llena la posicion de CUENTA DE DIFERENCIA -- CURRENCYAMOUNT
            ls_items_am-itemno_acc = lv_cuantos.
            ls_items_am-curr_type = '10'.
            ls_items_am-currency = 'MXN'.
            ls_items_am-amt_doccur = lv_diferencia.
            APPEND ls_items_am TO lt_items_am.
            CLEAR ls_items_am.
            ls_items_am-itemno_acc = lv_cuantos.
            ls_items_am-curr_type = '00'.
            ls_items_am-currency = 'USD'.
            ls_items_am-amt_doccur = 0.
            APPEND ls_items_am TO lt_items_am.
            CLEAR ls_items_am.

          ENDIF.
*         Fin de dolares
        ENDLOOP.
      ENDIF.
      lv_paso = ''.
      lv_cuantos = 0.
      lv_cuantos_gl = 0.

*Se llama a la BAPI para la creación del pago de ventas.
      TRY.
          CALL FUNCTION 'BAPI_ACC_DOCUMENT_POST'
            EXPORTING
              documentheader    = ls_header
              customercpd       = ls_items_cpd
            TABLES
              accountgl         = lt_items_gl
              accountreceivable = lt_items_re
              extension1        = lt_bapiacextc
              currencyamount    = lt_items_am
              return            = lt_return.
        CATCH /iwbep/cx_mgw_tech_exception.
      ENDTRY.

*Regresa de la BAPI sin errores y toma el numero de Documneto que genero
      LOOP AT lt_return INTO ls_return WHERE type EQ 'S' AND id EQ 'RW' AND number EQ '605'.
        lv_pagado = |{ ls_return-message ALPHA = IN }|.
        lv_docto_pago = |{ ls_return-message_v2(10) ALPHA = IN }|.
      ENDLOOP.

      IF lv_pagado EQ ''.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        lv_error_msg = 'No se creó el pago, favor de validar'.
        CALL METHOD lo_msg->add_message
          EXPORTING
            iv_msg_type   = /iwbep/cl_cos_logger=>error
            iv_msg_id     = 'ZSD_MSG'
            iv_msg_number = '006'
            iv_msg_text   = lv_error_msg.
        RETURN.
      ELSE.
        IF NOT line_exists( lt_return[ type = 'E' ] ).
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
          gs_de_aplicapago-nodocupago = lv_docto_pago.
        ELSE.
*Lectura de tabla return para enviar el motivo por el que se da error al tratar de crear el pago.
          CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
          LOOP AT lt_return INTO ls_return.
            CALL METHOD lo_msg->add_message_from_bapi
              EXPORTING
                is_bapi_message           = ls_return
                iv_add_to_response_header = abap_true
                iv_message_target         = CONV string( ls_return-field ).
          ENDLOOP.
          RETURN.
        ENDIF.
      ENDIF.

      me->copy_data_to_ref(
      EXPORTING
         is_data = gs_de_aplicapago
      CHANGING
         cr_data = er_deep_entity
      ).

    ENDIF.
  ENDMETHOD.


  METHOD /iwbep/if_mgw_appl_srv_runtime~get_expanded_entity.

*Validamos desde que servicio se detona el método get expanded entity
    IF iv_entity_name EQ 'Cartera' OR iv_entity_name EQ 'Pagadas'.
*Declaración de tablas y estructuras internas para los entity SET
      DATA: it_de_cartera           TYPE TABLE OF zcl_zsd_salesapp_mpc=>ts_de_cartera,
            it_de_pagadas           TYPE TABLE OF zcl_zsd_salesapp_mpc=>ts_de_pagadas,
            wa_de_cartera           TYPE zcl_zsd_salesapp_mpc=>ts_de_cartera,
            wa_de_pagadas           TYPE zcl_zsd_salesapp_mpc=>ts_de_pagadas,
            wa_de_carteraclientes   TYPE zcl_zsd_salesapp_mpc=>ts_de_carteraclientes,
            wa_de_carteraclientesp  TYPE zcl_zsd_salesapp_mpc=>ts_de_carteraclientesp,
            wa_de_carterapendientes TYPE zcl_zsd_salesapp_mpc=>ts_de_carterapendientes,
            wa_de_carterapagadas    TYPE zcl_zsd_salesapp_mpc=>ts_de_carterapagadas,
            wa_carterapagospen      TYPE zcl_zsd_salesapp_mpc=>ts_carterapagos,
            wa_carterapagospag      TYPE zcl_zsd_salesapp_mpc=>ts_carterapagos,
            wa_carterancr           TYPE zcl_zsd_salesapp_mpc=>ts_carterancr.

*Declaración de tablas y estructuras internas para vaciar info de tablas estándar
      DATA: lt_bsad    TYPE STANDARD TABLE OF bsad_view,
            ls_bsad    TYPE bsad_view,
            lt_bsad_rv TYPE STANDARD TABLE OF bsad_view,
            ls_bsad_rv TYPE bsad_view,
            lt_bsid    TYPE STANDARD TABLE OF bsid_view,
            ls_bsid    TYPE bsid_view,
            lt_vbrk    TYPE STANDARD TABLE OF vbrk,
            ls_vbrk    TYPE vbrk,
            "lt_vbrk2   TYPE STANDARD TABLE OF vbrk,
            "ls_vbrk2   TYPE vbrk,
            lt_vbrp    TYPE STANDARD TABLE OF vbrp,
            ls_vbrp    TYPE vbrp,
            lt_kna1    TYPE STANDARD TABLE OF kna1,
            ls_kna1    TYPE kna1,
            lt_timbre  TYPE STANDARD TABLE OF zsd_cfdi_return,
            ls_timbre  TYPE zsd_cfdi_return,
*            lt_agente  TYPE STANDARD TABLE OF tvgrt,
*            ls_agente  TYPE tvgrt,
            lt_knvv    TYPE STANDARD TABLE OF knvv,
            ls_knvv    TYPE knvv,
            lt_tpago   TYPE STANDARD TABLE OF zfi_pagos_return,
            ls_tpago   TYPE zfi_pagos_return,
            lt_pparc   TYPE STANDARD TABLE OF zfi_pago_parcial,
            ls_pparc   TYPE zfi_pago_parcial.

*Declaración de variables
      DATA: lv_agente    TYPE vkgrp,
            lv_pagos     TYPE wrbtr,
            lv_lines     TYPE i,
            lv_error_msg TYPE bapi_msg,
            lo_msg       TYPE REF TO /iwbep/if_message_container.

*Declaración de constantes

      DATA: lo_tech_request TYPE REF TO /iwbep/cl_mgw_request.

*Instancia a objeto para contenedor de mensajes de error.
      CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
        RECEIVING
          ro_message_container = lo_msg.

*Asignación de propiedades de navegación
      lo_tech_request ?= io_tech_request_context.
      DATA(lv_expand) = lo_tech_request->/iwbep/if_mgw_req_entityset~get_expand( ).
      TRANSLATE lv_expand TO UPPER CASE.
      SPLIT lv_expand AT ',' INTO TABLE et_expanded_tech_clauses.

*Lectura de tabla de valores procedentes de la ejecución de la API. Aquí se recibe el valor desde la URL.
      READ TABLE it_key_tab INTO DATA(wa_keytab) INDEX 1.

      IF sy-subrc EQ 0.
        lv_agente = |{ wa_keytab-value ALPHA = IN }|.

*Llenado de tablas internas
        "Llenado de tabla de agentes y nombre de agente (grupos de vendedores)
        SELECT tt~spras, tt~vkgrp, tt~bezei FROM tvgrt AS tt
          INNER JOIN tvkgr AS tk ON tk~vkgrp EQ tt~vkgrp
          WHERE tt~spras EQ 'S'
          AND tk~hide EQ ''
          AND tt~vkgrp EQ @lv_agente
          INTO TABLE @DATA(lt_agente).

        IF sy-subrc NE 0.
          CONCATENATE 'El agente' lv_agente 'no existe, favor de validar.' INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZSD_MSG'
              iv_msg_number = '001'
              iv_msg_text   = lv_error_msg.
          RETURN.
        ENDIF.

        "Llenado de tabla de posiciones de factura filtrada por agente.
        SELECT * FROM vbrp
          WHERE vkgrp EQ @lv_agente
          INTO TABLE @lt_vbrp.

        SELECT vb~vbeln FROM knvv AS kn
          INNER JOIN vbrk AS vb ON vb~kunag EQ kn~kunnr
          WHERE kn~vkgrp EQ @lv_agente
          AND vb~fksto EQ ''
          INTO TABLE @DATA(lt_paso).

        IF lt_paso[] IS NOT INITIAL.
          SELECT * FROM vbrp
            FOR ALL ENTRIES IN @lt_paso
            WHERE vbeln EQ @lt_paso-vbeln
            INTO TABLE @DATA(lt_vbrpaux).

          IF lt_vbrpaux[] IS NOT INITIAL.
            INSERT LINES OF lt_vbrpaux INTO TABLE lt_vbrp.
          ENDIF.
        ENDIF.

        IF lt_vbrp[] IS INITIAL.
          CONCATENATE 'El agente' lv_agente 'no tiene facturas creadas.' INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZSD_MSG'
              iv_msg_number = '002'
              iv_msg_text   = lv_error_msg.
          RETURN.
        ELSE.
          SORT lt_vbrp ASCENDING BY vbeln.
          DELETE ADJACENT DUPLICATES FROM lt_vbrp COMPARING vbeln.
        ENDIF.

        "Llenado de tabla de facturas (cabecera).
*        SELECT * FROM vbrk
*          FOR ALL ENTRIES IN @lt_vbrp
*          WHERE vbeln EQ @lt_vbrp-vbeln
*          AND vbtyp EQ 'M'
*          AND fksto EQ ''
*          INTO TABLE @lt_vbrk.
        IF lv_expand EQ 'TO_CARTERACLIENTES/TO_CARTERAPENDIENTES/TO_CARTERAPAGOSPEN,TO_CARTERACLIENTES/TO_CARTERAPENDIENTES/TO_CARTERANCR'.
          SELECT a~vbeln, a~kunrg, a~bukrs, a~gjahr, a~belnr, a~fkdat, a~netwr, a~mwsbk, b~uuid, c~zuonr FROM vbrk AS a
            INNER JOIN zsd_cfdi_return AS b ON b~nodocu EQ a~vbeln
            INNER JOIN bsid_view AS c ON c~vbeln EQ a~vbeln
            FOR ALL ENTRIES IN @lt_vbrp
            WHERE a~vbeln EQ @lt_vbrp-vbeln
            AND a~vbtyp EQ 'M'
            AND a~fksto EQ ''
            AND ( c~blart EQ 'DZ' OR c~blart EQ 'RV' )
            AND c~bukrs EQ a~bukrs
            "AND c~gjahr EQ a~gjahr
            AND b~uuid NE ''
            INTO TABLE @DATA(lt_vbrk2).
        ELSEIF lv_expand EQ 'TO_CARTERACLIENTESP/TO_CARTERAPAGADAS/TO_CARTERAPAGOSPAG'.
          SELECT a~vbeln, a~kunrg, a~bukrs, a~gjahr, a~belnr, a~fkdat, a~netwr, a~mwsbk, b~uuid, c~zuonr FROM vbrk AS a
            INNER JOIN zsd_cfdi_return AS b ON b~nodocu EQ a~vbeln
            INNER JOIN bsad_view AS c ON c~vbeln EQ a~vbeln
            FOR ALL ENTRIES IN @lt_vbrp
            WHERE a~vbeln EQ @lt_vbrp-vbeln
            AND a~vbtyp EQ 'M'
            AND a~fksto EQ ''
            AND c~blart EQ 'RV'
            AND c~bukrs EQ a~bukrs
            "AND c~gjahr EQ a~gjahr
            AND b~uuid NE ''
            INTO TABLE @lt_vbrk2.
        ENDIF.

        SORT lt_vbrk2 ASCENDING BY vbeln.
        DELETE ADJACENT DUPLICATES FROM lt_vbrk2 COMPARING vbeln.

        "Llenado de tabla de timbrado de CFDI.
        SELECT * FROM zsd_cfdi_return
          FOR ALL ENTRIES IN @lt_vbrk2
          WHERE nodocu EQ @lt_vbrk2-vbeln
          AND uuid NE ''
          INTO TABLE @lt_timbre.

        "Llenado de tabla de facturas incluyendo solo aquellas que estén timbradas
*        SELECT * FROM vbrk
*          FOR ALL ENTRIES IN @lt_timbre
*          WHERE vbeln EQ @lt_timbre-nodocu
*          INTO TABLE @lt_vbrk2.

        "Llenado de tabla de clientes.
        SELECT * FROM kna1
          FOR ALL ENTRIES IN @lt_vbrk2
          WHERE kunnr EQ @lt_vbrk2-kunrg
          INTO TABLE @lt_kna1.

        "Llenado de tabla de clientes por área de ventas
        SELECT * FROM knvv
          FOR ALL ENTRIES IN @lt_kna1
          WHERE kunnr EQ @lt_kna1-kunnr
          INTO TABLE @lt_knvv.

        SORT lt_knvv ASCENDING BY kunnr vkorg vtweg spart.

        "Llenado de tabla de documentos pendientes de pago
        IF lv_expand EQ 'TO_CARTERACLIENTES/TO_CARTERAPENDIENTES/TO_CARTERAPAGOSPEN,TO_CARTERACLIENTES/TO_CARTERAPENDIENTES/TO_CARTERANCR'.
          SELECT * FROM bsid_view
            FOR ALL ENTRIES IN @lt_vbrk2
            WHERE vbeln EQ @lt_vbrk2-vbeln(10)
            AND bukrs EQ @lt_vbrk2-bukrs
            AND gjahr EQ @lt_vbrk2-gjahr
            AND blart EQ 'DZ'
            INTO TABLE @lt_bsid.

          SELECT * FROM bsid_view
            FOR ALL ENTRIES IN @lt_vbrk2
            WHERE zuonr EQ @lt_vbrk2-zuonr
            AND bukrs EQ @lt_vbrk2-bukrs
            AND gjahr EQ @lt_vbrk2-gjahr
            AND blart EQ 'DZ'
            INTO TABLE @DATA(lt_bsid2).

          DELETE lt_bsid2 WHERE zuonr EQ ''.

          IF lt_bsid2[] IS NOT INITIAL.

            LOOP AT lt_bsid2 ASSIGNING FIELD-SYMBOL(<fs_bsid2>).
              <fs_bsid2>-vbeln = <fs_bsid2>-zuonr.
              MODIFY lt_bsid2 FROM <fs_bsid2>.
            ENDLOOP.
            UNASSIGN <fs_bsid2>.

            APPEND LINES OF lt_bsid2[] TO lt_bsid[].
            SORT lt_bsid ASCENDING BY belnr.
            DELETE ADJACENT DUPLICATES FROM lt_bsid.

          ENDIF.

          LOOP AT lt_vbrk2 INTO DATA(ls_vbrk2).
            SELECT * FROM bsid_view
              WHERE xblnr EQ @ls_vbrk2-vbeln
              AND bukrs EQ @ls_vbrk2-bukrs
              AND gjahr EQ @ls_vbrk2-gjahr
              AND blart EQ 'DZ'
              INTO @ls_bsid.
              IF sy-subrc EQ 0.
                MOVE ls_bsid-xblnr TO ls_bsid-vbeln.
                APPEND ls_bsid TO lt_bsid.
              ENDIF.
            ENDSELECT.
            CLEAR: ls_vbrk2, ls_bsid.
          ENDLOOP.

          IF lt_bsid[] IS NOT INITIAL.
            SORT lt_bsid ASCENDING BY vbeln.

            SELECT * FROM zfi_pagos_return
              FOR ALL ENTRIES IN @lt_bsid
              WHERE nodocu EQ @lt_bsid-belnr
              INTO TABLE @lt_tpago.
          ENDIF.
        ENDIF.

        "Búsqueda de notas de crédito relacionadas a facturas
        SELECT * FROM vbfa
          FOR ALL ENTRIES IN @lt_vbrk2
          WHERE vbelv EQ @lt_vbrk2-vbeln
          AND vbtyp_n EQ 'K'
*          AND meins NE ''                        "MODIF. - CAOG - Se comenta por que no se encuentran NCR relacionadas de facturas de canal tradicional.
          INTO TABLE @DATA(lt_solncr).

        "Búsqueda de notas de crédito por devolución (la NCR por devol se crea a partir de la solicitud de devolución).
        SELECT * FROM vbfa
         FOR ALL ENTRIES IN @lt_vbrk2
         WHERE vbelv EQ @lt_vbrk2-vbeln
         AND vbtyp_n EQ 'H'
         INTO TABLE @DATA(lt_solncrdev).

        IF lt_solncrdev[] IS NOT INITIAL.
          APPEND LINES OF lt_solncrdev TO lt_solncr.
        ENDIF.

        SORT: lt_solncr ASCENDING BY vbeln posnn.
        DELETE ADJACENT DUPLICATES FROM: lt_solncr COMPARING vbeln.

        IF NOT lt_solncr[] IS INITIAL.
          SELECT * FROM vbfa
            FOR ALL ENTRIES IN @lt_solncr
            WHERE vbelv EQ @lt_solncr-vbeln
            AND vbtyp_n EQ 'O'
            INTO TABLE @DATA(lt_ncr).

          IF NOT lt_ncr[] IS INITIAL.

            SORT lt_ncr ASCENDING BY vbelv vbeln.
            DELETE ADJACENT DUPLICATES FROM lt_ncr COMPARING vbeln.

            SELECT * FROM vbrk
              FOR ALL ENTRIES IN @lt_ncr
              WHERE vbeln EQ @lt_ncr-vbeln
              AND fksto EQ ''
              INTO TABLE @DATA(lt_vbncr).

            IF NOT lt_vbncr[] IS INITIAL.
              SELECT * FROM zsd_cfdi_return
                FOR ALL ENTRIES IN @lt_vbncr
                WHERE nodocu EQ @lt_vbncr-vbeln
                INTO TABLE @DATA(lt_ncrreturn).

              SELECT * FROM prcd_elements
                FOR ALL ENTRIES IN @lt_vbncr
                WHERE knumv EQ @lt_vbncr-knumv
                INTO TABLE @DATA(lt_prcd).
            ENDIF.
          ENDIF.
        ENDIF.

        "Llenado de tabla de documentos pagados
        IF lv_expand EQ 'TO_CARTERACLIENTESP/TO_CARTERAPAGADAS/TO_CARTERAPAGOSPAG'.
          SELECT * FROM bsad_view
            FOR ALL ENTRIES IN @lt_vbrk2
            WHERE belnr EQ @lt_vbrk2-belnr
            AND bukrs EQ @lt_vbrk2-bukrs
            AND gjahr EQ @lt_vbrk2-gjahr
            AND blart EQ 'RV'
            INTO TABLE @lt_bsad_rv.

          IF sy-subrc EQ 0.
            SORT lt_bsad_rv ASCENDING BY  augbl vbeln.
            DELETE ADJACENT DUPLICATES FROM lt_bsad_rv COMPARING augbl vbeln.

            SELECT * FROM bsad_view
              FOR ALL ENTRIES IN @lt_bsad_rv
              WHERE augbl EQ @lt_bsad_rv-augbl
              AND bukrs EQ @lt_bsad_rv-bukrs
              AND gjahr EQ @lt_bsad_rv-gjahr
              AND blart EQ 'DZ'
              INTO TABLE @lt_bsad.

            IF sy-subrc EQ 0.
              SELECT * FROM zfi_pagos_return
                FOR ALL ENTRIES IN @lt_bsad
                WHERE nodocu EQ @lt_bsad-belnr
                INTO TABLE @lt_tpago.
            ENDIF.

            LOOP AT lt_bsad INTO ls_bsad.
              LOOP AT lt_bsad_rv INTO ls_bsad_rv WHERE augbl EQ ls_bsad-augbl AND vbeln EQ ls_bsad-xblnr.
                ls_bsad-vbeln = ls_bsad-xblnr.
                MODIFY lt_bsad FROM ls_bsad.
              ENDLOOP.

              IF sy-subrc NE 0.
                READ TABLE lt_bsad_rv INTO ls_bsad_rv WITH KEY  augbl = ls_bsad-augbl.
                IF sy-subrc EQ 0.
                  IF ls_bsad-vbeln EQ '' AND ls_bsad_rv-vbeln NE ''.
                    ls_bsad-vbeln = ls_bsad_rv-vbeln.
                    MODIFY lt_bsad FROM ls_bsad.
                  ENDIF.
                ENDIF.
              ENDIF.
            ENDLOOP.
          ENDIF.
        ENDIF.

        "Llenado de tabla de pagos parciales.
        SELECT * FROM zfi_pago_parcial
          FOR ALL ENTRIES IN @lt_tpago
          WHERE doccompensadz EQ @lt_tpago-nodocu
          AND ejercicio EQ @lt_tpago-ejercicio
          AND sociedad EQ @lt_tpago-sociedad
          INTO TABLE @lt_pparc.

*Se comienza con el llenado del response.
        "Se llena el response para Facturas Pendientes de Pago
        DESCRIBE TABLE lt_vbrk2 LINES lv_lines.
        IF lv_lines GT 0 AND lv_expand EQ 'TO_CARTERACLIENTES/TO_CARTERAPENDIENTES/TO_CARTERAPAGOSPEN,TO_CARTERACLIENTES/TO_CARTERAPENDIENTES/TO_CARTERANCR'.
          "***DATOS CARTERA***
          "Agente
          wa_de_cartera-agente = lv_agente.

          READ TABLE lt_agente INTO DATA(ls_agente) WITH KEY spras = 'S' vkgrp = lv_agente.
          "Nombre de agente
          IF sy-subrc EQ 0.
            wa_de_cartera-nombreagente = ls_agente-bezei.
            CLEAR ls_agente.
          ENDIF.

          "***DATOS CARTERA CLIENTES***
          LOOP AT lt_kna1 INTO ls_kna1.
            "Agente
            wa_de_carteraclientes-agente = lv_agente.

            "Cliente
            wa_de_carteraclientes-cliente = ls_kna1-kunnr.

            "Nombre de cliente
            CONCATENATE ls_kna1-name1 ls_kna1-name2 ls_kna1-name3 ls_kna1-name4 INTO wa_de_carteraclientes-nombrecliente.
            CONDENSE wa_de_carteraclientes-nombrecliente.

            READ TABLE lt_knvv INTO ls_knvv WITH KEY kunnr = ls_kna1-kunnr.

            IF sy-subrc EQ 0.
              "Zona de ventas
              wa_de_carteraclientes-zona = ls_knvv-bzirk.

              "Cadena
              wa_de_carteraclientes-cadena = ls_knvv-kvgr1.
            ENDIF.

            "***DATOS DE FACTURAS PENDIENTES***
            LOOP AT lt_vbrk2 INTO ls_vbrk2 WHERE kunrg EQ ls_kna1-kunnr.
              "Agente
              wa_de_carterapendientes-agente = lv_agente.

              "Cliente
              wa_de_carterapendientes-cliente = ls_kna1-kunnr.

              "Serie
              READ TABLE lt_timbre INTO ls_timbre WITH KEY nodocu = ls_vbrk2-vbeln.

              IF sy-subrc EQ 0.
                wa_de_carterapendientes-serie = ls_timbre-serie.
                CLEAR ls_timbre.
              ENDIF.

              "Folio
              wa_de_carterapendientes-folio = ls_vbrk2-vbeln.

              "Fecha Factura
              CONCATENATE ls_vbrk2-fkdat+6(2) '/' ls_vbrk2-fkdat+4(2) '/' ls_vbrk2-fkdat(4) INTO wa_de_carterapendientes-fechafactura.

              "Total Factura
              wa_de_carterapendientes-totalfactura = ls_vbrk2-netwr + ls_vbrk2-mwsbk.

              "Saldo Pendiente
              LOOP AT lt_bsid INTO ls_bsid WHERE vbeln EQ ls_vbrk2-vbeln AND gjahr EQ ls_vbrk2-gjahr AND bukrs EQ ls_vbrk2-bukrs AND blart EQ 'DZ'.
                READ TABLE lt_tpago INTO ls_tpago WITH KEY nodocu = ls_bsid-belnr ejercicio = ls_bsid-gjahr sociedad = ls_bsid-bukrs.

                IF sy-subrc EQ 0 AND ls_tpago-uuid NE ''.
                  lv_pagos = lv_pagos + ls_bsid-wrbtr.
                ENDIF.
                CLEAR: ls_bsid, ls_tpago.
              ENDLOOP.
              "Si no encuentra nada en la tabla BSID, puede ser por que no hay pagos, o por que la factura está totalmente pagada. Se busca en la BSAD para ver si
              "está pagada por completo y calcular el saldo pendiente, o si por el contrario no se ha pagado nada y debemos seguir mostrándola.
              IF sy-subrc NE 0.
                SELECT * FROM bsad_view
                  WHERE belnr EQ @ls_vbrk2-belnr
                  AND bukrs EQ @ls_vbrk2-bukrs
                  AND gjahr EQ @ls_vbrk2-gjahr
                  AND blart EQ 'RV'
                  INTO TABLE @lt_bsad_rv.

                IF sy-subrc EQ 0.
                  LOOP AT lt_bsad_rv INTO ls_bsad_rv.
                    SELECT * FROM bsad_view
                      WHERE augbl EQ @ls_bsad_rv-augbl
                      AND bukrs EQ @ls_bsad_rv-bukrs
                      AND gjahr EQ @ls_bsad_rv-gjahr
                      AND xblnr EQ @ls_vbrk2-vbeln
                      AND blart EQ 'DZ'
                      INTO @ls_bsad.
                      IF sy-subrc EQ 0.
                        IF ls_bsad-vbeln EQ ''.
                          MOVE ls_bsad_rv-vbeln TO ls_bsad-vbeln.
                        ENDIF.
                        APPEND ls_bsad TO lt_bsad.
                      ENDIF.
                    ENDSELECT.
                    SELECT * FROM bsad_view
                      WHERE augbl EQ @ls_bsad_rv-augbl
                      AND bukrs EQ @ls_bsad_rv-bukrs
                      AND gjahr EQ @ls_bsad_rv-gjahr
                      AND blart EQ 'DZ'
                      INTO @ls_bsad.
                      IF sy-subrc EQ 0.
                        IF ls_bsad-vbeln EQ ''.
                          MOVE ls_bsad_rv-vbeln TO ls_bsad-vbeln.
                        ENDIF.
                        APPEND ls_bsad TO lt_bsad.
                      ENDIF.
                    ENDSELECT.
                    CLEAR: ls_bsad_rv.
                  ENDLOOP.

                  IF sy-subrc EQ 0.
                    LOOP AT lt_bsad INTO ls_bsad  WHERE vbeln EQ ls_vbrk2-vbeln AND gjahr EQ ls_vbrk2-gjahr AND bukrs EQ ls_vbrk2-bukrs AND blart EQ 'DZ'.
                      lv_pagos = lv_pagos + ls_bsad-wrbtr.
                      CLEAR ls_bsad.
                    ENDLOOP.
                  ENDIF.
                ENDIF.
              ENDIF.

              wa_de_carterapendientes-saldopendiente = wa_de_carterapendientes-totalfactura - lv_pagos.
              CLEAR lv_pagos.

              "UUID Factura
              READ TABLE lt_timbre INTO ls_timbre WITH KEY nodocu = ls_vbrk2-vbeln.

              IF sy-subrc EQ 0.
                wa_de_carterapendientes-uuid = ls_timbre-uuid.
                CLEAR ls_timbre.
              ENDIF.

              "***DATOS DE DOCUMENTOS DE PAGO***
              DESCRIBE TABLE lt_bsid LINES DATA(lv_lines2).
              LOOP AT lt_bsid INTO ls_bsid WHERE vbeln EQ ls_vbrk2-vbeln AND gjahr EQ ls_vbrk2-gjahr AND bukrs EQ ls_vbrk2-bukrs AND blart EQ 'DZ'.
                "Agenete
                wa_carterapagospen-agente = lv_agente.

                "Cliente
                wa_carterapagospen-cliente = ls_kna1-kunnr.

                READ TABLE lt_tpago INTO ls_tpago WITH KEY sociedad = ls_bsid-bukrs nodocu = ls_bsid-belnr ejercicio = ls_bsid-gjahr.

                IF sy-subrc EQ 0.
                  "Serie
                  wa_carterapagospen-serie = ls_tpago-serie.

                  "UUID
                  wa_carterapagospen-uuid = ls_tpago-uuid.
                ENDIF.
                CLEAR: ls_tpago.

                "Folio
                wa_carterapagospen-folio = ls_vbrk2-vbeln.

                "DocumentoPago
                wa_carterapagospen-documentopago = ls_bsid-belnr.

                "FechaPago
                CONCATENATE ls_bsid-cpudt+6(2) '/' ls_bsid-cpudt+4(2) '/' ls_bsid-cpudt(4) INTO wa_carterapagospen-fechapago.

                "MontoPago
                wa_carterapagospen-montopago = ls_bsid-wrbtr.

                "Parcialidad
                READ TABLE lt_pparc INTO ls_pparc WITH KEY doccompensadz = ls_bsid-belnr sociedad = ls_bsid-bukrs ejercicio = ls_bsid-gjahr.

                IF sy-subrc EQ 0.
                  wa_carterapagospen-parcialidad = ls_pparc-parcialidad.
                ELSEIF wa_carterapagospen-uuid NE '' AND sy-subrc NE 0.
                  wa_carterapagospen-parcialidad = '1'.
                ENDIF.
                CLEAR: ls_pparc.

                IF wa_carterapagospen-uuid NE ''.
                  APPEND wa_carterapagospen TO wa_de_carterapendientes-to_carterapagospen.
                  DELETE ADJACENT DUPLICATES FROM wa_de_carterapendientes-to_carterapagospen.
                ENDIF.
                CLEAR wa_carterapagospen.
              ENDLOOP.

              "DATOS DE NCR RELACIONADAS
              LOOP AT lt_solncr ASSIGNING FIELD-SYMBOL(<fs_solncr>) WHERE vbelv EQ ls_vbrk2-vbeln.
                LOOP AT lt_ncr ASSIGNING FIELD-SYMBOL(<fs_ncr>) WHERE vbelv = <fs_solncr>-vbeln.

                  IF <fs_ncr> IS ASSIGNED.
                    READ TABLE lt_vbncr ASSIGNING FIELD-SYMBOL(<fs_vbncr>) WITH KEY vbeln = <fs_ncr>-vbeln.
                    READ TABLE lt_ncrreturn ASSIGNING FIELD-SYMBOL(<fs_ncrreturn>) WITH KEY nodocu = <fs_ncr>-vbeln.

                    wa_carterancr-agente   = lv_agente.

                    IF <fs_vbncr> IS ASSIGNED.
                      wa_carterancr-cliente  = <fs_vbncr>-kunrg.
                      wa_carterancr-folio    = <fs_vbncr>-vbeln.
                      wa_carterancr-fechancr = <fs_vbncr>-fkdat.
                    ENDIF.

                    IF <fs_ncrreturn> IS ASSIGNED.
                      wa_carterancr-serie    = <fs_ncrreturn>-serie.
                      wa_carterancr-uuid     = <fs_ncrreturn>-uuid.
                    ENDIF.

                    IF <fs_solncr>-vbelv EQ ls_vbrk2-vbeln.
                      IF <fs_vbncr> IS ASSIGNED.
                        LOOP AT lt_prcd ASSIGNING FIELD-SYMBOL(<fs_prcd>) WHERE knumv EQ <fs_vbncr>-knumv AND ( koaid EQ 'B' OR koaid EQ 'D' OR koaid EQ 'A' ) AND kstat EQ '' AND kinak EQ ''.
                          wa_carterancr-totalncr = wa_carterancr-totalncr + <fs_prcd>-kwert.
                        ENDLOOP.
                        UNASSIGN <fs_prcd>.
                      ENDIF.
                    ENDIF.

                    IF ( wa_carterancr-uuid NE '' AND <fs_solncr>-vbelv EQ ls_vbrk2-vbeln ).
                      "IF <fs_solncr>-vbelv EQ ls_vbrk2-vbeln.
                      APPEND wa_carterancr TO wa_de_carterapendientes-to_carterancr.
                    ENDIF.
                    UNASSIGN: <fs_vbncr>, <fs_ncrreturn>.
                  ENDIF.
                  CLEAR wa_carterancr.
                ENDLOOP.
                UNASSIGN <fs_ncr>.
              ENDLOOP.
              UNASSIGN: <fs_solncr>, <fs_ncr>, <fs_vbncr>, <fs_ncrreturn>.

              IF ( wa_de_carterapendientes-uuid NE '' AND ls_bsid-vbeln EQ ls_vbrk2-vbeln ) OR ( wa_de_carterapendientes-uuid NE '' AND wa_de_carterapendientes-saldopendiente GT 0 ).
                APPEND wa_de_carterapendientes TO wa_de_carteraclientes-to_carterapendientes.
              ENDIF.
              CLEAR: wa_de_carterapendientes.
              CLEAR: ls_vbrk2.
            ENDLOOP.

            APPEND wa_de_carteraclientes TO wa_de_cartera-to_carteraclientes.
            CLEAR: wa_de_carteraclientes.


            CLEAR: lv_lines.
          ENDLOOP.
        ENDIF.

        "Se llena el response para Facturas Pagadas
        DESCRIBE TABLE lt_vbrk2 LINES lv_lines.
        IF lv_lines GT 0 AND lv_expand EQ 'TO_CARTERACLIENTESP/TO_CARTERAPAGADAS/TO_CARTERAPAGOSPAG'.
          "***DATOS PAGADAS***
          "Agente
          wa_de_pagadas-agente = lv_agente.

          READ TABLE lt_agente INTO ls_agente WITH KEY spras = 'S' vkgrp = lv_agente.
          "Nombre de agente
          IF sy-subrc EQ 0.
            wa_de_pagadas-nombreagente = ls_agente-bezei.
            CLEAR ls_agente.
          ENDIF.

          "***DATOS CARTERA CLIENTES***
          LOOP AT lt_kna1 INTO ls_kna1.
            "Agente
            wa_de_carteraclientesp-agente = lv_agente.

            "Cliente
            wa_de_carteraclientesp-cliente = ls_kna1-kunnr.

            "Nombre de cliente
            CONCATENATE ls_kna1-name1 ls_kna1-name2 ls_kna1-name3 ls_kna1-name4 INTO wa_de_carteraclientesp-nombrecliente.
            CONDENSE wa_de_carteraclientesp-nombrecliente.

            READ TABLE lt_knvv INTO ls_knvv WITH KEY kunnr = ls_kna1-kunnr.

            IF sy-subrc EQ 0.
              "Zona de ventas
              wa_de_carteraclientesp-zona = ls_knvv-bzirk.

              "Cadena
              wa_de_carteraclientesp-cadena = ls_knvv-kvgr1.
            ENDIF.
            "***DATOS DE FACTURAS PAGADAS***
            LOOP AT lt_vbrk2 INTO ls_vbrk2 WHERE kunrg EQ ls_kna1-kunnr.
              "Agente
              wa_de_carterapagadas-agente = lv_agente.

              "Cliente
              wa_de_carterapagadas-cliente = ls_kna1-kunnr.

              "Serie
              READ TABLE lt_timbre INTO ls_timbre WITH KEY nodocu = ls_vbrk2-vbeln.

              IF sy-subrc EQ 0.
                wa_de_carterapagadas-serie = ls_timbre-serie.
                CLEAR ls_timbre.
              ENDIF.

              "Folio
              wa_de_carterapagadas-folio = ls_vbrk2-vbeln.

              "Fecha Factura
              CONCATENATE ls_vbrk2-fkdat+6(2) '/' ls_vbrk2-fkdat+4(2) '/' ls_vbrk2-fkdat(4) INTO wa_de_carterapagadas-fechafactura.

              "Total Factura
              wa_de_carterapagadas-totalfactura = ls_vbrk2-netwr + ls_vbrk2-mwsbk.

              "Saldo Pendiente
              LOOP AT lt_bsad INTO ls_bsad WHERE vbeln EQ ls_vbrk2-vbeln AND gjahr EQ ls_vbrk2-gjahr AND bukrs EQ ls_vbrk2-bukrs AND blart EQ 'DZ'.
                READ TABLE lt_tpago INTO ls_tpago WITH KEY nodocu = ls_bsad-belnr ejercicio = ls_bsad-gjahr sociedad = ls_bsad-bukrs.

                IF sy-subrc EQ 0 AND ls_tpago-uuid NE '' AND ls_bsad-vbeln EQ ls_vbrk2-vbeln.
                  lv_pagos = lv_pagos + ls_bsad-wrbtr.
                ENDIF.
                CLEAR: ls_bsid, ls_tpago.
              ENDLOOP.

              wa_de_carterapagadas-saldopendiente = wa_de_carterapagadas-totalfactura - lv_pagos.
              CLEAR lv_pagos.

              "UUID Factura
              READ TABLE lt_timbre INTO ls_timbre WITH KEY nodocu = ls_vbrk2-vbeln.

              IF sy-subrc EQ 0.
                wa_de_carterapagadas-uuid = ls_timbre-uuid.
                CLEAR ls_timbre.
              ENDIF.

              "***DATOS DE DOCUMENTOS DE PAGO***
              LOOP AT lt_bsad INTO ls_bsad WHERE vbeln EQ ls_vbrk2-vbeln AND gjahr EQ ls_vbrk2-gjahr AND bukrs EQ ls_vbrk2-bukrs AND blart EQ 'DZ'.
                "Agenete
                wa_carterapagospag-agente = lv_agente.

                "Cliente
                wa_carterapagospag-cliente = ls_kna1-kunnr.

                READ TABLE lt_tpago INTO ls_tpago WITH KEY sociedad = ls_bsad-bukrs nodocu = ls_bsad-belnr ejercicio = ls_bsad-gjahr.

                IF sy-subrc EQ 0.
                  "Serie
                  wa_carterapagospag-serie = ls_tpago-serie.

                  "UUID
                  wa_carterapagospag-uuid = ls_tpago-uuid.
                ENDIF.
                CLEAR: ls_tpago.

                "Folio
                wa_carterapagospag-folio = ls_vbrk2-vbeln.

                "DocumentoPago
                wa_carterapagospag-documentopago = ls_bsad-belnr.

                "FechaPago
                CONCATENATE ls_bsad-cpudt+6(2) '/' ls_bsad-cpudt+4(2) '/' ls_bsad-cpudt(4) INTO wa_carterapagospag-fechapago.

                "MontoPago
                wa_carterapagospag-montopago = ls_bsad-wrbtr.

                "Parcialidad
                READ TABLE lt_pparc INTO ls_pparc WITH KEY doccompensadz = ls_bsad-belnr sociedad = ls_bsad-bukrs ejercicio = ls_bsad-gjahr.

                IF sy-subrc EQ 0.
                  wa_carterapagospag-parcialidad = ls_pparc-parcialidad.
                ELSEIF wa_carterapagospag-uuid NE '' AND sy-subrc NE 0.
                  wa_carterapagospag-parcialidad = '1'.
                ENDIF.
                CLEAR: ls_pparc.

                IF wa_carterapagospag-uuid NE '' AND wa_de_carterapagadas-saldopendiente EQ 0.
                  APPEND wa_carterapagospag TO wa_de_carterapagadas-to_carterapagospag.
                ENDIF.
                CLEAR: wa_carterapagospag.
              ENDLOOP.

              IF wa_de_carterapagadas-uuid NE '' AND wa_de_carterapagadas-saldopendiente EQ 0.
                APPEND wa_de_carterapagadas TO wa_de_carteraclientesp-to_carterapagadas.
              ENDIF.
              CLEAR: wa_de_carterapagadas.
            ENDLOOP.
            CLEAR: ls_vbrk2.

            APPEND wa_de_carteraclientesp TO wa_de_pagadas-to_carteraclientesp.
            CLEAR: wa_de_carteraclientesp.


            CLEAR: lv_lines.

          ENDLOOP.
          CLEAR: ls_kna1.
        ENDIF.


      ENDIF.

*Se regresa la deep entity comprobante para dar salida en el response.
      IF lv_expand EQ 'TO_CARTERACLIENTES/TO_CARTERAPENDIENTES/TO_CARTERAPAGOSPEN,TO_CARTERACLIENTES/TO_CARTERAPENDIENTES/TO_CARTERANCR'.
        CALL METHOD me->copy_data_to_ref
          EXPORTING
            is_data = wa_de_cartera
          CHANGING
            cr_data = er_entity.
      ELSEIF lv_expand EQ 'TO_CARTERACLIENTESP/TO_CARTERAPAGADAS/TO_CARTERAPAGOSPAG'.
        CALL METHOD me->copy_data_to_ref
          EXPORTING
            is_data = wa_de_pagadas
          CHANGING
            cr_data = er_entity.
      ENDIF.

    ELSEIF iv_entity_name EQ 'soHeader'.                                                "Lectura de pedidos de venta.
      DATA: it_de_header TYPE TABLE OF zcl_zsd_salesapp_mpc=>ts_de_header,
            wa_de_header TYPE          zcl_zsd_salesapp_mpc=>ts_de_header.

      DATA: wa_partners_data         TYPE zcl_zsd_salesapp_mpc=>ts_de_partners,
            wa_items_data            TYPE zcl_zsd_salesapp_mpc=>ts_de_items,
            wa_texts_data            TYPE zcl_zsd_salesapp_mpc=>ts_sotexts,
            wa_partnersitem_data     TYPE zcl_zsd_salesapp_mpc=>ts_sopartnersitem,
            wa_conditionsitem_data   TYPE zcl_zsd_salesapp_mpc=>ts_soconditionsitem,
            wa_textsitem_data        TYPE zcl_zsd_salesapp_mpc=>ts_sotextsitem,
            wa_partneraddresses_data TYPE zcl_zsd_salesapp_mpc=>ts_sopartneraddresses,
            lt_header                TYPE thead,
            lt_lines                 TYPE STANDARD TABLE OF tline,
            lt_lines1                TYPE STANDARD TABLE OF tdline.

      DATA: lv_vbeln TYPE vbeln,
            lv_knumv TYPE knumv,
            lv_name  TYPE tdobname.

*      DATA: lo_tech_request TYPE REF TO /iwbep/cl_mgw_request.

*Lectura de tablas para obtención de valores de consulta
      READ TABLE it_key_tab INTO wa_keytab INDEX 1.
      IF sy-subrc EQ 0.
        lv_vbeln = |{ wa_keytab-value ALPHA = IN }|.   "Convierte el valor de entrada al tipo de datos vbeln definido para la variable lv_vbeln.
      ENDIF.
*Se llena la cabecera
      SELECT FROM vbak AS a INNER JOIN vbkd AS b ON b~vbeln = a~vbeln
      FIELDS a~vbeln, a~auart, a~vkorg, a~vtweg, a~spart, a~vkgrp, a~vkbur, a~vdatu, b~bstdk, a~bsark, b~inco1, a~augru, b~prsdt, b~bstkd, a~vsbed, b~zlsch
      WHERE b~posnr EQ '000000' AND a~vbeln = @lv_vbeln
      INTO TABLE @DATA(it_header).

*Se llenan las tablas internas para el Level 1.
      IF sy-subrc EQ 0.
        SELECT FROM vbpa
          FIELDS vbeln, parvw, kunnr, adrnr
          FOR ALL ENTRIES IN @it_header
          WHERE vbeln EQ @it_header-vbeln AND posnr EQ '000000'
          INTO TABLE @DATA(it_partners).

        SELECT FROM adrc AS a INNER JOIN adr6 AS b ON b~addrnumber = a~addrnumber
          FIELDS a~addrnumber, a~name1, a~name2, a~name3, a~name4, a~city1, a~city2, a~post_code1, a~street, a~streetcode, a~house_num1, a~country, a~langu, a~region, a~tel_number, b~smtp_addr
          FOR ALL ENTRIES IN @it_partners
          WHERE a~addrnumber EQ @it_partners-adrnr
          INTO TABLE @DATA(it_partneraddresses).

        SELECT FROM vbap
          FIELDS vbeln, posnr, matnr, abgru, werks, lgort, kwmeng, vrkme
          FOR ALL ENTRIES IN @it_header
          WHERE vbeln EQ @it_header-vbeln
          INTO TABLE @DATA(it_items).

        SELECT FROM vbpa
          FIELDS vbeln, posnr, parvw, kunnr
          FOR ALL ENTRIES IN @it_items
          WHERE vbeln EQ @it_items-vbeln AND posnr = @it_items-posnr
          INTO TABLE @DATA(it_partnersitem).

        SELECT SINGLE knumv INTO lv_knumv
          FROM vbak
          WHERE vbeln = lv_vbeln.

        SELECT FROM prcd_elements
          FIELDS kposn, kschl, kbetr, waerk, kpein, kmein
          FOR ALL ENTRIES IN @it_items
          WHERE knumv EQ @lv_knumv AND kposn = @it_items-posnr AND ( koaid = 'A' OR koaid = 'B' OR koaid = 'D' ) AND kstat = ''
          INTO TABLE @DATA(it_conditionsitem).
      ENDIF.

*Extracción del texto de cabecera.
      lv_name = |{ lv_vbeln }|.

      CALL FUNCTION 'READ_TEXT'
        EXPORTING
          client          = sy-mandt
          id              = '0001'
          language        = 'S'
          name            = lv_name
          object          = 'VBBK'
        IMPORTING
          header          = lt_header
        TABLES
          lines           = lt_lines
        EXCEPTIONS
          id              = 1
          language        = 2
          name            = 3
          not_found       = 4
          object          = 5
          reference_check = 6.

*Se llena el WA para la cabecera
      LOOP AT it_header INTO DATA(wa_header).

        wa_de_header-salesdocumentin = wa_header-vbeln.
        wa_de_header-doc_type        = wa_header-auart.
        wa_de_header-sales_org       = wa_header-vkorg.
        wa_de_header-distr_chan      = wa_header-vtweg.
        wa_de_header-division        = wa_header-spart.
        wa_de_header-sales_grp       = wa_header-vkgrp.
        wa_de_header-sales_off       = wa_header-vkbur.
        wa_de_header-req_date_h      = wa_header-vdatu.
        wa_de_header-purch_date      = wa_header-bstdk.
        wa_de_header-po_method       = wa_header-bsark.
        wa_de_header-incoterms1      = wa_header-inco1.
        wa_de_header-ord_reason      = wa_header-augru.
        wa_de_header-price_date      = wa_header-prsdt.
        wa_de_header-purch_no_c      = wa_header-bstkd.
        wa_de_header-ship_cond       = wa_header-vsbed.
        wa_de_header-pymt_meth       = wa_header-zlsch.

*Se llenan los WA para el Level 1.
        LOOP AT it_partners INTO DATA(wa_partners) WHERE vbeln = wa_header-vbeln.

          wa_partners_data-salesdocumentin = wa_partners-vbeln.
          wa_partners_data-partn_role      = wa_partners-parvw.
          wa_partners_data-partn_numb      = wa_partners-kunnr.
          wa_partners_data-addr_link       = wa_partners-adrnr.

*Se llena WA para PartnerAddresses
          LOOP AT it_partneraddresses INTO DATA(wa_partneraddresses) WHERE addrnumber = wa_partners-adrnr.

            wa_partneraddresses_data-salesdocumentin = wa_partners-vbeln.
            wa_partneraddresses_data-addr_no         = wa_partneraddresses-addrnumber.
            wa_partneraddresses_data-name            = wa_partneraddresses-name1.
            wa_partneraddresses_data-name_2          = wa_partneraddresses-name2.
            wa_partneraddresses_data-name_3          = wa_partneraddresses-name3.
            wa_partneraddresses_data-name_4          = wa_partneraddresses-name4.
            wa_partneraddresses_data-city            = wa_partneraddresses-city1.
            wa_partneraddresses_data-district        = wa_partneraddresses-city2.
            wa_partneraddresses_data-postl_cod1      = wa_partneraddresses-post_code1.
            wa_partneraddresses_data-street          = wa_partneraddresses-street.
            wa_partneraddresses_data-street_no       = wa_partneraddresses-streetcode.
            wa_partneraddresses_data-house_no        = wa_partneraddresses-house_num1.
            wa_partneraddresses_data-country         = wa_partneraddresses-country.
            wa_partneraddresses_data-langu           = wa_partneraddresses-langu.
            wa_partneraddresses_data-region          = wa_partneraddresses-region.
            wa_partneraddresses_data-tel1_numbr      = wa_partneraddresses-tel_number.
            wa_partneraddresses_data-e_mail          = wa_partneraddresses-tel_number.

            IF wa_partneraddresses-addrnumber = wa_partners-adrnr.
              APPEND wa_partneraddresses_data TO wa_partners_data-to_partneraddresses.
              CLEAR: wa_partneraddresses_data, wa_partneraddresses.
            ENDIF.

          ENDLOOP.

          APPEND wa_partners_data TO wa_de_header-to_partners.
          CLEAR: wa_partners, wa_partners_data-to_partneraddresses.

        ENDLOOP.

        IF NOT lt_lines IS INITIAL.
          lt_lines1 = VALUE #( FOR ls_lines IN lt_lines
                  ( ls_lines-tdline ) ).

          DATA(lv_string) = concat_lines_of( table = lt_lines1 sep = cl_abap_char_utilities=>newline ).

          wa_texts_data-doc_number = lt_header-tdname.
          wa_texts_data-langu      = lt_header-tdspras.
          wa_texts_data-text_id    = lt_header-tdid.
          wa_texts_data-text_line  = lv_string.
          APPEND wa_texts_data TO wa_de_header-to_texts.
          CLEAR: wa_texts_data, lt_header, lt_lines, lt_lines1, lv_string, lv_name.
        ENDIF.

        LOOP AT it_items INTO DATA(wa_items) WHERE vbeln = wa_header-vbeln.

          wa_items_data-salesdocumentin = wa_items-vbeln.
          wa_items_data-itm_number      = wa_items-posnr.
          wa_items_data-material        = wa_items-matnr.
          wa_items_data-reason_rej      = wa_items-abgru.
          wa_items_data-plant           = wa_items-werks.
          wa_items_data-store_loc       = wa_items-lgort.
          wa_items_data-target_qty      = wa_items-kwmeng.
          wa_items_data-target_qu       = wa_items-vrkme.

*Se llenan los WA para Level 2 que dependen de los Items.
          LOOP AT it_partnersitem INTO DATA(wa_partnersitem) WHERE vbeln = wa_items-vbeln AND posnr = wa_items-posnr.

            wa_partnersitem_data-salesdocumentin = wa_partnersitem-vbeln.
            wa_partnersitem_data-itm_number      = wa_partnersitem-posnr.
            wa_partnersitem_data-partn_role      = wa_partnersitem-parvw.
            wa_partnersitem_data-partn_numb      = wa_partnersitem-kunnr.
            APPEND wa_partnersitem_data TO wa_items_data-to_partnersitem.
            CLEAR: wa_partnersitem, wa_items_data-to_partnersitem.

          ENDLOOP.
*Extracción de textos de posición.
          lv_name = |{ lv_vbeln && wa_items-posnr }|.
          CALL FUNCTION 'READ_TEXT'
            EXPORTING
              client          = sy-mandt
              id              = '0001'
              language        = 'S'
              name            = lv_name
              object          = 'VBBP'
            IMPORTING
              header          = lt_header
            TABLES
              lines           = lt_lines
            EXCEPTIONS
              id              = 1
              language        = 2
              name            = 3
              not_found       = 4
              object          = 5
              reference_check = 6.

          IF NOT lt_lines IS INITIAL.

            lt_lines1 = VALUE #( FOR ls_lines IN lt_lines
                                ( ls_lines-tdline ) ).

            lv_string = concat_lines_of( table = lt_lines1 sep = cl_abap_char_utilities=>newline ).

            wa_textsitem_data-doc_number = lt_header-tdname.
            wa_textsitem_data-langu      = lt_header-tdspras.
            wa_textsitem_data-text_id    = lt_header-tdid.
            wa_textsitem_data-text_line  = lv_string.
            APPEND wa_textsitem_data TO wa_items_data-to_textsitem.
            CLEAR: wa_textsitem_data, lt_header, lt_lines, lt_lines1, lv_string, lv_name.

          ENDIF.

          LOOP AT it_conditionsitem INTO DATA(wa_conditionsitem) WHERE kposn = wa_items-posnr. "WHERE vbeln = wa_items-vbeln AND posnr = wa_items-posnr.

            wa_conditionsitem_data-salesdocumentin = lv_vbeln.
            wa_conditionsitem_data-itm_number      = wa_conditionsitem-kposn.
            wa_conditionsitem_data-cond_type       = wa_conditionsitem-kschl.
            wa_conditionsitem_data-cond_value      = wa_conditionsitem-kbetr.
            wa_conditionsitem_data-currency        = wa_conditionsitem-waerk.
            wa_conditionsitem_data-cond_unit       = wa_conditionsitem-kmein.
            wa_conditionsitem_data-cond_p_unt      = wa_conditionsitem-kpein.
            APPEND wa_conditionsitem_data TO wa_items_data-to_conditionsitem.
            CLEAR wa_conditionsitem.

          ENDLOOP.
          APPEND wa_items_data TO wa_de_header-to_items.
          CLEAR: wa_items, wa_items_data-to_conditionsitem, wa_items_data-to_textsitem, wa_items_data-to_partnersitem.
        ENDLOOP.

        APPEND wa_de_header TO it_de_header.
*          CLEAR  wa_de_header.

      ENDLOOP.

*
      CALL METHOD me->copy_data_to_ref
        EXPORTING
          is_data = wa_de_header
        CHANGING
          cr_data = er_entity.

*Asignación de propiedades de navegación
      lo_tech_request ?= io_tech_request_context.
      lv_expand = lo_tech_request->/iwbep/if_mgw_req_entityset~get_expand( ).
      TRANSLATE lv_expand TO UPPER CASE.
      SPLIT lv_expand AT ',' INTO TABLE et_expanded_tech_clauses.

    ELSEIF iv_entity_name EQ 'TrasladoCab'.
      DATA: it_de_traslado TYPE TABLE OF zcl_zsd_salesapp_mpc=>ts_de_trasladocab,
            wa_de_traslado TYPE          zcl_zsd_salesapp_mpc=>ts_de_trasladocab,
            it_trasdet     TYPE TABLE OF zcl_zsd_salesapp_mpc=>ts_trasladodet,
            wa_trasdet     TYPE          zcl_zsd_salesapp_mpc=>ts_trasladodet.

      DATA: lt_matdoc TYPE STANDARD TABLE OF matdoc,
            ls_matdoc TYPE matdoc,
            lt_vbfa   TYPE STANDARD TABLE OF vbfa,
            ls_vbfa   TYPE vbfa,
            lt_ekbe   TYPE STANDARD TABLE OF ekbe,
            ls_ekbe   TYPE ekbe.

      DATA: lv_mblnr TYPE mblnr,
            lv_mjahr TYPE mjahr.

*Lectura de tabla de valores procedentes de la ejecución de la API. Aquí se recibe el valor desde la URL.
      READ TABLE it_key_tab INTO DATA(wa_mblnr) WITH KEY name = 'Mblnr'.
      READ TABLE it_key_tab INTO DATA(wa_mjahr) WITH KEY name = 'Mjahr'.

      IF sy-subrc EQ 0.
        lv_mblnr = |{ wa_mblnr-value ALPHA = IN }|.
        lv_mjahr = |{ wa_mjahr-value ALPHA = IN }|.

        SELECT * FROM matdoc
          WHERE mblnr EQ @lv_mblnr
          AND mjahr EQ @lv_mjahr
          INTO TABLE @lt_matdoc.

        IF sy-subrc EQ 0.

          READ TABLE lt_matdoc INTO ls_matdoc WITH KEY mblnr = lv_mblnr mjahr = lv_mjahr.

          wa_de_traslado-mblnr = ls_matdoc-mblnr.
          wa_de_traslado-mjahr = ls_matdoc-mjahr.
          wa_de_traslado-bwart = ls_matdoc-bwart.

          CLEAR ls_matdoc.

          LOOP AT lt_matdoc INTO ls_matdoc WHERE  mblnr EQ lv_mblnr AND mjahr EQ lv_mjahr AND lbbsa_sid EQ '01'.
            wa_trasdet-matnr     = |{ ls_matdoc-matnr ALPHA = OUT }|.
            wa_trasdet-werks     = ls_matdoc-werks.
            wa_trasdet-lgort     = ls_matdoc-lgort.
            wa_trasdet-charg     = ls_matdoc-charg.
            wa_trasdet-meins     = ls_matdoc-meins.
            wa_trasdet-menge     = ls_matdoc-menge.
            wa_trasdet-mblnr     = ls_matdoc-mblnr.
            wa_trasdet-mjahr     = ls_matdoc-mjahr.
            wa_trasdet-ummat     = ls_matdoc-ummat.
            wa_trasdet-umwrk_cid = ls_matdoc-umwrk_cid.
            wa_trasdet-umlgo     = ls_matdoc-umlgo.
            wa_trasdet-umcha     = ls_matdoc-umcha.
            wa_trasdet-budat     = ls_matdoc-budat.
            wa_trasdet-cpudt     = ls_matdoc-cpudt.
            wa_trasdet-cputm     = ls_matdoc-cputm.
            wa_trasdet-bwart     = ls_matdoc-bwart.
            wa_trasdet-xblnr     = ls_matdoc-xblnr.
            wa_trasdet-usnam     = ls_matdoc-usnam.
            wa_trasdet-vbeln_im  = ls_matdoc-vbeln_im.

            IF wa_trasdet-bwart NE '601'.
              wa_trasdet-zebeln    = ls_matdoc-xblnr.
            ENDIF.

            SELECT * FROM vbfa
              WHERE vbeln EQ @ls_matdoc-xblnr
              AND vbtyp_n EQ 'J'
              AND vbtyp_v EQ 'C'
              INTO TABLE @lt_vbfa.

            IF sy-subrc EQ 0.
              READ TABLE lt_vbfa INTO ls_vbfa WITH KEY vbeln = ls_matdoc-xblnr.
              wa_trasdet-zvbeln = |{ ls_vbfa-vbelv ALPHA = OUT }|.
              CLEAR ls_vbfa.
            ENDIF.

            APPEND wa_trasdet TO wa_de_traslado-to_trasladodet.

            CLEAR: ls_matdoc, wa_trasdet.
          ENDLOOP.
        ENDIF.
      ENDIF.

      CALL METHOD me->copy_data_to_ref
        EXPORTING
          is_data = wa_de_traslado
        CHANGING
          cr_data = er_entity.

*Asignación de propiedades de navegación
      lo_tech_request ?= io_tech_request_context.
      lv_expand = lo_tech_request->/iwbep/if_mgw_req_entityset~get_expand( ).
      TRANSLATE lv_expand TO UPPER CASE.
      SPLIT lv_expand AT ',' INTO TABLE et_expanded_tech_clauses.

    ENDIF.

  ENDMETHOD.


  METHOD monitortraslados_get_entityset.
    DATA: gs_traslados_monitor TYPE  zcl_zsd_salesapp_mpc_ext=>ts_monitortraslados,
          lv_fechaini          TYPE fkdat,
          lv_fechafin          TYPE fkdat,
          lv_diasdiff          TYPE dlydy,
          lv_diasdiff1         TYPE c LENGTH 6.

    DATA: lt_matdoc TYPE STANDARD TABLE OF matdoc,
          ls_matdoc TYPE matdoc,
          lt_bwart  TYPE STANDARD TABLE OF zparamglob,
          ls_bwart  TYPE zparamglob,
          lt_vbfa   TYPE STANDARD TABLE OF vbfa,
          ls_vbfa   TYPE vbfa,
          lt_ekbe   TYPE STANDARD TABLE OF ekbe,
          ls_ekbe   TYPE ekbe,
          lt_trasl  TYPE STANDARD TABLE OF zmm_traslados,
          ls_trasl  TYPE zmm_traslados.

*Cálculo de fechas para intervalo de búsqueda de facturas sin timbrar.
    SELECT SINGLE valor1
        INTO @lv_diasdiff1
        FROM zparamglob
        WHERE programa = 'ZSD_CARGAPEDIDOS'
        AND parametro = '9'
        AND subparametro = '1'.

    lv_diasdiff = lv_diasdiff1.

    CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
      EXPORTING
        date      = sy-datum
        days      = lv_diasdiff
        months    = 0
        signum    = '-' " para calcular fechas anteriores
        years     = 0
      IMPORTING
        calc_date = lv_fechaini.

    lv_fechafin = sy-datum.

*Se recuperan las clases de movimiento de la tabla ZPARAMGLOB para las consultas
    SELECT * FROM zparamglob
      WHERE programa = 'ZSD_CARGAPEDIDOS'
      AND parametro = '10'
      INTO TABLE @lt_bwart.

*Selección de documentos de material con movimiento de mercancía de tabla MATDOC
    SELECT * FROM matdoc
      FOR ALL ENTRIES IN @lt_bwart
      WHERE budat GE @lv_fechaini
      AND budat LE @lv_fechafin
      AND bwart EQ @lt_bwart-valor1(3)
      INTO TABLE @lt_matdoc.

    "Buscamos en la tabla ZMM_TRASLADOS para descartar aquellos documentos de material que ya fueron procesados en G-LINK.
    SELECT * FROM zmm_traslados
      FOR ALL ENTRIES IN @lt_matdoc
      WHERE mblnr EQ @lt_matdoc-mblnr
      AND mjahr EQ @lt_matdoc-mjahr
      AND bwart EQ @lt_matdoc-bwart
      INTO TABLE @lt_trasl.

    LOOP AT lt_matdoc INTO ls_matdoc.

      READ TABLE lt_trasl INTO ls_trasl WITH KEY mblnr = ls_matdoc-mblnr mjahr = ls_matdoc-mjahr bwart = ls_matdoc-bwart.

      IF ( sy-subrc EQ 0 AND ls_trasl-registrado EQ '' ) OR sy-subrc NE 0.
        gs_traslados_monitor-mblnr   = ls_matdoc-mblnr.
        gs_traslados_monitor-mjahr   = ls_matdoc-mjahr.
        gs_traslados_monitor-bwart   = ls_matdoc-bwart.

        "Búsqueda de origen del documento de material.
        SELECT * FROM vbfa
          WHERE vbeln EQ @ls_matdoc-xblnr
          INTO TABLE @lt_vbfa.

        IF sy-subrc EQ 0.
          gs_traslados_monitor-origfen = 'Ventas'.
        ELSEIF sy-subrc NE 0.
          SELECT * FROM ekbe
            WHERE belnr EQ @ls_matdoc-xblnr
            INTO TABLE @lt_ekbe.
          IF sy-subrc EQ 0.
            gs_traslados_monitor-origfen = 'Traslado'.
          ENDIF.
        ENDIF.

        APPEND gs_traslados_monitor TO et_entityset.
        SORT et_entityset ASCENDING BY mblnr mjahr bwart.
        DELETE ADJACENT DUPLICATES FROM et_entityset COMPARING mblnr mjahr bwart.
      ENDIF.
      CLEAR: gs_traslados_monitor, ls_matdoc.
    ENDLOOP.
  ENDMETHOD.


  method TRASLADORESULTSE_CREATE_ENTITY.
    DATA: ls_trasladoresult TYPE zcl_zsd_salesapp_mpc_ext=>ts_trasladoresult,
          lo_msg            TYPE REF TO /iwbep/if_message_container,
          lv_error_msg      TYPE bapi_msg,
          lv_mblnr          TYPE mblnr,
          lv_mjahr          TYPE mjahr,
          lv_bwart          TYPE bwart,
          lt_matdocu        TYPE STANDARD TABLE OF matdoc.

    CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
      RECEIVING
        ro_message_container = lo_msg.

*Lectura del request recibido en el método POST.
    TRY.
        CALL METHOD io_data_provider->read_entry_data
          IMPORTING
            es_data = ls_trasladoresult.
      CATCH /iwbep/cx_mgw_tech_exception.
    ENDTRY.

    lv_mblnr = |{ ls_trasladoresult-mblnr ALPHA = IN }|.
    lv_mjahr = |{ ls_trasladoresult-mjahr ALPHA = IN }|.
    lv_bwart = |{ ls_trasladoresult-bwart ALPHA = IN }|.

    IF lv_mblnr EQ ''.
      lv_error_msg = 'El número de documento de material está vacío'.

      CALL METHOD lo_msg->add_message
        EXPORTING
          iv_msg_type   = /iwbep/cl_cos_logger=>error
          iv_msg_id     = 'ZSD_MSG'
          iv_msg_number = '001'
          iv_msg_text   = lv_error_msg.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ENDIF.

    IF lv_mjahr EQ ''.
      lv_error_msg = 'El año para el número de documento de material está vacío'.

      CALL METHOD lo_msg->add_message
        EXPORTING
          iv_msg_type   = /iwbep/cl_cos_logger=>error
          iv_msg_id     = 'ZSD_MSG'
          iv_msg_number = '002'
          iv_msg_text   = lv_error_msg.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ENDIF.

    IF lv_bwart EQ ''.
      lv_error_msg = 'La clave de movimiento para el número de documento de material está vacío'.

      CALL METHOD lo_msg->add_message
        EXPORTING
          iv_msg_type   = /iwbep/cl_cos_logger=>error
          iv_msg_id     = 'ZSD_MSG'
          iv_msg_number = '003'
          iv_msg_text   = lv_error_msg.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ENDIF.

    SELECT * FROM matdoc
      WHERE mblnr = @lv_mblnr
      AND mjahr = @lv_mjahr
      AND bwart = @lv_bwart
      INTO TABLE @lt_matdocu.

    IF sy-subrc NE 0.
      CONCATENATE 'No existe el documento de material' lv_mblnr 'para el ejercicio' lv_mjahr 'con la clase de movimiento' lv_bwart INTO lv_error_msg SEPARATED BY space.

      CALL METHOD lo_msg->add_message
        EXPORTING
          iv_msg_type   = /iwbep/cl_cos_logger=>error
          iv_msg_id     = 'ZSD_MSG'
          iv_msg_number = '004'
          iv_msg_text   = lv_error_msg.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ELSEIF sy-subrc EQ 0.
      INSERT zmm_traslados FROM ls_trasladoresult.
      CLEAR ls_trasladoresult.
    ENDIF.




  endmethod.


  METHOD trasladosset_get_entityset.
    DATA: lt_traslado TYPE TABLE OF zcl_zsd_salesapp_mpc_ext=>ts_traslados,
          ls_traslado TYPE zcl_zsd_salesapp_mpc_ext=>ts_traslados.

    DATA: lt_matdoc TYPE STANDARD TABLE OF matdoc,
          ls_matdoc TYPE matdoc,
          lt_vbfa   TYPE STANDARD TABLE OF vbfa,
          ls_vbfa   TYPE vbfa,
          lt_ekbe   TYPE STANDARD TABLE OF ekbe,
          ls_ekbe   TYPE ekbe.

    DATA: lv_mblnr TYPE mblnr,
          lv_mjahr TYPE mjahr,
          lo_msg   TYPE REF TO /iwbep/if_message_container.

*Instancia a objeto para contenedor de mensajes de error.
    CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
      RECEIVING
        ro_message_container = lo_msg.

*Lectura de tabla de valores procedentes de la ejecución de la API. Aquí se recibe el valor desde la URL.
    READ TABLE it_key_tab INTO DATA(wa_mblnr) WITH KEY name = 'Mblnr'.
    READ TABLE it_key_tab INTO DATA(wa_mjahr) WITH KEY name = 'Mjahr'.

    IF sy-subrc EQ 0.
      lv_mblnr = |{ wa_mblnr-value ALPHA = IN }|.
      lv_mjahr = |{ wa_mjahr-value ALPHA = IN }|.

      IF iv_entity_name EQ 'Traslados'.

        SELECT * FROM matdoc
          WHERE mblnr EQ @lv_mblnr
          AND mjahr EQ @lv_mjahr
          INTO TABLE @lt_matdoc.

        IF sy-subrc EQ 0.
          "READ TABLE lt_matdoc INTO ls_matdoc WITH KEY mblnr = lv_mblnr mjahr = lv_mjahr.
          LOOP AT lt_matdoc INTO ls_matdoc WHERE  mblnr EQ lv_mblnr AND mjahr EQ lv_mjahr AND lbbsa_sid EQ '01'.
            ls_traslado-matnr     = |{ ls_matdoc-matnr ALPHA = OUT }|.
            ls_traslado-werks     = ls_matdoc-werks.
            ls_traslado-lgort     = ls_matdoc-lgort.
            ls_traslado-charg     = ls_matdoc-charg.
            ls_traslado-meins     = ls_matdoc-meins.
            ls_traslado-menge     = ls_matdoc-menge.
            ls_traslado-mblnr     = ls_matdoc-mblnr.
            ls_traslado-mjahr     = ls_matdoc-mjahr.
            ls_traslado-ummat     = ls_matdoc-ummat.
            ls_traslado-umwrk_cid = ls_matdoc-umwrk_cid.
            ls_traslado-umlgo     = ls_matdoc-umlgo.
            ls_traslado-umcha     = ls_matdoc-umcha.
            ls_traslado-budat     = ls_matdoc-budat.
            ls_traslado-cpudt     = ls_matdoc-cpudt.
            ls_traslado-cputm     = ls_matdoc-cputm.
            ls_traslado-bwart     = ls_matdoc-bwart.
            ls_traslado-xblnr     = ls_matdoc-xblnr.
            ls_traslado-usnam     = ls_matdoc-usnam.
            ls_traslado-vbeln_im  = ls_matdoc-vbeln_im.

            IF ls_matdoc-bwart NE '601'.
              ls_traslado-zebeln    = ls_matdoc-xblnr.
            ENDIF.

            SELECT * FROM vbfa
              WHERE vbeln EQ @ls_matdoc-xblnr
              AND vbtyp_n EQ 'J'
              AND vbtyp_v EQ 'C'
              INTO TABLE @lt_vbfa.

            IF sy-subrc EQ 0.
              READ TABLE lt_vbfa INTO ls_vbfa WITH KEY vbeln = ls_matdoc-xblnr.
              ls_traslado-zvbeln = |{ ls_vbfa-vbelv ALPHA = OUT }|.
              CLEAR ls_vbfa.
            ENDIF.

            APPEND ls_traslado TO et_entityset.
            CLEAR: ls_matdoc, ls_traslado.
          ENDLOOP.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
