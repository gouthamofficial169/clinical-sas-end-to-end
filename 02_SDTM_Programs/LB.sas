/*--------------------------------------------------------------------------------------------- */
/*****************************************************************************
* Filename    : LB.sas
* Author      : Goutham
* Date        : &sysdate9.
* SAS Version : SAS 9.4 (SAS ODA)
* Platform    : Linux (SAS OnDemand Cloud)
* Project     : EMR200048052 — EXPAND Trial
* Description : Create SDTM LB — Laboratory Test Results Domain
*               Unit standardization: 100+ raw units mapped to CDISC CT
* Input       : GASTRIC.labs_chem  (Biochemistry raw data)
*               GASTRIC.labs_hema (Hematology raw data)
* Output      : GASTI_F.LB (Laboratory Test Results Domain)
* Standards   : SDTM IG v3.4 | CDISC CT 2026-03-27
*****************************************************************************
* MODIFICATION HISTORY
* Date          Author    Description
* -----------   --------  --------------------------------------------------
* &sysdate9.    Goutham   Initial creation
*****************************************************************************/


/*--------------------------------------------------------------------------------------------- */
/*ASSIGN THE LIBRARY  */
LIBNAME GASTRIC "/home/u64240743/gastric";
RUN;
/*-------------------------------------------------------------------------------------------- */
/*  STACK THE DATASET */
DATA LB_MERGE;
SET GASTRIC.labs_chem GASTRIC.labs_hema;
PROC SORT OUT=LB_SORT;
BY PT T_GRP STUDY;
RUN;

/* --------------------------------------------------------------------------------------------- */
/*1.IDENTIFIERS  */

DATA LB_1;
SET LB_MERGE;

STUDYID= STRIP(STUDY);

DOMAIN= "LB";

USUBJID= CATX('-',STUDYID,PT);

RUN;

PROC SORT DATA=lb_1 OUT=LB_2SORT;BY PT STUDYID USUBJID T_GRP;

RUN;
/*--------------------------------------------------------------------------------------------------  */
/*DERIVE THE SEQUENCE NUMBER  */
DATA LB_2;
SET LB_2SORT;
BY STUDYID PT;
IF FIRST.PT THEN LBSEQ=1;
ELSE LBSEQ+1;

/*VISITNUM MAPPING ------------ LOGIC CYCLE*100 + DAY */
VISIT = STRIP(VISIT);

CYCLE = INPUT(SCAN(VISIT,2,""),??BEST.);
DAY = INPUT(SCAN(VISIT,4,""),??BEST.);
VISITNUM = (CYCLE*100)+DAY;

IF VISIT = "Screening" THEN VISITNUM = 1;
IF VISIT = "Lab retest" THEN VISITNUM = 998;
IF VISIT = "Imaging" THEN VISITNUM = 999; 


/* ASSIGN THE CATEGORY VARIABLE */

LBCAT= UPCASE(STRIP(T_GRP));
RUN;

/*-------------------------------------------------------------------------------------------------------  */

/*2. TEST VARIABLES  */

DATA LB_3F;
SET LB_2;
LENGTH LBTEST $ 50. LBTESTCD $ 20. LBORRESU $ 20.;

IF NOT MISSING(PARAM) THEN DO;

    SELECT (UPCASE(PARAM));

        WHEN ("ALAT") DO;
            LBTEST= "Alanine Aminotransferase";
            LBTESTCD= "ALT";
        END;

        WHEN ("ASAT") DO;
            LBTEST = "Aspartate Aminotransferase";
            LBTESTCD= "AST";
        END;

        WHEN ("AP") DO;
            LBTEST= "Alkaline Phosphatase";
            LBTESTCD= "ALP";
        END;

        WHEN ("CALCIUM") DO;
            LBTEST= "Calcium";
            LBTESTCD= "CA";
        END;

        WHEN ("CREATININE") DO;
            LBTEST= "Creatinine";
            LBTESTCD= "CREAT";
        END;

        WHEN ("GFR") DO;
            LBTEST= "Glomerular Filtration Rate";
            LBTESTCD= "GFR";
        END;
        
        WHEN ("GFR AUTOCALC") DO;
        	 LBTEST= "Glomerular Filtration Rate";
            LBTESTCD= "GFR";
        END;	

        WHEN ("LACTATE DEHYDROGENASE (LDH)") DO;
            LBTEST= "Lactate Dehydrogenase";
            LBTESTCD= "LDH";
        END;

        WHEN ("MAGNESIUM") DO;
            LBTEST= "Magnesium";
            LBTESTCD= "MG";
        END;

        WHEN ("PHOSPHATE") DO;
            LBTEST= "Phosphate";
            LBTESTCD= "PHOS";
        END;

        WHEN ("POTASSIUM") DO;
            LBTEST= "Potassium";
            LBTESTCD= "K";
        END;

        WHEN ("SERUM ALBUMIN") DO;
            LBTEST= "Albumin";
            LBTESTCD= "ALB";
        END;

        WHEN ("SODIUM") DO;
            LBTEST= "Sodium";
            LBTESTCD= "SODIUM";
        END;

        WHEN ("TOTAL BILIRUBIN") DO;
            LBTEST= "Bilirubin";
            LBTESTCD= "BILI";
        END;

        /* HEMATOLOGY */

        WHEN ("WBC (LEUCOCYTES)") DO;
            LBTEST= "Leukocytes";
            LBTESTCD= "WBC";
        END;

        WHEN ("ABSOLUTE NEUTROPHILE COUNT") DO;
            LBTEST= "Neutrophils";
            LBTESTCD= "NEUT";
        END;

        WHEN ("HEMOGLOBIN") DO;
            LBTEST= "Hemoglobin";
            LBTESTCD= "HGB";
        END;

        WHEN ("PLATELETS") DO;
            LBTEST= "Platelets";
            LBTESTCD= "PLAT";
        END;

        OTHERWISE DO;
            LBTEST = "";
            LBTESTCD = "";
        END;

    END;

END;

	
/*-------------------------------------------------------------------------------------------------- */
/* RESULT VARIABLES */
/*-------------------------------------------------------------------------------------------------- */

LBORRES=STRIP(LOC_RESC);

/*ORIGINAL RESULT UNIT  */

IF LOC_UNIT = "mIU/mL" THEN LBORRESU = "IU/L";
ELSE IF LOC_UNIT = "mL/min" THEN LBORRESU = "mL/min";
ELSE IF LOC_UNIT = "mU/mL" THEN LBORRESU = "U/L";
ELSE IF LOC_UNIT = "mg/dL" THEN LBORRESU = "mg/dL";
ELSE IF LOC_UNIT = "mg/mL" THEN LBORRESU = "g/L";
ELSE IF LOC_UNIT = "mmol/L" THEN LBORRESU = "mmol/L";
ELSE IF LOC_UNIT = "mval/L" THEN LBORRESU = "mEq/L";
ELSE IF LOC_UNIT = "ukat/L" THEN LBORRESU = "ukat/L";
ELSE IF LOC_UNIT = "umol/L" THEN LBORRESU = "umol/L";
ELSE IF LOC_UNIT = "mEq/L" THEN LBORRESU = "mEq/L";
ELSE IF LOC_UNIT = "g/dL" THEN LBORRESU = "g/dL";
ELSE IF LOC_UNIT = "g/L" THEN LBORRESU = "g/L";
ELSE IF LOC_UNIT = "g%" THEN LBORRESU = "g/dL";
ELSE IF LOC_UNIT = "U/L" THEN LBORRESU = "U/L";
ELSE IF LOC_UNIT = "IU/L" THEN LBORRESU = "IU/L";
ELSE IF LOC_UNIT = "10^9/L" THEN LBORRESU = "10^9/L";
ELSE IF LOC_UNIT = "10^3/mcL" THEN LBORRESU = "10^9/L";
ELSE IF LOC_UNIT = "/mcL" THEN LBORRESU = "10^9/L";
ELSE IF LOC_UNIT = "mcmol/L" THEN LBORRESU = "umol/L";

/*ORIGINAL RANGE VALUE  */

LBORNRLO= STRIP(LOW);

LBORNRHI= STRIP(HIGH);

RUN;

/*DERIVE A STANDARDIZED UNIT AND RESULT FROM ORIGINAL UNIT  */
DATA LB_STDF;
SET LB_3F;

LENGTH LBSTRESU $15 LBNRIND $ 15.;

IF LBORRES = "not measurable" THEN DO;
    LBSTRESN = .;
    LBSTRESC = STRIP(LBORRES);
    LBSTRESU = STRIP(LBORRESU);
END;
ELSE DO;
/* ================== ENZYMES ================== */
IF LBORRESU IN ("U/L","IU/L") THEN DO;
    LBSTRESU = "U/L";
    LBSTRESN = round(INPUT(LBORRES,??BEST.),0.01);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;
ELSE IF LBORRESU = "ukat/L" THEN DO;
    LBSTRESU = "U/L";
    LBSTRESN = round(INPUT(LBORRES,?? BEST.)*60,0.01);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;

/* ================== CREATININE ================== */
ELSE IF LBTEST = "Creatinine" AND LBORRESU = "umol/L" THEN DO;
    LBSTRESU = "umol/L";
    LBSTRESN = round(INPUT(LBORRES,??BEST.),0.01);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;

ELSE IF LBTEST = "Creatinine" AND LBORRESU = "mg/dL" THEN DO;
    LBSTRESU = "umol/L";
    LBSTRESN = round(INPUT(LBORRES,??BEST.)*88.4,0.01);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;


/* ================== BILIRUBIN ================== */
ELSE IF LBTEST = "Bilirubin" AND LBORRESU = "umol/L" THEN DO;
    LBSTRESU = "umol/L";
    LBSTRESN = round(INPUT(LBORRES,??BEST.),0.01);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;

ELSE IF LBTEST = "Bilirubin" AND LBORRESU = "mg/dL" THEN DO;
    LBSTRESU = "umol/L";
    LBSTRESN = round(INPUT(LBORRES,??BEST.)*17.1,0.01);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;

/* ================== CALCIUM ================== */
ELSE IF LBTEST = "Calcium" AND LBORRESU = "mmol/L" THEN DO;
    LBSTRESU = "mmol/L";
    LBSTRESN = round(INPUT(LBORRES,??BEST.),0.01);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;
ELSE IF LBTEST = "Calcium" AND LBORRESU = "mEq/L" THEN DO;
    LBSTRESU = "mmol/L";
    LBSTRESN = round(INPUT(LBORRES,??BEST.)/2,0.01);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;

ELSE IF LBTEST = "Calcium" AND LBORRESU = "mg/dL" THEN DO;
    LBSTRESU = "mmol/L";
    LBSTRESN = round(INPUT(LBORRES,??BEST.)*0.2495,0.01);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;

/* ================== MAGNESIUM ================== */
ELSE IF LBTEST = "Magnesium" AND LBORRESU = "mmol/L" THEN DO;
    LBSTRESU = "mmol/L";
    LBSTRESN = round(INPUT(LBORRES,??BEST.),0.01);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;

ELSE IF LBTEST = "Magnesium" AND LBORRESU = "mEq/L" THEN DO;
    LBSTRESU = "mmol/L";
    LBSTRESN = round(INPUT(LBORRES,??BEST.)/2,0.01);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;

ELSE IF LBTEST = "Magnesium" AND LBORRESU = "mg/dL" THEN DO;
    LBSTRESU = "mmol/L";
    LBSTRESN = round(INPUT(LBORRES,??BEST.)*0.4114,0.01);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;

/* ================== PHOSPHATE ================== */
ELSE IF LBTEST = "Phosphate" AND LBORRESU = "mmol/L" THEN DO;
    LBSTRESU = "mmol/L";
    LBSTRESN = round(INPUT(LBORRES,??BEST.),0.01);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;

ELSE IF LBTEST = "Phosphate" AND LBORRESU = "mg/dL" THEN DO;
    LBSTRESU = "mmol/L";
    LBSTRESN = round(INPUT(LBORRES,??BEST.)*0.3229,0.01);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;

/* ================== HEMOGLOBIN ================== */
ELSE IF LBTEST = "Hemoglobin" AND LBORRESU = "g/L" THEN DO;
    LBSTRESU = "g/dL";
    LBSTRESN = round(INPUT(LBORRES,??BEST.)/10,0.01);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;

ELSE IF LBTEST = "Hemoglobin" AND LBORRESU = "g/dL" THEN DO;
    LBSTRESU = "g/dL";
    LBSTRESN = round(INPUT(LBORRES,??BEST.),0.01);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;

ELSE IF LBTEST = "Hemoglobin" AND LBORRESU = "mmol/L" THEN DO;
    LBSTRESU = "g/dL";
    LBSTRESN = round(INPUT(LBORRES,??BEST.)*1.6113,0.01);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;

/* ================== ALBUMIN ================== */
ELSE IF LBTEST = "Albumin" AND LBORRESU = "g/L" THEN DO;
    LBSTRESU = "g/L";
    LBSTRESN = round(INPUT(LBORRES,??BEST.),0.01);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;

ELSE IF LBTEST = "Albumin" AND LBORRESU = "mg/dL" THEN DO;
    LBSTRESU = "g/L";
    LBSTRESN = round(INPUT(LBORRES,??BEST.)/100,0.01);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;
ELSE IF LBTEST = "Albumin" AND LBORRESU = "g/dL" THEN DO;
    LBSTRESU = "g/L";
    LBSTRESN = round(INPUT(LBORRES,??BEST.)*10,0.01);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;

/* ================== GFR ================== */
ELSE IF LBORRESU = "mL/min" THEN DO;
    LBSTRESU = "mL/min";
    LBSTRESN = INPUT(LBORRES,??BEST.);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;

/* ================== HEMATOLOGY ================== */
ELSE IF LBTEST IN ("Leukocytes","Neutrophils","Platelets") THEN DO;

    LBSTRESU = "10^9/L";

    IF LBORRESU = "10^9/L" THEN LBSTRESN = LBORRES;
    ELSE IF LOC_UNIT = "/mcL" AND LBORRESU = "10^9/L" THEN LBSTRESN = ROUND(LBORRES/1000,0.01);
	LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;

/* ================== ELECTROLYTES ================== */
ELSE IF LBTEST IN ("Potassium","Sodium") AND LBORRESU= "mmol/L" THEN DO;

    LBSTRESU = "mmol/L"; 
    LBSTRESN = round(INPUT(LBORRES,??BEST.),0.01);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;

ELSE IF LBTEST IN ("Potassium","Sodium") AND LBORRESU= "mEq/L" THEN DO;

    LBSTRESU = "mmol/L";
    LBSTRESN = round(INPUT(LBORRES,??BEST.),0.01);
    LBSTRESC = STRIP(PUT(LBSTRESN,BEST.));
END;

END;
    
/*------------------------------------------------------------------------------------------  */
/*REFERENCE RANGE FOR STANDRAD  */
/*--------------------------------------------------------------------------------------------- */

LBSTNRLO = INPUT(REF_LOW,BEST.);
LBSTNRHI = INPUT(REF_HIGH,BEST.);

/*--------------------------------------------------------------------------------------------- */
/*INDICATOR VARIABLE  */
/*--------------------------------------------------------------------------------------------- */

IF NOT MISSING(LBSTRESN) THEN DO;

/* BOTH RANGES AVAILABLE — FULL DETERMINATION */
IF NOT MISSING(LBSTNRLO) AND NOT MISSING(LBSTNRHI) THEN DO;
      IF      LBSTRESN < LBSTNRLO THEN LBNRIND = "LOW";
      ELSE IF LBSTRESN > LBSTNRHI THEN LBNRIND = "HIGH";
      ELSE                             LBNRIND = "NORMAL";
END;

/* ONLY LOWER RANGE AVAILABLE */
/* CAN DETERMINE LOW BUT NOT HIGH */
ELSE IF NOT MISSING(LBSTNRLO) AND MISSING(LBSTNRHI) THEN DO;

      IF LBSTRESN < LBSTNRLO THEN LBNRIND = "LOW";
      
      ELSE                        LBNRIND = ""; /* CANNOT CONFIRM NORMAL OR HIGH */
END;

/* ONLY UPPER RANGE AVAILABLE */
/* CAN DETERMINE HIGH BUT NOT LOW */
ELSE IF MISSING(LBSTNRLO) AND NOT MISSING(LBSTNRHI) THEN DO;
      IF LBSTRESN > LBSTNRHI THEN LBNRIND = "HIGH";
      ELSE                        LBNRIND = ""; /* CANNOT CONFIRM NORMAL OR LOW */
END;

/* BOTH RANGES MISSING */
/* CANNOT DETERMINE ANYTHING */
ELSE DO;
      LBNRIND = "";
END;

END;


LBLOBXFL= "";

/*--------------------------------------------------------------------------------------------- */
/*DATE VARIABLE */
/*--------------------------------------------------------------------------------------------- */
IF NOT MISSING (COLLDT) THEN DO;
LBDTC= PUT(COLLDT,E8601DA10.);
END;
ELSE LBDTC = "";

RUN;

/*--------------------------------------------------------------------------------------------- */
/* GETTING RFSTDTC FROM DM */
/*--------------------------------------------------------------------------------------------- */
PROC SQL;
CREATE TABLE LB_DAY AS
SELECT A.*,B.RFSTDTC 
FROM LB_STDF A 
LEFT JOIN GASTI_F.DM B 
ON A.USUBJID = B.USUBJID;
QUIT;

/*--------------------------------------------------------------------------------------------- */
/* DAY VARIABLE */
/*--------------------------------------------------------------------------------------------- */

DATA LB_DAY_FINAL;
SET LB_DAY;
/* CONVERT CHAR TO NUM USING THE INPUT()  */
LBDATE = INPUT(LBDTC, YYMMDD10.);
RFDATE = INPUT(RFSTDTC, YYMMDD10.);

IF LBDATE GE RFDATE THEN LBDY =  LBDATE-RFDATE +1;
ELSE LBDY = LBDATE - RFDATE;
RUN;
/*--------------------------------------------------------------------------------------------- */

/*--------------------------------------------------------------------------------------------- */
DATA LB_FINAL1;
SET LB_DAY_FINAL;
KEEP 
	STUDYID
	DOMAIN
	USUBJID
	LBSEQ
	LBTESTCD
	LBTEST
	LBCAT
	LBORRES
	LBORRESU
	LBORNRLO
	LBORNRHI
	LBSTRESC
	LBSTRESN
	LBSTRESU
	LBSTNRLO
	LBSTNRHI
	LBNRIND
	LBLOBXFL
	VISITNUM
	VISIT
	LBDTC
	LBDY;
RUN;
/*--------------------------------------------------------------------------------------------- */

PROC SORT 
SORTSEQ=LINGUISTIC(NUMERIC_COLLATION = ON);
BY USUBJID VISIT VISITNUM;
RUN;
/*--------------------------------------------------------------------------------------------- */

/*--------------------------------------------------------------------------------------------- */
PROC SQL;
CREATE TABLE LB_S AS
SELECT
    STUDYID     LENGTH= 15  LABEL="Study Identifier",
    DOMAIN      LENGTH=2   LABEL="Domain Abbreviation",
    USUBJID     LENGTH=18  LABEL="Unique Subject Identifier",
    LBSEQ       LENGTH=8    LABEL="Sequence Number",
    LBTESTCD    LENGTH=8   LABEL="Lab Test or Examination Short Name",
    LBTEST      LENGTH=30  LABEL="Lab Test or Examination Name",
    LBCAT       LENGTH=18  LABEL="Category for Lab Test",

    LBORRES     LENGTH=10  LABEL="Result or Finding in Original Units",
    LBORRESU    LENGTH=10  LABEL="Original Units",
    LBORNRLO    LENGTH=10  LABEL="Reference Range Lower Limit in Orig Unit",
    LBORNRHI    LENGTH=10  LABEL="Reference Range Upper Limit in Orig Unit",

    LBSTRESC    LENGTH=10  LABEL="Character Result/Finding in Std Format",
    LBSTRESN    LENGTH=8    LABEL="Numeric Result/Finding in Standard Units",
    LBSTRESU    LENGTH=10  LABEL="Standard Units",
    LBSTNRLO    LENGTH=8    LABEL="Reference Range Lower Limit-Std Units",
    LBSTNRHI    LENGTH=8    LABEL="Reference Range Upper Limit-Std Units",

    LBNRIND     LENGTH=6   LABEL="Reference Range Indicator",
    LBLOBXFL    LENGTH=1   LABEL="Last Observation Before Exposure Flag",
    
    VISITNUM    LENGTH=8    LABEL="Visit Number",
    VISIT    	LENGTH=15   LABEL="Visit Name",
    LBDTC       LENGTH=15  LABEL="Date/Time of Specimen Collection",
    LBDY 		LENGTH=5  LABEL="Study Day of Specimen Collection"

FROM LB_FINAL1;
QUIT;
/*--------------------------------------------------------------------------------------------- */

/*--------------------------------------------------------------------------------------------- */
/*SORTING AND REMOVAL OF DUPLICATES */
/*--------------------------------------------------------------------------------------------- */

PROC SORT DATA=LB_S NODUPKEY DUPOUT=DUP OUT=LB
SORTSEQ=LINGUISTIC(NUMERIC_COLLATION=ON);
BY USUBJID VISITNUM LBCAT LBSTRESC LBTESTCD LBCAT LBDTC LBDY ;
RUN;

-----------------------------------------------------------------------------------------------------  */
/*FINAL DATA  */
/*------------------------------------------------------------------------------------------- */

	LIBNAME GASTI_F "/home/u64240743/gastric/GASTRIC SDTM RESULT";
	DATA GASTI_F.LB (LABEL="Laboratory Test Results");
	SET LB;
	RUN;
/*------------------------------------------------------------------------------------------- */
/* EXPORT AS XPT FORMAT */
/*--------------------------------------------------------------------------------------------- */
	
	LIBNAME XPTFILE XPORT "/home/u64240743/gastric/GASTRIC_XPT/LB.XPT";
	PROC COPY IN=gasti_f OUT=XPTFILE;
	SELECT LB;
	RUN;
	
/*--------------------------------------------------------------------------------------------- */



	