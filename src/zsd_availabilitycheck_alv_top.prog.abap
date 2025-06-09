*&---------------------------------------------------------------------*
*& Include          ZSD_AVAILABILITYCHECK_ALV_TOP
*&---------------------------------------------------------------------*
TABLES: mvke, makt, mard, t001w, t001l, mchb.

TYPE-POOLS solis.

TYPES: BEGIN OF gty_dispo,
         matnr TYPE mvke-matnr,                         "Material
         maktx TYPE makt-maktx,                         "Descripción Material
         werks TYPE mard-werks,                         "Centro
         name1 TYPE t001w-name1,                        "Descripción Centro
         lgort TYPE mard-lgort,                         "Almacén
         lgobe TYPE t001l-lgobe,                        "Descripción Almacén
         charg TYPE mchb-charg,                         "Lote
         comer TYPE c LENGTH 1,                         "Comercialización
         comed TYPE string,                             "Descripción Comercialización
         qtumb TYPE mchb-clabs,                         "Cantidad en Unidad de medida base
         umb   TYPE meins,                              "Unidad de medida base
         qtumv TYPE mchb-clabs,                         "Cantidad en Unidad de medida de venta
         umv   TYPE vrkme,                              "Unidad de medida de venta
       END OF gty_dispo.

DATA: gs_layout    TYPE slis_layout_alv,
      gs_dispo     TYPE gty_dispo,
      gt_dispo     TYPE TABLE OF gty_dispo,
      gt_fieldcat  TYPE slis_t_fieldcat_alv,
      gt_windowcat TYPE slis_layout_alv_spec1.

CONSTANTS: abap_true  TYPE c LENGTH 1 VALUE 'X',
           abap_false TYPE c LENGTH 1 VALUE ''.
