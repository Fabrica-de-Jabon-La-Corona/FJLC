*----------------------------------------------------------------------*
***INCLUDE LZTM_PERMISOSCTF01.
*----------------------------------------------------------------------*
FORM entry_zpermisosct.

  SELECT SINGLE rt~text FROM /sapapo/res_txt AS rt
    INNER JOIN /sapapo/res_head AS rh ON rh~resuid = rt~resuid
    INTO ztm_permisosct-text
    WHERE rh~name = ztm_permisosct-name.

  ztm_permisosct-changeuser = sy-uname.
  ztm_permisosct-changedate = sy-datum.
  ztm_permisosct-changehour = sy-uzeit.
ENDFORM.

FORM modify_zpermisosct.

  FIELD-SYMBOLS <fs_field> TYPE any.

  LOOP AT total.
    CHECK <action> EQ aendern.

    ASSIGN COMPONENT 'CHANGEUSER' OF STRUCTURE <vim_total_struc> TO <fs_field>.
    IF <fs_field> IS ASSIGNED.
      <fs_field> = sy-uname.
      UNASSIGN <fs_field>.
    ENDIF.

    ASSIGN COMPONENT 'CHANGEDATE' OF STRUCTURE <vim_total_struc> TO <fs_field>.
    IF <fs_field> IS ASSIGNED.
      <fs_field> = sy-datum.
      UNASSIGN <fs_field>.
    ENDIF.

    ASSIGN COMPONENT 'CHANGEHOUR' OF STRUCTURE <vim_total_struc> TO <fs_field>.
    IF <fs_field> IS ASSIGNED.
      <fs_field> = sy-uzeit.
      UNASSIGN <fs_field>.
    ENDIF.

    READ TABLE extract WITH KEY <vim_xtotal_key>.
    IF sy-subrc EQ 0.
      extract = total.
      MODIFY extract INDEX sy-tabix.
    ENDIF.

    IF total IS NOT INITIAL.
      MODIFY total.
    ENDIF.
  ENDLOOP.

ENDFORM.
