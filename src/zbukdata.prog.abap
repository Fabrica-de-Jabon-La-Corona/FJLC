TABLES: VBUK, *VBUK.
TABLES: KVBUK.                          "Statusfelder Kredit
DATA: CON_CMGST_FREIGABE VALUE 'D'.     "
DATA: BEGIN OF VBUKKEY,
        MANDT LIKE VBUK-MANDT,
        VBELN LIKE VBUK-VBELN,
      END OF VBUKKEY.

DATA:    BEGIN OF COMMON PART VBUKCOM.
* Alter Tabellenstand beim Ändern

DATA:    BEGIN OF YVBUK OCCURS 0.
           INCLUDE STRUCTURE VBUKVB.
DATA:    END OF YVBUK.

* Aktueller Tabellenstand

DATA:    BEGIN OF XVBUK OCCURS 2.
           INCLUDE STRUCTURE VBUKVB.
DATA:    END OF XVBUK.

DATA:    SVBUK_TABIX LIKE SY-TABIX,
         SVBUK_SUBRC LIKE SY-SUBRC.

DATA: VBUK_FREIGABE.            "Kreditfreigabemodus
DATA: VBUK_RECHECK.             "Kreditrecheck
DATA: VBUK_KREDIT_VFP.          "Verfügbarkeitsprüfung bei VKM1 ?
DATA: VBUK_KEIN_KREDITCHECK.    "kein Kreditrecheck
DATA: VBUK_KREDIT_NEUAUFBAU.    "Neuaufbau Kredit

* C5024641 Teil-WE
* Fileds for partial goods receipt
data: PARTIAL_GR_KZ type BORGR_PGR_KZ.

DATA: UPD_VBUK.                 "Für Änderungsbelege

* offene Werte in Vertriebsbelegen
DATA: BEGIN OF open_values OCCURS 0.
       INCLUDE STRUCTURE BEZS132.
DATA: END   OF open_values.

DATA: BEGIN OF wk_open_values OCCURS 0.
       INCLUDE STRUCTURE BEZS135.
DATA: END   OF wk_open_values.

DATA:    END OF COMMON PART VBUKCOM.
*eject
