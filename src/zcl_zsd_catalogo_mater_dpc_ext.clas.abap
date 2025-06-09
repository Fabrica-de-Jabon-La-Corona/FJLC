class ZCL_ZSD_CATALOGO_MATER_DPC_EXT definition
  public
  inheriting from ZCL_ZSD_CATALOGO_MATER_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_EXPANDED_ENTITYSET
    redefinition .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ZSD_CATALOGO_MATER_DPC_EXT IMPLEMENTATION.


  METHOD /iwbep/if_mgw_appl_srv_runtime~get_expanded_entityset.
    DATA: ls_materiales     TYPE zcl_zsd_catalogo_mater_mpc_ext=>ts_de_materiales,
          lt_materiales     LIKE TABLE OF ls_materiales,
          ls_existencias    TYPE zcl_zsd_catalogo_mater_mpc_ext=>ts_existencias,
          ls_unidadesmedida TYPE zcl_zsd_catalogo_mater_mpc_ext=>ts_unidadesmedida.

    DATA: lo_tech_request TYPE REF TO /iwbep/cl_mgw_request.

    DATA: lv_emenge TYPE ekpo-menge.

    CASE iv_entity_set_name.
      WHEN 'MaterialesSet'.

*Select a tabla de materiales (MARA) validando que estén extendidos para el canal 01 (Tradicional).
        SELECT FROM mara AS ma
          INNER JOIN mvke AS mv ON mv~matnr EQ ma~matnr
          INNER JOIN makt AS mt ON mt~matnr EQ mv~matnr
          INNER JOIN mlan AS ml ON ml~matnr EQ mt~matnr
          FIELDS ma~matnr, ma~meins, mv~vrkme, mt~maktx, mv~prodh, ma~brgew, ma~ntgew, ma~volum, ma~gewei, ma~voleh, ml~taxm1
          WHERE ma~lvorm EQ ''
          AND ( ma~mtart EQ 'ZFER'
          OR ma~mtart EQ 'HAWA' )
          AND mv~vkorg EQ '1000'
          AND mv~vtweg EQ '01'
          AND mt~spras EQ 'S'
          AND ml~aland EQ 'MX'
          AND mv~lvorm EQ ''
          AND mv~vmsta EQ ''
          AND ma~mstav EQ ''
          INTO TABLE @DATA(lt_mara).

        SORT lt_mara ASCENDING BY matnr.

*Select a tabla de existencias (MCHB).
        SELECT matnr, werks, lgort, SUM( clabs ) AS clabs
          INTO TABLE @DATA(lt_mchb)
          FROM mchb
          WHERE clabs GT 0
          GROUP BY matnr, werks, lgort.

        SORT lt_mchb ASCENDING BY matnr werks lgort.

*Select a tabla de unidades de medida (MARM).
        SELECT * FROM marm
          FOR ALL ENTRIES IN @lt_mara
          WHERE matnr EQ @lt_mara-matnr
          INTO TABLE @DATA(lt_marm).

*Armado de response
*Datos Generales*
        LOOP AT lt_mara ASSIGNING FIELD-SYMBOL(<fs_mara>).
          IF <fs_mara>-vrkme EQ ''.
            <fs_mara>-vrkme = <fs_mara>-meins.
          ENDIF.

          ls_materiales-material       = |{ <fs_mara>-matnr ALPHA = OUT }|.
          ls_materiales-umb            = |{ <fs_mara>-meins ALPHA = OUT }|.
          ls_materiales-umv            = |{ <fs_mara>-vrkme ALPHA = OUT }|.
          ls_materiales-descripcion    = <fs_mara>-maktx.
          ls_materiales-jerarquia      = <fs_mara>-prodh.
          ls_materiales-pesobruto      = <fs_mara>-brgew.
          ls_materiales-pesoneto       = <fs_mara>-ntgew.
          ls_materiales-volumen        = <fs_mara>-volum.
          ls_materiales-unidadpeso     = <fs_mara>-gewei.
          ls_materiales-unidadvolumen  = <fs_mara>-voleh.
          ls_materiales-materiallegado = ''.
          ls_materiales-aplicaiva      = <fs_mara>-taxm1.

          CONDENSE: ls_materiales-pesobruto, ls_materiales-pesoneto, ls_materiales-volumen.

*Existencias*
          LOOP AT lt_mchb ASSIGNING FIELD-SYMBOL(<fs_mchb>) WHERE matnr EQ <fs_mara>-matnr.
            ls_existencias-material = |{ <fs_mchb>-matnr ALPHA = OUT }|.
            ls_existencias-centro   = <fs_mchb>-werks.
            ls_existencias-almacen  = <fs_mchb>-lgort.
            ls_existencias-unidadlu = <fs_mara>-vrkme.

            CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
              EXPORTING
                i_matnr              = <fs_mchb>-matnr
                i_in_me              = <fs_mara>-meins
                i_out_me             = <fs_mara>-vrkme
                i_menge              = <fs_mchb>-clabs
              IMPORTING
                e_menge              = lv_emenge
              EXCEPTIONS
                error_in_application = 1
                error                = 2
                OTHERS               = 3.
            IF sy-subrc <> 0.
              MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
            ENDIF.

            ls_existencias-libreutilizacion = lv_emenge.

            CONDENSE: ls_existencias-libreutilizacion.

            APPEND ls_existencias TO ls_materiales-to_existencias.
            CLEAR: ls_existencias, <fs_mchb>.
          ENDLOOP.
          UNASSIGN: <fs_mchb>.

*Unidades de Medida*
          LOOP AT lt_marm ASSIGNING FIELD-SYMBOL(<fs_marm>) WHERE matnr EQ <fs_mara>-matnr AND meinh EQ <fs_mara>-vrkme.
            ls_unidadesmedida-material    = |{ <fs_marm>-matnr ALPHA = OUT }|.
            ls_unidadesmedida-cantidadumb = <fs_marm>-umrez.
            ls_unidadesmedida-umb         = <fs_mara>-meins.
            ls_unidadesmedida-cantidaduma = <fs_marm>-umren.
            ls_unidadesmedida-uma         = <fs_marm>-meinh.

            APPEND ls_unidadesmedida TO ls_materiales-to_unidadesmedida.
            CLEAR: ls_unidadesmedida, <fs_marm>.
          ENDLOOP.
          UNASSIGN: <fs_marm>.

          APPEND ls_materiales TO lt_materiales.
          CLEAR: ls_materiales, <fs_mara>.
        ENDLOOP.
        UNASSIGN: <fs_mara>.
    ENDCASE.

*Se regresa la deep entity comprobante para dar salida en el response.
    CALL METHOD me->copy_data_to_ref
      EXPORTING
        is_data = lt_materiales
      CHANGING
        cr_data = er_entityset.

*Asignación de propiedades de navegación
    lo_tech_request ?= io_tech_request_context.
    DATA(lv_expand) = lo_tech_request->/iwbep/if_mgw_req_entityset~get_expand( ).
    TRANSLATE lv_expand TO UPPER CASE.
    SPLIT lv_expand AT ',' INTO TABLE et_expanded_tech_clauses.
  ENDMETHOD.
ENDCLASS.
