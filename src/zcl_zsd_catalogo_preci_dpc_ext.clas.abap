class ZCL_ZSD_CATALOGO_PRECI_DPC_EXT definition
  public
  inheriting from ZCL_ZSD_CATALOGO_PRECI_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_EXPANDED_ENTITYSET
    redefinition .
protected section.

  methods DESCUENTOSSET_GET_ENTITYSET
    redefinition .
  methods IMPUESTOSSET_GET_ENTITYSET
    redefinition .
  methods PRECIOSSET_GET_ENTITYSET
    redefinition .
  methods PROMOCIONESSET_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZSD_CATALOGO_PRECI_DPC_EXT IMPLEMENTATION.


  METHOD /iwbep/if_mgw_appl_srv_runtime~get_expanded_entityset.
    DATA: ls_promos       TYPE zcl_zsd_catalogo_preci_mpc_ext=>ts_de_promociones,
          lt_promos       LIKE TABLE OF ls_promos,
          ls_promoescala  TYPE zcl_zsd_catalogo_preci_mpc_ext=>ts_promoescala,
          lo_tech_request TYPE REF TO /iwbep/cl_mgw_request.

    CASE iv_entity_set_name.
      WHEN 'PromocionesSet'.
        "Obtenemos registros de condición para promociones (cl. cond. ZDKA).
        "Secuencia Canal / Ref. cliente / Material (Tabla A523).
        SELECT FROM a523 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~zzbstkd, a~matnr, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl EQ 'ZDKA'
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a523).

        "Secuencia Canal / Ref. pedido / Material (Tabla A524).
        SELECT FROM a524 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~zzihrez, a~matnr, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl EQ 'ZDKA'
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a524).

        "Secuencia Canal / Ref. cliente (Tabla A521).
        SELECT FROM a521 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~zzbstkd, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl EQ 'ZDKA'
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a521).

        "Secuencia Canal / Ref. pedido (Tabla A520).
        SELECT FROM a520 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~zzihrez, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl EQ 'ZDKA'
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a520).

        SELECT * FROM konm
          INTO TABLE @DATA(lt_konm).

        LOOP AT lt_a523 ASSIGNING FIELD-SYMBOL(<fs_a523>).
          ls_promos-kschl   = <fs_a523>-kschl.
          ls_promos-knumh   = <fs_a523>-knumh.
          ls_promos-vtweg   = <fs_a523>-vtweg.
          ls_promos-zzbstkd = <fs_a523>-zzbstkd.
          ls_promos-matnr   = |{ <fs_a523>-matnr ALPHA = OUT }|.
          ls_promos-datab   = <fs_a523>-datab.
          ls_promos-datbi   = <fs_a523>-datbi.
          ls_promos-kbetr   = <fs_a523>-kbetr / 10.
          ls_promos-konwa   = <fs_a523>-konwa.
          ls_promos-kpein   = <fs_a523>-kpein.
          ls_promos-kmein   = <fs_a523>-kmein.
          ls_promos-orden   = '1'.

          CONDENSE: ls_promos-kbetr, ls_promos-kpein.

          LOOP AT lt_konm ASSIGNING FIELD-SYMBOL(<fs_konm>) WHERE knumh = <fs_a523>-knumh.
            ls_promoescala-knumh = <fs_konm>-knumh.
            ls_promoescala-kschl = <fs_a523>-kschl.
            ls_promoescala-kopos = <fs_konm>-kopos.
            ls_promoescala-klfn1 = <fs_konm>-klfn1.
            ls_promoescala-kbetr = <fs_konm>-kbetr / 10.
            ls_promoescala-kstbm = <fs_konm>-kstbm.

            CONDENSE: ls_promoescala-kbetr, ls_promoescala-kstbm.

            APPEND ls_promoescala TO ls_promos-to_promoescalas.
            SORT ls_promos-to_promoescalas ASCENDING BY knumh kopos klfn1.
            CLEAR: ls_promoescala, <fs_konm>, ls_promos-kbetr, ls_promos-konwa, ls_promos-kpein.
          ENDLOOP.
          UNASSIGN: <fs_konm>.

          APPEND ls_promos TO lt_promos.
          CLEAR: ls_promos, <fs_a523>.
        ENDLOOP.
        UNASSIGN: <fs_a523>.

        LOOP AT lt_a524 ASSIGNING FIELD-SYMBOL(<fs_a524>).
          ls_promos-kschl   = <fs_a524>-kschl.
          ls_promos-knumh   = <fs_a524>-knumh.
          ls_promos-vtweg   = <fs_a524>-vtweg.
          ls_promos-zzihrez = <fs_a524>-zzihrez.
          ls_promos-matnr   = |{ <fs_a524>-matnr ALPHA = OUT }|.
          ls_promos-datab   = <fs_a524>-datab.
          ls_promos-datbi   = <fs_a524>-datbi.
          ls_promos-kbetr   = <fs_a524>-kbetr / 10.
          ls_promos-konwa   = <fs_a524>-konwa.
          ls_promos-kpein   = <fs_a524>-kpein.
          ls_promos-kmein   = <fs_a524>-kmein.
          ls_promos-orden   = '2'.

          CONDENSE: ls_promos-kbetr, ls_promos-kpein.

          LOOP AT lt_konm ASSIGNING <fs_konm> WHERE knumh = <fs_a524>-knumh.
            ls_promoescala-knumh = <fs_konm>-knumh.
            ls_promoescala-kschl = <fs_a524>-kschl.
            ls_promoescala-kopos = <fs_konm>-kopos.
            ls_promoescala-klfn1 = <fs_konm>-klfn1.
            ls_promoescala-kbetr = <fs_konm>-kbetr / 10.
            ls_promoescala-kstbm = <fs_konm>-kstbm.

            CONDENSE: ls_promoescala-kbetr, ls_promoescala-kstbm.

            APPEND ls_promoescala TO ls_promos-to_promoescalas.
            SORT ls_promos-to_promoescalas ASCENDING BY knumh kopos klfn1.
            CLEAR: ls_promoescala, <fs_konm>, ls_promos-kbetr, ls_promos-konwa, ls_promos-kpein.
          ENDLOOP.
          UNASSIGN: <fs_konm>.

          APPEND ls_promos TO lt_promos.
          CLEAR: ls_promos, <fs_a524>.
        ENDLOOP.
        UNASSIGN: <fs_a524>.

        LOOP AT lt_a521 ASSIGNING FIELD-SYMBOL(<fs_a521>).
          ls_promos-kschl   = <fs_a521>-kschl.
          ls_promos-knumh   = <fs_a521>-knumh.
          ls_promos-vtweg   = <fs_a521>-vtweg.
          ls_promos-zzbstkd = <fs_a521>-zzbstkd.
          ls_promos-datab   = <fs_a521>-datab.
          ls_promos-datbi   = <fs_a521>-datbi.
          ls_promos-kbetr   = <fs_a521>-kbetr / 10.
          ls_promos-konwa   = <fs_a521>-konwa.
          ls_promos-kpein   = <fs_a521>-kpein.
          ls_promos-kmein   = <fs_a521>-kmein.
          ls_promos-orden   = '3'.

          CONDENSE: ls_promos-kbetr, ls_promos-kpein.

          LOOP AT lt_konm ASSIGNING <fs_konm> WHERE knumh = <fs_a521>-knumh.
            ls_promoescala-knumh = <fs_konm>-knumh.
            ls_promoescala-kschl = <fs_a521>-kschl.
            ls_promoescala-kopos = <fs_konm>-kopos.
            ls_promoescala-klfn1 = <fs_konm>-klfn1.
            ls_promoescala-kbetr = <fs_konm>-kbetr / 10.
            ls_promoescala-kstbm = <fs_konm>-kstbm.

            CONDENSE: ls_promoescala-kbetr, ls_promoescala-kstbm.

            APPEND ls_promoescala TO ls_promos-to_promoescalas.
            SORT ls_promos-to_promoescalas ASCENDING BY knumh kopos klfn1.
            CLEAR: ls_promoescala, <fs_konm>, ls_promos-kbetr, ls_promos-konwa, ls_promos-kpein.
          ENDLOOP.
          UNASSIGN: <fs_konm>.

          APPEND ls_promos TO lt_promos.
          CLEAR: ls_promos, <fs_a521>.
        ENDLOOP.
        UNASSIGN: <fs_a521>.

        LOOP AT lt_a520 ASSIGNING FIELD-SYMBOL(<fs_a520>).
          ls_promos-kschl   = <fs_a520>-kschl.
          ls_promos-knumh   = <fs_a520>-knumh.
          ls_promos-vtweg   = <fs_a520>-vtweg.
          ls_promos-zzihrez = <fs_a520>-zzihrez.
          ls_promos-datab   = <fs_a520>-datab.
          ls_promos-datbi   = <fs_a520>-datbi.
          ls_promos-kbetr   = <fs_a520>-kbetr / 10.
          ls_promos-konwa   = <fs_a520>-konwa.
          ls_promos-kpein   = <fs_a520>-kpein.
          ls_promos-kmein   = <fs_a520>-kmein.
          ls_promos-orden   = '4'.

          CONDENSE: ls_promos-kbetr, ls_promos-kpein.

          LOOP AT lt_konm ASSIGNING <fs_konm> WHERE knumh = <fs_a520>-knumh.
            ls_promoescala-knumh = <fs_konm>-knumh.
            ls_promoescala-kschl = <fs_a520>-kschl.
            ls_promoescala-kopos = <fs_konm>-kopos.
            ls_promoescala-klfn1 = <fs_konm>-klfn1.
            ls_promoescala-kbetr = <fs_konm>-kbetr / 10.
            ls_promoescala-kstbm = <fs_konm>-kstbm.

            CONDENSE: ls_promoescala-kbetr, ls_promoescala-kstbm.

            APPEND ls_promoescala TO ls_promos-to_promoescalas.
            SORT ls_promos-to_promoescalas ASCENDING BY knumh kopos klfn1.
            CLEAR: ls_promoescala, <fs_konm>, ls_promos-kbetr, ls_promos-konwa, ls_promos-kpein.
          ENDLOOP.
          UNASSIGN: <fs_konm>.

          APPEND ls_promos TO lt_promos.
          CLEAR: ls_promos, <fs_a520>.
        ENDLOOP.
        UNASSIGN: <fs_a520>.

    ENDCASE.

    copy_data_to_ref(
      EXPORTING
        is_data = lt_promos
      CHANGING
        cr_data = er_entityset ).

    "Asignación de propiedades de navegación
    lo_tech_request ?= io_tech_request_context.
    DATA(lv_expand) = lo_tech_request->/iwbep/if_mgw_req_entityset~get_expand( ).
    TRANSLATE lv_expand TO UPPER CASE.
    SPLIT lv_expand AT ',' INTO TABLE et_expanded_tech_clauses.

  ENDMETHOD.


  METHOD descuentosset_get_entityset.
    DATA: ls_descuentos TYPE zcl_zsd_catalogo_preci_mpc_ext=>ts_descuentos.

    CASE iv_entity_set_name.
      WHEN 'DescuentosSet'.
        "Obtenemos registros de condición para descuentos (cl. cond. ZDES, ZDTF).
        "Secuencia Canal / Cliente / Material (Tabla A502).
        SELECT FROM a502 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~kunnr, a~matnr, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl IN ( 'ZDES', 'ZDTF' )
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a502).

        SORT lt_a502 ASCENDING BY kschl knumh.

        "Secuencia Canal / Cliente / Jerarquía de productos (Tabla A515).
        SELECT FROM a515 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~kunnr, a~prodh, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl IN ( 'ZDES', 'ZDTF' )
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a515).

        SORT lt_a515 ASCENDING BY kschl knumh.

        "Secuencia Canal / Cliente / JP1 / JP2 (Tabla A509).
        SELECT FROM a509 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~kunnr, a~prodh1, a~prodh2, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl IN ( 'ZDES', 'ZDTF' )
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a509).

        SORT lt_a509 ASCENDING BY kschl knumh.

        "Secuencia Canal / Cliente / JP1 (Tabla A510).
        SELECT FROM a510 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~kunnr, a~prodh1, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl IN ( 'ZDES', 'ZDTF' )
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a510).

        SORT lt_a510 ASCENDING BY kschl knumh.

        "Secuencia Canal / Cadena / Material (Tabla A513).
        SELECT FROM a513 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~kvgr1, a~matnr, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl IN ( 'ZDES', 'ZDTF' )
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a513).

        SORT lt_a513 ASCENDING BY kschl knumh.

        "Secuencia Canal / Cadena / Jerarquía de productos (Tabla A516).
        SELECT FROM a516 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~kvgr1, a~prodh, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl IN ( 'ZDES', 'ZDTF' )
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a516).

        SORT lt_a516 ASCENDING BY kschl knumh.

        "Secuencia Canal / Cadena / JP1 / JP2 (Tabla A511).
        SELECT FROM a511 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~kvgr1, a~prodh1, a~prodh2, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl IN ( 'ZDES', 'ZDTF' )
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a511).

        SORT lt_a511 ASCENDING BY kschl knumh.

        "Secuencia Canal / Cadena / JP1 (Tabla A512).
        SELECT FROM a512 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~kvgr1, a~prodh1, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl IN ( 'ZDES', 'ZDTF' )
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a512).

        SORT lt_a512 ASCENDING BY kschl knumh.

        "Secuencia Canal / Gr.Precios / Material (Tabla A522).
        SELECT FROM a522 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~kvgr3, a~matnr, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl IN ( 'ZDES', 'ZDTF' )
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a522).

        SORT lt_a513 ASCENDING BY kschl knumh.

        "Secuencia Canal / Gr.Precios / Jerarquía de productos (Tabla A525).
        SELECT FROM a525 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~kvgr3, a~prodh, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl IN ( 'ZDES', 'ZDTF' )
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a525).

        SORT lt_a516 ASCENDING BY kschl knumh.

        "Secuencia Canal / Gr.Precios / JP1 / JP2 (Tabla A526).
        SELECT FROM a526 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~kvgr3, a~prodh1, a~prodh2, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl IN ( 'ZDES', 'ZDTF' )
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a526).

        SORT lt_a511 ASCENDING BY kschl knumh.

        "Secuencia Canal / Gr.Precios / JP1 (Tabla A527).
        SELECT FROM a527 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~kvgr3, a~prodh1, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl IN ( 'ZDES', 'ZDTF' )
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a527).

        SORT lt_a512 ASCENDING BY kschl knumh.

        "Secuencia Canal / Cliente (Tabla A505).
        SELECT FROM a505 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~kunnr, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl IN ( 'ZDES', 'ZDTF' )
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a505).

        SORT lt_a505 ASCENDING BY kschl knumh.

        "Secuencia Canal / Cadena (Tabla A514).
        SELECT FROM a514 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~kvgr1, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl IN ( 'ZDES', 'ZDTF' )
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a514).

        SORT lt_a514 ASCENDING BY kschl knumh.

        "Secuencia Canal / Gr.Precios (Tabla A528).
        SELECT FROM a528 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~kvgr3, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl IN ( 'ZDES', 'ZDTF' )
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a528).

        SORT lt_a514 ASCENDING BY kschl knumh.

        "Secuencia Canal / Jerarquía de productos (Tabla A517).
        SELECT FROM a517 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~prodh, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl IN ( 'ZDES', 'ZDTF' )
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a517).

        SORT lt_a517 ASCENDING BY kschl knumh.

        "Secuencia Canal / JP1 / JP2 (Tabla A518).
        SELECT FROM a518 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~prodh1, a~prodh2, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl IN ( 'ZDES', 'ZDTF' )
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a518).

        SORT lt_a518 ASCENDING BY kschl knumh.

        "Secuencia Canal / JP1 (Tabla A519).
        SELECT FROM a519 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~prodh1, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl IN ( 'ZDES', 'ZDTF' )
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a519).

        SORT lt_a519 ASCENDING BY kschl knumh.

        "Secuencia Canal / Material (Tabla A508).
        SELECT FROM a508 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~matnr, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl IN ( 'ZDES', 'ZDTF' )
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a508).

        SORT lt_a508 ASCENDING BY kschl knumh.

        "Armado de response para descuentos.
        LOOP AT lt_a502 ASSIGNING FIELD-SYMBOL(<fs_a502>).
          ls_descuentos-kschl = <fs_a502>-kschl.
          ls_descuentos-vtweg = <fs_a502>-vtweg.
          ls_descuentos-kunnr = |{ <fs_a502>-kunnr ALPHA = OUT }|.
          ls_descuentos-matnr = |{ <fs_a502>-matnr ALPHA = OUT }|.
          ls_descuentos-datab = <fs_a502>-datab.
          ls_descuentos-datbi = <fs_a502>-datbi.
          ls_descuentos-kbetr = <fs_a502>-kbetr / 10.
          ls_descuentos-konwa = <fs_a502>-konwa.
          ls_descuentos-kpein = <fs_a502>-kpein.
          ls_descuentos-kmein = <fs_a502>-kmein.
          ls_descuentos-orden = '1'.

          CONDENSE: ls_descuentos-kbetr, ls_descuentos-kpein.

          APPEND ls_descuentos TO et_entityset.
          CLEAR: ls_descuentos, <fs_a502>.
        ENDLOOP.
        UNASSIGN: <fs_a502>.

        LOOP AT lt_a515 ASSIGNING FIELD-SYMBOL(<fs_a515>).
          ls_descuentos-kschl = <fs_a515>-kschl.
          ls_descuentos-vtweg = <fs_a515>-vtweg.
          ls_descuentos-kunnr = |{ <fs_a515>-kunnr ALPHA = OUT }|.
          ls_descuentos-prodh = <fs_a515>-prodh.
          ls_descuentos-datab = <fs_a515>-datab.
          ls_descuentos-datbi = <fs_a515>-datbi.
          ls_descuentos-kbetr = <fs_a515>-kbetr / 10.
          ls_descuentos-konwa = <fs_a515>-konwa.
          ls_descuentos-kpein = <fs_a515>-kpein.
          ls_descuentos-kmein = <fs_a515>-kmein.
          ls_descuentos-orden = '2'.

          CONDENSE: ls_descuentos-kbetr, ls_descuentos-kpein.

          APPEND ls_descuentos TO et_entityset.
          CLEAR: ls_descuentos, <fs_a515>.
        ENDLOOP.
        UNASSIGN: <fs_a515>.

        LOOP AT lt_a509 ASSIGNING FIELD-SYMBOL(<fs_a509>).
          ls_descuentos-kschl = <fs_a509>-kschl.
          ls_descuentos-vtweg = <fs_a509>-vtweg.
          ls_descuentos-kunnr = |{ <fs_a509>-kunnr ALPHA = OUT }|.
          ls_descuentos-prodh1 = <fs_a509>-prodh1.
          ls_descuentos-prodh2 = <fs_a509>-prodh2.
          ls_descuentos-datab = <fs_a509>-datab.
          ls_descuentos-datbi = <fs_a509>-datbi.
          ls_descuentos-kbetr = <fs_a509>-kbetr / 10.
          ls_descuentos-konwa = <fs_a509>-konwa.
          ls_descuentos-kpein = <fs_a509>-kpein.
          ls_descuentos-kmein = <fs_a509>-kmein.
          ls_descuentos-orden = '3'.

          CONDENSE: ls_descuentos-kbetr, ls_descuentos-kpein.

          APPEND ls_descuentos TO et_entityset.
          CLEAR: ls_descuentos, <fs_a509>.
        ENDLOOP.
        UNASSIGN: <fs_a509>.

        LOOP AT lt_a510 ASSIGNING FIELD-SYMBOL(<fs_a510>).
          ls_descuentos-kschl = <fs_a510>-kschl.
          ls_descuentos-vtweg = <fs_a510>-vtweg.
          ls_descuentos-kunnr = |{ <fs_a510>-kunnr ALPHA = OUT }|.
          ls_descuentos-prodh1 = <fs_a510>-prodh1.
          ls_descuentos-datab = <fs_a510>-datab.
          ls_descuentos-datbi = <fs_a510>-datbi.
          ls_descuentos-kbetr = <fs_a510>-kbetr / 10.
          ls_descuentos-konwa = <fs_a510>-konwa.
          ls_descuentos-kpein = <fs_a510>-kpein.
          ls_descuentos-kmein = <fs_a510>-kmein.
          ls_descuentos-orden = '4'.

          CONDENSE: ls_descuentos-kbetr, ls_descuentos-kpein.

          APPEND ls_descuentos TO et_entityset.
          CLEAR: ls_descuentos, <fs_a510>.
        ENDLOOP.
        UNASSIGN: <fs_a510>.

        LOOP AT lt_a513 ASSIGNING FIELD-SYMBOL(<fs_a513>).
          ls_descuentos-kschl = <fs_a513>-kschl.
          ls_descuentos-vtweg = <fs_a513>-vtweg.
          ls_descuentos-kvgr1 = <fs_a513>-kvgr1.
          ls_descuentos-matnr = |{ <fs_a513>-matnr ALPHA = OUT }|.
          ls_descuentos-datab = <fs_a513>-datab.
          ls_descuentos-datbi = <fs_a513>-datbi.
          ls_descuentos-kbetr = <fs_a513>-kbetr / 10.
          ls_descuentos-konwa = <fs_a513>-konwa.
          ls_descuentos-kpein = <fs_a513>-kpein.
          ls_descuentos-kmein = <fs_a513>-kmein.
          ls_descuentos-orden = '5'.

          CONDENSE: ls_descuentos-kbetr, ls_descuentos-kpein.

          APPEND ls_descuentos TO et_entityset.
          CLEAR: ls_descuentos, <fs_a513>.
        ENDLOOP.
        UNASSIGN: <fs_a513>.

        LOOP AT lt_a516 ASSIGNING FIELD-SYMBOL(<fs_a516>).
          ls_descuentos-kschl = <fs_a516>-kschl.
          ls_descuentos-vtweg = <fs_a516>-vtweg.
          ls_descuentos-kvgr1 = <fs_a516>-kvgr1.
          ls_descuentos-prodh = <fs_a516>-prodh.
          ls_descuentos-datab = <fs_a516>-datab.
          ls_descuentos-datbi = <fs_a516>-datbi.
          ls_descuentos-kbetr = <fs_a516>-kbetr / 10.
          ls_descuentos-konwa = <fs_a516>-konwa.
          ls_descuentos-kpein = <fs_a516>-kpein.
          ls_descuentos-kmein = <fs_a516>-kmein.
          ls_descuentos-orden = '6'.

          CONDENSE: ls_descuentos-kbetr, ls_descuentos-kpein.

          APPEND ls_descuentos TO et_entityset.
          CLEAR: ls_descuentos, <fs_a516>.
        ENDLOOP.
        UNASSIGN: <fs_a516>.

        LOOP AT lt_a511 ASSIGNING FIELD-SYMBOL(<fs_a511>).
          ls_descuentos-kschl = <fs_a511>-kschl.
          ls_descuentos-vtweg = <fs_a511>-vtweg.
          ls_descuentos-kvgr1 = <fs_a511>-kvgr1.
          ls_descuentos-prodh1 = <fs_a511>-prodh1.
          ls_descuentos-prodh2 = <fs_a511>-prodh2.
          ls_descuentos-datab = <fs_a511>-datab.
          ls_descuentos-datbi = <fs_a511>-datbi.
          ls_descuentos-kbetr = <fs_a511>-kbetr / 10.
          ls_descuentos-konwa = <fs_a511>-konwa.
          ls_descuentos-kpein = <fs_a511>-kpein.
          ls_descuentos-kmein = <fs_a511>-kmein.
          ls_descuentos-orden = '7'.

          CONDENSE: ls_descuentos-kbetr, ls_descuentos-kpein.

          APPEND ls_descuentos TO et_entityset.
          CLEAR: ls_descuentos, <fs_a511>.
        ENDLOOP.
        UNASSIGN: <fs_a511>.

        LOOP AT lt_a512 ASSIGNING FIELD-SYMBOL(<fs_a512>).
          ls_descuentos-kschl = <fs_a512>-kschl.
          ls_descuentos-vtweg = <fs_a512>-vtweg.
          ls_descuentos-kvgr1 = <fs_a512>-kvgr1.
          ls_descuentos-prodh1 = <fs_a512>-prodh1.
          ls_descuentos-datab = <fs_a512>-datab.
          ls_descuentos-datbi = <fs_a512>-datbi.
          ls_descuentos-kbetr = <fs_a512>-kbetr / 10.
          ls_descuentos-konwa = <fs_a512>-konwa.
          ls_descuentos-kpein = <fs_a512>-kpein.
          ls_descuentos-kmein = <fs_a512>-kmein.
          ls_descuentos-orden = '8'.

          CONDENSE: ls_descuentos-kbetr, ls_descuentos-kpein.

          APPEND ls_descuentos TO et_entityset.
          CLEAR: ls_descuentos, <fs_a512>.
        ENDLOOP.
        UNASSIGN: <fs_a512>.

        LOOP AT lt_a522 ASSIGNING FIELD-SYMBOL(<fs_a522>).
          ls_descuentos-kschl = <fs_a522>-kschl.
          ls_descuentos-vtweg = <fs_a522>-vtweg.
          ls_descuentos-kvgr3 = <fs_a522>-kvgr3.
          ls_descuentos-matnr = |{ <fs_a522>-matnr ALPHA = OUT }|.
          ls_descuentos-datab = <fs_a522>-datab.
          ls_descuentos-datbi = <fs_a522>-datbi.
          ls_descuentos-kbetr = <fs_a522>-kbetr / 10.
          ls_descuentos-konwa = <fs_a522>-konwa.
          ls_descuentos-kpein = <fs_a522>-kpein.
          ls_descuentos-kmein = <fs_a522>-kmein.
          ls_descuentos-orden = '9'.

          CONDENSE: ls_descuentos-kbetr, ls_descuentos-kpein.

          APPEND ls_descuentos TO et_entityset.
          CLEAR: ls_descuentos, <fs_a522>.
        ENDLOOP.
        UNASSIGN: <fs_a522>.

        LOOP AT lt_a525 ASSIGNING FIELD-SYMBOL(<fs_a525>).
          ls_descuentos-kschl = <fs_a525>-kschl.
          ls_descuentos-vtweg = <fs_a525>-vtweg.
          ls_descuentos-kvgr3 = <fs_a525>-kvgr3.
          ls_descuentos-prodh = <fs_a525>-prodh.
          ls_descuentos-datab = <fs_a525>-datab.
          ls_descuentos-datbi = <fs_a525>-datbi.
          ls_descuentos-kbetr = <fs_a525>-kbetr / 10.
          ls_descuentos-konwa = <fs_a525>-konwa.
          ls_descuentos-kpein = <fs_a525>-kpein.
          ls_descuentos-kmein = <fs_a525>-kmein.
          ls_descuentos-orden = '10'.

          CONDENSE: ls_descuentos-kbetr, ls_descuentos-kpein.

          APPEND ls_descuentos TO et_entityset.
          CLEAR: ls_descuentos, <fs_a525>.
        ENDLOOP.
        UNASSIGN: <fs_a525>.

        LOOP AT lt_a526 ASSIGNING FIELD-SYMBOL(<fs_a526>).
          ls_descuentos-kschl = <fs_a526>-kschl.
          ls_descuentos-vtweg = <fs_a526>-vtweg.
          ls_descuentos-kvgr3 = <fs_a526>-kvgr3.
          ls_descuentos-prodh1 = <fs_a526>-prodh1.
          ls_descuentos-prodh2 = <fs_a526>-prodh2.
          ls_descuentos-datab = <fs_a526>-datab.
          ls_descuentos-datbi = <fs_a526>-datbi.
          ls_descuentos-kbetr = <fs_a526>-kbetr / 10.
          ls_descuentos-konwa = <fs_a526>-konwa.
          ls_descuentos-kpein = <fs_a526>-kpein.
          ls_descuentos-kmein = <fs_a526>-kmein.
          ls_descuentos-orden = '11'.

          CONDENSE: ls_descuentos-kbetr, ls_descuentos-kpein.

          APPEND ls_descuentos TO et_entityset.
          CLEAR: ls_descuentos, <fs_a526>.
        ENDLOOP.
        UNASSIGN: <fs_a526>.

        LOOP AT lt_a527 ASSIGNING FIELD-SYMBOL(<fs_a527>).
          ls_descuentos-kschl = <fs_a527>-kschl.
          ls_descuentos-vtweg = <fs_a527>-vtweg.
          ls_descuentos-kvgr3 = <fs_a527>-kvgr3.
          ls_descuentos-prodh1 = <fs_a527>-prodh1.
          ls_descuentos-datab = <fs_a527>-datab.
          ls_descuentos-datbi = <fs_a527>-datbi.
          ls_descuentos-kbetr = <fs_a527>-kbetr / 10.
          ls_descuentos-konwa = <fs_a527>-konwa.
          ls_descuentos-kpein = <fs_a527>-kpein.
          ls_descuentos-kmein = <fs_a527>-kmein.
          ls_descuentos-orden = '12'.

          CONDENSE: ls_descuentos-kbetr, ls_descuentos-kpein.

          APPEND ls_descuentos TO et_entityset.
          CLEAR: ls_descuentos, <fs_a527>.
        ENDLOOP.
        UNASSIGN: <fs_a527>.

        LOOP AT lt_a505 ASSIGNING FIELD-SYMBOL(<fs_a505>).
          ls_descuentos-kschl = <fs_a505>-kschl.
          ls_descuentos-vtweg = <fs_a505>-vtweg.
          ls_descuentos-kunnr = |{ <fs_a505>-kunnr ALPHA = OUT }|.
          ls_descuentos-datab = <fs_a505>-datab.
          ls_descuentos-datbi = <fs_a505>-datbi.
          ls_descuentos-kbetr = <fs_a505>-kbetr / 10.
          ls_descuentos-konwa = <fs_a505>-konwa.
          ls_descuentos-kpein = <fs_a505>-kpein.
          ls_descuentos-kmein = <fs_a505>-kmein.
          ls_descuentos-orden = '13'.

          CONDENSE: ls_descuentos-kbetr, ls_descuentos-kpein.

          APPEND ls_descuentos TO et_entityset.
          CLEAR: ls_descuentos, <fs_a505>.
        ENDLOOP.
        UNASSIGN: <fs_a505>.

        LOOP AT lt_a514 ASSIGNING FIELD-SYMBOL(<fs_a514>).
          ls_descuentos-kschl = <fs_a514>-kschl.
          ls_descuentos-vtweg = <fs_a514>-vtweg.
          ls_descuentos-kvgr1 = <fs_a514>-kvgr1.
          ls_descuentos-datab = <fs_a514>-datab.
          ls_descuentos-datbi = <fs_a514>-datbi.
          ls_descuentos-kbetr = <fs_a514>-kbetr / 10.
          ls_descuentos-konwa = <fs_a514>-konwa.
          ls_descuentos-kpein = <fs_a514>-kpein.
          ls_descuentos-kmein = <fs_a514>-kmein.
          ls_descuentos-orden = '14'.

          CONDENSE: ls_descuentos-kbetr, ls_descuentos-kpein.

          APPEND ls_descuentos TO et_entityset.
          CLEAR: ls_descuentos, <fs_a514>.
        ENDLOOP.
        UNASSIGN: <fs_a514>.

        LOOP AT lt_a528 ASSIGNING FIELD-SYMBOL(<fs_a528>).
          ls_descuentos-kschl = <fs_a528>-kschl.
          ls_descuentos-vtweg = <fs_a528>-vtweg.
          ls_descuentos-kvgr3 = <fs_a528>-kvgr3.
          ls_descuentos-datab = <fs_a528>-datab.
          ls_descuentos-datbi = <fs_a528>-datbi.
          ls_descuentos-kbetr = <fs_a528>-kbetr / 10.
          ls_descuentos-konwa = <fs_a528>-konwa.
          ls_descuentos-kpein = <fs_a528>-kpein.
          ls_descuentos-kmein = <fs_a528>-kmein.
          ls_descuentos-orden = '15'.

          CONDENSE: ls_descuentos-kbetr, ls_descuentos-kpein.

          APPEND ls_descuentos TO et_entityset.
          CLEAR: ls_descuentos, <fs_a528>.
        ENDLOOP.
        UNASSIGN: <fs_a528>.

        LOOP AT lt_a517 ASSIGNING FIELD-SYMBOL(<fs_a517>).
          ls_descuentos-kschl = <fs_a517>-kschl.
          ls_descuentos-vtweg = <fs_a517>-vtweg.
          ls_descuentos-prodh = <fs_a517>-prodh.
          ls_descuentos-datab = <fs_a517>-datab.
          ls_descuentos-datbi = <fs_a517>-datbi.
          ls_descuentos-kbetr = <fs_a517>-kbetr / 10.
          ls_descuentos-konwa = <fs_a517>-konwa.
          ls_descuentos-kpein = <fs_a517>-kpein.
          ls_descuentos-kmein = <fs_a517>-kmein.
          ls_descuentos-orden = '16'.

          CONDENSE: ls_descuentos-kbetr, ls_descuentos-kpein.

          APPEND ls_descuentos TO et_entityset.
          CLEAR: ls_descuentos, <fs_a517>.
        ENDLOOP.
        UNASSIGN: <fs_a517>.

        LOOP AT lt_a518 ASSIGNING FIELD-SYMBOL(<fs_a518>).
          ls_descuentos-kschl = <fs_a518>-kschl.
          ls_descuentos-vtweg = <fs_a518>-vtweg.
          ls_descuentos-prodh1 = <fs_a518>-prodh1.
          ls_descuentos-prodh2 = <fs_a518>-prodh2.
          ls_descuentos-datab = <fs_a518>-datab.
          ls_descuentos-datbi = <fs_a518>-datbi.
          ls_descuentos-kbetr = <fs_a518>-kbetr / 10.
          ls_descuentos-konwa = <fs_a518>-konwa.
          ls_descuentos-kpein = <fs_a518>-kpein.
          ls_descuentos-kmein = <fs_a518>-kmein.
          ls_descuentos-orden = '17'.

          CONDENSE: ls_descuentos-kbetr, ls_descuentos-kpein.

          APPEND ls_descuentos TO et_entityset.
          CLEAR: ls_descuentos, <fs_a518>.
        ENDLOOP.
        UNASSIGN: <fs_a518>.

        LOOP AT lt_a519 ASSIGNING FIELD-SYMBOL(<fs_a519>).
          ls_descuentos-kschl = <fs_a519>-kschl.
          ls_descuentos-vtweg = <fs_a519>-vtweg.
          ls_descuentos-prodh1 = <fs_a519>-prodh1.
          ls_descuentos-datab = <fs_a519>-datab.
          ls_descuentos-datbi = <fs_a519>-datbi.
          ls_descuentos-kbetr = <fs_a519>-kbetr / 10.
          ls_descuentos-konwa = <fs_a519>-konwa.
          ls_descuentos-kpein = <fs_a519>-kpein.
          ls_descuentos-kmein = <fs_a519>-kmein.
          ls_descuentos-orden = '18'.

          CONDENSE: ls_descuentos-kbetr, ls_descuentos-kpein.

          APPEND ls_descuentos TO et_entityset.
          CLEAR: ls_descuentos, <fs_a519>.
        ENDLOOP.
        UNASSIGN: <fs_a519>.

        LOOP AT lt_a508 ASSIGNING FIELD-SYMBOL(<fs_a508>).
          ls_descuentos-kschl = <fs_a508>-kschl.
          ls_descuentos-vtweg = <fs_a508>-vtweg.
          ls_descuentos-matnr = |{ <fs_a508>-matnr ALPHA = OUT }|.
          ls_descuentos-datab = <fs_a508>-datab.
          ls_descuentos-datbi = <fs_a508>-datbi.
          ls_descuentos-kbetr = <fs_a508>-kbetr / 10.
          ls_descuentos-konwa = <fs_a508>-konwa.
          ls_descuentos-kpein = <fs_a508>-kpein.
          ls_descuentos-kmein = <fs_a508>-kmein.
          ls_descuentos-orden = '19'.

          CONDENSE: ls_descuentos-kbetr, ls_descuentos-kpein.

          APPEND ls_descuentos TO et_entityset.
          CLEAR: ls_descuentos, <fs_a508>.
        ENDLOOP.
        UNASSIGN: <fs_a508>.
    ENDCASE.
  ENDMETHOD.


  method IMPUESTOSSET_GET_ENTITYSET.
    DATA: ls_impuestos TYPE zcl_zsd_catalogo_preci_mpc_ext=>ts_impuestos.

    CASE iv_entity_set_name.
      WHEN 'ImpuestosSet'.
        "Obtenemos registros de condición para impuestos (cl. cond. MWST).
        "Secuencia País / Cl. Fiscal cliente / Cl. Fiscal Material (Tabla A002).
        SELECT FROM A002 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~aland, a~taxk1, a~taxm1, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl EQ 'MWST'
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a002).

        "Armado de response para impuestos.
        LOOP AT lt_a002 ASSIGNING FIELD-SYMBOL(<fs_a002>).
          ls_impuestos-kschl = <fs_a002>-kschl.
          ls_impuestos-aland = <fs_a002>-aland.
          ls_impuestos-taxk1 = <fs_a002>-taxk1.
          ls_impuestos-taxm1 = <fs_a002>-taxm1.
          ls_impuestos-datab = <fs_a002>-datab.
          ls_impuestos-datbi = <fs_a002>-datbi.
          ls_impuestos-kbetr = <fs_a002>-kbetr / 10.
          ls_impuestos-konwa = <fs_a002>-konwa.
          ls_impuestos-kpein = <fs_a002>-kpein.
          ls_impuestos-kmein = <fs_a002>-kmein.
          ls_impuestos-orden = '1'.

          CONDENSE: ls_impuestos-kbetr, ls_impuestos-kpein.

          APPEND ls_impuestos TO et_entityset.
          CLEAR: ls_impuestos, <fs_a002>.
        ENDLOOP.
        UNASSIGN: <fs_a002>.
    ENDCASE.
  endmethod.


  method PRECIOSSET_GET_ENTITYSET.
    DATA: ls_precios TYPE zcl_zsd_catalogo_preci_mpc_ext=>ts_precios.

    CASE iv_entity_set_name.
      WHEN 'PreciosSet'.
        "Obtenemos registros de condición para precios (cl. cond. ZPR0).
        "Secuencia Canal / Cadena / Material (Tabla A513).
        SELECT FROM A513 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~kvgr1, a~matnr, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl EQ 'ZPR0'
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a513).

        "Secuencia Canal / Grupo de precios / Material (Tabla A522).
        SELECT FROM A522 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~kvgr3, a~matnr, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl EQ 'ZPR0'
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a522).

        "Armado de response para precios.
        LOOP AT lt_a513 ASSIGNING FIELD-SYMBOL(<fs_a513>).
          ls_precios-kschl = <fs_a513>-kschl.
          ls_precios-vtweg = <fs_a513>-vtweg.
          ls_precios-kvgr1 = <fs_a513>-kvgr1.
          ls_precios-matnr = |{ <fs_a513>-matnr ALPHA = OUT }|.
          ls_precios-datab = <fs_a513>-datab.
          ls_precios-datbi = <fs_a513>-datbi.
          ls_precios-kbetr = <fs_a513>-kbetr.
          ls_precios-konwa = <fs_a513>-konwa.
          ls_precios-kpein = <fs_a513>-kpein.
          ls_precios-kmein = <fs_a513>-kmein.
          ls_precios-orden = '1'.

          CONDENSE: ls_precios-kbetr, ls_precios-kpein.

          APPEND ls_precios TO et_entityset.
          CLEAR: ls_precios, <fs_a513>.
        ENDLOOP.
        UNASSIGN: <fs_a513>.

        LOOP AT lt_a522 ASSIGNING FIELD-SYMBOL(<fs_a522>).
          ls_precios-kschl = <fs_a522>-kschl.
          ls_precios-vtweg = <fs_a522>-vtweg.
          ls_precios-kvgr3 = <fs_a522>-kvgr3.
          ls_precios-matnr = |{ <fs_a522>-matnr ALPHA = OUT }|.
          ls_precios-datab = <fs_a522>-datab.
          ls_precios-datbi = <fs_a522>-datbi.
          ls_precios-kbetr = <fs_a522>-kbetr.
          ls_precios-konwa = <fs_a522>-konwa.
          ls_precios-kpein = <fs_a522>-kpein.
          ls_precios-kmein = <fs_a522>-kmein.
          ls_precios-orden = '2'.

          CONDENSE: ls_precios-kbetr, ls_precios-kpein.

          APPEND ls_precios TO et_entityset.
          CLEAR: ls_precios, <fs_a522>.
        ENDLOOP.
        UNASSIGN: <fs_a522>.
    ENDCASE.
  endmethod.


  method PROMOCIONESSET_GET_ENTITYSET.
    DATA: ls_promos TYPE zcl_zsd_catalogo_preci_mpc_ext=>ts_promociones.

    CASE iv_entity_set_name.
      WHEN 'PromocionesSet'.
        "Obtenemos registros de condición para promociones (cl. cond. ZDKA).
        "Secuencia Canal / Ref. cliente / Material (Tabla A523).
        SELECT FROM A523 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~zzbstkd, a~matnr, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl EQ 'ZDKA'
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a523).

        "Secuencia Canal / Ref. pedido / Material (Tabla A524).
        SELECT FROM A524 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~zzihrez, a~matnr, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl EQ 'ZDKA'
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a524).

        "Secuencia Canal / Ref. cliente (Tabla A521).
        SELECT FROM A521 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~zzbstkd, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl EQ 'ZDKA'
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a521).

        "Secuencia Canal / Ref. pedido (Tabla A520).
        SELECT FROM A520 AS a
          INNER JOIN konp AS k ON k~knumh EQ a~knumh
          FIELDS a~kschl, a~vtweg, a~zzihrez, a~datab, a~datbi, a~knumh, k~kbetr, k~konwa, k~kpein, k~kmein
          WHERE a~kschl EQ 'ZDKA'
          AND a~datab LT @sy-datum
          AND a~datbi GT @sy-datum
          AND a~kfrst EQ ''
          AND k~loevm_ko EQ ''
          INTO TABLE @DATA(lt_a520).

        LOOP AT lt_a523 ASSIGNING FIELD-SYMBOL(<fs_a523>).
          ls_promos-kschl   = <fs_a523>-kschl.
          ls_promos-vtweg   = <fs_a523>-vtweg.
          ls_promos-zzbstkd = <fs_a523>-zzbstkd.
          ls_promos-matnr   = |{ <fs_a523>-matnr ALPHA = OUT }|.
          ls_promos-datab   = <fs_a523>-datab.
          ls_promos-datbi   = <fs_a523>-datbi.
          ls_promos-kbetr   = <fs_a523>-kbetr / 10.
          ls_promos-konwa   = <fs_a523>-konwa.
          ls_promos-kpein   = <fs_a523>-kpein.
          ls_promos-kmein   = <fs_a523>-kmein.
          ls_promos-orden   = '1'.

          CONDENSE: ls_promos-kbetr, ls_promos-kpein.

          APPEND ls_promos TO et_entityset.
          CLEAR: ls_promos, <fs_a523>.
        ENDLOOP.

        LOOP AT lt_a524 ASSIGNING FIELD-SYMBOL(<fs_a524>).
          ls_promos-kschl   = <fs_a524>-kschl.
          ls_promos-vtweg   = <fs_a524>-vtweg.
          ls_promos-zzihrez = <fs_a524>-zzihrez.
          ls_promos-matnr   = |{ <fs_a524>-matnr ALPHA = OUT }|.
          ls_promos-datab   = <fs_a524>-datab.
          ls_promos-datbi   = <fs_a524>-datbi.
          ls_promos-kbetr   = <fs_a524>-kbetr / 10.
          ls_promos-konwa   = <fs_a524>-konwa.
          ls_promos-kpein   = <fs_a524>-kpein.
          ls_promos-kmein   = <fs_a524>-kmein.
          ls_promos-orden   = '2'.

          CONDENSE: ls_promos-kbetr, ls_promos-kpein.

          APPEND ls_promos TO et_entityset.
          CLEAR: ls_promos, <fs_a524>.
        ENDLOOP.

        LOOP AT lt_a521 ASSIGNING FIELD-SYMBOL(<fs_a521>).
          ls_promos-kschl   = <fs_a521>-kschl.
          ls_promos-vtweg   = <fs_a521>-vtweg.
          ls_promos-zzbstkd = <fs_a521>-zzbstkd.
          ls_promos-datab   = <fs_a521>-datab.
          ls_promos-datbi   = <fs_a521>-datbi.
          ls_promos-kbetr   = <fs_a521>-kbetr / 10.
          ls_promos-konwa   = <fs_a521>-konwa.
          ls_promos-kpein   = <fs_a521>-kpein.
          ls_promos-kmein   = <fs_a521>-kmein.
          ls_promos-orden   = '3'.

          CONDENSE: ls_promos-kbetr, ls_promos-kpein.

          APPEND ls_promos TO et_entityset.
          CLEAR: ls_promos, <fs_a521>.
        ENDLOOP.

        LOOP AT lt_a520 ASSIGNING FIELD-SYMBOL(<fs_a520>).
          ls_promos-kschl   = <fs_a520>-kschl.
          ls_promos-vtweg   = <fs_a520>-vtweg.
          ls_promos-zzihrez = <fs_a520>-zzihrez.
          ls_promos-datab   = <fs_a520>-datab.
          ls_promos-datbi   = <fs_a520>-datbi.
          ls_promos-kbetr   = <fs_a520>-kbetr / 10.
          ls_promos-konwa   = <fs_a520>-konwa.
          ls_promos-kpein   = <fs_a520>-kpein.
          ls_promos-kmein   = <fs_a520>-kmein.
          ls_promos-orden   = '4'.

          CONDENSE: ls_promos-kbetr, ls_promos-kpein.

          APPEND ls_promos TO et_entityset.
          CLEAR: ls_promos, <fs_a520>.
        ENDLOOP.

    ENDCASE.
  endmethod.
ENDCLASS.
