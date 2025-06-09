"Name: \PR:SD_SALES_DOCUMENT_VIEW\EX:SD_SALES_DOCUMENT_VIEW_EP_EXT2\EI
ENHANCEMENT 0 ZSD_EHC_VA05_AUTHORIZ_VKGRP.

DATA: lv_message TYPE string,
      lt_vkgrp   TYPE TABLE OF vkgrp.

SELECT * FROM usr05
  WHERE bname EQ @sy-uname
  AND parid EQ 'ZSD_VKGRP'
  INTO TABLE @DATA(lt_param).

IF sy-subrc EQ 0.
  READ TABLE lt_param ASSIGNING FIELD-SYMBOL(<fs_param>) INDEX 1.
  SPLIT <fs_param>-parva AT ',' INTO TABLE lt_vkgrp.

  IF lt_vkgrp[] IS NOT INITIAL.
    SORT lt_vkgrp ASCENDING.
    DELETE ADJACENT DUPLICATES FROM lt_vkgrp.
  ENDIF.
ENDIF.

IF line_exists( lt_vkgrp[ table_line = '*' ] ).
  DATA(lv_allgrp) = 'X'.
ENDIF.

IF gs_selcrit-vkgrp[] IS NOT INITIAL.
  IF lv_allgrp NE 'X'.
    DATA(lt_selgrp) = gs_selcrit-vkgrp[].

    LOOP AT lt_selgrp ASSIGNING FIELD-SYMBOL(<fs_selgrp>).
      READ TABLE lt_vkgrp ASSIGNING FIELD-SYMBOL(<fs_vkgrp>) WITH KEY table_line = <fs_selgrp>-low.

      IF <fs_vkgrp> IS NOT ASSIGNED.
        MESSAGE e003(zsd) WITH <fs_selgrp>-low.
      ENDIF.
    ENDLOOP.
  ENDIF.
ELSE.
 IF lv_allgrp EQ ''.
   MESSAGE 'Favor de indicar un número de agente (grupo de ventas)' TYPE 'E' DISPLAY LIKE 'E'.
 ELSE.
 ENDIF.
ENDIF.
ENDENHANCEMENT.
