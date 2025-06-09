class ZMB_MIGO_BADI definition
  public
  final
  create public .

public section.

  interfaces IF_BADI_INTERFACE .
  interfaces IF_EX_MB_MIGO_BADI .
protected section.
private section.
ENDCLASS.



CLASS ZMB_MIGO_BADI IMPLEMENTATION.


  method IF_EX_MB_MIGO_BADI~CHECK_HEADER.
  endmethod.


  method IF_EX_MB_MIGO_BADI~CHECK_ITEM.
  endmethod.


  method IF_EX_MB_MIGO_BADI~HOLD_DATA_DELETE.
  endmethod.


  method IF_EX_MB_MIGO_BADI~HOLD_DATA_LOAD.
  endmethod.


  method IF_EX_MB_MIGO_BADI~HOLD_DATA_SAVE.
  endmethod.


  method IF_EX_MB_MIGO_BADI~INIT.
  endmethod.


  method IF_EX_MB_MIGO_BADI~LINE_DELETE.
  endmethod.


  METHOD if_ex_mb_migo_badi~line_modify.
    "Ini. Validación de estatus de POD de entrega saliente antes de hacer traspaso de stock en tránsito a almacén. - CAOG - 19.03.2025 - S4DK910512
    DATA: lv_message TYPE string,
          lv_matnr   TYPE matnr.

    IF cs_goitem-bwart EQ '411' AND cs_goitem-sobkz EQ 'T'.
      SELECT vbeln, posnr, pstyv, matnr, arktx, gbsta, pdsta, fksta, wbsta, vgbel, vgpos, werks, lgort FROM lips
        WHERE vbeln EQ @cs_goitem-vlief_avis
        INTO TABLE @DATA(lt_lips).

      READ TABLE lt_lips ASSIGNING FIELD-SYMBOL(<fs_lips>) WITH KEY vbeln = cs_goitem-vlief_avis posnr = cs_goitem-vbelp_avis matnr = cs_goitem-matnr.

      IF <fs_lips> IS ASSIGNED.
        lv_matnr = |{ <fs_lips>-matnr ALPHA = OUT }|.
        CASE <fs_lips>-pdsta.
          WHEN 'A'.
            CONCATENATE 'El material' lv_matnr '-' <fs_lips>-arktx 'no cuenta con POD.' INTO lv_message SEPARATED BY space.
            CONDENSE lv_message.
            MESSAGE lv_message TYPE 'E' DISPLAY LIKE 'E'.
          WHEN 'B'.
            CONCATENATE 'No se ha confirmado el POD para el material' lv_matnr '-' <fs_lips>-arktx INTO lv_message SEPARATED BY space.
            CONDENSE lv_message.
            MESSAGE lv_message TYPE 'E' DISPLAY LIKE 'E'.
          WHEN 'C'.
            CONCATENATE 'El material' lv_matnr '-' <fs_lips>-arktx 'cuenta con POD confirmado' INTO lv_message SEPARATED BY space.
            CONDENSE lv_message.
            MESSAGE lv_message TYPE 'S' DISPLAY LIKE 'S'.
          WHEN ''.
        ENDCASE.
      ENDIF.
    ENDIF.
    "Fin. Validación de estatus de POD de entrega saliente antes de hacer traspaso de stock en tránsito a almacén. - CAOG - 19.03.2025 - S4DK910512
  ENDMETHOD.


  method IF_EX_MB_MIGO_BADI~MAA_LINE_ID_ADJUST.
  endmethod.


  method IF_EX_MB_MIGO_BADI~MODE_SET.
  endmethod.


  method IF_EX_MB_MIGO_BADI~PAI_DETAIL.
  endmethod.


  method IF_EX_MB_MIGO_BADI~PAI_HEADER.
  endmethod.


  method IF_EX_MB_MIGO_BADI~PBO_DETAIL.
  endmethod.


  method IF_EX_MB_MIGO_BADI~PBO_HEADER.
  endmethod.


  METHOD if_ex_mb_migo_badi~post_document.
*INI - CAOG - Validación para no contabilizar cantidades mayores a la de la entrega que se está recibiendo.
    TYPES:
      BEGIN OF ty_collect_mseg,
        vbeln_im TYPE mseg-vbeln_im,
        matnr    TYPE mseg-matnr,
        erfmg    TYPE mseg-erfmg,
      END OF ty_collect_mseg.

    TYPES:
      BEGIN OF ty_collect_lips,
        vbeln TYPE lips-vbeln,
        matnr TYPE lips-matnr,
        arktx TYPE lips-arktx,
        lfimg TYPE lips-lfimg,
      END OF ty_collect_lips.

    DATA: it_collect_mseg TYPE TABLE OF ty_collect_mseg,
          it_collect_lips TYPE TABLE OF ty_collect_lips,
          ls_collect_mseg TYPE ty_collect_mseg,
          ls_collect_lips TYPE ty_collect_lips,
          lv_message      TYPE string.

    READ TABLE it_mseg ASSIGNING FIELD-SYMBOL(<fs_mseg>) INDEX 1.

    SELECT SINGLE bsart INTO @DATA(lv_bsart)
      FROM ekko
      WHERE ebeln EQ @<fs_mseg>-ebeln.

    IF lv_bsart EQ 'ZUB' AND <fs_mseg>-bwart EQ '101'. "Se valida que el documento origen sea un traslado de tipo ZUB.
      SELECT vbeln, posnr, pstyv, matnr, lfimg, vrkme, lgmng, arktx, gbsta, pdsta, fksta, wbsta, vgbel, vgpos, werks, lgort FROM lips
        WHERE vbeln EQ @<fs_mseg>-vbeln_im
        INTO TABLE @DATA(lt_lips).

      UNASSIGN <fs_mseg>.

      LOOP AT it_mseg ASSIGNING <fs_mseg>.
        CLEAR: ls_collect_mseg.
        MOVE-CORRESPONDING <fs_mseg> TO ls_collect_mseg.
        COLLECT ls_collect_mseg INTO it_collect_mseg.
      ENDLOOP.
      UNASSIGN: <fs_mseg>.

      LOOP AT lt_lips ASSIGNING FIELD-SYMBOL(<fs_lips>).
        CLEAR: ls_collect_lips.
        MOVE-CORRESPONDING <fs_lips> TO ls_collect_lips.
        COLLECT ls_collect_lips INTO it_collect_lips.
      ENDLOOP.
      UNASSIGN: <fs_lips>.

      LOOP AT it_collect_mseg ASSIGNING FIELD-SYMBOL(<fs_collect_mseg>).
        READ TABLE it_collect_lips ASSIGNING FIELD-SYMBOL(<fs_collect_lips>) WITH KEY matnr = <fs_collect_mseg>-matnr.
        IF <fs_collect_lips> IS ASSIGNED.
          DATA(lv_matnr) = |{ <fs_collect_lips>-matnr ALPHA = OUT }|.
          IF <fs_collect_mseg>-erfmg GT <fs_collect_lips>-lfimg.
            CONCATENATE 'La cantidad de entrada para el material' lv_matnr '-' <fs_collect_lips>-arktx 'es mayor que la cantidad de la entrega.' INTO lv_message SEPARATED BY space.
            CONDENSE lv_message.
            MESSAGE lv_message TYPE 'E' DISPLAY LIKE 'E'.
          ENDIF.
          UNASSIGN: <fs_collect_lips>.
        ENDIF.
      ENDLOOP.
      UNASSIGN: <fs_collect_mseg>.
    ENDIF.
*FIN - CAOG - Validación para no contabilizar cantidades mayores a la de la entrega que se está recibiendo.
  ENDMETHOD.


  method IF_EX_MB_MIGO_BADI~PROPOSE_SERIALNUMBERS.
  endmethod.


  method IF_EX_MB_MIGO_BADI~PUBLISH_MATERIAL_ITEM.
  endmethod.


  method IF_EX_MB_MIGO_BADI~RESET.
  endmethod.


  method IF_EX_MB_MIGO_BADI~STATUS_AND_HEADER.
  endmethod.
ENDCLASS.
