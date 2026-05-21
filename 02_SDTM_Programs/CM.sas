/*------------------------------------------------------------------------------------------------------------  */
/*****************************************************************************
 * Filename    : CM.sas
 * Author      : Goutham
 * Date        : &sysdate9.
 * SAS Version : SAS 9.4 (SAS ODA)
 * Platform    : Linux (SAS OnDemand Cloud)
 * Project     : EMR200048052 — EXPAND Trial
 * Description : Create SDTM CM — Concomitant Medication Domain
 * Input       : GASTRIC.cctx  (Raw CM Dataset)
 * Output      : GASTI_F.CM     (Concomitant Medication Domain)
 * Standards   : SDTM IG v3.4 | CDISC CT 2026-03-27
 *****************************************************************************
 * MODIFICATION HISTORY
 * Date          Author    Description
 * -----------   --------  --------------------------------------------------
 * &sysdate9.    Goutham   Initial creation
 *****************************************************************************/

/*--------------------------------------------------------------------------------------------- */
/*ASSIGN THE LIBRARY  */
/*------------------------------------------------------------------------------------------- */
LIBNAME GASTRIC "/home/u64240743/gastric";
RUN;
LIBNAME GASTI_F "/home/u64240743/gastric/GASTRIC SDTM RESULT";
RUN;
/*-------------------------------------------------------------------------------------------- */
DATA CM_1;
SET GASTRIC.CCTX;

LENGTH CMDOSU $40;

/*------------------------------------------------------------------------------------------  */
/*IDENTIFIER VARIABLE */
/*------------------------------------------------------------------------------------------  */

STUDYID = STRIP(STUDY);

DOMAIN = "CM";

USUBJID = STRIP(CATX("-",STUDYID,PT));

CMTRT = STRIP(DRL_TX);

CMDECOD = STRIP(PT_TX);

/*------------------------------------------------------------------------------------------  */
/*DOSE VARAIABLES  */
/*------------------------------------------------------------------------------------------  */

	IF MISSING(COMPRESS(DOSETX,'.0123456789')) THEN
CMDOSE= INPUT(DOSETX,BEST.);

 _UNIT = UPCASE(STRIP(TRTUNI));

  /*── MILLIGRAMS ──────────────────────────────────*/
  IF _UNIT IN ("MILLIGRAMS","MG","MGR","MG(PRN)")
  THEN CMDOSU = "mg";

  /*── MICROGRAMS ──────────────────────────────────*/
  ELSE IF _UNIT IN ("MICROGRAMS","MCG","MICROG",
                    "MICROGR","MICROGRAM","UG",
                    "µG","MKG","MIKROGRAM/",
                    "MICROGRAM/","Micrograms")
  THEN CMDOSU = "ug";
  
  ELSE IF _UNIT IN ("MCG/H","UG/H","µG /H",
  					"µG/H","µGR/H","Micrograms per Hours")
  					
  THEN CMDOSU = "ug/h";

  /*── MILLILITERS ─────────────────────────────────*/
  ELSE IF _UNIT IN ("MILLILITER","ML","Milliliter","ML(PRN)")
  THEN CMDOSU = "mL";
  
  ELSE IF _UNIT IN ("ML/H","ML/HR") then CMDOSU = "mL/h";

  /*── GRAMS ───────────────────────────────────────*/
  else if _unit in ("GRAM","GRAMS","GRAMM","Grams",
                    "G","g")
  then CMDOSU = "g";

  else if _unit = "G/L" then CMDOSU = "g/L";


  /*── LITERS ──────────────────────────────────────*/
  else if _unit in ("LITER","Liter","L")
  then CMDOSU = "L";

  /*── INTERNATIONAL UNITS ─────────────────────────*/
  else if _unit in ("INTERNATIONAL UNIT","IU","UI",
                    "I.E.","IE","I/U",
                    "International unit","KU","MIU",
                    "MIO IU","MUI",
                    "M.U.")
  then CMDOSU = "IU";
  
  else if _unit ="IU/ML" then CMDOSU = "IU/mL";
  else if _unit ="MUI/ML" then CMDOSU = "IU/L";
  else if _unit ="Million units" then CMDOSU = "10^6 U";


  /*── MILLIMOLES / MILLIEQUIVALENTS ───────────────*/
  else if _unit in ("MILLIEQUIVALENT","MVAL","M VAL",
                    "Milliequivalent","20MEQ")
  then CMDOSU = "mEq";

  else if _unit in ("MILLIMOLE","Millimole","MLN")
  then CMDOSU = "mmol";

  /*── CUBIC CENTIMETERS / CC ──────────────────────*/
  else if _unit in ("CUBIC CENTIMETERS","CC","C.C","C.C.","CM3","1000CC","C")
  then CMDOSU = "mL";  /* CC = mL numerically */

  /*── TABLETS ─────────────────────────────────────*/
  else if _unit in ("TABLET","TABLETS","TAB","TAB.",
                    "TABL","TBL","TB","Tabs","T","TABIET","TBL","TAB.")
  then CMDOSU = "TABLET";

  /*── CAPSULES ────────────────────────────────────*/
  else if _unit in ("CAPSULE","CAPSULES","CAP","CAPSUL","CPS","CP","Caplets")
  then CMDOSU = "CAPSULE";

  /*── DROPS ───────────────────────────────────────*/
  else if _unit in ("DROP","DROPS","GTT","GGT","GGTS",
                    "DRPS","DRP","DROP.","Drops","GUTTA","DROS")
  then CMDOSU = "DROP";

  /*── AMPOULES / VIALS ────────────────────────────*/
  else if _unit in ("AMPOULE","AMPULE","AMP","AMP.",
                    "AMPLE","AMPOLUE","AMPULLA","VIAL",
                    "Vials","VIOLS","VL")
  then CMDOSU = "VIAL";

  /*── PATCHES ─────────────────────────────────────*/
  else if _unit in ("PATCH","Patch")
  then CMDOSU = "PATCH";

  /*── SUPPOSITORIES ───────────────────────────────*/
  else if _unit in ("SUPPOSITORY","Suppository")
  then CMDOSU = "SUPPOSITORY";

  /*── PUFFS / INHALERS ────────────────────────────*/
  else if _unit in ("PUFF","PUFFS","PUF","Puffs")
  then CMDOSU = "PUFF";

  /*── SACHETS / PACKETS ───────────────────────────*/
  else if _unit in ("SACHET","PACK","PCK","POUCH","PK")
  then CMDOSU = "SACHET";

  /*── BAGS ────────────────────────────────────────*/
  else if _unit in ("BAG","BAGS","BTL","Bottle")
  then CMDOSU = "BAG";

  /*── NANOGRAMS ───────────────────────────────────*/
  else if _unit in ("NG")
  then CMDOSU = "ng";

  /*── SPOONS ──────────────────────────────────────*/
  else if _unit in ("TABLESPOON","SPOON")
  then CMDOSU = "Tbsp";
  
  else if _unit = "Tea spoon"
  then CMDOSU = "tsp";

  /*── PERCENT ─────────────────────────────────────*/
  else if _unit in ("PERCENT","Percent","1%","PERCENT")
  then CMDOSU = "%";

  /*── APPLICATION ─────────────────────────────────*/
  else if _unit in ("APLICATION","APPLICATIO","APPLICATION")
  then CMDOSU = "APPLICATION";

  /*── GRAIN ───────────────────────────────────────*/
  else if _unit in ("GRAIN","Grain")
  then CMDOSU = "grain";

  /*── UNIT (GENERIC) ──────────────────────────────*/
  else if _unit in ("UNIT","UNITS","Units","AU","EA",
                    "UD","UN","TU","QP","RG")
  then CMDOSU = "U";
  
  else if _unit in ("PEN","PIL","PILL",
                    "PILLS","PILS","P")
  then CMDOSU = "PILL";

  else if _unit = "QS"
  then CMDOSU = "/wk";

  /*── CALORIES ────────────────────────────────────*/
  else if _unit in ("KCAL")
  then CMDOSU = "kcal";

  /*── PIPETTES / CANNULAS ─────────────────────────*/
  else if _unit in ("PIPETTE","PIPET","PIP","CANNULA","SHEET")
  then CMDOSU = "";

  /*── PELLETS ─────────────────────────────────────*/
  else if _unit in ("PELLET")
  then CMDOSU = "PELLET";

  /*── MOUTHWASH ───────────────────────────────────*/
  else if _unit in ("MOUTH WASH")
  then CMDOSU = "mL";

  /*── TOPICAL ─────────────────────────────────────*/
  else if _unit in ("TOPICAL","TO-TOPICAL")
  then CMDOSU = "APPLICATION";

  /*── NUMERIC-ONLY VALUES (likely doses not units) */
  else if _unit in ("1","2","10","60","80","1000",
                    "5MG","20MG","100MG")
  then CMDOSU = "";  /* Flag for review */
 
  else if _unit in ("ADM/DAY","TIMES/DAY")
  then CMDOSU = "";
  
  else if _unit in ("5MG/5ML")
  then CMDOSU = "";

  /*── UNKNOWN / MISSING ───────────────────────────*/
  else if _unit in ("UNK","NK","NA","ND","NE","NAP",
                    "--","A","M","E","V","IH","IV",
                    "FL","HUB","J.M.","MF","OD","TQB",
                    "UK","U.K.","CH","DRAGEES","PINT",
                    "CLYSTER","PAIR","GAMMA","AU",
                    "PRN","TO","CAB","CAN",
                    "BOX")
  then CMDOSU = "";

  else do;
    CMDOSU = "";
  end;

  drop _unit;

run;

/*------------------------------------------------------------------------------------------  */

/*------------------------------------------------------------------------------------------  */
/* ROUTE  */
/*------------------------------------------------------------------------------------------  */

DATA CM_2;
SET CM_1;
LENGTH CMROUTE $ 25. CMENRF $ 10.;

IF NOT MISSING(TRTRTE) THEN DO;
	IF TRTRTE = "Dermal" THEN CMROUTE = "TOPICAL";
	ELSE IF TRTRTE = "Oral" THEN CMROUTE = "ORAL";
	ELSE IF TRTRTE = "Inhalations" THEN CMROUTE = "RESPIRATORY (INHALATION)";
	ELSE IF TRTRTE = "Rectal" THEN CMROUTE = "RECTAL";
	ELSE IF TRTRTE = "s.c." THEN CMROUTE = "SUBCUTANEOUS";
	ELSE IF TRTRTE = "i.v." THEN CMROUTE = "INTRAVENOUS";
	ELSE IF TRTRTE = "i.m." THEN CMROUTE = "INTRAMUSCULAR";
	ELSE IF TRTRTE = "Other" THEN CMROUTE = "";
END;
ELSE CMROUTE = "";

/*INDICATION / CMINDC  */

CMINDC = STRIP(INDICA);

/*------------------------------------------------------------------------------------------  */
/*CMENRF  */
/*------------------------------------------------------------------------------------------  */

IF STRIP(UPCASE(CONT))="YES" THEN CMENRF = "ONGOING";
ELSE CMENRF = "";

/*------------------------------------------------------------------------------------------  */
/*CMSTDTC */
/*------------------------------------------------------------------------------------------  */

IF STARTDTS  NE "******" THEN DO;
CMSTDTC = STRIP(STARTDTS);
END;
ELSE CMSTDTC = "";

/*------------------------------------------------------------------------------------------  */
/*CMENDTC  */
/*------------------------------------------------------------------------------------------  */

IF ENDDTS  NE "******" THEN DO;
CMENDTC = STRIP(ENDDTS);
END;
ELSE CMENDTC = "";

RUN;

/*------------------------------------------------------------------------------------------  */
/* RELATIVE DAY */
/*------------------------------------------------------------------------------------------  */

PROC SQL NOPRINT;
CREATE TABLE CM_DATE AS
SELECT A.*,B.RFSTDTC
FROM CM_2 A 
LEFT JOIN GASTI_F.DM B
ON A.USUBJID = B.USUBJID;
QUIT;

DATA CM_DAY;
SET CM_DATE;

IF LENGTH(RFSTDTC) = 10 THEN 
RFDATE = INPUT(RFSTDTC,YYMMDD10.);

IF LENGTH(CMSTDTC) = 10 THEN 
CMSTDATE = INPUT(CMSTDTC,YYMMDD10.);

IF LENGTH(CMENDTC) = 10 THEN 
CMENDATE = INPUT(CMENDTC,YYMMDD10.);

/*CMSTDY  */
IF CMSTDATE GE RFDATE THEN CMSTDY = CMSTDATE - RFDATE + 1;
ELSE CMSTDY = CMSTDATE - RFDATE;

/* CMENDY */

IF CMENDATE GE RFDATE THEN CMENDY = CMENDATE - RFDATE + 1;
ELSE CMENDY = CMENDATE - RFDATE;

RUN;

/*------------------------------------------------------------------------------------------  */

PROC SORT DATA=CM_DAY
SORTSEQ=LINGUISTIC(NUMERIC_COLLATION=ON);
BY USUBJID;
RUN;

/*------------------------------------------------------------------------------------------  */
/*------------------------------------------------------------------------------------------  */
DATA CM_FINAL;
SET CM_DAY;
BY USUBJID;

/*------------------------------------------------------------------------------------------  */
/*CMSEQ  */
/*------------------------------------------------------------------------------------------  */
IF FIRST.USUBJID THEN CMSEQ=1;
ELSE CMSEQ+1;

/*------------------------------------------------------------------------------------------  */
KEEP 
STUDYID
DOMAIN
USUBJID
CMSEQ
CMTRT
CMDECOD
CMDOSE
CMDOSU
CMROUTE
CMINDC
CMENRF
CMSTDTC
CMENDTC
CMSTDY
CMENDY;
/*------------------------------------------------------------------------------------------  */

RUN;
/*------------------------------------------------------------------------------------------  */

/*------------------------------------------------------------------------------------------  */
PROC SQL NOPRINT;
CREATE TABLE CM AS
SELECT 
	STUDYID LABEL= "Study Identifier" 							LENGTH=15,
	DOMAIN	LABEL= "Domain Abbreviation"						LENGTH=2,
	USUBJID	LABEL= "Unique Subject Identifier"					LENGTH=18,
	CMSEQ	LABEL= "Sequence Number"							LENGTH=8,
	CMTRT	LABEL= "Reported Name of Drug, Med, or Therapy"		LENGTH=50,
	CMDECOD	LABEL= "Standardized Medication Name"				LENGTH=50,
	CMINDC	LABEL= "Indication"									LENGTH=20,
	CMDOSE	LABEL= "Dose per Administration"					LENGTH=8,
	CMDOSU	LABEL= "Dose Units"									LENGTH=22,
	CMROUTE	LABEL= "Route of Administration"					LENGTH=30,
	CMSTDTC	LABEL= "Start Date/Time of Medication"				LENGTH=10,
	CMENDTC	LABEL= "End Date/Time of Medication"				LENGTH=10,
	CMSTDY	LABEL= "Study Day of Start of Medication"			LENGTH=8,
	CMENDY	LABEL= "Study Day of End of Medication"				LENGTH=8,
	CMENRF	LABEL= "End Relative to Reference Period"			LENGTH=12
	
FROM CM_FINAL;
QUIT;
/*------------------------------------------------------------------------------------------  */


/*------------------------------------------------------------------------------------------  */
/*FINAL SAS DATA  */
/*------------------------------------------------------------------------------------------  */	

	LIBNAME GASTI_F "/home/u64240743/gastric/GASTRIC SDTM RESULT";
	DATA GASTI_F.CM;
	SET CM;
	RUN;


/*------------------------------------------------------------------------------------------  */
/* EXPORT AS XPT FORMAT */
/*------------------------------------------------------------------------------------------  */
	LIBNAME XPTFILE XPORT "/home/u64240743/gastric/GASTRIC_XPT/CM.XPT";
	PROC COPY IN=gasti_f OUT=XPTFILE;
	SELECT CM;
	RUN;
	
/*------------------------------------------------------------------------------------------  */


