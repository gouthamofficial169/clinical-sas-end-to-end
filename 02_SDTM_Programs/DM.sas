/*------------------------------------------------------------------------------------------  */
/*****************************************************************************
 * Filename    : DM.sas
 * Author      : Goutham
 * Date        : &sysdate9.
 * SAS Version : SAS 9.4 (SAS ODA)
 * Platform    : Linux (SAS OnDemand Cloud)
 * Project     : EMR200048052 — EXPAND Trial
 * Description : Create SDTM DM — Demographics Domain
 *               following SDTM IG v3.4
 * Input       : GASTRIC.demo (Raw Demographics)
 * Output      : GASTI_F.DM (Demographics Domain)
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

/*------------------------------------------------------------------------------------------  */
DATA DM1;
	SET GASTRIC.DEMO (RENAME=(RACE=RACE_1));

	/*------------------------------------------------------------------------------------------  */
	/*IDENTIFIER VARIABLE  */
	/*------------------------------------------------------------------------------------------  */
	STUDYID=STRIP(STUDY);
	DOMAIN="DM";
	SUBJID=STRIP(PT);
	USUBJID=CATX("-", STUDYID, SUBJID);
RUN;

/*------------------------------------------------------------------------------------------  */
/*DERIVE THE DATE VARIABLE */
/*------------------------------------------------------------------------------------------  */
/*GETTING EXSTDTC AND EXENDTC FROM DACA  */
DATA DACA_EX_DATE;
	SET GASTRIC.DACA;
	LENGTH EXSTDTC1 $ 200.;
	USUBJID=STRIP(CATX("-", STUDY, PT));

	IF FIRSTDT AND LASTDT NE . THEN
		DO;
			EXSTDTC1=STRIP(PUT(FIRSTDT, E8601DA10.));
			EXENDTC1=STRIP(PUT(LASTDT, E8601DA10.));
		END;
	ELSE
		DO EXSTDTC1="";
			EXENDTC1="";
			KEEP USUBJID EXSTDTC1 EXENDTC1;
		END;

/*GETTING EXSTDTC AND EXENDTC FROM DACI  */
DATA DACI_EX_DATE;
	SET GASTRIC.DACI;
	USUBJID=STRIP(CATX("-", STUDY, PT));

	IF NOT MISSING(INFUSDT) AND NOT MISSING(INFUSTMC) THEN
		DO EXSTDTC1=CATX("T", STRIP(PUT(INFUSDT, E8601DA10.)), STRIP(INFUSTMC));
		END;
	ELSE
		DO;
			EXSTDTC1="";
		END;
	EXENDTC1="";

	/*end date is not available in daci dataset*/
	KEEP USUBJID EXSTDTC1 EXENDTC1;
RUN;

/* COMBINE */
DATA DACA_DACI;
	SET DACA_EX_DATE DACI_EX_DATE;
RUN;

/*RFXSTDTC AND RFXENDTC  */
PROC SQL;
	CREATE TABLE DACA_DAC_DATE AS SELECT USUBJID, MIN(EXSTDTC1) AS RFXSTDTC, 
		MAX(EXENDTC1) AS RFXENDTC FROM DACA_DACI GROUP BY USUBJID;
QUIT;

PROC SORT DATA=DACA_DAC_DATE SORTSEQ=LINGUISTIC(NUMERIC_COLLATION=ON);
	BY USUBJID;
RUN;

/*------------------------------------------------------------------------------------------  */
/*GETTING STUDY END DATE FROM DISC DATASET  */
/*------------------------------------------------------------------------------------------  */
DATA DISC_DM;
	MERGE GASTRIC.DISC GASTRIC.CONS;
	USUBJID=CATX("-", STUDY, PT);
RUN;

PROC SORT DATA=DISC_DM SORTSEQ=LINGUISTIC(NUMERIC_COLLATION=ON);
	BY USUBJID;
RUN;

DATA DM_3;
	MERGE DACA_DAC_DATE(IN=A) DISC_DM(IN=B);

	IF A;
	BY USUBJID;
	RFENDTC_MAX=MAX(OFFDT, INPUT(RFXENDTC, YYMMDD10.), INPUT(RFXSTDTC, YYMMDD10.));

/*------------------------------------------------------------------------------------------  */
/*RFSTDTC AND RFENDTC  */
/*------------------------------------------------------------------------------------------  */
	RFSTDTC=STRIP(RFXSTDTC);
	RFENDTC=PUT(RFENDTC_MAX, E8601DA10.);
	RFICDTC=PUT(INFCSDT, E8601DA10.);
	RFPENDTC=RFENDTC;
	KEEP USUBJID RFSTDTC RFENDTC RFXSTDTC RFXENDTC RFICDTC RFPENDTC;
RUN;

/*------------------------------------------------------------------------------------------  */
/* CALCULATE THE AGE VARIABLE */
/*------------------------------------------------------------------------------------------  */
DATA DM_4;
	MERGE DM1 DM_3;
	LENGTH RACE $ 30. ETHNIC $ 30.;

	/*BIRTHDATE AND AGE CALCULATION  */
	BRTHDTC=STRIP(BIRTHDTS);

/*------------------------------------------------------------------------------------------  */
/*AGE  */
/*------------------------------------------------------------------------------------------  */
	AGE=INTCK('YEAR', INPUT(STRIP(BIRTHDTC)||'-01-01', YYMMDD10.), INPUT(RFSTDTC, YYMMDD10.), 'C');

/*------------------------------------------------------------------------------------------  */
/*AGEU  */
/*------------------------------------------------------------------------------------------  */
	IF AGE NE . THEN
		AGEU="YEARS";

/*------------------------------------------------------------------------------------------  */
/*SEX */
/*------------------------------------------------------------------------------------------  */
	IF SEX="Male" THEN
		SEX="M";
	ELSE IF SEX="Female" THEN
		SEX="F";

/*------------------------------------------------------------------------------------------  */
/*RACE  */
/*------------------------------------------------------------------------------------------  */
	IF RACE_1 IN ("Japanese", "Asian (not japanese)") THEN
		RACE="ASIAN";

	IF RACE_1="Caucasian" THEN
		RACE="WHITE";

	IF RACE_1="Black" THEN
		RACE="BLACK OR AFRICAN AMERICAN";

	IF RACE_1="Other" THEN
		RACE="OTHER";

	IF RACE_1="Hispanic" THEN
		RACE="OTHER";

/*------------------------------------------------------------------------------------------  */
/*ETHINICITY  */
/*------------------------------------------------------------------------------------------  */
	IF RACE_1="Hispanic" THEN
		ETHNIC="HISPANIC OR LATINO";
	ELSE
		ETHNIC="NOT HISPANIC OR LATINO";
RUN;

/*------------------------------------------------------------------------------------------  */
/* ARM VARIABLES */
/*------------------------------------------------------------------------------------------  */
DATA DM_ARM;
	SET GASTRIC.RAND;

	IF TRTGRP NE "" AND TRTGRP="Group B" THEN
		DO;
			ARM="CAPECITABINE + CISPLATIN";
			ARMCD="XP";
			ACTARM="CAPECITABINE + CISPLATIN";
			ACTARMCD="XP";
		END;
	ARMNRS="";
	ACTARMUD="";
	KEEP PT ARM ARMCD ACTARM ACTARMCD ARMNRS ACTARMUD;
RUN;

/*------------------------------------------------------------------------------------------  */
/*DERIVE DEATH DATE VARIABLE FROM DIED DATASET  */
/*------------------------------------------------------------------------------------------  */
DATA DM_DIED;
	SET GASTRIC.DIED;
	DTHDTC=COMPRESS(STRIP(DEATHDTS), '*');
	KEEP PT DTHDTC;
RUN;

DATA DM_5;
	MERGE DM_4 (IN=A) DM_ARM (IN=B) DM_DIED(IN=C);

	IF A;
	BY PT;

/*------------------------------------------------------------------------------------------  */
/*DERIVE THE DEATH FLAG VARIABLE  */
/*------------------------------------------------------------------------------------------  */
	IF NOT MISSING(DTHDTC) THEN
		DTHFL="Y";
	ELSE
		DTHFL="";
	SITEID="";
	COUNTRY="";
	KEEP STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC RFXSTDTC RFXENDTC RFICDTC 
		RFPENDTC DTHDTC DTHFL SITEID BRTHDTC AGE AGEU SEX RACE ETHNIC ARMCD ARM 
		ACTARMCD ACTARM ARMNRS ACTARMUD COUNTRY;
RUN;

/*------------------------------------------------------------------------------------------  */
/*------------------------------------------------------------------------------------------  */
PROC SQL;
	CREATE TABLE DM AS SELECT 
		STUDYID LABEL="Study Identifier" LENGTH=20, 
		DOMAIN 	LABEL="Domain Abbreviation" LENGTH=2, 
		USUBJID LABEL="Unique Subject Identifier" LENGTH=25, 
		SUBJID 	LABEL="Subject Identifier for the Study" LENGTH=10, 
		RFSTDTC LABEL="Subject Reference Start Date/Time" LENGTH=12, 
		RFENDTC LABEL="Subject Reference End Date/Time" LENGTH=12, 
		RFXSTDTC LABEL="Date/Time of First Study Treatment" LENGTH=12, 
		RFXENDTC LABEL="Date/Time of Last Study Treatment" LENGTH=12, 
		RFICDTC LABEL="Date/Time of Informed Consent" LENGTH=12, 
		RFPENDTC LABEL="Date/Time of End of Participation" LENGTH=12, 
		DTHDTC LABEL="Date/Time of Death" LENGTH=12, 
		DTHFL LABEL="Subject Death Flag" LENGTH=2, 
		SITEID LABEL="Study Site Identifier" LENGTH=8, 
		BRTHDTC LABEL="Date/Time of Birth" LENGTH=12, AGE LABEL="Age" LENGTH=3, 
		AGEU LABEL="Age Units" LENGTH=8, SEX LABEL="Sex" LENGTH=7, 
		RACE LABEL="Race" LENGTH=30, 
		ETHNIC LABEL="Ethnicity" LENGTH=30, 
		ARMCD LABEL="Planned Arm Code" LENGTH=2, 
		ARM LABEL="Description of Planned Arm" LENGTH=30, 
		ACTARMCD LABEL="Actual Arm Code" LENGTH=2, 
		ACTARM LABEL="Description of Actual Arm" LENGTH=30, 
		ARMNRS LABEL="Reason Arm and/or Actual Arm is Null" , 
		ACTARMUD LABEL="Description of Unplanned Actual Arm" , 
		COUNTRY LABEL="Country" 
		from DM_5;
QUIT;

/*------------------------------------------------------------------------------------------  */
/*FINAL SAS DATA  */
/*------------------------------------------------------------------------------------------  */
	LIBNAME GASTI_F "/home/u64240743/gastric/GASTRIC SDTM RESULT";

	DATA GASTI_F.DM (LABEL="Demographics");
	SET DM;
	RUN;

/*------------------------------------------------------------------------------------------  */
/* EXPORT AS XPT FORMAT */
/*------------------------------------------------------------------------------------------  */
	LIBNAME XPTFILE XPORT "/home/u64240743/gastric/GASTRIC_XPT/DM.XPT";

	PROC COPY IN=gasti_f OUT=XPTFILE;
	SELECT DM;
	RUN;

/*------------------------------------------------------------------------------------------  */