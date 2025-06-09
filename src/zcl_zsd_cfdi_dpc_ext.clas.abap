class ZCL_ZSD_CFDI_DPC_EXT definition
  public
  inheriting from ZCL_ZSD_CFDI_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_EXPANDED_ENTITY
    redefinition .
protected section.

  methods ANULACIONESSET_GET_ENTITYSET
    redefinition .
  methods CFDIMONITORSET_GET_ENTITYSET
    redefinition .
  methods TIMBREFISCALSET_CREATE_ENTITY
    redefinition .
  methods TIMBREFISCALSET_UPDATE_ENTITY
    redefinition .
  methods REGENERAPDFSET_UPDATE_ENTITY
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZSD_CFDI_DPC_EXT IMPLEMENTATION.


  METHOD /iwbep/if_mgw_appl_srv_runtime~get_expanded_entity.
*Declaración de tablas y estructuras internas para los entity SET
    DATA: it_de_comprobante            TYPE TABLE OF zcl_zsd_cfdi_mpc=>ts_de_comprobante,
          wa_de_comprobante            TYPE zcl_zsd_cfdi_mpc=>ts_de_comprobante,
          wa_de_cfdirelacionado_data   TYPE zcl_zsd_cfdi_mpc=>ts_de_cfdirelacionado,
          wa_cfdirelacionados_data     TYPE zcl_zsd_cfdi_mpc=>ts_cfdirelacionados,
          wa_emisor_data               TYPE zcl_zsd_cfdi_mpc=>ts_emisor,
          wa_receptor_data             TYPE zcl_zsd_cfdi_mpc=>ts_receptor,
          wa_de_conceptos_data         TYPE zcl_zsd_cfdi_mpc=>ts_de_conceptos,
          wa_de_conceptoimpuestos_data TYPE zcl_zsd_cfdi_mpc=>ts_de_conceptoimpuestos,
          wa_conceptotraslados         TYPE zcl_zsd_cfdi_mpc=>ts_conceptotraslados,
          wa_de_impuestos_data         TYPE zcl_zsd_cfdi_mpc=>ts_de_impuestos,
          wa_traslados_data            TYPE zcl_zsd_cfdi_mpc=>ts_traslados,
          wa_de_complementocce_data    TYPE zcl_zsd_cfdi_mpc=>ts_de_complementocce,
          wa_de_cceemisor_data         TYPE zcl_zsd_cfdi_mpc=>ts_de_cceemisor,
          wa_ccedomicilioemisor_data   TYPE zcl_zsd_cfdi_mpc=>ts_ccedomicilioemisor,
          wa_de_ccereceptor_data       TYPE zcl_zsd_cfdi_mpc=>ts_de_ccereceptor,
          wa_ccedomicilioreceptor_data TYPE zcl_zsd_cfdi_mpc=>ts_ccedomicilioreceptor,
          wa_de_ccemercancias_data     TYPE zcl_zsd_cfdi_mpc=>ts_de_ccemercancias,
          wa_ccemercancia_data         TYPE zcl_zsd_cfdi_mpc=>ts_ccemercancia,
          wa_de_addendacabecera        TYPE zcl_zsd_cfdi_mpc=>ts_de_addendacabecera,
          wa_addendaposicion           TYPE zcl_zsd_cfdi_mpc=>ts_addendaposicion.

*Declaración de tablas y estructuras internas para vaciar info de tablas estándar
    DATA: lt_vbrk       TYPE STANDARD TABLE OF vbrk,
          ls_vbrk       TYPE vbrk,
          lt_vbrp       TYPE STANDARD TABLE OF vbrp,
          ls_vbrp       TYPE vbrp,
          lt_prcd       TYPE STANDARD TABLE OF prcd_elements,
          ls_prcd       TYPE prcd_elements,
          lt_adrc       TYPE STANDARD TABLE OF adrc,
          ls_adrc       TYPE adrc,
          lt_adremi     TYPE STANDARD TABLE OF adrc,
          ls_adremi     TYPE adrc,
          lt_likp       TYPE STANDARD TABLE OF likp,
          ls_likp       TYPE likp,
          lt_vbpa       TYPE STANDARD TABLE OF vbpa,
          ls_vbpa       TYPE vbpa,
          lt_makt       TYPE STANDARD TABLE OF makt,
          ls_makt       TYPE makt,
          lt_taxnum     TYPE STANDARD TABLE OF dfkkbptaxnum,
          ls_taxnum     TYPE dfkkbptaxnum,
          lt_procode    TYPE STANDARD TABLE OF /aif/t_mvmapval,
          ls_procode    TYPE /aif/t_mvmapval,
          ls_tipocambio TYPE bapi1093_0,
          lt_arancel    TYPE STANDARD TABLE OF /sapsll/maritc,
          ls_arancel    TYPE /sapsll/maritc,
          lt_uaduana    TYPE STANDARD TABLE OF /sapsll/clsnr,
          ls_uaduana    TYPE /sapsll/clsnr,
          lt_mean       TYPE STANDARD TABLE OF mean,
          ls_mean       TYPE mean,
          lt_vbkd       TYPE STANDARD TABLE OF vbkd,
          ls_vbkd       TYPE vbkd,
          lt_vbak       TYPE STANDARD TABLE OF vbak,
          ls_vbak       TYPE vbak,
          lt_knmt       TYPE STANDARD TABLE OF knmt,
          ls_knmt       TYPE knmt,
          lt_but0id     TYPE STANDARD TABLE OF but0id,
          ls_but0id     TYPE but0id,
          ls_headertext TYPE thead,
          lt_htlines    TYPE STANDARD TABLE OF tline,
          ls_htlines    TYPE tline,
          lt_fpcond     TYPE STANDARD TABLE OF zsd_cfdi_fpcond1,
          ls_fpcond     TYPE zsd_cfdi_fpcond1.

*Declaración de variables
    DATA: lv_vbeln_in   TYPE vbrk-vbeln,
          lv_vbeln_out  TYPE vbrk-vbeln,
          lv_entrega    TYPE likp-vbeln,
          lv_error_msg  TYPE bapi_msg,
          lv_folio      TYPE c LENGTH 10,
          lv_descr      TYPE c LENGTH 50,
          lv_rfctrans   TYPE stcd1,
          lv_nombretra  TYPE c LENGTH 80,
          lv_regfistra  TYPE c LENGTH 3,
          lv_date       TYPE d,
          lv_numtotmer  TYPE i,
          lv_desctotal  TYPE prcd_elements-kwert,
          lv_subtotal   TYPE prcd_elements-kwert,
          lv_descpos    TYPE prcd_elements-kwert,
          lv_iva        TYPE prcd_elements-kwert,
          lv_kdiff      TYPE prcd_elements-kdiff,
          lv_kdiffpos   TYPE prcd_elements-kdiff,
          lv_namere     TYPE c LENGTH 163,
          lv_cekilos    TYPE ekpo-menge,
          lv_htlines    TYPE thead-tdtxtlines,
          lv_textname   TYPE thead-tdname,
          lv_ampdescr   TYPE string,
          lv_pneto      TYPE vbrp-ntgew,
          lv_pbruto     TYPE vbrp-brgew,
          lv_pnetog     TYPE vbrp-ntgew,
          lv_pbrutog    TYPE vbrp-brgew,
          lv_nodoparte  TYPE c LENGTH 1,
          lv_checkparte TYPE c LENGTH 1,
          lv_clfiscal   TYPE prcd_elements-mwsk1,
          lo_msg        TYPE REF TO /iwbep/if_message_container.

*Declaración de constantes
    CONSTANTS: abap_true   TYPE c LENGTH 1  VALUE 'X',
               abap_false  TYPE c LENGTH 1  VALUE '',
               lc_programa TYPE c LENGTH 13 VALUE 'ZCFDI_MONITOR'.

    DATA: lo_tech_request TYPE REF TO /iwbep/cl_mgw_request.

*Instancia a objeto para contenedor de mensajes de error.
    CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
      RECEIVING
        ro_message_container = lo_msg.

*Lectura de tabla de valores procedentes de la ejecución de la API. Aquí se recibe el valor desde la URL.
    READ TABLE it_key_tab INTO DATA(wa_keytab) INDEX 1.

    IF sy-subrc EQ 0.
*Convertimos el valor recibido en el tipo de dato de la variable lv_vbeln y a partir de este valor se comienzan a hacer las consultas para la orden de flete.
      lv_vbeln_in = |{ wa_keytab-value ALPHA = IN }|.
      lv_vbeln_out = |{ wa_keytab-value ALPHA = OUT }|.

      IF iv_entity_name EQ 'Comprobante'.
*Traemos los datos de la tabla de cabecera de facturas
        SELECT * FROM vbrk
          INTO TABLE lt_vbrk
          WHERE vbeln = lv_vbeln_in.

        IF sy-subrc EQ 0.

          LOOP AT lt_vbrk INTO ls_vbrk.
*Validamos que el documento esté contabilizado, si no es así se manda error.
            IF ls_vbrk-xblnr EQ ''.
              CONCATENATE 'La factura' lv_vbeln_out 'no ha sido contabilizada. Favor de validar' INTO lv_error_msg SEPARATED BY space.
              CALL METHOD lo_msg->add_message
                EXPORTING
                  iv_msg_type   = /iwbep/cl_cos_logger=>error
                  iv_msg_id     = 'ZSD_MSG'
                  iv_msg_number = '003'
                  iv_msg_text   = lv_error_msg.
              RETURN.
            ENDIF.

*Validamos que el documento esté contabilizado, si no es así se manda error.
            IF ls_vbrk-fksto NE ''.
              CONCATENATE 'La factura' lv_vbeln_out 'fue anulada' INTO lv_error_msg SEPARATED BY space.
              CALL METHOD lo_msg->add_message
                EXPORTING
                  iv_msg_type   = /iwbep/cl_cos_logger=>error
                  iv_msg_id     = 'ZSD_MSG'
                  iv_msg_number = '004'
                  iv_msg_text   = lv_error_msg.
              RETURN.
            ENDIF.

*Si la factura existe, traemos los datos de posición de la tabla de detalle.
            SELECT * FROM vbrp
              INTO TABLE lt_vbrp
              WHERE vbeln EQ ls_vbrk-vbeln.

            "LOOP AT lt_vbrp INTO ls_vbrp WHERE posnr EQ '000010'.
            READ TABLE lt_vbrp INTO ls_vbrp INDEX 1.
            DATA(lv_vstel)   = ls_vbrp-vstel.
            DATA(lv_pedido)  = ls_vbrp-aubel.
            DATA(lv_entrega1) = ls_vbrp-vgbel.
            DATA(lv_vbtyp)   = ls_vbrk-vbtyp.
            DATA(lv_vtweg)   = ls_vbrk-vtweg.
            DATA(lv_werks)   = ls_vbrp-werks.
            "ENDLOOP.
            CLEAR ls_vbrp.

*Obtenemos fracciones arancelarias.
            SELECT * FROM /sapsll/maritc
              INTO TABLE lt_arancel
              FOR ALL ENTRIES IN lt_vbrp
              WHERE matnr EQ lt_vbrp-matnr
              AND stcts EQ 'ZSD_FRARAN'
              AND datbi EQ '99991231'.

*Unidad de medida relacionada a la fracción arancelaria.
            SELECT * FROM /sapsll/clsnr
              INTO TABLE lt_uaduana
              FOR ALL ENTRIES IN lt_arancel
              WHERE ccngn EQ lt_arancel-ccngn
              AND nosct EQ 'ZSD_FRARAN'
              AND datbi EQ '99991231'.

*Traemos los datos de interlocutores.
            SELECT * FROM vbpa
              INTO TABLE lt_vbpa
              WHERE vbeln EQ ls_vbrk-vbeln.

            SORT lt_vbpa ASCENDING BY kunnr.
            DELETE ADJACENT DUPLICATES FROM lt_vbpa.

*Traemos datos de rfc
            SELECT * FROM dfkkbptaxnum
              INTO TABLE lt_taxnum
              FOR ALL ENTRIES IN lt_vbpa
              WHERE partner EQ lt_vbpa-kunnr.

*Traemos los datos de dirección de los interlocutores.
            SELECT * FROM adrc
              INTO TABLE lt_adrc
              FOR ALL ENTRIES IN lt_vbpa
              WHERE addrnumber EQ lt_vbpa-adrnr.

*Traemos los datos de dirección del emisor.
            SELECT SINGLE adrnr INTO @DATA(lv_adremisor)
              FROM t001
              WHERE bukrs EQ @ls_vbrk-bukrs.

            SELECT * FROM adrc
              INTO TABLE lt_adremi
              WHERE addrnumber EQ lv_adremisor.

*Traemos los RFC del responsable de factura.
            LOOP AT lt_vbpa INTO ls_vbpa WHERE parvw EQ 'RE'.
              SELECT SINGLE xcpdk, kunnr INTO ( @DATA(lv_cpd), @DATA(lv_kunre) )
                FROM kna1
                WHERE kunnr EQ @ls_vbpa-kunnr.

              DATA(lv_adrnre) = ls_vbpa-adrnr.
            ENDLOOP.
            CLEAR ls_vbpa.

*Si el cliente es CPD (clíente de única vez) se extrae el RFC de la tabla VBPA3, de lo contrario se extrae de la tabla standar de DM.
            IF lv_cpd EQ ''.
              SELECT SINGLE taxnum INTO @DATA(lv_taxnumre)
                FROM dfkkbptaxnum
                WHERE partner EQ @lv_kunre
                AND taxtype EQ 'MX1'.
            ELSEIF lv_cpd EQ 'X'.
              SELECT SINGLE stcd1 INTO @lv_taxnumre
                FROM vbpa3
                WHERE vbeln EQ @ls_vbrk-vbeln
                AND parvw EQ 'RE'.
              IF sy-subrc NE 0 OR lv_taxnumre EQ ''.
                SELECT SINGLE taxnum INTO @lv_taxnumre
                  FROM dfkkbptaxnum
                  WHERE partner EQ @lv_kunre
                  AND taxtype EQ 'MX1'.
              ENDIF.
            ENDIF.

            IF lv_taxnumre EQ 'XEXX010101000'.
              SELECT SINGLE taxnum INTO @DATA(lv_numregid)
               FROM dfkkbptaxnum
               WHERE partner EQ @lv_kunre
               AND taxtype NE 'MX1'.
            ENDIF.

            LOOP AT lt_vbrp INTO ls_vbrp.

*Se obtiene la cadena del cliente.
              SELECT SINGLE kvgr1 INTO @DATA(lv_cadena)
                FROM knvv
                WHERE kunnr EQ @lv_kunre
                AND vkorg EQ @ls_vbrk-vkorg
                AND vtweg EQ @ls_vbrk-vtweg
                AND spart EQ @ls_vbrk-spart.

*Traemos descripciones de materiales.
              ls_makt-mandt = sy-mandt.
              ls_makt-matnr = ls_vbrp-matnr.
              LOOP AT lt_vbpa INTO ls_vbpa WHERE parvw EQ 'AG'.
                SELECT SINGLE spras INTO @DATA(lv_spras)
                  FROM kna1
                  WHERE kunnr EQ @ls_vbpa-kunnr.
              ENDLOOP.
              SELECT SINGLE maktx maktg INTO ( ls_makt-maktx, ls_makt-maktg )
                FROM makt
                WHERE matnr EQ ls_vbrp-matnr
                AND spras EQ lv_spras.

              ls_makt-spras = lv_spras.

              APPEND ls_makt TO lt_makt.

            ENDLOOP.

*Traemos las condiciones de precio de la factura.
            SELECT * FROM prcd_elements
              INTO TABLE lt_prcd
              WHERE knumv EQ ls_vbrk-knumv.

*Si el documento a timbrar es una NCR o NCA, traemos el documento relacionado.

            IF ls_vbrk-vbtyp EQ 'O' OR ls_vbrk-vbtyp EQ 'P'.
              SELECT SINGLE vbelv INTO @DATA(lv_referencia)
                FROM vbfa
                WHERE vbeln EQ @ls_vbrk-vbeln
                AND vbtyp_v EQ 'M'.

              IF sy-subrc NE 0.
                SELECT SINGLE vbelv INTO @DATA(lv_solncr)
                  FROM vbfa
                  WHERE vbeln EQ @ls_vbrk-vbeln
                  AND vbtyp_v EQ 'K'.

                SELECT SINGLE vbelv INTO @lv_referencia
                  FROM vbfa
                  WHERE vbeln EQ @lv_solncr
                  AND vbtyp_v EQ 'M'.
              ENDIF.

              SELECT SINGLE serie, nodocu, uuid INTO ( @DATA(lv_serierel), @DATA(lv_foliorel), @DATA(lv_uuidrel) )
                FROM zsd_cfdi_return
                WHERE nodocu EQ @lv_referencia.

              SELECT SINGLE zlsch, zterm INTO ( @DATA(lv_fpref), @DATA(lv_mpref) )
                FROM vbrk
                WHERE vbeln EQ @lv_referencia.

*             Se comenta este select por que se crea nueva tabla y trx para que el usuario haga el mantenimiento de MP y FP en NCR por RFC de cliente
*              SELECT valor1 FROM zparamglob
*                INTO TABLE @DATA(lt_cadenascondona)
*                WHERE programa EQ @lc_programa
*                AND parametro EQ '6'.

*Lectura de tabla ZSD_CFDI_FPCOND1 para traer uso de cfdi, mp y fp por RFC para notas de crédito.
              SELECT * FROM zsd_cfdi_fpcond1
                INTO TABLE @lt_fpcond.
            ENDIF.

*Se busca si la factura a timbrar tiene relación con alguna factura de anticipo.
            IF ls_vbrk-fkart EQ 'ZF2'.
              SELECT SINGLE vbelv INTO @DATA(lv_pedant)
                FROM vbfa
                WHERE vbeln EQ @ls_vbrk-vbeln
                AND vbtyp_v EQ 'C'.

              SELECT SINGLE vbelv INTO @DATA(lv_facant)
                FROM vbfa
                WHERE vbeln EQ @lv_pedant
                AND vbtyp_v EQ 'M'.

              IF lv_facant NE ''.
                SELECT SINGLE fkart INTO @DATA(lv_clfacant)
                  FROM vbrk
                  WHERE vbeln EQ @lv_facant.

                IF lv_clfacant EQ 'ZANT'.
                  SELECT SINGLE serie, nodocu, uuid INTO ( @lv_serierel, @lv_foliorel, @lv_uuidrel )
                    FROM zsd_cfdi_return
                    WHERE nodocu EQ @lv_facant.
                ENDIF.
              ENDIF.
            ENDIF.

            IF ls_vbrk-fkart EQ 'ZNAN'.
              SELECT SINGLE vbelv INTO @lv_pedant
                FROM vbfa
                WHERE vbeln EQ @ls_vbrk-vbeln
                AND vbtyp_v EQ 'K'.

              SELECT SINGLE vbelv INTO @lv_facant
                FROM vbfa
                WHERE vbeln EQ @lv_pedant
                AND vbtyp_v EQ 'M'.

              IF lv_facant NE ''.
                SELECT SINGLE fkart INTO @lv_clfacant
                  FROM vbrk
                  WHERE vbeln EQ @lv_facant.

                IF lv_clfacant EQ 'ZF2'.
                  SELECT SINGLE serie, nodocu, uuid INTO ( @lv_serierel, @lv_foliorel, @lv_uuidrel )
                    FROM zsd_cfdi_return
                    WHERE nodocu EQ @lv_facant.
                ENDIF.
              ENDIF.
            ENDIF.

*Se busca si la factura tiene facturas previas, si es así se obtiene el UUID para el nodo tipo relación.
*            IF ls_vbrk-vbtyp EQ 'M'.
*              SELECT SINGLE vbelv INTO @lv_referencia
*               FROM vbfa
*               WHERE vbeln EQ @ls_vbrk-vbeln
*               AND vbtyp_v EQ 'M'.
*
*              SELECT SINGLE uuid INTO @lv_uuidrel
*               FROM zsd_cfdi_return
*               WHERE nodocu EQ @lv_referencia.
*
*              IF lv_uuidrel EQ ''.
*                SELECT SINGLE vbelv INTO @DATA(lv_pedreferencia)
*                  FROM vbfa
*                  WHERE vbeln EQ @ls_vbrk-vbeln
*                  AND vbtyp_v EQ 'C'.
*
*                SELECT * FROM vbfa
*                  INTO TABLE @DATA(lt_vbfa_m)
*                  WHERE vbelv EQ @lv_pedreferencia
*                  AND vbtyp_n EQ 'M'.
*
*                SORT lt_vbfa_m DESCENDING BY vbeln.
*
*                READ TABLE lt_vbfa_m INDEX 2 INTO DATA(ls_vbfa_m).
*
*                SELECT SINGLE uuid INTO @lv_uuidrel
*                  FROM zsd_cfdi_return
*                  WHERE nodocu EQ @ls_vbfa_m-vbeln.
*              ENDIF.
*            ENDIF.

*Obtenemos tabla de cabecera del pedido
            SELECT * FROM vbak
              INTO TABLE lt_vbak
              WHERE vbeln EQ lv_pedido.

*Obtenemos tabla de datos comerciales.
            SELECT * FROM vbkd
              INTO TABLE lt_vbkd
              WHERE vbeln EQ lv_pedido
              AND posnr EQ '000000'.

*Obtenemos tabla de códigos EAN
            SELECT * FROM mean
              INTO TABLE lt_mean
              FOR ALL ENTRIES IN lt_vbrp
              WHERE matnr EQ lt_vbrp-matnr.

*Obtenemos tabla de registro info cliente-material
            SELECT * FROM knmt
              INTO TABLE lt_knmt
              FOR ALL ENTRIES IN lt_vbrp
              WHERE matnr EQ lt_vbrp-matnr.

*Obtenemos números de identificación de los clientes.
            SELECT * FROM but0id
              INTO TABLE lt_but0id
              FOR ALL ENTRIES IN lt_vbpa
              WHERE partner EQ lt_vbpa-kunnr.

*Traemos el valor para la varible lv_nodoparte que indicará si se debe armar o no la info correspondiente a dicho nodo a nivel concepto.
            SELECT SINGLE valor1 INTO @lv_nodoparte
              FROM zparamglob
              WHERE programa EQ @lc_programa
              AND parametro EQ '8'
              AND subparametro EQ '1'.

*Comienza armado del response.
*** Datos de comprobante ***
            "Documento
            wa_de_comprobante-nodocu = ls_vbrk-vbeln.

            "Versión de CFDI.
            SELECT SINGLE valor1 INTO wa_de_comprobante-version
              FROM zparamglob
              WHERE programa EQ lc_programa
              AND parametro EQ '3'
              AND subparametro EQ '1'.

            "Serie
            SELECT SINGLE valor5 INTO wa_de_comprobante-serie
              FROM zparamglob
              WHERE programa EQ lc_programa
              AND parametro EQ '2'
              AND valor1 EQ lv_werks
              AND valor2 EQ lv_vtweg
              AND valor3 EQ lv_vbtyp.

            "Folio
            wa_de_comprobante-folio = ls_vbrk-vbeln.

            "Fecha
            CONCATENATE ls_vbrk-erdat(4) '-' ls_vbrk-erdat+4(2) '-' ls_vbrk-erdat+6(2) 'T' ls_vbrk-erzet(2) ':' ls_vbrk-erzet+2(2) ':' ls_vbrk-erzet+4(2)  INTO wa_de_comprobante-fecha.

            "Método de pago
            IF ls_vbrk-vbtyp EQ 'M' OR ls_vbrk-vbtyp EQ 'P'.
              IF ls_vbrk-zterm EQ 'LC00' OR ls_vbrk-zterm EQ 'NT00'.
                wa_de_comprobante-metodopago = 'PUE'.
              ELSE.
                wa_de_comprobante-metodopago = 'PPD'.
              ENDIF.
            ELSEIF ls_vbrk-vbtyp EQ 'O' OR ls_vbrk-vbtyp EQ 'H'.
              IF lv_mpref EQ 'LC00' OR lv_mpref EQ 'NT00'.
                wa_de_comprobante-metodopago = 'PUE'.
              ENDIF.
            ENDIF.

            "Forma de Pago
            IF ls_vbrk-vbtyp EQ 'M' OR ls_vbrk-vbtyp EQ 'P'.
              IF ( ls_vbrk-zlsch EQ '' OR ls_vbrk-zlsch EQ 'Z' ) AND wa_de_comprobante-metodopago EQ 'PPD'.
                wa_de_comprobante-formapago = '99'.
              ELSE.
                SELECT SINGLE valor2 INTO wa_de_comprobante-formapago
                  FROM zparamglob
                  WHERE programa EQ lc_programa
                  AND parametro EQ '4'
                  AND valor1 EQ ls_vbrk-zlsch.
              ENDIF.
            ELSEIF ls_vbrk-vbtyp EQ 'O' OR ls_vbrk-vbtyp EQ 'H'.
**Se valida si la cadena de la ncr pide forma de pago 15
*              LOOP AT lt_cadenascondona INTO DATA(ls_cadenascondona).
*                IF lv_cadena EQ ls_cadenascondona-valor1.
*                  DATA(lv_aux) = 'X'.
*                ENDIF.
*              ENDLOOP.
*              IF lv_aux EQ 'X'.
*                wa_de_comprobante-formapago = '15'.
*                wa_de_comprobante-metodopago = 'PUE'.
*              ELSE.

              LOOP AT lt_fpcond INTO ls_fpcond WHERE rfc EQ lv_taxnumre.
                wa_de_comprobante-formapago  = ls_fpcond-fpago.
                wa_de_comprobante-metodopago = ls_fpcond-mpago.
                CLEAR: ls_fpcond.
              ENDLOOP.
              IF wa_de_comprobante-formapago = '' AND wa_de_comprobante-metodopago = ''.
*Si ni se encuentra la cadena en la lista de condonación, entonces se busca las condiciones de pago de la factura de referencia para determinar la forma de pago y método de pago de la NCR que serán las mismas que las de su factura origen
                IF lv_mpref EQ 'LC00' OR lv_mpref EQ 'NT00'.
                  SELECT SINGLE valor2 INTO wa_de_comprobante-formapago
                    FROM zparamglob
                    WHERE programa EQ lc_programa
                    AND parametro EQ '4'
                    AND valor1 EQ lv_fpref.
                  wa_de_comprobante-metodopago = 'PUE'.
                ELSE.
*Si la condición de pago de la factura de referencia no es de contado, entonces la NCR tendrá el método de pago PPD y forma de pago 99
                  wa_de_comprobante-formapago = '99'.
                  wa_de_comprobante-metodopago = 'PPD'.
                ENDIF.
              ENDIF.
            ENDIF.
*            CLEAR lv_aux.
*Si el documento es una nota de crédito por anticipo (ZNAN), entonces la forma de pago es 30 y el método de pago PUE.
            IF ls_vbrk-fkart EQ 'ZNAN'.
              wa_de_comprobante-formapago  = '30'.
              wa_de_comprobante-metodopago = 'PUE'.
            ENDIF.

            "Exportación
            IF lv_taxnumre EQ 'XEXX010101000' AND ls_vbrk-vbtyp EQ 'M'.
              wa_de_comprobante-exportacion = '02'.
            ELSE.
              wa_de_comprobante-exportacion = '01'.
            ENDIF.

            "Condiciones de pago
            SELECT SINGLE vtext INTO wa_de_comprobante-condicionesdepago
              FROM tvzbt
              WHERE zterm EQ ls_vbrk-zterm
              AND spras EQ lv_spras.

            "Moneda
            wa_de_comprobante-moneda = ls_vbrk-waerk.

            "Tipo de comprobante.
            IF ls_vbrk-vbtyp EQ 'M' OR ls_vbrk-vbtyp EQ 'P'.
              wa_de_comprobante-tipodecomprobante = 'I'.
            ELSEIF ls_vbrk-vbtyp EQ 'O' OR ls_vbrk-vbtyp EQ 'H'.
              wa_de_comprobante-tipodecomprobante = 'E'.
            ENDIF.

            "Subtotal
*            wa_de_comprobante-subtotal = ls_vbrk-netwr.
            LOOP AT lt_prcd INTO ls_prcd WHERE kstat NE 'X' AND koaid EQ 'B' AND kinak EQ '' AND ( kschl EQ 'ZPR1' OR kschl EQ 'ZPR0' OR kschl EQ 'ZNC1' OR kschl EQ 'ZNDP' OR kschl EQ 'ZNPR' OR kschl EQ 'ZNTM' OR kschl EQ 'ZNLO' ).
              lv_subtotal = lv_subtotal + ls_prcd-kwert.
            ENDLOOP.
            CLEAR ls_prcd.

            wa_de_comprobante-subtotal = abs( lv_subtotal ).


            "Descuentos
            LOOP AT lt_prcd INTO ls_prcd WHERE kstat NE 'X' AND koaid EQ 'A' AND kwert LT 0 AND kinak EQ ''.
              lv_desctotal = lv_desctotal + ls_prcd-kwert.
            ENDLOOP.
            CLEAR ls_prcd.

            wa_de_comprobante-descuento = abs( lv_desctotal ).

            "Total
            "Obtenemos el IVA para sumarlo al subtotal.
            LOOP AT lt_prcd INTO ls_prcd WHERE kschl EQ 'MWST' AND  kstat NE 'X' AND koaid EQ 'D' AND kinak EQ ''.
              lv_iva = lv_iva + ls_prcd-kwert.
            ENDLOOP.
            CLEAR ls_prcd.

            "Obtenemos los redondeos por diferencias para sumarlos o restarlos al total Total = Subtotal + Impuestos - Descuentos - Redondeos por diferencia.
            LOOP AT lt_prcd INTO ls_prcd WHERE kschl EQ 'MWST' AND  kstat NE 'X' AND koaid EQ 'D' AND kinak EQ ''.
              lv_kdiff = lv_kdiff + ls_prcd-kdiff.
            ENDLOOP.
            CLEAR ls_prcd.

            wa_de_comprobante-total = abs( lv_subtotal ) + lv_desctotal + lv_iva - lv_kdiff.

            "Tipo de cambio
            wa_de_comprobante-tipocambio = ls_vbrk-kurrf.

            "Lugar de expedición (se toma el código postal del puesto de expedición o en caso de ser factura relacionada al pedido, se toma del centro)
            SELECT SINGLE post_code1 INTO wa_de_comprobante-lugarexpedicion
              FROM adrc AS a
              INNER JOIN tvst AS b ON b~adrnr EQ a~addrnumber
              WHERE b~vstel EQ lv_vstel.
            IF sy-subrc NE '0'.
              SELECT SINGLE post_code1 INTO wa_de_comprobante-lugarexpedicion
                FROM adrc AS a
                INNER JOIN t001w AS b ON b~adrnr EQ a~addrnumber
                WHERE b~werks EQ lv_werks.
            ENDIF.

*** Datos CFDI Relacionado ***
            IF lv_uuidrel NE ''.
              IF ls_vbrk-vbtyp EQ 'O' OR ls_vbrk-vbtyp EQ 'P' OR ls_vbrk-vbtyp EQ 'M'.
                "Documento
                wa_cfdirelacionados_data-nodocu = ls_vbrk-vbeln.
                "UUID Relacionado
                wa_cfdirelacionados_data-uuid = lv_uuidrel.
                "Serie
                wa_cfdirelacionados_data-serie = lv_serierel.
                "Folio
                wa_cfdirelacionados_data-folio = lv_foliorel.

                APPEND wa_cfdirelacionados_data TO wa_de_cfdirelacionado_data-to_relacionados.

                "Documento
                wa_de_cfdirelacionado_data-nodocu = ls_vbrk-vbeln.
                "Tipo de Relación
                IF ls_vbrk-vbtyp EQ 'O' AND ls_vbrk-fktyp EQ 'L' AND ls_vbrk-fkart EQ 'ZRE'.         "Devolución
                  wa_de_cfdirelacionado_data-tiporelacion = '03'.
                ELSEIF ls_vbrk-vbtyp EQ 'O' AND ls_vbrk-fktyp EQ 'A' AND ls_vbrk-fkart EQ 'ZG2'.     "Nota de crédito
                  wa_de_cfdirelacionado_data-tiporelacion = '01'.
                ELSEIF ls_vbrk-vbtyp EQ 'P'.                              "Nota de débito
                  wa_de_cfdirelacionado_data-tiporelacion = '02'.
                ELSEIF ls_vbrk-vbtyp EQ 'M' AND ls_vbrk-fktyp EQ 'L' AND lv_clfacant EQ 'ZANT'.       "Factura relacionada a anticipo
                  wa_de_cfdirelacionado_data-tiporelacion = '07'.
                ELSEIF ls_vbrk-vbtyp EQ 'O' AND ls_vbrk-fktyp EQ 'A' AND ls_vbrk-fkart EQ 'ZNAN'.     "Nota de crédito anticipo
                  wa_de_cfdirelacionado_data-tiporelacion = '07'.
                ENDIF.

                APPEND wa_de_cfdirelacionado_data TO wa_de_comprobante-to_relacionado.
              ENDIF.

              CLEAR: wa_cfdirelacionados_data, wa_de_cfdirelacionado_data.
            ENDIF.

*** Datos de Emisor ***
            "Documento
            wa_emisor_data-nodocu = ls_vbrk-vbeln.

            "RFC Emisor
            SELECT SINGLE paval INTO wa_emisor_data-rfc
              FROM t001z
              WHERE bukrs EQ ls_vbrk-bukrs
              AND party EQ 'MX_RFC'.

            "Régimen fiscal Emisor
            SELECT SINGLE paval INTO wa_emisor_data-regimenfiscal
              FROM t001z
              WHERE bukrs EQ ls_vbrk-bukrs
              AND party EQ 'CFDITR'.

            "Razón social Emisor
            IF ls_vbrk-bukrs EQ 'LACN'.
              wa_emisor_data-nombre = 'FABRICA DE JABON LA CORONA'.
            ENDIF.

            APPEND wa_emisor_data TO wa_de_comprobante-to_emisor.

*** Datos de Receptor ***
            "Documento
            wa_receptor_data-nodocu = ls_vbrk-vbeln.

            "RFC Receptor
            wa_receptor_data-rfc = lv_taxnumre.

            "Nombre Receptor.
            IF lv_cpd EQ ''.

              SELECT FROM but000
                FIELDS partner, type, name_org1, name_org2, name_org3, name_org4, name_first, name_last, name_grp1, name_grp2
                WHERE partner EQ @lv_kunre
                INTO TABLE @DATA(lt_but000re).

              READ TABLE lt_but000re ASSIGNING FIELD-SYMBOL(<fs_but000re>) WITH KEY partner = lv_kunre.

              IF <fs_but000re> IS ASSIGNED.
                IF <fs_but000re>-type EQ '1'.
                  CONCATENATE <fs_but000re>-name_first <fs_but000re>-name_last INTO lv_namere SEPARATED BY space.
                  CONDENSE lv_namere.
                ELSEIF <fs_but000re>-type EQ '2'.
                  CONCATENATE <fs_but000re>-name_org1 <fs_but000re>-name_org2 <fs_but000re>-name_org3 <fs_but000re>-name_org4 INTO lv_namere SEPARATED BY space.
                  CONDENSE lv_namere.
                ELSEIF <fs_but000re>-type EQ '3'.
                  CONCATENATE <fs_but000re>-name_grp1 <fs_but000re>-name_grp2 INTO lv_namere SEPARATED BY space.
                  CONDENSE lv_namere.
                ENDIF.
              ENDIF.

            ELSEIF lv_cpd EQ 'X'.
              SELECT SINGLE name1, name2, name3, name4 INTO ( @DATA(lv_name1re), @DATA(lv_name2re), @DATA(lv_name3re), @DATA(lv_name4re) )
                FROM adrc
                WHERE addrnumber EQ @lv_adrnre.

              CONCATENATE lv_name1re lv_name2re lv_name3re lv_name4re INTO lv_namere SEPARATED BY space.
              CONDENSE lv_namere.

            ENDIF.

            wa_receptor_data-nombre = lv_namere.

            "Número de ID Tributario para documentos de exportación.
            IF lv_taxnumre EQ 'XEXX010101000'.
              wa_receptor_data-numregidtrib = lv_numregid.

              "Residencia fiscal cuando el documento es de exportación.
              SELECT SINGLE intca3 INTO wa_receptor_data-residenciafiscal
                FROM t005
                WHERE land1 EQ ls_vbrk-land1.

              "Régimen fiscal Receptor de exportaciones
              wa_receptor_data-regimenfiscalreceptor = '616'.

              "Uso de CFDI para Receptor de exportaciones
              wa_receptor_data-usocfdi = 'S01'.

              "Domicilio Fiscal Receptor de exportaciones
              wa_receptor_data-domiciliofiscalreceptor = wa_de_comprobante-lugarexpedicion.
            ELSE.
              IF lv_cpd EQ ''.
                "Uso de CFDI Receptor
                IF ls_vbrk-vbtyp EQ 'O' OR ls_vbrk-vbtyp EQ 'H'.
                  CLEAR ls_fpcond.
                  READ TABLE lt_fpcond INTO ls_fpcond WITH KEY rfc = lv_taxnumre.
                  IF sy-subrc EQ 0.
                    wa_receptor_data-usocfdi = ls_fpcond-usocfdi.
                  ELSE.
                    wa_receptor_data-usocfdi = 'G02'.
                  ENDIF.
                ELSEIF ls_vbrk-vbtyp EQ 'M' OR ls_vbrk-vbtyp EQ 'P'.
                  SELECT SINGLE ext_value INTO wa_receptor_data-usocfdi
                    FROM /aif/t_mvmapval
                    WHERE vmapname EQ 'CFDI_USAGE'
                    AND ns EQ '/EDOMX'
                    AND int_value EQ ls_vbrk-kunrg.
                ENDIF.

                "Se valida si el pedido tiene un uso de cfdi, se da prioridad al del pedido, si está vacío se deja el del DM del cliente.

                SELECT SINGLE abrvw INTO @DATA(lv_usocfdiped)
                  FROM vbak
                  WHERE vbeln EQ @lv_pedido.

                IF lv_usocfdiped NE ''.
                  wa_receptor_data-usocfdi = lv_usocfdiped.
                  CLEAR lv_usocfdiped.
                ENDIF.

                "Régimen Fiscal Receptor
                SELECT SINGLE ext_value INTO wa_receptor_data-regimenfiscalreceptor
                  FROM /aif/t_mvmapval
                  WHERE vmapname EQ 'RECEIVER_TAX_REGIME'
                  AND ns EQ '/EDOMX'
                  AND int_value EQ ls_vbrk-kunrg.

                "Domicilio Fiscal Receptor.
                LOOP AT lt_adrc INTO ls_adrc WHERE addrnumber EQ lv_adrnre.
                  IF lv_taxnumre EQ 'XAXX010101000'.
                    wa_receptor_data-domiciliofiscalreceptor = wa_de_comprobante-lugarexpedicion.
                    wa_receptor_data-usocfdi = 'S01'.
                    wa_receptor_data-regimenfiscalreceptor = '616'.
                  ELSE.
                    wa_receptor_data-domiciliofiscalreceptor = ls_adrc-post_code1.
                  ENDIF.
                ENDLOOP.
                CLEAR ls_adrc.

              ELSEIF lv_cpd EQ 'X'.
                IF lv_taxnumre EQ 'XAXX010101000'.
                  wa_receptor_data-domiciliofiscalreceptor = wa_de_comprobante-lugarexpedicion.
                  wa_receptor_data-usocfdi = 'S01'.
                  wa_receptor_data-regimenfiscalreceptor = '616'.
                ELSE.
                  "Uso de CFDI para Receptor CPD
                  SELECT SINGLE abrvw INTO wa_receptor_data-usocfdi
                    FROM vbak
                    WHERE vbeln EQ lv_pedido.

                  "Domicilio Fiscal Receptor CPD, Régimen fiscal Receptor CPD
                  SELECT SINGLE post_code1, po_box INTO ( @wa_receptor_data-domiciliofiscalreceptor, @wa_receptor_data-regimenfiscalreceptor )
                    FROM adrc
                    WHERE addrnumber EQ @lv_adrnre.
                ENDIF.

              ENDIF.
            ENDIF.

            APPEND wa_receptor_data TO wa_de_comprobante-to_receptor.

*** Datos de Conceptos ***

            LOOP AT lt_vbrp INTO ls_vbrp.
              "Número de documento
              wa_de_conceptos_data-nodocu = ls_vbrp-vbeln.

*              IF ls_vbrp-upmat NE '' AND lv_checkparte EQ ''.
*                wa_de_conceptos_data-noidentificacion = |{ ls_vbrp-upmat ALPHA = OUT }|.
*
*                SELECT SINGLE
*
*              ELSE.
              "Número de identificación
              wa_de_conceptos_data-noidentificacion = |{ ls_vbrp-matnr ALPHA = OUT }|.

              "Clave de productos y servicios
              SELECT SINGLE ext_value INTO wa_de_conceptos_data-claveprodserv
                  FROM /aif/t_mvmapval
                  WHERE vmapname EQ 'PRODUCT_CODE'
                  AND ns EQ '/EDOMX'
                  AND int_value EQ ls_vbrp-matnr.

              "Cantidad
              wa_de_conceptos_data-cantidad = ls_vbrp-fkimg.

              "Clave de Unidad.
              SELECT SINGLE valor2 INTO wa_de_conceptos_data-claveunidad
                FROM zparamglob
                WHERE programa EQ lc_programa
                AND parametro EQ '5'
                AND valor1 EQ ls_vbrp-vrkme.

              "Unidad
              SELECT SINGLE msehl INTO wa_de_conceptos_data-unidad
                FROM t006a
                WHERE msehi EQ ls_vbrp-vrkme
                AND spras EQ lv_spras.

              "Descripción
              "Se busca si existe un texto en un idioma diferente a español de acuerdo con el idioma del cliente, si existe el texto comercial, se usa como
              "descripción del material en el XML y PDF.
              IF lv_spras NE 'S'.
                DATA lv_matnr40 TYPE c LENGTH 40.

                lv_matnr40 = ls_vbrp-matnr.
                CONCATENATE lv_matnr40 ls_vbrk-vkorg ls_vbrk-vtweg INTO lv_textname RESPECTING BLANKS.

                SELECT * FROM stxl
                  WHERE tdobject EQ 'MVKE'
                  AND tdid EQ '0001'
                  AND tdspras EQ @lv_spras
                  AND tdname EQ @lv_textname
                  INTO TABLE @DATA(lt_stxl).

                IF sy-subrc EQ 0.
                  CALL FUNCTION 'READ_TEXT'
                    EXPORTING
                      client   = sy-mandt
                      id       = '0001'
                      language = lv_spras
                      name     = lv_textname
                      object   = 'MVKE'
                    TABLES
                      lines    = lt_htlines.

                  IF sy-subrc EQ 0.
                    LOOP AT lt_htlines INTO ls_htlines.
                      wa_de_conceptos_data-descripcion = ls_htlines-tdline.
                      CLEAR: ls_htlines.
                    ENDLOOP.
                    CLEAR: lt_htlines, lv_textname, lv_matnr40.
                  ENDIF.
                ENDIF.
              ENDIF.

              IF wa_de_conceptos_data-descripcion EQ ''.

                LOOP AT lt_makt INTO ls_makt WHERE spras EQ lv_spras AND matnr EQ ls_vbrp-matnr.
                  IF ls_makt-maktx EQ ls_vbrp-arktx.
                    wa_de_conceptos_data-descripcion = ls_makt-maktx.
                  ELSE.
                    wa_de_conceptos_data-descripcion = ls_vbrp-arktx.
                  ENDIF.
                ENDLOOP.
                CLEAR ls_makt.

                CONCATENATE ls_vbrp-vbeln ls_vbrp-posnr INTO lv_textname.

                "Obtenemos texto de ampliación de descripción
                CALL FUNCTION 'READ_TEXT'
                  EXPORTING
                    client                  = sy-mandt
                    id                      = 'Z001'
                    language                = 'S'
                    name                    = lv_textname
                    object                  = 'VBBP'
                  IMPORTING
                    header                  = ls_headertext
                    old_line_counter        = lv_htlines
                  TABLES
                    lines                   = lt_htlines
                  EXCEPTIONS
                    id                      = 1
                    language                = 2
                    name                    = 3
                    not_found               = 4
                    object                  = 5
                    reference_check         = 6
                    wrong_access_to_archive = 7
                    OTHERS                  = 8.

                IF sy-subrc EQ 0.
                  IF lv_htlines GT '00001'.
                    LOOP AT lt_htlines INTO ls_htlines.
                      lv_ampdescr = |{ lv_ampdescr } { ls_htlines-tdline }|.
                    ENDLOOP.
                    CONDENSE lv_ampdescr.
                    DATA(lv_htlen) = strlen( lv_ampdescr ).
                    CONCATENATE wa_de_conceptos_data-descripcion lv_ampdescr INTO wa_de_conceptos_data-descripcion SEPARATED BY space.
                  ELSEIF lv_htlines EQ '00001'.
                    LOOP AT lt_htlines INTO ls_htlines.
                      lv_ampdescr = |{ lv_ampdescr } { ls_htlines-tdline }|.
                    ENDLOOP.
                    CONCATENATE wa_de_conceptos_data-descripcion lv_ampdescr INTO wa_de_conceptos_data-descripcion SEPARATED BY space.
                  ENDIF.
                  CLEAR:ls_htlines, lt_htlines, ls_headertext, lv_htlines, lv_htlen, lv_ampdescr.
                ENDIF.
              ENDIF.

              "Precio
              LOOP AT lt_prcd INTO ls_prcd WHERE kstat NE 'X' AND koaid EQ 'B' AND kwert GE 0 AND kinak EQ '' AND kposn EQ ls_vbrp-posnr.
                "Verificamos que la unidad de medida de venta sea igual a la unidad de medida de precio.
*                IF ls_vbrp-vrkme NE ls_prcd-kmein.
*                  "Valor Unitario
*                  wa_de_conceptos_data-valorunitario = round( val = ls_prcd-kbetr / ls_prcd-kumza dec = 2 mode = cl_abap_math=>round_up ).
*
*                  "Importe
*                  wa_de_conceptos_data-importe = ls_prcd-kwert.
*                ELSE.
                "Valor Unitario
                wa_de_conceptos_data-valorunitario = ls_prcd-kbetr.

                "Importe
                wa_de_conceptos_data-importe = ls_prcd-kwert.
*                ENDIF.
                lv_clfiscal = ls_prcd-mwsk1.
                CLEAR ls_prcd.
              ENDLOOP.

              "Descuento
              LOOP AT lt_prcd INTO ls_prcd WHERE kstat NE 'X' AND koaid EQ 'A' AND kwert LT 0 AND kinak EQ '' AND kposn EQ ls_vbrp-posnr.
                lv_descpos = ( lv_descpos + ls_prcd-kwert ).
                CLEAR ls_prcd.
              ENDLOOP.

              wa_de_conceptos_data-descuento = abs( lv_descpos ).
              CLEAR lv_descpos.

              "Objeto Impuesto
              SELECT SINGLE taxm1, taxm3 INTO ( @DATA(lv_taxm1), @DATA(lv_taxm3) )
                FROM mlan
                WHERE matnr EQ @ls_vbrp-matnr
                AND  aland EQ 'MX'.
*
*              IF lv_taxm1 EQ '1' OR lv_taxm3 EQ '1'.
*                wa_de_conceptos_data-objetoimp = '02'.
*              ELSE.
*                wa_de_conceptos_data-objetoimp = '01'.
*              ENDIF.

              CASE lv_clfiscal.
                WHEN 'A0'.
                  wa_de_conceptos_data-objetoimp = '02'.
                WHEN 'A1'.
                  wa_de_conceptos_data-objetoimp = '02'.
                WHEN 'A2'.
                  wa_de_conceptos_data-objetoimp = '02'.
                WHEN 'A3'.
                  wa_de_conceptos_data-objetoimp = '02'.
                WHEN 'A4'.
                  wa_de_conceptos_data-objetoimp = '02'.
                WHEN 'B0'.
                  wa_de_conceptos_data-objetoimp = '02'.
                WHEN 'B1'.
                  wa_de_conceptos_data-objetoimp = '02'.
                WHEN 'B2'.
                  wa_de_conceptos_data-objetoimp = '02'.
                WHEN 'B3'.
                  wa_de_conceptos_data-objetoimp = '02'.
                WHEN 'B4'.
                  wa_de_conceptos_data-objetoimp = '02'.
                WHEN OTHERS.
                  wa_de_conceptos_data-objetoimp = '01'.
              ENDCASE.

              DATA: lv_totalpos TYPE kwert.
              lv_totalpos = wa_de_conceptos_data-importe - wa_de_conceptos_data-descuento.

              IF lv_totalpos EQ 0.
                wa_de_conceptos_data-objetoimp = '04'.
              ENDIF.

              "Para facturaa de QUALITAS se introduce validación por clasificador de impuesto a nivel de material e indicador de impuesto para determinar
              "el valor 01 como objeto de impuesto - 19.06.2024 - S4DK907218
              IF lv_taxm1 EQ '2' AND lv_clfiscal EQ 'A0'.
                wa_de_conceptos_data-objetoimp = '01'.
              ENDIF.

*** Datos de impuestos a nivel posición ***
              IF wa_de_conceptos_data-objetoimp EQ '02'.

                DATA(lv_imptraslados) = 'X'.

                IF |{ wa_de_conceptos_data-noidentificacion ALPHA = IN }| EQ ls_vbrp-matnr.
                  "Número de documento
                  wa_de_conceptoimpuestos_data-nodocu = ls_vbrp-vbeln.

                  "Número de identificación
                  wa_de_conceptoimpuestos_data-noidentificacion = |{ ls_vbrp-matnr ALPHA = OUT }|.

*** Datos de impuestos trasladados a nivel posición ***
                  "Número de documento
                  wa_conceptotraslados-nodocu = ls_vbrp-vbeln.

                  LOOP AT lt_prcd INTO ls_prcd WHERE kstat NE 'X' AND koaid EQ 'D' AND kwert GE 0 AND kinak EQ '' AND kposn EQ ls_vbrp-posnr.
                    "Base de cálculo para impuestos
                    wa_conceptotraslados-base = ls_prcd-kawrt.

                    "Importe de impuesto
                    wa_conceptotraslados-importe = ls_prcd-kwert - ls_prcd-kdiff.

                    "Impuesto, TipoFactor, TasaOCuota
                    IF ls_prcd-kschl EQ 'MWST'.
                      wa_conceptotraslados-impuesto = '002'.
                      wa_conceptotraslados-tipofactor = 'Tasa'.
                      wa_conceptotraslados-tasaocuota = ls_prcd-kbetr / 100.
                    ENDIF.

                    CLEAR ls_prcd.
                  ENDLOOP.
                  APPEND wa_conceptotraslados TO wa_de_conceptoimpuestos_data-to_conceptotraslados.
                  CLEAR: wa_conceptotraslados.

                  APPEND wa_de_conceptoimpuestos_data TO wa_de_conceptos_data-to_conceptoimpuestos.
                  CLEAR wa_de_conceptoimpuestos_data.
                ENDIF.
              ENDIF.

              APPEND wa_de_conceptos_data TO wa_de_comprobante-to_conceptos.
              REFRESH wa_de_conceptos_data-to_conceptoimpuestos.
              CLEAR: wa_de_conceptos_data-cantidad,wa_de_conceptos_data-claveprodserv, wa_de_conceptos_data-claveunidad, wa_de_conceptos_data-unidad,
                     wa_de_conceptos_data-descripcion, wa_de_conceptos_data-valorunitario, wa_de_conceptos_data-importe, wa_de_conceptos_data-descuento,
                     wa_de_conceptos_data-objetoimp, wa_de_conceptos_data-noidentificacion.
*              ENDIF.
              CLEAR: ls_vbrp, wa_de_conceptos_data-descripcion, lv_totalpos.
            ENDLOOP.

*** Datos de impuestos a nivel comprobante ***
            IF lv_imptraslados EQ 'X' AND wa_de_comprobante-total GT 0.
              "IF wa_de_conceptos_data-objetoimp EQ '02' AND wa_de_comprobante-total GT 0.
              "Número de documento
              wa_de_impuestos_data-nodocu = ls_vbrk-vbeln.

              "Total de impuestos trasladados
              LOOP AT lt_prcd INTO ls_prcd WHERE kstat NE 'X' AND koaid EQ 'D' AND kwert GE 0 AND kinak EQ ''.
                wa_de_impuestos_data-totalimpuestostrasladados = abs( wa_de_impuestos_data-totalimpuestostrasladados + ls_prcd-kwert - ls_prcd-kdiff ).
              ENDLOOP.

*** Datos de impuestos trasladados a nivel comprobante ***

              "Número de documento
              wa_traslados_data-nodocu = ls_vbrk-vbeln.

              "Base de cálculo e Importe
              SELECT SUM( kawrt ), SUM( kwert ), SUM( kdiff ) INTO ( @wa_traslados_data-base, @wa_traslados_data-importe, @lv_kdiffpos )
                FROM prcd_elements
                WHERE kstat NE 'X'
                AND koaid EQ 'D'
                AND kbetr GT 0
                AND kinak EQ ''
                AND kschl EQ 'MWST'
                AND knumv EQ @ls_vbrk-knumv.
              "Tasa o Cuota
              SELECT SINGLE kbetr INTO @DATA(lv_tasa)
                FROM prcd_elements
                WHERE kstat NE 'X'
                AND koaid EQ 'D'
                AND kbetr GT 0
                AND kinak EQ ''
                AND kschl EQ 'MWST'
                AND knumv EQ @ls_vbrk-knumv.

              wa_traslados_data-tasaocuota = lv_tasa / 100.

              wa_traslados_data-importe = wa_traslados_data-importe - lv_kdiffpos.

              "Impuesto, TipoFactor
              IF ls_prcd-kschl EQ 'MWST'.
                wa_traslados_data-impuesto = '002'.
                wa_traslados_data-tipofactor = 'Tasa'.
              ENDIF.
              IF wa_traslados_data-base GT 0.
                APPEND wa_traslados_data TO wa_de_impuestos_data-to_traslados.
              ENDIF.
              CLEAR: wa_traslados_data.

              "Número de documento
              wa_traslados_data-nodocu = ls_vbrk-vbeln.

              "Base de cálculo e Importe
              SELECT SUM( kawrt ), SUM( kwert ), SUM( kdiff ) INTO ( @wa_traslados_data-base, @wa_traslados_data-importe, @lv_kdiffpos )
                FROM prcd_elements
                WHERE kstat NE 'X'
                AND koaid EQ 'D'
                AND kbetr EQ 0
                AND kinak EQ ''
                AND kschl EQ 'MWST'
                AND knumv EQ @ls_vbrk-knumv.
              "Tasa o Cuota
              SELECT SINGLE kbetr INTO @lv_tasa
                FROM prcd_elements
                WHERE kstat NE 'X'
                AND koaid EQ 'D'
                AND kbetr EQ 0
                AND kinak EQ ''
                AND kschl EQ 'MWST'
                AND knumv EQ @ls_vbrk-knumv.

              wa_traslados_data-tasaocuota = lv_tasa / 100.

              wa_traslados_data-importe = wa_traslados_data-importe - lv_kdiffpos.

              "Impuesto, TipoFactor
              IF ls_prcd-kschl EQ 'MWST'.
                wa_traslados_data-impuesto = '002'.
                wa_traslados_data-tipofactor = 'Tasa'.
              ENDIF.
              IF wa_traslados_data-base GT 0.
                APPEND wa_traslados_data TO wa_de_impuestos_data-to_traslados.
              ENDIF.
              CLEAR: ls_prcd, wa_traslados_data.

              APPEND wa_de_impuestos_data TO wa_de_comprobante-to_impuestos.
            ENDIF.

*** Comienza armado de complemento de comercio exterior solo para facturas.
            IF lv_taxnumre EQ 'XEXX010101000' AND ls_vbrk-vbtyp EQ 'M'.

              wa_de_complementocce_data-nodocu = ls_vbrk-vbeln.

              SELECT SINGLE valor1 INTO wa_de_complementocce_data-version
                FROM zparamglob
                WHERE programa EQ lc_programa
                AND parametro EQ '3'
                AND subparametro EQ '2'.

              wa_de_complementocce_data-clavedepedimento = 'A1'.
              wa_de_complementocce_data-certificadoorigen = '0'.
              wa_de_complementocce_data-incoterm = ls_vbrk-inco1.

              IF ls_vbrk-waerk EQ 'USD'.
                wa_de_complementocce_data-tipocambiousd = ls_vbrk-kurrf.
                IF ls_vbrk-netwr NE 0.
                  wa_de_complementocce_data-totalusd = ls_vbrk-netwr.
                ELSEIF ls_vbrk-netwr EQ 0.
                  wa_de_complementocce_data-totalusd = wa_de_comprobante-subtotal.
                ENDIF.
              ELSEIF ls_vbrk-waerk EQ 'MXN'.

                CALL FUNCTION 'BAPI_EXCHANGERATE_GETDETAIL'
                  EXPORTING
                    rate_type  = 'M'
                    from_curr  = ls_vbrk-waerk
                    to_currncy = 'USD'
                    date       = ls_vbrk-fkdat
                  IMPORTING
                    exch_rate  = ls_tipocambio.
                wa_de_complementocce_data-tipocambiousd = ls_tipocambio-exch_rate_v.
                wa_de_complementocce_data-totalusd = ls_vbrk-netwr / ls_tipocambio-exch_rate_v.
              ELSE.

                CALL FUNCTION 'BAPI_EXCHANGERATE_GETDETAIL'
                  EXPORTING
                    rate_type  = 'M'
                    from_curr  = ls_vbrk-waerk
                    to_currncy = 'MXN'
                    date       = ls_vbrk-fkdat
                  IMPORTING
                    exch_rate  = ls_tipocambio.

                DATA(lv_montomxn) = ls_vbrk-netwr * ls_tipocambio-exch_rate_v.
                CLEAR ls_tipocambio.

                CALL FUNCTION 'BAPI_EXCHANGERATE_GETDETAIL'
                  EXPORTING
                    rate_type  = 'M'
                    from_curr  = 'MXN'
                    to_currncy = 'USD'
                    date       = ls_vbrk-fkdat
                  IMPORTING
                    exch_rate  = ls_tipocambio.

                wa_de_complementocce_data-tipocambiousd = ls_tipocambio-exch_rate_v.
                wa_de_complementocce_data-totalusd = lv_montomxn / ls_tipocambio-exch_rate_v.
              ENDIF.

*Armado de datos del emisor en el complemento de comercio exterior.

              LOOP AT lt_adremi INTO ls_adremi.

                wa_de_cceemisor_data-nodocu = ls_vbrk-vbeln.
                wa_de_cceemisor_data-nodireccion = lv_adremisor.

*Datos del domicilio del emisor
                wa_ccedomicilioemisor_data-nodocu = ls_vbrk-vbeln.
                wa_ccedomicilioemisor_data-nodireccion = lv_adremisor.
                wa_ccedomicilioemisor_data-calle = ls_adremi-street.
                wa_ccedomicilioemisor_data-codigopostal = ls_adremi-post_code1.
                wa_ccedomicilioemisor_data-estado = ls_adremi-region.
                wa_ccedomicilioemisor_data-numeroexterior = ls_adremi-house_num1.

                SELECT SINGLE intca3 INTO wa_ccedomicilioemisor_data-pais
                  FROM t005
                  WHERE land1 EQ ls_adremi-country.

                APPEND wa_ccedomicilioemisor_data TO wa_de_cceemisor_data-to_ccedomicilioemisor.
                APPEND wa_de_cceemisor_data TO wa_de_complementocce_data-to_cceemisor.
              ENDLOOP.

*Armado de datos del receptor en el complemento de comercio exterior.
              CLEAR ls_vbpa.
              LOOP AT lt_vbpa INTO ls_vbpa WHERE parvw EQ 'AG'.
                wa_de_ccereceptor_data-nodocu = ls_vbrk-vbeln.
                wa_de_ccereceptor_data-nodireccion = ls_vbpa-adrnr.
                LOOP AT lt_taxnum INTO ls_taxnum WHERE partner EQ ls_vbpa-kunnr AND taxtype NE 'MX1'.
                  wa_de_ccereceptor_data-numregistrib = ls_taxnum-taxnum.
                ENDLOOP.



*Datos del domicilio del receptor.
                CLEAR ls_adrc.
                LOOP AT lt_adrc INTO ls_adrc WHERE addrnumber EQ ls_vbpa-adrnr.
                  wa_ccedomicilioreceptor_data-nodocu = ls_vbrk-vbeln.
                  wa_ccedomicilioreceptor_data-nodireccion = ls_vbpa-adrnr.
                  wa_ccedomicilioreceptor_data-calle = ls_adrc-street.
                  wa_ccedomicilioreceptor_data-numeroexterior = ls_adrc-house_num1.
                  wa_ccedomicilioreceptor_data-codigopostal = ls_adrc-post_code1.
                  wa_ccedomicilioreceptor_data-estado = ls_adrc-region.
                  wa_ccedomicilioreceptor_data-municipio = ls_adrc-city1.

                  SELECT SINGLE intca3 INTO wa_ccedomicilioreceptor_data-pais
                    FROM t005
                    WHERE land1 EQ ls_adrc-country.

                  APPEND wa_ccedomicilioreceptor_data TO wa_de_ccereceptor_data-to_ccedomicilioreceptor.
                ENDLOOP.
                APPEND wa_de_ccereceptor_data TO wa_de_complementocce_data-to_ccereceptor.
              ENDLOOP.

*Armado de nodo de mercancias en el complemento de comercio exterior.
              CLEAR ls_vbrp.
              wa_de_ccemercancias_data-nodocu = ls_vbrk-vbeln.
              LOOP AT lt_vbrp INTO ls_vbrp.
                wa_ccemercancia_data-nodocu = ls_vbrp-vbeln.
                wa_ccemercancia_data-noidentificacion = |{ ls_vbrp-matnr ALPHA = OUT }|.
                LOOP AT lt_arancel INTO ls_arancel WHERE matnr EQ ls_vbrp-matnr AND datbi EQ '99991231' AND stcts EQ 'ZSD_FRARAN'.
                  wa_ccemercancia_data-fraccionarancelaria = ls_arancel-ccngn.
                  CLEAR ls_arancel.
                ENDLOOP.

                IF ls_vbrp-vrkme EQ 'SER'.
                  wa_ccemercancia_data-unidadaduana = '99'.
                  wa_de_complementocce_data-totalusd = wa_de_complementocce_data-totalusd - ls_vbrp-netwr.
                  wa_ccemercancia_data-fraccionarancelaria = ''.                          "Si el material es tipo SER, se quita la fracción arancelaria en caso de que la hayan capturado erróneamente en el catálogo - CAOG - 24.01.25 - S4DK909873
                ELSE.
                  LOOP AT lt_uaduana INTO ls_uaduana WHERE ccngn EQ wa_ccemercancia_data-fraccionarancelaria AND nosct EQ 'ZSD_FRARAN' AND datbi EQ '99991231'.
                    wa_ccemercancia_data-unidadaduana = ls_uaduana-cuom1.
                  ENDLOOP.
                  CLEAR ls_uaduana.
                ENDIF.

                CASE wa_ccemercancia_data-unidadaduana.
                  WHEN '01'.
                    "Convertimos la unidad de medida de venta a kilos.
                    CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
                      EXPORTING
                        i_matnr  = ls_vbrp-matnr
                        i_in_me  = ls_vbrp-meins
                        i_out_me = 'KG'
                        i_menge  = ls_vbrp-fklmg
                      IMPORTING
                        e_menge  = lv_cekilos.
                    IF sy-subrc EQ 0.
                      wa_ccemercancia_data-cantidadaduana = lv_cekilos.
                      IF ls_vbrp-netwr NE 0.
                        wa_ccemercancia_data-valorunitarioaduana = round( val = ls_vbrp-netwr / lv_cekilos dec = 4 mode = cl_abap_math=>round_up ).
                        wa_ccemercancia_data-valordolares = ls_vbrp-netwr.
                      ELSEIF ls_vbrp-netwr EQ 0.
                        LOOP AT lt_prcd INTO ls_prcd WHERE kstat NE 'X' AND koaid EQ 'B' AND kwert GE 0 AND kinak EQ '' AND kposn EQ ls_vbrp-posnr.
                          wa_ccemercancia_data-valorunitarioaduana = round( val = ls_prcd-kwert / lv_cekilos dec = 4 mode = cl_abap_math=>round_up ).
                          wa_ccemercancia_data-valordolares = ls_prcd-kwert.
                        ENDLOOP.

                      ENDIF.
                    ENDIF.
                  WHEN '03'.
                    "Convertimos la unidad de medida de venta a metro lineal.
                    CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
                      EXPORTING
                        i_matnr  = ls_vbrp-matnr
                        i_in_me  = ls_vbrp-meins
                        i_out_me = 'M'
                        i_menge  = ls_vbrp-fklmg
                      IMPORTING
                        e_menge  = lv_cekilos.
                    IF sy-subrc EQ 0.
                      wa_ccemercancia_data-cantidadaduana = lv_cekilos.
                      IF ls_vbrp-netwr NE 0.
                        wa_ccemercancia_data-valorunitarioaduana = round( val = ls_vbrp-netwr / lv_cekilos dec = 4 mode = cl_abap_math=>round_up ).
                        wa_ccemercancia_data-valordolares = ls_vbrp-netwr.
                      ELSEIF ls_vbrp-netwr EQ 0.
                        LOOP AT lt_prcd INTO ls_prcd WHERE kstat NE 'X' AND koaid EQ 'B' AND kwert GE 0 AND kinak EQ '' AND kposn EQ ls_vbrp-posnr.
                          wa_ccemercancia_data-valorunitarioaduana = round( val = ls_prcd-kwert / lv_cekilos dec = 4 mode = cl_abap_math=>round_up ).
                          wa_ccemercancia_data-valordolares = ls_prcd-kwert.
                        ENDLOOP.

                      ENDIF.
                    ENDIF.
                  WHEN '06'.
                    "Unidad de medida aduana es pieza, por lo que se deja sin conversión.
                    wa_ccemercancia_data-cantidadaduana = ls_vbrp-fklmg.
                    LOOP AT lt_prcd INTO ls_prcd WHERE kstat NE 'X' AND koaid EQ 'B' AND kwert GE 0 AND kinak EQ '' AND kposn EQ ls_vbrp-posnr.
                      wa_ccemercancia_data-valorunitarioaduana = round( val = ls_prcd-kwert / ls_vbrp-fklmg dec = 4 mode = cl_abap_math=>round_up ).
                      wa_ccemercancia_data-valordolares = ls_prcd-kwert.
                    ENDLOOP.
                  WHEN 99.
                    "Unidad de medida aduana es servicio, por lo que se envían en ceros.
                    wa_ccemercancia_data-cantidadaduana = ls_vbrp-fklmg.
                    wa_ccemercancia_data-valorunitarioaduana = '0.00'.
                    wa_ccemercancia_data-valordolares = '0.00'.
                ENDCASE.

                APPEND wa_ccemercancia_data TO wa_de_ccemercancias_data-to_ccemercancia.
                CLEAR: ls_vbrp, wa_ccemercancia_data.
              ENDLOOP.

              APPEND wa_de_ccemercancias_data TO wa_de_complementocce_data-to_ccemercancias.

              APPEND wa_de_complementocce_data TO wa_de_comprobante-to_complementocce.
            ENDIF.

*Armado de nodo Addenda Cabecera
            LOOP AT lt_vbak INTO ls_vbak WHERE vbeln = lv_pedido.
              wa_de_addendacabecera-nodocu          = ls_vbrk-vbeln.
              wa_de_addendacabecera-nocontrol       = |{ ls_vbak-vbeln ALPHA = OUT }|.
              wa_de_addendacabecera-cadena          = ls_vbak-kvgr1.
              wa_de_addendacabecera-agente          = ls_vbak-vkgrp.
              wa_de_addendacabecera-cliente         = |{ ls_vbak-kunnr ALPHA = OUT }|.
              wa_de_addendacabecera-condicionespago = wa_de_comprobante-condicionesdepago.
              wa_de_addendacabecera-clasepedido     = ls_vbak-auart.
              wa_de_addendacabecera-canaldistr      = ls_vbrk-vtweg.
              CONCATENATE ls_vbak-erdat+6(2) '/' ls_vbak-erdat+4(2) '/' ls_vbak-erdat(4) INTO wa_de_addendacabecera-fechanocontrol.

              LOOP AT lt_vbkd INTO ls_vbkd WHERE vbeln EQ ls_vbak-vbeln.
                wa_de_addendacabecera-pedidocliente = ls_vbkd-bstkd.
                wa_de_addendacabecera-zona = ls_vbkd-bzirk.

                IF ls_vbkd-bstdk EQ '00000000'.
                  wa_de_addendacabecera-fechapedcliente = wa_de_addendacabecera-fechanocontrol.
                ELSE.
                  CONCATENATE ls_vbkd-bstdk+6(2) '/' ls_vbkd-bstdk+4(2) '/' ls_vbkd-bstdk(4) INTO wa_de_addendacabecera-fechapedcliente.
                ENDIF.
                CLEAR ls_vbkd.
              ENDLOOP.

              LOOP AT lt_vbpa INTO ls_vbpa WHERE vbeln EQ ls_vbrk-vbeln AND parvw EQ 'WE'.
                wa_de_addendacabecera-nodestinatariomerc = ls_vbpa-kunnr.

                LOOP AT lt_adrc INTO ls_adrc WHERE addrnumber EQ ls_vbpa-adrnr.
                  CONCATENATE ls_adrc-name1 ls_adrc-name2 ls_adrc-name3 ls_adrc-name4 INTO wa_de_addendacabecera-destinatariomerc SEPARATED BY space.
                  CONDENSE wa_de_addendacabecera-destinatariomerc.

                  SELECT SINGLE landx INTO @DATA(lv_paisdm)
                    FROM t005t
                    WHERE land1 EQ @ls_adrc-country
                    AND spras EQ @lv_spras.
                  TRANSLATE lv_paisdm TO UPPER CASE.

                  SELECT SINGLE bezei INTO @DATA(lv_estadodm)
                    FROM t005u
                    WHERE land1 EQ @ls_adrc-country
                    AND bland EQ @ls_adrc-region
                    AND spras EQ @lv_spras.
                  TRANSLATE lv_estadodm TO UPPER CASE.

                  CONCATENATE ls_adrc-street ls_adrc-house_num1 ls_adrc-post_code1 ls_adrc-city1 ',' lv_estadodm ',' lv_paisdm INTO wa_de_addendacabecera-direcciondm SEPARATED BY space.
                  CONDENSE wa_de_addendacabecera-direcciondm.

                  LOOP AT lt_but0id INTO ls_but0id WHERE partner EQ ls_vbpa-kunnr AND type EQ 'ZBUGLN'.
                    wa_de_addendacabecera-glndestinatariomerc = ls_but0id-idnumber.
                    CLEAR ls_but0id.
                  ENDLOOP.

                  IF wa_de_addendacabecera-glndestinatariomerc EQ ''.
                    LOOP AT lt_but0id INTO ls_but0id WHERE partner EQ ls_vbpa-kunnr AND type EQ 'ZBUEDI'.
                      wa_de_addendacabecera-glndestinatariomerc = ls_but0id-idnumber.
                      CLEAR ls_but0id.
                    ENDLOOP.
                  ENDIF.
                ENDLOOP.
                CLEAR ls_vbpa.

                LOOP AT lt_vbpa INTO ls_vbpa WHERE vbeln EQ ls_vbrk-vbeln AND parvw EQ 'AG'.
                  LOOP AT lt_but0id INTO ls_but0id WHERE partner EQ ls_vbpa-kunnr AND type EQ 'ZBUGLN'.
                    wa_de_addendacabecera-glnsolicitante = ls_but0id-idnumber.
                  ENDLOOP.
                  CLEAR ls_but0id.

                  IF wa_de_addendacabecera-glndestinatariomerc EQ ''.
                    LOOP AT lt_but0id INTO ls_but0id WHERE partner EQ ls_vbpa-kunnr AND type EQ 'ZBUEDI'.
                      wa_de_addendacabecera-glnsolicitante = ls_but0id-idnumber.
                    ENDLOOP.
                    CLEAR ls_but0id.
                  ENDIF.
                ENDLOOP.

                lv_textname = ls_vbak-vbeln.

*Obtenemos textos de intrucciones de entrega y observaciones.
                CALL FUNCTION 'READ_TEXT'
                  EXPORTING
                    client                  = sy-mandt
                    id                      = 'ZINS'
                    language                = 'S'
                    name                    = lv_textname
                    object                  = 'VBBK'
                  IMPORTING
                    header                  = ls_headertext
                    old_line_counter        = lv_htlines
                  TABLES
                    lines                   = lt_htlines
                  EXCEPTIONS
                    id                      = 1
                    language                = 2
                    name                    = 3
                    not_found               = 4
                    object                  = 5
                    reference_check         = 6
                    wrong_access_to_archive = 7
                    OTHERS                  = 8.

                IF sy-subrc EQ 0.
                  IF lv_htlines GT '00001'.
                    LOOP AT lt_htlines INTO ls_htlines.
                      wa_de_addendacabecera-instrucciones = |{ wa_de_addendacabecera-instrucciones } { '-' } { ls_htlines-tdline }|.
                    ENDLOOP.
                    lv_htlen = strlen( wa_de_addendacabecera-instrucciones ).
                    wa_de_addendacabecera-instrucciones = wa_de_addendacabecera-instrucciones+3.
                    CONDENSE wa_de_addendacabecera-instrucciones.
                  ELSEIF lv_htlines EQ '00001'.
                    LOOP AT lt_htlines INTO ls_htlines.
                      wa_de_addendacabecera-instrucciones = ls_htlines-tdline.
                    ENDLOOP.
                  ENDIF.
                  CLEAR:ls_htlines, lt_htlines, ls_headertext, lv_htlines, lv_textname.
                ENDIF.

                wa_de_addendacabecera-idiomacliente = lv_spras.

*Obtenemos textos capturados en la entrega de salida.

                lv_textname = ls_vbrk-vbeln.

                CALL FUNCTION 'READ_TEXT'
                  EXPORTING
                    client                  = sy-mandt
                    id                      = 'TX14'
                    language                = 'S'
                    name                    = lv_textname
                    object                  = 'VBBK'
                  IMPORTING
                    header                  = ls_headertext
                    old_line_counter        = lv_htlines
                  TABLES
                    lines                   = lt_htlines
                  EXCEPTIONS
                    id                      = 1
                    language                = 2
                    name                    = 3
                    not_found               = 4
                    object                  = 5
                    reference_check         = 6
                    wrong_access_to_archive = 7
                    OTHERS                  = 8.

                IF sy-subrc EQ 0.
                  IF lv_htlines GT '00001'.
                    LOOP AT lt_htlines INTO ls_htlines.
                      wa_de_addendacabecera-textoentrega14 = |{ wa_de_addendacabecera-textoentrega14 } { '-' } { ls_htlines-tdline }|.
                    ENDLOOP.
                    lv_htlen = strlen( wa_de_addendacabecera-textoentrega14 ).
                    wa_de_addendacabecera-textoentrega14 = wa_de_addendacabecera-textoentrega14+3.
                    CONDENSE wa_de_addendacabecera-textoentrega14.
                  ELSEIF lv_htlines EQ '00001'.
                    LOOP AT lt_htlines INTO ls_htlines.
                      wa_de_addendacabecera-textoentrega14 = ls_htlines-tdline.
                    ENDLOOP.
                  ENDIF.
                  CLEAR:ls_htlines, lt_htlines, ls_headertext, lv_htlines.
                ENDIF.

              ENDLOOP.

              CLEAR ls_vbrp.
              LOOP AT lt_vbrp INTO ls_vbrp WHERE vbeln EQ ls_vbrk-vbeln.
                IF ls_vbrp-gewei EQ 'KG'.
                  lv_pneto = lv_pneto + ls_vbrp-ntgew.
                  lv_pbruto = lv_pbruto + ls_vbrp-brgew.
                ELSEIF ls_vbrp-gewei EQ 'G'.
                  lv_pnetog = lv_pnetog + ls_vbrp-ntgew.
                  lv_pbrutog = lv_pbrutog + ls_vbrp-brgew.
                ENDIF.
                lv_pneto = lv_pneto + ( lv_pnetog / 1000 ).
                lv_pbruto = lv_pbruto + ( lv_pbrutog / 1000 ).
              ENDLOOP.

              wa_de_addendacabecera-pesobruto = lv_pbruto.
              wa_de_addendacabecera-pesoneto = lv_pneto.
              wa_de_addendacabecera-umpeso = 'KG'.

              IF ls_vbrk-land1 NE 'MX'.  "Se convierte a LBS si el país de entrega es extranjero.
                wa_de_addendacabecera-pesobruto = lv_pbruto * '2.20462262'.
                wa_de_addendacabecera-pesoneto = lv_pneto * '2.20462262'.
                wa_de_addendacabecera-umpeso = 'LBS'.
              ENDIF.

              "Se obtiene la placa del tracto.

              DATA lv_entrtm TYPE /scmtms/base_btd_id.

              lv_entrtm = |{ lv_entrega1 ALPHA = IN }|.

              SELECT SINGLE a~parent_key INTO @DATA(lv_parentkey)
                FROM /scmtms/d_torite AS a
                INNER JOIN /scmtms/d_torrot AS b ON b~db_key EQ a~parent_key
                WHERE a~base_btd_id EQ @lv_entrtm
                AND a~ref_bo EQ 'TOR'
                AND b~lifecycle NE '10'.

              IF sy-subrc EQ 0.
                SELECT * FROM /scmtms/d_torite
                  WHERE parent_key EQ @lv_parentkey
                  INTO TABLE @DATA(lt_torite).
              ENDIF.

              READ TABLE lt_torite INTO DATA(ls_torite) WITH KEY item_type = 'TRUC'.

              IF sy-subrc EQ 0.
                wa_de_addendacabecera-placatracto = ls_torite-platenumber.

                SELECT SINGLE tor_id INTO @DATA(lv_viaje)
                  FROM /scmtms/d_torrot
                  WHERE db_key EQ @ls_torite-parent_key.

                wa_de_addendacabecera-viaje = |{ lv_viaje ALPHA = OUT }|.

                SELECT SINGLE actual_date INTO @DATA(lv_fecheckout)
                  FROM /scmtms/d_torexe
                  WHERE event_code EQ 'CHECK_OUT'
                  AND parent_key EQ @ls_torite-parent_key.

                CONVERT TIME STAMP lv_fecheckout TIME ZONE 'UTC-6' INTO DATE DATA(lv_feviaje) TIME DATA(lv_hrviaje).

                wa_de_addendacabecera-fechaviaje = lv_feviaje.

              ENDIF.
              CLEAR ls_torite.

              "Se obtiene la placa de remolques.
              SELECT * FROM /scmtms/d_torite
                WHERE parent_key EQ @lv_parentkey
                AND item_type EQ 'TRL'
                INTO TABLE @DATA(lt_torite_rem).

              SORT lt_torite_rem ASCENDING BY item_id.

              DESCRIBE TABLE lt_torite_rem LINES DATA(lv_rem).

              CASE lv_rem.
                WHEN 1.   "1 Remolque
                  READ TABLE lt_torite_rem INTO DATA(ls_torite_rem) WITH KEY item_type = 'TRL'.
                  wa_de_addendacabecera-placaremolque1 = ls_torite_rem-platenumber.
                  CLEAR ls_torite_rem.
                WHEN 2.   "2 Remolques
                  READ TABLE lt_torite_rem INTO ls_torite_rem WITH KEY item_type = 'TRL'.
                  wa_de_addendacabecera-placaremolque1 = ls_torite_rem-platenumber.
                  CLEAR ls_torite_rem.

                  SORT lt_torite_rem DESCENDING BY item_id.

                  READ TABLE lt_torite_rem INTO ls_torite_rem WITH KEY item_type = 'TRL'.
                  wa_de_addendacabecera-placaremolque2 = ls_torite_rem-platenumber.
                  CLEAR ls_torite_rem.
                WHEN OTHERS.
              ENDCASE.

              "Se obtienen los sellos del transporte.
              IF lt_torite[] IS NOT INITIAL.
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
                      wa_de_addendacabecera-sellos = ls_text2-text.
                    ELSEIF lv_linestext GT 1.
                      LOOP AT lt_text2 INTO ls_text2.
                        CONCATENATE lv_sellos ls_text2-text INTO lv_sellos SEPARATED BY space.
                      ENDLOOP.
                      CONDENSE lv_sellos.
                      wa_de_addendacabecera-sellos = lv_sellos.
                    ENDIF.
                  ENDIF.
                ENDIF.
                CLEAR: ls_text, ls_text2, lv_sellos.
              ENDIF.


              CLEAR: ls_vbak, lv_textname, ls_vbrp.

*Armado de nodo Addenda Posición.
              CLEAR ls_vbrp.
              LOOP AT lt_vbrp INTO ls_vbrp WHERE vbeln EQ ls_vbrk-vbeln.
                wa_addendaposicion-nodocu       = ls_vbrp-vbeln.
                wa_addendaposicion-posicion     = ls_vbrp-posnr.
                wa_addendaposicion-material     = |{ ls_vbrp-matnr ALPHA = OUT }|.
                wa_addendaposicion-centro       = ls_vbrp-werks.
                wa_addendaposicion-almacen      = ls_vbrp-lgort.
                wa_addendaposicion-indicadoriva = ls_vbrp-mwsk1.

                LOOP AT lt_mean INTO ls_mean WHERE matnr EQ ls_vbrp-matnr AND meinh EQ 'CS' AND eantp EQ 'IC'.
                  wa_addendaposicion-codigoean = ls_mean-ean11.
                ENDLOOP.
                CLEAR ls_mean.

                LOOP AT lt_knmt INTO ls_knmt WHERE matnr EQ ls_vbrp-matnr AND kunnr EQ ls_vbrk-kunag.
                  wa_addendaposicion-codigomatcliente = ls_knmt-kdmat.
                ENDLOOP.
                CLEAR ls_knmt.

                CONCATENATE ls_vbrp-vbeln ls_vbrp-posnr INTO lv_textname.

*Obtenemos textos de posición.
                CALL FUNCTION 'READ_TEXT'
                  EXPORTING
                    client                  = sy-mandt
                    id                      = '0001'
                    language                = 'S'
                    name                    = lv_textname
                    object                  = 'VBBP'
                  IMPORTING
                    header                  = ls_headertext
                    old_line_counter        = lv_htlines
                  TABLES
                    lines                   = lt_htlines
                  EXCEPTIONS
                    id                      = 1
                    language                = 2
                    name                    = 3
                    not_found               = 4
                    object                  = 5
                    reference_check         = 6
                    wrong_access_to_archive = 7
                    OTHERS                  = 8.

                IF sy-subrc EQ 0.
                  IF lv_htlines GT '00001'.
                    LOOP AT lt_htlines INTO ls_htlines.
                      wa_addendaposicion-textoposicion = |{ wa_addendaposicion-textoposicion } { '-' } { ls_htlines-tdline }|.
                    ENDLOOP.
                    lv_htlen = strlen( wa_addendaposicion-textoposicion ).
                    wa_addendaposicion-textoposicion = wa_addendaposicion-textoposicion+3.
                    CONDENSE wa_addendaposicion-textoposicion.
                  ELSEIF lv_htlines EQ '00001'.
                    LOOP AT lt_htlines INTO ls_htlines.
                      wa_addendaposicion-textoposicion = ls_htlines-tdline.
                    ENDLOOP.
                  ENDIF.
                  CLEAR:ls_htlines, lt_htlines, ls_headertext, lv_htlines.
                ENDIF.

                "Número de registro sanitario Nicaragua
                DATA: lt_caract  TYPE STANDARD TABLE OF bapi1003_alloc_values_char,
                      lt_curr    TYPE STANDARD TABLE OF bapi1003_alloc_values_curr,
                      lt_nums    TYPE STANDARD TABLE OF bapi1003_alloc_values_num,
                      lt_retchar TYPE STANDARD TABLE OF bapiret2,
                      lv_objkey  TYPE bapi1003_key-object.

                CASE lv_paisdm.
                  WHEN 'NICARAGUA'.

                    lv_objkey = ls_vbrp-matnr.

                    CALL FUNCTION 'BAPI_OBJCL_GETDETAIL'
                      EXPORTING
                        objectkey       = lv_objkey
                        objecttable     = 'MARA'
                        classnum        = 'PRODUCTOS'
                        classtype       = '001'
                      TABLES
                        allocvalueschar = lt_caract
                        allocvaluesnum  = lt_nums
                        allocvaluescurr = lt_curr
                        return          = lt_retchar.
                    IF sy-subrc EQ 0.
                      READ TABLE lt_caract ASSIGNING FIELD-SYMBOL(<fs_caract>) WITH KEY charact = 'REGISTRO_SANITARIO_NICARAGUA'.
                      IF <fs_caract> IS ASSIGNED.
                        wa_addendaposicion-registrosanitario = <fs_caract>-value_char.
                        CONDENSE wa_addendaposicion-registrosanitario.
                      ENDIF.
                      UNASSIGN <fs_caract>.
                    ENDIF.
                ENDCASE.

                APPEND wa_addendaposicion TO wa_de_addendacabecera-to_addendaposicion.
                CLEAR wa_addendaposicion.
              ENDLOOP.

              APPEND wa_de_addendacabecera TO wa_de_comprobante-to_addendacabecera.
            ENDLOOP.

          ENDLOOP.

        ELSE.
*Error: no existe el número de factura consultado.
          CONCATENATE 'No existe la factura' lv_vbeln_out 'por favor valida que tu captura sea correcta.' INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZSD_MSG'
              iv_msg_number = '002'
              iv_msg_text   = lv_error_msg.
          RETURN.
        ENDIF.
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
    ELSE.
*Error: no se envió un parámetro en el request.
      lv_error_msg = 'Por favor envía una factura como parámetro.'.
      CALL METHOD lo_msg->add_message
        EXPORTING
          iv_msg_type   = /iwbep/cl_cos_logger=>error
          iv_msg_id     = 'ZSD_MSG'
          iv_msg_number = '001'
          iv_msg_text   = lv_error_msg.
      RETURN.
    ENDIF.
  ENDMETHOD.


  METHOD anulacionesset_get_entityset.
    DATA: gs_anulaciones TYPE zcl_zsd_cfdi_mpc_ext=>ts_anulaciones,
          gs_vbak        TYPE vbak,
          gt_vbak        TYPE STANDARD TABLE OF vbak WITH DEFAULT KEY,
          gs_vbfa        TYPE vbfa,
          gt_vbfa        TYPE STANDARD TABLE OF vbfa WITH DEFAULT KEY,
          lv_fechaini    TYPE erdat,
          lv_fechafin    TYPE erdat,
          lv_diasdiff    TYPE dlydy,
          lv_diasdiff1   TYPE c LENGTH 6.

*Cálculo de fechas para intervalo de búsqueda de facturas sin timbrar.
    SELECT SINGLE valor1
        INTO @lv_diasdiff1
        FROM zparamglob
        WHERE programa = 'ZCFDI_MONITOR'
        AND parametro = '7'
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

*Almacenamos los pedidos con motivo de bloqueo de factura Z1 en el periodo de tiempo calculado en el paso anterior.

    SELECT * FROM vbak
      INTO CORRESPONDING FIELDS OF gs_vbak
      WHERE augru EQ 'Z01'
      AND erdat GE lv_fechaini
      AND erdat LE lv_fechafin.

      APPEND gs_vbak TO gt_vbak.
    ENDSELECT.

*Buscamos las facturas asociadas a los pedidos con bloqueo de factura tipo de documentos M (Facturas) O (Notas de crédito) P (notas de cargo), verificando que las facturas no estén anuladas en SAP y que tengan UUID.

    SELECT * FROM vbfa AS a
      INNER JOIN vbrk AS b ON b~vbeln EQ a~vbeln
      INNER JOIN zsd_cfdi_return AS c ON c~nodocu EQ a~vbeln
      INTO CORRESPONDING FIELDS OF gs_vbfa
      FOR ALL ENTRIES IN gt_vbak
      WHERE a~vbelv EQ gt_vbak-vbeln
      AND a~vbtyp_n IN ('M', 'O', 'P')
      AND b~fksto EQ ''
      AND c~uuid NE ''
      AND c~cancelado EQ ''.

      APPEND gs_vbfa TO gt_vbfa.
    ENDSELECT.
    CLEAR gs_vbfa.

*Se comeinza con el llenado del response.
    LOOP AT gt_vbfa INTO gs_vbfa.
      gs_anulaciones-nodocu = gs_vbfa-vbeln.
      gs_anulaciones-estatus = 'Sol. de Cancelación'.

      SELECT SINGLE serie INTO gs_anulaciones-serie
        FROM zsd_cfdi_return
        WHERE nodocu EQ gs_vbfa-vbeln.

      APPEND gs_anulaciones TO et_entityset.

    ENDLOOP.
    CLEAR gs_anulaciones.
  ENDMETHOD.


  METHOD cfdimonitorset_get_entityset.
    DATA: gs_cfdi_monitor TYPE zcl_zsd_cfdi_mpc_ext=>ts_cfdimonitor,
          gt_vbrk         TYPE STANDARD TABLE OF vbrk WITH DEFAULT KEY,
          lt_dates        TYPE RANGE OF sy-datum,
          ls_dates        LIKE LINE OF lt_dates,
          lt_types        TYPE RANGE OF vbrk-vbtyp,
          ls_types        LIKE LINE OF lt_types,
          lv_fechaini     TYPE fkdat,
          lv_fechafin     TYPE fkdat,
          lv_mesesdiff    TYPE dlydy,
          lv_mesesdiff1   TYPE c LENGTH 6,
          lv_salesorder   TYPE vbak-vbeln,
          lv_delivery     TYPE likp-vbeln,
          lv_pexped       TYPE vstel,
          lv_cpd          TYPE xcpdk,
          lv_name1_ag     TYPE adrc-name1,
          lv_name2_ag     TYPE adrc-name2,
          lv_name1_we     TYPE adrc-name1,
          lv_name2_we     TYPE adrc-name2,
          lv_werks        TYPE vbap-werks,
          lv_vtweg        TYPE vbrk-vtweg,
          lv_vbtyp        TYPE vbrk-vbtyp.

*Cálculo de fechas para intervalo de búsqueda de facturas sin timbrar.
    SELECT SINGLE valor1
        INTO @lv_mesesdiff1
        FROM zparamglob
        WHERE programa = 'ZCFDI_MONITOR'
        AND parametro = '1'
        AND subparametro = '1'.

    lv_mesesdiff = lv_mesesdiff1.

    CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
      EXPORTING
        date      = sy-datum
        days      = lv_mesesdiff
        months    = 0
        signum    = '-' " para calcular fechas anteriores
        years     = 0
      IMPORTING
        calc_date = lv_fechaini.

    lv_fechafin = sy-datum.

    ls_dates-sign   = 'I'.
    ls_dates-option = 'EQ'.
    ls_dates-low    = lv_fechaini.
    ls_dates-high   = lv_fechafin.

    APPEND ls_dates TO lt_dates.

    ls_types-sign   = 'I'.
    ls_types-option = 'EQ'.
    ls_types-low    = 'M'.
    ls_types-high   = 'P'.

**Almacenamos las factruras, notas de crédito y notas de cargo que no estén anuladas y que estén contabilizadas en un intervalo de fechas en una work area.
*    SELECT * FROM vbrk
*      INTO CORRESPONDING FIELDS OF gs_vbrk
*      WHERE vbtyp EQ 'M' OR vbtyp EQ 'O' OR vbtyp EQ 'P'
*      AND fksto NE 'X'
*      AND fkdat GE lv_fechaini
*      AND fkdat LE lv_fechafin
*      AND belnr NE ''.
**Se hace el llenado de la tabla interna gt_vbrk a partir del work area gs_vbrk.
*      IF gs_vbrk-belnr NE '' AND gs_vbrk-gjahr NE '0000'.
*        APPEND gs_vbrk TO gt_vbrk.
*      ENDIF.
*      CLEAR gs_vbrk.
*    ENDSELECT.

*Almacenamos las factruras, notas de crédito y notas de cargo que no estén anuladas y que estén contabilizadas en un intervalo de fechas en una work area.
    SELECT * FROM vbrk
      WHERE fksto NE 'X'
      AND fkdat BETWEEN @ls_dates-low AND  @ls_dates-high
      AND belnr NE ''
      AND vbtyp BETWEEN @ls_types-low AND @ls_types-high
      INTO TABLE @gt_vbrk.

*Tablas necesarias para armado de response
    SELECT * FROM vbpa
      FOR ALL ENTRIES IN @gt_vbrk
      WHERE vbeln EQ @gt_vbrk-vbeln
      AND posnr EQ '000000'
      INTO TABLE @DATA(gt_vbpa).

    IF NOT gt_vbpa[] IS INITIAL.
      SELECT * FROM adrc
        FOR ALL ENTRIES IN @gt_vbpa
        WHERE addrnumber EQ @gt_vbpa-adrnr
        INTO TABLE @DATA(gt_adrc).
    ENDIF.

    SELECT * FROM kna1
      FOR ALL ENTRIES IN @gt_vbrk
      WHERE kunnr EQ @gt_vbrk-kunag
      INTO TABLE @DATA(gt_kna1).

    SELECT * FROM vbfa
      FOR ALL ENTRIES IN @gt_vbrk
      WHERE vbeln EQ @gt_vbrk-vbeln
      INTO TABLE @DATA(gt_vbfa).

*Comienza loop para llenado del response.
    LOOP AT gt_vbrk ASSIGNING FIELD-SYMBOL(<fs_vbrk>).

      gs_cfdi_monitor-sociedad       = <fs_vbrk>-bukrs.
      gs_cfdi_monitor-factura        = <fs_vbrk>-vbeln.
      gs_cfdi_monitor-anio           = <fs_vbrk>-gjahr.
      gs_cfdi_monitor-tipodocumento  = <fs_vbrk>-vbtyp.
      gs_cfdi_monitor-fechadocumento = <fs_vbrk>-fkdat.
      gs_cfdi_monitor-numerocliente  = <fs_vbrk>-kunag.
      gs_cfdi_monitor-importe        = <fs_vbrk>-netwr.

      lv_vtweg = <fs_vbrk>-vtweg.
      lv_vbtyp = <fs_vbrk>-vbtyp.

      SELECT SINGLE xcpdk INTO @lv_cpd
        FROM kna1
        WHERE kunnr EQ @<fs_vbrk>-kunag.

      IF lv_cpd EQ 'X'.
*        SELECT SINGLE b~name1 b~name2 INTO ( lv_name1_ag, lv_name2_ag )
*          FROM vbpa AS a
*          INNER JOIN adrc AS b ON b~addrnumber EQ a~adrnr
*          WHERE a~vbeln EQ <fs_vbrk>-vbeln
*          AND a~posnr EQ '000000'
*          AND a~parvw EQ 'AG'.

        READ TABLE gt_vbpa ASSIGNING FIELD-SYMBOL(<fs_vbpa>) WITH KEY vbeln = <fs_vbrk>-vbeln parvw = 'AG'.

        IF <fs_vbpa> IS ASSIGNED.
          READ TABLE gt_adrc ASSIGNING FIELD-SYMBOL(<fs_adrc>) WITH KEY addrnumber = <fs_vbpa>-adrnr.
          IF <fs_adrc> IS ASSIGNED.
            lv_name1_ag = <fs_adrc>-name1.
            lv_name2_ag = <fs_adrc>-name2.
            CONCATENATE lv_name1_ag lv_name2_ag INTO gs_cfdi_monitor-nombrecliente SEPARATED BY space.
            CONDENSE gs_cfdi_monitor-nombrecliente.
          ENDIF.
        ENDIF.
        UNASSIGN: <fs_vbpa>, <fs_adrc>.
      ELSE.
*        SELECT SINGLE name1 name2 INTO ( lv_name1_ag, lv_name2_ag )
*          FROM kna1
*          WHERE kunnr EQ gs_cfdi_monitor-numerocliente.

        READ TABLE gt_kna1 ASSIGNING FIELD-SYMBOL(<fs_kna1>) WITH KEY kunnr = <fs_vbrk>-kunag.
        IF <fs_kna1> IS ASSIGNED.
          lv_name1_ag = <fs_kna1>-name1.
          lv_name2_ag = <fs_kna1>-name2.
          CONCATENATE lv_name1_ag lv_name2_ag INTO gs_cfdi_monitor-nombrecliente SEPARATED BY space.
          CONDENSE gs_cfdi_monitor-nombrecliente.
          UNASSIGN <fs_kna1>.
        ENDIF.
      ENDIF.
      CLEAR lv_cpd.

*Búsqueda de pedido relacionado a la factura para obtener datos de pedido de cliente.
*      SELECT SINGLE vbelv INTO ( lv_salesorder )
*        FROM vbfa
*        WHERE vbeln EQ <fs_vbrk>-vbeln
*        AND vbtyp_v EQ 'C'.

      READ TABLE gt_vbfa ASSIGNING FIELD-SYMBOL(<fs_vbfa>) WITH KEY vbeln = <fs_vbrk>-vbeln vbtyp_v = 'C'.
      IF <fs_vbfa> IS ASSIGNED.
        SELECT SINGLE bstkd INTO gs_cfdi_monitor-pedidocliente
          FROM vbkd
          WHERE vbeln EQ <fs_vbfa>-vbelv
          AND posnr EQ '000000'.
        UNASSIGN <fs_vbfa>.
      ENDIF.
*Búsqueda de entrega relacionada a la factura para obtener datos de destinatario y puesto de expedición.
*      SELECT SINGLE vbelv INTO ( lv_delivery )
*        FROM vbfa
*        WHERE vbeln EQ <fs_vbrk>-vbeln
*        AND vbtyp_v EQ 'J'.

      READ TABLE gt_vbfa ASSIGNING <fs_vbfa> WITH KEY vbeln = <fs_vbrk>-vbeln vbtyp_v = 'J'.
      IF <fs_vbfa> IS ASSIGNED.
        SELECT SINGLE vstel kunnr INTO ( lv_pexped, gs_cfdi_monitor-destinatariomercancia )
          FROM likp
          WHERE vbeln EQ <fs_vbfa>-vbelv.
        UNASSIGN <fs_vbfa>.
      ENDIF.

      SELECT SINGLE werks INTO lv_werks
        FROM vbrp
        WHERE vbeln EQ <fs_vbrk>-vbeln.

*Se obtiene la serie del documento de la tabla ZPARAMGLOB.
      "Serie
      SELECT SINGLE valor5 INTO gs_cfdi_monitor-serie
        FROM zparamglob
        WHERE programa EQ 'ZCFDI_MONITOR'
        AND parametro EQ '2'
        AND valor1 EQ lv_werks
        AND valor2 EQ lv_vtweg
        AND valor3 EQ lv_vbtyp.

      SELECT SINGLE xcpdk INTO lv_cpd
          FROM kna1
          WHERE kunnr EQ gs_cfdi_monitor-destinatariomercancia.

      IF lv_cpd EQ 'X'.
*        SELECT SINGLE b~name1 b~name2 INTO ( lv_name1_we, lv_name2_we )
*          FROM vbpa AS a
*          INNER JOIN adrc AS b ON b~addrnumber EQ a~adrnr
*          WHERE a~vbeln EQ lv_delivery
*          AND a~posnr EQ '000000'
*          AND a~parvw EQ 'WE'.

        READ TABLE gt_vbpa ASSIGNING <fs_vbpa> WITH KEY vbeln = <fs_vbrk>-vbeln parvw = 'WE'.

        IF <fs_vbpa> IS ASSIGNED.
          READ TABLE gt_adrc ASSIGNING <fs_adrc> WITH KEY addrnumber = <fs_vbpa>-adrnr.
          IF <fs_adrc> IS ASSIGNED.
            lv_name1_we = <fs_adrc>-name1.
            lv_name2_we = <fs_adrc>-name2.
            CONCATENATE lv_name1_we lv_name2_we INTO gs_cfdi_monitor-nombredestinatario SEPARATED BY space.
            CONDENSE gs_cfdi_monitor-nombredestinatario.
          ENDIF.
        ENDIF.
        UNASSIGN: <fs_vbpa>, <fs_adrc>.
      ELSE.
*        SELECT SINGLE name1 name2 INTO ( lv_name1_we, lv_name2_we )
*          FROM kna1
*          WHERE kunnr EQ gs_cfdi_monitor-destinatariomercancia.

         READ TABLE gt_kna1 ASSIGNING <fs_kna1> WITH KEY kunnr = gs_cfdi_monitor-destinatariomercancia.
        IF <fs_kna1> IS ASSIGNED.
          lv_name1_we = <fs_kna1>-name1.
          lv_name2_we = <fs_kna1>-name2.
          CONCATENATE lv_name1_we lv_name2_we INTO gs_cfdi_monitor-nombredestinatario SEPARATED BY space.
          CONDENSE gs_cfdi_monitor-nombredestinatario.
          UNASSIGN <fs_kna1>.
        ENDIF.
      ENDIF.
      CLEAR lv_cpd.

*Se busca el UUID y Fecha de timbrado para cada factura.
      SELECT SINGLE uuid fectimbre INTO ( gs_cfdi_monitor-foliofiscal, gs_cfdi_monitor-fechatimbrado )
        FROM zsd_cfdi_return
        WHERE nodocu EQ <fs_vbrk>-vbeln.

*Se valida que se envíen solamente los documentos que no han sido timbrados.
      IF gs_cfdi_monitor-foliofiscal EQ ''.
        APPEND gs_cfdi_monitor TO et_entityset.
      ENDIF.
      CLEAR: gs_cfdi_monitor.
    ENDLOOP.
    UNASSIGN <fs_vbrk>.
  ENDMETHOD.


  METHOD regenerapdfset_update_entity.
    DATA: gs_regenerapdf TYPE zcl_zsd_cfdi_mpc_ext=>ts_regenerapdf,
          gs_cfdireturn  TYPE zsd_cfdi_return,
          lo_msg         TYPE REF TO /iwbep/if_message_container,
          lv_error_msg   TYPE bapi_msg,
          lv_vbeln       TYPE vbrk-vbeln,
          lv_anulada     TYPE vbrk-fksto,
          ls_header_inx  TYPE bapisdh1x,
          ls_header_in   TYPE bapisdh1,
          lt_return_so   TYPE STANDARD TABLE OF bapiret2,
          lv_cancelada   TYPE c LENGTH 1,
          lv_uuid        TYPE c LENGTH 36,
          lv_pdfant      TYPE string,
          lt_srgbtbrel   TYPE STANDARD TABLE OF srgbtbrel,
          ls_srgbtbrel   TYPE srgbtbrel,
          lt_sood        TYPE STANDARD TABLE OF sood,
          ls_sood        TYPE sood,
          lv_objtp       TYPE sood-objtp,
          lv_objyr       TYPE sood-objyr,
          lv_objno       TYPE sood-objno,
          lv_objfo       TYPE c LENGTH 17.

**Declaración de tablas
    DATA: lt_return  TYPE STANDARD TABLE OF bapiret2,
          lt_success TYPE STANDARD TABLE OF bapivbrksuccess,
          ls_return  TYPE bapiret2,
          ls_success TYPE bapivbrksuccess.

    DATA: gt_file_table TYPE filetable,
          gt_content    TYPE soli_tab,
          gs_fol_id     TYPE soodk,
          gs_obj_id     TYPE soodk,
          gv_ext        TYPE sood1-file_ext,
          gv_fname      TYPE sood1-objdes,
          ls_obj_data   TYPE sood1,
          lt_objhead    TYPE STANDARD TABLE OF soli,
          ls_folmem_k   TYPE sofmk,
          ls_note       TYPE borident,
          lv_ep_note    TYPE borident-objkey,
          ls_object     TYPE borident,
          gs_filebase64 TYPE string,
          lv_filexml    TYPE string,
          lv_filepdf    TYPE string,
          gs_filedecode TYPE xstring,
          lt_filedecode TYPE solix_tab,
          lv_length     TYPE i,
          i_attsrv      TYPE REF TO cl_gos_document_service,
          i_boridenta   TYPE borident,
          i_boridentb   TYPE borident.

    CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~get_message_container
      RECEIVING
        ro_message_container = lo_msg.

*Lectura del request recibido en el método POST.
    TRY.
        CALL METHOD io_data_provider->read_entry_data
          IMPORTING
            es_data = gs_regenerapdf.
      CATCH /iwbep/cx_mgw_tech_exception.
    ENDTRY.

*Convertimos el valor recibido en el tipo de dato de la variable gs_timbrefiscal-nodocu al tipo de dato vbrk-vbeln para que los select a las tablas de facturas sean correctos.
    lv_vbeln = |{ gs_regenerapdf-folio ALPHA = IN }|.

*Se valida que se mande un número de factura en el request.
    IF gs_regenerapdf-folio EQ ''.
      lv_error_msg = 'Por favor indique un número de factura.'.
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

*Se valida si la factura existe.
    SELECT SINGLE vbeln INTO @DATA(lv_vbeln1)
      FROM vbrk
      WHERE vbeln EQ @lv_vbeln.

    IF sy-subrc NE 0.
      CONCATENATE 'La factura' gs_regenerapdf-folio 'no existe en la base de datos, favor de verificar' INTO lv_error_msg SEPARATED BY space.
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

*Se valida si la factura se encuentra anulada en SAP, si es así no se actualiza y se manda mensaje de error.

    SELECT SINGLE fksto INTO @lv_anulada
      FROM vbrk
      WHERE vbeln EQ @lv_vbeln.

    IF lv_anulada EQ 'X'.
      CONCATENATE 'La factura' gs_regenerapdf-folio 'se encuentra anulada en SAP, no se actualizarán los datos enviados.' INTO lv_error_msg SEPARATED BY space.
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

*Se valida si el documento está cancelado ante el SAT.
    SELECT SINGLE cancelado INTO @lv_cancelada
      FROM zsd_cfdi_return
      WHERE nodocu EQ @lv_vbeln.

    IF lv_cancelada EQ 'X'.
      CONCATENATE 'La factura' gs_regenerapdf-folio 'ya se encuentra cancelada ante el SAT, no se actualizarán los datos enviados' INTO lv_error_msg SEPARATED BY space.
      CALL METHOD lo_msg->add_message
        EXPORTING
          iv_msg_type   = /iwbep/cl_cos_logger=>error
          iv_msg_id     = 'ZSD_MSG'
          iv_msg_number = '004'
          iv_msg_text   = lv_error_msg.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ENDIF.

*Se valida si el documento está timbrado.
    SELECT SINGLE uuid INTO @lv_uuid
      FROM zsd_cfdi_return
      WHERE nodocu EQ @lv_vbeln.

    IF lv_uuid EQ ''.
      CONCATENATE 'La factura' gs_regenerapdf-folio 'aún no ha sido timbrada, no podrá regenerar el PDF.' INTO lv_error_msg SEPARATED BY space.
      CALL METHOD lo_msg->add_message
        EXPORTING
          iv_msg_type   = /iwbep/cl_cos_logger=>error
          iv_msg_id     = 'ZSD_MSG'
          iv_msg_number = '005'
          iv_msg_text   = lv_error_msg.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ENDIF.

*Almacenamos el string del PDF antes de ser actualizado para comparar y si son diferentes después del update se haga el borrado de anexo y carga del nuevo PDF
    SELECT SINGLE pdf INTO lv_pdfant
      FROM zsd_cfdi_return
      WHERE nodocu EQ gs_regenerapdf-folio.

    gs_cfdireturn-pdf = gs_regenerapdf-pdfb64.

*Actualiza el registro en la tabla zsd_cfdi_return.
    UPDATE zsd_cfdi_return
      SET pdf = gs_cfdireturn-pdf
      WHERE nodocu EQ gs_regenerapdf-folio.
    CLEAR gs_cfdireturn.

*Se valida si el documento se insertó a la tabla zsd_cfdi_return correctamente.
    SELECT * FROM zsd_cfdi_return
      INTO CORRESPONDING FIELDS OF gs_cfdireturn
      WHERE nodocu EQ lv_vbeln.
    ENDSELECT.

    IF gs_cfdireturn-pdf NE lv_pdfant.
      MOVE-CORRESPONDING gs_cfdireturn TO er_entity.

      IF gs_cfdireturn-noerror EQ ''.

        SELECT * FROM vbrk
        WHERE vbeln EQ @lv_vbeln
        INTO TABLE @DATA(gt_vbrk).

*Se elimina el PDF adjunto a la factura antes de cargar el nuevo PDF.
        SELECT * FROM srgbtbrel
          WHERE reltype EQ 'ATTA'
          AND instid_a  EQ @lv_vbeln
          AND typeid_a  EQ 'VBRK'
          AND catid_a   EQ 'BO'
          INTO TABLE @lt_srgbtbrel.

        IF sy-subrc EQ 0.
          LOOP AT lt_srgbtbrel INTO ls_srgbtbrel.

            i_boridenta-objkey  = ls_srgbtbrel-instid_a.
            i_boridenta-objtype = ls_srgbtbrel-typeid_a.

            i_boridentb-objkey  = ls_srgbtbrel-instid_b.
            i_boridentb-objtype = ls_srgbtbrel-typeid_b.

            gs_fol_id-objtp = ls_srgbtbrel-instid_b+0(3).
            gs_fol_id-objyr = ls_srgbtbrel-instid_b+3(2).
            gs_fol_id-objno = ls_srgbtbrel-instid_b+5(12).

            gs_obj_id-objtp = ls_srgbtbrel-instid_b+17(3).
            gs_obj_id-objyr = ls_srgbtbrel-instid_b+20(2).
            gs_obj_id-objno = ls_srgbtbrel-instid_b+22(12).

            SELECT * FROM sood
              WHERE objtp EQ @gs_obj_id-objtp
              AND objyr EQ @gs_obj_id-objyr
              AND objno EQ @gs_obj_id-objno

              AND ( file_ext EQ 'pdf' OR file_ext EQ 'PDF' )
              INTO TABLE @lt_sood.

            IF sy-subrc EQ 0.
              LOOP AT lt_sood INTO ls_sood.
                CALL FUNCTION 'BINARY_RELATION_DELETE'
                  EXPORTING
                    obj_rolea          = i_boridenta
                    obj_roleb          = i_boridentb
                    relationtype       = 'ATTA'
                  EXCEPTIONS
                    entry_not_existing = 1
                    internal_error     = 2
                    no_relation        = 3
                    no_role            = 4
                    OTHERS             = 5.

                CALL FUNCTION 'SO_OBJECT_DELETE'
                  EXPORTING
                    folder_id                  = gs_fol_id
                    object_id                  = gs_obj_id
                  EXCEPTIONS
                    communication_failure      = 1
                    folder_not_empty           = 2
                    folder_not_exist           = 3
                    folder_no_authorization    = 4
                    forwarder_not_exist        = 5
                    object_not_exist           = 6
                    object_no_authorization    = 7
                    operation_no_authorization = 8
                    owner_not_exist            = 9
                    substitute_not_active      = 10
                    substitute_not_defined     = 11
                    system_failure             = 12
                    x_error                    = 13
                    OTHERS                     = 14.
                IF sy-subrc EQ 0.
                  COMMIT WORK AND WAIT.
                ENDIF.
              ENDLOOP.
            ENDIF.
            CLEAR: ls_srgbtbrel, i_boridenta, i_boridentb, lv_objfo, lv_objtp, lv_objyr, lv_objno.
          ENDLOOP.
        ENDIF.

*Se adjunta PDF regenerado en la factura.
        IF gs_cfdireturn-pdf NE ''.

          lv_length = strlen( gs_cfdireturn-pdf ).
*1. Se decodifica el fichero recibido en BASE64 y se deja en una variable tipo XSTRING (fichero en hexadecimal).
          CALL FUNCTION 'SSFC_BASE64_DECODE'
            EXPORTING
              b64data = gs_cfdireturn-pdf
              b64leng = lv_length
            IMPORTING
              bindata = gs_filedecode.
*2. Se convierte la variable XSTRING (hexadecimal) a STRING (cadena de texto) para obtener el tamaño del fichero
          CALL METHOD cl_bcs_convert=>xstring_to_string
            EXPORTING
              iv_xstr   = gs_filedecode
              iv_cp     = 1100
            RECEIVING
              rv_string = lv_filepdf.
*3. Obtenemos el tamaño real del fichero y se almacena en la variable lv_length que se utilizará para insertar el documento con GOS ***Este paso es muy importante, ya que de no enviar el tamaño correcto, se provoca error al abrir el fichero (XML)
          lv_length = strlen( lv_filepdf ).
*4. Pasamos el fichero hexadecimal a una tabla.
          CALL METHOD cl_bcs_convert=>xstring_to_solix
            EXPORTING
              iv_xstring = gs_filedecode
            RECEIVING
              et_solix   = lt_filedecode.
*5. Convertimos la tabla hexadecimal a binario
          CALL FUNCTION 'SO_SOLIXTAB_TO_SOLITAB'
            EXPORTING
              ip_solixtab = lt_filedecode
            IMPORTING
              ep_solitab  = gt_content.
*6. Se prepara el GOS para recibir el fichero
          CALL FUNCTION 'SO_FOLDER_ROOT_ID_GET'
            EXPORTING
              region    = 'B'
            IMPORTING
              folder_id = gs_fol_id
            EXCEPTIONS
              OTHERS    = 1.

          CONCATENATE gs_cfdireturn-serie gs_cfdireturn-nodocu INTO gv_fname.
          gv_ext = 'pdf'.

          ls_obj_data-objsns   = 'O'.
          ls_obj_data-objla    = sy-langu.
          ls_obj_data-objdes   = gv_fname.
          ls_obj_data-file_ext = gv_ext.
*En la mayoría de referencias, se indica que se obtenga el tamaño del fichero multiplicando el número de líneas de la tabla que contiene el archivo binario por 255 que es la cantidad de cartacteres que admite cada registro
*de la tabla. Si lo hacemos así, hay una gran posibilidad de provocar un error cuando se intenta abrir el fichero debido a que el sistema tratará de "completar" el archivo para alcanzar el tamaño indicado
*en el caso de ficheros XML, se añaden valores NUL al final de éste y no es posible leerlo en el navegador. Por eso es importante obtener el valor real del fichero como se hace en los pasos 2 y 3.
*          ls_obj_data-objlen   = lines( gt_content ) * 255.
          ls_obj_data-objlen   = lv_length.
          CONDENSE ls_obj_data-objlen.
*7. Se inserta el fichero en GOS.
          CALL FUNCTION 'SO_OBJECT_INSERT'
            EXPORTING
              folder_id             = gs_fol_id
              object_type           = 'EXT'
              object_hd_change      = ls_obj_data
            IMPORTING
              object_id             = gs_obj_id
            TABLES
              objhead               = lt_objhead
              objcont               = gt_content
            EXCEPTIONS
              active_user_not_exist = 35
              folder_not_exist      = 6
              object_type_not_exist = 17
              owner_not_exist       = 22
              parameter_error       = 23
              OTHERS                = 1000.

          ls_object-objkey = gs_cfdireturn-nodocu.
          ls_object-objtype = 'VBRK'.
          ls_note-objtype   = 'MESSAGE'.

          CONCATENATE gs_fol_id-objtp gs_fol_id-objyr gs_fol_id-objno gs_obj_id-objtp gs_obj_id-objyr gs_obj_id-objno INTO ls_note-objkey.
*8. Se relaciona el fichero recién insertado con el objeto SAP
          CALL FUNCTION 'BINARY_RELATION_CREATE_COMMIT'
            EXPORTING
              obj_rolea    = ls_object
              obj_roleb    = ls_note
              relationtype = 'ATTA'
            EXCEPTIONS
              OTHERS       = 1.


        ENDIF.
        CLEAR: gs_filedecode, lt_filedecode, gt_content, gs_fol_id, ls_obj_data, ls_object, lt_objhead, ls_note, lv_filepdf.

        CONCATENATE 'Se actualizó el PSD de la factura' gs_cfdireturn-nodocu 'con el UUID: ' gs_cfdireturn-uuid INTO lv_error_msg SEPARATED BY space.
        CALL METHOD lo_msg->add_message
          EXPORTING
            iv_msg_type   = /iwbep/cl_cos_logger=>success
            iv_msg_id     = 'ZSD_MSG'
            iv_msg_number = '006'
            iv_msg_text   = lv_error_msg.

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
          EXPORTING
            message_container = lo_msg.
      ENDIF.
    ENDIF.
    CLEAR gs_cfdireturn.
  ENDMETHOD.


  METHOD timbrefiscalset_create_entity.
    DATA: gs_timbrefiscal TYPE zcl_zsd_cfdi_mpc_ext=>ts_timbrefiscal,
          gs_cfdireturn   TYPE zsd_cfdi_return,
          lo_msg          TYPE REF TO /iwbep/if_message_container,
          lv_error_msg    TYPE bapi_msg,
          lv_vbeln        TYPE vbrk-vbeln.

    DATA: gt_content    TYPE soli_tab,
          gs_fol_id     TYPE soodk,
          gs_obj_id     TYPE soodk,
          gv_ext        TYPE sood1-file_ext,
          gv_fname      TYPE sood1-objdes,
          ls_obj_data   TYPE sood1,
          lt_objhead    TYPE STANDARD TABLE OF soli,
          ls_note       TYPE borident,
          ls_object     TYPE borident,
          gs_filedecode TYPE xstring,
          lt_filedecode TYPE solix_tab,
          lv_length     TYPE i,
          lv_filexml    TYPE string,
          lv_filepdf    TYPE string.

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

*Convertimos el valor recibido en el tipo de dato de la variable gs_timbrefiscal-nodocu al tipo de dato vbrk-vbeln para que los select a las tablas de facturas sean correctos.
    lv_vbeln = |{ gs_timbrefiscal-nodocu ALPHA = IN }|.

*Se valida que se mande un número de factura en el request.
    IF gs_timbrefiscal-nodocu EQ ''.
      CONCATENATE 'Por favor indique un número de factura para poder guardar el folio fiscal' gs_timbrefiscal-uuid INTO lv_error_msg SEPARATED BY space.
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

*Se valida si la factura existe.
    SELECT SINGLE vbeln INTO @DATA(lv_vbeln1)
      FROM vbrk
      WHERE vbeln EQ @lv_vbeln.

    IF sy-subrc NE 0.
      CONCATENATE 'La factura' gs_timbrefiscal-nodocu 'no existe en la base de datos, favor de verificar' INTO lv_error_msg SEPARATED BY space.
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

*Se valida si el documento ya se encuentra timbrado antes de hacer el insert.
    SELECT SINGLE uuid, fectimbre INTO ( @DATA(lv_uuid), @DATA(lv_fectimbre) )
      FROM zsd_cfdi_return
      WHERE nodocu EQ @lv_vbeln.

    IF lv_uuid NE '' AND lv_fectimbre NE ''.
      CONCATENATE 'La factura' gs_timbrefiscal-nodocu 'ya se encuentra timbrada con el folio fiscal' lv_uuid 'de fecha' lv_fectimbre INTO lv_error_msg SEPARATED BY space.
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

    gs_cfdireturn-mandt          = sy-mandt.
    gs_cfdireturn-serie          = gs_timbrefiscal-serie.
    gs_cfdireturn-nodocu         = gs_timbrefiscal-nodocu.
    gs_cfdireturn-uuid           = gs_timbrefiscal-uuid.
    gs_cfdireturn-fectimbre      = gs_timbrefiscal-fectimbre.
    gs_cfdireturn-rfcproovcertif = gs_timbrefiscal-rfcproovcertif.
    gs_cfdireturn-sellocfd       = gs_timbrefiscal-sellocfd.
    gs_cfdireturn-certificadosat = gs_timbrefiscal-certificadosat.
    gs_cfdireturn-sellosat       = gs_timbrefiscal-sellosat.
    gs_cfdireturn-cancelado      = gs_timbrefiscal-cancelado.
    gs_cfdireturn-xml            = gs_timbrefiscal-xml.
    gs_cfdireturn-pdf            = gs_timbrefiscal-pdf.
    gs_cfdireturn-status         = gs_timbrefiscal-status.
    gs_cfdireturn-noerror        = gs_timbrefiscal-noerror.
    gs_cfdireturn-mensaje        = gs_timbrefiscal-mensaje.

*Se valida si el PAC regresa los campos necesarios para el llenado de la tabla zsd_cfdi_return.
    IF gs_cfdireturn-noerror EQ ''.
      IF gs_cfdireturn-uuid EQ '' OR gs_cfdireturn-fectimbre EQ '' OR gs_cfdireturn-rfcproovcertif EQ '' OR gs_cfdireturn-sellocfd EQ '' OR gs_cfdireturn-certificadosat EQ '' OR gs_cfdireturn-sellosat EQ ''.

        IF gs_cfdireturn-uuid EQ ''.
          CONCATENATE 'Por favor indique el folio fiscal (UUID) para la factura' gs_timbrefiscal-nodocu INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZSD_MSG'
              iv_msg_number = '004'
              iv_msg_text   = lv_error_msg.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg.
        ENDIF.

        IF gs_cfdireturn-fectimbre EQ ''.
          CONCATENATE 'Por favor indique la fecha de timbrado para la factura' gs_timbrefiscal-nodocu INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZSD_MSG'
              iv_msg_number = '005'
              iv_msg_text   = lv_error_msg.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg.
        ENDIF.

        IF gs_cfdireturn-rfcproovcertif EQ ''.
          CONCATENATE 'Por favor indique el RFC del PAC para la factura' gs_timbrefiscal-nodocu INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZSD_MSG'
              iv_msg_number = '006'
              iv_msg_text   = lv_error_msg.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg.
        ENDIF.

        IF gs_cfdireturn-sellocfd EQ ''.
          CONCATENATE 'Por favor indique el sello del CFD para la factura' gs_timbrefiscal-nodocu INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZSD_MSG'
              iv_msg_number = '007'
              iv_msg_text   = lv_error_msg.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg.
        ENDIF.

        IF gs_cfdireturn-certificadosat EQ ''.
          CONCATENATE 'Por favor indique el número de certificado SAT para la factura' gs_timbrefiscal-nodocu INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZSD_MSG'
              iv_msg_number = '008'
              iv_msg_text   = lv_error_msg.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg.
        ENDIF.

        IF gs_cfdireturn-sellosat EQ ''.
          CONCATENATE 'Por favor indique el sello SAT para la factura' gs_timbrefiscal-nodocu INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZSD_MSG'
              iv_msg_number = '009'
              iv_msg_text   = lv_error_msg.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg.
        ENDIF.
      ENDIF.
    ENDIF.

*Inserta el registro en la tabla zsd_cfdi_return.
    INSERT zsd_cfdi_return FROM gs_cfdireturn.
    CLEAR gs_cfdireturn.

*Se valida si el documento se insertó a la tabla zsd_cfdi_return correctamente.
    SELECT * FROM zsd_cfdi_return
      INTO CORRESPONDING FIELDS OF gs_cfdireturn
      WHERE nodocu EQ lv_vbeln.
    ENDSELECT.

    IF sy-subrc EQ 0.
      MOVE-CORRESPONDING gs_cfdireturn TO er_entity.

      SELECT * FROM vbrk
        WHERE vbeln EQ @lv_vbeln
        INTO TABLE @DATA(gt_vbrk).

      IF gs_cfdireturn-noerror EQ ''.
*Buscamos el documento contable relacionado a la factura en la tabla BSID (documentos no compensados).
        LOOP AT gt_vbrk INTO DATA(gs_vbrk).
          SELECT * FROM bsid_view
            WHERE bukrs EQ @gs_vbrk-bukrs
            AND kunnr EQ @gs_vbrk-kunrg
            AND vbeln EQ @gs_vbrk-vbeln
            AND blart EQ 'RV'
            INTO TABLE @DATA(gt_bsid).
*        ENDSELECT.

*Si no se encuentra el documento contable en BSID, buscamos el documento contable relacionado a la factura en la tabla BSAD (documentos compensados).
          IF sy-subrc NE 0.
            SELECT * FROM bsad_view
              WHERE bukrs EQ @gs_vbrk-bukrs
              AND kunnr EQ @gs_vbrk-kunrg
              AND vbeln EQ @gs_vbrk-vbeln
              AND blart EQ 'RV'
              INTO TABLE @DATA(gt_bsad).
*          ENDSELECT.
          ENDIF.
        ENDLOOP.
*    ENDSELECT.

*Se envía el UUID a la tabla BKPF
        IF NOT gt_bsid IS INITIAL.
          LOOP AT gt_bsid INTO DATA(gs_bsid).
            UPDATE bkpf SET glo_ref1_hd = gs_cfdireturn-uuid
            WHERE bukrs = gs_bsid-bukrs AND belnr = gs_bsid-belnr AND gjahr = gs_bsid-gjahr.
          ENDLOOP.
        ELSEIF NOT gt_bsad IS INITIAL.
          LOOP AT gt_bsad INTO DATA(gs_bsad).
            UPDATE bkpf SET glo_ref1_hd = gs_cfdireturn-uuid
            WHERE bukrs = gs_bsad-bukrs AND belnr = gs_bsad-belnr AND gjahr = gs_bsad-gjahr.
          ENDLOOP.
        ENDIF.

*Se adjuntan el XML y PDF en la factura.
        IF gs_cfdireturn-xml NE ''.

          lv_length = strlen( gs_cfdireturn-xml ).
*1. Se decodifica el fichero recibido en BASE64 y se deja en una variable tipo XSTRING (fichero en hexadecimal).
          CALL FUNCTION 'SSFC_BASE64_DECODE'
            EXPORTING
              b64data = gs_cfdireturn-xml
              b64leng = lv_length
            IMPORTING
              bindata = gs_filedecode.
*2. Se convierte la variable XSTRING (hexadecimal) a STRING (cadena de texto) para obtener el tamaño del fichero
          CALL METHOD cl_bcs_convert=>xstring_to_string
            EXPORTING
              iv_xstr   = gs_filedecode
              iv_cp     = 1100
            RECEIVING
              rv_string = lv_filexml.
*3. Obtenemos el tamaño real del fichero y se almacena en la variable lv_length que se utilizará para insertar el documento con GOS ***Este paso es muy importante, ya que de no enviar el tamaño correcto, se provoca error al abrir el fichero (XML)
          lv_length = strlen( lv_filexml ).
*4. Pasamos el fichero hexadecimal a una tabla.
          CALL METHOD cl_bcs_convert=>xstring_to_solix
            EXPORTING
              iv_xstring = gs_filedecode
            RECEIVING
              et_solix   = lt_filedecode.
*5. Convertimos la tabla hexadecimal a binario
          CALL FUNCTION 'SO_SOLIXTAB_TO_SOLITAB'
            EXPORTING
              ip_solixtab = lt_filedecode
            IMPORTING
              ep_solitab  = gt_content.
*6. Se prepara el GOS para recibir el fichero
          CALL FUNCTION 'SO_FOLDER_ROOT_ID_GET'
            EXPORTING
              region    = 'B'
            IMPORTING
              folder_id = gs_fol_id
            EXCEPTIONS
              OTHERS    = 1.

          CONCATENATE gs_cfdireturn-serie gs_cfdireturn-nodocu INTO gv_fname.
          gv_ext = 'xml'.

          ls_obj_data-objsns   = 'O'.
          ls_obj_data-objla    = sy-langu.
          ls_obj_data-objdes   = gv_fname.
          ls_obj_data-file_ext = gv_ext.
*En la mayoría de referencias, se indica que se obtenga el tamaño del fichero multiplicando el número de líneas de la tabla que contiene el archivo binario por 255 que es la cantidad de cartacteres que admite cada registro
*de la tabla. Si lo hacemos así, hay una gran posibilidad de provocar un error cuando se intenta abrir el fichero debido a que el sistema tratará de "completar" el archivo para alcanzar el tamaño indicado
*en el caso de ficheros XML, se añaden valores NUL al final de éste y no es posible leerlo en el navegador. Por eso es importante obtener el valor real del fichero como se hace en los pasos 2 y 3.
*          ls_obj_data-objlen   = lines( gt_content ) * 255.
          ls_obj_data-objlen   = lv_length.
          CONDENSE ls_obj_data-objlen.
*7. Se inserta el fichero en GOS.
          CALL FUNCTION 'SO_OBJECT_INSERT'
            EXPORTING
              folder_id             = gs_fol_id
              object_type           = 'EXT'
              object_hd_change      = ls_obj_data
            IMPORTING
              object_id             = gs_obj_id
            TABLES
              objhead               = lt_objhead
              objcont               = gt_content
            EXCEPTIONS
              active_user_not_exist = 35
              folder_not_exist      = 6
              object_type_not_exist = 17
              owner_not_exist       = 22
              parameter_error       = 23
              OTHERS                = 1000.

          ls_object-objkey = gs_cfdireturn-nodocu.
          ls_object-objtype = 'VBRK'.
          ls_note-objtype   = 'MESSAGE'.

          CONCATENATE gs_fol_id-objtp gs_fol_id-objyr gs_fol_id-objno gs_obj_id-objtp gs_obj_id-objyr gs_obj_id-objno INTO ls_note-objkey.
*8. Se relaciona el fichero recién insertado con el objeto SAP
          CALL FUNCTION 'BINARY_RELATION_CREATE_COMMIT'
            EXPORTING
              obj_rolea    = ls_object
              obj_roleb    = ls_note
              relationtype = 'ATTA'
            EXCEPTIONS
              OTHERS       = 1.

        ENDIF.
        CLEAR: gs_filedecode, lt_filedecode, gt_content, gs_fol_id, ls_obj_data, ls_object, lt_objhead, ls_note, lv_filexml.

        IF gs_cfdireturn-pdf NE ''.

          lv_length = strlen( gs_cfdireturn-pdf ).
*1. Se decodifica el fichero recibido en BASE64 y se deja en una variable tipo XSTRING (fichero en hexadecimal).
          CALL FUNCTION 'SSFC_BASE64_DECODE'
            EXPORTING
              b64data = gs_cfdireturn-pdf
              b64leng = lv_length
            IMPORTING
              bindata = gs_filedecode.
*2. Se convierte la variable XSTRING (hexadecimal) a STRING (cadena de texto) para obtener el tamaño del fichero
          CALL METHOD cl_bcs_convert=>xstring_to_string
            EXPORTING
              iv_xstr   = gs_filedecode
              iv_cp     = 1100
            RECEIVING
              rv_string = lv_filepdf.
*3. Obtenemos el tamaño real del fichero y se almacena en la variable lv_length que se utilizará para insertar el documento con GOS ***Este paso es muy importante, ya que de no enviar el tamaño correcto, se provoca error al abrir el fichero (XML)
          lv_length = strlen( lv_filepdf ).
*4. Pasamos el fichero hexadecimal a una tabla.
          CALL METHOD cl_bcs_convert=>xstring_to_solix
            EXPORTING
              iv_xstring = gs_filedecode
            RECEIVING
              et_solix   = lt_filedecode.
*5. Convertimos la tabla hexadecimal a binario
          CALL FUNCTION 'SO_SOLIXTAB_TO_SOLITAB'
            EXPORTING
              ip_solixtab = lt_filedecode
            IMPORTING
              ep_solitab  = gt_content.
*6. Se prepara el GOS para recibir el fichero
          CALL FUNCTION 'SO_FOLDER_ROOT_ID_GET'
            EXPORTING
              region    = 'B'
            IMPORTING
              folder_id = gs_fol_id
            EXCEPTIONS
              OTHERS    = 1.

          CONCATENATE gs_cfdireturn-serie gs_cfdireturn-nodocu INTO gv_fname.
          gv_ext = 'pdf'.

          ls_obj_data-objsns   = 'O'.
          ls_obj_data-objla    = sy-langu.
          ls_obj_data-objdes   = gv_fname.
          ls_obj_data-file_ext = gv_ext.
*En la mayoría de referencias, se indica que se obtenga el tamaño del fichero multiplicando el número de líneas de la tabla que contiene el archivo binario por 255 que es la cantidad de cartacteres que admite cada registro
*de la tabla. Si lo hacemos así, hay una gran posibilidad de provocar un error cuando se intenta abrir el fichero debido a que el sistema tratará de "completar" el archivo para alcanzar el tamaño indicado
*en el caso de ficheros XML, se añaden valores NUL al final de éste y no es posible leerlo en el navegador. Por eso es importante obtener el valor real del fichero como se hace en los pasos 2 y 3.
*          ls_obj_data-objlen   = lines( gt_content ) * 255.
          ls_obj_data-objlen   = lv_length.
          CONDENSE ls_obj_data-objlen.
*7. Se inserta el fichero en GOS.
          CALL FUNCTION 'SO_OBJECT_INSERT'
            EXPORTING
              folder_id             = gs_fol_id
              object_type           = 'EXT'
              object_hd_change      = ls_obj_data
            IMPORTING
              object_id             = gs_obj_id
            TABLES
              objhead               = lt_objhead
              objcont               = gt_content
            EXCEPTIONS
              active_user_not_exist = 35
              folder_not_exist      = 6
              object_type_not_exist = 17
              owner_not_exist       = 22
              parameter_error       = 23
              OTHERS                = 1000.

          ls_object-objkey = gs_cfdireturn-nodocu.
          ls_object-objtype = 'VBRK'.
          ls_note-objtype   = 'MESSAGE'.

          CONCATENATE gs_fol_id-objtp gs_fol_id-objyr gs_fol_id-objno gs_obj_id-objtp gs_obj_id-objyr gs_obj_id-objno INTO ls_note-objkey.
*8. Se relaciona el fichero recién insertado con el objeto SAP
          CALL FUNCTION 'BINARY_RELATION_CREATE_COMMIT'
            EXPORTING
              obj_rolea    = ls_object
              obj_roleb    = ls_note
              relationtype = 'ATTA'
            EXCEPTIONS
              OTHERS       = 1.


        ENDIF.
        CLEAR: gs_filedecode, lt_filedecode, gt_content, gs_fol_id, ls_obj_data, ls_object, lt_objhead, ls_note, lv_filepdf.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD timbrefiscalset_update_entity.
    DATA: gs_timbrefiscal TYPE zcl_zsd_cfdi_mpc_ext=>ts_timbrefiscal,
          gs_cfdireturn   TYPE zsd_cfdi_return,
          lo_msg          TYPE REF TO /iwbep/if_message_container,
          lv_error_msg    TYPE bapi_msg,
          lv_vbeln        TYPE vbrk-vbeln,
          lv_anulada      TYPE vbrk-fksto,
          ls_header_inx   TYPE bapisdh1x,
          ls_header_in    TYPE bapisdh1,
          lt_return_so    TYPE STANDARD TABLE OF bapiret2,
          lv_cancelada    TYPE c LENGTH 1.

**Declaración de tablas
    DATA: lt_return  TYPE STANDARD TABLE OF bapiret2,
          lt_success TYPE STANDARD TABLE OF bapivbrksuccess,
          ls_return  TYPE bapiret2,
          ls_success TYPE bapivbrksuccess.

    DATA: gt_file_table TYPE filetable,
          gt_content    TYPE soli_tab,
          gs_fol_id     TYPE soodk,
          gs_obj_id     TYPE soodk,
          gv_ext        TYPE sood1-file_ext,
          gv_fname      TYPE sood1-objdes,
          ls_obj_data   TYPE sood1,
          lt_objhead    TYPE STANDARD TABLE OF soli,
          ls_folmem_k   TYPE sofmk,
          ls_note       TYPE borident,
          lv_ep_note    TYPE borident-objkey,
          ls_object     TYPE borident,
          gs_filebase64 TYPE string,
          lv_filexml    TYPE string,
          lv_filepdf    TYPE string,
          gs_filedecode TYPE xstring,
          lt_filedecode TYPE solix_tab,
          lv_length     TYPE i.

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

*Convertimos el valor recibido en el tipo de dato de la variable gs_timbrefiscal-nodocu al tipo de dato vbrk-vbeln para que los select a las tablas de facturas sean correctos.
    lv_vbeln = |{ gs_timbrefiscal-nodocu ALPHA = IN }|.

*Se valida que se mande un número de factura en el request.
    IF gs_timbrefiscal-nodocu EQ ''.
      CONCATENATE 'Por favor indique un número de factura para poder actualizar el documento' gs_timbrefiscal-uuid INTO lv_error_msg SEPARATED BY space.
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

*Se valida si la factura existe.
    SELECT SINGLE vbeln INTO @DATA(lv_vbeln1)
      FROM vbrk
      WHERE vbeln EQ @lv_vbeln.

    IF sy-subrc NE 0.
      CONCATENATE 'La factura' gs_timbrefiscal-nodocu 'no existe en la base de datos, favor de verificar' INTO lv_error_msg SEPARATED BY space.
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

*Se valida si la factura se encuentra anulada en SAP, si es así no se actualiza y se manda mensaje de error.

    SELECT SINGLE fksto INTO lv_anulada
      FROM vbrk
      WHERE vbeln EQ lv_vbeln.

    IF lv_anulada EQ 'X'.
      CONCATENATE 'La factura' gs_timbrefiscal-nodocu 'se encuentra anulada en SAP, no se actualizarán los datos enviados.' INTO lv_error_msg SEPARATED BY space.
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

*Se valida si el documento está cancelado ante el SAT.
    SELECT SINGLE cancelado INTO lv_cancelada
      FROM zsd_cfdi_return
      WHERE nodocu EQ lv_vbeln.

    IF lv_cancelada EQ 'X'.
      CONCATENATE 'La factura' gs_timbrefiscal-nodocu 'ya se encuentra cancelada ante el SAT, no se actualizarán los datos enviados' INTO lv_error_msg SEPARATED BY space.
      CALL METHOD lo_msg->add_message
        EXPORTING
          iv_msg_type   = /iwbep/cl_cos_logger=>error
          iv_msg_id     = 'ZSD_MSG'
          iv_msg_number = '004'
          iv_msg_text   = lv_error_msg.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_msg.
    ENDIF.

    gs_cfdireturn-mandt          = sy-mandt.
    gs_cfdireturn-serie          = gs_timbrefiscal-serie.
    gs_cfdireturn-nodocu         = gs_timbrefiscal-nodocu.
    gs_cfdireturn-uuid           = gs_timbrefiscal-uuid.
    gs_cfdireturn-fectimbre      = gs_timbrefiscal-fectimbre.
    gs_cfdireturn-rfcproovcertif = gs_timbrefiscal-rfcproovcertif.
    gs_cfdireturn-sellocfd       = gs_timbrefiscal-sellocfd.
    gs_cfdireturn-certificadosat = gs_timbrefiscal-certificadosat.
    gs_cfdireturn-sellosat       = gs_timbrefiscal-sellosat.
    gs_cfdireturn-cancelado      = gs_timbrefiscal-cancelado.
    gs_cfdireturn-xml            = gs_timbrefiscal-xml.
    gs_cfdireturn-pdf            = gs_timbrefiscal-pdf.
    gs_cfdireturn-status         = gs_timbrefiscal-status.
    gs_cfdireturn-noerror        = gs_timbrefiscal-noerror.
    gs_cfdireturn-mensaje        = gs_timbrefiscal-mensaje.

    IF gs_cfdireturn-cancelado NE 'X'.

*Se valida si el PAC regresa los campos necesarios para el llenado de la tabla zsd_cfdi_return.
      IF ( gs_cfdireturn-uuid EQ '' OR gs_cfdireturn-fectimbre EQ '' OR gs_cfdireturn-rfcproovcertif EQ '' OR gs_cfdireturn-sellocfd EQ '' OR gs_cfdireturn-certificadosat EQ '' OR gs_cfdireturn-sellosat EQ '' ) AND gs_cfdireturn-noerror EQ ''.

        IF gs_cfdireturn-uuid EQ ''.
          CONCATENATE 'Por favor indique el folio fiscal (UUID) para la factura' gs_timbrefiscal-nodocu INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZSD_MSG'
              iv_msg_number = '005'
              iv_msg_text   = lv_error_msg.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg.
        ENDIF.

        IF gs_cfdireturn-fectimbre EQ ''.
          CONCATENATE 'Por favor indique la fecha de timbrado para la factura' gs_timbrefiscal-nodocu INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZSD_MSG'
              iv_msg_number = '006'
              iv_msg_text   = lv_error_msg.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg.
        ENDIF.

        IF gs_cfdireturn-rfcproovcertif EQ ''.
          CONCATENATE 'Por favor indique el RFC del PAC para la factura' gs_timbrefiscal-nodocu INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZSD_MSG'
              iv_msg_number = '007'
              iv_msg_text   = lv_error_msg.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg.
        ENDIF.

        IF gs_cfdireturn-sellocfd EQ ''.
          CONCATENATE 'Por favor indique el sello del CFD para la factura' gs_timbrefiscal-nodocu INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZSD_MSG'
              iv_msg_number = '008'
              iv_msg_text   = lv_error_msg.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg.
        ENDIF.

        IF gs_cfdireturn-certificadosat EQ ''.
          CONCATENATE 'Por favor indique el número de certificado SAT para la factura' gs_timbrefiscal-nodocu INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZSD_MSG'
              iv_msg_number = '009'
              iv_msg_text   = lv_error_msg.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg.
        ENDIF.

        IF gs_cfdireturn-sellosat EQ ''.
          CONCATENATE 'Por favor indique el sello SAT para la factura' gs_timbrefiscal-nodocu INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>error
              iv_msg_id     = 'ZSD_MSG'
              iv_msg_number = '010'
              iv_msg_text   = lv_error_msg.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg.
        ENDIF.

      ENDIF.

*Actualiza el registro en la tabla zsd_cfdi_return.
      UPDATE zsd_cfdi_return SET nodocu = gs_cfdireturn-nodocu
        serie = gs_cfdireturn-serie
        uuid = gs_cfdireturn-uuid
        fectimbre = gs_cfdireturn-fectimbre
        rfcproovcertif = gs_cfdireturn-rfcproovcertif
        sellocfd = gs_cfdireturn-sellocfd
        certificadosat = gs_cfdireturn-certificadosat
        sellosat = gs_cfdireturn-sellosat
        cancelado = gs_cfdireturn-cancelado
        xml = gs_cfdireturn-xml
        pdf = gs_cfdireturn-pdf
        status = gs_cfdireturn-status
        noerror = gs_cfdireturn-noerror
        mensaje = gs_cfdireturn-mensaje
        docanula = gs_cfdireturn-docanula
      WHERE nodocu EQ gs_cfdireturn-nodocu
      AND serie EQ gs_cfdireturn-serie.
      CLEAR gs_cfdireturn.

*Se valida si el documento se insertó a la tabla zsd_cfdi_return correctamente.
      SELECT * FROM zsd_cfdi_return
        INTO CORRESPONDING FIELDS OF gs_cfdireturn
        WHERE nodocu EQ lv_vbeln
        AND serie = gs_timbrefiscal-serie.
      ENDSELECT.

      IF sy-subrc EQ 0.
        MOVE-CORRESPONDING gs_cfdireturn TO er_entity.

        IF gs_cfdireturn-noerror EQ ''.

          SELECT * FROM vbrk
          WHERE vbeln EQ @lv_vbeln
          INTO TABLE @DATA(gt_vbrk).

*Se actualiza el campo "UUID Decisión México" del documento contable relacionado a la factura
          LOOP AT gt_vbrk INTO DATA(gs_vbrk).
            IF gs_vbrk NE ''.
              UPDATE bkpf SET glo_ref1_hd = gs_cfdireturn-uuid
              WHERE bukrs = gs_vbrk-bukrs AND belnr = gs_vbrk-belnr AND gjahr = gs_vbrk-gjahr.
            ENDIF.
          ENDLOOP.

*Se adjuntan el XML y PDF en la factura.
          IF gs_cfdireturn-xml NE ''.

            lv_length = strlen( gs_cfdireturn-xml ).
*1. Se decodifica el fichero recibido en BASE64 y se deja en una variable tipo XSTRING (fichero en hexadecimal).
            CALL FUNCTION 'SSFC_BASE64_DECODE'
              EXPORTING
                b64data = gs_cfdireturn-xml
                b64leng = lv_length
              IMPORTING
                bindata = gs_filedecode.
*2. Se convierte la variable XSTRING (hexadecimal) a STRING (cadena de texto) para obtener el tamaño del fichero
            CALL METHOD cl_bcs_convert=>xstring_to_string
              EXPORTING
                iv_xstr   = gs_filedecode
                iv_cp     = 1100
              RECEIVING
                rv_string = lv_filexml.
*3. Obtenemos el tamaño real del fichero y se almacena en la variable lv_length que se utilizará para insertar el documento con GOS ***Este paso es muy importante, ya que de no enviar el tamaño correcto, se provoca error al abrir el fichero (XML)
            lv_length = strlen( lv_filexml ).
*4. Pasamos el fichero hexadecimal a una tabla.
            CALL METHOD cl_bcs_convert=>xstring_to_solix
              EXPORTING
                iv_xstring = gs_filedecode
              RECEIVING
                et_solix   = lt_filedecode.
*5. Convertimos la tabla hexadecimal a binario
            CALL FUNCTION 'SO_SOLIXTAB_TO_SOLITAB'
              EXPORTING
                ip_solixtab = lt_filedecode
              IMPORTING
                ep_solitab  = gt_content.
*6. Se prepara el GOS para recibir el fichero
            CALL FUNCTION 'SO_FOLDER_ROOT_ID_GET'
              EXPORTING
                region    = 'B'
              IMPORTING
                folder_id = gs_fol_id
              EXCEPTIONS
                OTHERS    = 1.

            CONCATENATE gs_cfdireturn-serie gs_cfdireturn-nodocu INTO gv_fname.
            gv_ext = 'xml'.

            ls_obj_data-objsns   = 'O'.
            ls_obj_data-objla    = sy-langu.
            ls_obj_data-objdes   = gv_fname.
            ls_obj_data-file_ext = gv_ext.
*En la mayoría de referencias, se indica que se obtenga el tamaño del fichero multiplicando el número de líneas de la tabla que contiene el archivo binario por 255 que es la cantidad de cartacteres que admite cada registro
*de la tabla. Si lo hacemos así, hay una gran posibilidad de provocar un error cuando se intenta abrir el fichero debido a que el sistema tratará de "completar" el archivo para alcanzar el tamaño indicado
*en el caso de ficheros XML, se añaden valores NUL al final de éste y no es posible leerlo en el navegador. Por eso es importante obtener el valor real del fichero como se hace en los pasos 2 y 3.
*          ls_obj_data-objlen   = lines( gt_content ) * 255.
            ls_obj_data-objlen   = lv_length.
            CONDENSE ls_obj_data-objlen.
*7. Se inserta el fichero en GOS.
            CALL FUNCTION 'SO_OBJECT_INSERT'
              EXPORTING
                folder_id             = gs_fol_id
                object_type           = 'EXT'
                object_hd_change      = ls_obj_data
              IMPORTING
                object_id             = gs_obj_id
              TABLES
                objhead               = lt_objhead
                objcont               = gt_content
              EXCEPTIONS
                active_user_not_exist = 35
                folder_not_exist      = 6
                object_type_not_exist = 17
                owner_not_exist       = 22
                parameter_error       = 23
                OTHERS                = 1000.

            ls_object-objkey = gs_cfdireturn-nodocu.
            ls_object-objtype = 'VBRK'.
            ls_note-objtype   = 'MESSAGE'.

            CONCATENATE gs_fol_id-objtp gs_fol_id-objyr gs_fol_id-objno gs_obj_id-objtp gs_obj_id-objyr gs_obj_id-objno INTO ls_note-objkey.
*8. Se relaciona el fichero recién insertado con el objeto SAP
            CALL FUNCTION 'BINARY_RELATION_CREATE_COMMIT'
              EXPORTING
                obj_rolea    = ls_object
                obj_roleb    = ls_note
                relationtype = 'ATTA'
              EXCEPTIONS
                OTHERS       = 1.

          ENDIF.
          CLEAR: gs_filedecode, lt_filedecode, gt_content, gs_fol_id, ls_obj_data, ls_object, lt_objhead, ls_note, lv_filexml.

          IF gs_cfdireturn-pdf NE ''.

            lv_length = strlen( gs_cfdireturn-pdf ).
*1. Se decodifica el fichero recibido en BASE64 y se deja en una variable tipo XSTRING (fichero en hexadecimal).
            CALL FUNCTION 'SSFC_BASE64_DECODE'
              EXPORTING
                b64data = gs_cfdireturn-pdf
                b64leng = lv_length
              IMPORTING
                bindata = gs_filedecode.
*2. Se convierte la variable XSTRING (hexadecimal) a STRING (cadena de texto) para obtener el tamaño del fichero
            CALL METHOD cl_bcs_convert=>xstring_to_string
              EXPORTING
                iv_xstr   = gs_filedecode
                iv_cp     = 1100
              RECEIVING
                rv_string = lv_filepdf.
*3. Obtenemos el tamaño real del fichero y se almacena en la variable lv_length que se utilizará para insertar el documento con GOS ***Este paso es muy importante, ya que de no enviar el tamaño correcto, se provoca error al abrir el fichero (XML)
            lv_length = strlen( lv_filepdf ).
*4. Pasamos el fichero hexadecimal a una tabla.
            CALL METHOD cl_bcs_convert=>xstring_to_solix
              EXPORTING
                iv_xstring = gs_filedecode
              RECEIVING
                et_solix   = lt_filedecode.
*5. Convertimos la tabla hexadecimal a binario
            CALL FUNCTION 'SO_SOLIXTAB_TO_SOLITAB'
              EXPORTING
                ip_solixtab = lt_filedecode
              IMPORTING
                ep_solitab  = gt_content.
*6. Se prepara el GOS para recibir el fichero
            CALL FUNCTION 'SO_FOLDER_ROOT_ID_GET'
              EXPORTING
                region    = 'B'
              IMPORTING
                folder_id = gs_fol_id
              EXCEPTIONS
                OTHERS    = 1.

            CONCATENATE gs_cfdireturn-serie gs_cfdireturn-nodocu INTO gv_fname.
            gv_ext = 'pdf'.

            ls_obj_data-objsns   = 'O'.
            ls_obj_data-objla    = sy-langu.
            ls_obj_data-objdes   = gv_fname.
            ls_obj_data-file_ext = gv_ext.
*En la mayoría de referencias, se indica que se obtenga el tamaño del fichero multiplicando el número de líneas de la tabla que contiene el archivo binario por 255 que es la cantidad de cartacteres que admite cada registro
*de la tabla. Si lo hacemos así, hay una gran posibilidad de provocar un error cuando se intenta abrir el fichero debido a que el sistema tratará de "completar" el archivo para alcanzar el tamaño indicado
*en el caso de ficheros XML, se añaden valores NUL al final de éste y no es posible leerlo en el navegador. Por eso es importante obtener el valor real del fichero como se hace en los pasos 2 y 3.
*          ls_obj_data-objlen   = lines( gt_content ) * 255.
            ls_obj_data-objlen   = lv_length.
            CONDENSE ls_obj_data-objlen.
*7. Se inserta el fichero en GOS.
            CALL FUNCTION 'SO_OBJECT_INSERT'
              EXPORTING
                folder_id             = gs_fol_id
                object_type           = 'EXT'
                object_hd_change      = ls_obj_data
              IMPORTING
                object_id             = gs_obj_id
              TABLES
                objhead               = lt_objhead
                objcont               = gt_content
              EXCEPTIONS
                active_user_not_exist = 35
                folder_not_exist      = 6
                object_type_not_exist = 17
                owner_not_exist       = 22
                parameter_error       = 23
                OTHERS                = 1000.

            ls_object-objkey = gs_cfdireturn-nodocu.
            ls_object-objtype = 'VBRK'.
            ls_note-objtype   = 'MESSAGE'.

            CONCATENATE gs_fol_id-objtp gs_fol_id-objyr gs_fol_id-objno gs_obj_id-objtp gs_obj_id-objyr gs_obj_id-objno INTO ls_note-objkey.
*8. Se relaciona el fichero recién insertado con el objeto SAP
            CALL FUNCTION 'BINARY_RELATION_CREATE_COMMIT'
              EXPORTING
                obj_rolea    = ls_object
                obj_roleb    = ls_note
                relationtype = 'ATTA'
              EXCEPTIONS
                OTHERS       = 1.


          ENDIF.
          CLEAR: gs_filedecode, lt_filedecode, gt_content, gs_fol_id, ls_obj_data, ls_object, lt_objhead, ls_note, lv_filepdf.

          CONCATENATE 'Se actualizó la factura' gs_cfdireturn-nodocu 'con el UUID: ' gs_cfdireturn-uuid INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>success
              iv_msg_id     = 'ZSD_MSG'
              iv_msg_number = '012'
              iv_msg_text   = lv_error_msg.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg.

        ELSEIF gs_cfdireturn-noerror NE ''.
          CONCATENATE 'Se actualizó la factura' gs_cfdireturn-nodocu 'con el error: ' gs_cfdireturn-mensaje INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>success
              iv_msg_id     = 'ZSD_MSG'
              iv_msg_number = '012'
              iv_msg_text   = lv_error_msg.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg.
        ENDIF.
      ENDIF.
    ELSEIF gs_cfdireturn-cancelado EQ 'X'.
      TRY.
          CALL FUNCTION 'BAPI_BILLINGDOC_CANCEL1'
            EXPORTING
              billingdocument = gs_cfdireturn-nodocu
              testrun         = ''
              no_commit       = ''
              billingdate     = sy-datum
            TABLES
              return          = lt_return
              success         = lt_success.
        CATCH /iwbep/cx_mgw_tech_exception.
      ENDTRY.
      IF NOT line_exists( lt_return[ type = 'E' ] ).
        LOOP AT lt_success INTO ls_success.

          CLEAR gs_cfdireturn.
          gs_cfdireturn-nodocu    = gs_timbrefiscal-nodocu.
          gs_cfdireturn-cancelado = 'X'.
          gs_cfdireturn-docanula  = ls_success-bill_doc.

          UPDATE zsd_cfdi_return SET cancelado = 'X' docanula = ls_success-bill_doc
          WHERE nodocu = gs_cfdireturn-nodocu.

          CLEAR gs_cfdireturn.

          SELECT * FROM zsd_cfdi_return
            INTO CORRESPONDING FIELDS OF gs_cfdireturn
            WHERE nodocu EQ lv_vbeln.
          ENDSELECT.

          ls_header_inx-updateflag = 'U'.
          ls_header_inx-bill_block = 'X'.
          ls_header_in-bill_block = ''.

          CALL FUNCTION 'BAPI_SALESORDER_CHANGE'
            EXPORTING
              salesdocument    = lv_vbeln
              order_header_in  = ls_header_in
              order_header_inx = ls_header_inx
            TABLES
              return           = lt_return_so.

          IF NOT line_exists( lt_return_so[ type = 'E' ] ).
            CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
          ENDIF.

          CONCATENATE 'Se ha creado el documento de anulación' ls_success-bill_doc 'relacionado a la factura' ls_success-ref_doc INTO lv_error_msg SEPARATED BY space.
          CALL METHOD lo_msg->add_message
            EXPORTING
              iv_msg_type   = /iwbep/cl_cos_logger=>success
              iv_msg_id     = 'ZSD_MSG'
              iv_msg_number = '011'
              iv_msg_text   = lv_error_msg.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_msg.
        ENDLOOP.
      ELSE.
*Lectura de tabla return para enviar el motivo por el que se da error al tratar de crear el pedido.
        UPDATE zsd_cfdi_return SET cancelado = '' WHERE nodocu EQ gs_cfdireturn-nodocu.
        gs_cfdireturn-cancelado = ''.
        MOVE-CORRESPONDING gs_cfdireturn TO er_entity.
        LOOP AT lt_return INTO ls_return.
          CALL METHOD lo_msg->add_message_from_bapi
            EXPORTING
              is_bapi_message           = ls_return
              iv_add_to_response_header = abap_false
              iv_message_target         = CONV string( ls_return-message ).
        ENDLOOP.
        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
          EXPORTING
            message_container = lo_msg.
        RETURN.
      ENDIF.
    ENDIF.
    CLEAR gs_cfdireturn.
  ENDMETHOD.
ENDCLASS.
