



DATA: LS_SERNR LIKE RISERLS.
DATA: BEGIN OF LT_SERNR OCCURS 5.
        INCLUDE STRUCTURE RISERLS.
DATA: END   OF LT_SERNR.

REFRESH GT_SERNR_PRT.

LOOP AT IS_DLV_DELNOTE-IT_SERNR INTO GS_IT_SERNR
                                WHERE DELIV_NUMB = GS_IT_GEN-DELIV_NUMB
                                  AND ITM_NUMBER = GS_IT_GEN-ITM_NUMBER.
  CLEAR LS_SERNR.
  LS_SERNR-VBELN = GS_IT_SERNR-DELIV_NUMB.
  LS_SERNR-POSNR = GS_IT_SERNR-ITM_NUMBER.
  LS_SERNR-SERNR = GS_IT_SERNR-SERIAL_NUM.
  APPEND LS_SERNR TO LT_SERNR.
ENDLOOP.

* Process the stringtable for Printing.
CALL FUNCTION 'PROCESS_SERIALS_FOR_PRINT'
     EXPORTING
          I_BOUNDARY_LEFT             = '(_'
          I_BOUNDARY_RIGHT            = '_)'
          I_SEP_CHAR_STRINGS          = ',_'
          I_SEP_CHAR_INTERVAL         = '_-_'
          I_USE_INTERVAL              = 'X'
          I_BOUNDARY_METHOD           = 'C'
          I_LINE_LENGTH               = 50
          I_NO_ZERO                   = 'X'
          I_ALPHABET                  = SY-ABCDE
          I_DIGITS                    = '0123456789'
          I_SPECIAL_CHARS             = '-'
          I_WITH_SECOND_DIGIT         = ' '
     TABLES
          SERIALS                     = LT_SERNR
          SERIALS_PRINT               = GT_SERNR_PRT
     EXCEPTIONS
          BOUNDARY_MISSING            = 01
          INTERVAL_SEPARATION_MISSING = 02
          LENGTH_TO_SMALL             = 03
          INTERNAL_ERROR              = 04
          WRONG_METHOD                = 05
          WRONG_SERIAL                = 06
          TWO_EQUAL_SERIALS           = 07
          SERIAL_WITH_WRONG_CHAR      = 08
          SERIAL_SEPARATION_MISSING   = 09.





