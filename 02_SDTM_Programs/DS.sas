/*------------------------------------------------------------------------------------------  */
/*****************************************************************************
 * Filename    : DS.sas
 * Author      : Goutham
 * Date        : &sysdate9.
 * SAS Version : SAS 9.4 (SAS ODA)
 * Platform    : Linux (SAS OnDemand Cloud)
 * Project     : EMR200048052 — EXPAND Trial
 * Description : Create SDTM DS — Disposition Domain
 *               following SDTM IG v3.4
 * Input       : GASTRIC.DISC (Raw Disposition)
 * Output      : GASTI_F.DS (Disposition Domain)
 * Standards   : SDTM IG v3.4 | CDISC CT 2026-03-27
 *****************************************************************************
 * MODIFICATION HISTORY
 * Date          Author    Description
 * -----------   --------  --------------------------------------------------
 * &sysdate9.    Goutham   Initial creation
 *****************************************************************************/

/*------------------------------------------------------------------------------------------  */
/*IMPORT THE LIBRARY  */
/*------------------------------------------------------------------------------------------  */
LIBNAME GASTRIC "/home/u64240743/gastric";
RUN;
LIBNAME GASTI_F "/home/u64240743/gastric/GASTRIC SDTM RESULT";
RUN;
/*---------------------------------------------------------------------------------------------------  */
/*COMBINE THE DIFFRENT PROTOCOL MILESTONE DATASET   */
/*------------------------------------------------------------------------------------------  */
DATA DS_PROTO;
MERGE GASTRIC.CONS GASTRIC.IVRS GASTRIC.RAND;
RUN;
/*---------------------------------------------------------------------------------------------------  */

DATA DS_PROTO_1;
SET DS_PROTO;
LENGTH DSTERM $ 30. DSDECOD $ 30. DSCAT $ 20.;

STUDYID= STRIP(STUDY);
USUBJID= CATX("-",STUDYID,PT);

/*INFORMED CONSENT  */
IF NOT MISSING(INFCSDT) THEN DO;
	DSCAT= "PROTOCOL MILESTONE";
	DSTERM= "INFORMED CONSENT";
	DSDECOD= "INFORMED CONSENT OBTAINED";
	DSSTDTC= PUT(INFCSDT,E8601DA10.);
	OUTPUT;
END;

/*RANDOMIZATION  */
IF NOT MISSING(IVRSDT) THEN DO;
	DSCAT= "PROTOCOL MILESTONE";
	DSTERM= "RANDOMIZATION";
	DSDECOD= "RANDOMIZED";
	DSSTDTC= PUT(IVRSDT,E8601DA10.);
	OUTPUT;
END;

KEEP PT STUDYID USUBJID DSTERM DSCAT DSDECOD DSSTDTC;

RUN;

/*------------------------------------------------------------------------------------------  */
/*PERFORM DISPOSITION EVENT USING DISC DATASET  */
/*------------------------------------------------------------------------------------------  */
DATA DS_2;
SET GASTRIC.DISC;
LENGTH DSTERM $ 30. DSDECOD $ 30. DSCAT $ 20. DSSCAT $ 30. EPOCH $ 20.;


STUDYID= STRIP(STUDY);
USUBJID= CATX("-",STUDYID,PT);

/*------------------------------------------------------------------------------------------  */
/* ASSIGN THE VERBATIM */
/*------------------------------------------------------------------------------------------  */

DSTERM = UPCASE(STRIP(REASON));

SELECT (UPCASE(STRIP(REASON)));
	WHEN ("ADVERSE EVENT") DSDECOD= "ADVERSE EVENT";
	WHEN ("DEATH") DSDECOD= "DEATH";
	WHEN ("LOST TO FOLLOW UP") DSDECOD= "LOST TO FOLLOW-UP";
	WHEN ("OTHER") DO; DSTERM= "OTHER REASON NOT SPECIFIED" ;DSDECOD= "OTHER EVENT";END;
	WHEN ("PROGRESSIVE DISEASE") DSDECOD= "PROGRESSIVE DISEASE";
	WHEN ("PROTOCOL NON COMPLIANCE") DSDECOD= "PROTOCOL VIOLATION";
	WHEN ("SYMPTOMATIC DETERIORATION") DSDECOD= "PROGRESSIVE DISEASE";
	WHEN ("WITHDREW CONSENT") DSDECOD= "WITHDRAWAL BY SUBJECT";
	WHEN ("COMPLETED") DSDECOD= "COMPLETED";
	OTHERWISE DO;
	DSDECOD = "OTHER EVENT";
	DSTERM = "UNSPECIFIED REASON"; END;
END;
	DSCAT= "DISPOSITION EVENT";
	DSSTDTC= PUT(OFFDT,YYMMDD10.); 
        
OUTPUT;

KEEP PT STUDYID USUBJID DSTERM DSCAT DSDECOD DSSTDTC;
RUN;

/*------------------------------------------------------------------------------------------  */
/* COMBINE DATASET OF PROTOCOL MILESTONE AND DISPOSITION EVENT */
/*------------------------------------------------------------------------------------------  */
DATA DS_F1;
SET ds_proto_1 DS_2;
OUTPUT;
RUN;

PROC SORT DATA=DS_F1 OUT=DS_F2
SORTSEQ=LINGUISTIC(NUMERIC_COLLATION=ON);
BY PT USUBJID DSCAT ;
RUN;

/*------------------------------------------------------------------------------------------  */
/* DISPOSITION SEQUENCE NUMBER */
/*------------------------------------------------------------------------------------------  */
DATA DS_SEQ;
SET DS_F2;
BY USUBJID;

IF FIRST.USUBJID THEN DSSEQ=1;
ELSE DSSEQ+1;
DROP PT;
RUN;

/*------------------------------------------------------------------------------------------  */
/* Study Day of Start of Disposition Event */
/*------------------------------------------------------------------------------------------  */

PROC SQL ;
CREATE TABLE DS_FINAL1 AS 
SELECT A.*, B.RFSTDTC
FROM DS_SEQ A
LEFT JOIN GASTI_F.DM B
ON A.USUBJID = B.USUBJID;
QUIT;

DATA DS_FINAL2;
SET DS_FINAL1;
LENGTH EPOCH $ 20.;
DOMAIN= "DS";
DSDATE = INPUT(DSSTDTC, E8601DA10.);
RFDATE = INPUT(RFSTDTC, E8601DA10.);

IF NOT MISSING(DSDATE) AND NOT MISSING(RFDATE) THEN DO;
    IF DSDATE >= RFDATE THEN DSSTDY = DSDATE - RFDATE + 1;
    ELSE DSSTDY = DSDATE - RFDATE;
END;

/*------------------------------------------------------------------------------------------  */
/*EPOCH VARIABLE  */
/*------------------------------------------------------------------------------------------  */
IF DSTERM IN ("SCREENING","INFORMED CONSENT") THEN EPOCH="SCREENING";
ELSE EPOCH="TREATMENT";



DROP RFSTDTC DSDATE RFDATE;
RUN;

PROC SORT DATA=DS_FINAL2 OUT=DS_FINAL3
SORTSEQ=LINGUISTIC(NUMERIC_COLLATION=ON);
BY USUBJID DSSEQ DSTERM;
RUN;
/*------------------------------------------------------------------------------------------  */

/*------------------------------------------------------------------------------------------  */
/* ASSIGN THE VARIABLE LENGTH AAND LABEL */
/*------------------------------------------------------------------------------------------  */
PROC SQL NOPRINT;
CREATE TABLE DS AS 
SELECT 
		STUDYID 	LABEL= "Study Identifier" LENGTH=15,
		
		DOMAIN		LABEL= "Domain Abbreviation" LENGTH=2,
		
		USUBJID		LABEL= "Unique Subject Identifier" LENGTH=17,
		
		DSSEQ		LABEL= "Sequence Number" LENGTH=8,

		DSTERM		LABEL= "Reported Term for the Disposition Event" LENGTH=30,

		DSDECOD		LABEL= "Standardized Disposition Term" LENGTH=30,
		
		DSCAT		LABEL= "Category for Disposition Event" LENGTH=21,
		
		EPOCH	    LABEL= "Epoch" LENGTH=15,

		DSSTDTC		LABEL= "Start Date/Time of Disposition Event" LENGTH=15,
		
		DSSTDY		LABEL= "Study Day of Start of Disposition Event" LENGTH=5

FROM DS_FINAL3;
QUIT;

/*------------------------------------------------------------------------------------------  */
/*FINAL SAS DATA  */
/*------------------------------------------------------------------------------------------  */

	LIBNAME GASTI_F "/home/u64240743/gastric/GASTRIC SDTM RESULT";
	DATA GASTI_F.DS (LABEL="Disposition");
	SET DS ;
	RUN;
/*------------------------------------------------------------------------------------------  */
/* EXPORT AS XPT FORMAT */
/*------------------------------------------------------------------------------------------  */
	
	LIBNAME XPTFILE XPORT "/home/u64240743/gastric/GASTRIC_XPT/DS.XPT";
	PROC COPY IN=gasti_f OUT=XPTFILE;
	SELECT DS;
	RUN;
/*------------------------------------------------------------------------------------------  */


