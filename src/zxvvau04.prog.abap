*&---------------------------------------------------------------------*
*& Include          ZXVVAU04
*&---------------------------------------------------------------------*
CASE sy-tcode.
  WHEN 'VA01'.
    AUTHORITY-CHECK OBJECT 'ZSD_VKGRP'
       ID 'VKGRP' FIELD i_vkgrp
       ID 'ACTVT' FIELD '01'.

    IF sy-subrc NE 0.
      MESSAGE e007(zsd) WITH i_vkgrp.
    ENDIF.
ENDCASE.
