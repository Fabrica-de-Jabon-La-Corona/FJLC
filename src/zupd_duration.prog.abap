*&---------------------------------------------------------------------*
*& Report  ZUPD_DURATION
*&
*&---------------------------------------------------------------------*

REPORT  ZUPD_DURATION.

TABLES: QMIH.

SELECT-OPTIONS : S_QMNUM FOR QMIH-QMNUM.

UPDATE QMIH SET AUSZT  = 0
            WHERE QMNUM IN S_QMNUM.

WRITE : / 'Number of notifications updated :',SY-DBCNT.
