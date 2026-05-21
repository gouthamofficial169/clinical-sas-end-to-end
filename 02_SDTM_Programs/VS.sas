/*------------------------------------------------------------------------------------------  */
/*****************************************************************************
 * Filename    : VS.sas
 * Author      : Goutham
 * Date        : &sysdate9.
 * SAS Version : SAS 9.4 (SAS ODA)
 * Platform    : Linux (SAS OnDemand Cloud)
 * Project     : EMR200048052 — EXPAND Trial
 * Description : Create SDTM VS — Vital Sign Domain
 *               following SDTM IG v3.4
 * Input       : GASTRIC.VITS (Raw Vital Sign)
 * Output      : GASTI_F.VS (Vital Sign Domain)
 * Standards   : SDTM IG v3.4 | CDISC CT 2026-03-27
 *****************************************************************************
 * MODIFICATION HISTORY
 * Date          Author    Description
 * -----------   --------  --------------------------------------------------
 * &sysdate9.    Goutham   Initial creation
 *****************************************************************************/


/*------------------------------------------------------------------------------------  */
/*IMPORT THE LIBRARY  */
/*------------------------------------------------------------------------------------  */
LIBNAME GASTRIC "/home/u64240743/gastric";
RUN;
/*------------------------------------------------------------------------------------  */

/*------------------------------------------------------------------------------------  */
/*IDENTIFIER VARIABLE  */
/*------------------------------------------------------------------------------------  */

DATA VS_1;
	SET GASTRIC.VITS;
	LENGTH VSORRESU VSSTRESU $ 20.;
	
	STUDYID = STRIP(STUDY);
	
	DOMAIN = "VS";
	
	USUBJID = CATX("-",STUDYID,STRIP(PT));
	
	WHERE VISIT = "Screening";

/*------------------------------------------------------------------------------------  */
/* DERIVATION OF BSA */
/*------------------------------------------------------------------------------------  */

	IF NOT MISSING(HEIGHT) AND NOT MISSING(WEIGHT) THEN 
	BSA = ROUND(SQRT((HEIGHT*WEIGHT)/3600),0.01);
	
*------------------------------------------------------------------------------------  */
/* DERIVATION OF OTHER PARAMETERS */
/*------------------------------------------------------------------------------------  */;

	
	ARRAY TEST{7} HEIGHT WEIGHT TEMP PULSE SYSTOLIC DIASTOLI BSA ;
	ARRAY TESTNAME{7} $ 40 ("Height",
							"Weight",
							"Temperature",
							"Pulse Rate",
							"Systolic Blood Pressure",
							"Diastolic Blood Pressure",
							"Body Surface Area");
	ARRAY TESTCD{7} $ 10 ("HEIGHT","WEIGHT","TEMP","PULSE","SYSBP","DIABP","BSA");
	
	DO I = 1 TO 7;

/*------------------------------------------------------------------------------------  */
/* VITAL SIGN TEST 	 */
/*------------------------------------------------------------------------------------  */

	VSTESTCD= STRIP(TESTCD{I});
	VSTEST = STRIP(TESTNAME{I});

/*------------------------------------------------------------------------------------  */
/* RESULT  */
/*------------------------------------------------------------------------------------  */
	
/*VSORRES 	 */
	IF NOT MISSING(TEST{I}) THEN DO; VSORRES = STRIP(PUT(TEST{I},BEST.)); END;
	ELSE VSORRES = "";
	
	VSSTRESN = test{i};
	
/* VSSTRESC	 */
	IF NOT MISSING(TEST{I}) THEN DO; VSSTRESC= STRIP(PUT(TEST{I},BEST.));END;
	ELSE  VSSTRESC = "";

/*------------------------------------------------------------------------------------  */
/* UNITS */
/*------------------------------------------------------------------------------------  */

IF NOT MISSING(VSORRES) THEN DO;
	
	IF  VSTESTCD IN ("SYSBP","DIABP")THEN DO;
	VSORRESU = "mmHg";
	VSSTRESU = "mmHg";
	END;
	
	ELSE IF VSTESTCD= "PULSE" THEN DO;
	VSORRESU = "beats/min";
	VSSTRESU = "beats/min";
	END;
	
	ELSE IF VSTESTCD = "HEIGHT" THEN DO;
	VSORRESU = "cm";
	VSSTRESU = "cm";
	END;
	
	ELSE IF VSTESTCD = "WEIGHT" THEN DO;
	VSORRESU = "kg";
	VSSTRESU = "kg";
	END;
	
	ELSE IF VSTESTCD = "TEMP" THEN DO;
	VSORRESU = "C";
	VSSTRESU = "C";
	END;

	IF VSTESTCD = "BSA" THEN DO;
	VSORRESU = "m2";
	VSSTRESU = "m2";
	END;
END;
	ELSE DO;
	VSORRESU = "";
	VSSTRESU = "";END;
	
	OUTPUT;
	END;
	
RUN;

PROC SORT DATA=VS_1
SORTSEQ=LINGUISTIC(NUMERIC_COLLATION = ON);
BY USUBJID VSTEST VSTESTCD;
RUN;
	
DATA VS_2;
SET VS_1;
LENGTH VSSTAT $ 11.;
/* SEQUENCE NUMBER */
	BY STUDYID USUBJID;
	IF FIRST.USUBJID THEN VSSEQ = 1;
	ELSE VSSEQ +1 ;
	
	
/* VITAL SIGN COLLECTION DATE	 */
	VSDTC = "";
	
	VSLOBXFL = "";
	
/*VISIT AND VISIT NUMBER 	 */

	VISIT = STRIP(VISIT);
	
	VISITNUM = 1;
	
/*VSSTAT  */

IF MISSING(VSORRES) THEN VSSTAT = "NOT DONE";

RUN;
	
DATA VS_3;
SET VS_2;

KEEP 	
	STUDYID
	DOMAIN
	USUBJID
	VSSEQ
	VSTESTCD
	VSTEST
	VSORRES
	VSORRESU
	VSSTRESC
	VSSTRESN
	VSSTRESU
	VSSTAT
	VSLOBXFL
	VISITNUM
	VISIT
	VSDTC;
	
RUN;

PROC SQL NOPRINT ;
CREATE TABLE VS AS
SELECT 

	STUDYID		LABEL="Study Identifier" LENGTH=20,
	
	DOMAIN		LABEL="Domain Abbreviation" LENGTH=2,
	
	USUBJID		LABEL="Unique Subject Identifier" LENGTH=20,
	
	VSSEQ		LABEL="Sequence Number" LENGTH=5,
	
	VSTESTCD	LABEL="Vital Signs Test Short Name" LENGTH=8,
	
	VSTEST		LABEL="Vital Signs Test Name" LENGTH=25,

	VSORRES		LABEL="Result or Finding in Original Units" LENGTH=10,

	VSORRESU	LABEL="Original Units" LENGTH=10,

	VSSTRESC	LABEL="Character Result/Finding in Std Format" LENGTH=10,

	VSSTRESN	LABEL="Numeric Result/Finding in Standard Units" LENGTH=8,

	VSSTRESU	LABEL="Standard Units" LENGTH=10,
	
	VSSTAT		LABEL= "Completion Status" LENGTH=11,
	
	VSLOBXFL	LABEL="Last Observation Before Exposure Flag" LENGTH=1,
	
	VISITNUM	LABEL="Visit Number" LENGTH=8,
	
	VISIT		LABEL="Visit Name" LENGTH=12,
	
	VSDTC		LABEL="Date/Time of Measurements" 
	
	FROM VS_3;
	
	QUIT;


/*------------------------------------------------------------------------------------------  */
/*FINAL SAS DATA  */
/*------------------------------------------------------------------------------------------  */	

	LIBNAME GASTI_F "/home/u64240743/gastric/GASTRIC SDTM RESULT";
	
	DATA GASTI_F.VS (LABEL="Vital Signs");
	SET VS;
	RUN;

/*------------------------------------------------------------------------------------------  */
/* EXPORT AS XPT FORMAT */
/*------------------------------------------------------------------------------------------  */
	LIBNAME XPTFILE XPORT "/home/u64240743/gastric/GASTRIC_XPT/VS.XPT";
	PROC COPY IN=gasti_f OUT=XPTFILE;
	SELECT VS;
	RUN;
	
/*------------------------------------------------------------------------------------------  */







	
	

							
	
	
	
	
