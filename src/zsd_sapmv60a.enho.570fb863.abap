"Name: \PR:SAPMV60A\FO:VBRK_BEARBEITEN\SE:BEGIN\EI
ENHANCEMENT 0 ZSD_SAPMV60A.
DATA: lv_message TYPE string,
      lv_flag    TYPE c LENGTH 1.

IF sy-tcode EQ 'VF03'.
  IF sy-ucomm EQ 'BACK' AND sy-dynnr EQ '0101'.
    LEAVE SCREEN.
  ENDIF.

  IF vbrk-vbeln NE ''.
    DATA: lv_pedido TYPE vbak-vbeln,
          lv_vkgrp  TYPE vbak-vkgrp.

    SELECT SINGLE aubel INTO lv_pedido
      FROM vbrp
      WHERE vbeln EQ vbrk-vbeln.

    IF sy-subrc EQ 0.
      SELECT SINGLE vkgrp INTO lv_vkgrp
        FROM vbak
        WHERE vbeln EQ lv_pedido.

      AUTHORITY-CHECK OBJECT 'ZSD_VKGRP'
      ID 'VKGRP' FIELD lv_vkgrp
      ID 'ACTVT' FIELD '03'.

      IF sy-subrc NE 0.

        MOVE 'X' TO lv_flag.

        CONCATENATE 'Sin autorización para ver facturas del agente/broker: ' lv_vkgrp INTO lv_message SEPARATED BY space.
        "LEAVE SCREEN.
        "MESSAGE e006(zsd) WITH 'Sin autorización para ver facturas del agente/broker: ' lv_vkgrp.
        MESSAGE lv_message TYPE 'E'.
        "STOP.
      ENDIF.
    ENDIF.
  ENDIF.
ENDIF.
ENDENHANCEMENT.
