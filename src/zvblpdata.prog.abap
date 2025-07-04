*-----------------------------------------------------------------------
*        Datenbank-Tabelle LIPS
*-----------------------------------------------------------------------

TYPE-POOLS: vlips, vlkor, v50t1.

TABLES:  lips,  *lips,
         lipsd, *lipsd,
         vepo,
         tvlp,
         dgmsd.

TABLES: t156.                                               "IS2ERP

DATA:    BEGIN OF COMMON PART lipscom.
* Alter Tabellenstand beim Ändern

DATA:    BEGIN OF ylips OCCURS 5.
        INCLUDE STRUCTURE lipsvb.
DATA:    END OF ylips.
* Aktueller Tabellenstand

DATA:    BEGIN OF xlips OCCURS 15.
        INCLUDE STRUCTURE lipsvb.
DATA:    END OF xlips.
DATA:    xlips_ref TYPE leshp_lips_refdata_t.                 "AIP
DATA:    BEGIN OF tverpo OCCURS 0.
        INCLUDE STRUCTURE verpo.
DATA:    END OF tverpo.
* Hauptposition

DATA:    BEGIN OF hlips OCCURS 0.
        INCLUDE STRUCTURE lips.
DATA:    END OF hlips.

* Position, aus der die Splitposition entsteht
DATA:    BEGIN OF clips OCCURS 0.
        INCLUDE STRUCTURE lipsvb.
DATA:    END OF clips.
DATA:    BEGIN OF save_clips.
        INCLUDE STRUCTURE lipsvb.
DATA:    END OF save_clips.
DATA:    BEGIN OF clips_old OCCURS 0.
        INCLUDE STRUCTURE lipsvb.
DATA:    END OF clips_old.

* clips value on/after any entry on the batch split screen
DATA:    BEGIN OF gs_split_clips.
        INCLUDE STRUCTURE lipsvb.
DATA:    END OF gs_split_clips.

* Versandelement, aus dem Position generiert wird
DATA:    BEGIN OF cvekp OCCURS 0.
        INCLUDE STRUCTURE vekpvb.
DATA:    END OF cvekp.

* Fehlerprotokoll für Kommirückmeldung
DATA: BEGIN OF wat_prot OCCURS 0.
        INCLUDE STRUCTURE prott.
DATA: END OF wat_prot.


* LIPS-Key
DATA: BEGIN OF lipskey,
        mandt LIKE lips-mandt,
        vbeln LIKE lips-vbeln,
        posnr LIKE lips-posnr,
      END OF lipskey.

* Indextabelle für die Anzeige am Schirm

DATA:    BEGIN OF ilips OCCURS 15,
           posnr LIKE lips-posnr,
           tabix LIKE sy-tabix,       "Index für Tabelle XLIPS
           selkz,
         END OF ilips.

* XLIPS-TABIX  zur Sstep-Loop-Zeile.

DATA:   BEGIN OF slips OCCURS 12,
          tabix LIKE sy-tabix,
        END OF slips.

* bereits vorhandene Positionen bei Erweitern Lieferung
DATA:    BEGIN OF alips OCCURS 15,
           posnr LIKE lips-posnr,
         END OF alips.

* Hilfsfelder fuer Blättern

CONSTANTS:
        tabix_0             LIKE sy-tabix VALUE IS INITIAL.
DATA:   ilips_tabix_zeile_1 LIKE sy-tabix, "Tabix der ersten Zeile
        ilips_tabix_aktuell LIKE sy-tabix, "laufender Tabix der Seite
        ilips_loopc         LIKE sy-tabix, "Anzahl LOOP-Zeilen
        ilips_del_ind       LIKE sy-tabix. "aufsetzen nach Löschen
*       ILIPS_tabix_delete  LIKE SY-TABIX. "aufsetzen nach Löschen
* Flag: initial - erste Zeile unterliegt der Kontrolle des Table Control
*       'X'     - erste Zeile wird durch Programm bestimmt (z.B. seiten-
*                 weise Blättern oder Positionieren)
DATA:   ilips_tabix_zeile_1_set.            "MOS


DATA:
        xlips_high_posnr LIKE lips-posnr, "Hoechste Positionsnummer
        xlips_loeschen,
        xlips_loeschen_bei_anlegen,
        xlips_loeschen_menge_0,
        xlips_artikel_gesperrt,
        xlips_umfang(1)   TYPE c,         "Umfang der Liste
        text_value_item TYPE c.        " Flag Text-/Wertpos. in Auftrag

* Hilfsfeld zum Erkennen der ersten Position ohne Auftragsreferenz
DATA:   or_erste_position.
DATA: strukturpflege_rekursiv_lips TYPE c.  "rekursion fuer Korrelation

* TWE-MDIFF                                                   "v_XAN-SPE
DATA: BEGIN OF xvbpok_split OCCURS 10.
        INCLUDE STRUCTURE borgr_vbpok_split.
DATA: END OF xvbpok_split.                                    "^_XAN-SPE

*---------------------------------------------------------------------*
*        Direktwerte zum Umfang                                       *
*---------------------------------------------------------------------*
DATA:   xlips_umfang_uall TYPE c VALUE 'A', "Alle Pos ohne Ch-Upos
        xlips_umfang_uhau TYPE c VALUE 'B', "Hauptpositionen
        xlips_umfang_umar TYPE c VALUE 'C', "markierte Positionen
        xlips_umfang_uunv TYPE c VALUE 'D', "unvollständige Positionen
        xlips_umfang_ucha TYPE c VALUE 'E', "Chargenstruktur
        xlips_umfang_unor TYPE c VALUE 'F'. "Alle Positionen

* Coding for R/2-R/3 coupling removed EHP 4

*     Rounding pick quantity (note 89276, ALRK065605)
DATA: epsilon TYPE f VALUE '0E1'.             "choose epsilon <= 0.0005

* only used in case of overpick for ATP-check of the delivery
* filled in delivery_batch_item_change(LV50LF12)
* only for use in aktion_bestimmen(FV50VF0A) and
* map_to_atp_item(LLE_ATP_DELIVERY_INTERFACEF0A)
DATA: gf_lips_overpick_diff LIKE lips-lfimg_flo.
DATA: gv_xsit TYPE sitkz.                                           "v_SIT
DATA: gv_sitbw TYPE sitbw.
DATA: gv_sit_flag TYPE flag.
DATA: gv_sit_flag_cont TYPE flag.
DATA: GV_SIT_CANCEL_FLAG,
      GV_SIT_GM TYPE XFELD.  "N ... not relevant, X ... relevant    n_1919490
DATA: gv_sit_doc_num TYPE emkpf-mblnr.
DATA: gt_sitbw TYPE tdt_sitbw WITH HEADER LINE,
      gv_sit_retpo      TYPE flag.
*DATA: BEGIN OF gt_sitbw OCCURS 1,
*        vbeln LIKE lips-vbeln,
*        posnr LIKE lips-posnr,
*        bwart LIKE lips-bwart,
*      END OF gt_sitbw.

                                "^_SIT
DATA:   END OF COMMON PART.
*eject

*---------------------------------------------------------------------*
*        Direktwerte zur Namensraumänderung                           *
*---------------------------------------------------------------------*

DATA: tc_vl01 LIKE sy-tcode VALUE 'VL01',
      tc_vl02 LIKE sy-tcode VALUE 'VL02'.

DATA: dgmsd_wa_de LIKE  rdgsdiot.
DATA: x_dgmsd_tab1 LIKE dgmsdvb OCCURS 0 WITH HEADER LINE.


* --------------------------------------------------------------------
*   Subcontracting Components: Global component table for delivery
* --------------------------------------------------------------------
DATA: gt_compvb TYPE  lecompvb_t.           " HSO 2008-03-27



*-----------------------------------------*
* Allocation run relevant data declaration*
*-----------------------------------------*
  DATA: go_arun_obd_process TYPE REF TO cl_arun_outbound_delivery.
  DATA: go_arun_ibd_process TYPE REF TO cl_arun_inboundelivery_process. "IDB Dellocation processing
