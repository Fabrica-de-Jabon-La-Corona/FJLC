class ZCL_ZMM_PURCHORD_DPC_EXT definition
  public
  inheriting from ZCL_ZMM_PURCHORD_DPC
  create public .

public section.

  interfaces IF_EX_ME_PROCESS_PO_CUST .

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CREATE_DEEP_ENTITY
    redefinition .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ZMM_PURCHORD_DPC_EXT IMPLEMENTATION.


  METHOD /iwbep/if_mgw_appl_srv_runtime~create_deep_entity.
    DATA: ls_de_purchase   TYPE zcl_zmm_purchord_mpc_ext=>ts_de_poheader,
          ls_poheader_data TYPE zcl_zmm_purchord_mpc_ext=>ts_poheader,
          ls_poitems_data  TYPE zcl_zmm_purchord_mpc_ext=>ts_poitems,
          lt_poitems_data  TYPE zcl_zmm_purchord_mpc_ext=>tt_poitems,
          ls_poheader_in   TYPE bapimepoheader,
          ls_poheader_inx  TYPE bapimepoheaderx,
          ls_poitem_in     TYPE bapimepoitem,
          lt_poitem_in     TYPE STANDARD TABLE OF bapimepoitem,
          ls_poitem_inx    TYPE bapimepoitemx,
          lt_poitem_inx    TYPE STANDARD TABLE OF bapimepoitemx,
          ls_return        TYPE bapiret2,
          lt_return        TYPE STANDARD TABLE OF bapiret2,
          ls_poitemdata    TYPE mepoitem.

    DATA: lv_purchord TYPE bapimepoheader-po_number,
          lv_matnr    TYPE c LENGTH 18.

    CONSTANTS: abap_true   TYPE c LENGTH 1 VALUE 'X',
               lc_programa TYPE c LENGTH 12 VALUE 'ZMM_PURCHORD'.

    DATA: lo_msg    TYPE REF TO /iwbep/if_message_container,
          lo_procpo TYPE REF TO if_ex_me_process_po_cust,
          lo_poitem TYPE REF TO if_purchase_order_item_mm.

    CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
      RECEIVING
        ro_message_container = lo_msg.

*Lectura del request recibido en el método POST.
    TRY.
        CALL METHOD io_data_provider->read_entry_data
          IMPORTING
            es_data = ls_de_purchase.
      CATCH /iwbep/cx_mgw_tech_exception.
    ENDTRY.

    MOVE-CORRESPONDING ls_de_purchase TO ls_poheader_data.

    IF NOT ls_poheader_data IS INITIAL.
      "Llenado de estructura header_in y header_inx.
      ls_poheader_in-comp_code = ls_poheader_data-comp_code.
      ls_poheader_in-vendor    = ls_poheader_data-vendor.
      ls_poheader_in-purch_org = ls_poheader_data-purch_org.
      ls_poheader_in-pur_group = ls_poheader_data-pur_group.
      ls_poheader_in-doc_date  = ls_poheader_data-doc_date.
      ls_poheader_in-shiptype  = ls_poheader_data-shiptype.

      SELECT SINGLE valor1 INTO ls_poheader_in-doc_type
        FROM zparamglob
        WHERE programa EQ lc_programa
        AND parametro EQ '1'
        AND subparametro EQ '1'.

      ls_poheader_inx-comp_code = abap_true.
      ls_poheader_inx-vendor    = abap_true.
      ls_poheader_inx-purch_org = abap_true.
      ls_poheader_inx-pur_group = abap_true.
      ls_poheader_inx-doc_date  = abap_true.
      ls_poheader_inx-shiptype  = abap_true.
      ls_poheader_inx-doc_type  = abap_true.

      lt_poitems_data[] = ls_de_purchase-to_poitems[].

      LOOP AT lt_poitems_data INTO ls_poitems_data.

        lv_matnr = |{ ls_poitems_data-material ALPHA = IN }|.

        ls_poitem_in-po_item      = ls_poitems_data-po_item.
        ls_poitem_in-short_text   = ls_poitems_data-short_text.
        ls_poitem_in-material     = lv_matnr.
        ls_poitem_in-plant        = ls_poitems_data-plant.
        ls_poitem_in-stge_loc     = ls_poitems_data-stge_loc.
        ls_poitem_in-quantity     = ls_poitems_data-quantity.
        ls_poitem_in-po_unit      = ls_poitems_data-po_unit.
        ls_poitem_in-item_cat     = ls_poitems_data-item_cat.
        ls_poitem_in-order_reason = ls_poitems_data-order_reason.
        ls_poitem_in-batch        = ls_poitems_data-batch.
        ls_poitem_in-suppl_stloc  = ls_poitems_data-suppl_stloc.

        ls_poitem_inx-po_item      = ls_poitems_data-po_item.
        ls_poitem_inx-short_text   = abap_true.
        ls_poitem_inx-material     = abap_true.
        ls_poitem_inx-plant        = abap_true.
        ls_poitem_inx-stge_loc     = abap_true.
        ls_poitem_inx-quantity     = abap_true.
        ls_poitem_inx-po_unit      = abap_true.
        ls_poitem_inx-item_cat     = abap_true.
        ls_poitem_inx-order_reason = abap_true.
        ls_poitem_inx-batch        = abap_true.

        APPEND: ls_poitem_in TO lt_poitem_in,
                ls_poitem_inx TO lt_poitem_inx.

        CLEAR: ls_poitem_in, ls_poitem_inx.
      ENDLOOP.

      TRY.
          CALL FUNCTION 'BAPI_PO_CREATE1'
            EXPORTING
              poheader         = ls_poheader_in
              poheaderx        = ls_poheader_inx
            IMPORTING
              exppurchaseorder = lv_purchord
            TABLES
              return           = lt_return
              poitem           = lt_poitem_in
              poitemx          = lt_poitem_inx.
        CATCH /iwbep/cx_mgw_tech_exception.
      ENDTRY.

      IF NOT line_exists( lt_return[ type = 'E' ] ).
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
        ls_de_purchase-po_number = lv_purchord.

*Se valida si el campo "Clase de expedición" no está vacío para actualizar el pedido creado.
        IF ls_poheader_data-shiptype NE ''.
*          CALL METHOD lo_procpo->process_item
*            EXPORTING
*              im_item = lo_poitem.
*
*          ls_poitemdata = lo_poitem->get_data( ).
*
*          ls_poitemdata-vsart = ls_poheader_data-shiptype.
*
*          lo_poitem->set_data( EXPORTING im_data = ls_poitemdata ).

        ENDIF.

      ELSE.
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
      is_data = ls_de_purchase
    CHANGING
      cr_data = er_deep_entity
    ).

  ENDMETHOD.


  method IF_EX_ME_PROCESS_PO_CUST~PROCESS_ITEM.
  endmethod.
ENDCLASS.
