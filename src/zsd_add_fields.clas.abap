class ZSD_ADD_FIELDS definition
  public
  final
  create public .

public section.

  interfaces IF_BADI_INTERFACE .
  interfaces IF_BADI_SDOC_WRAPPER .
protected section.
private section.
ENDCLASS.



CLASS ZSD_ADD_FIELDS IMPLEMENTATION.


  method IF_BADI_SDOC_WRAPPER~ADAPT_RESULT_COMP.
*  En los informes optimizados, las siguientes tablas de base de datos ya están seleccionadas por defecto:
*
*ADRC ("Direcciones (gestión central de direcciones)")
*VBAK ("Documento de ventas: Datos de cabecera")
*VBAP ("Documento de ventas: Datos de posición")
*VEDA ("Datos de contrato")
*VBKD ("Documento de ventas: Datos comerciales")
*VBPA ("Documento de ventas: Socio")
*VBEP ("Documento de ventas: Datos de reparto")
*Ver SAP NOTE: 1780163 - Optimización de informes: Acceso a otras tablas Para campos adicionales o para incluir botones nuevos para nueva funcionalidad.

*Visualizar campos adicionales tabla VBAP. (Posición
    "Norma de Embalaje.
    INSERT VALUE #( table = 'VBAP'
                    field = 'MVGR4'
                    name  = 'VBAP_MVGR4' ) INTO TABLE ct_result_comp.

    "Ruta
    INSERT VALUE #( table = 'VBAP'
                    field = 'ROUTE'
                    name  = 'VBAP_ROUTE' ) INTO TABLE ct_result_comp.

*Visualizar campos adicionales tabla VBEP. (Reparto)
    "Fecha de Carga
    INSERT VALUE #( table = 'VBEP'
                    field = 'LDDAT'
                    name  = 'VBEP_LDDAT' ) INTO TABLE ct_result_comp.
  endmethod.


  method IF_BADI_SDOC_WRAPPER~POST_PROCESSING.
  endmethod.
ENDCLASS.
