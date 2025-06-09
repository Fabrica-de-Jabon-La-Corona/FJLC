*&---------------------------------------------------------------------*
*& Include          ZTM_FEVIAJES_ALV_TOP
*&---------------------------------------------------------------------*
TABLES: vbkd, vbak, vbap, kna1, vbpa, likp, vbrk, /scmtms/d_torrot.

TYPE-POOLS solis.

TYPES: BEGIN OF gty_viajes,
         bstkd  TYPE vbkd-bstkd,              "Pedido de cliente
         kunnr  TYPE vbak-kunnr,              "Cliente
         namso  TYPE kna1-name1,              "Nombre de cliente
         kunwe  TYPE vbpa-kunnr,              "Destinatario de mercancía
         namwe  TYPE kna1-name1,              "Nombre del destinatario de mercancía
         vkgrp  TYPE vbak-vkgrp,              "Grupo de vendedores (agente/broker)
         route  TYPE vbap-route,              "Ruta
         werks  TYPE vbap-werks,              "Centro
         lgort  TYPE vbap-lgort,              "Almacén
         bezei  TYPE tvgrt-bezei,             "Nombre del agente/broker
         vbelp  TYPE vbak-vbeln,              "Pedido
         erdat  TYPE vbak-erdat,              "Creado el
         gbstk  TYPE vbak-gbstk,              "Estado global del pedido
         diasc  TYPE i,                       "Días de antiguedad del pedido (fecha actual menos fecha de creación)
         kwmeng TYPE vbap-kwmeng,             "Cantidad pedida
         brgew  TYPE vbap-brgew,              "Peso bruto pedido
         ntgew  TYPE vbap-ntgew,              "Peso neto pedido
         volum  TYPE vbap-volum,              "Volumen Pedido
         vbele  TYPE likp-vbeln,              "Entrega
         toruf  TYPE /scmtms/d_torrot-tor_id, "Unidad de Flete
         vbelf  TYPE vbrk-vbeln,              "Factura
         torid  TYPE /scmtms/d_torrot-tor_id, "Orden de Flete
         condu  TYPE string,                  "Nombre Chofer
         vdatu  TYPE vbak-vdatu,              "Fecha preferente de entrega
         dates  TYPE c LENGTH 10,             "Fecha real de salida del CEDIS
         datec  TYPE c LENGTH 10,             "Fecha real de cruce de aduana
         datee  TYPE c LENGTH 10,             "Fecha real de entrega a cliente
         dateci TYPE c LENGTH 19,             "Fecha y hora de Check In
         dateco TYPE c LENGTH 19,             "Fecha y hora de Check Out
         street TYPE adrc-street,             "Calle
         housen TYPE adrc-house_num1,         "Número
         city2  TYPE adrc-city2,              "Distrito
         city   TYPE adrc-city1,              "Población
         postl  TYPE adrc-post_code1,         "Código postal
         reion  TYPE t005u-bezei,             "Región
         land   TYPE t005t-landx,             "País
         xpos   TYPE /sapapo/loc-xpos,        "Longitud
         ypos   TYPE /sapapo/loc-ypos,        "Latitud
         pgps   TYPE icon-id,                 "ícono Punto GPS.
         trana  TYPE kna1-name1,              "Transportista nacional
         traex  TYPE kna1-name1,              "Transportista extranjero
         aduna  TYPE kna1-name1,              "Aduana nacional
         aduex  TYPE kna1-name1,              "Aduana extranjera
         inco   TYPE knvv-inco1,              "Incoterm
         front  TYPE knvv-inco2_l,            "Lugar de Incoterm
         cita   TYPE c LENGTH 1,              "Indicador de Cita
         observ TYPE string,                  "Observaciones o Instrucciones especiales
         stgen  TYPE likp-gbstk,              "Status Global Entrega
         stfen  TYPE likp-fkstk,              "Status Factura relacionada a entrega
         stare  TYPE likp-pdstk,              "Status POD a nivel cabecera de entrega
         stsme  TYPE likp-wbstk,              "Status salida de mercancía de entrega
         uuid   TYPE zsd_cfdi_return-uuid,    "Folio fiscal de factura
         error  TYPE zsd_cfdi_return-mensaje, "Error de timbrado
       END OF gty_viajes.

DATA: gs_layout   TYPE slis_layout_alv,
      lt_viajes   TYPE TABLE OF gty_viajes,
      gs_viajes   TYPE gty_viajes,
      gt_viajes   TYPE TABLE OF gty_viajes,
      gt_fieldcat TYPE slis_t_fieldcat_alv.

CONSTANTS: abap_true  TYPE c LENGTH 1 VALUE 'X',
           abap_false TYPE c LENGTH 1 VALUE ''.
