*&---------------------------------------------------------------------*
*& Report YFS177601
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT yfs177601.

TABLES:
  mara, makt.

TYPES:
  t_gewicht LIKE mara-brgew,
  t_matnr   LIKE mara-matnr,
  BEGIN OF t_mat,
    matnr TYPE t_matnr,
    maktx LIKE makt-maktx,
    meins LIKE mara-meins,
    gewei LIKE mara-gewei,
    brgew LIKE mara-brgew,
    ntgew LIKE mara-ntgew,
  END OF t_mat,
  BEGIN OF t_pos,
    idnrk LIKE stpo-idnrk,
    menge LIKE stpo-menge,
    meins LIKE stpo-meins,
  END OF t_pos.

DATA:
  rn     TYPE i,
  st     TYPE i,
  rs     TYPE TABLE OF t_mat,
  row    TYPE t_mat,
  _menge TYPE f,
  result TYPE t_gewicht VALUE 0.

PARAMETERS:
  matnr TYPE t_matnr DEFAULT 'MS1700BABYKPL',
  stlal LIKE mast-stlal DEFAULT '01',
  stlan LIKE mast-stlan DEFAULT '1',
  menge TYPE i DEFAULT 1.

WRITE: /15 'Material', 34 'Beschreibung', 81'Basis-Gewicht', 107'Basis-Menge', 125'Gesamt-Gewicht'.
PERFORM repeat_character USING '-' 138.

* Convert integer to floating point
_menge = menge.

PERFORM staufl USING 0 _menge matnr 1 'ST' CHANGING result.

PERFORM repeat_character USING '-' 138.
WRITE: / 'Gesamtgewicht Rohstoffe:', 120 result, 'G'.

FORM staufl
  USING
      VALUE(stufe) TYPE i
      VALUE(faktor) TYPE f
      matnr TYPE t_matnr
      menge LIKE stpo-menge
      meins LIKE stpo-meins
  CHANGING
      result TYPE t_gewicht.

  DATA:
    pos            TYPE t_pos,
    stpos          TYPE TABLE OF t_pos,
    leaf           TYPE c,
    total_position TYPE t_gewicht.
* Mandant wird durch Compiler gesetzt!
  SELECT SINGLE mara~matnr, makt~maktx, mara~meins, mara~gewei, mara~brgew, mara~ntgew
    FROM mara
    JOIN makt ON makt~matnr = mara~matnr AND makt~spras = 'D'
    INTO @row
   WHERE mara~matnr = @matnr.

  PERFORM calculate_basis_menge USING stufe row-brgew row-gewei row-meins menge meins CHANGING total_position.
  total_position = total_position * faktor.

  SELECT stpo~idnrk, stpo~menge, stpo~meins
    FROM mast
    JOIN stpo ON stpo~stlnr = mast~stlnr
    INTO TABLE @stpos
   WHERE mast~matnr = @matnr AND mast~stlan = @stlan AND mast~stlal = @stlal.

  IF sy-subrc = 0.
    leaf = 'T'.
  ELSEIF sy-subrc = 4.
    leaf = 'L'.
  ELSE.
    leaf = sy-subrc.
  ENDIF.

  IF stufe = 0.
* Use for debugging:    WRITE: / 'Material: ', leaf, matnr, row-maktx, row-brgew, row-gewei, menge, meins, total.
    WRITE: /15 matnr, row-maktx, row-brgew, row-gewei, menge, meins, total_position, 'G'.
    PERFORM repeat_character USING '-' 138.
  ELSE.
    PERFORM repeat_character USING '.' stufe.
* Use for debugging:    WRITE: 15 leaf, matnr, row-maktx, row-brgew, row-gewei, menge, meins, total.
    WRITE: 15 matnr, row-maktx, row-brgew, row-gewei, menge, meins.
    IF leaf = 'L'.
      WRITE: total_position, 'G'.
    ELSE.
      WRITE: '            Bauteil'.
    ENDIF.
  ENDIF.

  IF leaf = 'T'.
    stufe = stufe + 1.
*    WRITE: / 'Faktor :', faktor, menge.
    faktor = faktor * menge.
*    WRITE: / 'Faktor nachher = ', faktor.
    LOOP AT stpos INTO pos.
      PERFORM staufl USING stufe faktor pos-idnrk pos-menge pos-meins CHANGING result.
    ENDLOOP.
*** Stückliste, rekursiv aufrufen
***    WRITE: / 'Stückliste!'.
  ELSEIF leaf = 'L'.
    result = result + total_position.
*** Keine Stückliste, Rekursion abbrechen
***    WRITE: / 'Keine Stückliste!'.
  ELSE.
*** FEHLER!!
    WRITE: / 'SUBRC: ', leaf.
  ENDIF.
ENDFORM.

FORM calculate_basis_menge
  USING
      stufe TYPE i
      VALUE(gewic) TYPE t_gewicht
      VALUE(gewei) LIKE mara-gewei
      VALUE(basme) LIKE mara-meins
      VALUE(menge) LIKE stpo-menge
      VALUE(slpme) LIKE stpo-meins
  CHANGING
      total TYPE t_gewicht.
* Stücklistenposition-Mengeneinheit = Basismengeneinheit
  IF slpme = 'G' AND basme = 'G'.
    total = menge.
  ELSEIF slpme = 'ST'.
    total = menge * gewic.
  ELSEIF slpme = 'ML'.
    total = menge * '1.100'.
    gewei = 'G'.
  ELSEIF slpme = 'CM'.
    total = menge * '100'.
    gewei = 'G'.
  ELSE.
    WRITE: / 'I do not know how to conert ', slpme, ' into ', gewei.
    total = menge.
  ENDIF.
* Assume the base to be in g
  IF gewei = 'KG'.
    total = total * 1000.
  ENDIF.
ENDFORM.

FORM repeat_character USING char TYPE c n TYPE i.
  WRITE: / ''  NO-GAP.
  DO n TIMES.
    WRITE char NO-GAP.
  ENDDO.
ENDFORM.