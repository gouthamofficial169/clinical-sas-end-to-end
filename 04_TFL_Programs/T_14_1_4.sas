
/*-----------------------------------------------------------------------------------  */
/*ASSIGN THE LIBRARY  */
/*-----------------------------------------------------------------------------------  */

LIBNAME GASTI_AD "/home/u64240743/gastric/GASTRIC ADAM"; RUN;

/*-----------------------------------------------------------------------------------  */

/*-----------------------------------------------------------------------------------  */
DATA CM_TABLE_O1;
SET GASTI_AD.adcm;
IF SAFFL = "Y";
IF NOT MISSING(CMDECOD);
RUN;

PROC SQL NOPRINT;
CREATE TABLE TOPN AS
SELECT TRTAN, COUNT(DISTINCT USUBJID) AS COUNT,"Overall" AS CMDECOD LENGTH=50
FROM CM_TABLE_O1
GROUP BY TRTAN
ORDER BY TRTAN;

SELECT COUNT INTO: BIGN TRIMMED  FROM TOPN;
QUIT;

%PUT N=&BIGN;

PROC SQL NOPRINT;
CREATE TABLE CM_BODY AS
SELECT CMDECOD,TRTAN, COUNT(DISTINCT USUBJID) AS COUNT
FROM CM_TABLE_O1
GROUP BY CMDECOD,TRTAN
ORDER BY CMDECOD,TRTAN;
QUIT;

/*COMBINE DATA  */

DATA CM_COMBINE_1;
SET TOPN(IN=A) CM_BODY(IN=B);

IF A THEN DO; ORDER=1;END;
ELSE IF B THEN DO; ORDER=2;END;
RUN;

/*CALCULATE PERCENTAGE  */

DATA CM_PERCENT;
SET CM_COMBINE_1;

TRT = STRIP(PUT(COUNT,BEST.))||" ("|| STRIP(PUT((COUNT/&BIGN)*100,5.1))||")";

DROP TRTAN COUNT;
RUN;


DATA CM_ALL_FINAL;
SET CM_PERCENT;

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
 
ODS RTF FILE="~/T_14_1_4.rtf" 
STYLE= STYLES.TEST ;  
 
 
TITLE J=L "Protocol: EMR200048-052" 
J=R  "Page ^{pageof}";
 
TITLE3 J=C "Table 14.1.4 Concomitant Medication by Preferred Term";
Title4 J=C "Safety Population – Group B (Cisplatin and Capecitabine)" ;
 
footnote1 j=L "Source: &_SASPROGRAMFILE" j=R "Date: &sysdate9."; 

ODS ESCAPECHAR= "^";

proc report data=CM_ALL_FINAL split='*' missing nocenter headskip

style = {outputwidth= 100%};
COLUMN PAG1 ORDER CMDECOD TRT;

*Order variables; 
define PAG1/order noprint;
define ORDER/order noprint;

 
 *Reported columns; 
define CMDECOD/DISPLAY "Preferred WHO Name" style(column)={just=L cellwidth=30%}
 						 style(header)={just=l};
 define TRT/DISPLAY 'Group-B*(n=&BIGN)' style(column)={just=L cellwidth=10%}
                         style(header)={just=l};
COMPUTE AFTER ORDER;
line '';
 endcomp;
 
compute before _page_;
    line @1
      "^{style[
               bordertopcolor=black
               bordertopstyle=solid
               bordertopwidth=0pt]}";
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

 


