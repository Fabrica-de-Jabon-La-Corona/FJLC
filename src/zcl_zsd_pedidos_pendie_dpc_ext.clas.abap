class ZCL_ZSD_PEDIDOS_PENDIE_DPC_EXT definition
  public
  inheriting from ZCL_ZSD_PEDIDOS_PENDIE_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_EXPANDED_ENTITY
    redefinition .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ZSD_PEDIDOS_PENDIE_DPC_EXT IMPLEMENTATION.


  METHOD /iwbep/if_mgw_appl_srv_runtime~get_expanded_entity.
    DATA: ls_de_agente   TYPE zcl_zsd_pedidos_pendie_mpc_ext=>ts_de_agente,
          ls_de_cabecera TYPE zcl_zsd_pedidos_pendie_mpc_ext=>ts_de_cabecera,
          ls_posicion    TYPE zcl_zsd_pedidos_pendie_mpc_ext=>ts_posicion,
          ls_relacion    TYPE zcl_zsd_pedidos_pendie_mpc_ext=>ts_doctorelacion.

    DATA: lo_tech_request TYPE REF TO /iwbep/cl_mgw_request.

    DATA: lo_msg  TYPE REF TO /iwbep/if_message_container,
          lo_msg1 TYPE REF TO /bobf/if_frw_message.

    DATA: lv_agente    TYPE vkgrp,
          lv_pedido    TYPE vbeln,
          lt_lines     TYPE TABLE OF tline,
          lv_name      TYPE thead-tdname,
          lv_error_msg TYPE bapi_msg.

*Instancia a objeto para contenedor de mensajes de error.
    CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
      RECEIVING
        ro_message_container = lo_msg.

*Lectura de tabla de valores procedentes de la ejecución de la API. Aquí se recibe el valor desde la URL.
    READ TABLE it_key_tab ASSIGNING FIELD-SYMBOL(<fs_keytab>) WITH KEY name = 'NoAgente'.

    IF <fs_keytab> IS ASSIGNED.

      lv_agente = |{ <fs_keytab>-value ALPHA = IN }|.

      IF lv_agente NE ''.
        SELECT * FROM tvgrt
          WHERE spras EQ 'S'
          AND vkgrp EQ @lv_agente
          INTO TABLE @DATA(lt_tvgrt).

        IF lt_tvgrt[] IS INITIAL.
          CONCATENATE 'El agente' lv_agente 'no existe en SAP, favor de validar.' INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZSD_MSG'
              iv_msg_number = '001'
              iv_msg_text   = lv_error_msg.
          RETURN.
        ENDIF.

*Selección de datos
        "Validamos si se quiere consultar un pedido en específico o todos los pedidos del agente.
        READ TABLE it_key_tab ASSIGNING FIELD-SYMBOL(<fs_keytabpedido>) WITH KEY name = 'Pedido'.

        IF <fs_keytabpedido> IS ASSIGNED.
          lv_pedido = |{ <fs_keytabpedido>-value ALPHA = IN }|.
          UNASSIGN: <fs_keytabpedido>.
        ENDIF.

        IF lv_pedido EQ ''.  "Se seleccionan todos los pedidos del agente.
          SELECT * FROM vbak
            WHERE vbtyp EQ 'C'
            AND vkgrp EQ @lv_agente
            AND gbstk NE 'C'
            INTO TABLE @DATA(lt_vbak).
        ELSE.                "Se selecciona solamente el pedido indicado por el agente.
          SELECT * FROM vbak
            WHERE vbtyp EQ 'C'
            AND vkgrp EQ @lv_agente
            AND gbstk NE 'C'
            AND vbeln EQ @lv_pedido
            INTO TABLE @lt_vbak.
        ENDIF.

        IF lt_vbak[] IS NOT INITIAL.
          SORT lt_vbak ASCENDING BY vbeln.

          SELECT a~vbelv, a~vbtyp_v, a~vbeln, a~vbtyp_n, a~erdat, c~uuid FROM vbfa AS a
            INNER JOIN vbrk AS b ON b~vbeln EQ a~vbeln
            INNER JOIN zsd_cfdi_return AS c ON c~nodocu EQ b~vbeln
            FOR ALL ENTRIES IN @lt_vbak
            WHERE a~vbelv EQ @lt_vbak-vbeln
            AND a~vbtyp_n EQ 'M'
            AND b~fksto EQ ''
            INTO TABLE @DATA(lt_vbfam).

          SORT lt_vbfam ASCENDING BY vbelv vbeln.
          DELETE ADJACENT DUPLICATES FROM lt_vbfam COMPARING vbelv vbeln.

          SELECT * FROM vbfa
            FOR ALL ENTRIES IN @lt_vbak
            WHERE vbelv EQ @lt_vbak-vbeln
            AND vbtyp_n EQ 'J'
            INTO TABLE @DATA(lt_vbfae).

          IF lt_vbfam[] IS NOT INITIAL.
            SELECT * FROM dd07t
              WHERE domname EQ 'VBTYPL'
              AND ddlanguage EQ 'S'
              INTO TABLE @DATA(lt_dd07t).
          ENDIF.

          SELECT * FROM tvv1t
            FOR ALL ENTRIES IN @lt_vbak
            WHERE spras EQ 'S'
            AND kvgr1 EQ @lt_vbak-kvgr1
            INTO TABLE @DATA(lt_tvv1t).

          SELECT * FROM vbpa
            FOR ALL ENTRIES IN @lt_vbak
            WHERE vbeln EQ @lt_vbak-vbeln
            INTO TABLE @DATA(lt_vbpa).

          IF lt_vbpa[] IS NOT INITIAL.
            SORT lt_vbpa ASCENDING BY vbeln parvw kunnr.

            SELECT * FROM kna1
              FOR ALL ENTRIES IN @lt_vbpa
              WHERE kunnr EQ @lt_vbpa-kunnr
              INTO TABLE @DATA(lt_kna1).
          ENDIF.

          SELECT * FROM vbkd
            FOR ALL ENTRIES IN @lt_vbak
            WHERE vbeln EQ @lt_vbak-vbeln
            INTO TABLE @DATA(lt_vbkd).

          SORT  lt_vbkd ASCENDING BY vbeln.

          SELECT * FROM vbap
            FOR ALL ENTRIES IN @lt_vbak
            WHERE vbeln EQ @lt_vbak-vbeln
            AND gbsta NE 'C'
            AND abgru EQ ''
            INTO TABLE @DATA(lt_vbap).

          IF lt_vbap[] IS NOT INITIAL.
            SORT lt_vbap ASCENDING BY vbeln posnr.

            SELECT * FROM vbep
              FOR ALL ENTRIES IN @lt_vbap
              WHERE vbeln EQ @lt_vbap-vbeln
              AND posnr EQ @lt_vbap-posnr
              INTO TABLE @DATA(lt_vbep).

            SORT lt_vbep ASCENDING BY vbeln posnr etenr.
          ENDIF.
        ELSE.
          CONCATENATE 'El agente' lv_agente 'no tiene pedido pendientes.' INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZSD_MSG'
              iv_msg_number = '002'
              iv_msg_text   = lv_error_msg.
          RETURN.
        ENDIF.

*Armado de response.

        READ TABLE lt_tvgrt ASSIGNING FIELD-SYMBOL(<fs_tvgrt>) WITH KEY spras = 'S' vkgrp = lv_agente.

        IF <fs_tvgrt> IS ASSIGNED.
          ls_de_agente-noagente = <fs_tvgrt>-vkgrp.
          ls_de_agente-nombre   = <fs_tvgrt>-bezei.
          UNASSIGN: <fs_tvgrt>.
        ENDIF.

        "Cabecera del pedido
        LOOP AT lt_vbak ASSIGNING FIELD-SYMBOL(<fs_vbak>).
          ls_de_cabecera-agente           = <fs_vbak>-vkgrp.
          ls_de_cabecera-pedido           = |{ <fs_vbak>-vbeln ALPHA = OUT }|.
          ls_de_cabecera-solicitante      = |{ <fs_vbak>-kunnr ALPHA = OUT }|.
          ls_de_cabecera-fechaprefentrega = <fs_vbak>-vdatu.
          ls_de_cabecera-fechacreapedido  = <fs_vbak>-audat.
          ls_de_cabecera-cadena           = <fs_vbak>-kvgr1.

          READ TABLE lt_tvv1t ASSIGNING FIELD-SYMBOL(<fs_tvv1t>) WITH KEY spras = 'S' kvgr1 = <fs_vbak>-kvgr1.

          IF <fs_tvv1t> IS ASSIGNED.
            ls_de_cabecera-nombrecadena = <fs_tvv1t>-bezei.
            CONDENSE: ls_de_cabecera-nombrecadena.
            UNASSIGN: <fs_tvv1t>.
          ENDIF.

          READ TABLE lt_kna1 ASSIGNING FIELD-SYMBOL(<fs_kna1>) WITH KEY kunnr = <fs_vbak>-kunnr.

          IF <fs_kna1> IS ASSIGNED.

            CONCATENATE <fs_kna1>-name1 <fs_kna1>-name2 <fs_kna1>-name3 <fs_kna1>-name4 INTO ls_de_cabecera-nombresolicit SEPARATED BY space.
            CONDENSE ls_de_cabecera-nombresolicit.

            UNASSIGN: <fs_kna1>.
          ENDIF.

          READ TABLE lt_vbpa ASSIGNING FIELD-SYMBOL(<fs_vbpa>) WITH KEY parvw = 'WE' vbeln = <fs_vbak>-vbeln.

          IF <fs_vbpa> IS ASSIGNED.
            ls_de_cabecera-destinatario = |{ <fs_vbpa>-kunnr ALPHA = OUT }|.

            READ TABLE lt_kna1 ASSIGNING <fs_kna1> WITH KEY kunnr = <fs_vbpa>-kunnr.

            IF <fs_kna1> IS ASSIGNED.

              CONCATENATE <fs_kna1>-name1 <fs_kna1>-name2 <fs_kna1>-name3 <fs_kna1>-name4 INTO ls_de_cabecera-nombredesti SEPARATED BY space.
              CONDENSE ls_de_cabecera-nombredesti.

              UNASSIGN: <fs_kna1>.
            ENDIF.

            UNASSIGN: <fs_vbpa>.
          ENDIF.

          READ TABLE lt_vbkd ASSIGNING FIELD-SYMBOL(<fs_vbkd>) WITH KEY vbeln = <fs_vbak>-vbeln.

          IF <fs_vbkd> IS ASSIGNED.
            ls_de_cabecera-pedidocliente   = <fs_vbkd>-bstkd.
            ls_de_cabecera-fechapedcliente = <fs_vbkd>-bstdk.

            UNASSIGN: <fs_vbkd>.
          ENDIF.

          lv_name = <fs_vbak>-vbeln.

          CALL FUNCTION 'READ_TEXT'
            EXPORTING
              id                      = 'ZINS'          " ID del texto a leer
              language                = 'S'             " Idioma del texto a leer
              name                    = lv_name         " Nombre del texto a leer
              object                  = 'VBBK'          " Objeto del texto a leer
            TABLES
              lines                   = lt_lines        " Líneas del texto leído
            EXCEPTIONS
              id                      = 1 " ID de texto no válida
              language                = 2 " Idioma no válido
              name                    = 3 " Nombre de texto no válido
              not_found               = 4 " El texto no existe.
              object                  = 5 " Objeto de texto no válido
              reference_check         = 6 " Cadena de referencia interrumpida
              wrong_access_to_archive = 7 " Archive handle no permitido para el acceso
              OTHERS                  = 8.

          LOOP AT lt_lines ASSIGNING FIELD-SYMBOL(<fs_lines>).
            CONCATENATE ls_de_cabecera-observaciones <fs_lines>-tdline INTO ls_de_cabecera-observaciones SEPARATED BY space.
            CONDENSE ls_de_cabecera-observaciones.
            CLEAR <fs_lines>.
          ENDLOOP.
          UNASSIGN: <fs_lines>.

          "Posiciones del pedido
          LOOP AT lt_vbap ASSIGNING FIELD-SYMBOL(<fs_vbap>) WHERE vbeln EQ <fs_vbak>-vbeln.
            ls_posicion-agente         = |{ <fs_vbak>-vkgrp ALPHA = OUT }|.
            ls_posicion-pedido         = |{ <fs_vbap>-vbeln ALPHA = OUT }|.
            ls_posicion-posicion       = |{ <fs_vbap>-posnr ALPHA = OUT }|.
            ls_posicion-material       = |{ <fs_vbap>-matnr ALPHA = OUT }|.
            ls_posicion-descripcion    = <fs_vbap>-arktx.
            ls_posicion-cantidadpedido = <fs_vbap>-kwmeng.
            ls_posicion-umv            = <fs_vbap>-vrkme.
            ls_posicion-centro         = <fs_vbap>-werks.
            ls_posicion-almacen        = <fs_vbap>-lgort.

            READ TABLE lt_vbep ASSIGNING FIELD-SYMBOL(<fs_vbep>) WITH KEY vbeln = <fs_vbap>-vbeln posnr = <fs_vbap>-posnr etenr = '0001'.

            IF <fs_vbep> IS ASSIGNED.
              ls_posicion-cantidadpendiente = <fs_vbep>-ordqty_su.
              ls_posicion-umvpend           = <fs_vbep>-vrkme.
              UNASSIGN: <fs_vbep>.
            ENDIF.

            ls_posicion-cantidadfacturada = ls_posicion-cantidadpedido - ls_posicion-cantidadpendiente.
            ls_posicion-umvfact           = <fs_vbap>-vrkme.

            CONDENSE: ls_posicion-cantidadpedido, ls_posicion-cantidadpendiente, ls_posicion-cantidadfacturada.

            APPEND ls_posicion TO ls_de_cabecera-to_posicion.
            CLEAR: ls_posicion, <fs_vbap>.
          ENDLOOP.
          UNASSIGN: <fs_vbap>.

          "Documentos relacionados.
          "Facturas.
          LOOP AT lt_vbfam ASSIGNING FIELD-SYMBOL(<fs_vbfam>) WHERE vbelv EQ <fs_vbak>-vbeln.
            ls_relacion-agente        = |{ <fs_vbak>-vkgrp ALPHA = OUT }|.
            ls_relacion-pedido        = |{ <fs_vbak>-vbeln ALPHA = OUT }|.
            ls_relacion-documentorel  = <fs_vbfam>-vbeln.
            ls_relacion-tipodocumento = <fs_vbfam>-vbtyp_n.
            ls_relacion-uuid          = <fs_vbfam>-uuid.

            READ TABLE lt_dd07t ASSIGNING FIELD-SYMBOL(<fs_ddo7t>) WITH KEY domvalue_l = <fs_vbfam>-vbtyp_n.

            IF <fs_ddo7t> IS ASSIGNED.
              ls_relacion-descripcion = <fs_ddo7t>-ddtext.
              UNASSIGN: <fs_ddo7t>.
            ENDIF.

            APPEND ls_relacion TO ls_de_cabecera-to_doctorelacion.
            CLEAR: ls_relacion, <fs_vbfam>.
          ENDLOOP.
          UNASSIGN: <fs_vbfam>.

          "Documentos de Transporte (viajes).

          APPEND ls_de_cabecera TO ls_de_agente-to_cabecera.
          CLEAR: ls_de_cabecera, <fs_vbak>.
        ENDLOOP.
        UNASSIGN: <fs_vbak>.

*Se regresa la deep entity comprobante para dar salida en el response.
        CALL METHOD me->copy_data_to_ref
          EXPORTING
            is_data = ls_de_agente
          CHANGING
            cr_data = er_entity.

        CLEAR: ls_de_cabecera, ls_de_agente.

*Asignación de propiedades de navegación
        lo_tech_request ?= io_tech_request_context.
        DATA(lv_expand) = lo_tech_request->/iwbep/if_mgw_req_entityset~get_expand( ).
        TRANSLATE lv_expand TO UPPER CASE.
        SPLIT lv_expand AT ',' INTO TABLE et_expanded_tech_clauses.

      ENDIF.

      UNASSIGN: <fs_keytab>.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
