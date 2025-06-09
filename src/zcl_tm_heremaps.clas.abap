CLASS zcl_tm_heremaps DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS: get_latlon_cpd IMPORTING iv_adrnr     TYPE adrnr
                            EXPORTING iv_latitude  TYPE /sapapo/loc-ypos
                                      iv_longitude TYPE /sapapo/loc-xpos,
      get_distance   IMPORTING iv_latdes   TYPE string
                               iv_londes   TYPE string
                               iv_latori   TYPE string
                               iv_lonori   TYPE string
                               iv_adrnr    TYPE adrnr
                     EXPORTING iv_distance TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.

    METHODS:  get_geocode_here IMPORTING iv_street   TYPE adrc-street
                                         iv_housenum TYPE adrc-house_num1
                                         iv_city     TYPE adrc-city1
                                         iv_district TYPE adrc-city2
                                         iv_postcode TYPE adrc-post_code1
                                         iv_state    TYPE bezei
                                         iv_country  TYPE landx.

    DATA: mv_street   TYPE adrc-street,
          mv_housenum TYPE adrc-house_num1,
          mv_city     TYPE adrc-city1,
          mv_district TYPE adrc-city2,
          mv_postcode TYPE adrc-post_code1,
          mv_region   TYPE regio,
          mv_land     TYPE land1,
          mv_state    TYPE bezei,
          mv_country  TYPE landx,
          mv_xpos     TYPE /sapapo/loc-xpos,
          mv_ypos     TYPE /sapapo/loc-ypos,
          mv_distance TYPE string.

ENDCLASS.



CLASS ZCL_TM_HEREMAPS IMPLEMENTATION.


  METHOD get_distance.
    CONSTANTS: lc_apikey TYPE string VALUE '&key=AIzaSyAQttuWAh0q3hvkyUOwupXT-vxpHPPlM2I',
               lc_uri    TYPE string VALUE 'https://maps.googleapis.com/maps/api/distancematrix/json?destinations='.

    DATA: lv_latdes        TYPE string,
          lv_londes        TYPE string,
          lv_latori        TYPE string,
          lv_lonori        TYPE string,
          lv_json_response TYPE string,
          lv_http_status   TYPE i,
          lv_lenlon        TYPE i,
          lv_lenlat        TYPE i,
          lv_offsetlon     TYPE i,
          lv_offsetlat     TYPE i,
          lv_signolon      TYPE string,
          lv_signolat      TYPE string,
          lt_return        TYPE TABLE OF bapiret2.

*Si no existen las coordenadas en BD, se consulta el servicio para obtener coordenadas mediante la dirección del destino.
    IF iv_latdes EQ '' OR iv_londes EQ ''.
      me->get_latlon_cpd(
        EXPORTING
          iv_adrnr     = iv_adrnr
        IMPORTING
          iv_latitude  = me->mv_ypos
          iv_longitude = me->mv_xpos
      ).

      lv_latdes = mv_ypos.
      lv_londes = mv_xpos.

    ELSE.
      lv_latdes = iv_latdes.
      lv_londes = iv_londes.
    ENDIF.

*Si hay coordenadas negativas se reacomoda el signo al inicio de la coordenada.

    lv_lenlat = strlen( lv_latdes ).
    lv_lenlon = strlen( lv_londes ).

    lv_offsetlat = lv_lenlat - 1.
    lv_offsetlon = lv_lenlon - 1.

    lv_signolat = lv_latdes+lv_offsetlat(1).
    lv_signolon = lv_londes+lv_offsetlon(1).

    IF lv_signolat EQ '-'.
      CONCATENATE '-' lv_latdes(lv_lenlat) INTO lv_latdes.
      lv_latdes = lv_latdes(lv_lenlat).
    ENDIF.

    IF lv_signolon EQ '-'.
      CONCATENATE '-' lv_londes(lv_lenlon) INTO lv_londes.
      lv_londes = lv_londes(lv_lenlon).
    ENDIF.

    CLEAR: lv_lenlon, lv_lenlat, lv_offsetlon, lv_offsetlat,  lv_signolon, lv_signolat.

*Arma parámetros.
    "Destino
    CONDENSE: lv_latdes, lv_londes.

    CONCATENATE lv_latdes ',' lv_londes INTO DATA(lv_coordinatesdes).

    CONDENSE lv_coordinatesdes.

    "Origen
    lv_latori = iv_latori.
    lv_lonori = iv_lonori.

*Si hay coordenadas negativas se reacomoda el signo al inicio de la coordenada.

    lv_lenlat = strlen( lv_latori ).
    lv_lenlon = strlen( lv_lonori ).

    lv_offsetlat = lv_lenlat - 1.
    lv_offsetlon = lv_lenlon - 1.

    lv_signolat = lv_latori+lv_offsetlat(1).
    lv_signolon = lv_lonori+lv_offsetlon(1).

    IF lv_signolat EQ '-'.
      CONCATENATE '-' lv_latori(lv_lenlat) INTO lv_latdes.
      lv_latori = lv_latori(lv_lenlat).
    ENDIF.

    IF lv_signolon EQ '-'.
      CONCATENATE '-' lv_lonori(lv_lenlon) INTO lv_lonori.
      lv_lonori = lv_lonori(lv_lenlon).
    ENDIF.

    CLEAR: lv_lenlon, lv_lenlat, lv_offsetlon, lv_offsetlat,  lv_signolon, lv_signolat.

    CONDENSE: lv_latori, lv_lonori.

    CONCATENATE '&origins=' lv_latori ',' lv_lonori INTO DATA(lv_coordinatesori).

    CONDENSE lv_coordinatesori.

*Armado de request.

    CONCATENATE lc_uri lv_coordinatesdes lv_coordinatesori lc_apikey INTO DATA(lv_request).

* Objetos para manejo de WS.
    DATA: lo_http_client TYPE REF TO if_http_client,
          lo_response    TYPE REF TO if_http_response,
          lo_request     TYPE REF TO if_http_request.

* Crear el cliente HTTP
    CALL METHOD cl_http_client=>create_by_url
      EXPORTING
        url                = lv_request
      IMPORTING
        client             = lo_http_client
      EXCEPTIONS
        argument_not_found = 1
        plugin_not_active  = 2
        internal_error     = 3
        OTHERS             = 4.

    IF sy-subrc <> 0.
      WRITE: / 'Error al crear el cliente HTTP.'.
      EXIT.
    ENDIF.

* Enviar solicitud GET
    CALL METHOD lo_http_client->send
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        OTHERS                     = 4.
    IF sy-subrc <> 0.
      WRITE: / 'Error al enviar la solicitud HTTP'.
      EXIT.
    ENDIF.

* Obtener respuesta
    CALL METHOD lo_http_client->receive
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        OTHERS                     = 4.
    IF sy-subrc <> 0.
      WRITE: / 'Error al recibir la respuesta HTTP'.
      EXIT.
    ENDIF.

    lv_json_response = lo_http_client->response->get_cdata( ).

*Deserealizar el archivo JSON.

    DATA: lo_json_parser TYPE REF TO /ui5/cl_json_parser.

    " Instanciar el parser JSON
    CREATE OBJECT lo_json_parser.

    " Convertir JSON a estructura interna
    CALL METHOD lo_json_parser->parse
      EXPORTING
        json = lv_json_response.

    DATA(lt_ret_data) = lo_json_parser->m_entries.

*Obtiene distancia
    READ TABLE lt_ret_data ASSIGNING FIELD-SYMBOL(<fs_ret_data>) WITH KEY parent = '/rows/1/elements/1/distance' name = 'value'.
    IF <fs_ret_data> IS ASSIGNED.
      iv_distance = <fs_ret_data>-value.
      UNASSIGN <fs_ret_data>.
    ENDIF.

  ENDMETHOD.


  METHOD get_geocode_here.

    CONSTANTS: "lc_apikey TYPE string VALUE '&limit=1&apiKey=1a7NPhvmZJREe1baR2wvhVOQ-zp91VMsOgAIErM3diM',
      "lc_uri    TYPE string VALUE 'https://geocode.search.hereapi.com/v1/geocode?qq='.
      lc_apikey TYPE string VALUE '&key=AIzaSyAQttuWAh0q3hvkyUOwupXT-vxpHPPlM2I',
      lc_uri    TYPE string VALUE 'https://maps.google.com/maps/api/geocode/json?address='.

    DATA: lv_street        TYPE string,
          lv_housenum      TYPE string,
          lv_city          TYPE string,
          lv_district      TYPE string,
          lv_postcode      TYPE string,
          lv_state         TYPE string,
          lv_country       TYPE string,
          lv_request       TYPE string,
          lv_json_response TYPE string,
          lv_http_status   TYPE i,
          lt_return        TYPE TABLE OF bapiret2.

    "CONCATENATE 'street=' iv_street ';' INTO lv_street.
    "CONCATENATE 'houseNumber=' iv_housenum ';' INTO lv_housenum.
    "CONCATENATE 'city=' iv_city ';' INTO lv_city.
    "CONCATENATE 'district=' iv_district ';' INTO lv_district.
    "CONCATENATE 'postalCode=' iv_postcode ';' INTO lv_postcode.
    "CONCATENATE 'state=' iv_state ';' INTO lv_state.
    "CONCATENATE 'country=' iv_country INTO lv_country.

    CONCATENATE iv_street '+' INTO lv_street.
    CONCATENATE iv_housenum '+' INTO lv_housenum.
    CONCATENATE iv_city '+' INTO lv_city.
    CONCATENATE iv_district '+' INTO lv_district.
    CONCATENATE iv_postcode '+' INTO lv_postcode.
    CONCATENATE iv_state '+' INTO lv_state.

* Armado de request.

    "CONCATENATE lc_uri lv_street lv_housenum lv_city lv_district lv_postcode lv_state lv_country lc_apikey INTO lv_request.
    CONCATENATE lc_uri lv_street lv_housenum lv_city lv_district lv_postcode lv_state iv_country lc_apikey INTO lv_request.

* Objetos para manejo de WS.
    DATA: lo_http_client TYPE REF TO if_http_client,
          lo_response    TYPE REF TO if_http_response,
          lo_request     TYPE REF TO if_http_request.

* Crear el cliente HTTP
    CALL METHOD cl_http_client=>create_by_url
      EXPORTING
        url                = lv_request
      IMPORTING
        client             = lo_http_client
      EXCEPTIONS
        argument_not_found = 1
        plugin_not_active  = 2
        internal_error     = 3
        OTHERS             = 4.

    IF sy-subrc <> 0.
      WRITE: / 'Error al crear el cliente HTTP.'.
      EXIT.
    ENDIF.

* Enviar solicitud GET
    CALL METHOD lo_http_client->send
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        OTHERS                     = 4.
    IF sy-subrc <> 0.
      WRITE: / 'Error al enviar la solicitud HTTP'.
      EXIT.
    ENDIF.

* Obtener respuesta
    CALL METHOD lo_http_client->receive
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        OTHERS                     = 4.
    IF sy-subrc <> 0.
      WRITE: / 'Error al recibir la respuesta HTTP'.
      EXIT.
    ENDIF.

    lv_json_response = lo_http_client->response->get_cdata( ).

*Deserealizar el archivo JSON.

    DATA: lo_json_parser TYPE REF TO /ui5/cl_json_parser.

    " Instanciar el parser JSON
    CREATE OBJECT lo_json_parser.

    " Convertir JSON a estructura interna
    CALL METHOD lo_json_parser->parse
      EXPORTING
        json = lv_json_response.

    DATA(lt_ret_data) = lo_json_parser->m_entries.

    DATA: lv_parent TYPE string.

    READ TABLE lt_ret_data ASSIGNING FIELD-SYMBOL(<fs_ret_data>) WITH KEY value = 'postal_code'.

    IF <fs_ret_data> IS ASSIGNED.
      lv_parent = <fs_ret_data>-parent(11).
      CONCATENATE lv_parent 'geometry/location' INTO lv_parent.
      CONDENSE lv_parent.
      UNASSIGN: <fs_ret_data>.
    ELSE.
      lv_parent = '/results/1/geometry/location'.
    ENDIF.

*Asignar latitud y longitud.
    "LOOP AT lt_ret_data ASSIGNING FIELD-SYMBOL(<fs_ret_data>) WHERE parent = '/items/1/position'.
    "LOOP AT lt_ret_data ASSIGNING <fs_ret_data> WHERE parent = '/results/1/geometry/location'.
    LOOP AT lt_ret_data ASSIGNING <fs_ret_data> WHERE parent = lv_parent.
      IF <fs_ret_data>-name EQ 'lat'.
        mv_ypos = <fs_ret_data>-value.
      ELSEIF <fs_ret_data>-name EQ 'lng'.
        mv_xpos = <fs_ret_data>-value.
      ENDIF.
    ENDLOOP.
    UNASSIGN <fs_ret_data>.

  ENDMETHOD.


  METHOD get_latlon_cpd.

    SELECT SINGLE FROM adrc
      FIELDS street, house_num1, city1, city2, post_code1, region, country
      WHERE addrnumber = @iv_adrnr
      INTO ( @mv_street, @mv_housenum, @mv_city, @mv_district, @mv_postcode, @mv_region, @mv_land ).

    SELECT SINGLE FROM t005t
      FIELDS landx
      WHERE spras = 'S'
      AND land1 = @mv_land
      INTO @mv_country.

    SELECT SINGLE FROM t005u
      FIELDS bezei
      WHERE spras = 'S'
      AND land1 = @mv_land
      AND bland = @mv_region
      INTO @mv_state.

    me->get_geocode_here( iv_city = mv_city iv_country = mv_country iv_district = mv_district iv_housenum = mv_housenum iv_postcode = mv_postcode iv_state = mv_state iv_street = mv_street ).

    iv_latitude = mv_ypos.
    iv_longitude = mv_xpos.

  ENDMETHOD.
ENDCLASS.
