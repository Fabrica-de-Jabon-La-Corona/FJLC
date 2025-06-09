*-----------------------------------------------------------------------
*        Weitere Tabellendefinitionen
*-----------------------------------------------------------------------
INCLUDE set_off.
TYPE-POOLS: vlikp.

TABLES: likp,
        likpd,
        *likp,
        *likpd,                                             "470
        tvlk,
        vekp,
        tvlkt.
TABLES: ttzcu.

" Intercompany Transfer of Control Dates
TABLES: ico_likp_tocd_ui.

TABLES: flle_integration_fields_ui.

DATA: BEGIN OF COMMON PART likpcom.
* Alter Tabellenstand beim Ändern

DATA:    BEGIN OF ylikp OCCURS 1.
           INCLUDE STRUCTURE likp.
DATA:    END OF ylikp.
DATA:    ylikp_updkz.

* Aktueller Tabellenstand: nur Update-Kennzeichen erforderlich
DATA:    BEGIN OF xlikp OCCURS 10.
           INCLUDE STRUCTURE likpvb.
DATA:    END OF xlikp.
DATA: BEGIN OF vlikp OCCURS 1.              "nur für Verpacken
        INCLUDE STRUCTURE likpvb.
DATA: END OF vlikp.

DATA: header_identical TYPE c.

* Analysetabelle der Splitkriterien zum Lieferkopf
DATA: gt_likp_analyse TYPE vlikp_t_analyse.
DATA: gt_splitprot TYPE vlikp_t_splitprot.
DATA: gv_split_badi_called TYPE char1.
DATA: gs_suppress_split TYPE leshp_no_split.

DATA: BEGIN OF y1vbpa OCCURS 0.
        INCLUDE STRUCTURE vbpavb.
DATA: END OF y1vbpa.
DATA: gv_land1 TYPE land1.

DATA: BEGIN OF tverko OCCURS 0.
        INCLUDE STRUCTURE verko.
DATA: END OF tverko.

DATA: xlikp_updkz.

* Kennzeichen, dass ein Kopf angelegt wurde.
DATA: slikp-tabix LIKE sy-tabix.

* Globale Steuerkennzeichen
DATA:
  kz_lieferavis,                 "Sonderroutine Lieferavis
  kz_grobwe,                     "Sonderroutine Grobwe
  lfart_besttyp,                 "Bestätigungstyp der Lieferart
  kz_wareneingang,
* Anzahl M-Positionen beim Warenausgang.
  wa_anz_mpos     LIKE sy-tfill VALUE 0,
  wms_anz_pos     LIKE sy-tfill VALUE 0,
  zaehler_vbfs    LIKE vbfs-zaehl VALUE 0.

DATA:   packdaten_verbuchen(1) TYPE c. "Flag, ob Packdaten zu verbuchen
"sind  ' ': nein,  'X': ja

* Coding for R/2-R/3 coupling removed EHP 4

* Routenermittlung
DATA: BEGIN OF neuterminierung OCCURS 0,
        vbeln LIKE likp-vbeln,
        neute LIKE tvlk-neute,
      END OF neuterminierung.
DATA: BEGIN OF likp_dat OCCURS 0,
        vbeln_vl LIKE likp-vbeln.
        INCLUDE STRUCTURE vbep.
DATA: END OF likp_dat.

* fields that are used on delivery UI
DATA gv_likp_aezet          TYPE erzet.
DATA gv_likp_aetzone        TYPE tznzonesys.
DATA gv_wadat_tzonis        TYPE tznzonesys.
DATA gv_wadat_ist_tzonis    TYPE tsegzoniss.
DATA gv_lddat_tzonis        TYPE tsegzoniss.
DATA gv_tddat_tzonis        TYPE tsegzoniss.
DATA gv_kodat_tzonis        TYPE tsegzoniss.
DATA gv_fkdat_tzonis        TYPE tsegzoniss.
DATA gv_fkdiv_tzonis        TYPE tsegzoniss.
DATA gv_mbdat_tzonis        TYPE tsegzoniss.
DATA gv_wadat_ist_la_tzonrc TYPE tsegzonrec.


ENHANCEMENT-POINT vblkdata_10 SPOTS es_vblkdata STATIC INCLUDE BOUND .

DATA: END OF COMMON PART.


*Include for Retail(Fashion)
INCLUDE rfm_vblk_data.
