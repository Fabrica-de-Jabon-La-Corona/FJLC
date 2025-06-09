"Name: \PR:SAPFV50C\EX:VORLAGE_KOPIEREN_13\EI
ENHANCEMENT 0 ZZMOD_OUTBOUND_DATES_FROM_VBAK.
IF sy-uname EQ 'CAOLIVAS'.
  BREAK-POINT.
ENDIF.

IF cvbak-zzload_date NE '00000000'.
  MOVE cvbak-zzload_date TO likp-kodat.
  MOVE cvbak-zzload_date TO likp-tddat.
  MOVE cvbak-zzload_date TO likp-lddat.
  MOVE cvbak-zzload_date TO likp-wadat.
  MOVE cvbak-zzload_date TO lips-mbdat.

  MOVE cvbak-zzload_date TO xlikp-kodat.
  MOVE cvbak-zzload_date TO xlikp-tddat.
  MOVE cvbak-zzload_date TO xlikp-lddat.
  MOVE cvbak-zzload_date TO xlikp-wadat.

  LOOP AT xlips ASSIGNING FIELD-SYMBOL(<fs_xlips>).
    <fs_xlips>-mbdat = cvbak-zzload_date.
    MODIFY xlips FROM <fs_xlips> TRANSPORTING mbdat.
  ENDLOOP.

ENDIF.
ENDENHANCEMENT.
