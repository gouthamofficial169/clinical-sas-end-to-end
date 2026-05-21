/*****************************************************************************
* Filename    : adcm.sas
* Author      : Goutham
* Date        : &sysdate9.
* SAS Version : SAS 9.4 (SAS ODA)
* Platform    : Linux (SAS OnDemand Cloud)
* Project     : EMR200048052 — EXPAND Trial
* Description : Create ADaM ADAE — Adverse Events Analysis Dataset
*               OCCDS structure per ADaMIG v1.3
*               Key derivations: TRTEMFL ASTDT AENDT ADURN ANL01FL
* Input       : GASTI_F.CM (SDTM Concomitant Medication Domain)
*               GASTI_AD.ADSL  (Subject Level Analysis Dataset)
* Output      : GASTI_AD.ADCM (Concomitant Medication Analysis Dataset)
* Standards   : ADaMIG v1.3 | CDISC CT 2026-03-27
*****************************************************************************
* MODIFICATION HISTORY
* Date          Author    Description
* -----------   --------  --------------------------------------------------
* &sysdate9.    Goutham   Initial creation
*****************************************************************************/


/*--------------------------------------------------------------------------------------------- */
/*ASSIGN THE LIBRARY  */
/*------------------------------------------------------------------------------------------- */
LIBNAME GASTI_F "/home/u64240743/gastric/GASTRIC SDTM RESULT";
RUN;
LIBNAME GASTI_AD "/home/u64240743/gastric/GASTRIC ADAM";
RUN;
/*-------------------------------------------------------------------------------------------- */


/*-----------------------------------------------------------------------------------------*/
/*READ AND PROCESS INPUT DATASETS  */
/*-----------------------------------------------------------------------------------------*/

PROC SORT DATA=GASTI_AD.ADSL OUT=ADSL01_CM
SORTSEQ=LINGUISTIC(NUMERIC_COLLATION=ON);
	BY USUBJID STUDYID;
RUN;
/*------------------------------------------------------------------------------------------  */
/*------------------------------------------------------------------------------------------  */
PROC SORT DATA=GASTI_F.CM OUT=CM_SORT
SORTSEQ=LINGUISTIC(NUMERIC_COLLATION=ON);
	BY USUBJID STUDYID;
RUN;
/*-----------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*/
DATA ADCMO1;
	MERGE ADSL01_CM(IN=A) CM_SORT(IN=B);
	BY USUBJID STUDYID;
	IF A AND B;
/*-----------------------------------------------------------------------------------------*/
/* CREATE A DERIVED VARIABLES*/
/*-----------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------------  */
/*TIMING VARIABLES */
/*------------------------------------------------------------------------------------------  */
/*------------------------------------------------------------------------------------------  */
/* ASTDT/ASTDTF*/
/*------------------------------------------------------------------------------------------  */
	FORMAT ASTDT TEMPDT1 DATE9.;
	IF LENGTH(CMSTDTC)=10 THEN DO;
		ASTDT = INPUT(CMSTDTC,??YYMMDD10.);
	END;
	ELSE IF MISSING(CMSTDTC) THEN DO;
		ASTDT = TRTSDT;
		ASTDTF = "Y";
	END;
	
	ELSE IF LENGTH(CMSTDTC) = 7 THEN DO;
		TEMPDT1 = INPUT(CATS(CMSTDTC,"-01"),??YYMMDD10.);
		
		IF MONTH(TEMPDT1) = MONTH(TRTSDT) AND YEAR(TEMPDT1)=YEAR(TRTSDT)
		THEN ASTDT = TRTSDT;
		ELSE ASTDT = TEMPDT1;
		ASTDTF = "D";
	END;
	
	ELSE IF LENGTH(CMSTDTC) = 4 THEN DO;
		ASTDT = INPUT(CATS(CMSTDTC,"-01-01"),??YYMMDD10.);
		ASTDTF = "M";
	END;
/*------------------------------------------------------------------------------------------  */
/*AENDT/AENDTF  */
/*------------------------------------------------------------------------------------------  */
	FORMAT AENDT DATE9.;
	IF LENGTH(CMENDTC)=10 THEN DO;
		AENDT = INPUT(CMENDTC,??YYMMDD10.);
	END;
	ELSE IF MISSING(CMENDTC) THEN DO;
		IF TRTEDT < ASTDT THEN AENDT = ASTDT; /*IF TREATMENT END DATE LESS THEN CM START DATE THEN CM START DATE = CM END DATE */
	ELSE 
		AENDT = TRTEDT;
		AENDTF = "Y";
	END;
		
	ELSE IF LENGTH(CMENDTC) = 7 THEN DO;
		AENDT = INPUT(CATS(CMENDTC,"-01"),??YYMMDD10.);
		AENDTF = "D";
	END;
	
	ELSE IF LENGTH(CMENDTC) = 4 THEN DO;
		AENDT = INPUT(CATS(CMENDTC,"-01-01"),??YYMMDD10.);
		AENDTF = "M";
	END;
/*------------------------------------------------------------------------------------------  */
/*ASTDY ANALYSIS START RELATIVE DAY  */
/*------------------------------------------------------------------------------------------  */
	IF ASTDT GE TRTSDT THEN ASTDY = ASTDT-TRTSDT + 1 ; 
	ELSE ASTDY = ASTDT-TRTSDT ;
/*------------------------------------------------------------------------------------------  */
/*AENDY ANALYSIS END RELATIVE DAY  */
/*------------------------------------------------------------------------------------------  */
	IF AENDT GE TRTSDT THEN AENDY = AENDT-TRTSDT + 1 ; 
	ELSE AENDY = AENDT-TRTSDT ;
	
/*------------------------------------------------------------------------------------------  */
/* ONTRTFL/PREFL */
/*------------------------------------------------------------------------------------------  */

	IF . LT AENDT LT TRTSDT THEN PREFL = "Y";
	
	IF (. LT TRTSDT LE ASTDT LE TRTEDT) OR 
	   (. LT TRTSDT LE AENDT LE TRTEDT) OR
	   (. LT ASTDT LT TRTSDT AND AENDT GT TRTEDT GT .)
	   THEN ONTRTFL = "Y";
	   
/*------------------------------------------------------------------------------------------  */
/*TREATMENT VARIABLE  */
/*------------------------------------------------------------------------------------------  */

TRTAN = TRT01AN;
TRTA = TRT01A;

RUN;
/*------------------------------------------------------------------------------------------  */

/*------------------------------------------------------------------------------------------  */
/*KEEP ONLY REQUIRED VARIABLE AND SORT THE FINAL DATASET  */
/*------------------------------------------------------------------------------------------  */

DATA ADCM02;
SET ADCMO1;

KEEP 
STUDYID
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
ASTDT
ASTDTF
ASTDY
CMENDTC
AENDT
AENDTF
AENDY
ONTRTFL
PREFL
SAFFL
ITTFL
TRTA
TRTAN
TRTSDT
TRTEDT
AGE
AGEGR1
SEX
RACE;

RUN;
/*------------------------------------------------------------------------------------------  */

/*------------------------------------------------------------------------------------------  */
PROC SQL;
CREATE TABLE ADCM AS
	SELECT 
		STUDYID	LABEL= "Study Identifier" 							LENGTH=15,
		USUBJID	LABEL= "Unique Subject Identifier" 					LENGTH=18,
		CMSEQ	LABEL= "Sequence Number"							LENGTH=8,
		CMTRT	LABEL= "Reported Name of Drug, Med, or Therapy"		LENGTH=50,
		CMDECOD	LABEL= "Standardized Medication Name"				LENGTH=50,
		CMINDC	LABEL= "Indication"									LENGTH=20,
		CMDOSE	LABEL= "Dose per Administration"					LENGTH=8,
		CMDOSU	LABEL= "Dose Units"									LENGTH=22,
		CMROUTE	LABEL= "Route of Administration"					LENGTH=30,
		CMENRF	LABEL= "End Relative to Reference Period"			LENGTH=12,
		CMSTDTC	LABEL= "Start Date/Time of Medication"				LENGTH=10,
		ASTDT 	LABEL= "Analysis Start Date"						LENGTH=8,
		ASTDTF  LABEL= "Analysis Start Date Imputation Flag "		LENGTH=1,
		ASTDY   LABEL= "Analysis Start Relative Day "				LENGTH=4,
		CMENDTC	LABEL= "End Date/Time of Medication"				LENGTH=10,
		AENDT  	LABEL= "Analysis End Date"							LENGTH=8,
		AENDTF  LABEL= "Analysis End Date Imputation Flag "			LENGTH=1,
		AENDY   LABEL= "Analysis End Relative Day"					LENGTH=4,
		ONTRTFL LABEL= "On Treatment Record Flag"					LENGTH=1,
		PREFL   LABEL= "Pre-treatment Flag"							LENGTH=1,
		SAFFL	LABEL= "Safety Population Flag"						LENGTH=1,
		ITTFL	LABEL= "Intent-To-Treat Population Flag"			LENGTH=1,
		TRTA	LABEL= "Actual Treatment"							LENGTH=30,
		TRTAN	LABEL= "Actual Treatment (N)"						LENGTH=8,
		TRTSDT	LABEL= "Date of First Exposure to Treatment" 		LENGTH=8,
		TRTEDT	LABEL= "Date of Last Exposure to Treatment" 		LENGTH=8,
		AGE		LABEL= "Age"										LENGTH=3,
		AGEGR1	LABEL= "Pooled Age Group 1"							LENGTH=10,
		SEX		LABEL= "Sex"										LENGTH=2,
		RACE	LABEL= "Race"										LENGTH=30
		
FROM ADCM02;
QUIT;

/*------------------------------------------------------------------------------------------  */
/*FINAL SAS DATA  */
/*------------------------------------------------------------------------------------------  */	

	LIBNAME GASTI_AD "/home/u64240743/gastric/GASTRIC ADAM";
	
	DATA GASTI_AD.ADCM;
	SET ADCM ;
	RUN;

/*------------------------------------------------------------------------------------------  */
/* EXPORT AS XPT FORMAT */
/*------------------------------------------------------------------------------------------  */
	LIBNAME XPTFILE XPORT "/home/u64240743/gastric/GASTRIC_XPT/ADCM.XPT";
	PROC COPY IN=GASTI_AD OUT=XPTFILE;
	SELECT ADCM;
	RUN;
	
/*------------------------------------------------------------------------------------------  */


   
	