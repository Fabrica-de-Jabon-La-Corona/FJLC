


* check for existing batches
*READ TABLE
*           IS_DLV_DELNOTE-IT_GEN INTO GS_IT_GEN_BATCH
*                          WITH KEY DELIV_NUMB = GS_IT_GEN-DELIV_NUMB
*                                        UECHA = GS_IT_GEN-ITM_NUMBER.
*IF SY-SUBRC NE 0.
  CLEAR GS_IT_GEN_BATCH.
*ENDIF.










*









