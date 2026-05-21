/*------------------------------------------------------------------------------------------------  */
/*ASSIGN THE LIBRARY  */
/*------------------------------------------------------------------------------------------------  */

LIBNAME GASTI_AD "/home/u64240743/gastric/GASTRIC ADAM"; RUN;

/*------------------------------------------------------------------------------------------------  */

/*------------------------------------------------------------------------------------------------  */
DATA AE_TB_1;
SET GASTI_AD.ADSL;
IF SAFFL = "Y";

IF TRT01A = "CAPECITABINE + CISPLATIN" THEN DO; TRT="B"; ORD=1;END;
KEEP USUBJID TRT ORD;
RUN;

/*------------------------------------------------------------------------------------------------  */
/*CALCULATE THE BIGN COUNT  */
/*------------------------------------------------------------------------------------------------  */

PROC SQL NOPRINT;
SELECT COUNT (DISTINCT USUBJID) INTO: N TRIMMED FROM AE_TB_1
GROUP BY ORD
ORDER BY ORD;
QUIT;
%PUT BIGN = &N;

/*-------------------------------------------------------------------------------------------------- */

DATA AE_TB_2;
SET GASTI_AD.ADAE;

IF SAFFL = "Y"  AND TRTEMFL = "Y";
IF TRTA = "CAPECITABINE + CISPLATIN" THEN DO; TRT="B"; ORD=1;END;
RUN;


PROC SQL NOPRINT;
CREATE TABLE AE_TB_ANY AS
SELECT TRT,COUNT (DISTINCT USUBJID) AS N, "Number of Subjects with TEAEs" as AEBODSYS
LENGTH=200 FROM AE_TB_2
GROUP BY TRT;

CREATE TABLE AE_TB_SOC AS
SELECT TRT,AEBODSYS,COUNT (DISTINCT USUBJID) AS N
FROM AE_TB_2
GROUP BY TRT,AEBODSYS;


CREATE TABLE AE_TB_POT AS
SELECT TRT,AEBODSYS,AEDECOD,COUNT (DISTINCT USUBJID) AS N
FROM AE_TB_2
GROUP BY TRT,AEBODSYS,AEDECOD;

QUIT;




DATA AE_TB_ALL;
SET AE_TB_ANY AE_TB_SOC AE_TB_POT;
IF AEBODSYS = "Number of Subjects with TEAEs" THEN do; ORD=0;end;
ELSE ORD=1;
RUN;

PROC SORT DATA=AE_TB_ALL;
BY trt ORD AEBODSYS AEDECOD;
RUN;

PROC TRANSPOSE DATA=AE_TB_ALL OUT=TB_ALL_T;
ID TRT;
BY ORD AEBODSYS AEDECOD;
RUN;

/*CALCULATE PERCENTAGE  */

DATA TB_PERCENT;
SET TB_ALL_T;
LENGTH GROUPB $ 100.;

IF B = . THEN GROUPB = "0";
ELSE IF B=&N THEN GROUPB=strip(PUT(B,3.)||"(100%)");
ELSE GROUPB = strip(PUT(B,3.))|| "("|| strip(PUT(B/&N*100,4.1))||"%"|| ")";

IF AEDECOD = "" AND AEBODSYS NE "" THEN DO; AEBODSYS1=AEBODSYS; OD+1;End;
ELSE AEBODSYS1="    "||AEDECOD;

KEEP AEBODSYS AEDECOD AEBODSYS1 GROUPB OD ORD;
RUN;


DATA TB_ALL_FINAL;
SET TB_PERCENT;

RETAIN NUM 0 PAG1 1;
NUM+1; 

IF NUM>24 THEN DO;
PAG1 = PAG1 + 1;
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


OPTIONS ORIENTATION=LANDSCAPE NODATE NONUMBER;

ODS LISTING CLOSE;
 
ODS RTF FILE="~/T_14_1_2.rtf" 
STYLE= STYLES.TEST ;  
 
 
TITLE J=L "Protocol: EMR200048-052" 
J=R  "Page ^{pageof}";
 
TITLE3 J=C "Table 14.1.2 Treatment Emergent Adverse Events by Treatment, System Organ Class and Preferred Term";
Title4 J=C "Safety Population – Group B (Cisplatin and Capecitabine)" ;
 
footnote1 J=L "TEAEs: Treatment-emergent adverse events." ;
footnote2 "Subjects are counted once within each System Organ Class and Preferred Term.";
footnote3 "n = Number of subjects with at least one event.";
footnote4 "N = Number of subjects in the safety population. % = 100 × n/N.";
footnote5 j=L "Source: &_SASPROGRAMFILE" j=R "Date: &sysdate9."; 

ODS ESCAPECHAR= "^";

proc report data=TB_ALL_FINAL split='*' missing nocenter headskip

style = {outputwidth= 100%};
COLUMN pag1 OD AEBODSYS AEDECOD AEBODSYS1 
("Treatment" "^{style[borderbottomwidth=0pt
              borderbottomcolor=black
              borderbottomstyle=solid]}"
GROUPB);

*Order variables; 
define PAG1/group noprint;
define AEBODSYS/order noprint;
define AEDECOD/order noprint;
define od /order order=internal noprint;
/* define ord /order order=internal noprint; */
 
 *Reported columns; 
define AEBODSYS1 / display 'MedDRA System Organ Class*   MedDRA Preferred Term' style(column)={just=L cellwidth=30% asis=on}
 						 style(header)={just=l};
  compute before od;
  line "";
  endcomp;
define groupb / display "Group-B*(n=436)"  style(column)={just=L cellwidth=10%}
 										   style(header)={just=l};

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

  *Derived page breaking; 
 break after PAG1/page;
 

run;
ods rtf close;

 
 

