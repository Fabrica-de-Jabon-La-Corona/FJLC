
* set textnames for header, adress and footer
PERFORM GET_TEXTNAME USING    IS_DLV_DELNOTE
                     CHANGING GF_TXNAM_ADR
                              GF_TXNAM_KOP
                              GF_TXNAM_FUS
                              GF_TXNAM_GRU
                              GF_TXNAM_SDB
                              GF_TXNAM_ALA.

* object text name header
GF_TDNAME = IS_DLV_DELNOTE-HD_GEN-DELIV_NUMB.

* get customer adress number
READ TABLE IS_DLV_DELNOTE-HD_ADR INTO GS_HD_ADR
           WITH KEY DELIV_NUMB   = IS_DLV_DELNOTE-HD_GEN-DELIV_NUMB
                    OUTPUT_PARTN = 'X'.
IF SY-SUBRC NE 0.
   READ TABLE IS_DLV_DELNOTE-HD_ADR INTO GS_HD_ADR
              WITH KEY DELIV_NUMB = IS_DLV_DELNOTE-HD_GEN-DELIV_NUMB
                       PARTN_ROLE = 'WE'.
   IF SY-SUBRC NE 0.
      CLEAR GS_HD_ADR.
   ENDIF.
ENDIF.









