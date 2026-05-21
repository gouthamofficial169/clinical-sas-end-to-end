/*****************************************************************************
* Filename    : adae.sas
* Author      : Goutham
* Date        : &sysdate9.
* SAS Version : SAS 9.4 (SAS ODA)
* Platform    : Linux (SAS OnDemand Cloud)
* Project     : EMR200048052 — EXPAND Trial
* Description : Create ADaM ADAE — Adverse Events Analysis Dataset
*               OCCDS structure per ADaMIG v1.3
*               Key derivations: TRTEMFL ASTDT AENDT ADURN ANL01FL
* Input       : GASTI_F.AE (SDTM Adverse Events Domain)
*               GASTI_AD.ADSL  (Subject Level Analysis Dataset)
* Output      : GASTI_AD.ADAE (Adverse Events Analysis Dataset)
* Standards   : ADaMIG v1.3 | CDISC CT 2026-03-27
*****************************************************************************
* MODIFICATION HISTORY
* Date          Author    Description
* -----------   --------  --------------------------------------------------
* &sysdate9.    Goutham   Initial creation
*****************************************************************************/

/*-----------------------------------------------------------------------------------------*/
/* IMPORT THE ADAM PROGRAMMING FILE LIBRARY */
/*-----------------------------------------------------------------------------------------*/
LIBNAME GASTI_F "/home/u64240743/gastric/GASTRIC SDTM RESULT";
RUN;

LIBNAME GASTI_AD "/home/u64240743/gastric/GASTRIC ADAM";
RUN;
/*-----------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*/
/*READ AND PROCESS INPUT DATASETS  */
/*-----------------------------------------------------------------------------------------*/

PROC SORT DATA=GASTI_AD.ADSL OUT=ADSL01_ADAE
SORTSEQ=LINGUISTIC(NUMERIC_COLLATION=ON);
	BY USUBJID STUDYID;
RUN;


PROC SORT DATA=GASTI_F.AE OUT=ADE01_ADAE
SORTSEQ=LINGUISTIC(NUMERIC_COLLATION=ON);
	BY USUBJID STUDYID;
RUN;
/*-----------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*/
DATA ADAEO1;
	MERGE ADSL01_ADAE(IN=A) ADE01_ADAE(IN=B);
	BY USUBJID STUDYID;
	IF A AND B;
/*-----------------------------------------------------------------------------------------*/
/* CREATE A DERIVED VARIABLES*/
/*-----------------------------------------------------------------------------------------*/

/*TIMING VARIABLES */

/* ASTDT/ASTDTF*/
	FORMAT ASTDT TEMPDT DATE9.;
	IF LENGTH(AESTDTC)=10 THEN DO;
		ASTDT = INPUT(AESTDTC,??YYMMDD10.);
	END;
	ELSE IF MISSING(AESTDTC) THEN DO;
		ASTDT = TRTSDT;
		ASTDTF = "Y";
	END;
	
	ELSE IF LENGTH(AESTDTC) = 7 THEN DO;
		TEMPDT = INPUT(CATS(AESTDTC,"-01"),??YYMMDD10.);
		
		IF MONTH(TEMPDT) = MONTH(TRTSDT) AND YEAR(TEMPDT)=YEAR(TRTSDT)
		THEN ASTDT = TRTSDT;
		ELSE ASTDT = TEMPDT;
		ASTDTF = "D";
	END;
	
	ELSE IF LENGTH(AESTDTC) = 4 THEN DO;
		ASTDT = INPUT(CATS(AESTDTC,"-01-01"),??YYMMDD10.);
		ASTDTF = "M";
	END;
	
/*AENDT/AENDTF  */

	FORMAT AENDT DATE9.;
	IF LENGTH(AEENDTC)=10 THEN DO;
		AENDT = INPUT(AEENDTC,??YYMMDD10.);
	END;
	ELSE IF MISSING(AEENDTC) THEN DO;
		IF TRTEDT < ASTDT THEN AENDT = ASTDT; /*IF TREATMENT END DATE LESS THEN AE START DATE THEN AE START DATE = AE END DATE */
	ELSE 
		AENDT = TRTEDT;
		AENDTF = "Y";
	END;
		
	ELSE IF LENGTH(AEENDTC) = 7 THEN DO;
		AENDT = INPUT(CATS(AEENDTC,"-01"),??YYMMDD10.);
		AENDTF = "D";
	END;
	
	ELSE IF LENGTH(AEENDTC) = 4 THEN DO;
		AENDT = INPUT(CATS(AEENDTC,"-01-01"),??YYMMDD10.);
		AENDTF = "M";
	END;
	
/*ASTDY ANALYSIS START RELATIVE DAY  */

	IF ASTDT GE TRTSDT THEN ASTDY = ASTDT-TRTSDT + 1 ; 
	ELSE ASTDY = ASTDT-TRTSDT ;

/*AENDY ANALYSIS END RELATIVE DAY  */

	IF AENDT GE TRTSDT THEN AENDY = AENDT-TRTSDT + 1 ; 
	ELSE AENDY = AENDT-TRTSDT ;
	
	
/*ADURN / ADURU  */

	IF NOT MISSING(ASTDT) AND NOT MISSING(AENDT) THEN 
		ADURN = AENDT - ASTDT + 1;
	ELSE ADURN = .;
	
	ADURU = "DAYS";
	
/*TREATMENT EMERGENT FLAG  */

	IF NOT MISSING(ASTDT) AND ASTDT >= TRTSDT
		THEN TRTEMFL = "Y";
	ELSE TRTEMFL = "";
	
/*PRE-TREATMENT FLAG */
	
	IF NOT MISSING(ASTDT) AND ASTDT < TRTSDT
		THEN PREFL = "Y";
	ELSE PREFL = "";
	
/*ANL01FL — PRIMARY ANALYSIS */

	IF TRTEMFL = "Y" AND SAFFL = "Y" THEN ANL01FL = "Y";
	ELSE ANL01FL = "";

RUN;

/*-------------------------------------------------------------------------------------------------  */
/*VARIABLLES FROM ADSL  */
/*-------------------------------------------------------------------------------------------------  */

/*SUBJECT IDENTIFIERS  */
DATA ADAE02;
	SET ADAEO1;
	
	STUDYID = STRIP(STUDYID);
	
	USUBJID = STRIP(USUBJID);
	
	SUBJID = STRIP(SUBJID);
	
/*TREATMENT VARIABLES  */

	TRTP = STRIP(TRT01P);
	
	TRTPN = TRT01PN;
	
	TRTA = STRIP(TRT01A);
	
	TRTAN = TRT01AN;
	
/* AE DESCRIPTION VARIABLES	 */
	
	AEDECOD = STRIP(AEDECOD);
	
	AEPTCD = STRIP(AEPTCD);
	
	AEBODSYS = STRIP(AEBODSYS);
	
	AEBDSYCD = STRIP(AEBDSYCD);
	
	AELLT = STRIP(AELLT);
	
	AELLTCD = STRIP(AELLTCD);
	
	AEHLT = STRIP(AEHLT);
	
	AEHLGT= STRIP(AEHLGT);
	
	AESOC = STRIP(AESOC);
	
	AESOCCD = STRIP(AESOCCD);
	
	AETERM = STRIP(AETERM);

/*SEVERITY AND GRADE VARIABLES  */

	AESEV = STRIP(AESEV);
	
	AETOXGR = STRIP(AETOXGR);
	
	ATOXGR = INPUT(AETOXGR,BEST.);
	
/*SERIOUS ADVERSE EVENT  */

	AESER = STRIP(AESER);
	
	AEREL = STRIP(AEREL);
	
	AEACN = STRIP(AEACN);
	
/*POPULATION FLAGS FROM ADSL  */
	SAFFL = STRIP(SAFFL);
	
	ITTFL = STRIP(ITTFL);
	
	TRTSDT = TRTSDT;
	
	TRTEDT = TRTEDT;
	
	
/*DEMOGRAPHIC DETAILS  */

	AGE = AGE;
	
	SEX= STRIP(SEX);
	
	RACE = STRIP(RACE);
	
RUN;
	
DATA ADAE03;
	SET ADAE02;
	
	KEEP  ASTDT ASTDTF AENDT AENDTF ASTDY AENDY ADURN ADURU TRTEMFL PREFL
		  ANL01FL STUDYID USUBJID SUBJID TRTP TRTPN TRTA TRTAN AESTDTC AEENDTC AEDECOD AEBODSYS
		  AELLT AEHLT AEHLGT AESOC AETERM AESEV AETOXGR ATOXGR SAFFL ITTFL TRTSDT TRTEDT AESEQ AGE 
		  AGEGR1 SEX RACE AEBDSYCD AEPTCD AESOCCD AELLTCD AESER AEREL AEACN AEOUT;
		  
RUN;	 

PROC SQL;
CREATE TABLE ADAE AS
	SELECT 
		STUDYID	LABEL= "Study Identifier" 					LENGTH=20,
		USUBJID	LABEL= "Unique Subject Identifier" 			LENGTH=20,
		SUBJID	LABEL= "Subject Identifier for the Study" 	LENGTH=5,
		AESEQ	LABEL= "Sequence Number" 					LENGTH=8,
		AGE		LABEL= "Age"								LENGTH=3,
		AGEGR1	LABEL= "Pooled Age Group 1"					LENGTH=10,
		SEX		LABEL= "Sex"								LENGTH=2,
		RACE	LABEL= "Race"								LENGTH=30,
		SAFFL	LABEL= "Safety Population Flag"				LENGTH=1,
		ITTFL	LABEL= "Intent-To-Treat Population Flag"	LENGTH=1,
		TRTP	LABEL= "Planned Treatment"					LENGTH=30,
		TRTPN	LABEL= "Planned Treatment (N)"				LENGTH=8,
		TRTA	LABEL= "Actual Treatment"					LENGTH=30,
		TRTAN	LABEL= "Actual Treatment (N)"				LENGTH=8,
		TRTSDT	LABEL= "Date of First Exposure to Treatment" LENGTH=8,
		TRTEDT	LABEL= "Date of Last Exposure to Treatment" LENGTH=8,
		AETERM	LABEL= "Reported Term for the Adverse Event" LENGTH=30,
		AELLT	 LABEL= "Lowest Level Term" 				LENGTH=30,
		AELLTCD	LABEL= "Lowest Level Term Code" 			LENGTH=8,
		AEDECOD	LABEL= "Dictionary-Derived Term" 			LENGTH=40,
		AEPTCD	LABEL= "Preferred Term Code" 				LENGTH=8,
		AEHLT	LABEL= "High Level Term" 					LENGTH=50,
		AEHLGT	LABEL= "High Level Group Term" 				LENGTH=50,
		AEBODSYS LABEL= "Body System or Organ Class" 		LENGTH=50,
		AEBDSYCD	LABEL= "Body System or Organ Class Code" LENGTH=8,
		AESOC	LABEL= "Primary System Organ Class" 		LENGTH=50,
		AESOCCD	LABEL= "Primary System Organ Class Code" 	LENGTH=8,
		AEACN	LABEL= "Action Taken with Study Treatment"  LENGTH=20,
		AEREL	LABEL= "Causality" 							LENGTH=20,
		AEOUT	LABEL= "Outcome of Adverse Event" 			LENGTH=40,
		AESTDTC	LABEL= "Start Date/Time of Adverse Event" 	LENGTH=13,
		ASTDT 	LABEL= "Analysis Start Date"				LENGTH=8,
		ASTDTF  LABEL= "Analysis Start Date Imputation Flag " LENGTH=1,
		AEENDTC	LABEL= "End Date/Time of Adverse Event" LENGTH=15,
		AENDT  	LABEL= "Analysis End Date"					LENGTH=8,
		AENDTF  LABEL= "Analysis End Date Imputation Flag "	LENGTH=1,
		ASTDY   LABEL= "Analysis Start Relative Day "		LENGTH=4,
		AENDY   LABEL= "Analysis End Relative Day"			LENGTH=4,
		ADURN   LABEL= "Analysis Duration (N) "				LENGTH=4,
		ADURU   LABEL= "Analysis Duration Units"			LENGTH=4,
		ANL01FL	LABEL=	"Analysis Flag 01"					LENGTH=1,
		TRTEMFL LABEL= "Treatment Emergent Analysis Flag "  LENGTH=1,
		PREFL   LABEL= "Pre-treatment Flag"					LENGTH=1,
		AESEV	LABEL= "Severity/Intensity" 				LENGTH=10,
		AESER	LABEL= "Serious Event" 						LENGTH=1,
		AETOXGR	LABEL= "Standard Toxicity Grade" 			LENGTH=1,
		ATOXGR	LABEL= "Analysis Toxicity Grade"			LENGTH=4

FROM ADAE03;
QUIT;

/*------------------------------------------------------------------------------------------  */
/*FINAL SAS DATA  */
/*------------------------------------------------------------------------------------------  */	

	LIBNAME GASTI_AD "/home/u64240743/gastric/GASTRIC ADAM";
	
	DATA GASTI_AD.ADAE;
	SET ADAE ;
	RUN;

/*------------------------------------------------------------------------------------------  */
/* EXPORT AS XPT FORMAT */
/*------------------------------------------------------------------------------------------  */
	LIBNAME XPTFILE XPORT "/home/u64240743/gastric/GASTRIC_XPT/ADAE.XPT";
	PROC COPY IN=GASTI_AD OUT=XPTFILE;
	SELECT ADAE;
	RUN;
	
/*------------------------------------------------------------------------------------------  */


   
		
