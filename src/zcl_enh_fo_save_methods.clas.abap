class ZCL_ENH_FO_SAVE_METHODS definition
  public
  final
  create public .

public section.

  interfaces /BOBF/IF_FRW_DETERMINATION .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ENH_FO_SAVE_METHODS IMPLEMENTATION.


  METHOD /bobf/if_frw_determination~execute.
    DATA: lo_request    TYPE REF TO /sctm/cl_request,
          lt_failed_key TYPE /bobf/t_frw_key,
          lt_key        TYPE /bobf/t_frw_key,
          lo_message    TYPE REF TO /bobf/if_frw_message,
          lt_root       TYPE /scmtms/t_tor_root_k,
          lt_item       TYPE /scmtms/t_tor_item_tr_k,
          lt_link       TYPE /bobf/t_frw_key_link,
          lt_item_key   TYPE /bobf/t_frw_key.

    FIELD-SYMBOLS: <ls_key>      TYPE /bobf/s_frw_key,
                   <ls_root>     TYPE /scmtms/s_tor_root_k,
                   <ls_item>     TYPE /scmtms/s_tor_item_tr_k,
                   <ls_item_rem> TYPE /scmtms/s_tor_item_tr_k.

**********************************************************************
*    obtiene cabecera de la orden de flete (ROOT)
**********************************************************************

    CALL METHOD io_read->retrieve
      EXPORTING
        it_key     = it_key
        iv_node    = is_ctx-node_key
      IMPORTING
        eo_message = lo_message
        et_data    = lt_root.

**********************************************************************
*    obtiene posiciones de la orden de flete
**********************************************************************

    CALL METHOD io_read->retrieve_by_association "lo_tor_save_request->mo_tor_srvmgr->retrieve_by_association
      EXPORTING
        it_key         = it_key
        iv_node        = is_ctx-node_key "/scmtms/if_tor_c=>sc_node-root
        iv_association = /scmtms/if_tor_c=>sc_association-root-item_tr
        iv_fill_data   = abap_true
        "iv_edit_mode   = /bobf/if_conf_c=>sc_edit_read_only
      IMPORTING
        eo_message     = lo_message
        et_data        = lt_item
        et_key_link    = lt_link
        et_target_key  = lt_item_key
        et_failed_key  = lt_failed_key.

**********************************************************************
*    se valida si existen posiciones tipo "TRL" (Remolques)
*    si existen, se debe validar que la mercancía esté dentro de ellos
**********************************************************************
    LOOP AT lt_item ASSIGNING <ls_item> WHERE item_type EQ 'TRL'.
      DATA: lv_count TYPE i.
      lv_count = lv_count + 1.  "Cuenta el número de remolques.
    ENDLOOP.
    UNASSIGN <ls_item>.

    IF line_exists( lt_item[ item_type = 'TRL' ] ) AND lv_count GT 1.  "Si existe mas de 1 remolque en la orden de flete se validará que la mercancía esté asignada a los remolques.
      LOOP AT lt_item ASSIGNING <ls_item> WHERE item_type EQ 'PRD' AND main_cargo_item EQ 'X'.
        DATA(lv_material) = <ls_item>-product_id.
        READ TABLE lt_item ASSIGNING <ls_item_rem> WITH KEY key = <ls_item>-item_parent_key item_type = 'TRL'.
        IF sy-subrc NE 0.
          DATA: lv_temp TYPE string.
          CLEAR: lt_failed_key.
          MESSAGE e000(ztm) INTO lv_temp.

          CALL METHOD /scmtms/cl_common_helper=>msg_helper_add_symsg
            EXPORTING
              iv_key       = /scmtms/if_tor_c=>sc_bo_key
              iv_node_key  = /scmtms/if_tor_c=>sc_node-root
              iv_detlevel  = /scmtms/cl_applog_helper=>sc_al_detlev_default
              iv_probclass = /scmtms/cl_applog_helper=>sc_al_probclass_add_info
              iv_subobject = /scmtms/cl_applog_helper=>sc_al_sobj_chaco
            CHANGING
              co_message   = eo_message.

          LOOP AT it_key ASSIGNING <ls_key>.
            APPEND <ls_key> TO et_failed_key.
          ENDLOOP.
          UNASSIGN <ls_key>.

          RETURN.
        ENDIF.
      ENDLOOP.
      UNASSIGN <ls_item>.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
