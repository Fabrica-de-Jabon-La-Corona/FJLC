*&---------------------------------------------------------------------*
*& Report  ZDS_LIST_BO_DBS
*&
*&---------------------------------------------------------------------*
*& Determine DB tables of Business Object with archiving object.
*&---------------------------------------------------------------------*

REPORT  zds_list_arcbo_dbs.
DATA:
  lv_bo_name     TYPE /scmtms/bo_name,
  lt_bo          TYPE STANDARD TABLE OF /bobf/obm_obj,
  lo_conf        TYPE REF TO /bobf/if_frw_configuration,
  lt_node        TYPE /bobf/t_confro_node,
  lt_table       TYPE STANDARD TABLE OF tabname.

FIELD-SYMBOLS:
  <ls_bo>        TYPE /bobf/obm_obj,
  <ls_node>      TYPE /bobf/s_confro_node,
  <table>        TYPE tabname.

SELECT-OPTIONS:
  so_bo FOR lv_bo_name.


START-OF-SELECTION.
  SELECT bo~bo_key bo~name
    FROM /bobf/obm_obj AS bo
         INNER JOIN /bofu/i_obm_arch AS arc ON bo~name = arc~bo_name
    INTO CORRESPONDING FIELDS OF TABLE lt_bo
    WHERE bo~name         IN so_bo AND
          arc~arch_object NE space.
  IF sy-subrc NE 0.
*   No Business Object found
    WRITE:/'No business object found'.
    EXIT.
  ENDIF.
  SORT lt_bo BY name.
  DELETE ADJACENT DUPLICATES FROM lt_bo COMPARING name.

  LOOP AT lt_bo ASSIGNING <ls_bo>.
    "Ignore some specific BOs
    CHECK <ls_bo>-name NE /scmtms/if_bp_c=>sc_bo_name
      AND <ls_bo>-name NE /bofu/if_ppf_output_content_c=>sc_bo_name
      AND <ls_bo>-name NP '*DEMO*'
      AND <ls_bo>-name NP '*TEST*'.

    "Init
    lo_conf = /bobf/cl_frw_factory=>get_configuration( iv_bo_key = <ls_bo>-bo_key ).
    WRITE:/ 'Database tables of business object', (*) <ls_bo>-name, ':'.
    lo_conf->get_node_tab( IMPORTING et_node = lt_node ).

    "Collect DB Tables
    LOOP AT lt_node
      USING KEY key2
      ASSIGNING <ls_node>.
      CASE <ls_node>-ref_bo_key.
        WHEN /bofu/if_change_document_c=>sc_bo_key.
          APPEND 'CDHDR' TO lt_table.
          APPEND 'CDPOS' TO lt_table.
          APPEND 'CDPOS_UID' TO lt_table.
          APPEND 'CDPOS_STR' TO lt_table.
        WHEN /bofu/if_ppf_output_content_c=>sc_bo_key.
          APPEND '/BOFU/DPPFCNTR' TO lt_table.
          APPEND 'PPFTTRIGG' TO lt_table.
          APPEND 'PPFTALMRU' TO lt_table.
          APPEND 'BCST_PPFMD' TO lt_table.
          APPEND 'PPFTMETHRU' TO lt_table.
          APPEND 'PPFTPARTNR' TO lt_table.
          APPEND '/BOFU/DPPFEXT_C' TO lt_table.
        WHEN /bofu/if_addr_constants=>sc_bo_key.
          APPEND 'ADR10' TO lt_table.
          APPEND 'ADR11' TO lt_table.
          APPEND 'ADR12' TO lt_table.
          APPEND 'ADR13' TO lt_table.
          APPEND 'ADR2' TO lt_table.
          APPEND 'ADR3' TO lt_table.
          APPEND 'ADR4' TO lt_table.
          APPEND 'ADR5' TO lt_table.
          APPEND 'ADR6' TO lt_table.
          APPEND 'ADR7' TO lt_table.
          APPEND 'ADR8' TO lt_table.
          APPEND 'ADR9' TO lt_table.
          APPEND 'ADRCOMC' TO lt_table.
          APPEND 'ADRCT' TO lt_table.
          APPEND 'ADRG' TO lt_table.
          APPEND 'ADRGP' TO lt_table.
          APPEND 'ADRT' TO lt_table.
          APPEND 'ADRU' TO lt_table.
          APPEND 'ADRV' TO lt_table.
          APPEND 'ADRVP' TO lt_table.
      ENDCASE.
      CHECK <ls_node>-database_table IS NOT INITIAL.
      APPEND <ls_node>-database_table TO lt_table.
    ENDLOOP.

    "List db tables
    SORT lt_table.
    DELETE ADJACENT DUPLICATES FROM lt_table.
    LOOP AT lt_table ASSIGNING <table>.
      WRITE:/ <table>.
    ENDLOOP.
    ULINE.
    CLEAR lt_table.
  ENDLOOP.
