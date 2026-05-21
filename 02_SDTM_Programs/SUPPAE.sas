/*------------------------------------------------------------------------------------------------------------  */
/*****************************************************************************
 * Filename    : SUPPAE.sas
 * Author      : Goutham
 * Date        : &sysdate9.
 * SAS Version : SAS 9.4 (SAS ODA)
 * Platform    : Linux (SAS OnDemand Cloud)
 * Project     : EMR200048052 — EXPAND Trial
 * Description : Create SDTM AE — Supplemental Adverse Events Domain
 * Input       : GASTRIC.ade  (Raw AE Dataset — 7948 records)
 * Output      : GASTI_F.SUPPAE (Supplemental AE Qualifiers)
 * Standards   : SDTM IG v3.4 | CDISC CT 2026-03-27
 *****************************************************************************
 * MODIFICATION HISTORY
 * Date          Author    Description
 * -----------   --------  --------------------------------------------------
 * &sysdate9.    Goutham   Initial creation
 *****************************************************************************/

/*-----------------------------------------------------------------------------------  */
/*ASSIGN THE LIBRARY  */
/*-----------------------------------------------------------------------------------  */

LIBNAME GASTRIC "/home/u64240743/gastric";
RUN;

/*-----------------------------------------------------------------------------------  */

/*-----------------------------------------------------------------------------------  */
/*RELATIONSHIP VARIABLE  */
/*-----------------------------------------------------------------------------------  */

DATA SUPPAE_REL;
SET GASTRIC.ade;
BY PT;

LENGTH RDOMAIN QNAM QLABEL QVAL QORIG $ 40.;

STUDYID = STRIP(STUDY);

RDOMAIN = "AE";

USUBJID = CATX("-",STUDY,PT);

IF FIRST.PT THEN AESEQ=1;
ELSE AESEQ+1;

IDVAR = "AESEQ";

IDVARVAL = STRIP(PUT(AESEQ,BEST.));

QORIG = "CRF";

/*CAPECITABINE  */

QNAM = "CAPREL";

QLABEL = "Capecitabine Relationship";

QVAL = AECAPREL;

OUTPUT;

/*CISPLATIN  */

QNAM = "CISREL";

QLABEL = "Cisplatin Relationship";

QVAL = AECISREL;

OUTPUT;

KEEP STUDYID RDOMAIN USUBJID IDVAR IDVARVAL QORIG QNAM QLABEL QVAL;
RUN;

/*-----------------------------------------------------------------------------------  */

/*-----------------------------------------------------------------------------------  */
/*ACTION VARIABLE  */
/*-----------------------------------------------------------------------------------  */

DATA SUPPAE_ACT;
SET GASTRIC.ade;
BY PT;

LENGTH RDOMAIN QNAM QLABEL QVAL QORIG $ 40.;

STUDYID = STRIP(STUDY);

RDOMAIN = "AE";

USUBJID = CATX("-",STUDY,PT);

IF FIRST.PT THEN AESEQ=1;
ELSE AESEQ+1;

IDVAR = "AESEQ";

IDVARVAL = STRIP(PUT(AESEQ,BEST.));

QORIG = "CRF";

/*CAPECITABINE  */

QNAM = "CAPACT";

QLABEL = "Capecitabine Action Taken";

QVAL = CAPACTN;

OUTPUT;

/*CISPLATIN  */

QNAM = "CISACT";

QLABEL = "Cisplatin Action Taken";

QVAL = CISACTN;

OUTPUT;

KEEP STUDYID RDOMAIN USUBJID IDVAR IDVARVAL QORIG QNAM QLABEL QVAL;
RUN;
/*-----------------------------------------------------------------------------------  */

/*-----------------------------------------------------------------------------------  */
/* COMBINE DATA */
/*-----------------------------------------------------------------------------------  */

DATA SUPPAE_FINAL;
SET SUPPAE_REL SUPPAE_ACT;
RUN;

PROC SORT DATA=SUPPAE_FINAL
SORTSEQ=LINGUISTIC(NUMERIC_COLLATION=ON);
BY STUDYID USUBJID IDVAR IDVARVAL QNAM;
RUN;

PROC SQL NOPRINT;
CREATE TABLE SUPPAE AS
SELECT 
	STUDYID  LABEL= "Study Identifier"				LENGTH=15,
    RDOMAIN  LABEL= "Related Domain Abbreviation"		LENGTH=3,
    USUBJID  LABEL= "Unique Subject Identifier"		LENGTH=20,
    IDVAR    LABEL= "Identifying Variable"			LENGTH=5,
    IDVARVAL LABEL= "Identifying Variable Value"		LENGTH=5,
    QNAM     LABEL= "Qualifier Variable Name"			LENGTH=10,
    QLABEL   LABEL= "Qualifier Variable Label"		LENGTH=30,
    QVAL     LABEL= "Data Value"						LENGTH=10,
    QORIG    LABEL= "Origin"							LENGTH=5
    
FROM SUPPAE_FINAL;
QUIT;

	
/*-----------------------------------------------------------------------------------------------------  */
/*FINAL DATA  */
/*------------------------------------------------------------------------------------------- */

	
	LIBNAME GASTI_F "/home/u64240743/gastric/GASTRIC SDTM RESULT";
	DATA GASTI_F.SUPPAE;
	SET SUPPAE;
	RUN;
/*------------------------------------------------------------------------------------------- */

/* EXPORT AS XPT FORMAT */
	
	LIBNAME XPTFILE XPORT "/home/u64240743/gastric/GASTRIC_XPT/SUPPAE.XPT";
	PROC COPY IN=gasti_f OUT=XPTFILE;
	SELECT SUPPAE;
	RUN;

