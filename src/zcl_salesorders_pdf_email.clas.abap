CLASS zcl_salesorders_pdf_email DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: ty_item TYPE TABLE OF zsd_st_sales_orders.

    METHODS: send_mail_customer IMPORTING iv_vbeln     TYPE vbeln
                                          iv_kunnr     TYPE kunnr
                                          iv_po_number TYPE bstkd
                                          iv_so_date   TYPE audat
                                          iv_dlv_date  TYPE edatu_vbak
                                          iv_shipto    TYPE kunnr
                                          iv_grossw    TYPE brgew
                                          iv_netw      TYPE ntgew
                                          iv_gewei     TYPE gewei
                                          iv_terms     TYPE vtext
                                          iv_inco1     TYPE inco1
                                          iv_inco2     TYPE inco2
                                          iv_subtotal  TYPE netwr
                                          iv_taxporc   TYPE kbetr
                                          iv_taxbase   TYPE netwr
                                          iv_totaltax  TYPE netwr
                                          iv_total     TYPE netwr
                                          iv_uname     TYPE uname
                                          it_item      TYPE ty_item.
  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS: get_customer_data IMPORTING iv_kunnr  TYPE kunnr
                                         iv_shipto TYPE kunnr,
      get_user_data     IMPORTING iv_uname TYPE uname,
      create_pdf,
      send_mail.

* Customer Data
    DATA: mv_mail TYPE adr6-smtp_addr,
          mv_name TYPE name1_gp.

* Smartform
    CONSTANTS: gc_format   TYPE so_obj_tp VALUE 'PDF',
               gc_formname TYPE tdsfname  VALUE 'ZSF_SALESORDERS_PDF'.

* PDF
    DATA: mv_pdf_content TYPE solix_tab,
          mv_pdf_size    TYPE so_obj_len.

*Sales Document
    DATA: mv_vbeln       TYPE vbeln,
          mv_kunnr       TYPE kunnr,
          mv_po_number   TYPE bstkd,
          mv_so_date     TYPE audat,
          mv_dlv_date    TYPE edatu_vbak,
          mv_shipto      TYPE kunnr,
          mv_name1_ag    TYPE name1,
          mv_name2_ag    TYPE name2,
          mv_housenum_ag TYPE ad_hsnm1,
          mv_street_ag   TYPE ad_street,
          mv_city_ag     TYPE ad_city1,
          mv_regio_ag    TYPE regio,
          mv_postl_ag    TYPE ad_pstcd1,
          mv_land_ag     TYPE land1,
          mv_name1_we    TYPE name1,
          mv_name2_we    TYPE name2,
          mv_housenum_we TYPE ad_hsnm1,
          mv_street_we   TYPE ad_street,
          mv_city_we     TYPE ad_city1,
          mv_regio_we    TYPE regio,
          mv_postl_we    TYPE ad_pstcd1,
          mv_land_we     TYPE land1,
          mv_terms       TYPE vtext,
          mv_grossw      TYPE brgew,
          mv_netw        TYPE ntgew,
          mv_gewei       TYPE gewei,
          mv_inco1       TYPE inco1,
          mv_inco2       TYPE inco2,
          mv_subtotal    TYPE netwr,
          mv_taxporc     TYPE kbetr,
          mv_taxbase     TYPE netwr,
          mv_totaltax    TYPE netwr,
          mv_total       TYPE netwr,
          mv_uname       TYPE uname,
          mv_bname_smtp  TYPE ad_smtpadr,
          mt_items       TYPE zsd_tt_sales_orders.

ENDCLASS.



CLASS ZCL_SALESORDERS_PDF_EMAIL IMPLEMENTATION.


  METHOD create_pdf.
    DATA: ls_job_output_info TYPE ssfcrescl,
          lv_fm_name         TYPE rs38l_fnam,
          lv_size            TYPE i,
          lt_lines           TYPE TABLE OF tline.

* Obtener el nombre del módulo de funciones basados en el nombre del smartform.
    CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
      EXPORTING
        formname           = gc_formname
      IMPORTING
        fm_name            = lv_fm_name
      EXCEPTIONS
        no_form            = 1
        no_function_module = 2
        OTHERS             = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

* Deshabilitar dialogo en obtención de OTF desde el smartform
    DATA(ls_control_parameters) = VALUE ssfctrlop( no_dialog = abap_true
                                                   preview = space
                                                   getotf = abap_true ).

* Deshabilitar previsualización del smartform
    DATA(ls_output_options) = VALUE ssfcompop( tdnoprev = abap_false
                                               tdnoprint = abap_false ).

* Generación del smartform
    CALL FUNCTION lv_fm_name
      EXPORTING
        control_parameters = ls_control_parameters
        output_options     = ls_output_options
        iv_doc_number      = mv_vbeln
        iv_cust_id         = mv_kunnr
        iv_po_number       = mv_po_number
        iv_so_date         = mv_so_date
        iv_dlv_date        = mv_dlv_date
        iv_shipto_id       = mv_shipto
        iv_name1_ag        = mv_name1_ag
        iv_name2_ag        = mv_name2_ag
        iv_housenum_ag     = mv_housenum_ag
        iv_street_ag       = mv_street_ag
        iv_city_ag         = mv_city_ag
        iv_regio_ag        = mv_regio_ag
        iv_postl_ag        = mv_postl_ag
        iv_land_ag         = mv_land_ag
        iv_name1_we        = mv_name1_we
        iv_name2_we        = mv_name2_we
        iv_housenum_we     = mv_housenum_we
        iv_street_we       = mv_street_we
        iv_city_we         = mv_city_we
        iv_regio_we        = mv_regio_we
        iv_postl_we        = mv_postl_we
        iv_land_we         = mv_land_we
        iv_terms           = mv_terms
        iv_grossw          = mv_grossw
        iv_netw            = mv_netw
        iv_gewei           = mv_gewei
        iv_inco1           = mv_inco1
        iv_inco2           = mv_inco2
        iv_subtotal        = mv_subtotal
        iv_taxporc         = mv_taxporc
        iv_taxbase         = mv_taxbase
        iv_totaltax        = mv_totaltax
        iv_total           = mv_total
      IMPORTING
        job_output_info    = ls_job_output_info
      TABLES
        it_items           = mt_items
      EXCEPTIONS
        formatting_error   = 1
        internal_error     = 2
        send_error         = 3
        user_canceled      = 4
        OTHERS             = 5.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

* Convertir el OTF que nos entrega el smartform a PDF XString.
    CALL FUNCTION 'CONVERT_OTF'
      EXPORTING
        format                = gc_format
      IMPORTING
        bin_filesize          = lv_size
      TABLES
        otf                   = ls_job_output_info-otfdata
        lines                 = lt_lines
      EXCEPTIONS
        err_max_linewidth     = 1
        err_format            = 2
        err_conv_not_possible = 3
        err_bad_otf           = 4
        OTHERS                = 5.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    FIELD-SYMBOLS: <l_xline> TYPE x.

    LOOP AT lt_lines INTO DATA(ls_lines).
      ASSIGN ls_lines TO <l_xline> CASTING.
      CONCATENATE pdf_xstring <l_xline> INTO DATA(pdf_xstring) IN BYTE MODE.
    ENDLOOP.

* Convertir PDF XString a Solix
* Wrapper Class para documentos Office - BCS Business Communication Service

    mv_pdf_size = xstrlen( pdf_xstring ).
    mv_pdf_content = cl_document_bcs=>xstring_to_solix( ip_xstring = pdf_xstring ).

  ENDMETHOD.


  METHOD get_customer_data.

* Llena datos de cliente Sold-To (Solicitante)
    SELECT SINGLE FROM kna1 AS kn
           JOIN adrc AS ac ON kn~adrnr = ac~addrnumber
           FIELDS ac~name1, ac~name2, ac~house_num1, ac~street, ac~city1, ac~region, ac~post_code1, ac~country
           WHERE kn~kunnr = @iv_kunnr
           INTO ( @mv_name1_ag, @mv_name2_ag, @mv_housenum_ag, @mv_street_ag, @mv_city_ag, @mv_regio_ag, @mv_postl_ag, @mv_land_ag ).

    IF iv_kunnr EQ iv_shipto.
      mv_name1_we    = mv_name1_ag.
      mv_name2_we    = mv_name2_ag.
      mv_housenum_we = mv_housenum_ag.
      mv_street_we   = mv_street_ag.
      mv_city_we     = mv_city_ag.
      mv_regio_we    = mv_regio_ag.
      mv_postl_we    = mv_postl_ag.
      mv_land_we     = mv_land_ag.
    ELSE.
      SELECT SINGLE FROM kna1 AS kn
           JOIN adrc AS ac ON kn~adrnr = ac~addrnumber
           FIELDS ac~name1, ac~name2, ac~house_num1, ac~street, ac~city1, ac~region, ac~post_code1, ac~country
           WHERE kn~kunnr = @iv_shipto
           INTO ( @mv_name1_we, @mv_name2_we, @mv_housenum_we, @mv_street_we, @mv_city_we, @mv_regio_we, @mv_postl_we, @mv_land_we ).
    ENDIF.

  ENDMETHOD.


  METHOD get_user_data.
    SELECT SINGLE FROM usr21 AS us
      JOIN adr6 AS ad ON us~addrnumber = ad~addrnumber AND us~persnumber = ad~persnumber
      FIELDS ( ad~smtp_addr )
      WHERE us~bname = @iv_uname
      INTO ( @mv_bname_smtp ).
  ENDMETHOD.


  METHOD send_mail.

    CONSTANTS: lc_htm    TYPE char03   VALUE 'HTM',
               lc_id     TYPE tdid     VALUE 'ST',
               lc_name   TYPE tdobname VALUE 'ZST_EMAIL_SO',
               lc_object TYPE tdobject VALUE 'TEXT'.

    DATA: lv_subject   TYPE so_obj_des,
          lv_att_title TYPE so_obj_des.

    DATA: lt_lines  TYPE TABLE OF tline,
          ls_header TYPE thead.

    lv_subject = |New Sales Document { mv_vbeln } created|.

*Leer la plantilla del cuerpo del correo.
    CALL FUNCTION 'READ_TEXT'
      EXPORTING
        client                  = sy-mandt
        id                      = lc_id
        language                = sy-langu
        name                    = lc_name
        object                  = lc_object
      IMPORTING
        header                  = ls_header
      TABLES
        lines                   = lt_lines
      EXCEPTIONS
        id                      = 1
        language                = 2
        name                    = 3
        not_found               = 4
        object                  = 5
        reference_check         = 6
        wrong_access_to_archive = 7
        OTHERS                  = 8.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

*Reemplazar variables dentro del template para el cuerpo del correo.*
    CALL FUNCTION 'INIT_TEXTSYMBOL'.

* Se establece text symbol dinámico
    CALL FUNCTION 'SET_TEXTSYMBOL'
      EXPORTING
        name    = '&TEXT_NAME&'
        value   = mv_name1_ag
        replace = abap_true.

    CALL FUNCTION 'SET_TEXTSYMBOL'
      EXPORTING
        name    = '&TEXT_ORDER&'
        value   = mv_vbeln
        replace = abap_true.

    CALL FUNCTION 'SET_TEXTSYMBOL'
      EXPORTING
        name    = '&TEXT_PURCHORD&'
        value   = mv_po_number
        replace = abap_true.

* Longitud del texto.
    DATA(lv_count) = lines( lt_lines ).

    CALL FUNCTION 'REPLACE_TEXTSYMBOL'
      EXPORTING
        endline   = lv_count
        startline = 1
      TABLES
        lines     = lt_lines.
*********************************************************************

* Convertir el cuerpo del email a HTML

    DATA: lt_html_text  TYPE TABLE OF htmlline,
          lt_body_email TYPE soli_tab.

    CALL FUNCTION 'CONVERT_ITF_TO_HTML'
      EXPORTING
        i_header       = ls_header
        i_title        = 'Title'
      TABLES
        t_itf_text     = lt_lines
        t_html_text    = lt_html_text
      EXCEPTIONS
        syntax_check   = 1
        replace        = 2
        illegal_header = 3
        OTHERS         = 4.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    lt_body_email[] = lt_html_text[].

****************Asunto y cuerpo del correo**********************
    TRY.
        DATA(lo_send_request) = cl_bcs=>create_persistent( ).

* Añadimos el sender al request
        lo_send_request->set_sender( i_sender = cl_sapuser_bcs=>create( sy-uname ) ).  "Tomamos el email de envío de los datos del usuario (SU01)

* Añadir el recipient al request
*        lo_send_request->add_recipient( i_recipient = cl_cam_address_bcs=>create_internet_address( mv_mail )
*                                        i_express = abap_true ).                                                "Se convierte el email del cliente a un recipient para el remitente del correo.

*Añadir el recipient al request con el correo del usuario que creó el pedido.
        lo_send_request->add_recipient( i_recipient = cl_cam_address_bcs=>create_internet_address( mv_bname_smtp )
                                                i_express = abap_true ).                                                "Se convierte el email del autor del pedido a un recipient para el remitente del correo.

*Cuerpo del correo
        DATA(lo_document) = cl_document_bcs=>create_document( i_type = lc_htm
                                          i_subject = lv_subject
                                          i_text = lt_body_email ).
****************************************************************

*Añadir el documento adjunto
        lv_att_title = |{ mv_vbeln }-{ sy-datum }.pdf|.

        lo_document->add_attachment( i_attachment_type = gc_format
                                     i_attachment_subject = lv_att_title
                                     i_att_content_hex = mv_pdf_content ).

        lo_send_request->set_document( lo_document ).

*Envío del correo
        lo_send_request->send(
        EXPORTING
          i_with_error_screen = abap_true
        RECEIVING
          result = DATA(lv_sentto_all) ).

*Valida que esté correcto el envío
        CHECK lv_sentto_all = abap_true.

*Se ejecutan las acciones de envío.
        COMMIT WORK.

      CATCH cx_bcs INTO DATA(lo_bcs_exception).
        WRITE: |Type: { lo_bcs_exception->error_type } / Message { lo_bcs_exception->get_text(  ) }|.
    ENDTRY..


  ENDMETHOD.


  METHOD send_mail_customer.
    mv_vbeln     = |{ iv_vbeln ALPHA = OUT }|.
    mv_kunnr     = iv_kunnr.
    mv_po_number = iv_po_number.
    mv_so_date   = iv_so_date.
    mv_dlv_date  = iv_dlv_date.
    mv_shipto    = iv_shipto.
    mv_grossw    = iv_grossw.
    mv_netw      = iv_netw.
    mv_gewei     = iv_gewei.
    mv_terms     = iv_terms.
    mv_inco1     = iv_inco1.
    mv_inco2     = iv_inco2.
    mv_subtotal  = iv_subtotal.
    mv_taxporc   = iv_taxporc.
    mv_taxbase   = iv_taxbase.
    mv_totaltax  = iv_totaltax.
    mv_total     = iv_total.
    mt_items[]   = CORRESPONDING #( it_item[] ).
*    mt_items[] = CORRESPONDING #( it_komp[] MAPPING kunnr = kunnr ).  "En caso de que los nombres de los campos de la tabla no sean iguales, se usa la función MAPPING para mapear los campos

    me->get_customer_data( iv_kunnr = iv_kunnr iv_shipto = iv_shipto ).

    me->get_user_data( iv_uname = iv_uname ).

    me->create_pdf(  ).

    me->send_mail(  ).

  ENDMETHOD.
ENDCLASS.
