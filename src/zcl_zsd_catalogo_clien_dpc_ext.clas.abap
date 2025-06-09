class ZCL_ZSD_CATALOGO_CLIEN_DPC_EXT definition
  public
  inheriting from ZCL_ZSD_CATALOGO_CLIEN_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_EXPANDED_ENTITY
    redefinition .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ZSD_CATALOGO_CLIEN_DPC_EXT IMPLEMENTATION.


  METHOD /iwbep/if_mgw_appl_srv_runtime~get_expanded_entity.
    DATA: wa_de_agente    TYPE zcl_zsd_catalogo_clien_mpc_ext=>ts_de_agente,
          wa_de_clientes  TYPE zcl_zsd_catalogo_clien_mpc_ext=>ts_de_clientes,
          wa_de_comercial TYPE zcl_zsd_catalogo_clien_mpc_ext=>ts_de_comercial,
          wa_interlocutor TYPE zcl_zsd_catalogo_clien_mpc_ext=>ts_interlocutores,
          wa_sociedad     TYPE zcl_zsd_catalogo_clien_mpc_ext=>ts_sociedad.

    "Declaración de objetos.
    DATA: lo_msg          TYPE REF TO /iwbep/if_message_container,
          lo_tech_request TYPE REF TO /iwbep/cl_mgw_request..

    "Declaración de variables.
    DATA: lv_agente    TYPE vkgrp,
          lv_error_msg TYPE bapi_msg.

    "Instancia a objeto para contenedor de mensajes de error.
    CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
      RECEIVING
        ro_message_container = lo_msg.

    "Lectura de tabla de valores procedentes de la ejecución de la API. Aquí se recibe el valor desde la URL.
    READ TABLE it_key_tab INTO DATA(wa_keytab) INDEX 1.

    IF sy-subrc EQ 0.
      "Convertimos el valor recibido en el tipo de dato de la variable lv_agente y a partir de este valor se comienzan a hacer las consultas para el catálogo de clientes.
      lv_agente = |{ wa_keytab-value ALPHA = IN }|.

      IF iv_entity_name EQ 'Agente'.
        "Se valida si existe el agente en la BD de SAP.
        SELECT a~vkgrp, b~bezei FROM tvkgr AS a
          INNER JOIN tvgrt AS b ON b~vkgrp EQ a~vkgrp
          WHERE a~vkgrp EQ @lv_agente
          AND a~hide EQ ''
          AND b~spras EQ 'S'
          INTO TABLE @DATA(lt_agente).

        READ TABLE lt_agente ASSIGNING FIELD-SYMBOL(<fs_agente>) WITH KEY vkgrp = lv_agente.

        IF <fs_agente> IS ASSIGNED.
          "Select para determinar los clientes por agente a nivel área de ventas (datos comerciales).
          SELECT * FROM knvv
            WHERE vkgrp EQ @lv_agente
            AND loevm EQ ''
            AND aufsd EQ ''
            INTO TABLE @DATA(lt_knvv).

          SORT lt_knvv ASCENDING BY vkorg vtweg spart kunnr.

          "Select a tabla general de clientes.
          SELECT * FROM kna1
            FOR ALL ENTRIES IN @lt_knvv
            WHERE kunnr EQ @lt_knvv-kunnr
            AND aufsd EQ ''
            INTO TABLE @DATA(lt_kna1).

          SORT lt_kna1 ASCENDING BY kunnr.
          DELETE ADJACENT DUPLICATES FROM lt_kna1 COMPARING kunnr.

          "Select a tabla de datos de sociedad
          SELECT * FROM knb1
            FOR ALL ENTRIES IN @lt_kna1
            WHERE kunnr EQ @lt_kna1-kunnr
            AND loevm EQ ''
            INTO TABLE @DATA(lt_knb1).

          SORT lt_knb1 ASCENDING BY bukrs kunnr.

          "Select a tabla de interlocutores para trear a todos los destinatarios de mercancía.
          SELECT vp~kunnr, vp~vkorg, vp~vtweg, vp~spart, vp~parvw, vp~parza, vp~kunn2, a1~adrnr FROM knvp AS vp
            INNER JOIN kna1 AS a1 ON a1~kunnr EQ vp~kunn2
            FOR ALL ENTRIES IN @lt_knvv
            WHERE vp~kunnr EQ @lt_knvv-kunnr
            AND vp~vkorg EQ @lt_knvv-vkorg
            AND vp~vtweg EQ @lt_knvv-vtweg
            AND vp~spart EQ @lt_knvv-spart
            INTO TABLE @DATA(lt_knvp).

          "Select a tabla de RFC.
          SELECT * FROM dfkkbptaxnum
            FOR ALL ENTRIES IN @lt_knvp
            WHERE partner EQ @lt_knvp-kunn2
            AND taxtype EQ 'MX1'
            INTO TABLE @DATA(lt_taxnum).

          "Select a tabla de direcciones (solicitantes y destinatarios de mercancía).
          SELECT * FROM adrc
            FOR ALL ENTRIES IN @lt_knvp
            WHERE addrnumber EQ @lt_knvp-adrnr
            INTO TABLE @DATA(lt_adrc).

          "Select a tabla de correos.
          SELECT * FROM adr6
            FOR ALL ENTRIES IN @lt_knvp
            WHERE addrnumber EQ @lt_knvp-adrnr
            INTO TABLE @DATA(lt_adr6).

          "Select a tabla general de business partners.
          SELECT * FROM but000
            FOR ALL ENTRIES IN @lt_knvp
            WHERE partner EQ @lt_knvp-kunn2
            INTO TABLE @DATA(lt_but000).

          "Comienza armado del response.
          "***Datos de Agente***"
          wa_de_agente-noagente = <fs_agente>-vkgrp.
          wa_de_agente-nombre   = <fs_agente>-bezei.

          "***Datos de Clientes***"
          LOOP AT lt_kna1 ASSIGNING FIELD-SYMBOL(<fs_kna1>) WHERE ktokd NE 'ZENV'.
            wa_de_clientes-agente  = <fs_agente>-vkgrp.
            wa_de_clientes-cliente = <fs_kna1>-kunnr.
            CONCATENATE <fs_kna1>-name1 <fs_kna1>-name2 <fs_kna1>-name3 <fs_kna1>-name4 INTO wa_de_clientes-nombre SEPARATED BY space.
            CONDENSE wa_de_clientes-nombre.

            READ TABLE lt_adrc ASSIGNING FIELD-SYMBOL(<fs_adrc>) WITH KEY addrnumber = <fs_kna1>-adrnr.
            IF <fs_adrc> IS ASSIGNED.
              wa_de_clientes-calle          = <fs_adrc>-street.
              wa_de_clientes-numeroext      = <fs_adrc>-house_num1.
              wa_de_clientes-distrito       = <fs_adrc>-city2.
              wa_de_clientes-poblacion      = <fs_adrc>-city1.
              wa_de_clientes-codigopostal   = <fs_adrc>-post_code1.
              wa_de_clientes-zonatransporte = <fs_adrc>-transpzone.
              wa_de_clientes-telefeono      = <fs_adrc>-tel_number.

              SELECT SINGLE landx INTO @wa_de_clientes-pais
                FROM t005t
                WHERE spras EQ 'S'
                AND land1 EQ @<fs_adrc>-country.

              SELECT SINGLE bezei INTO @wa_de_clientes-region
                FROM t005u
                WHERE spras EQ 'S'
                AND land1 EQ @<fs_adrc>-country
                AND bland EQ @<fs_adrc>-region.

              UNASSIGN <fs_adrc>.
            ENDIF.

            READ TABLE lt_but000 ASSIGNING FIELD-SYMBOL(<fs_but000>) WITH KEY partner = <fs_kna1>-kunnr.

            IF <fs_but000> IS ASSIGNED.
              wa_de_clientes-clienteanterior = <fs_but000>-bpext.
              wa_de_clientes-negocio         = <fs_but000>-nickname.
              UNASSIGN: <fs_but000>.
            ENDIF.

            READ TABLE lt_taxnum ASSIGNING FIELD-SYMBOL(<fs_taxnum>) WITH KEY partner = <fs_kna1>-kunnr.

            IF <fs_taxnum> IS ASSIGNED.
              wa_de_clientes-rfc = <fs_taxnum>-taxnum.
              UNASSIGN: <fs_taxnum>.
            ENDIF.

            READ TABLE lt_adr6 ASSIGNING FIELD-SYMBOL(<fs_adr6>) WITH KEY addrnumber = <fs_kna1>-adrnr.

            IF <fs_adr6> IS ASSIGNED.
              wa_de_clientes-email = <fs_adr6>-smtp_addr.
              UNASSIGN: <fs_adr6>.
            ENDIF.

            SELECT SINGLE xpos, ypos INTO ( @DATA(lv_longitud), @DATA(lv_latitud) )
              FROM /sapapo/loc
              WHERE locno EQ @<fs_kna1>-kunnr.

            lv_longitud = round( val = lv_longitud dec = 6 ).
            lv_latitud = round( val = lv_latitud dec = 6 ).

            wa_de_clientes-longitud = lv_longitud.
            wa_de_clientes-latitud  = lv_latitud.

            DATA(lv_lenlon) = strlen( wa_de_clientes-longitud ).
            DATA(lv_lenlat) = strlen( wa_de_clientes-latitud ).

            DATA(lv_offsetlon) = lv_lenlon - 2.
            DATA(lv_offsetlat) = lv_lenlat - 2.

            DATA(lv_multlon) = wa_de_clientes-longitud+lv_offsetlon(2).
            DATA(lv_multlat) = wa_de_clientes-latitud+lv_offsetlon(2).

            CASE lv_multlat.
              WHEN '00'.
                wa_de_clientes-latitud = wa_de_clientes-latitud(12).
              WHEN '01'.
                wa_de_clientes-latitud = wa_de_clientes-latitud(12) * 10.
              WHEN '02'.
                wa_de_clientes-latitud = wa_de_clientes-latitud(12) * 100.
            ENDCASE.

            CASE lv_multlon.
              WHEN '00'.
                wa_de_clientes-longitud = wa_de_clientes-longitud(12).
              WHEN '01'.
                wa_de_clientes-longitud = wa_de_clientes-longitud(12) * 10.
              WHEN '02'.
                wa_de_clientes-longitud = wa_de_clientes-longitud(12) * 100.
            ENDCASE.

            SELECT SINGLE ext_value INTO wa_de_clientes-usocfdi
              FROM /aif/t_mvmapval
              WHERE vmapname EQ 'CFDI_USAGE'
              AND ns EQ '/EDOMX'
              AND int_value EQ <fs_kna1>-kunnr.

            SELECT SINGLE ext_value INTO wa_de_clientes-regimenfiscal
              FROM /aif/t_mvmapval
              WHERE vmapname EQ 'RECEIVER_TAX_REGIME'
              AND ns EQ '/EDOMX'
              AND int_value EQ <fs_kna1>-kunnr.

            CONDENSE: wa_de_clientes-longitud, wa_de_clientes-latitud, wa_de_clientes-usocfdi, wa_de_clientes-regimenfiscal.

            "***Datos Comerciales***"
            LOOP AT lt_knvv ASSIGNING FIELD-SYMBOL(<fs_knvv>) WHERE kunnr EQ <fs_kna1>-kunnr.
              wa_de_comercial-agente          = <fs_agente>-vkgrp.
              wa_de_comercial-cliente         = <fs_kna1>-kunnr.
              wa_de_comercial-orgventas       = <fs_knvv>-vkorg.
              wa_de_comercial-canal           = <fs_knvv>-vtweg.
              wa_de_comercial-sector          = <fs_knvv>-spart.
              wa_de_comercial-zonaventas      = <fs_knvv>-bzirk.
              wa_de_comercial-oficinaventas   = <fs_knvv>-vkbur.
              wa_de_comercial-moneda          = <fs_knvv>-waers.
              wa_de_comercial-prioentrega     = <fs_knvv>-lprio.
              wa_de_comercial-centrosumin     = <fs_knvv>-vwerk.
              wa_de_comercial-condexped       = <fs_knvv>-vsbed.
              wa_de_comercial-pod             = <fs_knvv>-podkz.
              wa_de_comercial-incoterms       = <fs_knvv>-inco1.
              wa_de_comercial-incolugar       = <fs_knvv>-inco2_l.
              wa_de_comercial-condpago        = <fs_knvv>-zterm.
              wa_de_comercial-grupoimputacion = <fs_knvv>-ktgrd.

              SELECT SINGLE taxkd INTO @wa_de_comercial-impuesto
                FROM knvi
                WHERE kunnr EQ @<fs_knvv>-kunnr
                AND aland EQ 'MX'
                AND tatyp EQ 'MWST'.

              "***Datos de Interlocutores***"
              LOOP AT lt_knvp ASSIGNING FIELD-SYMBOL(<fs_knvp>) WHERE kunnr EQ <fs_knvv>-kunnr AND vkorg EQ <fs_knvv>-vkorg AND vtweg EQ <fs_knvv>-vtweg AND spart EQ <fs_knvv>-spart AND parvw EQ 'WE'.
                wa_interlocutor-agente  = <fs_agente>-vkgrp.
                wa_interlocutor-cliente = <fs_knvp>-kunn2.

                READ TABLE lt_kna1 ASSIGNING FIELD-SYMBOL(<fs_kna1_we>) WITH KEY kunnr = <fs_knvp>-kunn2.

                IF <fs_kna1_we> IS ASSIGNED.
                  CONCATENATE <fs_kna1_we>-name1 <fs_kna1_we>-name2 <fs_kna1_we>-name3 <fs_kna1_we>-name4 INTO wa_interlocutor-nombre.
                  CONDENSE wa_interlocutor-nombre.
                  UNASSIGN <fs_kna1_we>.
                ENDIF.

                READ TABLE lt_but000 ASSIGNING <fs_but000> WITH KEY partner = <fs_knvp>-kunn2.

                IF <fs_but000> IS  ASSIGNED.
                  wa_interlocutor-negocio = <fs_but000>-nickname.
                  UNASSIGN <fs_but000>.
                ENDIF.

                READ TABLE lt_adrc ASSIGNING <fs_adrc> WITH KEY addrnumber = <fs_knvp>-adrnr.
                IF <fs_adrc> IS ASSIGNED.
                  wa_interlocutor-calle          = <fs_adrc>-street.
                  wa_interlocutor-numeroext      = <fs_adrc>-house_num1.
                  wa_interlocutor-distrito       = <fs_adrc>-city2.
                  wa_interlocutor-poblacion      = <fs_adrc>-city1.
                  wa_interlocutor-codigopostal   = <fs_adrc>-post_code1.
                  wa_interlocutor-zonatransporte = <fs_adrc>-transpzone.
                  wa_interlocutor-telefeono      = <fs_adrc>-tel_number.

                  SELECT SINGLE landx INTO @wa_interlocutor-pais
                    FROM t005t
                    WHERE spras EQ 'S'
                    AND land1 EQ @<fs_adrc>-country.

                  SELECT SINGLE bezei INTO @wa_interlocutor-region
                    FROM t005u
                    WHERE spras EQ 'S'
                    AND land1 EQ @<fs_adrc>-country
                    AND bland EQ @<fs_adrc>-region.

                  UNASSIGN <fs_adrc>.
                ENDIF.

                READ TABLE lt_taxnum ASSIGNING <fs_taxnum> WITH KEY partner = <fs_knvp>-kunn2.

                IF <fs_taxnum> IS ASSIGNED.
                  wa_interlocutor-rfc = <fs_taxnum>-taxnum.
                  UNASSIGN: <fs_taxnum>.
                ENDIF.

                READ TABLE lt_adr6 ASSIGNING <fs_adr6> WITH KEY addrnumber = <fs_knvp>-adrnr.

                IF <fs_adr6> IS ASSIGNED.
                  wa_interlocutor-email = <fs_adr6>-smtp_addr.
                  UNASSIGN: <fs_adr6>.
                ENDIF.

                SELECT SINGLE xpos, ypos INTO ( @DATA(lv_longitudwe), @DATA(lv_latitudwe) )
                  FROM /sapapo/loc
                  WHERE locno EQ @<fs_knvp>-kunn2.

                lv_longitudwe = round( val = lv_longitud dec = 6 ).
                lv_latitudwe = round( val = lv_latitud dec = 6 ).

                wa_interlocutor-longitud = lv_longitudwe.
                wa_interlocutor-latitud  = lv_latitudwe.

                DATA(lv_lenlonwe) = strlen( wa_interlocutor-longitud ).
                DATA(lv_lenlatwe) = strlen( wa_interlocutor-latitud ).

                DATA(lv_offsetlonwe) = lv_lenlonwe - 2.
                DATA(lv_offsetlatwe) = lv_lenlatwe - 2.

                DATA(lv_multlonwe) = wa_interlocutor-longitud+lv_offsetlonwe(2).
                DATA(lv_multlatwe) = wa_interlocutor-latitud+lv_offsetlonwe(2).

                CASE lv_multlatwe.
                  WHEN '00'.
                    wa_interlocutor-latitud = wa_interlocutor-latitud(12).
                  WHEN '01'.
                    wa_interlocutor-latitud = wa_interlocutor-latitud(12) * 10.
                  WHEN '02'.
                    wa_interlocutor-latitud = wa_interlocutor-latitud(12) * 100.
                ENDCASE.

                CASE lv_multlonwe.
                  WHEN '00'.
                    wa_interlocutor-longitud = wa_interlocutor-longitud(12).
                  WHEN '01'.
                    wa_interlocutor-longitud = wa_interlocutor-longitud(12) * 10.
                  WHEN '02'.
                    wa_interlocutor-longitud = wa_interlocutor-longitud(12) * 100.
                ENDCASE.

                CONDENSE: wa_interlocutor-longitud, wa_interlocutor-latitud.

                SELECT SINGLE FROM knb1
                  FIELDS altkn
                  WHERE kunnr = @<fs_knvp>-kunn2
                  AND bukrs = 'LACN'
                  INTO @wa_interlocutor-clienteanterior.

                APPEND wa_interlocutor TO wa_de_comercial-to_interlocutores.
                CLEAR wa_interlocutor.
              ENDLOOP.
              UNASSIGN <fs_knvp>.

              APPEND wa_de_comercial TO wa_de_clientes-to_comercial.
              CLEAR wa_de_comercial.
            ENDLOOP.
            UNASSIGN: <fs_knvv>.

            "***Datos de Sociedad***"
            LOOP AT lt_knb1 ASSIGNING FIELD-SYMBOL(<fs_knb1>) WHERE kunnr EQ <fs_kna1>-kunnr.
              wa_sociedad-agente          = <fs_agente>-vkgrp.
              wa_sociedad-cliente         = <fs_kna1>-kunnr.
              wa_sociedad-sociedadcte     = <fs_knb1>-bukrs.
              wa_sociedad-clienteanterior = <fs_knb1>-altkn.
              wa_sociedad-cuentaasoc      = <fs_knb1>-akont.
              wa_sociedad-viapago         = <fs_knb1>-zwels.

              APPEND wa_sociedad TO wa_de_clientes-to_sociedad.
              CLEAR wa_sociedad.
            ENDLOOP.
            UNASSIGN <fs_knb1>.

            APPEND wa_de_clientes TO wa_de_agente-to_clientes.
            CLEAR wa_de_clientes.
          ENDLOOP.
          UNASSIGN: <fs_agente>, <fs_kna1>.
        ELSE.
          CONCATENATE 'El agente' lv_agente 'no existe en la BD de SAP o está inactivo. Favor de reportar.' INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZSD_MSG'
              iv_msg_number = '002'
              iv_msg_text   = lv_error_msg.
          RETURN.
        ENDIF.
      ENDIF.
      "Se regresa la deep entity comprobante para dar salida en el response.
      CALL METHOD me->copy_data_to_ref
        EXPORTING
          is_data = wa_de_agente
        CHANGING
          cr_data = er_entity.

      "Asignación de propiedades de navegación
      lo_tech_request ?= io_tech_request_context.
      DATA(lv_expand) = lo_tech_request->/iwbep/if_mgw_req_entityset~get_expand( ).
      TRANSLATE lv_expand TO UPPER CASE.
      SPLIT lv_expand AT ',' INTO TABLE et_expanded_tech_clauses.
    ELSE.
      lv_error_msg = 'Por favor captura un número de agente'.
      CALL METHOD lo_msg->add_message
        EXPORTING
          iv_msg_type   = /iwbep/cl_cos_logger=>error
          iv_msg_id     = 'ZSD_MSG'
          iv_msg_number = '001'
          iv_msg_text   = lv_error_msg.
      RETURN.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
