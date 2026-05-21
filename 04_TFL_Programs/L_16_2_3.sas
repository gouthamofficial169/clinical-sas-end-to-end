/*-----------------------------------------------------------------------------------------*/
/* IMPORT THE ADAM PROGRAMMING FILE LIBRARY */
/*-----------------------------------------------------------------------------------------*/
LIBNAME GASTI_AD "/home/u64240743/gastric/GASTRIC ADAM RESULT";RUN;
/*-----------------------------------------------------------------------------------------*/

DATA SE_LIST_01;
SET GASTI_AD.adae;
LENGTH TBD $ 300.;
IF AESER = "Y";

TBD = CATX("/",AETERM,AEBODSYS,AEDECOD);

SUBORD= INPUT(SCAN(USUBJID,-1,"-"),BEST.);

KEEP SUBORD USUBJID TBD AESTDTC AEENDTC AESER AEACN AEREL AEOUT;

RUN;

PROC SORT DATA=SE_LIST_01;
BY SUBORD;
RUN;

DATA SE_LIST_02;
SET SE_LIST_01;

RETAIN NUM 0 PAG 1;
NUM+1;

IF NUM>24 THEN DO; 
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


OPTIONS ORIENTATION=LANDSCAPE NODATE NONUMBER;

ODS LISTING CLOSE;
 
ODS RTF FILE="~/L_16_2_3.rtf" 
STYLE= STYLES.TEST ;  
 
 
TITLE J=L "Protocol: EMR200048-052" 
J=R  "Page ^{pageof}";
 
TITLE3 J=C "Table 16.2.3 Serious Adverse Events";
 
footnote1 j=L "Source: &_SASPROGRAMFILE" j=R "Date: &sysdate9."; 

ODS ESCAPECHAR= "^";

proc report data=SE_LIST_02 split='*' missing nocenter headskip

style = {outputwidth= 100%};
COLUMN PAG SUBORD USUBJID TBD AESTDTC AEENDTC AESER AEACN AEREL AEOUT ;

*Order variables; 
define PAG/ORDER noprint;
define SUBORD/ORDER noprint;

 *Reported columns; 
	define USUBJID /ORDER 'Subj.*No.' 
	style(column)={just=L cellwidth=15%}
	style(header)={just=l};

	define TBD / "Adverse Event/Primary System Organ*Class/Preferred term"  
	style(column)={just=L cellwidth=30%}
 	style(header)={just=l};
 	
 	define AESTDTC / "Start*Date/time"  
	style(column)={just=L cellwidth=10%}
 	style(header)={just=l};
 	
 	define AEENDTC / "End*Date/time"  
	style(column)={just=L cellwidth=10%}
 	style(header)={just=l};
 	
 	define AESER / "Serious*Event"  
	style(column)={just=L cellwidth=6%}
 	style(header)={just=l};

	define AEACN / "Action*Taken"  
	style(column)={just=L cellwidth=8%}
 	style(header)={just=l};
 	
 	define AEREL / "Relationship*to*study drug"  
	style(column)={just=L cellwidth=10%}
 	style(header)={just=l};
 	
 	define AEOUT / "Outcome"  
	style(column)={just=L cellwidth=10%}
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
 break after PAG/page;
 

run;
ods rtf close;
