"Name: \PR:SAPMV45A\EX:MV45AI0V_VBAK-VBELN_ERM\EI
ENHANCEMENT 0 ZSD_SAPMV45A.

DATA: lv_vkgrp TYPE vbak-vkgrp.

SELECT SINGLE vkgrp INTO lv_vkgrp
  FROM vbak
  WHERE vbeln EQ vbak-vbeln.

CASE sy-tcode.
  WHEN 'VA02'.
    AUTHORITY-CHECK OBJECT 'ZSD_VKGRP'
      ID 'VKGRP' FIELD lv_vkgrp
      ID 'ACTVT' FIELD '02'.

    IF sy-subrc NE 0.
      MESSAGE e008(zsd) WITH lv_vkgrp.
    ENDIF.
  WHEN 'VA03'.
    AUTHORITY-CHECK OBJECT 'ZSD_VKGRP'
      ID 'VKGRP' FIELD lv_vkgrp
      ID 'ACTVT' FIELD '03'.

    IF sy-subrc NE 0.
      MESSAGE e009(zsd) WITH lv_vkgrp.
    ENDIF.
ENDCASE.

ENDENHANCEMENT.
