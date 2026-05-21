
/*------------------------------------------------------------------------------------------------  */
/* IMPORT THE LIBRARY */
/*------------------------------------------------------------------------------------------------  */
LIBNAME GASTI_F "/home/u64240743/gastric/GASTRIC SDTM RESULT";RUN;
LIBNAME GASTI_AD "/home/u64240743/gastric/GASTRIC ADAM";
RUN;

/*------------------------------------------------------------------------------------------------  */
/* CALCULATE THE BIGN */
/*------------------------------------------------------------------------------------------------  */

PROC SQL NOPRINT;
CREATE TABLE TRT AS 
SELECT TRTA,TRTAN, COUNT(DISTINCT USUBJID)  AS DENOM
FROM GASTI_AD.ADLB
GROUP BY TRTA,TRTAN
ORDER BY TRTA,TRTAN;

SELECT DENOM INTO: BIGN FROM TRT;
QUIT;

%PUT BIGN = &BIGN;

/*------------------------------------------------------------------------------------------------  */
/*MAIN BODY  */
/*------------------------------------------------------------------------------------------------  */
DATA SHIFT_1;
SET GASTI_AD.adlb;
IF SAFFL = "Y" AND PARCAT1 IN ("BIOCHEMISTRY" "HEMATOLOGY");
TRTA=TRTP;
TRTAN=TRTPN;

KEEP USUBJID AVISITN PARAM PARCAT1 ANRIND BNRIND TRTAN;
RUN;

DATA SHIFT_2;
SET SHIFT_1;

IF BNRIND = "" THEN BNRIND = "MISSING";
IF ANRIND = "" THEN ANRIND = "MISSING";

RUN;


PROC SORT DATA=SHIFT_2;
BY USUBJID PARCAT1 PARAM AVISITN;RUN;

DATA SHIFT_3;
SET SHIFT_2;

BY USUBJID PARCAT1 PARAM AVISITN;
IF LAST.PARAM;
RUN;

PROC FREQ DATA= SHIFT_3 NOPRINT;
TABLES PARCAT1*PARAM*BNRIND*ANRIND*TRTAN / OUT= SHIFT_4 (DROP=PERCENT RENAME=(COUNT=N));
RUN;

DATA SHIFT_PCT;
MERGE SHIFT_4(IN=A) TRT(IN=B);
BY TRTAN;
PCT1 = N/DENOM*100;

PCTF = STRIP(PUT(N,4.)) || "(" || STRIP(PUT(PCT1,5.1)) || ")";
RUN;
 
PROC SORT DATA=SHIFT_PCT;
BY PARCAT1 PARAM BNRIND;
RUN;

PROC TRANSPOSE DATA=SHIFT_PCT OUT= PCT_T;
BY PARCAT1 PARAM BNRIND;
ID ANRIND;
VAR PCTF;
RUN;

DATA SHIFT_5;
SET PCT_T;

IF LOW = "" THEN LOW= "0";
IF HIGH = "" THEN HIGH= "0";
IF NORMAL = "" THEN NORMAL= "0";
IF MISSING = "" THEN MISSING= "0";

DROP _NAME_;
RUN;

DATA SHIFT_6;
SET SHIFT_5;

RETAIN NUM PAG1 0;
NUM+1; 

IF NUM>16 THEN DO;
PAG1 = PAG1 + 1;
NUM=1;
END;
RUN;

DATA SHIFT_7;
SET SHIFT_6;
if parcat1 = "BIOCHEMISTRY" then do; od=1;end;
if parcat1 = "HEMATOLOGY" then do; od=2;end;

RUN;

proc sort data=shift_7 out= shift_final;
by od parcat1 param BNRIND pag1 ;
run;


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
 
ODS RTF FILE="~/T_14_1_3.rtf" 
STYLE= STYLES.TEST ;  
 
 
TITLE J=L "Protocol: EMR200048-052" 
J=R  "Page ^{pageof}";
 
TITLE3 J=C "Table 14.1.3  Laboratory Shift Table From Baseline to End of Period";
Title4 J=C "Safety Population – Group B (Cisplatin and Capecitabine)" ;
 
footnote1 J=L "1.Baseline = Last non-missing value on or before first dose date." ;
footnote2 "2. LOW = Below lower limit of normal (LLN); HIGH = Above upper limit of normal (ULN).";
footnote3 j=L "Source: &_SASPROGRAMFILE" j=R "Date: &sysdate9."; 

ODS ESCAPECHAR= "^";

proc report data=shift_final split='*' missing nocenter headskip

style = {outputwidth= 100%};
COLUMN OD PAG1 PARCAT1 PARAM BNRIND
("Treatment end* (N=436)" "^{style[borderbottomwidth=0pt
              borderbottomcolor=black
              borderbottomstyle=solid]}"
low Normal High Missing);

*Order variables; 
define PAG1/order noprint;
define od /order order=internal noprint;
 
 *Reported columns; 
 define parcat1 / ORDER 'Parameter*Category' style(column)={just=L cellwidth=10%}
 						 style(header)={just=l};
 define param /order 'Parameter (Unit)' style(column)={just=L cellwidth=22%}
                         style(header)={just=l};
  compute after param;
  line "";
  endcomp;
 define bnrind / display "Baseline"  style(column)={just=L cellwidth=8%}
 										   style(header)={just=l};
 define low / display "Low" style(column)={just=l cellwidth=8%}
 										   style(header)={just=l}; 
 define normal / display "Normal" style(column)={just=L cellwidth=8%}
 										   style(header)={ just=l};
 define high / display "High"  style(column)={just=L cellwidth=8%}
 										   style(header)={just=l};
 define missing / display "Missing"  style(column)={just=L cellwidth=8%}
 										   style(header)={just=l};
compute before _page_;
    line @1
      "^{style[
               bordertopcolor=black
               bordertopstyle=solid
               borderbottomwidth=0pt]}";
  endcomp;


compute after _page_;
    line @1
      "^{style[
               borderbottomwidth=0pt
               borderbottomcolor=black
               borderbottomstyle=solid]}";
  endcomp;

  *Derived page breaking; 
 break after PAG1/page;
 

run;
ods rtf close;

 
 
 


