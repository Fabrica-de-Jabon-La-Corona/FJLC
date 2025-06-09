*&---------------------------------------------------------------------*
*& Include          ZSD_MASSINFORECORD_TOP
*&---------------------------------------------------------------------*
TABLES: knmt, knmta.

TYPE-POOLS solis.

TYPES: BEGIN OF gty_inforecord,
         vkorg    TYPE knmt-vkorg,              "Sales Organization
         vtweg    TYPE knmt-vtweg,              "Distribution Channel
         kunnr    TYPE knmt-kunnr,              "Sold to Party
         matnr    TYPE c LENGTH 18,             "SAP Material
         maktx    TYPE makt-maktx,              "SAP Description
         kdmat    TYPE knmt-kdmat,              "Customer Material
         postx    TYPE knmt-postx,              "Customer Description
         kdmat2   TYPE knmta-kdmat,             "Casing Material
         addpostx TYPE knmta-addpostx,          "Centro
         status   TYPE string,                  "Status of inforecord (new or modify)
       END OF gty_inforecord.

DATA: gs_layout     TYPE slis_layout_alv,
      lt_inforecord TYPE TABLE OF gty_inforecord,
      gs_inforecord TYPE gty_inforecord,
      gt_inforecord TYPE TABLE OF gty_inforecord,
      gt_fieldcat   TYPE slis_t_fieldcat_alv,
      gt_infopaso   TYPE TABLE OF gty_inforecord,
      gv_paso       TYPE c LENGTH 1,
      gt_rows       TYPE salv_t_row,
      lo_selections TYPE REF TO cl_salv_selections.        "ALV column properties and selections.

CONSTANTS: abap_true  TYPE c LENGTH 1 VALUE 'X',
           abap_false TYPE c LENGTH 1 VALUE '',
           gv_casedes TYPE c LENGTH 7 VALUE 'Carcasa'.
