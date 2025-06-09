*&---------------------------------------------------------------------*
*& Report  ZSD_RVDELSTA                                                    *
*&                                                                     *
*&---------------------------------------------------------------------*
*&                                                                     *
*&                                                                     *
*&---------------------------------------------------------------------*

REPORT  zsd_rvdelsta                                .
TABLES: t185f, t180, v50agl.                                "n_1226602


TYPE-POOLS : slis.

** WORK AREA FOR HEADER DATA
DATA : wa_hdata_alv TYPE sdrvdels.
** INTERNAL TABLE FOR HEADER DATA
DATA : gt_hdata_alv TYPE STANDARD TABLE OF sdrvdels.

** WORK AREA FOR ITEM DATA
DATA : wa_idata_alv TYPE sdrvdels.
** INTERNAL TABLE FOR ITEM DATA
DATA : gt_idata_alv TYPE STANDARD TABLE OF sdrvdels.

DATA : lv_message(80)  TYPE c.
DATA : lv_vbeln        TYPE likp-vbeln.
DATA : gv_header(60)   TYPE c.
DATA : gv_end_page(60) TYPE c.

DATA :
* To store the structure name for header list.
  gc_structure TYPE dd02d-strname,

* Internal table for Field catalog header&item data
  gt_fieldcat  TYPE slis_t_fieldcat_alv,

* Internal table for events
  gt_eventtab  TYPE slis_t_event,

* Structure for the layout for the Primary list
  gs_layout    TYPE slis_layout_alv,

* Structure for keyinfo.
  gs_keyinfo   TYPE slis_keyinfo_alv,

* Report Name
  g_repid      TYPE sy-repid.         " Program name

CONSTANTS:
  gc_check(1)   TYPE c VALUE 'X',
* To store the header table name
  gc_tab_header TYPE slis_tabname VALUE 'GT_HDATA_ALV',

* To store the item table name
  gc_tab_item   TYPE slis_tabname VALUE 'GT_IDATA_ALV'.

INCLUDE zvblkdata.
*include vblkdata.
INCLUDE zvblpdata.
*include vblpdata.
INCLUDE zvbupdata.
*include vbupdata.
INCLUDE zvbuvdata.
*include vbuvdata.
INCLUDE zbukdata.
*include vbukdata.
INCLUDE zcopylifs.
*include copylifs.

DATA: BEGIN OF gt_likp OCCURS 10,
        mandt LIKE likp-mandt,
        vbeln LIKE likp-vbeln,
        vbtyp LIKE likp-vbtyp,
        klief LIKE likp-klief,
      END   OF gt_likp.

DATA: BEGIN OF gt_old_vbup OCCURS 0.
        INCLUDE STRUCTURE vbupvb.
DATA: END OF gt_old_vbup.

DATA: BEGIN OF gt_old_vbuk.
        INCLUDE STRUCTURE vbukvb.
DATA: END OF gt_old_vbuk.

DATA: BEGIN OF gt_fld_vbup OCCURS 0.
        INCLUDE STRUCTURE dntab.
DATA: END OF gt_fld_vbup.

DATA: BEGIN OF gt_fld_vbuk OCCURS 0.
        INCLUDE STRUCTURE dntab.
DATA: END OF gt_fld_vbuk.

DATA: gf_change      TYPE c,
      gf_msgtxt(120) TYPE c.

DATA: lf_msgno LIKE sy-msgno.
DATA: lf_lines TYPE i.                                      "n_1005265

SELECT-OPTIONS: delivery  FOR likp-vbeln MEMORY ID vl.
PARAMETERS:     p_test    AS CHECKBOX DEFAULT ''.
PARAMETERS:     p_poupd   TYPE c NO-DISPLAY DEFAULT space.  "n_1226602

INITIALIZATION.
  g_repid = sy-repid.
  gs_keyinfo-header01 = 'VBELN'.
  gs_keyinfo-item01   = 'VBELN'.

START-OF-SELECTION.

  v50agl-no_lfimg_check_mmli = 'X'.                         "n_2088444

  PERFORM get_table_structure. "get table structure in internal tables

*select wrong status deliveries.
  IF delivery[] IS INITIAL.
    SELECT FROM likp
      FIELDS 'I', 'EQ', vbeln
      WHERE fkstk EQ 'C'
      AND gbstk NE 'C'
      AND wbstk NE 'C'
      INTO TABLE @delivery.
  ENDIF.

* put only those documents to gt_likp which are deliveries (LIKP exists)
* and in the specified range.
  IF delivery[] IS NOT INITIAL.
    SELECT mandt vbeln vbtyp klief FROM likp
           INTO CORRESPONDING FIELDS OF TABLE gt_likp
           WHERE vbeln IN delivery.
    IF sy-subrc NE 0.
**  as we need to exit from the processing , we are giving STOP and
**  going to END_OF_SELECTION event and printing the write statement
      MOVE TEXT-001 TO gv_header .
      STOP.
    ENDIF.
  ELSE.
    MOVE TEXT-001 TO gv_header .
    STOP.
  ENDIF.

  DELETE gt_likp WHERE klief = 'X'.                        "v_n_1005265
  DESCRIBE TABLE gt_likp LINES lf_lines.
  IF lf_lines LE 0.          " Only correction deliveries were selected
    MESSAGE ID 'VL' TYPE 'E' NUMBER '136'.
  ENDIF.                                                   "^_n_1005265

  LOOP AT gt_likp.


    MOVE TEXT-002 TO wa_hdata_alv-text .
    wa_hdata_alv-vbeln = gt_likp-vbeln.

    APPEND wa_hdata_alv TO gt_hdata_alv.
    CLEAR wa_hdata_alv.

    lv_vbeln = gt_likp-vbeln.
    wa_idata_alv-vbeln = lv_vbeln.

    CLEAR gf_change.

*   Initializing to recalculate status
    PERFORM no_dequeue(sapmv50a) IF FOUND.
    PERFORM lieferungsupdate_extern_init(sapmv50a) IF FOUND.
    PERFORM transaktion_init(sapmv50a) USING 'VL02' IF FOUND.
    PERFORM lieferungsupdate_extern_init(sapmv50a) IF FOUND.
    PERFORM synchron(sapmv50a) IF FOUND.
    PERFORM nicht_sperren_y(sapmv50a) IF FOUND.
    PERFORM no_messages_update(sapmv50a) IF FOUND.
    PERFORM aufrufer_transport(sapmv50a) IF FOUND.

    REFRESH cvbfs.
*   Ensure that messages are written to the log instead to the screen
    t185f-aktyp = 'H'.

*   If requested by caller: Force update of the PO confirmation despite
*   AURUFER = 'T'. Default: P_POUPD is space since field is invisible
    v50agl-force_po_update = p_poupd.                       "n_1226602

    likp-vbeln = gt_likp-vbeln.
    IF gt_likp-vbtyp EQ if_sd_doc_category=>delivery_shipping_notif.
      t180-trvog = 'D'.
    ELSE.
      t180-trvog = '6'.
    ENDIF.
    PERFORM beleg_lesen(sapmv50a).

*   no unchecked deliveries
    READ TABLE xvbuk WITH KEY vbeln = gt_likp.
    IF NOT xvbuk-bestk IS INITIAL.


      wa_idata_alv-vbeln = lv_vbeln.
      wa_idata_alv-descr = TEXT-019.

      APPEND wa_idata_alv TO gt_idata_alv.
      CLEAR wa_idata_alv.
      CHECK 1 = 2.
    ENDIF.

    PERFORM old_status_save.       " save the current VBUP, VBUK entries

    SORT xlips BY mandt vbeln posnr.
    REFRESH ilips.
    LOOP AT xlips.
      ilips-posnr = xlips-posnr.
      ilips-tabix = sy-tabix.
      APPEND ilips.
    ENDLOOP.

    LOOP AT xlips.
      slips-tabix = sy-tabix.
      ilips-tabix = sy-tabix.
      PERFORM lips_bearbeiten_vorbereiten(sapfv50p).
      PERFORM lips_referenz_lesen(sapfv50p).
      PERFORM lips_bearbeiten(sapfv50p).
      IF v50agl-force_po_update NE space AND                "v_n_1226602
         xlips-updkz EQ space.
        MOVE-CORRESPONDING xlips TO ylips.
        APPEND ylips.
        xlips-updkz = 'U'.
        MODIFY xlips INDEX slips-tabix.
      ENDIF.                                                "^_n_1226602
    ENDLOOP.

*   Ensure calculation of the incompleteness status
    PERFORM uc_complete_recalc(sapfv50u).

    PERFORM xvbuk_pflegen(sapfv50k).     " recalculate header status

    LOOP AT cvbfs WHERE msgty CA 'AEX'.
      IF sy-tabix EQ 1.
        wa_idata_alv-vbeln = lv_vbeln.
        wa_idata_alv-descr = TEXT-003.
        APPEND wa_idata_alv TO gt_idata_alv.
        CLEAR  wa_idata_alv.

      ENDIF.
      lf_msgno = cvbfs-msgno.
      PERFORM message_aufbauen(sapmv50a) USING lf_msgno
                                               cvbfs-msgty
                                               cvbfs-msgid
                                               cvbfs-msgv1
                                               cvbfs-msgv2
                                               cvbfs-msgv3
                                               cvbfs-msgv4
                                               gf_msgtxt.


      CONCATENATE cvbfs-msgid cvbfs-msgno gf_msgtxt INTO lv_message
                                             SEPARATED BY space.
      wa_idata_alv-vbeln = lv_vbeln.
      wa_idata_alv-descr = lv_message.
      APPEND wa_idata_alv TO gt_idata_alv.
      CLEAR  wa_idata_alv.

    ENDLOOP.
    IF sy-subrc EQ 0.
      CONTINUE.
    ENDIF.

    PERFORM status_compare.  "compare status before and after report

    IF p_test IS INITIAL.
      PERFORM position_gewichtsupdate_chsp(sapfv50p) USING space.
      PERFORM beleg_sichern(sapmv50a) USING space.
      COMMIT WORK.
    ENDIF.
    IF gf_change EQ space.
      wa_idata_alv-vbeln = lv_vbeln.
      wa_idata_alv-descr = TEXT-004.
      APPEND wa_idata_alv TO gt_idata_alv.
      CLEAR wa_idata_alv.
    ENDIF.
  ENDLOOP.

  IF NOT p_test IS INITIAL.
    MOVE TEXT-005 TO gv_end_page .
  ELSE.
    MOVE TEXT-006 TO gv_end_page .                          "n_930929
  ENDIF.

END-OF-SELECTION.

  PERFORM output_alv.

*---------------------------------------------------------------------*
*       FORM get_table_structure                                      *
*---------------------------------------------------------------------*
*       Creates internal tables carrying the fieldnames of the
*       database-tables
*---------------------------------------------------------------------*
FORM get_table_structure.

  CALL FUNCTION 'NAMETAB_GET'
    EXPORTING
      tabname             = 'LIPS_STATUS'
    TABLES
      nametab             = gt_fld_vbup
    EXCEPTIONS
      internal_error      = 0
      table_has_no_fields = 0
      table_not_activ     = 0
      no_texts_found      = 0
      OTHERS              = 0.

  CALL FUNCTION 'NAMETAB_GET'
    EXPORTING
      tabname             = 'LIKP_STATUS'
    TABLES
      nametab             = gt_fld_vbuk
    EXCEPTIONS
      internal_error      = 0
      table_has_no_fields = 0
      table_not_activ     = 0
      no_texts_found      = 0
      OTHERS              = 0.

ENDFORM.                                         "get_table_structure

*---------------------------------------------------------------------*
*       FORM old_status_save                                          *
*---------------------------------------------------------------------*
*       Saves the current status information of the delivery
*---------------------------------------------------------------------*
FORM old_status_save.

* save current entries of VBUP to be able to write a log on screen
  gt_old_vbup[] = xvbup[].
  SORT gt_old_vbup BY mandt vbeln posnr.

* save currenct entries of VBUK to be able to write a log on screen
  MOVE-CORRESPONDING  xvbuk TO gt_old_vbuk.

ENDFORM.                                         "old_status_save

*---------------------------------------------------------------------*
*       FORM status_compare                                           *
*---------------------------------------------------------------------*
*       Compares status of the delivery before and after the run
*---------------------------------------------------------------------*
FORM status_compare.


  DATA: lf_text(120) TYPE c.

  FIELD-SYMBOLS: <io>, <in>,           " item old, item new
                 <ho>, <hn>.           " header old, header new

  DATA : lv_hrd_status(120) TYPE c.
  DATA : lv_itm_status(120) TYPE c.

* Compare header status
  LOOP AT gt_fld_vbuk.

    IF NOT gt_fld_vbuk-fieldname = 'SAPRL'.
      ASSIGN COMPONENT gt_fld_vbuk-fieldname
                       OF STRUCTURE xvbuk TO <hn>.
      ASSIGN COMPONENT gt_fld_vbuk-fieldname
                       OF STRUCTURE gt_old_vbuk TO <ho>.

      IF <ho> NE <hn>.

        wa_idata_alv-vbeln = lv_vbeln.
        CONCATENATE TEXT-007 gt_fld_vbuk-fieldname(6) TEXT-009 <ho>
                 TEXT-020 <hn> INTO lv_hrd_status SEPARATED BY space.
        wa_idata_alv-descr = lv_hrd_status.
        APPEND wa_idata_alv TO gt_idata_alv.
        CLEAR  wa_idata_alv.
        gf_change = 'X'.
      ENDIF.
    ENDIF.

  ENDLOOP.

* Compare item status
  LOOP AT xvbup.
    READ TABLE gt_old_vbup WITH KEY mandt = xvbup-mandt
                                 vbeln = xvbup-vbeln
                                 posnr = xvbup-posnr
                        BINARY SEARCH.
    CHECK sy-subrc EQ 0.                                    "n_1863204
    LOOP AT gt_fld_vbup.

      ASSIGN COMPONENT gt_fld_vbup-fieldname
                       OF STRUCTURE xvbup
                       TO <in>.
      ASSIGN COMPONENT gt_fld_vbup-fieldname
                       OF STRUCTURE gt_old_vbup
                       TO <io>.
      IF <io> NE <in>.
        wa_idata_alv-vbeln = lv_vbeln.
        CONCATENATE TEXT-017 xvbup-posnr TEXT-008
                    gt_fld_vbup-fieldname(8) TEXT-009 <io> TEXT-020 <in>
                    INTO lv_itm_status SEPARATED BY space.
        wa_idata_alv-descr = lv_itm_status.
        APPEND wa_idata_alv TO gt_idata_alv.
        CLEAR  wa_idata_alv.
        gf_change = 'X'.
      ENDIF.
    ENDLOOP.
  ENDLOOP.


* Check whether header incompleteness status changed
  LOOP AT yvbuv WHERE posnr EQ '000000'.

    READ TABLE xvbuv WITH KEY vbeln = yvbuv-vbeln
                              posnr = yvbuv-posnr
                              etenr = yvbuv-etenr
                              parvw = yvbuv-parvw
                              tdid  = yvbuv-tdid
                              tbnam = yvbuv-tbnam
                              fdnam = yvbuv-fdnam
               BINARY SEARCH.
    IF sy-subrc NE 0.
      PERFORM write_incompleteness USING    yvbuv
                                            TEXT-010          "'removed'
                                   CHANGING lf_text.
      gf_change = 'X'.
    ELSEIF xvbuv NE yvbuv.
      PERFORM write_incompleteness USING    yvbuv
                                            TEXT-011          "'updated'
                                   CHANGING lf_text.
      gf_change = 'X'.
    ENDIF.
  ENDLOOP.
  LOOP AT xvbuv WHERE posnr EQ '000000'.
    READ TABLE yvbuv WITH KEY vbeln = xvbuv-vbeln
                              posnr = xvbuv-posnr
                              etenr = xvbuv-etenr
                              parvw = xvbuv-parvw
                              tdid  = xvbuv-tdid
                              tbnam = xvbuv-tbnam
                              fdnam = xvbuv-fdnam
               BINARY SEARCH TRANSPORTING NO FIELDS.
    IF sy-subrc NE 0.
      PERFORM write_incompleteness USING    xvbuv
                                            TEXT-012         "'inserted'
                                   CHANGING lf_text.
      gf_change = 'X'.
    ENDIF.
  ENDLOOP.

* Check whether incompleteness data on item level are changed
  LOOP AT yvbuv WHERE posnr NE '000000'.

    READ TABLE xvbuv WITH KEY vbeln = yvbuv-vbeln
                              posnr = yvbuv-posnr
                              etenr = yvbuv-etenr
                              parvw = yvbuv-parvw
                              tdid  = yvbuv-tdid
                              tbnam = yvbuv-tbnam
                              fdnam = yvbuv-fdnam
               BINARY SEARCH.
    IF sy-subrc NE 0.
      PERFORM write_incompleteness USING    yvbuv
                                            TEXT-010          "'removed'
                                   CHANGING lf_text.
      gf_change = 'X'.
    ELSEIF xvbuv NE yvbuv.
      PERFORM write_incompleteness USING    yvbuv
                                            TEXT-011          "'updated'
                                   CHANGING lf_text.
      gf_change = 'X'.
    ENDIF.
  ENDLOOP.
  LOOP AT xvbuv WHERE posnr NE '000000'.
    READ TABLE yvbuv WITH KEY vbeln = xvbuv-vbeln
                              posnr = xvbuv-posnr
                              etenr = xvbuv-etenr
                              parvw = xvbuv-parvw
                              tdid  = xvbuv-tdid
                              tbnam = xvbuv-tbnam
                              fdnam = xvbuv-fdnam
               BINARY SEARCH TRANSPORTING NO FIELDS.
    IF sy-subrc NE 0.
      PERFORM write_incompleteness USING    xvbuv
                                            TEXT-012         "'inserted'
                                   CHANGING lf_text.
      gf_change = 'X'.
    ENDIF.
  ENDLOOP.

ENDFORM.                                         "status_compare
*&---------------------------------------------------------------------*
*&      Form  write_incompleteness
*&---------------------------------------------------------------------*
FORM write_incompleteness USING    cs_vbuv LIKE vbuvvb
                                   if_action
                          CHANGING cf_text.

  DATA: lf_field(50) TYPE c.

  IF cs_vbuv-posnr EQ '000000'.
    cf_text = TEXT-013.                      "'- Header incompleteness'.
  ELSE.
    cf_text =  TEXT-017.                                     "'- Item'.
    CONCATENATE cf_text cs_vbuv-posnr TEXT-014        "'incompleteness'
                INTO cf_text SEPARATED BY space.
  ENDIF.
  CONCATENATE cf_text TEXT-015                             "'for field'
              INTO cf_text SEPARATED BY space.
  CONCATENATE cs_vbuv-tbnam '-' cs_vbuv-fdnam INTO lf_field.
  CONCATENATE cf_text lf_field INTO cf_text SEPARATED BY space.
  CONDENSE cf_text.
  IF NOT cs_vbuv-tdid IS INITIAL.
    CONCATENATE cf_text TEXT-018                              "'TextID'
                cs_vbuv-tdid INTO cf_text SEPARATED BY space.
  ENDIF.
  IF NOT cs_vbuv-parvw IS INITIAL.
    CONCATENATE cf_text TEXT-016                               "'PARVW'
                cs_vbuv-parvw INTO cf_text SEPARATED BY space.
  ENDIF.
  CONCATENATE cf_text if_action INTO cf_text
              SEPARATED BY space.
  CONDENSE cf_text.

  wa_idata_alv-vbeln = lv_vbeln.
  wa_idata_alv-descr = cf_text.
  APPEND wa_idata_alv TO gt_idata_alv.
  CLEAR  wa_idata_alv.

ENDFORM.                    " write_incompleteness

*&---------------------------------------------------------------------*
*&      Form  output_alv
*&---------------------------------------------------------------------*
*       To Display the data in ALV
*----------------------------------------------------------------------*
*       No parameters to be passed
*----------------------------------------------------------------------*
FORM output_alv .

  gc_structure = 'SDRVDELS'.
  PERFORM fieldcat_build USING gc_structure
                               gc_tab_header
                         CHANGING gt_fieldcat.

  gc_structure = 'SDRVDELS'.
  PERFORM fieldcat_build USING gc_structure
                               gc_tab_item
                         CHANGING gt_fieldcat.

* To get the events
  PERFORM eventtab_inv_build CHANGING gt_eventtab.

* To get the Layout changes
  PERFORM layout_build .


  CALL FUNCTION 'REUSE_ALV_HIERSEQ_LIST_DISPLAY'
    EXPORTING
      i_callback_program = g_repid
      is_layout          = gs_layout
      it_fieldcat        = gt_fieldcat
      i_tabname_header   = gc_tab_header
      i_tabname_item     = gc_tab_item
      is_keyinfo         = gs_keyinfo
      it_events          = gt_eventtab
    TABLES
      t_outtab_header    = gt_hdata_alv
      t_outtab_item      = gt_idata_alv
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                    " output_alv

*&---------------------------------------------------------------------*
*&      Form  fieldcat_build
*&---------------------------------------------------------------------*
*       To build the field catalog for the display the changes in
*       physical inventory documents
*----------------------------------------------------------------------*
*       <--iv_structure   Structure Name
*       <--iv_tab         Internal Table Name
*       -->XT_FIELDCAT    Field Catalog
*----------------------------------------------------------------------*
FORM fieldcat_build  USING iv_structure   TYPE dd02D-strname
                           iv_tab         TYPE slis_tabname
                     CHANGING xt_fieldcat TYPE slis_t_fieldcat_alv.

  DATA: ls_fieldcat TYPE slis_fieldcat_alv.

* For building the Field Catalog
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name         = g_repid
      i_internal_tabname     = iv_tab
      i_structure_name       = iv_structure
*     i_inclname             = g_repid
    CHANGING
      ct_fieldcat            = xt_fieldcat
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.                               " IF SY-SUBRC <> 0.


  IF iv_tab = 'GT_HDATA_ALV'.

    CLEAR ls_fieldcat.
    ls_fieldcat-tech = gc_check.
    MODIFY xt_fIELDcat FROM ls_fieldcat TRANSPORTING tech
                                   WHERE fieldname = 'TEXT'
                                     AND tabname   = 'GT_HDATA_ALV'.

    CLEAR ls_fieldcat.
    ls_fieldcat-tech = gc_check.
    MODIFY xt_fIELDcat FROM ls_fieldcat TRANSPORTING tech
                                   WHERE fieldname = 'DESCR'
                                     AND tabname   = 'GT_HDATA_ALV'.

  ELSEIF iv_tab = 'GT_IDATA_ALV'.

    CLEAR ls_fieldcat.
    ls_fieldcat-tech = gc_check.
    MODIFY xt_fIELDcat FROM ls_fieldcat TRANSPORTING tech
                                   WHERE fieldname = 'VBELN'
                                     AND tabname   = 'GT_IDATA_ALV'.

    CLEAR ls_fieldcat.
    ls_fieldcat-tech = gc_check.
    MODIFY xt_fIELDcat FROM ls_fieldcat TRANSPORTING tech
                                   WHERE fieldname = 'TEXT'
                                     AND tabname   = 'GT_IDATA_ALV'.

  ENDIF.

ENDFORM.                               " fieldcat_inv_build

*&---------------------------------------------------------------------*
*&      Form  eventtab_inv_build
*&---------------------------------------------------------------------*
*       To get the all the events to an internal table
*----------------------------------------------------------------------*
*      -->XT_EVENTTAB  text
*----------------------------------------------------------------------*
FORM eventtab_inv_build  CHANGING xt_eventtab TYPE slis_t_event.

  DATA : ls_event TYPE slis_alv_event. " For Events tabls

* To get the events
  CALL FUNCTION 'REUSE_ALV_EVENTS_GET'
    IMPORTING
      et_events       = xt_eventtab
    EXCEPTIONS
      list_type_wrong = 1
      OTHERS          = 2.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
         WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.                               " IF SY-SUBRC <> 0.

*** End-of-list

  READ TABLE xt_eventtab INTO ls_event
                         WITH KEY name = slis_ev_end_of_list.
  IF sy-subrc = 0.
    ls_event-form = slis_ev_end_of_list.
    MODIFY xt_eventtab  FROM ls_event INDEX sy-tabix TRANSPORTING form.
  ENDIF.                               " IF sy-subrc = 0.

*** Top-of-page
  READ TABLE xt_eventtab INTO ls_event
                         WITH KEY name = slis_ev_top_of_page.
  IF sy-subrc = 0.
    ls_event-form = slis_ev_top_of_page.
    MODIFY xt_eventtab  FROM ls_event INDEX sy-tabix TRANSPORTING form.
  ENDIF.                               " IF sy-subrc = 0.


ENDFORM.                               " eventtab_inv_build

*&---------------------------------------------------------------------*
*&      Form  END_OF_LIST
*&---------------------------------------------------------------------*
*       To Display the End of list for the secondary list
*----------------------------------------------------------------------*
*       There are no parameters to be passed
*----------------------------------------------------------------------*
FORM end_of_list.

  CONSTANTS : lc_a TYPE c VALUE 'A'.

  DATA: it_list_END_of_LIST TYPE slis_t_listheader,
        ls_line             TYPE slis_listheader.

  CLEAR ls_line.
  ls_line-typ  = lc_A.
  ls_line-info = gv_end_page.

  APPEND ls_line TO it_list_END_of_LIST.

  CLEAR gv_end_page.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = it_list_END_of_LIST
*     I_LOGO             =
*     I_END_OF_LIST_GRID =
*     I_ALV_FORM         =
    .

ENDFORM.                               " END_OF_LIST

*&---------------------------------------------------------------------*
*&      Form  TOP_OF_PAGE
*&---------------------------------------------------------------------*
*       To Display the TOP_OF_PAGE for the List
*----------------------------------------------------------------------*
*       There are no parameters to be passed
*----------------------------------------------------------------------*
FORM top_of_page.

  CONSTANTS : lc_h TYPE c VALUE 'H',
              lc_a TYPE c VALUE 'A'.

  DATA: it_list_top_of_page TYPE slis_t_listheader,
        ls_line             TYPE slis_listheader,
        lv_space(60)        TYPE c VALUE space,
        lv_text_long        TYPE dfies-reptext.      "for SIMULATION

  IF NOT gv_header IS INITIAL.
    CLEAR ls_line.
    ls_line-typ  = lc_h.
    ls_line-info = gv_header.

    APPEND ls_line TO it_list_top_of_page.

    CLEAR gv_header.

  ELSE.

    CLEAR ls_line.
    ls_line-typ  = lc_A.
    ls_line-info = sy-title.

    APPEND ls_line TO it_list_top_of_page.

  ENDIF.

* Code to display a blank line.
  SET BLANK LINES ON.
  CLEAR ls_line.
  ls_line-typ  = lc_A.
  MOVE lv_space TO ls_line-info.

  APPEND ls_line TO it_list_top_of_page.

*** TO GET THE DESCRIPTION OF SIMULATION RUN
  PERFORM get_description_alv USING 'P_SIMUL'
           CHANGING lv_text_LONG.

  CLEAR ls_line.
  ls_line-typ    = lc_a.
  ls_line-info   = lv_text_long.
  APPEND ls_line TO it_list_top_of_page.


  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = it_list_top_of_page
*     I_LOGO             =
*     I_END_OF_LIST_GRID =
*     I_ALV_FORM         =
    .
  SET BLANK LINES OFF.

ENDFORM.                               " END_OF_LIST

*&---------------------------------------------------------------------*
*&      Form  layout_build
*&---------------------------------------------------------------------*
*       To build the layout
*----------------------------------------------------------------------*
*       No parameters to be passed
*----------------------------------------------------------------------*
FORM layout_build .

  gs_layout-zebra      = gc_check.

ENDFORM.                    " layout_build

*&---------------------------------------------------------------------*
*&      Form  get_description_alv
*&---------------------------------------------------------------------*
*       Get the descriptions of Dataelement
*----------------------------------------------------------------------*
*      -->IV_DATAELEMENT   Dataelement
*      <--XV_TEXT_LONG     Long
*----------------------------------------------------------------------*
FORM get_description_alv   USING iv_dataelement TYPE ddobjname
                           CHANGING xv_text_long .

  CALL FUNCTION '/SAPDMC/DATAELEMENT_GET_TEXTS'
    EXPORTING
      name      = iv_dataelement
    IMPORTING
      text_long = xv_text_long
    EXCEPTIONS
      not_found = 1
      OTHERS    = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                    " get_description_alv
