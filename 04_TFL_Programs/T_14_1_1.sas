/*-----------------------------------------------------------------------------------------  */
/* ASSIGN THE ADSL LIBRARY */

/*-----------------------------------------------------------------------------------------  */
LIBNAME GASTI_AD "/home/u64240743/gastric/GASTRIC ADAM";
/*-----------------------------------------------------------------------------------------  */

DATA TABLE_DM1;
	SET GASTI_AD.adsl;
	
	IF TRT01A = "CAPECITABINE + CISPLATIN" THEN DO; TRT= "GROUPA"; ORD = 1;END;
RUN;

PROC SUMMARY DATA=TABLE_DM1 NWAY;
	CLASS TRT; 
	VAR AGE;
	OUTPUT OUT=AGE1
	MEAN = _MEAN MEDIAN = _MEDIAN STD = _SD MIN = _MIN MAX = _MAX Q1 = _Q1 Q3 = _Q3;
RUN;

DATA AGE2;
	SET AGE1;
	
	MEANSD= COMPRESS(PUT(_MEAN,4.1))||"("||COMPRESS(PUT(_SD,4.1))||")" ;
	MEDIAN = COMPRESS(PUT(_MEDIAN,4.1));
	MNMX =  COMPRESS(PUT(_MIN,3.0)) || "," || COMPRESS(PUT(_MAX,3.0));
	Q1Q3 = COMPRESS(PUT(_Q1,3.0)) || "," || COMPRESS(PUT(_Q3,3.0));
	
RUN;

	
PROC TRANSPOSE DATA=AGE2 OUT=AGE3;
	ID TRT;
	VAR MEANSD MEDIAN MNMX Q1Q3;
RUN;

DATA AGE4;
	RETAIN CAT STAT A;
	SET AGE3;
	LENGTH STAT CAT $ 15.;
	
	IF _NAME_  = "MEANSD" THEN DO; STAT = "Mean (SD)";ORD=1; END;
	IF _NAME_  = "MEDIAN" THEN DO; STAT = "Median"; ORD=2; END;
	IF _NAME_  = "MNMX" THEN DO; STAT = "Min, Max"; ORD=3; END;
	IF _NAME_  = "Q1Q3" THEN DO; STAT = "Q1, Q3"; ORD=4; END;
	
	IF _N_ = 1 THEN  CAT = "Age (Years)"; ELSE CAT = "";
	DROP _NAME_ ;
	
	OD = 1;
RUN;


proc sort data=age4;
by ord od;

/*-----------------------------------------------------------------------------------------  */
/*AGE CATEOGORY  */
/*-----------------------------------------------------------------------------------------  */
/*  Step 1 — Create format with exact labels */
/*-----------------------------------------------------------------------------------------  */
proc format;
  value agegrpf
    1 = "< 65 Years"
    2 = ">= 65 Years";
run;

/*-----------------------------------------------------------------------------------------  */
/* Step 2 — Assign age group in ADSL */
/*-----------------------------------------------------------------------------------------  */
data adsl_age;
  set TABLE_DM1 ;
  where SAFFL = "Y";

  if      AGE <  65 then AGEGR1N = 1;
  else if AGE >= 65 then AGEGR1N = 2;
  else                   AGEGR1N = .;

  format AGEGR1N agegrpf.;
run;

/*-----------------------------------------------------------------------------------------  */
/* Step 3 — Get total N for denominator */
/*-----------------------------------------------------------------------------------------  */
proc sql noprint;
  select count(*) into :total_n
  from adsl_age
  where not missing(AGEGR1N);
quit;
%put Total N = &total_n.;

/*-----------------------------------------------------------------------------------------  */
/* Step 4 — Get actual counts */
/*-----------------------------------------------------------------------------------------  */

proc freq data=adsl_age noprint;
  tables AGEGR1N / out=age_actual (drop=percent) missing;
run;

/*-----------------------------------------------------------------------------------------  */
/* Step 5 — Create SKELETON with ALL categoriesThis forces >= 65 to appear even with zero count */
/*-----------------------------------------------------------------------------------------  */

data age_skeleton;
  length AGEGR1N 8; 
  AGEGR1N = 1; output;   /* < 65  */
  AGEGR1N = 2; output;   /* >= 65 */
run;

/*-----------------------------------------------------------------------------------------  */
/* Step 6 — Merge skeleton with actual counts */
/*-----------------------------------------------------------------------------------------  */
proc sort data=age_actual;   by AGEGR1N; run;
proc sort data=age_skeleton; by AGEGR1N; run;

data agec_final;
  merge age_skeleton (in=a)
        age_actual   (in=b);
  by AGEGR1N;
  LENGTH STAT CAT $ 15.;

  /* Calculate percentage using total N */
  if not b then do;
    COUNT   = 0;
  end;

  format AGEGR1N agegrpf.;
  
  cat = "";
  
  if agegr1n = 1 then do stat = "<65 YEARS"; ORD =1;end;
  if agegr1n = 2 then do stat = ">= 65 YEARS";ORD = 2;end;
  
  GROUPA = strip(put(count,3.))||'('||strip(put(count/&total_n*100,3.))||'%'||')';
  
  OD = 2;
  
  drop count agegr1n;
run;


proc sort data=agec_final;
by ord od;


/*-----------------------------------------------------------------------------------------  */
/*COMBINE THE AGE AND AGE CATEOGORY */
/*-----------------------------------------------------------------------------------------  */

DATA AGE_FINAL;
SET AGE4 AGEC_FINAL;
VARORD = 1;
RUN;


proc sort data=AGE_FINAL;
by od;




/*-----------------------------------------------------------------------------------------  */
/*SEX*/
/*-----------------------------------------------------------------------------------------  */

PROC FREQ DATA=TABLE_DM1 NOPRINT;
TABLES TRT*SEX/ OUT=SEX1 (DROP=PERCENT);
RUN;

DATA SEX2;
SET SEX1;
LENGTH STAT $ 15.;

IF SEX = "M" THEN DO; STAT = "Male";ORD= 1;END; 
IF SEX = "F" THEN DO; STAT = "Female"; ORD =2 ;END;

RUN; 

PROC SORT DATA=SEX2;
BY ORD STAT;
RUN;

PROC TRANSPOSE DATA=SEX2;
BY ORD STAT;
ID TRT;
VAR COUNT;
RUN;

DATA SEX3;
RETAIN CAT STAT GROUPA;
SET SEX2;
LENGTH CAT $ 15.;

GROUPA = strip(PUT(COUNT,3.))||"("||strip(PUT(COUNT/&total_n*100,3.))||'%'||')';
IF _N_ = 1 THEN CAT = "SEX — n (%)";
ELSE CAT = "";
OD = 3;
VARORD = 1;
KEEP CAT STAT GROUPA ORD OD;
RUN;

proc sort data=sex3;
by ord od;

/*RACE  */


PROC FREQ DATA=TABLE_DM1 NOPRINT;
    TABLE TRT*RACE / OUT=RACE2(DROP=PERCENT);
RUN;

DATA RACE3;
SET RACE2;
LENGTH STAT CAT $ 15.;

IF RACE = "WHITE" THEN DO; STAT = "White"; ord=1;END;
IF RACE = "ASIAN" THEN DO; STAT = "Asian"; ord= 2;END;
IF RACE = "BLACK OR AFRICAN AMERICAN" THEN DO; STAT = "Black"; ord= 3;END;
IF RACE = "OTHER" THEN DO; STAT = "Other/Unknown"; ord=4;END;;

GROUPA = strip(PUT(COUNT,3.))||"("||strip(PUT(COUNT/&TOTAL_N*100,3.))||"%"||")";


OD=4;


KEEP STAT GROUPA ORD OD;
RUN;

PROC SORT DATA=RACE3;
BY OD ORD;
RUN;

DATA RACE4;
RETAIN CAT STAT GROUPA ;
SET RACE3;
LENGTH CAT $ 15.;
IF _N_ = 1 THEN CAT = "RACE — n (%)"; ELSE CAT = "";
VARORD = 1;
RUN;

/*CALCULATE THE BMI,HEIGHT AND WEIGHT  */

%MACRO STATG (VAR=, OUTPUT=,TITLE=, OD=);



PROC SUMMARY DATA=TABLE_DM1 NWAY;
	CLASS TRT; 
	VAR &VAR;
	OUTPUT OUT=&OUTPUT.1
	MEAN = _MEAN MEDIAN = _MEDIAN STD = _SD MIN = _MIN MAX = _MAX Q1 = _Q1 Q3 = _Q3;
RUN;

DATA &OUTPUT.2;
	SET &OUTPUT.1;
	
	MEANSD= COMPRESS(PUT(_MEAN,4.1))||"("||COMPRESS(PUT(_SD,4.1))||")" ;
	MEDIAN = COMPRESS(PUT(_MEDIAN,4.1));
	MNMX =  COMPRESS(PUT(_MIN,3.0)) || "," || COMPRESS(PUT(_MAX,3.0));
	Q1Q3 = COMPRESS(PUT(_Q1,3.0)) || "," || COMPRESS(PUT(_Q3,3.0));
	
RUN;

	
PROC TRANSPOSE DATA=&OUTPUT.2 OUT=&OUTPUT.3;
	ID TRT;
	VAR MEANSD MEDIAN MNMX Q1Q3;
RUN;

DATA &OUTPUT.4;
	RETAIN CAT STAT A;
	SET &OUTPUT.3;
	LENGTH STAT CAT $ 15.;
	
	IF _NAME_  = "MEANSD" THEN DO; STAT = "Mean (SD)";ORD=1; END;
	IF _NAME_  = "MEDIAN" THEN DO; STAT = "Median"; ORD=2; END;
	IF _NAME_  = "MNMX" THEN DO; STAT = "Min, Max"; ORD=3; END;
	IF _NAME_  = "Q1Q3" THEN DO; STAT = "Q1, Q3"; ORD=4; END;
	
	IF _N_ = 1 THEN  CAT = &TITLE; ELSE CAT = "";
	DROP _NAME_ ;
	
	OD = &OD;
	
	VARORD = 2;
RUN;

%MEND;

/*CALLING MACRO FOR WEIGHT  */;

%STATG (VAR= WEIGHTBL,OUTPUT=WEIGHT,TITLE= 'WEIGHT (kg)',OD=5);

/*CALLING MACRO FOR HEIGHT */;

%STATG (VAR= HEIGHTBL,OUTPUT=HEIGHT,TITLE= 'HEIGHT (cm)',OD=6);

/*CALLING MACRO FOR BMI */;

%STATG (VAR= BMIBL,OUTPUT=BMI,TITLE= 'BMI (kg/m2)',OD=7);


/*COMBINE  ALL DATA  */

DATA D1_F;
SET AGE_FINAL SEX3 RACE4 WEIGHT4 HEIGHT4 BMI4;
RUN;
PROC SORT DATA=D1_F;
BY OD;RUN;

DATA DEMOFINAL;
SET D1_F;

RETAIN NUM 0 PAG 1;
NUM+1;

IF NUM > 12 THEN DO; 
PAG=PAG+1;
NUM=1;
END;

RUN;



/*proc template macro  */


%macro _RTFSTYLE_ ;

proc template;
define style styles.test;
    parent= styles.rtf ;
    replace fonts/
   'BatchFixedFont'= ("Courier New",9pt)
   'TitleFont2'= ("Courier New",9pt)
   'TitleFont' = ("Courier New",9pt)
   'StrongFont'= ("Courier New",9pt)
   'EmphasisFont'= ("Courier New",9pt)
   'FixedEmphasisFont'= ("Courier New",9pt)
   'FixedStrongFont'= ("Courier New",9pt)
   'FixedFont'= ("Courier New",9pt)
   'FixedHeadingFont'= ("Courier New",9pt)
   'HeadingEmphasisFont'= ("Courier New",9pt)
   'headingFont'= ("Courier New",9pt)
   'DocFont'= ("Courier New",9pt);
      replace table from output /
      		cellpadding=0pt
      		cellspacing=0pt
      		borderwidth=0.50pt
      	background= white
      	frame=void;
    replace color_list /
    'link'= black
    'bgh'=white
    'fg'= black
    'bg'=white;
       replace body from document /
       bottommargin=1.00in
       topmargin=1.00in
       rightmargin=1.00in
       leftmargin=1.00in;
       
  end;
  run;
  
%mend _RTFSTYLE_ ;
%_RTFSTYLE_;




options orientation=landscape nodate nonumber;

ods listing close;
 
 
 ods rtf file="~/T_14_1_1.rtf" 
 style= styles.test ;  
 
 
 title j=c "Table 14.1.1 — Demographic and Baseline Characteristics";
 
 title2 j=c "Summary Statistics by Treatment Group — Safety Population";
 title3 j=c "Analysis Population: Safety Population (Group B: Cisplatin + Capecitabine, N=(436))" ;
 
 footnote1 j=l "Note: Percentages based on Safety Population (N)." ;
footnote2 j=l "Note: BMI derived as Weight(kg)/Height(m)^2.";

footnote3 j=l "Source: &_SASPROGRAMFILE" j=r "Date: &sysdate9."; 


proc report data=DEMOFINAL split='*' missing nowd headline headskip spacing=0
style(report)={outputwidth=100%};

column PAG od CAT STAT GROUPA;

* Order variables;
define od/order order=internal noprint;
define PAG/order order=internal noprint;

*Derived page breaking; 
 break after PAG/page;


 compute AFTER od ;
 line '';
 endcomp;
 

* Main columns;
define CAT / display 'Characteristic'
    style(column)={just=l }
    style(header)={just=l};

define STAT / display 'Statistic'
    style(column)={just=l }
    style(header)={just=l};

define GROUPA / display "Group B (N=436)"
    style(column)={just=c }
    style(header)={just=c};
    

compute before _page_;
    line @1
      "^{style[
               bordertopcolor=black
               bordertopstyle=solid
               bordertopwidth=0.5pt]}";
endcomp;


compute after _page_;
    line @1
      "^{style[
               bordertopcolor=black
               bordertopstyle=solid
               bordertopwidth=0pt]}";
  endcomp;

run;
ods rtf close;
 
 
 


