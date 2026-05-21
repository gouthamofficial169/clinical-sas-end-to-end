/*------------------------------------------------------------------------------------------------------------  */
/*****************************************************************************
 * Filename    : AE.sas
 * Author      : Goutham
 * Date        : &sysdate9.
 * SAS Version : SAS 9.4 (SAS ODA)
 * Platform    : Linux (SAS OnDemand Cloud)
 * Project     : EMR200048052 — EXPAND Trial
 * Description : Create SDTM AE — Adverse Events Domain
 * Input       : GASTRIC.ade  (Raw AE Dataset — 7948 records)
 *               GASTRIC.sae  (Raw SAE Dataset — 342 records)
 * Output      : GASTI_F.AE     (Adverse Events Domain)
 *               GASTI_F.SUPPAE (Supplemental AE Qualifiers)
 * Standards   : SDTM IG v3.4 | CDISC CT 2026-03-27
 *****************************************************************************
 * MODIFICATION HISTORY
 * Date          Author    Description
 * -----------   --------  --------------------------------------------------
 * &sysdate9.    Goutham   Initial creation
 *****************************************************************************/
/*------------------------------------------------------------------------------------------------------------  */
/*ASSIGN THE LIBRARY  */
/*------------------------------------------------------------------------------------------------------------  */
LIBNAME GASTRIC "/home/u64240743/gastric";
RUN;
LIBNAME GASTI_F "/home/u64240743/gastric/GASTRIC SDTM RESULT";
RUN;

/*------------------------------------------------------------------------------------------------------------  */
/* LOAD THE ADVERSE EVENT RAW DATA FROM GASTRIC LIBRARY */
/*------------------------------------------------------------------------------------------------------------  */
DATA AE_1;
	SET GASTRIC.ade;
RUN;

/* SORT THE DATASET ADE */
PROC SORT DATA=AE_1 OUT=AE_1_SORT;
	BY PT STUDY AESEQNO;
RUN;

/*------------------------------------------------------------------------------------------------------------  */
/*IDENTIFIER VARIABLES */
/*------------------------------------------------------------------------------------------------------------  */
DATA AE_IDEN;
	SET AE_1_SORT;
	LENGTH USUBJID $ 40. AEOUT $  45.;
	STUDYID=STRIP(STUDY);
	DOMAIN="AE";
	USUBJID=CATX("-", STUDY, PT);

/*------------------------------------------------------------------------------------------------------------  */
/*AE OUTCOME*/
/*------------------------------------------------------------------------------------------------------------  */
	IF OUTCOME NE "" THEN
		DO;

			IF OUTCOME="Change in toxicity grade/severity or seriousness" THEN
				AEOUT="NOT RECOVERED/NOT RESOLVED";
			ELSE IF OUTCOME="Recovered (AE disappeared)" THEN
				AEOUT="RECOVERED/RESOLVED";
			ELSE IF OUTCOME="Not yet recovered at" THEN
				AEOUT="NOT RECOVERED/NOT RESOLVED";
			ELSE IF OUTCOME="Not recovered at death" THEN
				AEOUT="NOT RECOVERED/NOT RESOLVED";
			ELSE IF OUTCOME="Fatal (AE resulted in death)" THEN
				AEOUT="FATAL";
			ELSE IF OUTCOME="Recovered with sequelae" THEN
				AEOUT="RECOVERED/RESOLVED WITH SEQUELAE";
		END;
	ELSE
		AEOUT="";

/*------------------------------------------------------------------------------------------------------------  */
/* SAE */
/*------------------------------------------------------------------------------------------------------------  */
	IF SAE="Yes" THEN
		AESER="Y";
	ELSE IF SAE="No" THEN
		AESER="N";
	ELSE
		AESER="";
	KEEP AESEQNO STUDYID DOMAIN USUBJID AEOUT ONSETDTS AE_EDTS AESER;
RUN;

PROC SORT DATA=AE_IDEN SORTSEQ=linguistic(NUMERIC_COLLATION=ON);
	BY USUBJID AESEQNO;
RUN;

DATA AE_SAE_RAW;
	SET GASTRIC.SAE;
	LENGTH USUBJID $ 40.;
	USUBJID=CATX("-", STUDY, PT);
	AESEQNO=INPUT(AEREFID, BEST.);
RUN;

PROC SORT DATA=AE_SAE_RAW SORTSEQ=LINGUISTIC(NUMERIC_COLLATION=ON);
	BY USUBJID AESEQNO;
RUN;

/*------------------------------------------------------------------------------------------------------------  */
/* RELATEED TO SERIOUS ADVERSE EVENT VARIABLES */
/*------------------------------------------------------------------------------------------------------------  */
DATA AE_SAE;
	MERGE AE_IDEN(IN=A) AE_SAE_RAW(IN=B);
	BY USUBJID AESEQNO;

	IF AESER="Y" THEN
		DO;

			/*Congenital Anomaly or Birth Defect  */
			IF SERCONG="X" THEN
				AESCONG="Y";

			/*Persist or Signif Disability/Incapacity  */
			IF SERDIS="X" THEN
				AESDISAB="Y";

			/*Results in Death */
			IF SERDIED="X" THEN
				AESDTH="Y";

			/*Requires or Prolongs Hospitalization  */
			IF SERHOSP="X" THEN
				AESHOSP="Y";

			/* Is Life Threatening */
			IF SERLIFE="X" THEN
				AESLIFE="Y";

			/*Other Medically Important Serious Event  */
			IF SERMEDEV="X" THEN
				AESMIE="Y";
		END;
	ELSE IF AESER="N" THEN
		DO;
			AESCONG="N";
			AESDISAB="N";
			AESDTH="N";
			AESHOSP="N";
			AESLIFE="N";
			AESMIE="N";
		END;
	ELSE IF AESER="Y" AND MISSING(AESCONG) AND MISSING(AESDISAB) AND 
		MISSING(AESDTH) AND MISSING(AESHOSP) AND MISSING(AESLIFE) AND MISSING(AESMIE) 
		THEN
			DO;
			AESCONG="";
			AESDISAB="";
			AESDTH="";
			AESHOSP="";
			AESLIFE="";
			AESMIE="";
		END;
	KEEP USUBJID AESEQNO AESCONG AESDISAB AESDTH AESHOSP AESLIFE AESMIE AESER;
RUN;

PROC SORT DATA=AE_SAE SORTSEQ=linguistic(NUMERIC_COLLATION=ON);
	BY USUBJID AESEQNO;
RUN;

/*------------------------------------------------------------------------------------------------------------  */
/*COMBINE AE_IDEN AND AE_SAE */
/*------------------------------------------------------------------------------------------------------------  */
DATA AE_IDEN_SAE;
	MERGE AE_IDEN(IN=A) AE_SAE(IN=B);
	BY USUBJID AESEQNO;
RUN;

PROC SORT DATA=AE_IDEN_SAE SORTSEQ=linguistic(NUMERIC_COLLATION=ON);
	BY USUBJID;
RUN;

/*------------------------------------------------------------------------------------------------------------  */
/* CALCULATE RELATIVE DAY VARIABLES */
/* COMBINE THE DM DATASET AND AE TO GET THE RFISTDTCC */
/*------------------------------------------------------------------------------------------------------------  */
PROC SORT DATA=GASTI_F.DM OUT=DM_RF1 SORTSEQ=linguistic(NUMERIC_COLLATION=ON);
	BY USUBJID RFSTDTC RFENDTC;
RUN;

PROC SORT DATA=AE_IDEN OUT=AE_RF1 SORTSEQ=LINGUISTIC(NUMERIC_COLLATION=ON);
	BY USUBJID;
RUN;

DATA AE_DAY_1;
	MERGE DM_RF1(IN=A) AE_RF1(IN=B);
	BY USUBJID;

	IF B;

/*------------------------------------------------------------------------------------------------------------  */
/* AE DATE AND TIME VARIABLE */
/*------------------------------------------------------------------------------------------------------------  */
	IF ONSETDTS NE "" AND ONSETDTS NE "******" THEN
		DO;
			AESTDTC=STRIP(ONSETDTS);
		END;
	ELSE
		AESTDTC="";

	IF AE_EDTS NE "" AND AE_EDTS NE "******" THEN
		DO;
			AEENDTC=STRIP(AE_EDTS);
		END;
	ELSE
		AEENDTC="";

	/* CONVERT THE ISO DATE TO SAS DATE */
	IF LENGTH(AESTDTC)=10 THEN
		AESDT=INPUT(AESTDTC, YYMMDD10.);
	ELSE
		AESDT=.;

	IF LENGTH(AEENDTC)=10 THEN
		AEENT=INPUT(AEENDTC, YYMMDD10.);
	ELSE
		AEENT=.;
	RFSDT=INPUT(RFSTDTC, YYMMDD10.);
	FORMAT AESDT AEENT RFSDT DATE9.;

/*------------------------------------------------------------------------------------------------------------  */
/*AESEQ NUMBER */
/*------------------------------------------------------------------------------------------------------------  */
	IF FIRST.USUBJID THEN
		AESEQ=1;
	ELSE
		AESEQ + 1;
	KEEP USUBJID AESDT AEENT RFSDT AESEQ RFSTDTC RFENDTC AESTDTC AEENDTC;
RUN;

PROC SORT DATA=AE_DAY_1 SORTSEQ=linguistic(NUMERIC_COLLATION=ON);
	BY USUBJID AESEQ;
RUN;

/*------------------------------------------------------------------------------------------------------------  */
/* CALCULATE THE AESTDY DAY VARIABLES */
/*------------------------------------------------------------------------------------------------------------  */
DATA AE_DAY_F;
	SET AE_DAY_1;
	BY USUBJID AESEQ;

	IF NOT MISSING(AEENT) AND NOT MISSING(RFSDT) THEN
		DO;

			IF AEENT GE RFSDT THEN
				AEENDY=AEENT - RFSDT + 1;
			ELSE
				AEENDY=AEENT - RFSDT;
		END;

	IF NOT MISSING(AESDT) AND NOT MISSING(RFSDT) THEN
		DO;

			IF AESDT GE RFSDT THEN
				AESTDY=AESDT - RFSDT + 1;
			ELSE
				AESTDY=AESDT - RFSDT;
		END;
	KEEP USUBJID AESTDY AEENDY AESEQ RFSTDTC AESDT AEENT AESTDTC AEENDTC;
RUN;

PROC SORT DATA=AE_DAY_F SORTSEQ=LINGUISTIC(NUMERIC_COLLATION=ON);
	BY USUBJID AESEQ;
RUN;

/*------------------------------------------------------------------------------------------------------------  */
/* MEDRA DICTIONARY VARIABLE */
/*------------------------------------------------------------------------------------------------------------  */
DATA AE_MED;
	SET AE_1_SORT;
	LENGTH USUBJID $ 40. AEREL $ 15. AESEV $ 10. AEACN $ 20.;
	USUBJID=CATX("-", STUDY, PT);
	AETERM=STRIP(MDLLTT);
	AELLT=STRIP(MDLLTT);
	AELLTCD=MDLLTC;
	AEDECOD=STRIP(MDPTT);
	AEPTCD=MDPTC;
	AEHLT=STRIP(MDHLTT);
	AEHLTCD="";
	AEHLGT=STRIP(MDHLGTT);
	AEHLGTCD="";
	AEBODSYS=STRIP(MDSOCT);
	AEBDSYCD=INPUT(MDSOCC, BEST.);
	AESOC=STRIP(MDSOCT);
	AESOCCD=INPUT(MDSOCC, BEST.);

	IF TOXGRADE="Grade 1 or mild" THEN
		DO;
			AETOXGR="1";
			AESEV="MILD";
		END;
	ELSE IF TOXGRADE="Grade 2 or moderate" THEN
		DO;
			AETOXGR="2";
			AESEV="MODERATE";
		END;
	ELSE IF TOXGRADE="Grade 3 or severe" THEN
		DO;
			AETOXGR="3";
			AESEV="SEVERE";
		END;

/*------------------------------------------------------------------------------------------------------------  */
/*Concomitant or Additional Trtmnt Given  */
/*------------------------------------------------------------------------------------------------------------  */
	IF CONMEDG NE "" THEN
		DO;

			IF CONMEDG="Yes" THEN
				AECONTRT="Y";
			ELSE IF CONMEDG="No" THEN
				AECONTRT="N";
		END;
	ELSE
		AECONTRT="";

/*------------------------------------------------------------------------------------------------------------  */
/*AEREL  */
/*------------------------------------------------------------------------------------------------------------  */
	IF UPCASE(STRIP(AECISREL))="YES" OR UPCASE(STRIP(AECAPREL))="YES" THEN
		AEREL="RELATED";
	ELSE IF UPCASE(STRIP(AECISREL))="NO" OR UPCASE(STRIP(AECAPREL))="NO" THEN
		AEREL="NOT RELATED";
	ELSE IF MISSING(AECISREL) AND MISSING(AECAPREL) THEN
		AEREL="";

/*------------------------------------------------------------------------------------------------------------  */
/*AEACN */
/*------------------------------------------------------------------------------------------------------------  */
	IF UPCASE(STRIP(CISACTN))="MEDICATION DISCONTINUED" OR 
		UPCASE(STRIP(CAPACTN))="MEDICATION DISCONTINUED" THEN
			AEACN="DRUG WITHDRAWN";
	ELSE IF UPCASE(STRIP(CISACTN))="DOSE REDUCTION" OR 
		UPCASE(STRIP(CAPACTN))="DOSE REDUCTION" THEN
			AEACN="DOSE REDUCED";
	ELSE IF UPCASE(STRIP(CISACTN))="MEDICATION DELAYED" OR 
		UPCASE(STRIP(CAPACTN))="MEDICATION DELAYED" THEN
			AEACN="DRUG INTERRUPTED";
	ELSE IF UPCASE(STRIP(CISACTN))="NONE" AND UPCASE(STRIP(CAPACTN))="NONE" THEN
		AEACN="DOSE NOT CHANGED";
	ELSE IF UPCASE(STRIP(CISACTN))="NOT APPLICABLE" AND 
		UPCASE(STRIP(CAPACTN))="NOT APPLICABLE" THEN
			AEACN="NOT APPLICABLE";
	KEEP USUBJID AETERM AELLT AELLTCD AEDECOD AEPTCD AEHLT AEHLTCD AEHLGT AEHLGTCD 
		AEBODSYS AEBDSYCD AESOC AESOCCD AETOXGR AESEV AECONTRT AEREL AEACN;
RUN;

PROC SORT DATA=AE_MED SORTSEQ=LINGUISTIC(NUMERIC_COLLATION=ON);
	BY USUBJID;
RUN;

/*------------------------------------------------------------------------------------------------------------  */
/* combine dataset */
/*------------------------------------------------------------------------------------------------------------  */
DATA AE_COMBINE22;
	MERGE AE_IDEN_SAE(IN=A) AE_DAY_F(IN=B) AE_MED(IN=C);
	BY USUBJID;
RUN;

PROC SORT DATA=AE_COMBINE22 NODUPKEY OUT=AE_LAST DUPOUT=AE_DUP 
		SORTSEQ=LINGUISTIC(NUMERIC_COLLATION=ON);
	BY USUBJID AETERM AEDECOD AESEV AETOXGR AESTDTC;
RUN;

/*------------------------------------------------------------------------------------------------------------  */
/* ASSIGN THE LABEL AND LENGTH TO THE VARIABLE  */
/*------------------------------------------------------------------------------------------------------------  */
PROC SQL NOPRINT;
	CREATE TABLE AE AS SELECT STUDYID LABEL="Study Identifier" LENGTH=15, DOMAIN 
		LABEL="Domain Abbreviation" LENGTH=2, USUBJID 
		LABEL="Unique Subject Identifier" LENGTH=20, AESEQ LABEL="Sequence Number" 
		LENGTH=8, AETERM LABEL="Reported Term for the Adverse Event" LENGTH=30, AELLT 
		LABEL="Lowest Level Term" LENGTH=30, AELLTCD LABEL="Lowest Level Term Code" 
		LENGTH=8, AEDECOD LABEL="Dictionary-Derived Term" LENGTH=40, AEPTCD 
		LABEL="Preferred Term Code" LENGTH=8, AEHLT LABEL="High Level Term" 
		LENGTH=50, AEHLTCD LABEL="High Level Term Code" LENGTH=8, AEHLGT 
		LABEL="High Level Group Term" LENGTH=50, AEHLGTCD 
		LABEL="High Level Group Term Code" LENGTH=8, AEBODSYS 
		LABEL="Body System or Organ Class" LENGTH=50, AEBDSYCD 
		LABEL="Body System or Organ Class Code" LENGTH=8, AESOC 
		LABEL="Primary System Organ Class" LENGTH=50, AESOCCD 
		LABEL="Primary System Organ Class Code" LENGTH=8, AESEV 
		LABEL="Severity/Intensity" LENGTH=10, AESER LABEL="Serious Event" LENGTH=1, 
		AEACN LABEL="Action Taken with Study Treatment" LENGTH=20, AEREL 
		LABEL="Causality" LENGTH=20, AEOUT LABEL="Outcome of Adverse Event" 
		LENGTH=40, AESCONG LABEL="Congenital Anomaly or Birth Defect" LENGTH=1, 
		AESDISAB LABEL="Persist or Signif Disability/Incapacity" LENGTH=1, AESDTH 
		LABEL="Results in Death" LENGTH=1, AESHOSP 
		LABEL="Requires or Prolongs Hospitalization" LENGTH=1, AESLIFE 
		LABEL="Is Life Threatening" LENGTH=1, AESMIE 
		LABEL="Other Medically Important Serious Event" LENGTH=1, AECONTRT 
		LABEL="Concomitant or Additional Trtmnt Given" LENGTH=1, AETOXGR 
		LABEL="Standard Toxicity Grade" LENGTH=1, AESTDTC 
		LABEL="Start Date/Time of Adverse Event" LENGTH=15, AEENDTC 
		LABEL="End Date/Time of Adverse Event" LENGTH=15, AESTDY 
		LABEL="Study Day of Start of Adverse Event" LENGTH=8, AEENDY 
		LABEL="Study Day of End of Adverse Event" LENGTH=8 FROM AE_LAST;
QUIT;

/*------------------------------------------------------------------------------------------------------------  */
/*-----------------------------------------------------------------------------------------------------  */
/*FINAL DATA  */
/*------------------------------------------------------------------------------------------- */
	LIBNAME GASTI_F "/home/u64240743/gastric/GASTRIC SDTM RESULT";

	DATA GASTI_F.AE (LABEL="ADVERSE EVENT");
	SET AE;
	RUN;

/*------------------------------------------------------------------------------------------- */
/* EXPORT AS XPT FORMAT */
/*------------------------------------------------------------------------------------------- */
	LIBNAME XPTFILE XPORT "/home/u64240743/gastric/GASTRIC_XPT/AE.XPT";

	PROC COPY IN=gasti_f OUT=XPTFILE;
	SELECT AE;
	RUN;

/*------------------------------------------------------------------------------------------------------------  */