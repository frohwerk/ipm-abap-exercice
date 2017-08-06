*&---------------------------------------------------------------------*
*& Report YFS177601
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT yfs177601.

TABLES:
  mara, makt.

TYPES:
  BEGIN OF t_mat,
    matnr LIKE mara-matnr,
    maktx LIKE makt-maktx,
    gewei LIKE mara-gewei,
    brgew LIKE mara-brgew,
    ntgew LIKE mara-ntgew,
  END OF t_mat.

DATA:
  rn  TYPE I,
  st  TYPE I,
  rs  TYPE TABLE OF t_mat,
  row TYPE t_mat.

PARAMETERS:
  matnr LIKE mara-matnr.

* Mandant wird durch Compiler gesetzt!
SELECT SINGLE mara~matnr, makt~maktx, mara~gewei, mara~brgew, mara~ntgew
  FROM mara
  JOIN makt ON makt~matnr = mara~matnr AND makt~spras = 'D'
  INTO @row
 WHERE mara~matnr = @matnr.

WRITE: / 'Material: ', matnr, row-maktx, row-brgew, row-gewei.
WRITE: / ''.

SELECT mara~matnr, makt~maktx, mara~gewei, mara~brgew, mara~ntgew
  FROM mast
  JOIN stpo ON stpo~stlnr = mast~stlnr
  JOIN mara ON mara~matnr = stpo~idnrk
  JOIN makt ON makt~matnr = mara~matnr AND makt~spras = 'D'
  INTO TABLE @rs
 WHERE mast~matnr = @matnr AND mast~stlan = 1 AND mast~stlan = 1.

RN = 0.
ST = 0.

LOOP AT rs INTO row.
  WRITE: / row-matnr, row-maktx, row-brgew, row-gewei.
ENDLOOP.