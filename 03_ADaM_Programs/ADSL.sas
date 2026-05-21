/*****************************************************************************
* Filename    : adsl.sas
* Author      : Goutham
* Date        : &sysdate9.
* SAS Version : SAS 9.4 (SAS ODA)
* Platform    : Linux (SAS OnDemand Cloud)
* Project     : EMR200048052 — EXPAND Trial
* Description : Create ADaM ADSL — Subject Level Analysis Dataset
*               BDS structure per ADaMIG v1.3
* Input       : GASTI_F.DM    (SDTM Demographics Domain)
* Output      : GASTI_AD.ADSL (Subject Level Analysis Dataset)
* Standards   : ADaMIG v1.3 | CDISC CT 2026-03-27
*****************************************************************************
* MODIFICATION HISTORY
* Date          Author    Description
* -----------   --------  --------------------------------------------------
* &sysdate9.    Goutham   Initial creation
*****************************************************************************/


/*===================================================================================  */
LIBNAME GASTRIC "/home/u64240743/gastric";
RUN;
LIBNAME GASTI_F "/home/u64240743/gastric/GASTRIC SDTM RESULT";run;

/*-----------------------------------------------------------------------------------  */
/*SUBJECT IDENTIFIERS  */
/*-----------------------------------------------------------------------------------  */

DATA ADSL_DM;
	SET GASTI_F.DM;
	LENGTH USUBJID $ 25.;
	
	STUDYID = STRIP(STUDYID);
	
	USUBJID = STRIP(USUBJID);
	
	SUBJID  = STRIP(SUBJID);
	
	SITEID  = ""; 	/*SITEID IS MISSING FROM RAW SOURCE */

/*-----------------------------------------------------------------------------------  */
/*DEMOGRAPHIC INFO*/
/*-----------------------------------------------------------------------------------  */

	AGE = AGE;
	
	AGEU = STRIP(AGEU);
	
	IF AGE < 65 THEN DO; AGEGR1 = "<65 YEARS"; AGEGR1N = 1;END;
	ELSE IF AGE >= 65 THEN DO; AGEGR1 = ">=65 YEARS"; AGEGR1N = 2;END;
	
	SEX = STRIP(SEX);
	
	RACE = STRIP(RACE);
	
/*-----------------------------------------------------------------------------------  */
/*TREATMENT VARIABLES*/
/*-----------------------------------------------------------------------------------  */

	ARM = STRIP(ARM);
	
	ACTARM = STRIP(ACTARM);
	
/*-----------------------------------------------------------------------------------  */
/*PLANNED TREATMENT  */
/*-----------------------------------------------------------------------------------  */

	TRT01P = STRIP(ARM);
	
	TRT01PN = 1;
	
/*-----------------------------------------------------------------------------------  */
/*ACTUAL TREATMENT  */
/*-----------------------------------------------------------------------------------  */
	
	TRT01A = STRIP(ACTARM);
	
	TRT01AN = 1;
	
/*-----------------------------------------------------------------------------------  */
/*TREATMENT DATE  */
/*-----------------------------------------------------------------------------------  */
	
	TRTSDT = INPUT(RFXSTDTC,YYMMDD10.);
	
	TRTEDT = INPUT(RFXENDTC,YYMMDD10.);
	
	FORMAT TRTSDT TRTEDT DATE9. ;
	
	IF NOT MISSING(TRTSDT) AND NOT MISSING(TRTEDT) THEN DO;
		TRTDURD = (TRTEDT-TRTSDT)+1;
		TRTDURM = INTCK('MONTH',TRTSDT,TRTEDT);
		TRTDURY = INTCK('YEAR',TRTSDT,TRTEDT); END;
		
/*-----------------------------------------------------------------------------------  */
/*INFORMED CONSENT DATE  */
/*-----------------------------------------------------------------------------------  */

	RFICDT = INPUT(RFICDTC,YYMMDD10.);
	FORMAT RFICDT DATE9.;
	
	
/*-----------------------------------------------------------------------------------  */
/*OTHER DATE  */
/*-----------------------------------------------------------------------------------  */
	RFSTDT = INPUT(RFSTDTC,YYMMDD10.);
	RFENDT = INPUT(RFENDTC,YYMMDD10.);
	
	FORMAT RFSTDT RFENDT DATE9.;
	
	
/*-----------------------------------------------------------------------------------  */
/*DEATH DATE  */
/*-----------------------------------------------------------------------------------  */
	FORMAT DTHDT DATE9.;

	IF NOT MISSING(DTHDTC) THEN DO;
    /* FULL DATE: YYYY-MM-DD */
    IF LENGTH(STRIP(DTHDTC)) = 10 THEN DO;
      DTHDT = INPUT(DTHDTC,YYMMDD10.);
      
    END;
    END;
RUN;
	
	PROC SORT DATA=ADSL_DM
	SORTSEQ=LINGUISTIC(NUMERIC_COLLATION = ON);
	BY SUBJID;
	RUN;
   
		
/*-----------------------------------------------------------------------------------  */
/*CAUSE OF DEATH   */
/*-----------------------------------------------------------------------------------  */
   
/*DERIVED FROM DIED DATASET  */
   
DATA ADSL_DC;
	SET GASTRIC.DIED;
	LENGTH USUBJID $ 25.;
	
	USUBJID = STRIP(CATX("-",STUDY,PT));
	
	DTHCAUS = STRIP(CAUSE);
	
	IF NOT MISSING(DEATHDT) THEN DO ;
	IF DTHCAUS = "Disease progression" THEN DTHCAUSN = 1;
	ELSE IF DTHCAUS = "Disease related complication" THEN DTHCAUSN = 2;
	ELSE IF DTHCAUS = "Events related to study treatment" THEN DTHCAUSN =3 ;
	ELSE IF DTHCAUS = "Intercurrent or unrelated illness/event" THEN DTHCAUSN =4 ;
	ELSE IF DTHCAUS = "Unknown" THEN DTHCAUSN =5 ; END;
	ELSE DTHCAUS = "";
	
	KEEP USUBJID DTHCAUS DTHCAUSN;
RUN;

	PROC SORT DATA=ADSL_DC
	SORTSEQ=LINGUISTIC(NUMERIC_COLLATION = ON);
	BY USUBJID;
	RUN;

/*-----------------------------------------------------------------------------------  */
/*RANDOMIZATION DATE  */
/*-----------------------------------------------------------------------------------  */
PROC SORT DATA=GASTI_F.DS
	SORTSEQ=LINGUISTIC(NUMERIC_COLLATION = ON);
	BY USUBJID;
	RUN;
DATA ADSL_RAND;
	SET GASTI_F.DS;
	LENGTH USUBJID $ 25. COMPLFL $ 2. EOSSTT $ 20. DCSREAS $ 30. ;
	BY USUBJID;
	
	RETAIN RANDDT ENRLDT EOSDT COMPLFL DCSREAS EOSSTT;
	IF FIRST.USUBJID THEN DO; 
	RANDDT =.;
	ENRLDT = .;
	EOSDT = .;
	COMPLFL = "" ;
	DCSREAS = "";
	EOSSTT = "";
	END;
	
	USUBJID = STRIP(USUBJID);
	
	FORMAT RANDDT ENRLDT EOSDT DATE9.;
	IF UPCASE(DSDECOD)= "INFORMED CONSENT OBTAINED" THEN ENRLDT = INPUT(DSSTDTC,YYMMDD10.);
	ELSE IF UPCASE(DSDECOD) = "RANDOMIZED" THEN 
	RANDDT =INPUT(DSSTDTC,YYMMDD10.) ;
	
/*DISCONTINUATION INFORMATION*/
	
	IF 	UPCASE(DSDECOD) IN ("ADVERSE EVENT",
			"DEATH",
			"OTHER EVENT",
			"LOST TO FOLLOW-UP",
			"PROGRESSIVE DISEASE",
			"PROTOCOL VIOLATION",
			"WITHDRAWAL BY SUBJECT")
		THEN DO;
			EOSDT = INPUT(DSSTDTC,YYMMDD10.);
			DCSREAS = DSDECOD;
	END;
			
	IF NOT MISSING(DCSREAS) AND NOT MISSING(EOSDT) THEN DO; 
			EOSSTT = "DISCONTINUED";
			COMPLFL = "N";
			
	END;
	
	IF LAST.USUBJID;
	
	KEEP USUBJID RANDDT ENRLDT EOSSTT DCSREAS EOSDT COMPLFL;
	
RUN;

	PROC SORT DATA=ADSL_RAND NODUPKEY
	SORTSEQ=LINGUISTIC(NUMERIC_COLLATION = ON);
	BY USUBJID;
	RUN;


/*-----------------------------------------------------------------------------------  */
/*COMBINE DATA  */
/*-----------------------------------------------------------------------------------  */

DATA GASTRIC_ADSL_1;
	MERGE ADSL_DM(IN=A) ADSL_DC(IN=B) ADSL_RAND(IN=C) ;
	LENGTH USUBJID $ 25.;
	IF A;
	BY USUBJID;
	
/*-----------------------------------------------------------------------------------  */
/*POPULATION FLAG*/
/*-----------------------------------------------------------------------------------  */

/*RANDOMIZATION POPULATION FLAG */

	IF NOT MISSING(RANDDT) THEN RANDFL="Y";
	ELSE RANDFL = "N";
	
/*SAFETY POPULATION FLAG  */
	
	IF NOT MISSING(TRTSDT) THEN SAFFL="Y";
	ELSE SAFFL = "N";
	
/*INTENT TO TREAT POPULATION FLAG */

	IF RANDFL = "Y" THEN ITTFL = "Y";
	ELSE ITTFL = "N";
	
/*FULL ANALYSIS SET POPULATION FLAG  */
	
	IF ITTFL = "Y" AND NOT MISSING(TRTSDT) THEN FASFL = "Y";
	ELSE FASFL = "N";
	
/*ENROLLMENT POPULATION FLAG 	 */

	IF NOT MISSING(ENRLDT) THEN  ENRLFL = "Y";
	ELSE ENRLFL = "N";
	
/*DEATH FLAG  */

	IF NOT MISSING(DEATHDT) THEN DTHFL = "Y";
	
	
KEEP STUDYID USUBJID SUBJID SITEID AGE AGEU AGEGR1N SEX RACE AGEGR1
 	ARM ACTARM TRT01P TRT01PN TRT01A TRT01AN TRTSDT TRTEDT TRTDURD 
 	TRTDURM TRTDURY RFICDT DTHDT DTHCAUS DTHCAUSN RANDDT ENRLDT EOSDT
 	COMPLFL DCSREAS EOSSTT RANDFL SAFFL ITTFL FASFL ENRLFL DTHFL RFSTDTC RFENDTC RFSTDT RFENDT;
	
RUN;

/*DERIVATION OF HEIGHT, WEIGHT,BMI */
DATA ADSL_VS;
	SET GASTI_F.VS;

	WHERE VSTESTCD IN ("HEIGHT","WEIGHT");
RUN;

PROC SORT DATA=ADSL_VS
	SORTSEQ=LINGUISTIC(NUMERIC_COLLATION = ON);
	BY USUBJID VSTESTCD;
RUN;

PROC TRANSPOSE DATA=ADSL_VS OUT=ADSL_VS_F;
	BY USUBJID;
	ID VSTESTCD;
	VAR VSSTRESN;
RUN; 

/*DERIVE BMI */

DATA ADSL_VS_BMI;
	SET ADSL_VS_F;
	LENGTH BMIBLGR1 $ 8.;
	IF HEIGHT > 0 AND WEIGHT > 0 THEN 

	BMIBL = ROUND((WEIGHT / ((HEIGHT/100)**2)),0.02);

	/*BMI GROUPING VARIABLE */

	IF BMIBL < 25 THEN DO; BMIBLGR1 = "<25"; END;
	ELSE IF 25 <=BMIBL < 30  THEN DO; BMIBLGR1 = "25-<30"; END;
	ELSE IF BMIBL >= 30  THEN DO; BMIBLGR1 = ">=30"; END;

	KEEP HEIGHT WEIGHT BMIBL BMIBLGR1 USUBJID;
RUN;
   
/*FINAL COMBINE OF ADSL WITH VS PARAMETERS */

DATA ADSL_FINAL;
	MERGE GASTRIC_ADSL_1 (IN=A) ADSL_VS_BMI(IN=B RENAME=(HEIGHT = HEIGHTBL WEIGHT = WEIGHTBL));
	
	KEEP STUDYID USUBJID SUBJID AGE AGEU AGEGR1 AGEGR1N SEX RACE 
 	ARM ACTARM TRT01P TRT01PN TRT01A TRT01AN TRTSDT TRTEDT TRTDURD 
 	TRTDURM TRTDURY RFICDT DTHDT DTHCAUS DTHCAUSN RANDDT ENRLDT EOSDT
 	COMPLFL DCSREAS EOSSTT RANDFL SAFFL ITTFL FASFL ENRLFL DTHFL RFSTDTC RFENDTC 
 	HEIGHTBL WEIGHTBL BMIBL BMIBLGR1;
	
RUN;
   
   
PROC SQL;
CREATE TABLE ADSL AS
	SELECT 
		STUDYID	LABEL= "Study Identifier" 					LENGTH=20,
		USUBJID	LABEL= "Unique Subject Identifier" 			LENGTH=20,
		SUBJID	LABEL= "Subject Identifier for the Study" 	LENGTH=5,
		AGE		LABEL= "Age"								LENGTH=3,
		AGEU	LABEL= "Age Units"							LENGTH=8,
		AGEGR1	LABEL= "Pooled Age Group 1"					LENGTH=10,
		AGEGR1N	LABEL= "Pooled Age Group 1 (N)"				LENGTH=8,
		SEX		LABEL= "Sex"								LENGTH=2,
		RACE	LABEL= "Race"								LENGTH=30,
		FASFL	LABEL= "Full Analysis Set Population Flag"	LENGTH=1,
		SAFFL	LABEL= "Safety Population Flag"				LENGTH=1,
		ITTFL	LABEL= "Intent-To-Treat Population Flag"	LENGTH=1,
		COMPLFL	LABEL= "Completers Population Flag"			LENGTH=1,
		RANDFL	LABEL= "Randomized Population Flag"			LENGTH=1,
		ENRLFL	LABEL= "Enrolled Population Flag"			LENGTH=1,
		ARM		LABEL= "Description of Planned Arm"			LENGTH=30,
		ACTARM	LABEL= "Description of Actual Arm"			LENGTH=30,
		TRT01P	LABEL= "Planned Treatment for Period 01"	LENGTH=30,
		TRT01PN	LABEL= "Planned Treatment for Period 01 (N)" LENGTH=8,
		TRT01A	LABEL= "Actual Treatment for Period 01"		LENGTH=30,
		TRT01AN	LABEL= "Actual Treatment for Period 01 (N)"	LENGTH=8,
		TRTSDT	LABEL= "Date of First Exposure to Treatment" LENGTH=8,
		TRTEDT	LABEL= "Date of Last Exposure to Treatment" LENGTH=8,
		EOSSTT	LABEL= "End of Study Status"				LENGTH=18,
		EOSDT	LABEL= "End of Study Date"					LENGTH=8,
		BMIBL	LABEL= "Baseline BMI (kg/m^2)" 				LENGTH=8,
		BMIBLGR1 LABEL= "Pooled Baseline BMI Group 1"		LENGTH=8,
		HEIGHTBL LABEL= "Baseline Height (cm)"				LENGTH=8,
		WEIGHTBL LABEL= "Baseline Weight (kg)"				LENGTH=8,
		RFSTDTC	LABEL="Subject Reference Start Date/Time"   LENGTH=12,
		RFENDTC	LABEL="Subject Reference End Date/Time"  LENGTH=12,
		DCSREAS	LABEL= "Reason for Discontinuation from Study" LENGTH=30,
		RFICDT	LABEL= "Date of Informed Consent" 			LENGTH=8,
		ENRLDT	LABEL= "Date of Enrollment"					LENGTH=8,
		RANDDT	LABEL= "Date of Randomization"				LENGTH=8,
		TRTDURD	LABEL= "Total Treatment Duration (Days)"	LENGTH=8,
		TRTDURM	LABEL= "Total Treatment Duration (Months)"	LENGTH=8,
		TRTDURY	LABEL= "Total Treatment Duration (Years)"	LENGTH=8,
		DTHDT	LABEL= "Date of Death"						LENGTH=8,
		DTHFL	LABEL= "Subject Died ?"						LENGTH=2,
		DTHCAUS	LABEL= "Cause of Death"						LENGTH=39,
		DTHCAUSN LABEL=	"Cause of Death (N)"				LENGTH=8
		
	FROM ADSL_FINAL;
QUIT;



/*------------------------------------------------------------------------------------------  */
/*FINAL SAS DATA  */
/*------------------------------------------------------------------------------------------  */	

	LIBNAME GASTI_AD "/home/u64240743/gastric/GASTRIC ADAM";
	
	DATA GASTI_AD.ADSL (LABEL="Subject-Level Analysis Dataset");
	SET ADSL ;
	RUN;

/*------------------------------------------------------------------------------------------  */
/* EXPORT AS XPT FORMAT */
/*------------------------------------------------------------------------------------------  */
	LIBNAME XPTFILE XPORT "/home/u64240743/gastric/GASTRIC_XPT/ADSL.XPT";
	PROC COPY IN=GASTI_AD OUT=XPTFILE;
	SELECT ADSL;
	RUN;
	
/*------------------------------------------------------------------------------------------  */


   
	