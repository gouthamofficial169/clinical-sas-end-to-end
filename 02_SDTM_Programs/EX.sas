/*------------------------------------------------------------------------------------------  */
/*****************************************************************************
 * Filename    : EX.sas
 * Author      : Goutham
 * Date        : &sysdate9.
 * SAS Version : SAS 9.4 (SAS ODA)
 * Platform    : Linux (SAS OnDemand Cloud)
 * Project     : EMR200048052 — EXPAND Trial
 * Description : Create SDTM EX — Exposure Domain
 *               following SDTM IG v3.4
 * Input       : GASTRIC.DACA
 				 GASTRIC.DACI
 * Output      : GASTI_F.EX (Exposure Domain)
 * Standards   : SDTM IG v3.4 | CDISC CT 2026-03-27
 *****************************************************************************
 * MODIFICATION HISTORY
 * Date          Author    Description
 * -----------   --------  --------------------------------------------------
 * &sysdate9.    Goutham   Initial creation
 *****************************************************************************/


/*--------------------------------------------------------------------------------------------- */
/*ASSIGN THE LIBRARY  */
/*----------------------------------------------------------------------------------------  */
LIBNAME GASTRIC "/home/u64240743/gastric";
RUN;

/*-------------------------------------------------------------------------------------------- */
/*FIRST DONE THE DACA(CAPECITABINE) DATASET*/
/*----------------------------------------------------------------------------------------  */
DATA EX_DACA;
SET GASTRIC.DACA;
LENGTH EXTRT $ 20. EXCAT $ 20. EXDOSFRM $ 20.  EXROUTE $ 15.;
	
/*IDENTIFIER VARIABLE */

STUDYID = STRIP(STUDY);

USUBJID = STRIP(CATX("-",STUDY,PT));

DOMAIN = "EX";
/*----------------------------------------------------------------------------------------  */
/* DOSE */
/*----------------------------------------------------------------------------------------  */
EXDOSE = DOSE;

IF EXDOSE NE . THEN EXDOSU = "mg/m2";

IF EXDOSE NE . THEN EXDOSFRM = "TABLET";

/*----------------------------------------------------------------------------------------  */
/* TREATMENT VARIABLE */
/*----------------------------------------------------------------------------------------  */
IF EXDOSE NE . THEN EXTRT = "CAPECITABINE";

IF EXTRT NE "" THEN EXCAT = "CHEMOTHERAPY";


/*----------------------------------------------------------------------------------------  */
/* ROUTE OF ADMINISTARTION */
/*----------------------------------------------------------------------------------------  */
IF EXDOSE NE . THEN EXROUTE = "ORAL";

/*----------------------------------------------------------------------------------------  */
/*EXPOSURE START AND END DATE TIME VARIABLES  */
/*----------------------------------------------------------------------------------------  */
IF FIRSTDT AND LASTDT NE . THEN DO;
EXSTDTC = STRIP(PUT(FIRSTDT,E8601DA10.));

EXENDTC = STRIP(PUT(LASTDT,E8601DA10.));
END;
ELSE DO EXSTDTC="";
EXENDTC = "";
END;


KEEP STUDYID DOMAIN USUBJID EXTRT EXCAT EXDOSE EXDOSU EXDOSFRM EXROUTE EXSTDTC
EXENDTC ;

RUN;

/*-------------------------------------------------------------------------------------------- */
/*DACI (CISPLATIN) DATASET*/
/*----------------------------------------------------------------------------------------  */

DATA EX_DACI;
SET GASTRIC.DACI;
LENGTH EXTRT $ 20. EXCAT $ 20. EXDOSFRM $ 20. EXROUTE $ 15.;
	
/*IDENTIFIER VARIABLE */

STUDYID = STRIP(STUDY);

USUBJID = STRIP(CATX("-",STUDY,PT));

DOMAIN = "EX";
/*----------------------------------------------------------------------------------------  */
/* DOSE */
/*----------------------------------------------------------------------------------------  */
EXDOSE = DOSE;

IF EXDOSE NE . THEN EXDOSU = "mg/m2";

IF EXDOSE NE . THEN EXDOSFRM = "INJECTION";

/*----------------------------------------------------------------------------------------  */
/* TREATMENT VARIABLE */
/*----------------------------------------------------------------------------------------  */
IF EXDOSE NE . THEN EXTRT = "CISPLATIN";

IF EXTRT NE "" THEN EXCAT = "CHEMOTHERAPY";


/*----------------------------------------------------------------------------------------  */
/* ROUTE OF ADMINISTARTION */
/*----------------------------------------------------------------------------------------  */
IF EXDOSE NE . THEN EXROUTE = "INTRAVENOUS";

/*----------------------------------------------------------------------------------------  */
/*EXPOSURE START AND END DATE TIME VARIABLES  */
/*----------------------------------------------------------------------------------------  */
IF NOT MISSING(INFUSDT) AND NOT MISSING(INFUSTMC) THEN DO
EXSTDTC = CATX("T",STRIP(PUT(INFUSDT,E8601DA10.)),STRIP(INFUSTMC));END;
ELSE DO;EXSTDTC = "";END;

EXENDTC = "";
KEEP STUDYID DOMAIN USUBJID EXTRT EXCAT EXDOSE EXDOSU EXDOSFRM EXROUTE EXSTDTC
EXENDTC ;

RUN;

/*------------------------------------------------------------------------------------------  */
/*COMBINNE DATASET CAPECITTABINE AND CISPLATIN DATASET */
/*------------------------------------------------------------------------------------------  */

DATA EX_1;
SET EX_DACA EX_DACI;
RUN;

PROC SORT DATA=EX_1 OUT=EX_2
SORTSEQ=LINGUISTIC(NUMERIC_COLLATION=ON);
BY USUBJID;
RUN;

/*------------------------------------------------------------------------------------------- */
/*GET RFSTDTC FROM DM DOMAIN */
/*------------------------------------------------------------------------------------------- */

PROC SQL ;
CREATE TABLE EX_FINAL1 AS 
SELECT A.*, B.RFSTDTC,B.RFENDTC
FROM EX_2 A
LEFT JOIN DM B
ON A.USUBJID = B.USUBJID;
QUIT;

/*------------------------------------------------------------------------------------------- */
/*CREATE A DAY VARIABLE  */
/*------------------------------------------------------------------------------------------- */

PROC SORT DATA=EX_FINAL1 OUT=EX_3
SORTSEQ=LINGUISTIC(NUMERIC_COLLATION=ON);
BY USUBJID;
RUN;

DATA EX_4;
SET EX_3;
BY USUBJID;
/* DERIVE SEQUENCE NUMBER */
IF FIRST.USUBJID THEN EXSEQ=1;
ELSE EXSEQ+1;

/* DERIVE EXSTDY */
/* CONVERT CHAR TO NUM USING THE INPUT()  */
EXDATE = INPUT(EXSTDTC, YYMMDD10.);
RFDATE = INPUT(RFSTDTC, YYMMDD10.);
EXENDATE = INPUT(EXENDTC, YYMMDD10.);

IF NOT MISSING(EXDATE) AND NOT MISSING(RFDATE) THEN DO;
    IF EXDATE >= RFDATE THEN EXSTDY = EXDATE - RFDATE + 1;
    ELSE EXSTDY = EXDATE - RFDATE;
END;


IF NOT MISSING(EXENDATE) AND NOT MISSING(RFDATE) THEN DO;
    IF EXENDATE >= RFDATE THEN EXENDY = EXENDATE - RFDATE + 1;
    ELSE EXENDY = EXENDATE - RFDATE;
END;

IF CMISS(EXCAT,EXTRT,EXDOSE,EXDOSU,EXDOSFRM,EXROUTE,EXSTDTC,EXENDTC,EXSTDY,EXENDY)=10 THEN DELETE;

KEEP 

	STUDYID
	DOMAIN
	USUBJID
	EXSEQ
	EXTRT
	EXCAT
	EXDOSE
	EXDOSU
	EXDOSFRM
	EXROUTE
	EXSTDTC
	EXENDTC
	EXSTDY
	EXENDY;

RUN;

PROC SORT DATA=EX_4 NODUPKEY DUPOUT=DUP OUT=EX_FINAL;
BY USUBJID EXTRT EXCAT EXROUTE EXSTDTC EXENDTC;
RUN;

PROC SORT DATA=EX_FINAL 
SORTSEQ=LINGUISTIC(NUMERIC_COLLATION=ON);
BY USUBJID EXTRT EXCAT EXROUTE EXSTDTC EXENDTC;
RUN;

/* ----------------------------------------------------------------------------------------- */
/*ASSIGN THE LABEL FOR ALL VARIABLE  */
/*------------------------------------------------------------------------------------------  */
PROC SQL NOPRINT;
	CREATE TABLE EX AS 
	SELECT 
			STUDYID  LABEL= "Study Identifier" LENGTH=15,

			DOMAIN   LABEL= "Domain Abbreviation" LENGTH=2,
				
			USUBJID	 LABEL= "Unique Subject Identifier" LENGTH=18,
				
			EXSEQ	LABEL= "Sequence Number" LENGTH=8,
			
			EXTRT	LABEL= "Name of Treatment" LENGTH=17,
			
			EXCAT	LABEL= "Category of Treatment" LENGTH=17,

			EXDOSE	LABEL= "Dose" LENGTH=8,

			EXDOSU	LABEL= "Dose Units" LENGTH=8,
			
			EXDOSFRM	LABEL= "Dose Form" LENGTH=17,

			EXROUTE	LABEL= "Route of Administration" LENGTH=17,
			
			EXSTDTC	LABEL= "Start Date/Time of Treatment" LENGTH=14,
			
			EXENDTC	LABEL= "End Date/Time of Treatment" LENGTH=14,
			
			EXSTDY	LABEL= "Study Day of Start of Treatment" LENGTH=8,
			
			EXENDY  LABEL= "Study Day of End of Treatment"	LENGTH=8
FROM EX_FINAL;
QUIT;

/*------------------------------------------------------------------------------------------- */
/*FINAL DATA  */
/*------------------------------------------------------------------------------------------- */
	
LIBNAME GASTI_F "/home/u64240743/gastric/GASTRIC SDTM RESULT";
	
DATA GASTI_F.EX (LABEL="Exposure");
SET EX;
RUN;
			
/*------------------------------------------------------------------------------------------- */
/* EXPORT AS XPT FORMAT */
/*------------------------------------------------------------------------------------------- */

LIBNAME XPTFILE XPORT "/home/u64240743/gastric/GASTRIC_XPT/EX.XPT";
PROC COPY IN=gasti_f OUT=XPTFILE;
SELECT EX;
RUN;
	
/*------------------------------------------------------------------------------------------- */
			
			
			
			
			

