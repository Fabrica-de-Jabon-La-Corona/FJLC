class ZCL_IM_ME_PROCESS_PO_CUST definition
  public
  final
  create public .

public section.

  interfaces IF_BADI_INTERFACE .
  interfaces IF_EX_ME_PROCESS_PO_CUST .
protected section.
private section.
ENDCLASS.



CLASS ZCL_IM_ME_PROCESS_PO_CUST IMPLEMENTATION.


  method IF_EX_ME_PROCESS_PO_CUST~CHECK.
  endmethod.


  method IF_EX_ME_PROCESS_PO_CUST~CLOSE.
  endmethod.


  method IF_EX_ME_PROCESS_PO_CUST~FIELDSELECTION_HEADER.
  endmethod.


  method IF_EX_ME_PROCESS_PO_CUST~FIELDSELECTION_HEADER_REFKEYS.
  endmethod.


  method IF_EX_ME_PROCESS_PO_CUST~FIELDSELECTION_ITEM.
  endmethod.


  method IF_EX_ME_PROCESS_PO_CUST~FIELDSELECTION_ITEM_REFKEYS.
  endmethod.


  method IF_EX_ME_PROCESS_PO_CUST~INITIALIZE.
  endmethod.


  method IF_EX_ME_PROCESS_PO_CUST~OPEN.
  endmethod.


  method IF_EX_ME_PROCESS_PO_CUST~POST.
  endmethod.


  method IF_EX_ME_PROCESS_PO_CUST~PROCESS_ACCOUNT.
  endmethod.


  method IF_EX_ME_PROCESS_PO_CUST~PROCESS_HEADER.
  endmethod.


  METHOD if_ex_me_process_po_cust~process_item.
    "Inicio - CAOLIVAS - Determinación de almacén origen PT53 para pedidos de traslado a exportación Nuevo Laredo. - 05.03.2025
    DATA: ls_hdr  TYPE REF TO if_purchase_order_mm.

    DATA: ls_hdrdata  TYPE mepoheader,
          ls_itemdata TYPE mepoitem.

    ls_hdr = im_item->get_header( ).
    ls_hdrdata = ls_hdr->get_data( ).

    IF ls_hdrdata-bsart EQ 'ZUB'.   "Se valida que la clase de pedido sea de traslado "ZUB"
      CASE ls_hdrdata-reswk.
        WHEN 'CXAL'."Se valida que el origen sea Xalostoc "CXAL"
          ls_itemdata = im_item->get_data( ).
          IF  ls_itemdata-werks EQ 'CNLD' AND ls_itemdata-lgort EQ 'NLD2'. "Se valida que el destino sea el centro Nuevo Laredo "CNLD" y almacén de exportaciones "NLD2".
            IF ls_itemdata-reslo EQ ''.
              ls_itemdata-reslo = 'PT53'.
              im_item->set_data( im_data = ls_itemdata ).
            ENDIF.
          ENDIF.
        WHEN 'CQRO'.
        WHEN OTHERS.
      ENDCASE.
    ENDIF.
    "Fin - CAOLIVAS - Determinación de almacén origen PT53 para pedidos de traslado a exportación Nuevo Laredo. - 05.03.2025
  ENDMETHOD.


  method IF_EX_ME_PROCESS_PO_CUST~PROCESS_SCHEDULE.
  endmethod.
ENDCLASS.
