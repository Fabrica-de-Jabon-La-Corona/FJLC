*&---------------------------------------------------------------------*
*& Include          ZTM_FEVIAJES_ALV_F01
*&---------------------------------------------------------------------*

FORM get_data.

  DATA: lv_message TYPE string,
        lv_years   TYPE p0347-scryy,
        lv_months  TYPE p0347-scrmm,
        lv_days    TYPE p0347-scrdd,
        lt_lines   LIKE TABLE OF tline.

  "Verifica autorización para agente.
  AUTHORITY-CHECK OBJECT 'ZSD_VKGRP'
      ID 'VKGRP' FIELD pa_vkgrp-low
      ID 'ACTVT' FIELD '03'.

  IF sy-subrc NE 0.
    CONCATENATE 'No posee autorización para ver inforación del agente:' pa_vkgrp INTO lv_message SEPARATED BY space.
    MESSAGE lv_message TYPE 'E' DISPLAY LIKE 'E'.
  ENDIF.

  "Verifica autorización para centro.
  AUTHORITY-CHECK OBJECT 'M_BEST_WRK'
      ID 'WERKS' FIELD pa_werks-low
      ID 'ACTVT' FIELD '03'.

  IF sy-subrc NE 0.
    CONCATENATE 'No posee autorización para ver inforación del centro:' pa_werks INTO lv_message SEPARATED BY space.
    MESSAGE lv_message TYPE 'E' DISPLAY LIKE 'E'.
  ENDIF.

  "Se obtiene cabecera de pedidos por agente / broker (sin importar si tiene viaje o no).
  SELECT vk~vbeln, vk~kunnr, vk~vkgrp, vk~vdatu, vp~route, vp~werks, vp~lgort, vk~erdat, vk~gbstk, vk~augru, vk~vtweg FROM vbak AS vk
    INNER JOIN vbap AS vp ON vp~vbeln EQ vk~vbeln
    WHERE vk~vkgrp IN @pa_vkgrp
    AND vk~vbtyp EQ 'C'
    AND vk~vbeln IN @pa_pedid
    "AND vk~audat IN @pa_fechp
    AND vk~vdatu IN @pa_feche
    AND vp~route IN @pa_ruta
    AND vp~werks IN @pa_werks
    AND vp~lgort IN @pa_lgort
    AND vk~gbstk IN @pa_statu
    INTO TABLE @DATA(lt_vbak).

  SORT lt_vbak ASCENDING BY vbeln.
  DELETE ADJACENT DUPLICATES FROM lt_vbak COMPARING vbeln.

  "Se obtienen repartos y posiciones del pedido.
  SELECT va~vbeln, va~posnr, va~matnr, ma~brgew, ma~ntgew, ma~gewei, ma~volum, va~kwmeng, ve~etenr, ve~ordqty_su, ve~ordqty_bu FROM vbap AS va
    INNER JOIN vbep AS ve ON ve~vbeln EQ va~vbeln AND ve~posnr EQ va~posnr
    INNER JOIN mara AS ma ON ma~matnr EQ va~matnr
    FOR ALL ENTRIES IN @lt_vbak
    WHERE va~vbeln EQ @lt_vbak-vbeln
    INTO TABLE @DATA(lt_vbep).

  "Se obtienen posiciones de factura.
  SELECT va~aubel, va~aupos, va~vbeln, va~posnr, va~matnr, va~fkimg, va~vrkme, va~meins, ma~brgew, ma~ntgew, ma~gewei, ma~volum FROM vbrp AS va
    INNER JOIN mara AS ma ON ma~matnr EQ va~matnr
    FOR ALL ENTRIES IN  @lt_vbak
    WHERE va~aubel EQ @lt_vbak-vbeln
    INTO TABLE @DATA(lt_vbrp).

  "Se obtienen nombres de agentes / brokers
  SELECT * FROM tvgrt
    FOR ALL ENTRIES IN @lt_vbak
    WHERE vkgrp EQ @lt_vbak-vkgrp
    AND spras EQ 'S'
    INTO TABLE @DATA(lt_tvgrt).

  "Se obtienen clientes
  SELECT * FROM kna1
    FOR ALL ENTRIES IN @lt_vbak
    WHERE kunnr EQ @lt_vbak-kunnr
    INTO TABLE @DATA(lt_kna1).

  "Se obtienen interlocutores del pedido
  SELECT * FROM vbpa
    FOR ALL ENTRIES IN @lt_vbak
    WHERE vbeln EQ @lt_vbak-vbeln
    AND parvw EQ 'WE'
    INTO TABLE @DATA(lt_vbpa).

  "Se obtienen direcciones de destinatarios
  IF NOT lt_vbpa[] IS INITIAL.
    SELECT * FROM adrc
      FOR ALL ENTRIES IN @lt_vbpa
      WHERE addrnumber EQ @lt_vbpa-adrnr
      INTO TABLE @DATA(lt_adrc).

    "Se obtienen descripciones de paises y regiones
    SELECT * FROM t005t               "Paises
      FOR ALL ENTRIES IN @lt_adrc
      WHERE spras EQ 'S'
      AND land1 EQ @lt_adrc-country
      INTO TABLE @DATA(lt_t005t).

    SELECT * FROM t005u               "Regiones
      FOR ALL ENTRIES IN @lt_adrc
      WHERE spras EQ 'S'
      AND land1 EQ @lt_adrc-country
      AND bland EQ @lt_adrc-region
      INTO TABLE @DATA(lt_t005u).
  ENDIF.

  "Se obtienen destinatarios
  SELECT * FROM kna1
    FOR ALL ENTRIES IN @lt_vbpa
    WHERE kunnr EQ @lt_vbpa-kunnr
    INTO TABLE @DATA(lt_kna1we).

  "Se obtienen ubicaciones
  TYPES:
    BEGIN OF ty_locations,
      locno TYPE /sapapo/loc-locno,
      xpos  TYPE /sapapo/loc-xpos,
      ypos  TYPE /sapapo/loc-ypos,
    END OF ty_locations.

  DATA: lt_locations TYPE STANDARD TABLE OF ty_locations,
        ls_locations TYPE ty_locations.

  LOOP AT lt_kna1we ASSIGNING FIELD-SYMBOL(<fs_we>).
    ls_locations-locno = <fs_we>-kunnr.
    APPEND ls_locations TO lt_locations.
  ENDLOOP.
  SORT lt_locations ASCENDING.
  DELETE ADJACENT DUPLICATES FROM lt_locations.

  IF lt_locations[] IS NOT INITIAL.
    SELECT FROM /sapapo/loc
      FIELDS locno, xpos, ypos
      FOR ALL ENTRIES IN @lt_locations
      WHERE locno EQ @lt_locations-locno
      INTO TABLE @DATA(lt_apoloc).
  ENDIF.

  "Se obtienen pedidos de cliente
  SELECT * FROM vbkd
    FOR ALL ENTRIES IN @lt_vbak
    WHERE vbeln EQ @lt_vbak-vbeln
    INTO TABLE @DATA(lt_vbkd).

  "Se obtiene entrega relacionada al pedido
  SELECT vbelv, vbeln FROM vbfa
    FOR ALL ENTRIES IN @lt_vbak
    WHERE vbelv EQ @lt_vbak-vbeln
    AND vbtyp_n EQ 'J'
    INTO TABLE @DATA(lt_entregas).

  SORT lt_entregas ASCENDING BY vbelv vbeln.
  DELETE ADJACENT DUPLICATES FROM lt_entregas.

  "Se obtiene tabla de entregas para status de entrega.
  IF lt_entregas[] IS NOT INITIAL.
    SELECT * FROM likp
      FOR ALL ENTRIES IN @lt_entregas
      WHERE vbeln EQ @lt_entregas-vbeln
      INTO TABLE @DATA(lt_likp).

    "Se obtiene factura relacionada a la entrega
    SELECT a~vbelv, a~vbeln FROM vbfa AS a
      INNER JOIN vbrk AS b ON b~vbeln EQ a~vbeln
      FOR ALL ENTRIES IN @lt_entregas
      WHERE a~vbelv EQ @lt_entregas-vbeln
      AND a~vbtyp_n EQ 'M'
      AND b~fksto EQ ''
      INTO TABLE @DATA(lt_facturas).

    SORT lt_facturas ASCENDING BY vbelv vbeln.
    DELETE ADJACENT DUPLICATES FROM lt_facturas.

    "Se obtiene tabla de facturas timbrada.
    IF lt_facturas[] IS NOT INITIAL.
      SELECT * FROM zsd_cfdi_return
        FOR ALL ENTRIES IN @lt_facturas
        WHERE nodocu EQ @lt_facturas-vbeln
        INTO TABLE @DATA(lt_timbre).
    ENDIF.
  ENDIF.

  "Se obtienen parent_keys de los viajes

  TYPES: BEGIN OF lsy_entr,
           pedido  TYPE vbak-vbeln,
           entrega TYPE /scmtms/d_torite-base_btd_id,
         END OF lsy_entr.

  DATA: ls_entr TYPE lsy_entr,
        lt_entr TYPE STANDARD TABLE OF lsy_entr.

  DATA: lv_basebtd TYPE /scmtms/d_torite-base_btd_id.

  LOOP AT lt_entregas ASSIGNING FIELD-SYMBOL(<fs_entregas>).
    lv_basebtd = |{ <fs_entregas>-vbeln ALPHA = IN }|.

    ls_entr-pedido  = <fs_entregas>-vbelv.
    ls_entr-entrega = lv_basebtd.
    APPEND ls_entr TO lt_entr.
    CLEAR: ls_entr, lv_basebtd.
  ENDLOOP.
  UNASSIGN <fs_entregas>.

  IF NOT lt_entr[] IS INITIAL.

    SELECT ti~parent_key, to~tor_id, ti~base_btd_id FROM /scmtms/d_torite AS ti
      INNER JOIN /scmtms/d_torrot AS to ON to~db_key EQ ti~parent_key
      FOR ALL ENTRIES IN @lt_entr
      WHERE ti~base_btd_id EQ @lt_entr-entrega
      AND ti~base_btd_tco EQ '73'
      AND ti~ref_bo EQ 'TOR'
      AND to~lifecycle NE '10'                               "Se descartan documentos con ciclo de vida "Anulado" - 22.01.2025 - S4DK909832
      INTO TABLE @DATA(lt_parent).

    "Selección d unidades de flete.
    SELECT ti~parent_key, to~tor_id, ti~base_btd_id FROM /scmtms/d_torite AS ti
      INNER JOIN /scmtms/d_torrot AS to ON to~db_key EQ ti~parent_key
      FOR ALL ENTRIES IN @lt_entr
      WHERE ti~base_btd_id EQ @lt_entr-entrega
      AND ti~base_btd_tco EQ '73'
      AND ti~ref_bo EQ 'TRQTR'
      AND to~tor_cat EQ 'FU'
      INTO TABLE @DATA(lt_freunit).

    SORT lt_freunit ASCENDING BY base_btd_id.
    DELETE ADJACENT DUPLICATES FROM lt_freunit COMPARING base_btd_id.

    SORT lt_parent ASCENDING BY parent_key.
    DELETE ADJACENT DUPLICATES FROM lt_parent COMPARING parent_key base_btd_id.

    "Cabecera de viajes
    SELECT * FROM /scmtms/d_torrot
      FOR ALL ENTRIES IN @lt_parent
      WHERE db_key EQ @lt_parent-parent_key
      AND lifecycle NE '10'                                  "Se descartan documentos con ciclo de vida "Anulado" - 22.01.2025 - S4DK909830
      "AND tor_id IN @pa_viaje
      AND tor_cat EQ 'TO'
      INTO TABLE @DATA(lt_torrot).

    "Posiciones de viajes para choferes
    IF lt_torrot[] IS NOT INITIAL.
      SELECT * FROM /scmtms/d_torite
        FOR ALL ENTRIES IN @lt_torrot
        WHERE parent_key EQ @lt_torrot-db_key
        AND item_cat EQ 'DRI'
        INTO TABLE @DATA(lt_torite).
    ENDIF.

    "Eventos del viaje
    SELECT * FROM /scmtms/d_torexe
      FOR ALL ENTRIES IN @lt_torrot
      WHERE parent_key EQ @lt_torrot-db_key
      INTO TABLE @DATA(lt_torexe).

    "Interlocutores del viaje
    SELECT * FROM /scmtms/d_torpty
      FOR ALL ENTRIES IN @lt_torrot
      WHERE parent_key EQ @lt_torrot-db_key
      INTO TABLE @DATA(lt_torpty).

    "Proveedores
    SELECT * FROM lfa1
      FOR ALL ENTRIES IN @lt_torpty
      WHERE lifnr EQ @lt_torpty-party_id
      INTO TABLE @DATA(lt_lfa1).

  ENDIF.

  "Se comienza el llenado de la tabla lt_viajes a partir de lt_vbak
  LOOP AT lt_vbak ASSIGNING FIELD-SYMBOL(<fs_vbak>).
    READ TABLE lt_vbkd ASSIGNING FIELD-SYMBOL(<fs_vbkd>) WITH KEY vbeln = <fs_vbak>-vbeln.
    IF <fs_vbkd> IS ASSIGNED.
      gs_viajes-bstkd = <fs_vbkd>-bstkd.      "Pedido de cliente
      gs_viajes-inco  = <fs_vbkd>-inco1.      "Incoterm
      gs_viajes-front = <fs_vbkd>-inco2_l.    "Lugar incoterm (frontera)
      gs_viajes-route = <fs_vbak>-route.      "Ruta
      gs_viajes-werks = <fs_vbak>-werks.      "Centro
      gs_viajes-lgort = <fs_vbak>-lgort.      "Almacén
      gs_viajes-gbstk = <fs_vbak>-gbstk.      "Estado global del pedido
      gs_viajes-erdat = <fs_vbak>-erdat.      "Creado el

      IF <fs_vbak>-augru EQ 'Z71'.
        gs_viajes-cita = abap_true.           "Indicador de cita
      ENDIF.

      CALL FUNCTION 'HR_HK_DIFF_BT_2_DATES'
        EXPORTING
          date1         = sy-datum
          date2         = <fs_vbak>-erdat
          output_format = '03'
        IMPORTING
          years         = lv_years
          months        = lv_months
          days          = lv_days.

      gs_viajes-diasc = lv_days.
      UNASSIGN <fs_vbkd>.
    ENDIF.
    gs_viajes-kunnr = <fs_vbak>-kunnr.        "Número de cliente (solicitante)
    gs_viajes-vdatu = <fs_vbak>-vdatu.        "Fecha preferente de entrega

    READ TABLE lt_kna1 ASSIGNING FIELD-SYMBOL(<fs_kna1>) WITH KEY kunnr = <fs_vbak>-kunnr.
    IF <fs_kna1> IS ASSIGNED.
      gs_viajes-namso = <fs_kna1>-name1.      "Nombre de cliente (solicitante)
      UNASSIGN <fs_kna1>.
    ENDIF.

    READ TABLE lt_vbpa ASSIGNING FIELD-SYMBOL(<fs_vbpa>) WITH KEY vbeln = <fs_vbak>-vbeln parvw = 'WE'.
    IF <fs_vbpa> IS ASSIGNED.
      gs_viajes-kunwe = <fs_vbpa>-kunnr.      "Número de destinatario de mercancía

      READ TABLE lt_kna1we ASSIGNING FIELD-SYMBOL(<fs_kna1we>) WITH KEY kunnr = <fs_vbpa>-kunnr.
      IF <fs_kna1we> IS ASSIGNED.
        gs_viajes-namwe = <fs_kna1we>-name1.  "Nombre de destinatario de mercancía
        UNASSIGN <fs_kna1we>.
      ENDIF.

      READ TABLE lt_adrc ASSIGNING FIELD-SYMBOL(<fs_adrc>) WITH KEY addrnumber = <fs_vbpa>-adrnr.
      IF <fs_adrc> IS ASSIGNED.
        gs_viajes-street = <fs_adrc>-street.     "Calle
        gs_viajes-housen = <fs_adrc>-house_num1. "Número Exterior
        gs_viajes-postl  = <fs_adrc>-post_code1. "Código postal
        gs_viajes-city2  = <fs_adrc>-city2.      "Distrito
        gs_viajes-city   = <fs_adrc>-city1.      "Población

        READ TABLE lt_t005t ASSIGNING FIELD-SYMBOL(<fs_t005t>) WITH KEY land1 = <fs_adrc>-country.
        IF <fs_t005t> IS ASSIGNED.
          gs_viajes-land   = <fs_t005t>-landx.    "País

          "Lee coordenadas geográficas, si existen pinta el ícono de localización GPS, de lo contrario deja el campo vacío.
          READ TABLE lt_apoloc ASSIGNING FIELD-SYMBOL(<fs_apoloc>) WITH KEY locno = <fs_vbpa>-kunnr.
          IF <fs_apoloc> IS ASSIGNED.
            IF <fs_apoloc>-xpos NE '' AND <fs_apoloc>-ypos NE ''.
              gs_viajes-pgps = '@AF@'.
              gs_viajes-xpos = <fs_apoloc>-xpos.
              gs_viajes-ypos = <fs_apoloc>-ypos.
            ELSE.
              gs_viajes-pgps = ''.
            ENDIF.
            UNASSIGN <fs_apoloc>.
          ENDIF.

          READ TABLE lt_t005u ASSIGNING FIELD-SYMBOL(<fs_t005u>) WITH KEY land1 = <fs_adrc>-country bland = <fs_adrc>-region.
          IF <fs_t005u> IS ASSIGNED.
            gs_viajes-reion  = <fs_t005u>-bezei.  "Región
            UNASSIGN <fs_t005u>.
          ENDIF.
          UNASSIGN <fs_t005t>.
        ENDIF.
        UNASSIGN <fs_adrc>.
      ENDIF.

      UNASSIGN <fs_vbpa>.
    ENDIF.

    gs_viajes-vkgrp = <fs_vbak>-vkgrp.        "Agente / Broker

    READ TABLE lt_tvgrt ASSIGNING FIELD-SYMBOL(<fs_tvgrt>) WITH KEY vkgrp = <fs_vbak>-vkgrp spras = 'S'.
    IF <fs_tvgrt> IS ASSIGNED.
      gs_viajes-bezei = <fs_tvgrt>-bezei.     "Nombre de Agente / Broker
      UNASSIGN <fs_tvgrt>.
    ENDIF.

    gs_viajes-vbelp = <fs_vbak>-vbeln.        "Número de pedido

    DATA: lv_name TYPE thead-tdname.

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
      CONCATENATE gs_viajes-observ <fs_lines>-tdline INTO gs_viajes-observ SEPARATED BY space.
      CONDENSE gs_viajes-observ.
      CLEAR <fs_lines>.
    ENDLOOP.
    UNASSIGN: <fs_lines>.

    IF <fs_vbak>-vtweg NE '02'.
      LOOP AT lt_vbep ASSIGNING FIELD-SYMBOL(<fs_vbep>) WHERE vbeln EQ <fs_vbak>-vbeln AND etenr EQ '0001'.
        gs_viajes-kwmeng = ( gs_viajes-kwmeng + <fs_vbep>-ordqty_su ). "Cantidad
        gs_viajes-volum = gs_viajes-volum + ( <fs_vbep>-ordqty_bu * <fs_vbep>-volum ).    "Volumen
        IF <fs_vbep>-gewei EQ 'KG'.
          gs_viajes-brgew = gs_viajes-brgew + ( <fs_vbep>-ordqty_bu * <fs_vbep>-brgew ).    "Peso Bruto
          gs_viajes-ntgew = gs_viajes-ntgew + ( <fs_vbep>-ordqty_bu * <fs_vbep>-ntgew ).    "Peso Neto
        ELSEIF <fs_vbep>-gewei EQ 'G'.
          gs_viajes-brgew = ( gs_viajes-brgew + ( <fs_vbep>-ordqty_bu * <fs_vbep>-brgew ) / 1000 ).   "Peso Bruto
          gs_viajes-ntgew = ( gs_viajes-ntgew + ( <fs_vbep>-ordqty_bu * <fs_vbep>-ntgew ) / 1000 ).   "Peso Neto
        ENDIF.
        CLEAR <fs_vbep>.
      ENDLOOP.
      UNASSIGN: <fs_vbep>.
    ELSE.
      LOOP AT lt_vbrp ASSIGNING FIELD-SYMBOL(<fs_vbrp>) WHERE aubel EQ <fs_vbak>-vbeln.
        DATA: lv_piezas TYPE fkimg.
        "Convierte a cantidad en piezas para multiplicar por el peso por pieza del maestro de materiales.
        CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
          EXPORTING
            i_matnr              = <fs_vbrp>-matnr
            i_in_me              = <fs_vbrp>-vrkme
            i_out_me             = <fs_vbrp>-meins
            i_menge              = <fs_vbrp>-fkimg
          IMPORTING
            e_menge              = lv_piezas
          EXCEPTIONS
            error_in_application = 1
            error                = 2
            OTHERS               = 3.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

        gs_viajes-kwmeng = ( gs_viajes-kwmeng + <fs_vbrp>-fkimg ). "Cantidad
        gs_viajes-volum = gs_viajes-volum + ( lv_piezas * <fs_vbrp>-volum ).    "Volumen
        IF <fs_vbrp>-gewei EQ 'KG'.
          gs_viajes-brgew = gs_viajes-brgew + ( lv_piezas * <fs_vbrp>-brgew ).    "Peso Bruto
          gs_viajes-ntgew = gs_viajes-ntgew + ( lv_piezas * <fs_vbrp>-ntgew ).    "Peso Neto
        ELSEIF <fs_vbrp>-gewei EQ 'G'.
          gs_viajes-brgew = ( gs_viajes-brgew + ( lv_piezas * <fs_vbrp>-brgew ) / 1000 ).   "Peso Bruto
          gs_viajes-ntgew = ( gs_viajes-ntgew + ( lv_piezas * <fs_vbrp>-ntgew ) / 1000 ).   "Peso Neto
        ENDIF.
        CLEAR: <fs_vbrp>, lv_piezas.
      ENDLOOP.
      UNASSIGN: <fs_vbrp>.
    ENDIF.

    IF line_exists( lt_entregas[ vbelv = <fs_vbak>-vbeln ] ).

      LOOP AT lt_entregas ASSIGNING <fs_entregas> WHERE vbelv = <fs_vbak>-vbeln.
        gs_viajes-vbele = <fs_entregas>-vbeln.  "Número de entrega

        READ TABLE lt_facturas ASSIGNING FIELD-SYMBOL(<fs_facturas>) WITH KEY vbelv = <fs_entregas>-vbeln.
        IF <fs_facturas> IS ASSIGNED.
          SELECT SINGLE fksto INTO @DATA(lv_fksto)
            FROM vbrk
            WHERE vbeln EQ @<fs_facturas>-vbeln.
          IF lv_fksto EQ ''.
            gs_viajes-vbelf = <fs_facturas>-vbeln.  "Número de factura
          ELSE.
            gs_viajes-vbelf = ''.
          ENDIF.

          READ TABLE lt_timbre ASSIGNING FIELD-SYMBOL(<fs_timbre>) WITH KEY nodocu = <fs_facturas>-vbeln.
          IF <fs_timbre> IS ASSIGNED.
            IF <fs_timbre>-uuid NE ''.
              gs_viajes-uuid = <fs_timbre>-uuid.
            ELSE.
              gs_viajes-error = <fs_timbre>-mensaje.
            ENDIF.
            UNASSIGN: <fs_timbre>.
          ENDIF.

          UNASSIGN <fs_facturas>.
        ENDIF.

        DATA lv_base_entr TYPE /scmtms/d_torrot-base_btd_id.

        lv_base_entr = |{ <fs_entregas>-vbeln ALPHA = IN }|.

        READ TABLE lt_entr ASSIGNING FIELD-SYMBOL(<fs_entr>) WITH KEY entrega = lv_base_entr."<fs_vbak>-vbeln.
        IF <fs_entr> IS ASSIGNED.
          READ TABLE lt_freunit ASSIGNING FIELD-SYMBOL(<fs_freunit>) WITH KEY base_btd_id = <fs_entr>-entrega.
          IF <fs_freunit> IS ASSIGNED.
            gs_viajes-toruf = <fs_freunit>-tor_id.  "Número de unidad de flete.
            UNASSIGN <fs_freunit>.
          ENDIF.
          READ TABLE lt_parent ASSIGNING FIELD-SYMBOL(<fs_parent>) WITH KEY base_btd_id = <fs_entr>-entrega.
          IF <fs_parent> IS ASSIGNED.
            READ TABLE lt_torrot ASSIGNING FIELD-SYMBOL(<fs_torrot>) WITH KEY db_key = <fs_parent>-parent_key.
            IF <fs_torrot> IS ASSIGNED.
              gs_viajes-torid = <fs_torrot>-tor_id. "Número de viaje
              READ TABLE lt_torexe ASSIGNING FIELD-SYMBOL(<fs_torexe>) WITH KEY parent_key = <fs_torrot>-db_key event_code = 'DEPARTURE'.
              IF <fs_torexe> IS ASSIGNED.
                CONVERT TIME STAMP <fs_torexe>-actual_date TIME ZONE 'UTC' INTO DATE DATA(lv_date) TIME DATA(lv_time) DAYLIGHT SAVING TIME DATA(lv_dst).
                CONCATENATE lv_date+6(2) '.' lv_date+4(2) '.' lv_date(4) INTO DATA(lv_date1).
                gs_viajes-dates = lv_date1.   "Fecha real de salida
                UNASSIGN <fs_torexe>.
                CLEAR: lv_date, lv_date1, lv_time, lv_dst.
              ENDIF.
              READ TABLE lt_torexe ASSIGNING <fs_torexe> WITH KEY parent_key = <fs_torrot>-db_key event_code = 'CUSTOMS_CROSSING'.
              IF <fs_torexe> IS ASSIGNED.
                CONVERT TIME STAMP <fs_torexe>-actual_date TIME ZONE 'UTC' INTO DATE lv_date TIME lv_time DAYLIGHT SAVING TIME lv_dst.
                CONCATENATE lv_date+6(2) '.' lv_date+4(2) '.' lv_date(4) INTO lv_date1.
                gs_viajes-datec = lv_date1.   "Fecha real de cruce de aduana
                UNASSIGN <fs_torexe>.
                CLEAR: lv_date, lv_date1, lv_time, lv_dst.
              ENDIF.
              READ TABLE lt_torexe ASSIGNING <fs_torexe> WITH KEY parent_key = <fs_torrot>-db_key event_code = 'ARRIV_DEST'.
              IF <fs_torexe> IS ASSIGNED.
                CONVERT TIME STAMP <fs_torexe>-actual_date TIME ZONE 'UTC' INTO DATE lv_date TIME lv_time DAYLIGHT SAVING TIME lv_dst.
                CONCATENATE lv_date+6(2) '.' lv_date+4(2) '.' lv_date(4) INTO lv_date1.
                gs_viajes-datee = lv_date1.   "Fecha real de llegada con cliente
                UNASSIGN <fs_torexe>.
              ENDIF.
              READ TABLE lt_torexe ASSIGNING <fs_torexe> WITH KEY parent_key = <fs_torrot>-db_key event_code = 'CHECK_IN'.
              IF <fs_torexe> IS ASSIGNED.
                CONVERT TIME STAMP <fs_torexe>-actual_date TIME ZONE 'CSTNO' INTO DATE lv_date TIME lv_time DAYLIGHT SAVING TIME lv_dst.
                CONCATENATE lv_date+6(2) '.' lv_date+4(2) '.' lv_date(4) 'T' lv_time(2) ':' lv_time+2(2) ':' lv_time+4(2) INTO gs_viajes-dateci.
                CONDENSE gs_viajes-dateci.
                UNASSIGN <fs_torexe>.
                CLEAR: lv_date, lv_date1, lv_time, lv_dst.
              ENDIF.
              READ TABLE lt_torexe ASSIGNING <fs_torexe> WITH KEY parent_key = <fs_torrot>-db_key event_code = 'CHECK_OUT'.
              IF <fs_torexe> IS ASSIGNED.
                CONVERT TIME STAMP <fs_torexe>-actual_date TIME ZONE 'CSTNO' INTO DATE lv_date TIME lv_time DAYLIGHT SAVING TIME lv_dst.
                CONCATENATE lv_date+6(2) '.' lv_date+4(2) '.' lv_date(4) 'T' lv_time(2) ':' lv_time+2(2) ':' lv_time+4(2) INTO gs_viajes-dateco.
                CONDENSE gs_viajes-dateco.
                UNASSIGN <fs_torexe>.
                CLEAR: lv_date, lv_date1, lv_time, lv_dst.
              ENDIF.

              "Obtenemos el nombre del chofer.
              READ TABLE lt_torite ASSIGNING FIELD-SYMBOL(<fs_torite>) WITH KEY parent_key = <fs_torrot>-db_key.

              IF <fs_torite> IS ASSIGNED.
                SELECT FROM but000
                  FIELDS name_first, name_last
                  WHERE partner EQ @<fs_torite>-res_id
                  INTO (@DATA(chonamefirst), @DATA(chonamelast)).

                  CONCATENATE chonamefirst chonamelast INTO gs_viajes-condu SEPARATED BY space.
                  CONDENSE gs_viajes-condu.
                ENDSELECT.
                UNASSIGN: <fs_torite>.
              ENDIF.

              LOOP AT lt_torpty ASSIGNING FIELD-SYMBOL(<fs_torpty>) WHERE parent_key EQ <fs_torrot>-db_key.
                CASE <fs_torpty>-party_rco.
                  WHEN 'ZT'.                  "Transportista Extranjero
                    READ TABLE lt_lfa1 ASSIGNING FIELD-SYMBOL(<fs_lfa1>) WITH KEY lifnr = <fs_torpty>-party_id.
                    IF <fs_lfa1> IS ASSIGNED.
                      gs_viajes-traex = <fs_lfa1>-name1.
                    ENDIF.
                    UNASSIGN <fs_lfa1>.
                  WHEN 'CF'.                  "Agente aduanal Extranjero
                    READ TABLE lt_lfa1 ASSIGNING <fs_lfa1> WITH KEY lifnr = <fs_torpty>-party_id.
                    IF <fs_lfa1> IS ASSIGNED.
                      gs_viajes-aduex = <fs_lfa1>-name1.
                    ENDIF.
                    UNASSIGN <fs_lfa1>.
                  WHEN 'CG'.                  "Agente aduanal nacional
                    READ TABLE lt_lfa1 ASSIGNING <fs_lfa1> WITH KEY lifnr = <fs_torpty>-party_id.
                    IF <fs_lfa1> IS ASSIGNED.
                      gs_viajes-aduna = <fs_lfa1>-name1.
                    ENDIF.
                    UNASSIGN <fs_lfa1>.
                  WHEN 'CT'.                  "Transportista nacional
                    READ TABLE lt_lfa1 ASSIGNING <fs_lfa1> WITH KEY lifnr = <fs_torpty>-party_id.
                    IF <fs_lfa1> IS ASSIGNED.
                      gs_viajes-trana = <fs_lfa1>-name1.
                    ENDIF.
                    UNASSIGN <fs_lfa1>.
                ENDCASE.
              ENDLOOP.
              UNASSIGN <fs_torpty>.

              IF gs_viajes-trana EQ ''.
                SELECT SINGLE name1 INTO @gs_viajes-trana    "Transportista nacional
                  FROM lfa1
                  WHERE lifnr EQ @<fs_torrot>-tspid.
              ENDIF.

              UNASSIGN <fs_torrot>.
              CLEAR: lv_date, lv_date1, lv_time, lv_dst.
            ENDIF.
            UNASSIGN <fs_parent>.
          ENDIF.

          READ TABLE lt_likp ASSIGNING FIELD-SYMBOL(<fs_likp>) WITH KEY vbeln = <fs_entr>-entrega+25(10).
          IF <fs_likp> IS ASSIGNED.
            gs_viajes-stsme = <fs_likp>-wbstk.
            gs_viajes-stare = <fs_likp>-pdstk.
            gs_viajes-stfen = <fs_likp>-fkstk.
            gs_viajes-stgen = <fs_likp>-gbstk.
            UNASSIGN: <fs_likp>.
          ENDIF.

          UNASSIGN <fs_entr>.
        ENDIF.

        IF line_exists( gt_viajes[ vbelp = <fs_entregas>-vbelv ] ).     "Si existe ya un registro con el número de pedido en la tabla interna, borramos cantidad pendiente, volumen y peso.
          CLEAR: gs_viajes-kwmeng, gs_viajes-volum, gs_viajes-brgew.
        ENDIF.

        IF pa_viaje IS INITIAL.
          APPEND gs_viajes TO gt_viajes.
        ELSE.
          IF  gs_viajes-torid IN pa_viaje.
            APPEND gs_viajes TO gt_viajes.
          ENDIF.
        ENDIF.
        CLEAR: gs_viajes-vbele, gs_viajes-vbelf, gs_viajes-toruf, gs_viajes-torid, gs_viajes-dates, gs_viajes-datec, gs_viajes-datee, gs_viajes-dateci, gs_viajes-dateco, gs_viajes-traex, gs_viajes-aduex, gs_viajes-aduna, gs_viajes-trana, gs_viajes-vdatu,
               gs_viajes-uuid, gs_viajes-error, gs_viajes-stsme, gs_viajes-stare, gs_viajes-stfen, gs_viajes-stgen, gs_viajes-condu.
      ENDLOOP.  "************************************************************************************************************************************************************
      UNASSIGN <fs_entregas>.
      CLEAR: gs_viajes.
    ELSE.
      IF pa_viaje IS INITIAL.
        APPEND gs_viajes TO gt_viajes.
      ELSE.
        IF  gs_viajes-torid IN pa_viaje.
          APPEND gs_viajes TO gt_viajes.
        ENDIF.
      ENDIF.
    ENDIF.
    CLEAR: gs_viajes.
  ENDLOOP.
  UNASSIGN: <fs_vbak>.

  SORT gt_viajes ASCENDING BY erdat route vbelp.

ENDFORM.

*&---------------------------------------------------------------------*
*& CLASS cl_handler
*&---------------------------------------------------------------------*
CLASS cl_handler DEFINITION.
  PUBLIC SECTION.
    METHODS on_double_click FOR EVENT double_click OF cl_salv_events_table
      IMPORTING row column.
ENDCLASS.

CLASS cl_handler IMPLEMENTATION.
  METHOD on_double_click.
*   Obtenemos la informacion de esa linea
    READ TABLE gt_viajes INTO DATA(wa_st_data) INDEX row.
    CHECK sy-subrc = 0.
    CASE column.
      WHEN 'VBELP'.
        SET PARAMETER ID 'AUN' FIELD wa_st_data-vbelp.
        CALL TRANSACTION 'VA03' AND SKIP FIRST SCREEN.
      WHEN 'VBELE'.
        SET PARAMETER ID 'VL' FIELD wa_st_data-vbele.
        CALL TRANSACTION 'VL03N' AND SKIP FIRST SCREEN.
      WHEN 'VBELF'.
        SET PARAMETER ID 'VF' FIELD wa_st_data-vbelf.
        CALL TRANSACTION 'VF03' AND SKIP FIRST SCREEN.
      WHEN 'PGPS'.
        DATA: lv_url  TYPE string,
              lv_xpos TYPE string,
              lv_ypos TYPE string.

        lv_xpos = round( val = wa_st_data-xpos dec = 6 ).
        lv_ypos = round( val = wa_st_data-ypos dec = 6 ).

        IF abs( lv_xpos ) GT '0' AND abs( lv_ypos ) GT '0'.

          DATA(lv_lenx) = strlen( lv_xpos ).
          DATA(lv_leny) = strlen( lv_ypos ).

          IF lv_lenx GE '12' AND lv_leny GE '12'.

            DATA(lv_offsetx) = lv_lenx - 2.
            DATA(lv_offsety) = lv_leny - 2.

            DATA(lv_multx) = lv_xpos+lv_offsetx(2).
            DATA(lv_multy) = lv_ypos+lv_offsety(2).

            CASE lv_multx.
              WHEN '00'.
                lv_xpos = lv_xpos(12).
              WHEN '01'.
                lv_xpos = lv_xpos(12) * 10.
              WHEN '02'.
                lv_xpos = lv_xpos(12) * 100.
            ENDCASE.

            CASE lv_multy.
              WHEN '00'.
                lv_ypos = lv_ypos(12).
              WHEN '01'.
                lv_ypos = lv_ypos(12) * 10.
              WHEN '02'.
                lv_ypos = lv_ypos(12) * 100.
            ENDCASE.
          ENDIF.

          CONDENSE: lv_xpos, lv_ypos.

          "lv_url = 'https://www.google.com/maps/search/?api=1&query=19.51700689629503,-99.08297897627712'.
          CONCATENATE 'https://www.google.com/maps/search/?api=1&query=' lv_ypos ',' lv_xpos INTO lv_url.
          CONDENSE lv_url.

          CALL METHOD cl_gui_frontend_services=>execute
            EXPORTING
              document = lv_url
            EXCEPTIONS
              OTHERS   = 1.
        ENDIF.
    ENDCASE.

  ENDMETHOD.
ENDCLASS.

*&---------------------------------------------------------------------*
*& Form display_alv
*&---------------------------------------------------------------------*
FORM display_alv.
  DATA: lo_gr_alv        TYPE REF TO cl_salv_table,             " Variable para propiedades ALV
        lo_gr_functions  TYPE REF TO cl_salv_functions_list,
        lo_event_handler TYPE REF TO cl_handler,                " Variables para eventos
        lo_events        TYPE REF TO cl_salv_events_table,
        lo_display       TYPE REF TO cl_salv_display_settings,  " Variable para layout settings
        lo_selections    TYPE REF TO cl_salv_selections,        " Variables para modo de seleccion y propiedades de la columna
        lo_columns       TYPE REF TO cl_salv_columns,
        lo_columns2      TYPE REF TO cl_salv_columns_table,
        lo_column        TYPE REF TO cl_salv_column_table,
        lo_column2       TYPE REF TO cl_salv_column,
        ref_alv_table    TYPE REF TO gty_viajes,
        cx_salv          TYPE REF TO cx_salv_msg,
        cx_not_found     TYPE REF TO cx_salv_not_found,
        lo_gr_layout     TYPE REF TO cl_salv_layout,
        key              TYPE salv_s_layout_key,
        gr_msg           TYPE string.

  IF sy-subrc <> 0.
*   MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*     WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

* Creacion ALV object
  TRY.
      CALL METHOD cl_salv_table=>factory(
        EXPORTING
*         r_container    = lo_container
          container_name = 'CONTAINER'
        IMPORTING
          r_salv_table   = lo_gr_alv
        CHANGING
          t_table        = gt_viajes ).
    CATCH cx_salv_msg.
  ENDTRY.

*Se muestran todos los botones del ALV (modificar, grabar, seleccionar layout).
  lo_gr_layout = lo_gr_alv->get_layout( ).
  key-report = sy-repid.
  lo_gr_layout->set_key( key ).

  lo_gr_layout->set_save_restriction( if_salv_c_layout=>restrict_none ).
  lo_gr_layout->set_save_restriction( ).
  lo_gr_layout->set_initial_layout( p_layout ).

*Mostramos los botones ALV
  lo_gr_functions = lo_gr_alv->get_functions( ).
  lo_gr_functions->set_all( abap_true ).

  TRY.
* Optimize
      lo_columns = lo_gr_alv->get_columns( ).
      lo_columns->set_optimize( 'X' ).
*Cambiamos descripción de columnas de fechas de eventos.

      lo_column ?= lo_columns->get_column( columnname = 'VDATU' ).
      lo_column->set_short_text( 'FePrefEnt' ).
      lo_column->set_medium_text( 'Fecha Pref Ent' ).
      lo_column->set_long_text( 'Fecha Preferente de Entrega' ).

      lo_column ?= lo_columns->get_column( columnname = 'DATES' ).
      lo_column->set_short_text( 'Fe.Re.Sal' ).
      lo_column->set_medium_text( 'Fe.Real.Sal.' ).
      lo_column->set_long_text( 'Fecha Real Salida' ).

      lo_column ?= lo_columns->get_column( columnname = 'DATEC' ).
      lo_column->set_short_text( 'Fe.Cr.Ad' ).
      lo_column->set_medium_text( 'Fe.Real Cruce' ).
      lo_column->set_long_text( 'Fecha Real Cruce Aduana' ).

      lo_column ?= lo_columns->get_column( columnname = 'DATEE' ).
      lo_column->set_short_text( 'Fe.Ent.Cte' ).
      lo_column->set_medium_text( 'Fe.Ent.Cliente' ).
      lo_column->set_long_text( 'Fecha Real Entrega Cliente' ).

*Cambiamos descripción de columna grupo de vendedor y denominación
      lo_column ?= lo_columns->get_column( columnname = 'VKGRP' ).
      lo_column->set_short_text( 'Ag./Br.' ).
      lo_column->set_medium_text( 'Agente/Broker' ).
      lo_column->set_long_text( 'Agente/Broker' ).

      lo_column ?= lo_columns->get_column( columnname = 'BEZEI' ).
      lo_column->set_short_text( 'Nombre' ).
      lo_column->set_medium_text( 'Nombre' ).
      lo_column->set_long_text( 'Nombre' ).

*Cambiamos descripción de columna del número de viaje
      lo_column ?= lo_columns->get_column( columnname = 'TORID' ).
      lo_column->set_short_text( 'NoViaje' ).
      lo_column->set_medium_text( 'Número de Viaje' ).
      lo_column->set_long_text( 'Número de Viaje' ).

*Cambiamos descripción de columna del nombre de chofer
      lo_column ?= lo_columns->get_column( columnname = 'CONDU' ).
      lo_column->set_short_text( 'Chofer' ).
      lo_column->set_medium_text( 'Chofer' ).
      lo_column->set_long_text( 'Chofer' ).

*Cambiamos descripción de columna destinatario
      lo_column ?= lo_columns->get_column( columnname = 'KUNWE' ).
      lo_column->set_short_text( 'Dest.' ).
      lo_column->set_medium_text( 'Destinatario' ).
      lo_column->set_long_text( 'Destinatario de Mercancía' ).

*Cambiamos descripción de columna check in
      lo_column ?= lo_columns->get_column( columnname = 'DATECI' ).
      lo_column->set_short_text( 'Fe.Entr' ).
      lo_column->set_medium_text( 'Fecha Entrada' ).
      lo_column->set_long_text( 'Fecha de Entrada Transporte' ).

*Cambiamos descripción de columna check out
      lo_column ?= lo_columns->get_column( columnname = 'DATECO' ).
      lo_column->set_short_text( 'Fe.Sal.' ).
      lo_column->set_medium_text( 'Fecha Salida' ).
      lo_column->set_long_text( 'Fecha de Salida Transporte' ).

*Cambiamos descripción de columna fontera
      lo_column ?= lo_columns->get_column( columnname = 'FRONT' ).
      lo_column->set_short_text( 'Frontera' ).
      lo_column->set_medium_text( 'Frontera' ).
      lo_column->set_long_text( 'Frontera' ).

*Cambiamos descripción de columna transportista nacional
      lo_column ?= lo_columns->get_column( columnname = 'TRANA' ).
      lo_column->set_short_text( 'Tra.Nac.' ).
      lo_column->set_medium_text( 'Transportista Nac.' ).
      lo_column->set_long_text( 'Transportista Nacional' ).

*Cambiamos descripción de columna transportista extranjero
      lo_column ?= lo_columns->get_column( columnname = 'TRAEX' ).
      lo_column->set_short_text( 'Tra.Ext.' ).
      lo_column->set_medium_text( 'Transportista Ext.' ).
      lo_column->set_long_text( 'Transportista Extranjero' ).

*Cambiamos descripción de columna aduana nacional
      lo_column ?= lo_columns->get_column( columnname = 'ADUNA' ).
      lo_column->set_short_text( 'Adu.Nac.' ).
      lo_column->set_medium_text( 'Aduana Nac.' ).
      lo_column->set_long_text( 'Agente Aduanal Nacional' ).

*Cambiamos descripción de columna aduana extranjero
      lo_column ?= lo_columns->get_column( columnname = 'ADUEX' ).
      lo_column->set_short_text( 'Adu.Ext.' ).
      lo_column->set_medium_text( 'Aduana Ext.' ).
      lo_column->set_long_text( 'Agente Aduanal Extranjero' ).

*Colocamos columnas pedido, entrega, factura Y punto GPS como HotSpot.
      lo_column ?= lo_columns->get_column( columnname = 'VBELP' ).
      lo_column->set_cell_type( if_salv_c_cell_type=>hotspot ).

      lo_column ?= lo_columns->get_column( columnname = 'VBELE' ).
      lo_column->set_cell_type( if_salv_c_cell_type=>hotspot ).

      lo_column ?= lo_columns->get_column( columnname = 'VBELF' ).
      lo_column->set_cell_type( if_salv_c_cell_type=>hotspot ).

      lo_column ?= lo_columns->get_column( columnname = 'PGPS' ).
      lo_column->set_cell_type( if_salv_c_cell_type=>hotspot ).

*Cambiamos descripción de columna dias creación del pedido
      lo_column ?= lo_columns->get_column( columnname = 'DIASC' ).
      lo_column->set_short_text( 'Días Ant.' ).
      lo_column->set_medium_text( 'Días Ant.' ).
      lo_column->set_long_text( 'Días Ant' ).

*Cambiamos descripción de columna Indicador de Cita
      lo_column ?= lo_columns->get_column( columnname = 'CITA' ).
      lo_column->set_short_text( 'Ind.Cita' ).
      lo_column->set_medium_text( 'Ind. Cita' ).
      lo_column->set_long_text( 'Indicador de Cita' ).

*Cambiamos descripción de columna Observaciones
      lo_column ?= lo_columns->get_column( columnname = 'OBSERV' ).
      lo_column->set_short_text( 'Obs.' ).
      lo_column->set_medium_text( 'Observaciones' ).
      lo_column->set_long_text( 'Observaciones' ).

*Cambiamos descripción de columna Unidad de Porte
      lo_column ?= lo_columns->get_column( columnname = 'TORUF' ).
      lo_column->set_short_text( 'Un.Flete' ).
      lo_column->set_medium_text( 'Unidad Flete' ).
      lo_column->set_long_text( 'Unidad de Flete' ).

*Cambiamos descripción de columna UUID
      lo_column ?= lo_columns->get_column( columnname = 'UUID' ).
      lo_column->set_short_text( 'UUID' ).
      lo_column->set_medium_text( 'Folio Fiscal' ).
      lo_column->set_long_text( 'Folio Fiscal' ).

*Cambiamos descripción de columna error
      lo_column ?= lo_columns->get_column( columnname = 'ERROR' ).
      lo_column->set_short_text( 'Error' ).
      lo_column->set_medium_text( 'Error Tim.' ).
      lo_column->set_long_text( 'Error de Timbrado' ).

*Cambiamos descripción de columna PGPS
      lo_column ?= lo_columns->get_column( columnname = 'PGPS' ).
      lo_column->set_short_text( 'GPS' ).
      lo_column->set_medium_text( 'Pto. GPS' ).
      lo_column->set_long_text( 'Punto GPS' ).
      lo_column->set_alignment( if_salv_c_alignment=>centered ).

    CATCH cx_salv_msg INTO cx_salv.
      gr_msg = cx_salv->get_text( ).
      MESSAGE gr_msg TYPE 'E'.
    CATCH cx_salv_not_found INTO cx_not_found.
      gr_msg = cx_not_found->get_text( ).
      MESSAGE gr_msg TYPE 'E'..
  ENDTRY.

* Posiciones
  lo_columns->set_column_position( columnname = 'BSTKD'  position = 1 ).  "Pedido de cliente
  lo_columns->set_column_position( columnname = 'KUNNR'  position = 2 ).  "Cliente
  lo_columns->set_column_position( columnname = 'NAMSO'  position = 3 ).  "Nombre de cliente
  lo_columns->set_column_position( columnname = 'KUNWE'  position = 4 ).  "Destinatario de mercancía
  lo_columns->set_column_position( columnname = 'NAMWE'  position = 5 ).  "Nombre del destinatario de mercancía
  lo_columns->set_column_position( columnname = 'STREET' position = 6 ).  "Calle
  lo_columns->set_column_position( columnname = 'HOUSEN' position = 7 ).  "Número
  lo_columns->set_column_position( columnname = 'CITY2'  position = 8 ).  "Distrito
  lo_columns->set_column_position( columnname = 'CITY'   position = 9 ).  "Población
  lo_columns->set_column_position( columnname = 'POSTL'  position = 10 ).  "Código postal
  lo_columns->set_column_position( columnname = 'REION'  position = 11 ). "Estado
  lo_columns->set_column_position( columnname = 'LAND'   position = 12 ). "País
  lo_columns->set_column_position( columnname = 'PGPS'   position = 13 ). "Punto GPS
  lo_columns->set_column_position( columnname = 'VKGRP'  position = 14 ). "Grupo de vendedores (agente/broker)
  lo_columns->set_column_position( columnname = 'BEZEI'  position = 15 ). "Nombre del agente/broker
  lo_columns->set_column_position( columnname = 'ROUTE'  position = 16 ). "Ruta
  lo_columns->set_column_position( columnname = 'WERKS'  position = 17 ). "Centro
  lo_columns->set_column_position( columnname = 'LGORT'  position = 18 ). "Almacén
  lo_columns->set_column_position( columnname = 'ERDAT'  position = 19 ). "Creado el
  lo_columns->set_column_position( columnname = 'GBSTK'  position = 20 ). "Estado global
  lo_columns->set_column_position( columnname = 'DIASC'  position = 21 ). "Días creación
  lo_columns->set_column_position( columnname = 'VBELP'  position = 22 ). "Pedido
  lo_columns->set_column_position( columnname = 'KWMENG' position = 23 ). "Cantidad
  lo_columns->set_column_position( columnname = 'BRGEW'  position = 24 ). "Peso Bruto
  lo_columns->set_column_position( columnname = 'NTGEW'  position = 25 ). "Peso Neto
  lo_columns->set_column_position( columnname = 'VOLUM'  position = 26 ). "Volumen
  lo_columns->set_column_position( columnname = 'VBELE'  position = 27 ). "Entrega
  lo_columns->set_column_position( columnname = 'STSME'  position = 28 ). "Estatus de salida de mercancía
  lo_columns->set_column_position( columnname = 'STARE'  position = 29 ). "Estatus de acuse de recibo de entrega
  lo_columns->set_column_position( columnname = 'STFEN'  position = 30 ). "Estatus de factura relacionada a entrega
  lo_columns->set_column_position( columnname = 'STGEN'  position = 31 ). "Estatus global de entrega
  lo_columns->set_column_position( columnname = 'TORUF'  position = 32 ). "Unidad de Flete
  lo_columns->set_column_position( columnname = 'VBELF'  position = 33 ). "Factura
  lo_columns->set_column_position( columnname = 'UUID'   position = 34 ). "Folio Fiscal
  lo_columns->set_column_position( columnname = 'ERROR'  position = 35 ). "Mensaje de Error
  lo_columns->set_column_position( columnname = 'TORID'  position = 36 ). "Orden de Flete
  lo_columns->set_column_position( columnname = 'CONDU'  position = 37 ). "Chofer
  lo_columns->set_column_position( columnname = 'DATECI' position = 38 ). "Fecha de llegada del transporte (CheckIn)
  lo_columns->set_column_position( columnname = 'VDATU'  position = 39 ). "Fecha preferente de entrega
  lo_columns->set_column_position( columnname = 'CITA'   position = 40 ). "Indicador de Cita
  lo_columns->set_column_position( columnname = 'OBSERV' position = 41 ). "Observaciones o Instrucciones especiales
  lo_columns->set_column_position( columnname = 'DATES'  position = 42 ). "Fecha real de salida del CEDIS
  lo_columns->set_column_position( columnname = 'DATECO' position = 43 ). "Fecha de salida del transporte (CheckOut)
  lo_columns->set_column_position( columnname = 'DATEC'  position = 44 ). "Fecha real de cruce de aduana
  lo_columns->set_column_position( columnname = 'DATEE'  position = 45 ). "Fecha real de entrega a cliente
  lo_columns->set_column_position( columnname = 'INCO'   position = 46 ). "Incoterm
  lo_columns->set_column_position( columnname = 'FRONT'  position = 47 ). "Lugar de Incoterm
  lo_columns->set_column_position( columnname = 'TRANA'  position = 48 ). "Transportista nacional
  lo_columns->set_column_position( columnname = 'TRAEX'  position = 49 ). "Transportista extranjero
  lo_columns->set_column_position( columnname = 'ADUNA'  position = 50 ). "Agente aduanal nacional
  lo_columns->set_column_position( columnname = 'ADUEX'  position = 51 ). "Agente aduanal extranjero

* Aplicando estilo zebra
  lo_display = lo_gr_alv->get_display_settings( ).
  lo_display->set_striped_pattern( cl_salv_display_settings=>true ).

* Eventos
  lo_events = lo_gr_alv->get_event( ).
  CREATE OBJECT lo_event_handler.
  SET HANDLER lo_event_handler->on_double_click FOR lo_events.

* Enable cell selection mode
  lo_selections = lo_gr_alv->get_selections( ).
  lo_selections->set_selection_mode( if_salv_c_selection_mode=>row_column ).

  lo_gr_alv->display( ).

  IF sy-subrc <> 0.
    MESSAGE 'ERROR AL MOSTRAR LISTADO' TYPE 'X'.
  ENDIF.
ENDFORM.
