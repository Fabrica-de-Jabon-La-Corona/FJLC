CLASS lcl_ztm_enh_modify_fu_data DEFINITION DEFERRED.
CLASS /scmtms/cl_ui_viewexit_pln_new DEFINITION LOCAL FRIENDS lcl_ztm_enh_modify_fu_data.
CLASS lcl_ztm_enh_modify_fu_data DEFINITION.
  PUBLIC SECTION.
    CLASS-DATA obj TYPE REF TO lcl_ztm_enh_modify_fu_data.  "#EC NEEDED
    DATA core_object TYPE REF TO /scmtms/cl_ui_viewexit_pln_new . "#EC NEEDED
 INTERFACES  IPO_ZTM_ENH_MODIFY_FU_DATA.
    METHODS:
      constructor IMPORTING core_object
                              TYPE REF TO /scmtms/cl_ui_viewexit_pln_new OPTIONAL.
ENDCLASS.
CLASS lcl_ztm_enh_modify_fu_data IMPLEMENTATION.
  METHOD constructor.
    me->core_object = core_object.
  ENDMETHOD.

  METHOD ipo_ztm_enh_modify_fu_data~_modify_fu_data.
*"------------------------------------------------------------------------*
*" Declaration of POST-method, do not insert any comments here please!
*"
*"methods _MODIFY_FU_DATA
*"  changing
*"    !ET_CHANGED_TBO_TORFU_KEY type /BOBF/T_FRW_KEY
*"    !CT_DATA type ANY TABLE
*"    !CV_DATA_CHANGED type BOOLE_D.
*"------------------------------------------------------------------------*
"Se llena el campo ZZROUTE para mostrar en las etapas de unidad de flete (Transportation Cockpit).
    FIELD-SYMBOLS: <ls_fu_data> TYPE /scmtms/s_ui_pln_fu_shp.

    DATA: lv_entrega TYPE likp-vbeln,
          lt_fu_data TYPE STANDARD TABLE OF /scmtms/s_ui_pln_fu_shp.

    LOOP AT ct_data ASSIGNING <ls_fu_data>.
      lv_entrega = <ls_fu_data>-base_btd_id_dlv_tr+25(10).

      SELECT SINGLE route INTO @<ls_fu_data>-zzroute
        FROM likp
        WHERE vbeln EQ @lv_entrega.

      APPEND <ls_fu_data> TO lt_fu_data.
    ENDLOOP.

    IF ct_data <> lt_fu_data.
      cv_data_changed = abap_true.
      ct_data         = lt_fu_data.
    ENDIF.

  ENDMETHOD.
ENDCLASS.
