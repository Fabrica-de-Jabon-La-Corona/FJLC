*&---------------------------------------------------------------------*
*& Include          ZXUSRU01
*&---------------------------------------------------------------------*
*   Variables para validacion de permiso externo Raul Ivan Ramirez Rossano, Abril 2024
    DATA: lv_RV_USER  TYPE SY-UNAME, "
          ip_address  TYPE string, "
          fext TYPE string, "
          T_PCNAME  TYPE string, "
          ADDRSTR TYPE NI_NODEADDR,
          pext  TYPE string.
*   Fin de variables personalizadas


*   Validaciones para sesion externa Raul Ivan Ramirez Rossano, Abril 2024
*   Obtenemos usuario
    lv_RV_USER = sy-uname.

*   Obtenemos la ip del cliente

    CALL FUNCTION 'TH_USER_INFO'
    EXPORTING
    CLIENT                    = SY-MANDT
    USER                      = lv_RV_USER
*       CHECK_GUI                 = 0
    IMPORTING
*       HOSTADDR                  =
    TERMINAL                  = T_PCNAME
*       ACT_SESSIONS              =
*       MAX_SESSIONS              =
*       MY_SESSION                =
*       MY_INTERNAL_SESSION       =
*       TASK_STATE                =
*       UPDATE_REC_EXIST          =
*       TID                       =
*       GUI_CHECK_FAILED          =
    ADDRSTR                   = ADDRSTR
*       RC                        =
.

    ip_address = ADDRSTR.
    IF ( ip_address EQ '172.16.2.107').
     SELECT SINGLE PARVA FROM usr05 INTO pext where PARID = 'ZREMOTE_ACCESS_GUI' and BNAME = lv_RV_USER.
      IF pext NE '1'.
        CALL 'SYST_LOGOFF'.
      ELSE.
        SELECT SINGLE PARVA FROM usr05 INTO fext where PARID = 'ZREMOTE_ACCESS_DATE' and BNAME = lv_RV_USER.
        IF sy-datum GT fext.
            CALL 'SYST_LOGOFF'.
        ENDIF.
      ENDIF.
    ELSE.
    ENDIF.

****Fin validaciones pasa sesion externa
