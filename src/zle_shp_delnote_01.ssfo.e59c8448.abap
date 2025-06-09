


* check for existing configurations.
READ TABLE
           IS_DLV_DELNOTE-IT_CONFITM INTO GS_IT_GEN_CONF
                          WITH KEY DELIV_NUMB = GS_IT_GEN-DELIV_NUMB
                                   ITM_NUMBER = GS_IT_GEN-ITM_NUMBER.
IF SY-SUBRC NE 0.
  CLEAR GS_IT_GEN_CONF.
ENDIF.










*










