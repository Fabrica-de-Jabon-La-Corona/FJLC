
CLEAR GS_IT_REF.
CLEAR GS_IT_REFORD.
CLEAR GS_IT_REFPURORD.

IF NOT IS_DLV_DELNOTE-IT_REFORD[] IS INITIAL.
* read order data
 IF IS_DLV_DELNOTE-HD_REF-ORDER_NUMB IS INITIAL.
* multiple order numbers exist
  READ TABLE IS_DLV_DELNOTE-IT_REFORD INTO GS_IT_REFORD
             WITH KEY DELIV_NUMB = GS_IT_GEN-DELIV_NUMB
                      ITM_NUMBER = GS_IT_GEN-ITM_NUMBER BINARY SEARCH.
  IF SY-SUBRC NE 0.
    CLEAR GS_IT_REFORD.
  ENDIF.
 ENDIF.
ELSEIF NOT IS_DLV_DELNOTE-IT_REF[] IS INITIAL.
* read stock transfer data
    IF IS_DLV_DELNOTE-HD_REF-REF_DOC IS INITIAL.
*      multiple stock transfer orders
       READ TABLE IS_DLV_DELNOTE-IT_REF INTO GS_IT_REF
              WITH KEY DELIV_NUMB = GS_IT_GEN-DELIV_NUMB
                       ITM_NUMBER = GS_IT_GEN-ITM_NUMBER BINARY SEARCH.
       IF SY-SUBRC NE 0.
          CLEAR GS_IT_REF.
       ENDIF.
    ENDIF.
ENDIF.

* read purchase order data
READ TABLE IS_DLV_DELNOTE-IT_REFPURORD INTO GS_IT_REFPURORD
           WITH KEY DELIV_NUMB = GS_IT_GEN-DELIV_NUMB
                    ITM_NUMBER = GS_IT_GEN-ITM_NUMBER BINARY SEARCH.
IF SY-SUBRC = 0.
  IF ( GS_IT_REFPURORD-PO_ITM_NO IS INITIAL ) AND
     ( NOT IS_DLV_DELNOTE-HD_REF-PURCH_NO_C IS INITIAL ).
*      po item number is initial
*      po number is written on delivery header level (unique)
*      -> no additional reference info, clear po cust number
       CLEAR GS_IT_REFPURORD-PURCH_NO_C.
   ENDIF.
  IF ( GS_IT_REFPURORD-PO_ITM_NO_S IS INITIAL ) AND
     ( NOT IS_DLV_DELNOTE-HD_REF-PURCH_NO_S IS INITIAL ).
*      po item number is initial
*      po number is written on delivery header level (unique)
*      -> no additional reference info, clear po ship to number
       CLEAR GS_IT_REFPURORD-PURCH_NO_S.
   ENDIF.
ENDIF.




