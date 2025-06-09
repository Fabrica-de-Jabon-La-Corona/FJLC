class ZCL_ZTM_CARTAPORTE_DPC_EXT definition
  public
  inheriting from ZCL_ZTM_CARTAPORTE_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_EXPANDED_ENTITY
    redefinition .
protected section.

  methods CCPTIMBREFISCALS_CREATE_ENTITY
    redefinition .
  methods CCPTIMBREFISCALS_UPDATE_ENTITY
    redefinition .
  methods CCPMONITORSET_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZTM_CARTAPORTE_DPC_EXT IMPLEMENTATION.


  METHOD /iwbep/if_mgw_appl_srv_runtime~get_expanded_entity.
*Declaración de tablas y estructuras internas para los entity SET
    DATA: it_de_comprobante         TYPE TABLE OF zcl_ztm_cartaporte_mpc=>ts_de_comprobante,
          wa_de_comprobante         TYPE zcl_ztm_cartaporte_mpc_ext=>ts_de_comprobante,
          wa_emisor_data            TYPE zcl_ztm_cartaporte_mpc_ext=>ts_ccpemisor,
          wa_receptor_data          TYPE zcl_ztm_cartaporte_mpc_ext=>ts_ccpreceptor,
          wa_conceptos_data         TYPE zcl_ztm_cartaporte_mpc_ext=>ts_ccpconceptos,
          wa_complemento_data       TYPE zcl_ztm_cartaporte_mpc_ext=>ts_de_complemento,
          wa_ubicaciones_data       TYPE zcl_ztm_cartaporte_mpc_ext=>ts_de_ubicaciones,
          wa_mercancias_data        TYPE zcl_ztm_cartaporte_mpc_ext=>ts_de_mercancias,
          wa_figuratran_data        TYPE zcl_ztm_cartaporte_mpc_ext=>ts_ccpfiguratransporte,
          wa_domicilio_data         TYPE zcl_ztm_cartaporte_mpc_ext=>ts_ccpdomicilio,
          wa_mercancia_data         TYPE zcl_ztm_cartaporte_mpc_ext=>ts_de_mercancia,
          wa_cantidadtran_data      TYPE zcl_ztm_cartaporte_mpc_ext=>ts_ccpcantidadtransporta,
          wa_autotransporte_data    TYPE zcl_ztm_cartaporte_mpc_ext=>ts_de_autotransporte,
          wa_identificaveh_data     TYPE zcl_ztm_cartaporte_mpc_ext=>ts_ccpidentificacionvehicular,
          wa_seguros_data           TYPE zcl_ztm_cartaporte_mpc_ext=>ts_ccpseguros,
          wa_remolques_data         TYPE zcl_ztm_cartaporte_mpc_ext=>ts_ccpremolques,
          wa_de_addendacab_data     TYPE zcl_ztm_cartaporte_mpc_ext=>ts_de_addendacab,
          wa_addendadet_data        TYPE zcl_ztm_cartaporte_mpc_ext=>ts_ccpaddendadet,
          wa_de_contremolques_data  TYPE zcl_ztm_cartaporte_mpc_ext=>ts_de_contremolques,
          wa_remolquedet_data       TYPE zcl_ztm_cartaporte_mpc_ext=>ts_remolquedet,
          wa_de_contcontenedor_data TYPE zcl_ztm_cartaporte_mpc_ext=>ts_de_contcontenedor,
          wa_contenedordet_data     TYPE zcl_ztm_cartaporte_mpc_ext=>ts_remolquedet,
          wa_interlocutor_data      TYPE zcl_ztm_cartaporte_mpc_ext=>ts_ccpaddendainterlo,
          wa_etapas_data            TYPE zcl_ztm_cartaporte_mpc_ext=>ts_ccpaddendaetapas,
          wa_conductor_data         TYPE zcl_ztm_cartaporte_mpc_ext=>ts_ccpaddendaconductor,
          wa_textos_data            TYPE zcl_ztm_cartaporte_mpc_ext=>ts_ccpaddendatextos.

*Declaración de tablas y estructuras internas para vaciar info de tablas estándar
    DATA: lt_torrot     TYPE STANDARD TABLE OF /scmtms/d_torrot,
          ls_torrot     TYPE /scmtms/d_torrot,
          lt_torite     TYPE STANDARD TABLE OF /scmtms/d_torite,
          ls_torite     TYPE /scmtms/d_torite,
          lt_torite_det TYPE STANDARD TABLE OF /scmtms/d_torite,
          ls_torite_det TYPE /scmtms/d_torite,
          lt_torite_rmq TYPE STANDARD TABLE OF /scmtms/d_torite,
          ls_torite_rmq TYPE /scmtms/d_torite,
          lt_torite_dri TYPE STANDARD TABLE OF /scmtms/d_torite,
          ls_torite_dri TYPE /scmtms/d_torite,
          lt_torstp     TYPE STANDARD TABLE OF /scmtms/d_torstp,
          ls_torstp     TYPE /scmtms/d_torstp,
          lt_torsts     TYPE STANDARD TABLE OF /scmtms/d_torsts,
          ls_torsts     TYPE /scmtms/d_torsts,
          lt_torpty     TYPE STANDARD TABLE OF /scmtms/d_torpty,
          ls_torpty     TYPE /scmtms/d_torpty,
          lt_apoloc     TYPE STANDARD TABLE OF /sapapo/loc,
          ls_apoloc     TYPE /sapapo/loc,
          lt_torexe     TYPE STANDARD TABLE OF /scmtms/d_torexe,
          ls_torexe     TYPE /scmtms/d_torexe,
          lt_adrc       TYPE STANDARD TABLE OF adrc,
          ls_adrc       TYPE adrc,
          lt_likp       TYPE STANDARD TABLE OF likp,
          ls_likp       TYPE likp,
          lt_lips1      TYPE STANDARD TABLE OF lips,
          ls_lips1      TYPE lips,
          lt_procode    TYPE STANDARD TABLE OF /aif/t_mvmapval,
          ls_procode    TYPE /aif/t_mvmapval,
          lt_ccpbien    TYPE STANDARD TABLE OF zsd_ccpbienestra,
          ls_ccpbien    TYPE zsd_ccpbienestra,
          lt_root_key   TYPE /bobf/t_frw_key,
          ls_key        TYPE /bobf/s_frw_key,
          lt_stage      TYPE /scmtms/t_pln_stage.

*Declaración de variables
    DATA: lv_torid             TYPE /scmtms/d_torrot-tor_id,
          lv_entrega           TYPE likp-vbeln,
          lv_error_msg         TYPE bapi_msg,
          lv_folio             TYPE c LENGTH 10,
          lv_descr             TYPE c LENGTH 50,
          lv_rfctrans          TYPE stcd1,
          lv_nombretra         TYPE c LENGTH 80,
          lv_regfistra         TYPE c LENGTH 3,
          lv_tiporeparto       TYPE c LENGTH 30,
          lv_date              TYPE d,
          lv_numtotmer         TYPE i,
          lv_trexterno         TYPE c LENGTH 1,
          lv_tortype           TYPE /scmtms/d_torrot-tor_type,
          lv_pesobruto         TYPE /scmtms/d_torite-gro_wei_val,
          lv_sumadistrecorrida TYPE /scmtms/total_distance_km,
          lo_msg               TYPE REF TO /iwbep/if_message_container,
          lo_msg1              TYPE REF TO /bobf/if_frw_message,
          lv_entexp            TYPE c LENGTH 1,
          lv_longitudori       TYPE c LENGTH 20,
          lv_latitudori        TYPE c LENGTH 20,
          lv_longituddes       TYPE c LENGTH 20,
          lv_latituddes        TYPE c LENGTH 20,
          lv_distancia         TYPE string.

*Declaración de constantes
    CONSTANTS: abap_true   TYPE c LENGTH 1  VALUE 'X',
               abap_false  TYPE c LENGTH 1  VALUE '',
               lc_comma    TYPE c LENGTH 1  VALUE ',',
               lc_programa TYPE c LENGTH 14 VALUE 'ZTM_CARTAPORTE'.

    DATA: lo_tech_request TYPE REF TO /iwbep/cl_mgw_request.

*Declaración de estructura interna.
    TYPES:
      BEGIN OF ts_procode1,
        ext_value TYPE /aif/t_mvmapval-ext_value,
      END OF ts_procode1.
    TYPES:
    tt_procode1 TYPE STANDARD TABLE OF ts_procode1.

    DATA: ls_procode1 TYPE ts_procode1,
          lt_procode1 TYPE tt_procode1.

    TYPES:
      BEGIN OF ts_procode2,
        cantidad  TYPE /scmtms/d_torite-qua_pcs_val,
        bienestra TYPE /aif/t_mvmapval-ext_value,
        claveuni  TYPE /scmtms/d_torite-qua_pcs_uni,
        pesoenkg  TYPE /scmtms/d_torite-gro_wei_val,
        decrip    TYPE zsd_ccpbienestra-descripcion,
      END OF ts_procode2.
    TYPES:
    tt_procode2 TYPE STANDARD TABLE OF ts_procode2.

    DATA: ls_procode2 TYPE ts_procode2,
          lt_procode2 TYPE tt_procode2,
          ls_procode3 TYPE ts_procode2,
          lt_procode3 TYPE tt_procode2.

    TYPES:
      BEGIN OF ts_cantitrans,
        cantidad  TYPE /scmtms/d_torite-qua_pcs_val,
        peso      TYPE /scmtms/d_torite-net_wei_val,
        bienestra TYPE /aif/t_mvmapval-ext_value,
        origen    TYPE /scmtms/d_torite-src_loc_idtrq,
        destino   TYPE /scmtms/d_torite-des_loc_idtrq,
      END OF ts_cantitrans.
    TYPES:
    tt_cantitrans TYPE STANDARD TABLE OF ts_cantitrans.

    DATA: ls_cantitrans TYPE ts_cantitrans,
          lt_cantitrans TYPE tt_cantitrans.

    TYPES:
      BEGIN OF ts_lips,
        matnr TYPE lips-matnr,
        lfimg TYPE lips-lfimg,
        arktx TYPE lips-arktx,
        vrkme TYPE lips-vrkme,
        prodh TYPE lips-prodh,
      END OF ts_lips.
    TYPES:
    tt_lips TYPE STANDARD TABLE OF ts_lips.

    DATA: ls_lips TYPE ts_lips,
          lt_lips TYPE tt_lips.

    TYPES:
      BEGIN OF ts_entregas,
        vbeln TYPE likp-vbeln,
        lfart TYPE likp-lfart,
      END OF ts_entregas.
    TYPES:
      tt_entregas TYPE STANDARD TABLE OF ts_entregas.

    DATA: lt_entregas TYPE tt_entregas,
          ls_entregas TYPE ts_entregas.

    TYPES:
      BEGIN OF ts_entregas_rem,
        vbeln  TYPE likp-vbeln,
        posnr  TYPE lips-posnr,
        matnr  TYPE lips-matnr,
        parent TYPE /scmtms/d_torite-item_parent_key,
        baseky TYPE /scmtms/d_torite-base_btd_key,
      END OF ts_entregas_rem.
    TYPES:
      tt_entregas_rem TYPE STANDARD TABLE OF ts_entregas_rem.

    DATA: lt_entregas_rem TYPE tt_entregas_rem,
          ls_entregas_rem TYPE ts_entregas_rem.

*Instancia a objeto de clase para consumo de servicios de maps.
    DATA: lo_heremaps TYPE REF TO zcl_tm_heremaps.
    CREATE OBJECT lo_heremaps.

*Instancia a objeto para contenedor de mensajes de error.
    CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
      RECEIVING
        ro_message_container = lo_msg.

*Lectura de tabla de valores procedentes de la ejecución de la API. Aquí se recibe el valor desde la URL.
    READ TABLE it_key_tab INTO DATA(wa_keytab) INDEX 1.

    IF sy-subrc EQ 0.
*Convertimos el valor recibido en el tipo de dato de la variable lv_torid y a partir de este valor se comienzan a hacer las consultas para la orden de flete.
      lv_torid = |{ wa_keytab-value ALPHA = IN }|.

      IF iv_entity_name EQ 'ccpComprobante'.

*Se comienza llenado de tablas y estructuras internas desde tablas estándar.
        SELECT * FROM  /scmtms/d_torrot
          INTO TABLE lt_torrot
          WHERE tor_id = lv_torid.

        IF sy-subrc EQ 0.
          LOOP AT lt_torrot INTO ls_torrot.
            IF ls_torrot-tor_id NE ''.
              SELECT * FROM /scmtms/d_torite
                INTO TABLE lt_torite
                WHERE parent_key = ls_torrot-db_key.

              SELECT * FROM /scmtms/d_torite
                INTO TABLE lt_torite_det
                WHERE parent_key = ls_torrot-db_key.

              SELECT * FROM /scmtms/d_torite
                INTO TABLE lt_torite_rmq
                WHERE parent_key = ls_torrot-db_key.

              SELECT * FROM /scmtms/d_torite
                INTO TABLE lt_torite_dri
                WHERE parent_key = ls_torrot-db_key
                AND item_cat EQ 'DRI'.

              SELECT * FROM /scmtms/d_torexe
                INTO TABLE lt_torexe
                WHERE parent_key = ls_torrot-db_key.

              SELECT * FROM /scmtms/d_torpty
                INTO TABLE lt_torpty
                WHERE parent_key = ls_torrot-db_key.

              ls_key-key = ls_torrot-db_key.
              APPEND ls_key TO lt_root_key.

              "Get TOR stages
              /scmtms/cl_gw_helper=>get_tor_stages(
                EXPORTING
                  it_root_key = lt_root_key
                IMPORTING
                  et_stage    = lt_stage
                  eo_message  = lo_msg1 ).

              IF lt_torite[] IS NOT INITIAL.
                LOOP AT lt_torite INTO ls_torite WHERE base_btd_tco EQ '73' OR base_btd_tco EQ '58'.
                  lv_entrega = |{ ls_torite-base_btd_id ALPHA = IN }|.
                  SELECT * FROM likp
                    INTO ls_likp
                    WHERE vbeln = lv_entrega.
                  ENDSELECT.
                  IF sy-subrc EQ 0.
                    APPEND ls_likp TO lt_likp.
                  ENDIF.
                  CLEAR: lv_entrega.
                ENDLOOP.
                DELETE ADJACENT DUPLICATES FROM lt_likp.
                CLEAR ls_torite.
                IF lt_likp IS INITIAL.
                  READ TABLE lt_torite INTO ls_torite WITH KEY trq_cat = '03'.
                  IF sy-subrc EQ 0.  "Si no hay entregas en la orden de flete, valida que tenga ordenes de expedición, si no es así manda error.
                    DATA(lv_ordexped) = ls_torite-trq_id.
                  ELSE.
*Error: Aún no hay entregas asociadas a la orden de flete lv_torid.
                    CONCATENATE 'Aún no hay entregas asociadas a la orden de flete' lv_torid INTO lv_error_msg SEPARATED BY space.
                    CALL METHOD lo_msg->add_message
                      EXPORTING
                        iv_msg_type   = /iwbep/cl_cos_logger=>error
                        iv_msg_id     = 'ZTM_MSG'
                        iv_msg_number = '002'
                        iv_msg_text   = lv_error_msg.
                    RETURN.
                  ENDIF.
                ENDIF.
              ENDIF.

*Se almacena el detalle de entregas asociadas al flete.
              IF lt_likp IS NOT INITIAL.
                SELECT * FROM lips
                  FOR ALL ENTRIES IN @lt_likp
                  WHERE vbeln EQ @lt_likp-vbeln
                  INTO TABLE @lt_lips1.
              ENDIF.

              READ TABLE lt_likp ASSIGNING FIELD-SYMBOL(<fs_likp>) WITH KEY lfart = 'ZLFX'.

              IF <fs_likp> IS ASSIGNED.
                lv_entexp = 'X'.
              ELSE.
                READ TABLE lt_likp ASSIGNING <fs_likp> WITH KEY lfart = 'ZEL'.
                IF <fs_likp> IS ASSIGNED.
                  DATA(lv_ententr) = 'X'.
                ENDIF.
              ENDIF.

              IF lv_entexp EQ 'X'.
                SORT lt_lips1 ASCENDING BY vbeln prodh.
              ELSE.
                SORT lt_lips1 ASCENDING BY prodh matnr.
              ENDIF.

              IF lt_lips1 IS NOT INITIAL.
                CLEAR: ls_lips.
                LOOP AT lt_lips1 INTO ls_lips1.
                  ls_lips-matnr = ls_lips1-matnr.
                  ls_lips-lfimg = ls_lips1-lfimg.
                  ls_lips-arktx = ls_lips1-arktx.
                  ls_lips-vrkme = ls_lips1-vrkme.
                  ls_lips-prodh = ls_lips1-prodh.

                  IF line_exists( lt_lips[ matnr = ls_lips-matnr ] ).
                    CLEAR ls_lips-lfimg.
                    READ TABLE lt_lips INTO ls_lips WITH KEY matnr = ls_lips1-matnr.
                    DATA(idx) = sy-tabix.
                    ls_lips-lfimg = ls_lips-lfimg + ls_lips1-lfimg.
                    MODIFY lt_lips INDEX idx FROM ls_lips TRANSPORTING lfimg.
                    CLEAR: ls_lips.
                  ELSE.
                    APPEND ls_lips TO lt_lips.
                    CLEAR: ls_lips.
                  ENDIF.
                  CLEAR: ls_lips1.
                ENDLOOP.
              ENDIF.

              IF lv_entexp EQ 'X'.
                "SORT lt_lips ASCENDING BY matnr.
              ELSE.
                SORT lt_lips ASCENDING BY prodh matnr.
              ENDIF.

              SELECT * FROM /scmtms/d_torstp
                INTO TABLE lt_torstp
                WHERE parent_key = ls_torrot-db_key.

              IF sy-subrc EQ 0.
                LOOP AT lt_torstp INTO ls_torstp.

                  SELECT * FROM /sapapo/loc
                    INTO ls_apoloc
                    WHERE locno = ls_torstp-log_locid.
                  ENDSELECT.
                  IF sy-subrc EQ 0.
                    APPEND ls_apoloc TO lt_apoloc.
                  ENDIF.
                  SORT lt_apoloc ASCENDING BY loctype locno.

                  SELECT * FROM /scmtms/d_torsts
                    INTO ls_torsts
                    WHERE root_key = ls_torstp-parent_key
                    AND parent_key = ls_torstp-db_key.
                  ENDSELECT.
                  IF sy-subrc EQ 0.
                    APPEND ls_torsts TO lt_torsts.
                  ENDIF.
                  SORT lt_torsts ASCENDING BY successor_id.

                ENDLOOP.
                SORT lt_apoloc ASCENDING BY locno.
                DELETE ADJACENT DUPLICATES FROM lt_apoloc.

                CLEAR: ls_apoloc, ls_torstp, ls_torsts.

                IF NOT lt_apoloc IS INITIAL.
                  LOOP AT lt_apoloc INTO ls_apoloc.

                    SELECT * FROM adrc
                      INTO ls_adrc
                      WHERE addrnumber = ls_apoloc-adrnummer.
                    ENDSELECT.
                    IF sy-subrc EQ 0.
                      APPEND ls_adrc TO lt_adrc.
                    ENDIF.

                  ENDLOOP.
                  CLEAR: ls_adrc, ls_apoloc.
                ELSE.
                ENDIF.
              ENDIF.
*Valida estatus de ejecución de la orden de flete

              SELECT SINGLE valor1 INTO @DATA(lv_stat)
                FROM zparamglob
                WHERE programa EQ @lc_programa
                AND parametro EQ '4'.

              READ TABLE lt_torexe INTO ls_torexe WITH KEY parent_key = ls_torrot-db_key event_code = lv_stat.
*Validar que las entregas de la orden de flete ya tengan salida de mercancía.
              IF lt_likp IS NOT INITIAL.
                LOOP AT lt_likp INTO ls_likp.
                  IF ls_likp-wbstk NE 'C' AND ls_torexe IS NOT INITIAL.
*Error: entrega no contabilizada.
                    CONCATENATE 'La entrega' ls_likp-vbeln 'no tiene salida de mercancía aún.' INTO lv_error_msg SEPARATED BY space.
                    CALL METHOD lo_msg->add_message
                      EXPORTING
                        iv_msg_type   = /iwbep/cl_cos_logger=>error
                        iv_msg_id     = 'ZTM_MSG'
                        iv_msg_number = '003'
                        iv_msg_text   = lv_error_msg.
                    RETURN.
                  ELSEIF ls_likp-wbstk NE 'C' AND ls_torexe IS INITIAL.
                    CONTINUE.
                  ENDIF.
                ENDLOOP.
                CLEAR ls_likp.
              ENDIF.

              SELECT * FROM zsd_ccpbienestra
                INTO TABLE @lt_ccpbien.

*Comienza armado de estructuras del comprobante con complemento carta porte.
              LOOP AT lt_torrot INTO ls_torrot.

                lv_folio = ls_torrot-tor_id+10(10).
                lv_tortype = ls_torrot-tor_type.

                SELECT SINGLE valor1 INTO @DATA(lv_verscomprob)
                  FROM zparamglob
                  WHERE programa EQ @lc_programa
                  AND parametro EQ '3'
                  AND subparametro EQ '2'.

                READ TABLE lt_torite INTO ls_torite WITH KEY parent_key = ls_torrot-db_key item_cat = 'PRD'.

                IF lv_ententr NE 'X'.
                  SELECT SINGLE valor2 INTO @DATA(lv_serie)
                    FROM zparamglob
                    WHERE programa EQ @lc_programa
                    AND parametro EQ '5'
                    AND valor1 EQ @ls_torite-src_loc_idtrq.
                ELSE.
                  SELECT SINGLE valor2 INTO @lv_serie
                    FROM zparamglob
                    WHERE programa EQ @lc_programa
                    AND parametro EQ '5'
                    AND valor1 EQ @ls_torite-des_loc_idtrq.
                ENDIF.


                CLEAR: ls_torite.

                READ TABLE lt_torite INTO ls_torite WITH KEY parent_key = ls_torrot-db_key item_cat = 'AVR'.

                DATA(lv_multimodal) = ls_torite-tures_cat.
                DATA(lv_transfer) = ls_torite-inc_transf_loc_n.

                CLEAR ls_torite.

                wa_de_comprobante-version = lv_verscomprob.
                wa_de_comprobante-serie = lv_serie.
                wa_de_comprobante-folio = lv_folio.
                READ TABLE lt_torexe ASSIGNING FIELD-SYMBOL(<fs_torexe>) WITH KEY parent_key = ls_torrot-db_key event_code = 'CHECK_OUT'.
                IF <fs_torexe> IS ASSIGNED.
                  CONVERT TIME STAMP <fs_torexe>-actual_date TIME ZONE 'UTC-6' INTO DATE DATA(lv_date1) TIME DATA(lv_time1) DAYLIGHT SAVING TIME DATA(lv_dst).
                  CONCATENATE lv_date1(4) '-' lv_date1+4(2) '-' lv_date1+6(2) 'T' lv_time1(2) ':' lv_time1+2(2) ':' lv_time1+4(2) INTO DATA(lv_fechacomp).
                  wa_de_comprobante-fecha = lv_fechacomp.
                ENDIF.

                wa_de_comprobante-subtotal = 0.
                wa_de_comprobante-total = 0.
                wa_de_comprobante-notrans = ls_torrot-tor_id.
                wa_de_comprobante-moneda = 'XXX'.
                wa_de_comprobante-exportacion = '01'.
                wa_de_comprobante-lugarexpedicion = '55348'.
                wa_de_comprobante-tipodecomprobante = 'T'.

                "Se lee la tabla TORITE en busca de órdenes de expedición y se añaden los materiales en la tabla lt_lips
                LOOP AT lt_torite INTO ls_torite WHERE trq_cat EQ '03' AND orig_ref_bo = 'TRQ'.
                  ls_lips-matnr = ls_torite-product_id.
                  ls_lips-lfimg = ls_torite-qua_pcs_val.
                  ls_lips-arktx = ls_torite-item_descr.
                  ls_lips-vrkme = ls_torite-qua_pcs_uni.

                  IF line_exists( lt_lips[ matnr = ls_lips-matnr
                                           arktx = ls_lips-arktx ] ).
                    CLEAR ls_lips-lfimg.
                    READ TABLE lt_lips INTO ls_lips WITH KEY matnr = ls_torite-product_id.
                    DATA(idx1) = sy-tabix.
                    ls_lips-lfimg = ls_lips-lfimg + ls_torite-qua_pcs_val.
                    MODIFY lt_lips INDEX idx1 FROM ls_lips TRANSPORTING lfimg.
                    CLEAR: ls_lips.
                  ELSE.
                    APPEND ls_lips TO lt_lips.
                    CLEAR: ls_lips.
                  ENDIF.
                  CLEAR ls_torite.
                ENDLOOP.

                LOOP AT lt_torite INTO ls_torite WHERE item_type EQ 'TRUC' AND item_parent_key EQ '00000000000000000000000000000000'.

                  "CONCATENATE 'REPARTO DE VIAJE' lv_folio sy-datum+6(2) sy-datum+4(2) sy-datum(4) INTO lv_descr SEPARATED BY space.
*Se llena el nodo "Conceptos".
                  LOOP AT lt_lips INTO ls_lips.
                    wa_conceptos_data-notrans = ls_torrot-tor_id.
                    "wa_conceptos_data-cantidad = '1'.
                    wa_conceptos_data-cantidad = ls_lips-lfimg.
                    "wa_conceptos_data-unidad = 'Servicio'.

                    SELECT SINGLE msehl INTO wa_conceptos_data-unidad
                      FROM t006a
                      WHERE msehi EQ ls_lips-vrkme
                      AND spras EQ 'S'.

                    "wa_conceptos_data-noidentificacion = '99989'.
                    wa_conceptos_data-noidentificacion = |{ ls_lips-matnr ALPHA = OUT }|.
                    "wa_conceptos_data-descripcion = lv_descr.
                    "wa_conceptos_data-descripcion = ls_lips-arktx.

                    SELECT SINGLE maktx INTO @wa_conceptos_data-descripcion
                      FROM makt
                      WHERE matnr EQ @ls_lips-matnr
                      AND spras EQ 'S'.

                    IF sy-subrc NE 0.
                      wa_conceptos_data-descripcion = ls_lips-arktx.
                    ENDIF.

                    wa_conceptos_data-valorunitario = '0'.
                    wa_conceptos_data-importe = '0'.
                    wa_conceptos_data-objetoimp = '01'.
                    "wa_conceptos_data-claveprodserv = '78101802'.

                    SELECT SINGLE ext_value INTO wa_conceptos_data-claveprodserv
                      FROM /aif/t_mvmapval
                      WHERE ns = '/EDOMX'
                      AND vmapname = 'PRODUCT_CODE'
                      AND int_value = ls_lips-matnr.

                    "wa_conceptos_data-claveunidad = 'SER'.
                    SELECT SINGLE valor2 INTO wa_conceptos_data-claveunidad
                      FROM zparamglob
                      WHERE programa EQ 'ZCFDI_MONITOR'
                      AND parametro EQ '5'
                      AND valor1 EQ ls_lips-vrkme.

                    APPEND wa_conceptos_data TO wa_de_comprobante-to_conceptos.
                    CLEAR: ls_lips, wa_conceptos_data.
                  ENDLOOP.

*Se llena el nodo "Emisor".

                  IF ls_torrot-tspid NE ''.
                    lv_trexterno = 'X'.
                  ENDIF.

*                  SELECT SINGLE valor1 INTO @DATA(lv_docpropio)
*                    FROM zparamglob
*                    WHERE programa EQ @lc_programa
*                    AND parametro EQ '2'
*                    AND subparametro EQ '1'.
*
*                  SELECT SINGLE valor1 INTO @DATA(lv_docexterno)
*                    FROM zparamglob
*                    WHERE programa EQ @lc_programa
*                    AND parametro EQ '2'
*                    AND subparametro EQ '2'.
*
*                  SELECT SINGLE valor1 INTO @DATA(lv_docmultimodal)
*                  FROM zparamglob
*                  WHERE programa EQ @lc_programa
*                  AND parametro EQ '2'
*                  AND subparametro EQ '3'.

                  "IF ls_torrot-tor_type EQ lv_docpropio OR ls_torrot-tor_type EQ lv_docmultimodal.          "Transporte propio.
                  IF lv_trexterno EQ ''.                                              "Transporte propio.
                    wa_emisor_data-notrans = ls_torrot-tor_id.
                    wa_emisor_data-rfc = 'FJC780315E91'.
                    wa_emisor_data-nombre = 'FABRICA DE JABON LA CORONA'.
                    wa_emisor_data-regimenfiscal = '601'.

                    APPEND wa_emisor_data TO wa_de_comprobante-to_emisor.
                    CLEAR wa_emisor_data.

*Se llena el nodo "Receptor".

                    wa_receptor_data-notrans = ls_torrot-tor_id.
                    wa_receptor_data-rfc = 'FJC780315E91'.
                    wa_receptor_data-nombre = 'FABRICA DE JABON LA CORONA'.
                    wa_receptor_data-regimenfiscalreceptor = '601'.
                    wa_receptor_data-domiciliofiscalreceptor = '55348'.
                    wa_receptor_data-usocfdi = 'S01'.

                    APPEND wa_receptor_data TO wa_de_comprobante-to_receptor.
                    CLEAR wa_receptor_data.

                    "ELSEIF ls_torrot-tor_type EQ lv_docexterno.      "Transporte de terceros.
                  ELSEIF lv_trexterno EQ 'X'.                                         "Transporte de terceros.
                    IF ls_torrot-tspid NE ''.

                      SELECT SINGLE taxnum INTO lv_rfctrans
                      FROM dfkkbptaxnum
                      WHERE partner EQ ls_torrot-tspid
                      AND taxtype EQ 'MX1'.

                      SELECT SINGLE name_org1, name_org2 INTO ( @DATA(lv_name1), @DATA(lv_name2) )
                        FROM but000
                        WHERE partner EQ @ls_torrot-tspid.

                      CONCATENATE lv_name1 lv_name2 INTO lv_nombretra SEPARATED BY space.
                      "CONDENSE lv_nombretra NO-GAPS.

                      SELECT SINGLE ext_value INTO lv_regfistra
                        FROM /aif/t_mvmapval
                        WHERE ns EQ '/EDOMX'
                        AND vmapname EQ 'RECEIVER_TAX_REGIME'
                        AND int_value EQ ls_torrot-tspid.

                      wa_emisor_data-notrans = ls_torrot-tor_id.
                      wa_emisor_data-rfc = lv_rfctrans.
                      wa_emisor_data-nombre = lv_nombretra.
                      wa_emisor_data-regimenfiscal = lv_regfistra.

                      APPEND wa_emisor_data TO wa_de_comprobante-to_emisor.
                      CLEAR wa_emisor_data.

                    ELSE.
*Error: "No hay un trnasportista asiciado a la orden de flete.
                      CONCATENATE 'La orden de flete' wa_keytab-value 'no tiene un trnasportista asociado.' INTO lv_error_msg SEPARATED BY space.
                      CALL METHOD lo_msg->add_message
                        EXPORTING
                          iv_msg_type   = /iwbep/cl_cos_logger=>error
                          iv_msg_id     = 'ZTM_MSG'
                          iv_msg_number = '004'
                          iv_msg_text   = lv_error_msg.
                      RETURN.
                    ENDIF.

*Se llena el nodo "Receptor".

                    wa_receptor_data-notrans = ls_torrot-tor_id.
                    wa_receptor_data-rfc = 'FJC780315E91'.
                    wa_receptor_data-nombre = 'FABRICA DE JABON LA CORONA'.
                    wa_receptor_data-regimenfiscalreceptor = '601'.
                    wa_receptor_data-domiciliofiscalreceptor = '55348'.
                    wa_receptor_data-usocfdi = 'S01'.

                    APPEND wa_receptor_data TO wa_de_comprobante-to_receptor.
                    CLEAR wa_receptor_data.

                  ENDIF.


                  CLEAR wa_conceptos_data.

*Se llena el nodo "Complemento".

                  SELECT SINGLE valor1 INTO @DATA(lv_versionccp)
                    FROM zparamglob
                    WHERE programa EQ @lc_programa
                    AND parametro EQ '3'
                    AND subparametro EQ '1'.

                  wa_complemento_data-notrans = ls_torrot-tor_id.
                  wa_complemento_data-version = lv_versionccp.
                  wa_complemento_data-transpinternac = 'No'.
                  wa_complemento_data-totaldistrec = ls_torrot-total_distance_km.

*Se llena el nodo "Ubicaciones"

                  DESCRIBE TABLE lt_torstp LINES DATA(lv_lnstp).

                  LOOP AT lt_torstp INTO ls_torstp.
                    wa_ubicaciones_data-notrans = ls_torrot-tor_id.

                    CONCATENATE lv_date1(4) '-' lv_date1+4(2) '-' lv_date1+6(2) 'T00:00:00' INTO DATA(lv_fechahorasal).

                    IF ls_torstp-stop_seq_pos EQ 'F'.
                      wa_ubicaciones_data-tipoubicacion = 'Origen'.
                      IF strlen( ls_torstp-log_locid ) > 4.
                        IF ls_torstp-log_locid(2) = 'SP'.
                          CONCATENATE 'OR' ls_torstp-log_locid+3(4) INTO DATA(lv_origen).
                        ELSE.
                          CONCATENATE 'OR' ls_torstp-log_locid+4(6) INTO lv_origen.
                        ENDIF.
                      ELSEIF strlen( ls_torstp-log_locid ) <= 4.
                        CONCATENATE 'OR' ls_torstp-log_locid INTO lv_origen.
                      ENDIF.
                      wa_ubicaciones_data-idubicacion = lv_origen.
                      wa_ubicaciones_data-rfcremitentedestinatario = 'FJC780315E91'.

                      IF lv_origen EQ 'ORCMAQ'.
                        SELECT SINGLE name1, name2, name3, name4 INTO ( @DATA(lv_nameor1), @DATA(lv_nameor2), @DATA(lv_nameor3), @DATA(lv_nameor4) )
                          FROM adrc AS ad
                          INNER JOIN /sapapo/loc AS lo ON ad~addrnumber = lo~adrnummer
                          WHERE lo~locno = @ls_torstp-log_locid.

                        CONCATENATE lv_nameor1 lv_nameor2 lv_nameor3 lv_nameor4 INTO DATA(lv_nombreorigen).
                        CONDENSE lv_nombreorigen.

                        wa_ubicaciones_data-nombreremitentedestinatario = lv_nombreorigen.
                      ELSE.
                        wa_ubicaciones_data-nombreremitentedestinatario = 'FABRICA DE JABON LA CORONA'.
                      ENDIF.

                      wa_ubicaciones_data-fechahorasalidallegada = lv_fechahorasal.
                      LOOP AT lt_apoloc INTO ls_apoloc WHERE locno = ls_torstp-log_locid.
                        wa_ubicaciones_data-nodireccion = ls_apoloc-adrnummer.

*Se llena el nodo "Domicilio".
                        LOOP AT lt_adrc INTO ls_adrc WHERE addrnumber EQ ls_apoloc-adrnummer.
                          wa_domicilio_data-notrans = ls_torrot-tor_id.
                          wa_domicilio_data-nodireccion = ls_apoloc-adrnummer.
                          wa_domicilio_data-calle = ls_adrc-street.
                          wa_domicilio_data-codigopostal = ls_adrc-post_code1.
                          wa_domicilio_data-estado = ls_adrc-region.
                          wa_domicilio_data-numeroexterior = ls_adrc-house_num1.
                          wa_domicilio_data-colonia = ls_adrc-city1.
                          wa_domicilio_data-municipio = ls_adrc-city2.
                          wa_domicilio_data-localidad = ''.
                          wa_domicilio_data-pais = ls_adrc-country.
                        ENDLOOP.

                        SELECT SINGLE ypos INTO @DATA(lv_latitud)
                          FROM /sapapo/loc
                          WHERE locno EQ @ls_torstp-log_locid.

                        SELECT SINGLE xpos INTO @DATA(lv_longitud)
                          FROM /sapapo/loc
                          WHERE locno EQ @ls_torstp-log_locid.

                        lv_latitud = round( val = lv_latitud dec = 6 ).
                        lv_longitud = round( val = lv_longitud dec = 6 ).

                        wa_domicilio_data-latitud = lv_latitud.
                        wa_domicilio_data-longitud = lv_longitud.

                        DATA(lv_lenlon) = strlen( wa_domicilio_data-longitud ).
                        DATA(lv_lenlat) = strlen( wa_domicilio_data-latitud ).

                        DATA(lv_offsetlon) = lv_lenlon - 2.
                        DATA(lv_offsetlat) = lv_lenlat - 2.

                        DATA(lv_multlon) = wa_domicilio_data-longitud+lv_offsetlon(2).
                        DATA(lv_multlat) = wa_domicilio_data-latitud+lv_offsetlon(2).

                        CASE lv_multlat.
                          WHEN '00'.
                            wa_domicilio_data-latitud = wa_domicilio_data-latitud(12).
                          WHEN '01'.
                            wa_domicilio_data-latitud = wa_domicilio_data-latitud(12) * 10.
                          WHEN '02'.
                            wa_domicilio_data-latitud = wa_domicilio_data-latitud(12) * 100.
                        ENDCASE.

                        CASE lv_multlon.
                          WHEN '00'.
                            wa_domicilio_data-longitud = wa_domicilio_data-longitud(12).
                          WHEN '01'.
                            wa_domicilio_data-longitud = wa_domicilio_data-longitud(12) * 10.
                          WHEN '02'.
                            wa_domicilio_data-longitud = wa_domicilio_data-longitud(12) * 100.
                        ENDCASE.

                        CONDENSE: wa_domicilio_data-latitud, wa_domicilio_data-longitud.

                        APPEND wa_domicilio_data TO wa_ubicaciones_data-to_domicilio.
                        CLEAR: wa_domicilio_data, lv_latitud, lv_longitud, lv_lenlon, lv_lenlat, lv_offsetlon, lv_offsetlat, lv_multlon, lv_multlat.
                      ENDLOOP.

                      APPEND wa_ubicaciones_data TO wa_complemento_data-to_ubicaciones.
                      CLEAR: wa_ubicaciones_data, ls_apoloc.
                    ELSEIF ls_torstp-stop_seq_pos EQ 'I' OR ls_torstp-stop_seq_pos EQ 'L'.
                      IF ls_torstp-stop_cat = 'I'.
                        IF strlen( ls_torstp-log_locid ) > 4.
                          IF ls_torstp-log_locid(2) = 'SP'.
                            CONCATENATE 'DE' ls_torstp-log_locid+3(4) INTO DATA(lv_destino).
                          ELSEIF ls_torstp-log_locid(1) = 'C'.
                            CONCATENATE 'DE' ls_torstp-log_locid(4) INTO lv_destino.
                          ELSE.
                            CONCATENATE 'DE' ls_torstp-log_locid+4(6) INTO lv_destino.
                          ENDIF.
                        ELSEIF strlen( ls_torstp-log_locid ) <= 4.
                          DATA: lv_longlocid TYPE i.

                          lv_longlocid = strlen( ls_torstp-log_locid ).

                          IF lv_longlocid EQ 1.
                            CONCATENATE '00000' ls_torstp-log_locid INTO ls_torstp-log_locid.
                          ELSEIF lv_longlocid EQ 2.
                            CONCATENATE '0000' ls_torstp-log_locid INTO ls_torstp-log_locid.
                          ELSEIF lv_longlocid EQ 3.
                            CONCATENATE '000' ls_torstp-log_locid INTO ls_torstp-log_locid.
                          ELSEIF lv_longlocid EQ 4.
                            CONCATENATE '00' ls_torstp-log_locid INTO ls_torstp-log_locid.
                          ELSEIF lv_longlocid EQ 5.
                            CONCATENATE '0' ls_torstp-log_locid INTO ls_torstp-log_locid.
                          ENDIF.

                          CONCATENATE 'DE' ls_torstp-log_locid INTO lv_destino.

                          SHIFT ls_torstp-log_locid LEFT DELETING LEADING '0'.
                        ENDIF.

                        IF ls_torstp-log_locid EQ 'SERASUR' OR ls_torstp-log_locid EQ 'ADAYUAN'.
                          CONCATENATE 'DE' ls_torstp-log_locid(4) INTO lv_destino.
                        ENDIF.

                        READ TABLE lt_torite ASSIGNING FIELD-SYMBOL(<fs_torite_id>) WITH KEY parent_key = ls_torstp-parent_key des_stop_key = ls_torstp-db_key item_cat = 'PRD' main_cargo_item = 'X'.
                        IF <fs_torite_id> IS ASSIGNED.
                          SELECT SINGLE xcpdk INTO @DATA(lv_cpd)
                            FROM kna1
                            WHERE kunnr EQ @<fs_torite_id>-consignee_id.

                          IF lv_cpd EQ 'X'.
                            SELECT SINGLE stcd1 INTO @DATA(lv_rfcdestino)
                              FROM vbpa3
                              WHERE vbeln EQ @<fs_torite_id>-orig_btd_id+25(10)
                              AND parvw EQ 'RE'.

                            IF lv_rfcdestino EQ ''.
                              lv_rfcdestino = 'XAXX010101000'.
                            ENDIF.

                            SELECT SINGLE name1, name2 INTO ( @DATA(lv_namedes1), @DATA(lv_namedes2) )
                              FROM adrc AS ad
                              INNER JOIN vbpa AS vb ON ad~addrnumber = vb~adrnr
                              WHERE vb~vbeln EQ @<fs_torite_id>-orig_btd_id+25(10)
                              AND vb~parvw EQ 'RE'.
                          ELSE.

                            SELECT SINGLE taxnum INTO @lv_rfcdestino
                          FROM dfkkbptaxnum
                          WHERE partner EQ @lv_destino+2(4)
                          AND taxtype EQ 'MX1'.

                            IF sy-subrc NE 0.
                              SELECT SINGLE taxnum INTO @lv_rfcdestino
                                FROM dfkkbptaxnum
                                WHERE partner EQ @ls_torstp-log_locid
                                AND taxtype EQ 'MX1'.
                            ENDIF.

                            SELECT SINGLE name_org1, name_org2, bu_group, type INTO ( @lv_namedes1, @lv_namedes2, @DATA(lv_bpgroup), @DATA(lv_type) )
                              FROM but000
                              WHERE partner EQ @lv_destino+2(4).

                            IF sy-subrc NE 0.

                              SELECT SINGLE name_org1, name_org2, bu_group, type INTO ( @lv_namedes1, @lv_namedes2, @lv_bpgroup, @lv_type )
                                FROM but000
                                WHERE partner EQ @ls_torstp-log_locid.
                              IF lv_type EQ 1.
                                SELECT SINGLE name_first, name_last, bu_group, type INTO ( @lv_namedes1, @lv_namedes2, @lv_bpgroup, @lv_type )
                                  FROM but000
                                  WHERE partner EQ @ls_torstp-log_locid.
                              ENDIF.

                            ENDIF.

                          ENDIF.
                        ENDIF.

                        IF lv_bpgroup EQ 'ZCEN'.
                          lv_rfcdestino = 'FJC780315E91'.
                        ENDIF.

                        IF lv_rfcdestino EQ ''.
                          SELECT SINGLE taxnum INTO @lv_rfcdestino
                            FROM dfkkbptaxnum
                            WHERE partner EQ @ls_torstp-log_locid
                            AND taxtype EQ 'MX1'.
                        ENDIF.

                        IF lv_namedes1 EQ ''.
                          SELECT SINGLE name_org1, name_org2 INTO ( @lv_namedes1, @lv_namedes2 )
                            FROM but000
                            WHERE partner EQ @ls_torstp-log_locid.
                        ENDIF.

                        CONCATENATE lv_namedes1 lv_namedes2 INTO DATA(lv_nombredestino) SEPARATED BY space.
                        "CONDENSE lv_nombredestino NO-GAPS.

                        IF lv_tortype EQ 'Z104' AND lv_rfcdestino NE 'XEXX010101000'. "Si la clase de documento es de exportaciones, buscamos el RFC del destino en las ubicaciones
                          CLEAR: lv_rfcdestino, lv_nombredestino.
                          SELECT SINGLE altlocid INTO @lv_rfcdestino
                            FROM /sapapo/localid AS a
                            INNER JOIN /sapapo/loc AS b
                            ON a~locid EQ b~locid
                            WHERE b~locno EQ @ls_torstp-log_locid
                            AND a~alitype EQ 'RFC_MX'.

                          IF sy-subrc NE 0.
                            lv_rfcdestino = 'XAXX010101000'.
                          ENDIF.

                          SELECT SINGLE descr40 INTO @lv_nombredestino
                            FROM /sapapo/loct AS a
                            INNER JOIN /sapapo/loc AS b
                            ON a~locid EQ b~locid
                            WHERE b~locno EQ @ls_torstp-log_locid.
                        ENDIF.

                        CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
                          EXPORTING
                            date      = sy-datum
                            days      = 1
                            months    = 0
                            signum    = '+' " para calcular fechas posteriores
                            years     = 0
                          IMPORTING
                            calc_date = lv_date.

                        CONCATENATE lv_date(4) '-' lv_date+4(2) '-' lv_date+6(2) 'T00:00:00' INTO DATA(lv_fechahorallega).

                        wa_ubicaciones_data-tipoubicacion = 'Destino'.
                        wa_ubicaciones_data-idubicacion = lv_destino.
                        IF lv_rfcdestino NE ''.
                          wa_ubicaciones_data-rfcremitentedestinatario = lv_rfcdestino.
                        ELSE.
                          IF lv_tortype EQ 'Z104'.
                            wa_ubicaciones_data-rfcremitentedestinatario = 'XAXX010101000'.
                          ELSE.
                            wa_ubicaciones_data-rfcremitentedestinatario = 'FJC780315E91'.
                          ENDIF.
                        ENDIF.
*                        IF strlen( wa_ubicaciones_data-idubicacion ) = 6.
*                          wa_ubicaciones_data-rfcremitentedestinatario = 'FJC780315E91'.
*                        ELSE.
*                          wa_ubicaciones_data-rfcremitentedestinatario = lv_rfcdestino.
*                        ENDIF.

                        DATA(lv_namedeslen) = strlen( lv_nombredestino ).

                        IF lv_nombredestino EQ '' OR lv_nombredestino IS INITIAL OR lv_nombredestino EQ ' ' OR lv_namedeslen EQ 0 OR lv_namedeslen EQ 1.
                          SELECT SINGLE name1, name2, name3, name4 INTO ( @lv_namedes1, @lv_namedes2, @DATA(lv_namedes3), @DATA(lv_namedes4) )
                            FROM adrc AS ad
                            INNER JOIN /sapapo/loc AS lo ON ad~addrnumber = lo~adrnummer
                            WHERE lo~locno = @ls_torstp-log_locid.

                          CONCATENATE lv_namedes1 lv_namedes2 lv_namedes3 lv_namedes4 INTO lv_nombredestino.
                          CONDENSE lv_nombredestino.

                          wa_ubicaciones_data-nombreremitentedestinatario = lv_nombredestino.
                        ELSE.
                          wa_ubicaciones_data-nombreremitentedestinatario = lv_nombredestino.
                        ENDIF.
                        wa_ubicaciones_data-fechahorasalidallegada = lv_fechahorallega.
                        LOOP AT lt_torsts INTO ls_torsts WHERE root_key EQ ls_torstp-parent_key AND succ_stop_key EQ ls_torstp-db_key.
                          wa_ubicaciones_data-distanciarecorrida = ls_torsts-distance_km.
                        ENDLOOP.

                        wa_ubicaciones_data-cliente = ls_torstp-log_locid.

                        LOOP AT lt_torite INTO DATA(ls_torite_ent) WHERE des_loc_idtrq EQ ls_torstp-log_locid AND item_type EQ 'PRD' AND main_cargo_item EQ 'X'.

                          ls_entregas-vbeln = ls_torite_ent-base_btd_id+25(10).
                          APPEND ls_entregas TO lt_entregas.

                          wa_ubicaciones_data-peso = wa_ubicaciones_data-peso + ls_torite_ent-gro_wei_val.
                          CLEAR: ls_torite_ent, ls_entregas.
                        ENDLOOP.

                        SORT lt_entregas ASCENDING BY vbeln.
                        DELETE ADJACENT DUPLICATES FROM lt_entregas.

                        IF sy-subrc NE 0 AND ls_torrot-tor_type EQ 'Z104'.  "Si la ubicación destino no existe en LT_TORITE por que solo se trata de una parada intermedia (Punto Aduabal)
                          READ TABLE lt_torstp INTO DATA(ls_torstp_final) WITH KEY stop_seq_pos = 'L' stop_cat = 'I'.
                          IF sy-subrc EQ 0.
                            LOOP AT lt_torite INTO ls_torite_ent WHERE des_loc_idtrq EQ ls_torstp_final-log_locid AND item_type EQ 'PRD' AND main_cargo_item EQ 'X'.

                              ls_entregas-vbeln = ls_torite_ent-base_btd_id+25(10).
                              APPEND ls_entregas TO lt_entregas.

                              wa_ubicaciones_data-peso = wa_ubicaciones_data-peso + ls_torite_ent-gro_wei_val.
                              CLEAR: ls_torite_ent, ls_entregas.
                            ENDLOOP.
                            SORT lt_entregas ASCENDING BY vbeln.
                            DELETE ADJACENT DUPLICATES FROM lt_entregas.
                          ENDIF.
                        ENDIF.


                        LOOP AT lt_entregas INTO ls_entregas.
                          IF wa_ubicaciones_data-entrega EQ ''.
                            wa_ubicaciones_data-entrega = ls_entregas-vbeln.
                          ELSE.
                            CONCATENATE wa_ubicaciones_data-entrega ', ' ls_entregas-vbeln INTO wa_ubicaciones_data-entrega.
                          ENDIF.
                        ENDLOOP.

                        LOOP AT lt_apoloc INTO ls_apoloc WHERE locno = ls_torstp-log_locid.
                          wa_ubicaciones_data-nodireccion = ls_apoloc-adrnummer.

*Se llena el nodo "Domicilio".
                          LOOP AT lt_adrc INTO ls_adrc WHERE addrnumber EQ ls_apoloc-adrnummer.
                            wa_domicilio_data-notrans = ls_torrot-tor_id.
                            wa_domicilio_data-nodireccion = ls_apoloc-adrnummer.
                            wa_domicilio_data-calle = ls_adrc-street.
                            wa_domicilio_data-codigopostal = ls_adrc-post_code1.
                            wa_domicilio_data-estado = ls_adrc-region.
                            wa_domicilio_data-numeroexterior = ls_adrc-house_num1.
                            wa_domicilio_data-colonia = ls_adrc-city1.
                            wa_domicilio_data-municipio = ls_adrc-city2.
                            wa_domicilio_data-localidad = ''.
                            wa_domicilio_data-pais = ls_adrc-country.
                          ENDLOOP.

                          IF lv_cpd NE 'X'.

                            SELECT SINGLE ypos INTO @lv_latitud
                              FROM /sapapo/loc
                              WHERE locno EQ @ls_torstp-log_locid.

                            SELECT SINGLE xpos INTO @lv_longitud
                              FROM /sapapo/loc
                              WHERE locno EQ @ls_torstp-log_locid.

                            lv_latitud = round( val = lv_latitud dec = 6 ).
                            lv_longitud = round( val = lv_longitud dec = 6 ).

                            wa_domicilio_data-latitud = lv_latitud.
                            wa_domicilio_data-longitud = lv_longitud.

                            lv_lenlon = strlen( wa_domicilio_data-longitud ).
                            lv_lenlat = strlen( wa_domicilio_data-latitud ).

                            lv_offsetlon = lv_lenlon - 2.
                            lv_offsetlat = lv_lenlat - 2.

                            lv_multlon = wa_domicilio_data-longitud+lv_offsetlon(2).
                            lv_multlat = wa_domicilio_data-latitud+lv_offsetlat(2).

                            CASE lv_multlat.
                              WHEN '00'.
                                wa_domicilio_data-latitud = wa_domicilio_data-latitud(12).
                              WHEN '01'.
                                wa_domicilio_data-latitud = wa_domicilio_data-latitud(12) * 10.
                              WHEN '02'.
                                wa_domicilio_data-latitud = wa_domicilio_data-latitud(12) * 100.
                            ENDCASE.

                            CASE lv_multlon.
                              WHEN '00'.
                                wa_domicilio_data-longitud = wa_domicilio_data-longitud(12).
                              WHEN '01'.
                                wa_domicilio_data-longitud = wa_domicilio_data-longitud(12) * 10.
                              WHEN '02'.
                                wa_domicilio_data-longitud = wa_domicilio_data-longitud(12) * 100.
                            ENDCASE.

                            CONDENSE: wa_domicilio_data-latitud, wa_domicilio_data-longitud.

                          ELSE.
                            "Si el cliente es CPD, consultamos el servicio de HERE Maps para obtener coordenadas GPS.
                            lo_heremaps->get_latlon_cpd(
                              EXPORTING
                                iv_adrnr     = ls_apoloc-adrnummer
                              IMPORTING
                                iv_latitude  = lv_latitud
                                iv_longitude = lv_longitud
                            ).

                            lv_latitud = round( val = lv_latitud dec = 6 ).
                            lv_longitud = round( val = lv_longitud dec = 6 ).

                            wa_domicilio_data-latitud = lv_latitud.
                            wa_domicilio_data-longitud = lv_longitud.

                            lv_lenlon = strlen( wa_domicilio_data-longitud ).
                            lv_lenlat = strlen( wa_domicilio_data-latitud ).

                            lv_offsetlon = lv_lenlon - 2.
                            lv_offsetlat = lv_lenlat - 2.

                            lv_multlon = wa_domicilio_data-longitud+lv_offsetlon(2).
                            lv_multlat = wa_domicilio_data-latitud+lv_offsetlat(2).

                            CASE lv_multlat.
                              WHEN '00'.
                                wa_domicilio_data-latitud = wa_domicilio_data-latitud(12).
                              WHEN '01'.
                                wa_domicilio_data-latitud = wa_domicilio_data-latitud(12) * 10.
                              WHEN '02'.
                                wa_domicilio_data-latitud = wa_domicilio_data-latitud(12) * 100.
                            ENDCASE.

                            CASE lv_multlon.
                              WHEN '00'.
                                wa_domicilio_data-longitud = wa_domicilio_data-longitud(12).
                              WHEN '01'.
                                wa_domicilio_data-longitud = wa_domicilio_data-longitud(12) * 10.
                              WHEN '02'.
                                wa_domicilio_data-longitud = wa_domicilio_data-longitud(12) * 100.
                            ENDCASE.

                            CONDENSE: wa_domicilio_data-latitud, wa_domicilio_data-longitud.

                          ENDIF.

                          IF lv_tortype EQ 'Z104'.    "Transporte para Exportaciones
                            IF lv_lnstp GT 1. "Si no es entrega directa (solo una parada), agrega solo las paradas cuyo país sea MX
                              DATA(lv_paisdest) = wa_domicilio_data-pais.
                              IF wa_domicilio_data-pais EQ 'MX'.
                                APPEND wa_domicilio_data TO wa_ubicaciones_data-to_domicilio.
                              ENDIF.
                            ENDIF.
                          ELSEIF lv_tortype NE 'Z104'.
                            APPEND wa_domicilio_data TO wa_ubicaciones_data-to_domicilio.
                          ENDIF.
                          "Cálculo de distancia a destino.
                          READ TABLE lt_torstp ASSIGNING FIELD-SYMBOL(<fs_torstp>) WITH KEY stop_seq_pos = 'F'. "Para coordenadas de origen.

                          IF <fs_torstp> IS ASSIGNED.
                            READ TABLE lt_apoloc ASSIGNING FIELD-SYMBOL(<fs_apoloc>) WITH KEY locno = <fs_torstp>-log_locid.
                            IF <fs_apoloc> IS ASSIGNED.
                              CLEAR: lv_lenlon, lv_lenlat, lv_multlon, lv_multlat.

                              lv_latitudori = <fs_apoloc>-ypos.
                              lv_longitudori = <fs_apoloc>-xpos.

                              lv_latitudori = round( val = lv_latitudori dec = 6 ).
                              lv_longitudori = round( val = lv_longitudori dec = 6 ).

                              lv_lenlon = strlen( lv_longitudori ).
                              lv_lenlat = strlen( lv_latitudori ).

                              lv_offsetlon = lv_lenlon - 2.
                              lv_offsetlat = lv_lenlat - 2.

                              lv_multlon = lv_longitudori+lv_offsetlon(2).
                              lv_multlat = lv_latitudori+lv_offsetlat(2).

                              CASE lv_multlat.
                                WHEN '00'.
                                  lv_latitudori = lv_latitudori(12).
                                WHEN '01'.
                                  lv_latitudori = lv_latitudori(12) * 10.
                                WHEN '02'.
                                  lv_latitudori = lv_latitudori(12) * 100.
                              ENDCASE.

                              CASE lv_multlon.
                                WHEN '00'.
                                  lv_longitudori = lv_longitudori(12).
                                WHEN '01'.
                                  lv_longitudori = lv_longitudori(12) * 10.
                                WHEN '02'.
                                  lv_longitudori = lv_longitudori(12) * 100.
                              ENDCASE.

                              UNASSIGN <fs_apoloc>.
                            ENDIF.
                            UNASSIGN <fs_torstp>.
                          ENDIF.

                          lv_longituddes = wa_domicilio_data-longitud.
                          lv_latituddes  = wa_domicilio_data-latitud.

*                          lo_heremaps->get_distance(
*                            EXPORTING
*                              iv_latdes    = lv_latituddes
*                              iv_londes    = lv_longituddes
*                              iv_latori    = lv_latitudori
*                              iv_lonori    = lv_longitudori
*                              iv_adrnr     = wa_ubicaciones_data-nodireccion
*                            IMPORTING
*                              iv_distance = lv_distancia
*                          ).
*
*                          wa_ubicaciones_data-distanciadestino = lv_distancia.

                          CLEAR: wa_domicilio_data, lv_latitud, lv_longitud, lv_lenlon, lv_lenlat, lv_offsetlon, lv_offsetlat, lv_multlon, lv_multlat, lv_rfcdestino, lv_nombredestino.
                        ENDLOOP.

                        IF lv_tortype EQ 'Z104'.
                          IF lv_paisdest EQ 'MX' AND lv_lnstp GT 1.
                            APPEND wa_ubicaciones_data TO wa_complemento_data-to_ubicaciones.
                            lv_sumadistrecorrida = lv_sumadistrecorrida + wa_ubicaciones_data-distanciarecorrida.
                          ENDIF.
                        ELSEIF lv_tortype NE 'Z104'.
                          APPEND wa_ubicaciones_data TO wa_complemento_data-to_ubicaciones.
                        ENDIF.
                        CLEAR: wa_ubicaciones_data, ls_apoloc, lv_paisdest.

                      ENDIF.
                    ENDIF.
                  ENDLOOP.
                  DELETE wa_complemento_data-to_ubicaciones WHERE tipoubicacion EQ 'Destino' AND peso EQ '0.00'.
                  IF wa_complemento_data-totaldistrec NE lv_sumadistrecorrida.
                    CLEAR: wa_complemento_data-totaldistrec.
                    wa_complemento_data-totaldistrec = lv_sumadistrecorrida.
                  ENDIF.

*Se llena el nodo "Figura Transporte".

                  IF ls_torrot-tspid NE ''.  "Si es transporte de línea, se envían datos del transportista como TipoFigura = 02 ("Propietario")
                    wa_figuratran_data-notrans = ls_torrot-tor_id.
                    wa_figuratran_data-tipofigura = '02'.
                    wa_figuratran_data-numlicencia = ls_torrot-tspid. "Se envía el número de BP en lugar de la licencia

                    SELECT SINGLE taxnum INTO @wa_figuratran_data-rfcfigura
                      FROM dfkkbptaxnum
                      WHERE partner EQ @ls_torrot-tspid
                      AND taxtype EQ 'MX1'.

                    SELECT SINGLE name_org1, name_org2, name_org3, name_org4
                      INTO ( @DATA(lv_nametransp1), @DATA(lv_nametransp2), @DATA(lv_nametransp3), @DATA(lv_nametransp4) )
                      FROM but000
                      WHERE partner EQ @ls_torrot-tspid.

                    CONCATENATE lv_nametransp1 lv_nametransp2 lv_nametransp3 lv_nametransp4 INTO wa_figuratran_data-nombrefigura SEPARATED BY space.
                    CONDENSE wa_figuratran_data-nombrefigura.

                    APPEND wa_figuratran_data TO wa_complemento_data-to_figuratransporte.
                    CLEAR wa_figuratran_data.

                  ELSE.
                    LOOP AT lt_torite INTO ls_torite WHERE item_cat EQ 'DRI'.

                      SELECT SINGLE name_first, name_last INTO ( @DATA(lv_namefi1), @DATA(lv_namefi2) )
                        FROM but000
                        WHERE partner EQ @ls_torite-res_id.

                      CONCATENATE lv_namefi1 lv_namefi2 INTO DATA(lv_nomfigura) SEPARATED BY space.

                      SELECT SINGLE idnumber INTO @DATA(lv_licefigura)   "Primero se busca si el conductor tiene licencia federal "ZTM002".
                        FROM but0id
                        WHERE partner EQ @ls_torite-res_id
                        AND type EQ 'ZTM002'.

                      IF lv_licefigura EQ ''.  "Si no tiene licencia federal, se busca la licencia estatal "ZTM001".
                        SELECT SINGLE idnumber INTO @lv_licefigura
                        FROM but0id
                        WHERE partner EQ @ls_torite-res_id
                        AND type EQ 'ZTM001'.
                      ENDIF.

                      SELECT SINGLE taxnum INTO @DATA(lv_rfcfigura)
                        FROM dfkkbptaxnum
                        WHERE partner EQ @ls_torite-res_id
                        AND taxtype EQ 'MX1'.

                      wa_figuratran_data-notrans = ls_torrot-tor_id.
                      wa_figuratran_data-tipofigura = '01'.
                      wa_figuratran_data-nombrefigura = lv_nomfigura.
                      wa_figuratran_data-rfcfigura = lv_rfcfigura.
                      wa_figuratran_data-numlicencia = lv_licefigura.

                      APPEND wa_figuratran_data TO wa_complemento_data-to_figuratransporte.
                      CLEAR wa_figuratran_data.

                    ENDLOOP.
                    "IF sy-subrc NE '0' AND ls_torrot-tor_type NE 'Z102'.
                    IF sy-subrc NE '0' AND lv_trexterno EQ ''.
                      CONCATENATE 'La orden de flete' wa_keytab-value 'no tiene un conductor asignado.' INTO lv_error_msg SEPARATED BY space.
                      CALL METHOD lo_msg->add_message
                        EXPORTING
                          iv_msg_type   = /iwbep/cl_cos_logger=>error
                          iv_msg_id     = 'ZTM_MSG'
                          iv_msg_number = '005'
                          iv_msg_text   = lv_error_msg.
                      RETURN.
                    ENDIF.
                  ENDIF.
                  CLEAR ls_torite.

*Se llena el nodo "Mercancías".
                  LOOP AT lt_torite INTO ls_torite WHERE item_type = 'TRUC' AND item_parent_key EQ '00000000000000000000000000000000'.

                    LOOP AT lt_torite INTO ls_torite WHERE item_cat = 'PRD'.

                      SELECT * INTO ls_procode
                        FROM /aif/t_mvmapval
                        WHERE ns EQ '/EDOMX'
                        AND vmapname EQ 'PRODUCT_CODE'
                        AND int_value EQ ls_torite-product_id.
                      ENDSELECT.
                      APPEND ls_procode TO lt_procode.
                      SORT lt_procode ASCENDING BY ext_value.

                      ls_procode1-ext_value = ls_procode-ext_value.
                      APPEND ls_procode1 TO lt_procode1.
                      DELETE ADJACENT DUPLICATES FROM lt_procode COMPARING int_value.

                      SORT lt_procode1 ASCENDING BY ext_value.
                      DELETE ADJACENT DUPLICATES FROM lt_procode1.
                      DESCRIBE TABLE lt_procode1 LINES lv_numtotmer.

                      wa_mercancias_data-notrans = ls_torrot-tor_id.
                      wa_mercancias_data-numtotalmercancias = lv_numtotmer.
                      CONDENSE wa_mercancias_data-numtotalmercancias.
                      wa_mercancias_data-pesobrutotal = ls_torrot-net_wei_val.
                      wa_mercancias_data-unidadpeso = 'KGM'.

                    ENDLOOP.

                    DELETE ADJACENT DUPLICATES FROM lt_procode COMPARING int_value.

*Se llena el nodo "Mercancía".

                    IF line_exists( lt_torite[ item_type = 'CONT' ] ).  "Si existe un contenedor dentro del viaje, se busca con dlv_prio.
                      SELECT FROM /aif/t_mvmapval AS a
                        INNER JOIN /scmtms/d_torite AS b
                        ON a~int_value EQ b~product_id
                        INNER JOIN zsd_ccpbienestra AS c
                        ON c~claveprodserv EQ a~ext_value
                        FIELDS b~qua_pcs_val, a~ext_value, b~qua_pcs_uni, b~gro_wei_val, c~descripcion
                        WHERE b~parent_key EQ @ls_torrot-db_key
                        AND b~item_cat EQ 'PRD'
                        "AND b~main_cargo_item EQ 'X' "Se cambia campo main_cargo_item por dlv_prio, ya que cuando hay contenedores, el contenedor toma el main_cargo.
                        AND b~dlv_prio NE ''
                        INTO TABLE @lt_procode2.
                    ELSE. "Si no existe contenedor dentro del viaje, entonces se busca por main_Cargo_item.
                      SELECT FROM /aif/t_mvmapval AS a
                      INNER JOIN /scmtms/d_torite AS b
                      ON a~int_value EQ b~product_id
                      INNER JOIN zsd_ccpbienestra AS c
                      ON c~claveprodserv EQ a~ext_value
                      FIELDS b~qua_pcs_val, a~ext_value, b~qua_pcs_uni, b~gro_wei_val, c~descripcion
                      WHERE b~parent_key EQ @ls_torrot-db_key
                      AND b~item_cat EQ 'PRD'
                      AND b~main_cargo_item EQ 'X' "Se cambia campo main_cargo_item por dlv_prio, ya que cuando hay contenedores, el contenedor toma el main_cargo.
                      "AND b~dlv_prio NE ''
                      INTO TABLE @lt_procode2.
                    ENDIF.

                    SORT lt_procode2 ASCENDING BY bienestra.

                    LOOP AT lt_procode2 INTO ls_procode2.
                      COLLECT ls_procode2 INTO lt_procode3.
                    ENDLOOP.
                    CLEAR ls_procode2.

                    SORT lt_procode3 ASCENDING BY bienestra.

                    LOOP AT lt_procode3 INTO ls_procode3.

                      wa_mercancia_data-notrans = ls_torrot-tor_id.
                      wa_mercancia_data-cantidad = ls_procode3-cantidad.
                      wa_mercancia_data-bienestransp = ls_procode3-bienestra.
                      "wa_mercancia_data-claveunidad = ls_procode3-claveuni.

                      SELECT SINGLE valor2 INTO wa_mercancia_data-claveunidad
                        FROM zparamglob
                        WHERE programa EQ 'ZCFDI_MONITOR'
                        AND parametro EQ '5'
                        AND valor1 EQ ls_procode3-claveuni.

                      IF ls_procode3-claveuni EQ ''.
                        wa_mercancia_data-claveunidad = 'KGM'.
                      ENDIF.

                      wa_mercancia_data-pesoenkg = ls_procode3-pesoenkg.
                      wa_mercancia_data-descripcion = ls_procode3-decrip.

                      lv_pesobruto = lv_pesobruto + ls_procode3-pesoenkg.

                      IF wa_mercancia_data-claveunidad EQ 'KGM' AND ( wa_mercancia_data-cantidad EQ 0 OR wa_mercancia_data-cantidad EQ '0.000' ).
                        wa_mercancia_data-cantidad = wa_mercancia_data-pesoenkg.
                      ENDIF.

*Se llena el nodo "Cantidad Transporta".
                      IF line_exists( lt_torite[ item_type = 'CONT' ] ).  "Si existe un contenedor dentro del viaje, se busca con dlv_prio.
                        SELECT FROM /aif/t_mvmapval AS a
                          INNER JOIN /scmtms/d_torite AS b
                          ON a~int_value EQ b~product_id
                          FIELDS SUM( b~qua_pcs_val ), SUM( b~net_wei_val ), a~ext_value, b~src_loc_idtrq, b~des_loc_idtrq
                          WHERE b~parent_key EQ @ls_torrot-db_key
                          AND b~item_cat EQ 'PRD'
                          "AND b~main_cargo_item EQ 'X' "Se cambia campo main_cargo_item por dlv_prio, ya que cuando hay contenedores, el contenedor toma el main_cargo.
                          AND b~dlv_prio NE ''
                          GROUP BY a~ext_value, b~src_loc_idtrq, b~des_loc_idtrq
                          INTO TABLE @lt_cantitrans.
                      ELSE.
                        SELECT FROM /aif/t_mvmapval AS a
                          INNER JOIN /scmtms/d_torite AS b
                          ON a~int_value EQ b~product_id
                          FIELDS SUM( b~qua_pcs_val ), SUM( b~net_wei_val ), a~ext_value, b~src_loc_idtrq, b~des_loc_idtrq
                          WHERE b~parent_key EQ @ls_torrot-db_key
                          AND b~item_cat EQ 'PRD'
                          AND b~main_cargo_item EQ 'X' "Se cambia campo main_cargo_item por dlv_prio, ya que cuando hay contenedores, el contenedor toma el main_cargo.
                          "AND b~dlv_prio NE ''
                          GROUP BY a~ext_value, b~src_loc_idtrq, b~des_loc_idtrq
                          INTO TABLE @lt_cantitrans.
                      ENDIF.

                      IF lv_tortype EQ 'Z104'.    "Transporte para Exportaciones
                        IF lv_lnstp GT 1. "Si no es entrega directa (solo una parada), agrega solo las paradas cuyo país sea MX
                          LOOP AT lt_cantitrans INTO ls_cantitrans.
                            SELECT SINGLE land1 INTO @lv_paisdest
                              FROM kna1
                              WHERE kunnr EQ @ls_cantitrans-destino.
                            IF lv_paisdest NE 'MX' AND lv_multimodal NE 'GTM'.
                              ls_cantitrans-destino = lv_destino.
                              MODIFY lt_cantitrans FROM ls_cantitrans TRANSPORTING destino.
                            ELSEIF lv_paisdest NE 'MX' AND lv_multimodal EQ 'GTM'.
                              CLEAR lv_destino.
                              IF lv_transfer EQ 'SERASUR' OR lv_transfer EQ 'ADAYUAN'.
                                CONCATENATE 'DE' lv_transfer(4) INTO lv_destino.
                              ENDIF.
                              ls_cantitrans-destino = lv_destino.
                              MODIFY lt_cantitrans FROM ls_cantitrans TRANSPORTING destino.
                            ENDIF.
                            CLEAR ls_cantitrans.
                          ENDLOOP.
                        ENDIF.
                      ENDIF.

                      LOOP AT lt_cantitrans INTO ls_cantitrans WHERE bienestra EQ ls_procode3-bienestra.
                        wa_cantidadtran_data-notrans = ls_torrot-tor_id.
                        wa_cantidadtran_data-bienestransp = ls_cantitrans-bienestra.
                        wa_cantidadtran_data-cantidad = ls_cantitrans-cantidad.
                        IF wa_cantidadtran_data-cantidad EQ 0 OR wa_cantidadtran_data-cantidad EQ '0.000'.
                          wa_cantidadtran_data-cantidad = ls_cantitrans-peso.
                        ENDIF.
                        IF strlen( ls_cantitrans-origen ) > 4.
                          IF ls_cantitrans-origen(2) = 'SP'.
                            CONCATENATE 'OR' ls_cantitrans-origen+3(4) INTO wa_cantidadtran_data-idorigen.
                          ELSE.
                            CONCATENATE 'OR' ls_cantitrans-origen+4(6) INTO wa_cantidadtran_data-idorigen.
                          ENDIF.
                        ELSEIF strlen( ls_cantitrans-origen ) <= 4.
                          CONCATENATE 'OR' ls_cantitrans-origen INTO wa_cantidadtran_data-idorigen.
                        ENDIF.


                        IF strlen( ls_cantitrans-destino ) > 4.
                          IF ls_cantitrans-destino(2) = 'SP'.
                            CONCATENATE 'DE' ls_cantitrans-destino+3(4) INTO wa_cantidadtran_data-iddestino.
                          ELSEIF ls_cantitrans-destino(2) = 'DE'.
                            wa_cantidadtran_data-iddestino = ls_cantitrans-destino.
                          ELSEIF ls_cantitrans-destino(1) = 'C'.
                            CONCATENATE 'DE' ls_cantitrans-destino(4) INTO wa_cantidadtran_data-iddestino.
                          ELSE.
                            CONCATENATE 'DE' ls_cantitrans-destino+4(6) INTO wa_cantidadtran_data-iddestino.
                          ENDIF.
                        ELSEIF strlen( ls_cantitrans-destino ) <= 4.

                          CLEAR: lv_longlocid.

                          lv_longlocid = strlen( ls_cantitrans-destino ).

                          IF lv_longlocid EQ 1.
                            CONCATENATE '00000' ls_cantitrans-destino INTO ls_cantitrans-destino.
                          ELSEIF lv_longlocid EQ 2.
                            CONCATENATE '0000' ls_cantitrans-destino INTO ls_cantitrans-destino.
                          ELSEIF lv_longlocid EQ 3.
                            CONCATENATE '000' ls_cantitrans-destino INTO ls_cantitrans-destino.
                          ELSEIF lv_longlocid EQ 4.
                            CONCATENATE '00' ls_cantitrans-destino INTO ls_cantitrans-destino.
                          ELSEIF lv_longlocid EQ 4.
                            CONCATENATE '0' ls_cantitrans-destino INTO ls_cantitrans-destino.
                          ENDIF.

                          CONCATENATE 'DE' ls_cantitrans-destino INTO wa_cantidadtran_data-iddestino.

                          SHIFT ls_cantitrans-destino LEFT DELETING LEADING '0'.
                        ENDIF.

                        APPEND wa_cantidadtran_data TO wa_mercancia_data-to_cantidadtransporta.
                        CLEAR wa_cantidadtran_data.
                      ENDLOOP.

                      APPEND wa_mercancia_data TO wa_mercancias_data-to_mercancia.
                      CLEAR wa_mercancia_data.

                    ENDLOOP.

                    IF lv_pesobruto NE wa_mercancias_data-pesobrutotal.
                      wa_mercancias_data-pesobrutotal = lv_pesobruto.
                    ENDIF.

*Se llena el nodo "Autotransporte".
                    LOOP AT lt_torite INTO ls_torite WHERE item_type = 'TRUC' AND item_parent_key EQ '00000000000000000000000000000000'.
                      SELECT SINGLE qualivalue INTO @DATA(lv_permisoSCT)
                        FROM /scmb/restmssk AS a
                        INNER JOIN /scmb/restmshd AS b
                        ON a~tmsresuuid = b~tmsresuid
                        WHERE b~name EQ @ls_torite-res_id
                        AND qualitype EQ 'PERMISOSCT'.
                      "IF sy-subrc NE '0' AND ls_torrot-tor_type NE 'Z102'.
                      IF sy-subrc NE '0' AND lv_trexterno EQ ''.
                        CONCATENATE 'El vehículo' ls_torite-res_id 'no cuenta con tipo de permiso SCT. Favor de revisar los datos maestros del recurso' INTO lv_error_msg SEPARATED BY space.
                        CALL METHOD lo_msg->add_message
                          EXPORTING
                            iv_msg_type   = /iwbep/cl_cos_logger=>error
                            iv_msg_id     = 'ZTM_MSG'
                            iv_msg_number = '006'
                            iv_msg_text   = lv_error_msg.
                        RETURN.
                      ENDIF.

                      SELECT SINGLE permisosct INTO @DATA(lv_numpermisoSCT)
                        FROM ztm_permisosct
                        WHERE name EQ @ls_torite-res_id.
*                      SELECT SINGLE qualivalue INTO @DATA(lv_numpermisoSCT)
*                        FROM /scmb/restmssk AS a
*                        INNER JOIN /scmb/restmshd AS b
*                        ON a~tmsresuuid = b~tmsresuid
*                        WHERE b~name EQ @ls_torite-res_id
*                        AND qualitype EQ 'NUMPERMISOSCT'.
                      "IF sy-subrc NE '0' AND ls_torrot-tor_type NE 'Z102'.
                      IF sy-subrc NE '0' AND lv_trexterno EQ ''.
                        CONCATENATE 'El vehículo' ls_torite-res_id 'no cuenta con número de permiso SCT. Favor de revisar los datos maestros del recurso' INTO lv_error_msg SEPARATED BY space.
                        CALL METHOD lo_msg->add_message
                          EXPORTING
                            iv_msg_type   = /iwbep/cl_cos_logger=>error
                            iv_msg_id     = 'ZTM_MSG'
                            iv_msg_number = '007'
                            iv_msg_text   = lv_error_msg.
                        RETURN.
                      ENDIF.

                      wa_autotransporte_data-notrans = ls_torrot-tor_id.
                      wa_autotransporte_data-permsct = lv_permisoSCT.
                      wa_autotransporte_data-numpermisosct = lv_numpermisosct.

                      SELECT name, tare_weight, max_length, max_width, max_height, orgcentre
                        FROM /scmb/restmshd
                        WHERE name EQ @ls_torite-res_id
                        INTO ( @DATA(lv_economico), @DATA(lv_tara), @DATA(lv_largo), @DATA(lv_ancho), @DATA(lv_alto), @DATA(lv_unidadorg) ).
                      ENDSELECT.

                      wa_autotransporte_data-economico = lv_economico.
                      wa_autotransporte_data-largo     = lv_largo.
                      wa_autotransporte_data-alto      = lv_alto.
                      wa_autotransporte_data-ancho     = lv_ancho.
                      wa_autotransporte_data-tara      = lv_tara.

                      CONDENSE: wa_autotransporte_data-largo, wa_autotransporte_data-alto, wa_autotransporte_data-ancho, wa_autotransporte_data-tara.

                      SELECT SINGLE valor2 INTO @DATA(lv_tipotr)
                        FROM zparamglob
                        WHERE programa = 'ZTM_CARTAPORTE'
                        AND parametro = '6'
                        AND valor1 EQ @lv_unidadorg.


                      CASE lv_tipotr.
                        WHEN 'CASA'.
                          wa_autotransporte_data-tipo = 'Casa'.
                        WHEN 'MULTIMODAL'.
                          wa_autotransporte_data-tipo = 'Multimodal'.
                        WHEN 'LINEA'.
                          wa_autotransporte_data-tipo = 'Linea'.
                        WHEN OTHERS.
                          wa_autotransporte_data-tipo = 'Linea'.
                      ENDCASE.

                      CLEAR: lv_economico, lv_tara, lv_largo, lv_ancho, lv_alto, lv_unidadorg, lv_tipotr.

*Se llena el nodo "Identificación Vehicular".
                      SELECT SINGLE qualivalue INTO @DATA(lv_configveh)
                        FROM /scmb/restmssk AS a
                        INNER JOIN /scmb/restmshd AS b
                        ON a~tmsresuuid = b~tmsresuid
                        WHERE b~name EQ @ls_torite-res_id
                        AND qualitype EQ 'CONFIGVEHICULAR'.
                      "IF sy-subrc NE '0' AND ls_torrot-tor_type NE 'Z102'.
*                      IF sy-subrc NE '0' AND lv_trexterno EQ ''.
*                        CONCATENATE 'El vehículo' ls_torite-res_id 'no cuenta con configuración vehicular. Favor de revisar los datos maestros del recurso' INTO lv_error_msg SEPARATED BY space.
*                        CALL METHOD lo_msg->add_message
*                          EXPORTING
*                            iv_msg_type   = /iwbep/cl_cos_logger=>error
*                            iv_msg_id     = 'ZTM_MSG'
*                            iv_msg_number = '008'
*                            iv_msg_text   = lv_error_msg.
*                        RETURN.
*                      ENDIF.

*Ini - Se redetermina el valor del campo "Configuración vehicular dependiendo del número de remolques que lleva el tráiler. - CAOG - 16.05.2025
                      DATA(lv_canrem) = REDUCE i( INIT i = 0 FOR wa IN lt_torite WHERE ( item_type EQ 'TRL' ) NEXT i = i + 1 ).

                      CASE lv_canrem.
                        WHEN 1.
                          lv_configveh = 'T3S2'.
                        WHEN 2.
                          lv_configveh = 'T3S2R4'.
                      ENDCASE.

                      IF lv_configveh EQ '' AND lv_trexterno EQ ''.
                        CONCATENATE 'El vehículo' ls_torite-res_id 'no cuenta con configuración vehicular. Favor de revisar los datos maestros del recurso' INTO lv_error_msg SEPARATED BY space.
                        CALL METHOD lo_msg->add_message
                          EXPORTING
                            iv_msg_type   = /iwbep/cl_cos_logger=>error
                            iv_msg_id     = 'ZTM_MSG'
                            iv_msg_number = '008'
                            iv_msg_text   = lv_error_msg.
                        RETURN.
                      ENDIF.

*Fin - Se redetermina el valor del campo "Configuración vehicular dependiendo del número de remolques que lleva el tráiler. - CAOG - 16.05.2025

                      SELECT SINGLE platenumber INTO @DATA(lv_placavm)
                        FROM /scmb/restmshd
                        WHERE name EQ @ls_torite-res_id.
                      "IF sy-subrc NE '0' AND ls_torrot-tor_type NE 'Z102'.
                      IF sy-subrc NE '0' AND lv_trexterno EQ ''.
                        CONCATENATE 'El vehículo' ls_torite-res_id 'no cuenta con placa capturada. Favor de revisar los datos maestros del recurso' INTO lv_error_msg SEPARATED BY space.
                        CALL METHOD lo_msg->add_message
                          EXPORTING
                            iv_msg_type   = /iwbep/cl_cos_logger=>error
                            iv_msg_id     = 'ZTM_MSG'
                            iv_msg_number = '009'
                            iv_msg_text   = lv_error_msg.
                        RETURN.
                      ENDIF.

                      SELECT SINGLE builddate INTO @DATA(lv_builddate)
                        FROM /scmb/restmshd
                        WHERE name EQ @ls_torite-res_id.
                      "IF sy-subrc NE '0' AND ls_torrot-tor_type NE 'Z102'.
                      IF sy-subrc NE '0' AND lv_trexterno EQ ''.
                        CONCATENATE 'El vehículo' ls_torite-res_id 'no cuenta con fecha de construcción. Favor de revisar los datos maestros del recurso' INTO lv_error_msg SEPARATED BY space.
                        CALL METHOD lo_msg->add_message
                          EXPORTING
                            iv_msg_type   = /iwbep/cl_cos_logger=>error
                            iv_msg_id     = 'ZTM_MSG'
                            iv_msg_number = '010'
                            iv_msg_text   = lv_error_msg.
                        RETURN.
                      ENDIF.

                      DATA(lv_aniomodelo) = lv_builddate(4).

                      wa_identificaveh_data-notrans = ls_torrot-tor_id.
                      wa_identificaveh_data-configvehicular = lv_configveh.
                      wa_identificaveh_data-placavm = lv_placavm.
                      wa_identificaveh_data-aniomodelovm = lv_aniomodelo.

                      APPEND wa_identificaveh_data TO wa_autotransporte_data-to_identificacionvehicular.
                      CLEAR wa_identificaveh_data.

*Se llena el nodo "Seguros".
                      SELECT SINGLE qualivalue INTO @DATA(lv_asegurarespciv)
                        FROM /scmb/restmssk AS a
                        INNER JOIN /scmb/restmshd AS b
                        ON a~tmsresuuid = b~tmsresuid
                        WHERE b~name EQ @ls_torite-res_id
                        AND qualitype EQ 'ASEGURARESPCIVIL'.
                      "IF sy-subrc NE '0' AND ls_torrot-tor_type NE 'Z102'.
                      IF sy-subrc NE '0' AND lv_trexterno EQ ''.
                        CONCATENATE 'El vehículo' ls_torite-res_id 'no tiene aseguradora de responsabilidad civil asignada.' INTO lv_error_msg SEPARATED BY space.
                        CALL METHOD lo_msg->add_message
                          EXPORTING
                            iv_msg_type   = /iwbep/cl_cos_logger=>error
                            iv_msg_id     = 'ZTM_MSG'
                            iv_msg_number = '011'
                            iv_msg_text   = lv_error_msg.
                        RETURN.
                      ENDIF.

                      SELECT SINGLE qualivalue INTO @DATA(lv_polizarespciv)
                        FROM /scmb/restmssk AS a
                        INNER JOIN /scmb/restmshd AS b
                        ON a~tmsresuuid = b~tmsresuid
                        WHERE b~name EQ @ls_torite-res_id
                        AND qualitype EQ 'POLIZARESPCIVIL'.
                      "IF sy-subrc NE '0' AND ls_torrot-tor_type NE 'Z102'.
                      IF sy-subrc NE '0' AND lv_trexterno EQ ''.
                        CONCATENATE 'El vehículo' ls_torite-res_id 'no tiene poliza de seguro de responsabilidad civil asignada.' INTO lv_error_msg SEPARATED BY space.
                        CALL METHOD lo_msg->add_message
                          EXPORTING
                            iv_msg_type   = /iwbep/cl_cos_logger=>error
                            iv_msg_id     = 'ZTM_MSG'
                            iv_msg_number = '012'
                            iv_msg_text   = lv_error_msg.
                        RETURN.
                      ENDIF.

                      wa_seguros_data-notrans = ls_torrot-tor_id.
                      wa_seguros_data-asegurarespcivil = lv_asegurarespciv.
                      wa_seguros_data-polizarespcivil = lv_polizarespciv.

*Se llena el nodo "Remolques".
                      LOOP AT  lt_torite INTO DATA(ls_torite_rem) WHERE item_type EQ 'TRL'.
                        wa_remolques_data-notrans = ls_torrot-tor_id.
                        wa_remolques_data-subtiporem = 'CTR004'.   "VALOR FIJO TEMPORAL SUBTIPO DE REMOLQUE
                        wa_remolques_data-placa = ls_torite_rem-platenumber.

                        SELECT name, tare_weight, max_length, max_width, max_height, orgcentre
                          FROM /scmb/restmshd
                          WHERE name EQ @ls_torite_rem-res_id
                          INTO ( @lv_economico, @lv_tara, @lv_largo, @lv_ancho, @lv_alto, @lv_unidadorg ).
                        ENDSELECT.

                        wa_remolques_data-economico = lv_economico.
                        wa_remolques_data-largo     = lv_largo.
                        wa_remolques_data-alto      = lv_alto.
                        wa_remolques_data-ancho     = lv_ancho.
                        wa_remolques_data-tara      = lv_tara.

                        CONDENSE: wa_remolques_data-largo, wa_remolques_data-alto, wa_remolques_data-ancho, wa_remolques_data-tara.

                        SELECT SINGLE valor2 INTO lv_tipotr
                          FROM zparamglob
                          WHERE programa = 'ZTM_CARTAPORTE'
                          AND parametro = '6'
                          AND valor1 EQ lv_unidadorg.


                        CASE lv_tipotr.
                          WHEN 'CASA'.
                            wa_remolques_data-tipo = 'Casa'.
                          WHEN 'MULTIMODAL'.
                            wa_remolques_data-tipo = 'Multimodal'.
                          WHEN 'LINEA'.
                            wa_remolques_data-tipo = 'Linea'.
                          WHEN OTHERS.
                            wa_remolques_data-tipo = 'Linea'.
                        ENDCASE.

                        APPEND wa_remolques_data TO wa_autotransporte_data-to_remolques.
                        CLEAR: ls_torite_rem, wa_remolques_data, lv_economico, lv_tara, lv_largo, lv_ancho, lv_alto, lv_unidadorg, lv_tipotr.
                      ENDLOOP.

                      APPEND wa_seguros_data TO wa_autotransporte_data-to_seguros.
                      CLEAR wa_seguros_data.

                      APPEND wa_autotransporte_data TO wa_mercancias_data-to_autotransporte.
                      CLEAR wa_autotransporte_data.
                    ENDLOOP.

                    APPEND wa_mercancias_data TO wa_complemento_data-to_mercancias.
                    CLEAR wa_mercancias_data.
                  ENDLOOP.

                  APPEND wa_complemento_data TO wa_de_comprobante-to_complemento.
                  CLEAR wa_complemento_data.

                  "Se llenan datos de addenda.
                  "***Addenda Cabecera***

                  DATA: lv_createdon TYPE c LENGTH 10.

                  wa_de_addendacab_data-notrans = ls_torrot-tor_id.

                  SELECT SINGLE smtp_addr INTO @DATA(lv_recipient)
                    FROM adr6 AS a
                    INNER JOIN usr21 AS b ON a~addrnumber EQ b~addrnumber
                    AND a~persnumber EQ b~persnumber
                    WHERE bname = @ls_torrot-changed_by.

                  wa_de_addendacab_data-usuario         = ls_torrot-changed_by.
                  wa_de_addendacab_data-correo          = lv_recipient.
                  wa_de_addendacab_data-clasetransporte = ls_torrot-tor_type.

                  CONVERT TIME STAMP ls_torrot-created_on TIME ZONE 'UTC-6' INTO DATE DATA(lv_dateon) TIME DATA(lv_timeon) DAYLIGHT SAVING TIME DATA(lv_dston).
                  CONCATENATE lv_dateon(4) '/' lv_dateon+4(2) '/' lv_dateon+6(2) INTO lv_createdon.
                  wa_de_addendacab_data-fechacreacion   = lv_createdon.

                  LOOP AT lt_entregas INTO ls_entregas.
                    SELECT SINGLE lfart INTO @lv_tiporeparto
                      FROM likp
                      WHERE vbeln EQ @ls_entregas-vbeln.

                    CASE lv_tiporeparto.
                      WHEN 'ZNL'.
                        lv_tiporeparto = 'Traslado'.
                      WHEN 'ZLF'.
                        lv_tiporeparto = 'Nacional'.
                      WHEN 'ZLFX'.
                        lv_tiporeparto = 'Exportación'.
                      WHEN 'ZCCU'.
                        lv_tiporeparto = 'Nacional'.
                      WHEN OTHERS.
                        lv_tiporeparto = 'Nacional'.
                    ENDCASE.
                  ENDLOOP.

                  "Extracción de nota para sellos
                  SELECT a~db_key AS dbkeytor,
                    b~host_key,
                    b~db_key AS dbkeyroot,
                    b~text_schema_id,
                    a~tor_id,
                    a~tor_cat,
                    c~parent_key AS parenttxt,
                    c~db_key AS dbkeytxt,
                    c~text_type,
                    c~language_code
                  FROM /scmtms/d_torrot AS a
                  LEFT OUTER JOIN /bobf/d_txcroot AS b ON a~db_key = b~host_key
                  LEFT OUTER JOIN /bobf/d_txctxt AS c ON b~db_key = c~parent_key
                  INTO TABLE @DATA(lt_text)
                  FOR ALL ENTRIES IN @lt_torite
                  WHERE a~db_key = @lt_torite-parent_key
                  AND c~text_type = 'SEALS'.

                  IF sy-subrc EQ 0.

                    READ TABLE lt_text INTO DATA(ls_text) WITH KEY text_schema_id = 'DEFAULT' text_type = 'SEALS'.

                    SELECT parent_key AS parentcon, text
                      FROM /bobf/d_txccon
                      WHERE parent_key EQ @ls_text-dbkeytxt
                      INTO TABLE @DATA(lt_text2).

                    IF sy-subrc EQ 0.
                      DATA: lv_sellos    TYPE string,
                            lv_linestext TYPE i.

                      DESCRIBE TABLE lt_text2 LINES lv_linestext.

                      IF lv_linestext EQ 1.
                        READ TABLE lt_text2 INTO DATA(ls_text2) WITH KEY parentcon = ls_text-dbkeytxt.
                        wa_de_addendacab_data-sellos = ls_text2-text.
                      ELSEIF lv_linestext GT 1.
                        LOOP AT lt_text2 INTO ls_text2.
                          CONCATENATE lv_sellos ls_text2-text INTO lv_sellos SEPARATED BY space.
                        ENDLOOP.
                        CONDENSE lv_sellos.
                        wa_de_addendacab_data-sellos = lv_sellos.
                      ENDIF.
                    ENDIF.
                  ENDIF.
                  CLEAR: ls_text, ls_text2, lv_sellos, lv_linestext.
                  REFRESH: lt_text, lt_text2.

                  "Extracción de nota para observaciones
                  SELECT a~db_key AS dbkeytor,
                    b~host_key,
                    b~db_key AS dbkeyroot,
                    b~text_schema_id,
                    a~tor_id,
                    a~tor_cat,
                    c~parent_key AS parenttxt,
                    c~db_key AS dbkeytxt,
                    c~text_type,
                    c~language_code
                  FROM /scmtms/d_torrot AS a
                  LEFT OUTER JOIN /bobf/d_txcroot AS b ON a~db_key = b~host_key
                  LEFT OUTER JOIN /bobf/d_txctxt AS c ON b~db_key = c~parent_key
                  INTO TABLE @lt_text
                  FOR ALL ENTRIES IN @lt_torite
                  WHERE a~db_key = @lt_torite-parent_key
                  AND c~text_type = 'OBSER'.

                  IF sy-subrc EQ 0.

                    READ TABLE lt_text INTO ls_text WITH KEY text_schema_id = 'DEFAULT' text_type = 'OBSER'.

                    SELECT parent_key AS parentcon, text
                      FROM /bobf/d_txccon
                      WHERE parent_key EQ @ls_text-dbkeytxt
                      INTO TABLE @lt_text2.

                    IF sy-subrc EQ 0.
                      DATA: lv_observ    TYPE string.

                      DESCRIBE TABLE lt_text2 LINES lv_linestext.

                      IF lv_linestext EQ 1.
                        READ TABLE lt_text2 INTO ls_text2 WITH KEY parentcon = ls_text-dbkeytxt.
                        wa_de_addendacab_data-observaciones = ls_text2-text.
                      ELSEIF lv_linestext GT 1.
                        LOOP AT lt_text2 INTO ls_text2.
                          CONCATENATE lv_observ ls_text2-text INTO lv_observ SEPARATED BY space.
                        ENDLOOP.
                        CONDENSE lv_observ.
                        wa_de_addendacab_data-observaciones = lv_observ.
                      ENDIF.
                    ENDIF.
                  ENDIF.
                  CLEAR: ls_text, ls_text2, lv_observ.
                  REFRESH: lt_text, lt_text2.

                  "Extracción de nota para talón
                  SELECT a~db_key AS dbkeytor,
                    b~host_key,
                    b~db_key AS dbkeyroot,
                    b~text_schema_id,
                    a~tor_id,
                    a~tor_cat,
                    c~parent_key AS parenttxt,
                    c~db_key AS dbkeytxt,
                    c~text_type,
                    c~language_code
                  FROM /scmtms/d_torrot AS a
                  LEFT OUTER JOIN /bobf/d_txcroot AS b ON a~db_key = b~host_key
                  LEFT OUTER JOIN /bobf/d_txctxt AS c ON b~db_key = c~parent_key
                  INTO TABLE @lt_text
                  FOR ALL ENTRIES IN @lt_torite
                  WHERE a~db_key = @lt_torite-parent_key
                  AND c~text_type = 'TALON'.

                  IF sy-subrc EQ 0.

                    READ TABLE lt_text INTO ls_text WITH KEY text_schema_id = 'DEFAULT' text_type = 'TALON'.

                    SELECT parent_key AS parentcon, text
                      FROM /bobf/d_txccon
                      WHERE parent_key EQ @ls_text-dbkeytxt
                      INTO TABLE @lt_text2.

                    IF sy-subrc EQ 0.
                      DATA: lv_talon    TYPE string.

                      DESCRIBE TABLE lt_text2 LINES lv_linestext.

                      IF lv_linestext EQ 1.
                        READ TABLE lt_text2 INTO ls_text2 WITH KEY parentcon = ls_text-dbkeytxt.
                        wa_de_addendacab_data-talon = ls_text2-text.
                      ELSEIF lv_linestext GT 1.
                        LOOP AT lt_text2 INTO ls_text2.
                          CONCATENATE lv_talon ls_text2-text INTO lv_talon SEPARATED BY space.
                        ENDLOOP.
                        CONDENSE lv_talon.
                        wa_de_addendacab_data-talon = lv_talon.
                      ENDIF.
                    ENDIF.
                  ENDIF.
                  CLEAR: ls_text, ls_text2, lv_talon.
                  REFRESH: lt_text, lt_text2.

                  "Extracción de nota para pallets
                  SELECT a~db_key AS dbkeytor,
                    b~host_key,
                    b~db_key AS dbkeyroot,
                    b~text_schema_id,
                    a~tor_id,
                    a~tor_cat,
                    c~parent_key AS parenttxt,
                    c~db_key AS dbkeytxt,
                    c~text_type,
                    c~language_code
                  FROM /scmtms/d_torrot AS a
                  LEFT OUTER JOIN /bobf/d_txcroot AS b ON a~db_key = b~host_key
                  LEFT OUTER JOIN /bobf/d_txctxt AS c ON b~db_key = c~parent_key
                  INTO TABLE @lt_text
                  FOR ALL ENTRIES IN @lt_torite
                  WHERE a~db_key = @lt_torite-parent_key
                  AND c~text_type = 'PALLE'.

                  IF sy-subrc EQ 0.

                    READ TABLE lt_text INTO ls_text WITH KEY text_schema_id = 'DEFAULT' text_type = 'PALLE'.

                    SELECT parent_key AS parentcon, text
                      FROM /bobf/d_txccon
                      WHERE parent_key EQ @ls_text-dbkeytxt
                      INTO TABLE @lt_text2.

                    IF sy-subrc EQ 0.
                      DATA: lv_pallet    TYPE string.

                      DESCRIBE TABLE lt_text2 LINES lv_linestext.

                      IF lv_linestext EQ 1.
                        READ TABLE lt_text2 INTO ls_text2 WITH KEY parentcon = ls_text-dbkeytxt.
                        wa_de_addendacab_data-pallets = ls_text2-text.
                      ELSEIF lv_linestext GT 1.
                        LOOP AT lt_text2 INTO ls_text2.
                          CONCATENATE lv_pallet ls_text2-text INTO lv_pallet SEPARATED BY space.
                        ENDLOOP.
                        CONDENSE lv_pallet.
                        wa_de_addendacab_data-pallets = lv_pallet.
                      ENDIF.
                    ENDIF.
                  ENDIF.
                  CLEAR: ls_text, ls_text2, lv_pallet.
                  REFRESH: lt_text, lt_text2.

                  "Extracción de nota para económico de la caja
                  SELECT a~db_key AS dbkeytor,
                    b~host_key,
                    b~db_key AS dbkeyroot,
                    b~text_schema_id,
                    a~tor_id,
                    a~tor_cat,
                    c~parent_key AS parenttxt,
                    c~db_key AS dbkeytxt,
                    c~text_type,
                    c~language_code
                  FROM /scmtms/d_torrot AS a
                  LEFT OUTER JOIN /bobf/d_txcroot AS b ON a~db_key = b~host_key
                  LEFT OUTER JOIN /bobf/d_txctxt AS c ON b~db_key = c~parent_key
                  INTO TABLE @lt_text
                  FOR ALL ENTRIES IN @lt_torite
                  WHERE a~db_key = @lt_torite-parent_key
                  AND c~text_type = 'ECCAJ'.

                  IF sy-subrc EQ 0.

                    READ TABLE lt_text INTO ls_text WITH KEY text_schema_id = 'DEFAULT' text_type = 'ECCAJ'.

                    SELECT parent_key AS parentcon, text
                      FROM /bobf/d_txccon
                      WHERE parent_key EQ @ls_text-dbkeytxt
                      INTO TABLE @lt_text2.

                    IF sy-subrc EQ 0.
                      DATA: lv_eccaj    TYPE string.

                      DESCRIBE TABLE lt_text2 LINES lv_linestext.

                      IF lv_linestext EQ 1.
                        READ TABLE lt_text2 INTO ls_text2 WITH KEY parentcon = ls_text-dbkeytxt.
                        wa_de_addendacab_data-eccaja = ls_text2-text.
                      ELSEIF lv_linestext GT 1.
                        LOOP AT lt_text2 INTO ls_text2.
                          CONCATENATE lv_eccaj ls_text2-text INTO lv_eccaj SEPARATED BY space.
                        ENDLOOP.
                        CONDENSE lv_eccaj.
                        wa_de_addendacab_data-eccaja = lv_eccaj.
                      ENDIF.
                    ENDIF.
                  ENDIF.
                  CLEAR: ls_text, ls_text2, lv_eccaj.
                  REFRESH: lt_text, lt_text2.

                  wa_de_addendacab_data-tiporeparto = lv_tiporeparto.
                  CLEAR lv_tiporeparto.

                  "***Addenda Textos***
                  SELECT a~db_key AS dbkeytor,
                    b~host_key,
                    b~db_key AS dbkeyroot,
                    b~text_schema_id,
                    a~tor_id,
                    a~tor_cat,
                    c~parent_key AS parenttxt,
                    c~db_key AS dbkeytxt,
                    c~text_type,
                    c~language_code,
                    d~text
                  FROM /scmtms/d_torrot AS a
                  LEFT OUTER JOIN /bobf/d_txcroot AS b ON a~db_key = b~host_key
                  LEFT OUTER JOIN /bobf/d_txctxt AS c ON b~db_key = c~parent_key
                  LEFT OUTER JOIN /bobf/d_txccon AS d ON c~db_key = d~parent_key
                  FOR ALL ENTRIES IN @lt_torite
                  WHERE a~db_key = @lt_torite-parent_key
                  AND text_schema_id EQ 'DEFAULT'
                  INTO TABLE @DATA(lt_text1).

                  IF sy-subrc EQ 0.

                    LOOP AT lt_text1 INTO DATA(ls_text1).
                      wa_textos_data-notrans = ls_torrot-tor_id.
                      wa_textos_data-cltexto = ls_text1-text_type.
                      wa_textos_data-idioma  = ls_text1-language_code.
                      wa_textos_data-texto   = ls_text1-text.

                      APPEND wa_textos_data TO wa_de_addendacab_data-to_addendatextos.
                      CLEAR: ls_text1, wa_textos_data.
                    ENDLOOP.

                    IF sy-subrc EQ 0.

                      DESCRIBE TABLE lt_text2 LINES lv_linestext.

                      IF lv_linestext EQ 1.
                        READ TABLE lt_text2 INTO ls_text2 WITH KEY parentcon = ls_text-dbkeytxt.
                        wa_de_addendacab_data-eccaja = ls_text2-text.
                      ELSEIF lv_linestext GT 1.
                        LOOP AT lt_text2 INTO ls_text2.
                          CONCATENATE lv_eccaj ls_text2-text INTO lv_eccaj SEPARATED BY space.
                        ENDLOOP.
                        CONDENSE lv_eccaj.
                        wa_de_addendacab_data-eccaja = lv_eccaj.
                      ENDIF.
                    ENDIF.
                  ENDIF.
                  CLEAR: ls_text1, ls_text2, lv_eccaj.
                  REFRESH: lt_text1, lt_text2.

                  "***Addenda Detalle***
                  LOOP AT lt_torite INTO ls_torite WHERE item_cat = 'PRD' AND dlv_prio NE ''.
                    wa_addendadet_data-notrans = ls_torrot-tor_id.
                    wa_addendadet_data-posicion = |{ ls_torite-item_id ALPHA = OUT }|.

                    APPEND wa_addendadet_data TO wa_de_addendacab_data-to_addendadet.
                    CLEAR: wa_addendadet_data, ls_torite.
                  ENDLOOP.
                  SORT wa_de_addendacab_data-to_addendadet ASCENDING BY posicion.

                  "***Se llena estructura de interlocutores comerciales***"
                  LOOP AT lt_torpty INTO ls_torpty.
                    wa_interlocutor_data-notrans = ls_torrot-tor_id.
                    wa_interlocutor_data-funcion = ls_torpty-party_rco.

                    SELECT SINGLE vtext INTO @wa_interlocutor_data-descfuncion
                      FROM tpart
                      WHERE parvw EQ @ls_torpty-party_rco
                      AND spras EQ 'S'.

                    wa_interlocutor_data-interlocutor = ls_torpty-party_id.

                    SELECT SINGLE name_org1 INTO @wa_interlocutor_data-razonsocial
                      FROM but000
                      WHERE partner EQ @ls_torpty-party_id.

                    SELECT SINGLE taxnum INTO @wa_interlocutor_data-nif
                      FROM dfkkbptaxnum
                      WHERE partner EQ @ls_torpty-party_id
                      AND taxtype EQ 'MX1'.

                    APPEND wa_interlocutor_data TO wa_de_addendacab_data-to_addendainterlo.
                    CLEAR: wa_interlocutor_data, ls_torpty.
                  ENDLOOP.

                  "***Se llena estructura de etapas***"
                  LOOP AT lt_stage INTO DATA(ls_stage).
                    wa_etapas_data-notrans    = ls_torrot-tor_id.
                    wa_etapas_data-secuencia  = ls_stage-seq_num.
                    wa_etapas_data-ubiorigen  = ls_stage-source_addr_det(180).
                    wa_etapas_data-dirorigen  = ls_stage-source_addr_det+180(75).
                    wa_etapas_data-ubidestino = ls_stage-dest_addr_det(180).
                    wa_etapas_data-dirdestino = ls_stage-dest_addr_det+180(75).

                    READ TABLE lt_torstp INTO DATA(ls_torstpstg) WITH KEY db_key = ls_stage-dest_stop_key.

                    SELECT SINGLE telf1, adrnr INTO ( @wa_etapas_data-telentrega, @DATA(lv_direcc) )
                      FROM kna1
                      WHERE kunnr EQ @ls_stage-dest_addr_det-location_id(10).

                    SELECT SINGLE time_zone INTO @DATA(lv_tz)
                      FROM adrc
                      WHERE addrnumber EQ @lv_direcc.

                    CONVERT TIME STAMP ls_torstpstg-appointment_start TIME ZONE lv_tz INTO DATE DATA(lv_fecita) TIME DATA(lv_hrcita) DAYLIGHT SAVING TIME DATA(lv_dst1).

                    CONCATENATE lv_fecita+6(2) '/' lv_fecita+4(2) '/' lv_fecita(4) INTO wa_etapas_data-fechacita.
                    CONCATENATE lv_hrcita(2) ':' lv_hrcita+2(2) ':' lv_hrcita+4(2) INTO wa_etapas_data-horacita.

                    READ TABLE lt_likp INTO ls_likp WITH KEY kunnr = ls_stage-dest_addr_det-location_id.

                    IF sy-subrc EQ 0.
                      wa_etapas_data-fechaentrega = ls_likp-lfdat.
                    ENDIF.

                    SELECT SINGLE smtp_addr INTO @wa_etapas_data-correoentrega
                      FROM adr6
                      WHERE addrnumber EQ @lv_direcc.

                    SELECT SINGLE btd_id INTO @DATA(lv_cita)
                      FROM /scmtms/d_torsdr
                      WHERE root_key EQ @ls_stage-root_key
                      AND parent_key EQ @ls_stage-stage_key
                      AND btd_tco EQ 'Z0001'.

                    wa_etapas_data-numcita = |{ lv_cita ALPHA = OUT }|.

                    APPEND wa_etapas_data TO wa_de_addendacab_data-to_addendaetapas.
                    CLEAR: ls_stage, wa_etapas_data, ls_torstpstg, lv_direcc, lv_fecita, lv_hrcita, wa_etapas_data, lv_tz, lv_cita.
                  ENDLOOP.

                  "*** Se llena estructura de Addenda Conductores ***
                  LOOP AT lt_torite_dri INTO ls_torite_dri.
                    DATA: lv_conductor TYPE /scmtms/d_torite-item_descr.

                    lv_conductor = ls_torite_dri-item_descr.
                    CONDENSE lv_conductor.
                    TRANSLATE lv_conductor TO UPPER CASE.

                    wa_conductor_data-notrans   = ls_torrot-tor_id.
                    wa_conductor_data-conductor = lv_conductor.

                    APPEND wa_conductor_data TO wa_de_addendacab_data-to_addendaconductor.
                    CLEAR: ls_torite_dri, lv_conductor, wa_conductor_data.
                  ENDLOOP.

                  APPEND wa_de_addendacab_data TO wa_de_comprobante-to_addendacab.
                  CLEAR: wa_de_addendacab_data, ls_torite.

                  "***Se llenan estructuras de remolques***"
                  SORT lt_torite_rmq ASCENDING BY item_id item_parent_key.
                  LOOP AT lt_torite_rmq INTO ls_torite_rmq WHERE item_type EQ 'TRL' OR item_type EQ 'TRUC'. " OR item_type EQ 'CONT'.
                    wa_de_contremolques_data-notrans     = ls_torrot-tor_id.
                    wa_de_contremolques_data-recurso     = ls_torite_rmq-res_id.
                    IF wa_de_contremolques_data-recurso EQ ''.
                      CASE ls_torite_rmq-item_type.
                        WHEN 'TRUC'.
                          wa_de_contremolques_data-recurso = 'TRACTO'.
                        WHEN 'TRL'.
                          wa_de_contremolques_data-recurso = 'REMOLQUE'.
                          "WHEN 'CONT'.
                          "  wa_de_contremolques_data-recurso = 'CONTENEDOR'.
                      ENDCASE.
                    ENDIF.
                    wa_de_contremolques_data-placa       = ls_torite_rmq-platenumber.
                    wa_de_contremolques_data-noremolque  = |{ ls_torite_rmq-item_id ALPHA = OUT }|.

                    SELECT SINGLE resourcename INTO @wa_de_contremolques_data-descrecurso
                      FROM /scmtms/cv_resourcebasicenh
                      WHERE resourceid EQ @ls_torite_rmq-res_id.

                    wa_de_contremolques_data-pesototal   = wa_de_contremolques_data-pesototal + ls_torite_rmq-gro_wei_val.
                    CONDENSE wa_de_contremolques_data-pesototal.

                    IF line_exists( lt_torite_rmq[ item_type = 'CONT' ] ).
                      IF ls_torite_rmq-item_type EQ 'TRL'.
                        READ TABLE lt_torite_rmq ASSIGNING FIELD-SYMBOL(<fs_trlparent>) WITH KEY item_type = 'CONT' item_parent_key = ls_torite_rmq-db_key.

                        IF <fs_trlparent> IS ASSIGNED.
                          wa_de_contcontenedor_data-notrans    = ls_torrot-tor_id.
                          wa_de_contcontenedor_data-recurso = <fs_trlparent>-res_id.
                          IF wa_de_contcontenedor_data-recurso EQ ''.
                            CASE <fs_trlparent>-item_type.
                              WHEN 'CONT'.
                                wa_de_contcontenedor_data-recurso = 'CONTENEDOR'.
                            ENDCASE.
                          ENDIF.
                          wa_de_contcontenedor_data-noremolque = <fs_trlparent>-platenumber.

                          LOOP AT lt_torite_det INTO ls_torite_det WHERE item_type EQ 'PRD' AND item_parent_key EQ <fs_trlparent>-db_key AND dlv_prio NE ''. "AND main_cargo_item EQ 'X'.
                            "LOOP AT lt_torite_det INTO ls_torite_det WHERE item_type EQ 'PRD' AND item_parent_key EQ ls_torite_rmq-db_key.   "Tomar en cuenta con contenedores
                            wa_contenedordet_data-notrans      = ls_torrot-tor_id.
                            wa_contenedordet_data-recurso      = <fs_trlparent>-res_id.
                            wa_contenedordet_data-material     = |{ ls_torite_det-product_id ALPHA = OUT }|.

                            SELECT SINGLE maktx INTO @wa_contenedordet_data-descmaterial
                              FROM makt
                              WHERE matnr EQ @ls_torite_det-product_id
                              AND spras EQ 'S'.

                            IF sy-subrc NE 0.
                              wa_contenedordet_data-descmaterial = ls_torite_det-item_descr.
                            ENDIF.

                            wa_contenedordet_data-cantidad     = ls_torite_det-qua_pcs_val.
                            IF  wa_contenedordet_data-cantidad EQ 0 OR  wa_contenedordet_data-cantidad EQ '0.00000000000000'.
                              wa_contenedordet_data-cantidad   = ls_torite_det-net_wei_val.
                            ENDIF.
                            CONDENSE wa_contenedordet_data-cantidad.
                            wa_contenedordet_data-unidad       = ls_torite_det-qua_pcs_uni.
                            IF wa_contenedordet_data-unidad EQ ''.
                              wa_contenedordet_data-unidad     = ls_torite_det-net_wei_uni.
                            ENDIF.
                            wa_contenedordet_data-peso         = ls_torite_det-gro_wei_val.    "El peso del material debe estar en kilos.

                            LOOP AT lt_torite INTO ls_torite_ent WHERE item_type EQ 'PRD' AND ( base_btd_tco EQ '73' OR base_btd_tco EQ '58' ) AND dlv_prio NE '' AND item_parent_key EQ <fs_trlparent>-db_key.
                              ls_entregas_rem-vbeln  = ls_torite_ent-base_btd_id+25(10).
                              ls_entregas_rem-parent = ls_torite_ent-item_parent_key.
                              ls_entregas_rem-posnr  = ls_torite_ent-base_btditem_id.
                              ls_entregas_rem-matnr  = ls_torite_ent-product_id.
                              ls_entregas_rem-baseky = ls_torite_ent-base_btd_key.
                              APPEND ls_entregas_rem TO lt_entregas_rem.

                              CLEAR: ls_torite_ent, ls_entregas_rem.
                            ENDLOOP.
                            SORT lt_entregas_rem BY vbeln parent ASCENDING.
                            DELETE ADJACENT DUPLICATES FROM lt_entregas_rem COMPARING vbeln parent matnr.

                            DESCRIBE TABLE lt_entregas_rem LINES DATA(lv_lines_entrem).


                            READ TABLE lt_entregas_rem INTO ls_entregas_rem WITH KEY parent = <fs_trlparent>-db_key matnr = ls_torite_det-product_id baseky = ls_torite_det-base_btd_key.
                            wa_contenedordet_data-entregas = ls_entregas_rem-vbeln.
                            CLEAR ls_entregas_rem.

                            APPEND wa_contenedordet_data TO wa_de_contcontenedor_data-to_contenedordet.
                            CLEAR: wa_contenedordet_data, ls_torite_det.
                          ENDLOOP.

                          APPEND wa_de_contcontenedor_data TO wa_de_contremolques_data-to_contcontenedor.
                          CLEAR: wa_de_contcontenedor_data.
                          UNASSIGN <fs_trlparent>.
                        ENDIF.
                      ENDIF.
                    ENDIF.

                    LOOP AT lt_torite_det INTO ls_torite_det WHERE item_type EQ 'PRD' AND item_parent_key EQ ls_torite_rmq-db_key AND trq_cat EQ '03'. "LOOP Para añadir ordenes de expedición
                      wa_remolquedet_data-notrans      = ls_torrot-tor_id.
                      wa_remolquedet_data-recurso      = ls_torite_rmq-res_id.
                      wa_remolquedet_data-material     = |{ ls_torite_det-product_id ALPHA = OUT }|.

                      SELECT SINGLE maktx INTO @wa_remolquedet_data-descmaterial
                        FROM makt
                        WHERE matnr EQ @ls_torite_det-product_id
                        AND spras EQ 'S'.

                      IF sy-subrc NE 0.
                        wa_remolquedet_data-descmaterial = ls_torite_det-item_descr.
                      ENDIF.

                      wa_remolquedet_data-cantidad     = ls_torite_det-qua_pcs_val.
                      IF  wa_remolquedet_data-cantidad EQ 0 OR  wa_remolquedet_data-cantidad EQ '0.00000000000000'.
                        wa_remolquedet_data-cantidad   = ls_torite_det-net_wei_val.
                      ENDIF.
                      CONDENSE wa_remolquedet_data-cantidad.
                      wa_remolquedet_data-unidad       = ls_torite_det-qua_pcs_uni.
                      IF wa_remolquedet_data-unidad EQ ''.
                        wa_remolquedet_data-unidad     = ls_torite_det-net_wei_uni.
                      ENDIF.
                      wa_remolquedet_data-peso         = ls_torite_det-gro_wei_val.    "El peso del material debe estar en kilos.
                      wa_remolquedet_data-entregas     = |{ ls_torite_det-trq_id ALPHA = OUT }|.

                      APPEND wa_remolquedet_data TO wa_de_contremolques_data-to_remolquedet.
                      CLEAR: wa_remolquedet_data, ls_torite_det.
                    ENDLOOP.

                    IF line_exists( lt_torite[ item_type = 'CONT' ] ).  "Si existe un contenedor dentro del viaje, se busca con dlv_prio.
                      LOOP AT lt_torite_det INTO ls_torite_det WHERE item_type EQ 'PRD' AND item_parent_key EQ ls_torite_rmq-db_key AND dlv_prio NE ''. "AND main_cargo_item EQ 'X'.
                        "LOOP AT lt_torite_det INTO ls_torite_det WHERE item_type EQ 'PRD' AND item_parent_key EQ ls_torite_rmq-db_key.   "Tomar en cuenta con contenedores
                        wa_remolquedet_data-notrans      = ls_torrot-tor_id.
                        wa_remolquedet_data-recurso      = ls_torite_rmq-res_id.
                        wa_remolquedet_data-material     = |{ ls_torite_det-product_id ALPHA = OUT }|.

                        SELECT SINGLE maktx INTO @wa_remolquedet_data-descmaterial
                          FROM makt
                          WHERE matnr EQ @ls_torite_det-product_id
                          AND spras EQ 'S'.

                        IF sy-subrc NE 0.
                          wa_remolquedet_data-descmaterial = ls_torite_det-item_descr.
                        ENDIF.

                        wa_remolquedet_data-cantidad     = ls_torite_det-qua_pcs_val.
                        IF  wa_remolquedet_data-cantidad EQ 0 OR  wa_remolquedet_data-cantidad EQ '0.00000000000000'.
                          wa_remolquedet_data-cantidad   = ls_torite_det-net_wei_val.
                        ENDIF.
                        CONDENSE wa_remolquedet_data-cantidad.
                        wa_remolquedet_data-unidad       = ls_torite_det-qua_pcs_uni.
                        IF wa_remolquedet_data-unidad EQ ''.
                          wa_remolquedet_data-unidad     = ls_torite_det-net_wei_uni.
                        ENDIF.
                        wa_remolquedet_data-peso         = ls_torite_det-gro_wei_val.    "El peso del material debe estar en kilos.

                        LOOP AT lt_torite INTO ls_torite_ent WHERE item_type EQ 'PRD' AND ( base_btd_tco EQ '73' OR base_btd_tco EQ '58' ) AND main_cargo_item EQ 'X' AND item_parent_key EQ ls_torite_rmq-db_key.
                          ls_entregas_rem-vbeln  = ls_torite_ent-base_btd_id+25(10).
                          ls_entregas_rem-parent = ls_torite_ent-item_parent_key.
                          ls_entregas_rem-posnr  = ls_torite_ent-base_btditem_id.
                          ls_entregas_rem-matnr  = ls_torite_ent-product_id.
                          ls_entregas_rem-baseky = ls_torite_ent-base_btd_key.
                          APPEND ls_entregas_rem TO lt_entregas_rem.

                          CLEAR: ls_torite_ent, ls_entregas_rem.
                        ENDLOOP.
                        SORT lt_entregas_rem BY vbeln parent ASCENDING.
                        DELETE ADJACENT DUPLICATES FROM lt_entregas_rem COMPARING vbeln parent matnr.

                        DESCRIBE TABLE lt_entregas_rem LINES lv_lines_entrem.


                        READ TABLE lt_entregas_rem INTO ls_entregas_rem WITH KEY parent = ls_torite_rmq-db_key matnr = ls_torite_det-product_id baseky = ls_torite_det-base_btd_key.
                        wa_remolquedet_data-entregas = ls_entregas_rem-vbeln.
                        CLEAR ls_entregas_rem.

                        APPEND wa_remolquedet_data TO wa_de_contremolques_data-to_remolquedet.
                        CLEAR: wa_remolquedet_data, ls_torite_det.
                      ENDLOOP.
                    ELSE.
                      LOOP AT lt_torite_det INTO ls_torite_det WHERE item_type EQ 'PRD' AND item_parent_key EQ ls_torite_rmq-db_key AND main_cargo_item EQ 'X'.
                        "LOOP AT lt_torite_det INTO ls_torite_det WHERE item_type EQ 'PRD' AND item_parent_key EQ ls_torite_rmq-db_key.   "Tomar en cuenta con contenedores
                        wa_remolquedet_data-notrans      = ls_torrot-tor_id.
                        wa_remolquedet_data-recurso      = ls_torite_rmq-res_id.
                        wa_remolquedet_data-material     = |{ ls_torite_det-product_id ALPHA = OUT }|.

                        SELECT SINGLE maktx INTO @wa_remolquedet_data-descmaterial
                          FROM makt
                          WHERE matnr EQ @ls_torite_det-product_id
                          AND spras EQ 'S'.

                        IF sy-subrc NE 0.
                          wa_remolquedet_data-descmaterial = ls_torite_det-item_descr.
                        ENDIF.

                        wa_remolquedet_data-cantidad     = ls_torite_det-qua_pcs_val.
                        IF  wa_remolquedet_data-cantidad EQ 0 OR  wa_remolquedet_data-cantidad EQ '0.00000000000000'.
                          wa_remolquedet_data-cantidad   = ls_torite_det-net_wei_val.
                        ENDIF.
                        CONDENSE wa_remolquedet_data-cantidad.
                        wa_remolquedet_data-unidad       = ls_torite_det-qua_pcs_uni.
                        IF wa_remolquedet_data-unidad EQ ''.
                          wa_remolquedet_data-unidad     = ls_torite_det-net_wei_uni.
                        ENDIF.
                        wa_remolquedet_data-peso         = ls_torite_det-gro_wei_val.    "El peso del material debe estar en kilos.

                        LOOP AT lt_torite INTO ls_torite_ent WHERE item_type EQ 'PRD' AND ( base_btd_tco EQ '73' OR base_btd_tco EQ '58' ) AND main_cargo_item EQ 'X' AND item_parent_key EQ ls_torite_rmq-db_key.
                          ls_entregas_rem-vbeln  = ls_torite_ent-base_btd_id+25(10).
                          ls_entregas_rem-parent = ls_torite_ent-item_parent_key.
                          ls_entregas_rem-posnr  = ls_torite_ent-base_btditem_id.
                          ls_entregas_rem-matnr  = ls_torite_ent-product_id.
                          ls_entregas_rem-baseky = ls_torite_ent-base_btd_key.
                          APPEND ls_entregas_rem TO lt_entregas_rem.

                          CLEAR: ls_torite_ent, ls_entregas_rem.
                        ENDLOOP.
                        SORT lt_entregas_rem BY vbeln parent ASCENDING.
                        DELETE ADJACENT DUPLICATES FROM lt_entregas_rem COMPARING vbeln parent matnr.

                        DESCRIBE TABLE lt_entregas_rem LINES lv_lines_entrem.

                        IF ls_torite_det-trq_cat EQ '03'.  "Orden de expedición
                          wa_remolquedet_data-entregas = |{ ls_torite_det-trq_id ALPHA = OUT }|.
                        ELSE.
                          READ TABLE lt_entregas_rem INTO ls_entregas_rem WITH KEY parent = ls_torite_rmq-db_key matnr = ls_torite_det-product_id baseky = ls_torite_det-base_btd_key.
                          wa_remolquedet_data-entregas = ls_entregas_rem-vbeln.
                        ENDIF.
                        CLEAR ls_entregas_rem.

                        APPEND wa_remolquedet_data TO wa_de_contremolques_data-to_remolquedet.
                        CLEAR: wa_remolquedet_data, ls_torite_det.
                      ENDLOOP.
                      IF lv_entexp EQ ''.
                        SORT wa_de_contremolques_data-to_remolquedet ASCENDING BY notrans recurso material cantidad.
                      ENDIF.
                      DELETE ADJACENT DUPLICATES FROM wa_de_contremolques_data-to_remolquedet COMPARING notrans recurso material cantidad entregas.
                    ENDIF.

                    APPEND wa_de_contremolques_data TO wa_de_comprobante-to_contremolques.
                    CLEAR: wa_de_contremolques_data.
                  ENDLOOP.
                  "***Fin llenado de Remolques***"

                ENDLOOP.

                APPEND wa_de_comprobante TO it_de_comprobante.
*                CLEAR: wa_de_comprobante.

              ENDLOOP.
            ENDIF.
          ENDLOOP.

          CLEAR: ls_torrot, wa_keytab.

        ELSE.
*Error: no existe el número de orden de flete consultado.
          CONCATENATE 'No existe la orden de flete' wa_keytab-value 'por favor valida que tu captura sea correcta.' INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZTM_MSG'
              iv_msg_number = '001'
              iv_msg_text   = lv_error_msg.
          RETURN.
        ENDIF.

*Se regresa la deep entity comprobante para dar salida en el response.
        CALL METHOD me->copy_data_to_ref
          EXPORTING
            is_data = wa_de_comprobante
          CHANGING
            cr_data = er_entity.

*Asignación de propiedades de navegación
        lo_tech_request ?= io_tech_request_context.
        DATA(lv_expand) = lo_tech_request->/iwbep/if_mgw_req_entityset~get_expand( ).
        TRANSLATE lv_expand TO UPPER CASE.
        SPLIT lv_expand AT ',' INTO TABLE et_expanded_tech_clauses.

        CLEAR wa_de_comprobante.

      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD ccpmonitorset_get_entityset.

*Declaración de tablas internas y work areas.
    DATA: gs_ccp_monitor TYPE zcl_ztm_cartaporte_mpc_ext=>ts_ccpmonitor,
          lt_torrot      TYPE STANDARD TABLE OF /scmtms/d_torrot,
          ls_torrot      TYPE /scmtms/d_torrot,
          lt_torexe      TYPE STANDARD TABLE OF /scmtms/d_torexe,
          ls_torexe      TYPE /scmtms/d_torexe,
          lt_torite      TYPE STANDARD TABLE OF /scmtms/d_torite,
          ls_torite      TYPE /scmtms/d_torite,
          lt_param       TYPE STANDARD TABLE OF zparamglob,
          ls_param       TYPE zparamglob,
          lt_timbre      TYPE STANDARD TABLE OF ztm_cfdiccp,
          ls_timbre      TYPE ztm_cfdiccp.

*Declaración de variables
    DATA: lv_fechaini  TYPE fkdat,
          lv_fechafin  TYPE fkdat,
          lv_fechaini1 TYPE string,
          lv_fechafin1 TYPE string,
          lv_diasdiff  TYPE t5a4a-dlydy,
          lv_diasdiff1 TYPE c LENGTH 6.

*Declaración de constantes

    CONSTANTS: lc_programa TYPE c LENGTH 14 VALUE 'ZTM_CARTAPORTE'.

*Cálculo de fechas para intervalo de búsqueda de facturas sin timbrar.
    SELECT SINGLE valor1
        INTO @lv_diasdiff1
        FROM zparamglob
        WHERE programa = @lc_programa
        AND parametro = '1'
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

    "Fecha fin de búsqueda es fecha actual mas un día (Revisar zona horaria del server)

    CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
      EXPORTING
        date      = sy-datum
        days      = 1
        months    = 0
        signum    = '+' " para calcular fechas anteriores
        years     = 0
      IMPORTING
        calc_date = lv_fechafin.

    "lv_fechafin = sy-datum.

    CONCATENATE lv_fechaini '000000' INTO lv_fechaini1.
    CONCATENATE lv_fechafin '235959' INTO lv_fechafin1.

*Busca los documentos de ordenes de flete generados en las fechas indicadas.

    SELECT * FROM /scmtms/d_torrot
      WHERE tor_cat EQ 'TO'
      AND tor_type IN ( 'Z100', 'Z101', 'Z102', 'Z104', 'Z105' )
      AND changed_on GE @lv_fechaini1
      AND changed_on LE @lv_fechafin1
      INTO TABLE @lt_torrot.

    SELECT * FROM /scmtms/d_torexe
      FOR ALL ENTRIES IN @lt_torrot
      WHERE parent_key EQ @lt_torrot-db_key
      INTO TABLE @lt_torexe.

    SELECT * FROM /scmtms/d_torite
      FOR ALL ENTRIES IN @lt_torrot
      WHERE parent_key EQ @lt_torrot-db_key
      INTO TABLE @lt_torite.

    SELECT * FROM ztm_cfdiccp
      FOR ALL ENTRIES IN @lt_torrot
      WHERE notrans EQ @lt_torrot-tor_id
      INTO TABLE @lt_timbre.

    LOOP AT lt_torrot INTO ls_torrot.

      SELECT SINGLE valor1 INTO @DATA(lv_stat)
        FROM zparamglob
        WHERE programa EQ @lc_programa
        AND parametro EQ '4'
        AND subparametro EQ '1'.

      READ TABLE lt_torexe INTO ls_torexe WITH KEY parent_key = ls_torrot-db_key event_code = lv_stat.

      IF sy-subrc EQ 0.
        READ TABLE lt_torite INTO ls_torite WITH KEY parent_key = ls_torrot-db_key item_type = 'PRD'. "item_id = '0000000010'.

        IF sy-subrc EQ 0 .
          SELECT SINGLE valor2 INTO @DATA(lv_serie)
            FROM zparamglob
            WHERE programa EQ @lc_programa
            AND parametro EQ '5'
            AND valor1 EQ @ls_torite-src_loc_idtrq.

          CONVERT TIME STAMP ls_torrot-changed_on TIME ZONE 'UTC-6' INTO DATE DATA(lv_date) TIME DATA(lv_time) DAYLIGHT SAVING TIME DATA(lv_dst).

          gs_ccp_monitor-serie = lv_serie.
          gs_ccp_monitor-folio = |{ ls_torrot-tor_id ALPHA = OUT }|.
          gs_ccp_monitor-anio  = lv_date(4).
          CONCATENATE lv_date+6(2) '/' lv_date+4(2) '/' lv_date(4) INTO gs_ccp_monitor-fechadocumento.
          gs_ccp_monitor-sociedad = 'LACN'.
          gs_ccp_monitor-tipodocumento = ls_torrot-tor_type.

          READ TABLE lt_timbre INTO ls_timbre WITH KEY notrans = ls_torrot-tor_id.

           IF ls_timbre-uuid EQ ''.
            IF ls_torrot-tor_type EQ 'Z104' OR ls_torrot-tor_type EQ 'Z105'.             "Si el documento de flete es de exportaciones
              IF ls_torrot-tspid EQ ''.                  "Solo se timbrarán los fletes con transporte propio (sin proveedor)
                APPEND gs_ccp_monitor TO et_entityset.
              ENDIF.
            ELSE.
              APPEND gs_ccp_monitor TO et_entityset.
            ENDIF.
          ENDIF.
          CLEAR ls_timbre.
        ENDIF.
        CLEAR: gs_ccp_monitor, ls_torite, lv_date, lv_serie.
      ENDIF.
      CLEAR: ls_torrot.
    ENDLOOP.

  ENDMETHOD.


  METHOD ccptimbrefiscals_create_entity.
    DATA: gs_timbrefiscal TYPE zcl_ztm_cartaporte_mpc_ext=>ts_ccptimbrefiscal,
          gs_cfdiccp      TYPE ztm_cfdiccp,
          lo_msg          TYPE REF TO /iwbep/if_message_container,
          lv_error_msg    TYPE bapi_msg,
          lv_torid        TYPE /scmtms/d_torrot-tor_id.

    CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
      RECEIVING
        ro_message_container = lo_msg.

*Lectura del request recibido en el método POST.
    TRY.
        CALL METHOD io_data_provider->read_entry_data
          IMPORTING
            es_data = gs_timbrefiscal.
      CATCH /iwbep/cx_mgw_tech_exception.
    ENDTRY.

*Convertimos el valor recibido en el tipo de dato de la variable gs_timbrefiscal-notrans al tipo de dato /sctms/d_torrot-tor_id para que los select a las tablas de TM sean correctos.
    lv_torid = |{ gs_timbrefiscal-notrans ALPHA = IN }|.

*Se valida que se mande un número de orden de transporte en el request.
    IF gs_timbrefiscal-notrans EQ ''.
      CONCATENATE 'Por favor indique un número de orden de transporte para poder guardar el folio fiscal' gs_timbrefiscal-uuid INTO lv_error_msg SEPARATED BY space.
      CALL METHOD lo_msg->add_message
        EXPORTING
          iv_msg_type   = /iwbep/cl_cos_logger=>error
          iv_msg_id     = 'ZTM_MSG'
          iv_msg_number = '001'
          iv_msg_text   = lv_error_msg.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ENDIF.

*Se valida si la orden de transporte existe.
    SELECT SINGLE tor_id INTO @DATA(lv_torid1)
      FROM /scmtms/d_torrot
      WHERE tor_id EQ @lv_torid.

    IF sy-subrc NE 0.
      CONCATENATE 'La orden de transporte' gs_timbrefiscal-notrans 'no existe en la base de datos, favor de verificar' INTO lv_error_msg SEPARATED BY space.
      CALL METHOD lo_msg->add_message
        EXPORTING
          iv_msg_type   = /iwbep/cl_cos_logger=>error
          iv_msg_id     = 'ZTM_MSG'
          iv_msg_number = '002'
          iv_msg_text   = lv_error_msg.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ENDIF.

*Se valida si el documento ya se encuentra timbrado antes de hacer el insert.
    SELECT SINGLE uuid, fectimbre INTO ( @DATA(lv_uuid), @DATA(lv_fectimbre) )
      FROM ztm_cfdiccp
      WHERE notrans EQ @lv_torid.

    IF lv_uuid NE '' AND lv_fectimbre NE ''.
      CONCATENATE 'La orden de transporte' gs_timbrefiscal-notrans 'ya se encuentra timbrada con el folio fiscal' lv_uuid 'de fecha' lv_fectimbre INTO lv_error_msg SEPARATED BY space.
      CALL METHOD lo_msg->add_message
        EXPORTING
          iv_msg_type   = /iwbep/cl_cos_logger=>error
          iv_msg_id     = 'ZTM_MSG'
          iv_msg_number = '003'
          iv_msg_text   = lv_error_msg.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ENDIF.

    gs_cfdiccp-mandt          = sy-mandt.
    gs_cfdiccp-serie          = gs_timbrefiscal-serie.
    gs_cfdiccp-notrans        = gs_timbrefiscal-notrans.
    gs_cfdiccp-uuid           = gs_timbrefiscal-uuid.
    gs_cfdiccp-fectimbre      = gs_timbrefiscal-fectimbre.
    gs_cfdiccp-rfcproovcertif = gs_timbrefiscal-rfcproovcertif.
    gs_cfdiccp-sellocfd       = gs_timbrefiscal-sellocfd.
    gs_cfdiccp-certificadosat = gs_timbrefiscal-certificadosat.
    gs_cfdiccp-sellosat       = gs_timbrefiscal-sellosat.
    gs_cfdiccp-cancelado      = gs_timbrefiscal-cancelado.
    gs_cfdiccp-xml            = gs_timbrefiscal-xml.
    gs_cfdiccp-pdf            = gs_timbrefiscal-pdf.
    gs_cfdiccp-status         = gs_timbrefiscal-status.
    gs_cfdiccp-noerror        = gs_timbrefiscal-noerror.
    gs_cfdiccp-mensaje        = gs_timbrefiscal-mensaje.

*Se valida si el PAC regresa los campos necesarios para el llenado de la tabla ztm_cfdiccp.
*    IF gs_cfdiccp-uuid EQ '' OR gs_cfdiccp-fectimbre EQ '' OR gs_cfdiccp-rfcproovcertif EQ '' OR gs_cfdiccp-sellocfd EQ '' OR gs_cfdiccp-certificadosat EQ '' OR gs_cfdiccp-sellosat EQ ''.
*
*      IF gs_cfdiccp-uuid EQ ''.
*        CONCATENATE 'Por favor indique el folio fiscal (UUID) para la orden de transporte' gs_timbrefiscal-notrans INTO lv_error_msg SEPARATED BY space.
*        CALL METHOD lo_msg->add_message
*          EXPORTING
*            iv_msg_type   = /iwbep/cl_cos_logger=>error
*            iv_msg_id     = 'ZTM_MSG'
*            iv_msg_number = '004'
*            iv_msg_text   = lv_error_msg.
*
*        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
*          EXPORTING
*            message_container = lo_msg.
*      ENDIF.
*
*      IF gs_cfdiccp-fectimbre EQ ''.
*        CONCATENATE 'Por favor indique la fecha de timbrado para la orden de transporte' gs_timbrefiscal-notrans INTO lv_error_msg SEPARATED BY space.
*        CALL METHOD lo_msg->add_message
*          EXPORTING
*            iv_msg_type   = /iwbep/cl_cos_logger=>error
*            iv_msg_id     = 'ZTM_MSG'
*            iv_msg_number = '005'
*            iv_msg_text   = lv_error_msg.
*
*        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
*          EXPORTING
*            message_container = lo_msg.
*      ENDIF.
*
*      IF gs_cfdiccp-rfcproovcertif EQ ''.
*        CONCATENATE 'Por favor indique el RFC del PAC para la orden de transporte' gs_timbrefiscal-notrans INTO lv_error_msg SEPARATED BY space.
*        CALL METHOD lo_msg->add_message
*          EXPORTING
*            iv_msg_type   = /iwbep/cl_cos_logger=>error
*            iv_msg_id     = 'ZTM_MSG'
*            iv_msg_number = '006'
*            iv_msg_text   = lv_error_msg.
*
*        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
*          EXPORTING
*            message_container = lo_msg.
*      ENDIF.
*
*      IF gs_cfdiccp-sellocfd EQ ''.
*        CONCATENATE 'Por favor indique el sello del CFD para la orden de transporte' gs_timbrefiscal-notrans INTO lv_error_msg SEPARATED BY space.
*        CALL METHOD lo_msg->add_message
*          EXPORTING
*            iv_msg_type   = /iwbep/cl_cos_logger=>error
*            iv_msg_id     = 'ZTM_MSG'
*            iv_msg_number = '007'
*            iv_msg_text   = lv_error_msg.
*
*        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
*          EXPORTING
*            message_container = lo_msg.
*      ENDIF.
*
*      IF gs_cfdiccp-certificadosat EQ ''.
*        CONCATENATE 'Por favor indique el número de certificado SAT para la orden de transporte' gs_timbrefiscal-notrans INTO lv_error_msg SEPARATED BY space.
*        CALL METHOD lo_msg->add_message
*          EXPORTING
*            iv_msg_type   = /iwbep/cl_cos_logger=>error
*            iv_msg_id     = 'ZTM_MSG'
*            iv_msg_number = '008'
*            iv_msg_text   = lv_error_msg.
*
*        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
*          EXPORTING
*            message_container = lo_msg.
*      ENDIF.
*
*      IF gs_cfdiccp-sellosat EQ ''.
*        CONCATENATE 'Por favor indique el sello SAT para la orden de transporte' gs_timbrefiscal-notrans INTO lv_error_msg SEPARATED BY space.
*        CALL METHOD lo_msg->add_message
*          EXPORTING
*            iv_msg_type   = /iwbep/cl_cos_logger=>error
*            iv_msg_id     = 'ZTM_MSG'
*            iv_msg_number = '009'
*            iv_msg_text   = lv_error_msg.
*
*        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
*          EXPORTING
*            message_container = lo_msg.
*      ENDIF.
*    ENDIF.

*Inserta el registro en la tabla ztm_cfdiccp.
    INSERT ztm_cfdiccp FROM gs_cfdiccp.
    CLEAR gs_cfdiccp.

*Se valida si el documento se insertó a la tabla ztm_cfdiccp correctamente.
    SELECT * FROM ztm_cfdiccp
      INTO CORRESPONDING FIELDS OF gs_cfdiccp
      WHERE notrans EQ lv_torid.
    ENDSELECT.

    IF sy-subrc EQ 0.
      MOVE-CORRESPONDING gs_cfdiccp TO er_entity.
    ENDIF.
  ENDMETHOD.


  METHOD ccptimbrefiscals_update_entity.
    DATA: gs_timbrefiscal TYPE zcl_ztm_cartaporte_mpc_ext=>ts_ccptimbrefiscal,
          gs_cfdiccp      TYPE ztm_cfdiccp,
          lo_msg          TYPE REF TO /iwbep/if_message_container,
          lv_error_msg    TYPE bapi_msg,
          lv_torid        TYPE /scmtms/d_torrot-tor_id.

    CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
      RECEIVING
        ro_message_container = lo_msg.

*Lectura del request recibido en el método POST.
    TRY.
        CALL METHOD io_data_provider->read_entry_data
          IMPORTING
            es_data = gs_timbrefiscal.
      CATCH /iwbep/cx_mgw_tech_exception.
    ENDTRY.

*Convertimos el valor recibido en el tipo de dato de la variable gs_timbrefiscal-notrans al tipo de dato /sctms/d_torrot-tor_id para que los select a las tablas de TM sean correctos.
    lv_torid = |{ gs_timbrefiscal-notrans ALPHA = IN }|.

*Se valida que se mande un número de orden de transporte en el request.
    IF gs_timbrefiscal-notrans EQ ''.
      CONCATENATE 'Por favor indique un número de orden de transporte para poder guardar el folio fiscal' gs_timbrefiscal-uuid INTO lv_error_msg SEPARATED BY space.
      CALL METHOD lo_msg->add_message
        EXPORTING
          iv_msg_type   = /iwbep/cl_cos_logger=>error
          iv_msg_id     = 'ZTM_MSG'
          iv_msg_number = '001'
          iv_msg_text   = lv_error_msg.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ENDIF.

*Se valida si la orden de transporte existe.
    SELECT SINGLE tor_id INTO @DATA(lv_torid1)
      FROM /scmtms/d_torrot
      WHERE tor_id EQ @lv_torid.

    IF sy-subrc NE 0.
      CONCATENATE 'La orden de transporte' gs_timbrefiscal-notrans 'no existe en la base de datos, favor de verificar' INTO lv_error_msg SEPARATED BY space.
      CALL METHOD lo_msg->add_message
        EXPORTING
          iv_msg_type   = /iwbep/cl_cos_logger=>error
          iv_msg_id     = 'ZTM_MSG'
          iv_msg_number = '002'
          iv_msg_text   = lv_error_msg.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ENDIF.

*Se valida si el documento ya se encuentra timbrado antes de hacer el insert.
    SELECT SINGLE uuid, fectimbre INTO ( @DATA(lv_uuid), @DATA(lv_fectimbre) )
      FROM ztm_cfdiccp
      WHERE notrans EQ @lv_torid.

*    IF lv_uuid NE '' AND lv_fectimbre NE '' AND .
*      CONCATENATE 'La orden de transporte' gs_timbrefiscal-notrans 'ya se encuentra timbrada con el folio fiscal' lv_uuid 'de fecha' lv_fectimbre INTO lv_error_msg SEPARATED BY space.
*      CALL METHOD lo_msg->add_message
*        EXPORTING
*          iv_msg_type   = /iwbep/cl_cos_logger=>error
*          iv_msg_id     = 'ZTM_MSG'
*          iv_msg_number = '003'
*          iv_msg_text   = lv_error_msg.
*
*      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
*        EXPORTING
*          message_container = lo_msg.

"    ELSE.
      gs_cfdiccp-mandt          = sy-mandt.
      gs_cfdiccp-serie          = gs_timbrefiscal-serie.
      gs_cfdiccp-notrans        = gs_timbrefiscal-notrans.
      gs_cfdiccp-uuid           = gs_timbrefiscal-uuid.
      gs_cfdiccp-fectimbre      = gs_timbrefiscal-fectimbre.
      gs_cfdiccp-rfcproovcertif = gs_timbrefiscal-rfcproovcertif.
      gs_cfdiccp-sellocfd       = gs_timbrefiscal-sellocfd.
      gs_cfdiccp-certificadosat = gs_timbrefiscal-certificadosat.
      gs_cfdiccp-sellosat       = gs_timbrefiscal-sellosat.
      gs_cfdiccp-cancelado      = gs_timbrefiscal-cancelado.
      gs_cfdiccp-xml            = gs_timbrefiscal-xml.
      gs_cfdiccp-pdf            = gs_timbrefiscal-pdf.
      gs_cfdiccp-status         = gs_timbrefiscal-status.
      gs_cfdiccp-noerror        = gs_timbrefiscal-noerror.
      gs_cfdiccp-mensaje        = gs_timbrefiscal-mensaje.

*Se valida si el PAC regresa los campos necesarios para el llenado de la tabla ztm_cfdiccp.
      IF gs_cfdiccp-uuid EQ '' OR gs_cfdiccp-fectimbre EQ '' OR gs_cfdiccp-rfcproovcertif EQ '' OR gs_cfdiccp-sellocfd EQ '' OR gs_cfdiccp-certificadosat EQ '' OR gs_cfdiccp-sellosat EQ ''.

        IF gs_cfdiccp-uuid EQ ''.
          CONCATENATE 'Por favor indique el folio fiscal (UUID) para la orden de transporte' gs_timbrefiscal-notrans INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZTM_MSG'
              iv_msg_number = '004'
              iv_msg_text   = lv_error_msg.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg.
        ENDIF.

        IF gs_cfdiccp-fectimbre EQ ''.
          CONCATENATE 'Por favor indique la fecha de timbrado para la orden de transporte' gs_timbrefiscal-notrans INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZTM_MSG'
              iv_msg_number = '005'
              iv_msg_text   = lv_error_msg.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg.
        ENDIF.

        IF gs_cfdiccp-rfcproovcertif EQ ''.
          CONCATENATE 'Por favor indique el RFC del PAC para la orden de transporte' gs_timbrefiscal-notrans INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZTM_MSG'
              iv_msg_number = '006'
              iv_msg_text   = lv_error_msg.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg.
        ENDIF.

        IF gs_cfdiccp-sellocfd EQ ''.
          CONCATENATE 'Por favor indique el sello del CFD para la orden de transporte' gs_timbrefiscal-notrans INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZTM_MSG'
              iv_msg_number = '007'
              iv_msg_text   = lv_error_msg.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg.
        ENDIF.

        IF gs_cfdiccp-certificadosat EQ ''.
          CONCATENATE 'Por favor indique el número de certificado SAT para la orden de transporte' gs_timbrefiscal-notrans INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZTM_MSG'
              iv_msg_number = '008'
              iv_msg_text   = lv_error_msg.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg.
        ENDIF.

        IF gs_cfdiccp-sellosat EQ ''.
          CONCATENATE 'Por favor indique el sello SAT para la orden de transporte' gs_timbrefiscal-notrans INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZTM_MSG'
              iv_msg_number = '009'
              iv_msg_text   = lv_error_msg.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg.
        ENDIF.
      ELSE.
*Actualiza el registro en la tabla ztm_cfdiccp.
        UPDATE ztm_cfdiccp FROM gs_cfdiccp.
        CLEAR gs_cfdiccp.
      ENDIF.
"    ENDIF.

*Se valida si el documento se insertó a la tabla ztm_cfdiccp correctamente.
    SELECT * FROM ztm_cfdiccp
      INTO CORRESPONDING FIELDS OF gs_cfdiccp
      WHERE notrans EQ lv_torid.
    ENDSELECT.

    IF sy-subrc EQ 0.
      MOVE-CORRESPONDING gs_cfdiccp TO er_entity.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
