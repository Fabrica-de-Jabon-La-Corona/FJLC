*&---------------------------------------------------------------------*
*& Report ZMC_CHANGE_DEVC
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZMC_CHANGE_DEVC.

DATA gv_proj_ident       TYPE dmc_pident.
DATA gv_user             TYPE responsibl.
DATA gv_proj_id          TYPE dmc_project_guid.
DATA gt_dynpfields       TYPE TABLE OF dynpread.
DATA gs_dynpfields       TYPE dynpread.
DATA gt_tadir            TYPE TABLE OF tadir.
DATA gv_failed           TYPE abap_bool.
DATA gv_question         TYPE string.
DATA gv_answer           TYPE c.
DATA gv_string           TYPE string.



*&---------------------------------------------------------------------*
*& SELECTION-SCREEN
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK bl1 WITH FRAME TITLE titbl1.
  PARAMETERS p_proj       TYPE dmc_pdescr.
  PARAMETERS p_ident      TYPE char20 MODIF ID dis.
SELECTION-SCREEN END OF BLOCK bl1.
SELECTION-SCREEN BEGIN OF BLOCK bl4 WITH FRAME TITLE titbl4.
  PARAMETERS p_devc       TYPE devclass MODIF ID dev.
SELECTION-SCREEN END OF BLOCK bl4.


AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN 'DIS'.
        screen-input = 0.
        MODIFY SCREEN.
      WHEN 'DEV'.
        screen-required = 2. "recommended
        MODIFY SCREEN.
      WHEN OTHERS.
        "do nothing
    ENDCASE.

    CASE screen-name.
      WHEN 'P_IDENT'.
        PERFORM get_ident_name USING    p_proj
                               CHANGING p_ident.
      WHEN OTHERS.
        "do nothing
    ENDCASE.
  ENDLOOP.

  IF p_ident IS NOT INITIAL.
    CLEAR gt_dynpfields.
    CLEAR gs_dynpfields.
    gs_dynpfields-fieldname  = 'P_IDENT'.
    gs_dynpfields-fieldvalue = p_ident.
    APPEND gs_dynpfields TO gt_dynpfields.

    CALL FUNCTION 'DYNP_VALUES_UPDATE'
      EXPORTING
        dyname               = sy-cprog
        dynumb               = '1000'
      TABLES
        dynpfields           = gt_dynpfields
      EXCEPTIONS
        invalid_abapworkarea = 1
        invalid_dynprofield  = 2
        invalid_dynproname   = 3
        invalid_dynpronummer = 4
        invalid_request      = 5
        no_fielddescription  = 6
        undefind_error       = 7
        OTHERS               = 8.
    IF sy-subrc <> 0.  "#EC EMPTY_IF_BRANCH
      "do nothing
    ENDIF.
  ENDIF.

INITIALIZATION.
  titbl1 = 'Project Selection'.
  titbl4 = 'Package to be Assigned'.

**********************
* START-OF-SELECTION *
**********************
START-OF-SELECTION.
  PERFORM check USING p_devc
                CHANGING gv_failed.
  IF gv_failed EQ abap_true.
    RETURN.
  ENDIF.

  CONCATENATE 'Are you sure you want to assign development package'(002) p_devc 'to migration project'(003) p_proj '?'
    INTO gv_question SEPARATED BY space.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar       = 'Change Package Assignment'(t01)
      text_question  = gv_question
      default_button = '2'
    IMPORTING
      answer         = gv_answer
    EXCEPTIONS
      text_not_found = 1
      OTHERS         = 2.
  IF sy-subrc <> 0 OR gv_answer <> '1'.
    MESSAGE 'Processing cancelled by user'(005) TYPE 'S'.
    RETURN.
  ENDIF.


  PERFORM get_ident_name USING    p_proj
                         CHANGING p_ident.

  PERFORM get_objects USING gv_proj_id
                      CHANGING gt_tadir.

  PERFORM change_objects USING p_devc.





*&---------------------------------------------------------------------*
*&      Form  CHECK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM check
          USING iv_devc
          CHANGING cv_failed. "#EC CI_FORM
  DATA lv_dev_exists       TYPE abap_bool.
  DATA lv_editable         TYPE abap_bool.

  cv_failed = abap_false.

  cl_dmc_authority=>check_change(
  EXCEPTIONS
    no_authority = 1
    OTHERS       = 2
    ).

  IF sy-subrc <> 0.
    MESSAGE 'You are not authorized to run this report'(004) TYPE 'S' DISPLAY LIKE 'E' ##NO_TEXT.
    cv_failed = abap_true.
    RETURN.
  ENDIF.

  IF /ltb/cl_ext_cls_factory=>get_cos_utilities( )->is_cloud( ) = abap_true.
    MESSAGE 'It is not possible to run this report in SAP S/4HANA Cloud systems'(007) TYPE 'S' DISPLAY LIKE 'E' ##NO_TEXT.
    cv_failed = abap_true.
    RETURN.
  ENDIF.

  IF iv_devc IS INITIAL.
    MESSAGE 'No development package specified; please specify a development package'(001) TYPE 'S' DISPLAY LIKE 'E'.
    cv_failed = abap_true.
    RETURN.
  ENDIF.

  /ltb/cl_bas_utils=>is_devc_existing_and_editable( EXPORTING iv_devc     = iv_devc
                                                    IMPORTING ev_existing = lv_dev_exists
                                                              ev_editable = lv_editable ).
  IF lv_dev_exists EQ abap_false.
    CLEAR gv_string.
    CONCATENATE 'Development package' iv_devc  'does not exist; please specify a different package'
      INTO gv_string SEPARATED BY space.
    MESSAGE gv_string TYPE 'I' DISPLAY LIKE 'E'.
    cv_failed = abap_true.
    RETURN.
  ENDIF.

  IF lv_editable EQ abap_false.
    CLEAR gv_string.
    CONCATENATE 'Development package' iv_devc  'is not editable'
      INTO gv_string SEPARATED BY space.
    MESSAGE gv_string TYPE 'I' DISPLAY LIKE 'E'.
    cv_failed = abap_true.
    RETURN.
  ENDIF.

ENDFORM.                    " CHECK

*&---------------------------------------------------------------------*
*&      Form  GET_IDENT_NAME
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_ident_name
  USING    iv_proj_descr
  CHANGING cv_ident_name.  "#EC CI_FORM

  CLEAR cv_ident_name.

  CHECK iv_proj_descr IS NOT INITIAL.  "#EC CHECK_POSITION

  SELECT SINGLE p~ident,p~author,p~guid FROM dmc_prjctt AS t
    LEFT OUTER JOIN dmc_prjct AS p ON p~guid = t~guid
    WHERE t~descr = @iv_proj_descr
    INTO  (@gv_proj_ident,@gv_user,@gv_proj_id) .
  IF sy-subrc EQ 0.
    cv_ident_name = gv_proj_ident.
  ELSE.
    CLEAR gv_string.
    CONCATENATE 'Migration project' iv_proj_descr  'does not exist; please specify a different project'
      INTO gv_string SEPARATED BY space.
    MESSAGE gv_string TYPE 'I' DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.                    " GET_IDENT_NAME

*&---------------------------------------------------------------------*
*&      Form  GET_OBJECTS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_objects USING iv_proj_id
                 CHANGING ct_tadir TYPE table.  "#EC CI_FORM
  DATA lt_sprj_range    TYPE RANGE OF dmc_sident.
  DATA lt_sprj          TYPE TABLE OF tadir.

  SELECT * FROM tadir
    WHERE object = 'PROJ' AND obj_name = @gv_proj_ident AND author = @gv_user
    INTO TABLE @ct_tadir. "#EC CI_GENBUFF.

  SELECT guid AS sprj_id, ident AS sprj_ident
    FROM dmc_sprjct INTO TABLE @DATA(lt_sub_projects)
      WHERE project = @iv_proj_id.

  CHECK lt_sub_projects IS NOT INITIAL.  "#EC CHECK_POSITION

  lt_sprj_range = VALUE #( FOR <sub_proj> IN lt_sub_projects
                 (
                    sign = 'I'
                    option = 'EQ'
                    low = <sub_proj>-sprj_ident
                 )
  ).
  SORT lt_sprj_range BY low.
  DELETE ADJACENT DUPLICATES FROM lt_sprj_range COMPARING low.

  SELECT * FROM tadir INTO TABLE @lt_sprj WHERE object = 'SPRJ' AND obj_name IN @lt_sprj_range. "#EC CI_GENBUFF.
  IF sy-subrc EQ 0.
    APPEND LINES OF lt_sprj TO ct_tadir.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  CHANGE_OBJECTS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM change_objects USING iv_devclass. "#EC CI_FORM
  DATA ls_tadir         TYPE tadir.

  LOOP AT gt_tadir INTO ls_tadir.
    CALL FUNCTION 'TR_TADIR_INTERFACE'
      EXPORTING
        wi_test_modus                  = abap_false
        wi_tadir_pgmid                 = ls_tadir-pgmid
        wi_tadir_object                = ls_tadir-object
        wi_tadir_obj_name              = ls_tadir-obj_name
        wi_tadir_devclass              = iv_devclass
      EXCEPTIONS
        tadir_entry_not_existing       = 1
        tadir_entry_ill_type           = 2
        no_systemname                  = 3
        no_systemtype                  = 4
        original_system_conflict       = 5
        object_reserved_for_devclass   = 6
        object_exists_global           = 7
        object_exists_local            = 8
        object_is_distributed          = 9
        obj_specification_not_unique   = 10
        no_authorization_to_delete     = 11
        devclass_not_existing          = 12
        simultanious_set_remove_repair = 13
        order_missing                  = 14
        no_modification_of_head_syst   = 15
        pgmid_object_not_allowed       = 16
        masterlanguage_not_specified   = 17
        devclass_not_specified         = 18
        specify_owner_unique           = 19
        loc_priv_objs_no_repair        = 20
        gtadir_not_reached             = 21
        object_locked_for_order        = 22
        change_of_class_not_allowed    = 23
        no_change_from_sap_to_tmp      = 24
        OTHERS                         = 25.
    IF sy-subrc NE 0.
      CLEAR gv_string.
      CONCATENATE 'Unable to assign development package' iv_devclass  'to migration project' p_proj
        INTO gv_string SEPARATED BY space.
      MESSAGE gv_string TYPE 'E'.
    ENDIF.
  ENDLOOP.

  CLEAR gv_string.
  CONCATENATE 'Development package' iv_devclass  'has been assigned to migration project' p_proj
    INTO gv_string SEPARATED BY space.
  MESSAGE gv_string TYPE 'S'.
ENDFORM.
