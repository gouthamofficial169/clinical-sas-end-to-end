/*****************************************************************************
* Filename    : adlb.sas
* Author      : Goutham
* Date        : &sysdate9.
* SAS Version : SAS 9.4 (SAS ODA)
* Platform    : Linux (SAS OnDemand Cloud)
* Project     : EMR200048052 — EXPAND Trial
* Description : Create ADaM ADLB — Laboratory Analysis Dataset
*               BDS structure per ADaMIG v1.3
* Input       : GASTI_F.LB    (SDTM Laboratory Domain)
*               GASTI_AD.ADSL (Subject Level Analysis Dataset)
* Output      : GASTI_AD.ADLB (Laboratory Analysis Dataset)
* Standards   : ADaMIG v1.3 | CDISC CT 2026-03-27
*****************************************************************************
* MODIFICATION HISTORY
* Date          Author    Description
* -----------   --------  --------------------------------------------------
* &sysdate9.    Goutham   Initial creation
*****************************************************************************/

/*===================================================================================  */
LIBNAME GASTI_F "/home/u64240743/gastric/GASTRIC SDTM RESULT";run;
LIBNAME GASTI_AD "/home/u64240743/gastric/GASTRIC ADAM";
RUN;
/*===================================================================================  */

/*-----------------------------------------------------------------------------------  */
/*SORT THE ADSL DATASET BY USUBJID  */
/*-----------------------------------------------------------------------------------  */

PROC SORT DATA=GASTI_AD.ADSL
	SORTSEQ=LINGUISTIC(NUMERIC_COLLATION = ON);
	BY USUBJID;
RUN;

/*-----------------------------------------------------------------------------------  */
/*SORT THE LB DATASET BY USUBJID  */
/*-----------------------------------------------------------------------------------  */

PROC SORT DATA=GASTI_F.LB
	SORTSEQ=LINGUISTIC(NUMERIC_COLLATION = ON);
	BY USUBJID;
RUN;

/*-----------------------------------------------------------------------------------  */
/*COMBINE THE ADSL AND LB DATASET  */
/*-----------------------------------------------------------------------------------  */

DATA ADLB_1;
	LENGTH USUBJID $ 40.;
	MERGE GASTI_AD.ADSL(IN=A) GASTI_F.LB(IN=B);
	BY USUBJID;
	IF A AND B;
RUN;

/*-----------------------------------------------------------------------------------  */
/*SUBJECT IDENTIFIERS  */
/*-----------------------------------------------------------------------------------  */

DATA ADLB_2;
	SET ADLB_1;
	
	STUDYID = STRIP(STUDYID);
	
	USUBJID = STRIP(USUBJID);
	
	SUBJID = STRIP(SUBJID);
	
	SITEID = "";
	
	ASEQ = LBSEQ;
	
/*-----------------------------------------------------------------------------------  */
/*GROUP 2 — PARAMETER VARIABLES */
/*-----------------------------------------------------------------------------------  */
	
	PARAM = CATX("  ",STRIP(LBTEST)," ("||STRIP(LBSTRESU)||")");
	
	PARAMCD = STRIP(LBTESTCD);
	
/* BIOCHEMISTRY	 */
	IF LBTESTCD = "ALT" THEN DO; PARAMN = 1;END;
	IF LBTESTCD = "AST" THEN DO; PARAMN = 2;END;
	IF LBTESTCD = "ALP" THEN DO; PARAMN = 3;END;
	IF LBTESTCD = "ALB" THEN DO; PARAMN = 4;END;
	IF LBTESTCD = "BILI" THEN DO; PARAMN = 5;END;
	IF LBTESTCD = "CREAT" THEN DO; PARAMN = 6;END;
	IF LBTESTCD = "GFR" THEN DO; PARAMN = 7;END;
	IF LBTESTCD = "LDH" THEN DO; PARAMN = 8;END;
	IF LBTESTCD = "MG" THEN DO; PARAMN = 9;END;
	IF LBTESTCD = "PHOS" THEN DO; PARAMN = 10;END;
	IF LBTESTCD = "K" THEN DO; PARAMN = 11;END;
	IF LBTESTCD = "SODIUM" THEN DO; PARAMN = 12;END;
	IF LBTESTCD = "CA" THEN DO; PARAMN = 13;END;
/* HEMATOLOGY */
	IF LBTESTCD = "WBC" THEN DO; PARAMN = 14;END;
	IF LBTESTCD = "NEUT" THEN DO; PARAMN = 15;END;
	IF LBTESTCD = "HGB" THEN DO; PARAMN = 16;END;
	IF LBTESTCD = "PLAT" THEN DO; PARAMN = 17;END;
	
/*PARAMETER CATEOGORY  */

	PARCAT1 = STRIP(LBCAT);
	
	
/*-----------------------------------------------------------------------------------  */
/*GROUP 3 — ANALYSIS VALUE VARIABLES  */
/*-----------------------------------------------------------------------------------  */
	
	AVAL = LBSTRESN;
	
	AVALC = STRIP(LBSTRESC);
	
	ANRLO = LBSTNRLO;
	
	ANRHI = LBSTNRHI;
	
	ANRIND = STRIP(LBNRIND);
	
/*-----------------------------------------------------------------------------------  */
/*GROUP 4 — TIMING VARIABLES  */
/*-----------------------------------------------------------------------------------  */
	
	ADT = INPUT(LBDTC,YYMMDD10.);
	FORMAT ADT DATE9.;
	
	AVISIT = STRIP(VISIT);
	
	AVISITN = VISITNUM;
	
	
RUN;

PROC SORT DATA=ADLB_2; 
  BY USUBJID PARAMCD ADT; 
RUN;
	
/*-----------------------------------------------------------------------------------  */
/*GROUP 5 — BASELINE AND CHANGE VARIABLES */
/*-----------------------------------------------------------------------------------  */
/*BASELINE FLAG  */
DATA ADLB_3;
	SET ADLB_2;
	BY USUBJID PARAMCD ADT;
	WHERE ADT <= TRTSDT AND NOT MISSING(AVAL); 
	IF LAST.PARAMCD THEN ABLFL = "Y";
	ELSE ABLFL= "";
	
	KEEP USUBJID PARAMCD ADT ABLFL;
	RUN;
	
DATA ADLB_4;
	MERGE ADLB_2 (IN=A) ADLB_3(IN=B);
	BY USUBJID PARAMCD ADT;
	IF A;

RUN;


PROC SORT DATA=ADLB_2; 
	BY USUBJID PARAMCD ADT; 
RUN;

/* BASE VARIABLE */
DATA ADLB_5;
	SET ADLB_4;
	LENGTH BNRIND $ 10. ;
	BY USUBJID PARAMCD;
	
	IF AVALC NE "" AND ABLFL = "Y" THEN DO;
	BASE = AVAL;
	BASEC = AVALC;
	BNRIND = STRIP(LBNRIND);
	END;
	IF ABLFL="Y";
	
	KEEP USUBJID PARAMCD PARCAT1 BASE BASEC BNRIND ;
	RUN;
	
	
PROC SORT DATA=ADLB_5; 
	BY USUBJID PARAMCD PARCAT1; 
RUN;

	
PROC SORT DATA=ADLB_4; 
	BY USUBJID PARAMCD PARCAT1; 
RUN;

DATA ADLB_6;
	MERGE ADLB_4(IN=A) ADLB_5;
	BY USUBJID PARAMCD PARCAT1;
	
/*CHANGE FROM BASELINE  */
	IF AVAL NE . AND BASE NE . THEN DO;
	CHG = AVAL-BASE;
	END;
	
/*PERCENTAGE CHANGE FROM BASELINE  */

	IF NOT MISSING(BASE) AND BASE NE 0 THEN 
	PCHG = ROUND(((AVAL-BASE)/BASE)*100,0.01);
	ELSE PCHG = .;
	
/* DERIVATION TYPE (DTYPE FOR LAB RETEST)	 */

/* 	IF AVISIT = "Lab retest" THEN DTYPE = "RETEST"; */
/* 	ELSE DTYPE = ""; */
	
/*-----------------------------------------------------------------------------------  */
/*ANL01FL — PRIMARY ANALYSIS RECORD FLAG EXPLICIT EXCLUSIONS FOR ALL NON-ANALYSIS VISITS */
/*-----------------------------------------------------------------------------------  */

  If ADT > TRTSDT               
     And Not Missing(AVAL)      
     AND DTYPE    =  ""          
     AND ABLFL    Ne "Y"         
     AND AVISIT NOT IN (
         "Screening",            
         "Lab retest",           
         "Imaging"  )
  THEN ANL01FL = "Y";
  ELSE ANL01FL = "";
  
	
/*-----------------------------------------------------------------------------------  */
/*GROUP 6 — TREATMENT VARIABLES */
/*-----------------------------------------------------------------------------------  */
  
	TRTP = STRIP(TRT01P);
	
	TRTPN = TRT01PN;
	
	TRTA = STRIP(TRT01A);
	
	TRTAN = TRT01AN;
	
	TRTSDT = TRTSDT;
	
	TRTEDT = TRTEDT;

/*-----------------------------------------------------------------------------------  */
/* FLAG VARIABLES FROM ADSL	 */
/*-----------------------------------------------------------------------------------  */

	FASFL = STRIP(FASFL);
	SAFFL = STRIP(SAFFL);
	ITTFL = STRIP(ITTFL);
	COMPLFL = STRIP(COMPLFL);
	RANDFL = STRIP(RANDFL);
	ENRLFL = STRIP(ENRLFL);
/*-----------------------------------------------------------------------------------  */
/* FLAG VARIABLES FROM ADSL	 */
/*-----------------------------------------------------------------------------------  */

	AGE = AGE;
	AGEGR1 = AGEGR1;
	AGEGR1N = AGEGR1N;
	SEX = STRIP(SEX);
	RACE = STRIP(RACE);
	
KEEP STUDYID  SUBJID USUBJID  ASEQ PARAM PARAMCD PARCAT1 PARAMN AVAL AVALC BASE BASEC 
BNRIND ANRLO ANRHI ANRIND ADT VISIT AVISIT AVISITN VISITNUM ABLFL CHG PCHG ANL01FL TRTP TRTPN 
TRTA TRTAN TRTSDT TRTEDT FASFL SAFFL ITTFL COMPLFL RANDFL ENRLFL AGE AGEGR1 AGEGR1N SEX RACE;
	
    
RUN;

PROC SQL NOPRINT;
	CREATE TABLE ADLB AS 
	SELECT
	
	/* IDENTIFIERS	 */
	
		STUDYID	LABEL= "Study Identifier"					LENGTH =15,
		USUBJID	LABEL= "Unique Subject Identifier"			LENGTH =20,
		SUBJID	LABEL= "Subject Identifier for the Study"	LENGTH =4,
		ASEQ	LABEL= "Analysis Sequence Number"			LENGTH =8,

	/* TREATMENT VARIABLES	 */
	
		TRTP	LABEL= "Planned Treatment"					LENGTH=30,
		TRTPN	LABEL= "Planned Treatment (N)"				LENGTH=8,
		TRTA	LABEL= "Actual Treatment"					LENGTH=30,
		TRTAN	LABEL= "Actual Treatment (N)"				LENGTH=8,
		
		TRTSDT	LABEL= "Date of First Exposure to Treatment" LENGTH=8,
		TRTEDT	LABEL= "Date of Last Exposure to Treatment"  LENGTH=8,
		
	/*DEMOGRAPHICS DETAILS */
	
		AGE		LABEL= "Age"								LENGTH=3,
		AGEGR1	LABEL= "Pooled Age Group 1"					LENGTH=10,
		AGEGR1N	LABEL= "Pooled Age Group 1 (N)"				LENGTH=8,
		SEX		LABEL= "Sex"								LENGTH=2,
		RACE	LABEL= "Race"								LENGTH=30,
				
	/*POPULATION FLAG */
	
		FASFL	LABEL= "Full Analysis Set Population Flag"	LENGTH=1,
		SAFFL	LABEL= "Safety Population Flag"				LENGTH=1,
		ITTFL	LABEL= "Intent-To-Treat Population Flag"	LENGTH=1,
		COMPLFL	LABEL= "Completers Population Flag"			LENGTH=1,
		RANDFL	LABEL= "Randomized Population Flag"			LENGTH=1,
		ENRLFL	LABEL= "Enrolled Population Flag"			LENGTH=1,
	
	/*TIMING */
	
		ADT		LABEL= "Analysis Date"						LENGTH=8,
		AVISIT	LABEL= "Analysis Visit"						LENGTH=20,
		AVISITN	LABEL= "Analysis Visit (N)"					LENGTH=8,
		VISIT   LABEL= "Visit Name"							LENGTH=20,
		VISITNUM  LABEL="Visit Number"						LENGTH=8,
    
		
	/*PARAMETER 	 */
	
		PARAM	LABEL= "Parameter"							LENGTH=40,
		PARAMCD	LABEL= "Parameter Code"						LENGTH=8,
		PARAMN	LABEL= "Parameter (N)"						LENGTH=8,
		PARCAT1	LABEL= "Parameter Category 1"				LENGTH=18,

		AVAL	LABEL= "Analysis Value"						LENGTH=8,
		AVALC	LABEL= "Analysis Value (C)"					LENGTH=8,
		
	/*BASELINE  */
	
		BASE	LABEL= "Baseline Value"						LENGTH=8,
		BASEC	LABEL= "Baseline Value (C)"					LENGTH=8,
		
		CHG		LABEL= "Change from Baseline"				LENGTH=8,
		PCHG	LABEL= "Percent Change from Baseline"		LENGTH=8,
/* 		DTYPE	LABEL= "Derivation Type"					LENGTH=10, */

	/*ANALYSIS VALUES  */
	
		ANRIND	LABEL= "Analysis Reference Range Indicator"	LENGTH=10,
		BNRIND	LABEL= "Baseline Reference Range Indicator"	LENGTH=10,
		ANRLO	LABEL= "Analysis Normal Range Lower Limit"	LENGTH=8,
		ANRHI	LABEL= "Analysis Normal Range Upper Limit"	LENGTH=8,

		ABLFL	LABEL= "Baseline Record Flag"				LENGTH=2,
		ANL01FL	LABEL= "Analysis Flag 01"					LENGTH=2
		
	FROM ADLB_6;

QUIT;


/*------------------------------------------------------------------------------------------  */
/*FINAL SAS DATA  */
/*------------------------------------------------------------------------------------------  */	

	LIBNAME GASTI_AD "/home/u64240743/gastric/GASTRIC ADAM";
	
	DATA GASTI_AD.ADLB (LABEL="Basic Data Structure");
	SET ADLB ;
	RUN;

/*------------------------------------------------------------------------------------------  */
/* EXPORT AS XPT FORMAT */
/*------------------------------------------------------------------------------------------  */
	LIBNAME XPTFILE XPORT "/home/u64240743/gastric/GASTRIC_XPT/ADLB.XPT";
	PROC COPY IN=GASTI_AD OUT=XPTFILE;
	SELECT ADLB;
	RUN;
	
/*------------------------------------------------------------------------------------------  */

	
		
	
	

	