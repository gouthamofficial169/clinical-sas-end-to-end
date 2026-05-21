# End-to-End Clinical SAS Programming Portfolio



#### Project Overview



This repository contains a comprehensive, self-directed, end-to-end clinical data programming pipeline developed using CDISC standards. Utilizing de-identified clinical trial data from the Project Data Sphere repository, this project replicates the exact workflows executed by a Statistical Programmer in a pharmaceutical or CRO environment—moving from raw clinical data mapping to regulatory submission-ready analysis packages and statistical reporting.



The project models a Phase III Oncology Study involving 436 subjects treated with Group B XP (Cisplatin \& Capecitabine). Working with a real de-identified dataset rather than synthetic data provided practical exposure to handling data quality issues, date-shifting anomalies, and missing values , which were systematically triaged and documented in a formal Reviewer's Guide.



#### Key Features \& Deliverables



* Data Mapping Specifications: Built comprehensive Excel-based mapping and derivation specs for SDTM and ADaM transitions.
* SDTM Implementation: Structural mapping of raw clinical data into 7 core domains and standard supplemental qualifiers following CDISC SDTMIG v3.4.
* ADaM Derivation: Building subject-level (ADSL), OCCDS, and BDS analysis datasets with full mathematical traceability following CDISC ADaMIG v1.3.
* TFL Generation: Production-grade statistical summary tables (Section 14) and patient listings (Section 16) formatted for Clinical Study Reports (CSR) using ICH E3 guidelines.
* Validation \& Compliance: Iterative programming quality control, rigorous SAS log validation, and Pinnacle 21 Community Edition compliance checks.
* Submission Readiness: Fully validated metadata-driven Define.xml (v2.1) packages and an authored formal Reviewer's Guide.





Repository Structure

clinical-sas-endtoend/

│

├── 01\_Specifications/             # Metadata Mapping \& Derivation Specifications

│   ├── SDTM\_Mapping\_Specifications.xlsx

│   └── ADaM\_Derivation\_Specifications.xlsx

│

├── 02\_SDTM\_Programs/              # SAS Source Code for SDTM Domains (.sas)

│   ├── dm.sas

│   ├── ae.sas

│   ├── ex.sas

│   ├── ds.sas

│   ├── lb.sas

│   ├── vs.sas

│   └── cm.sas

&#x20;   |\_\_\_ suppae.sas



├── 03\_ADaM\_Programs/              # SAS Source Code for ADaM Datasets (.sas)

│   ├── adsl.sas

│   ├── adae.sas

│   ├── adlb.sas

│   └── adcm.sas

│

|── 04\_TFL\_Programs/               # SAS Reporting Scripts for Tables \& Listings (.sas)

|   ├── L\_16\_2\_1.sas                #  All Adverse Events Listing

│   ├── L\_16\_2\_2.sas                # SAEs Leading to Death Listing

│   └── L\_16\_2\_3.sas                # Serious Adverse Events Listing

&#x20;   ├── T\_14\_1\_1.sas                # Demographics Summary Table

│   ├── T\_14\_1\_2.sas                # TEAE by treatment, soc and preferred term table

│   ├── T\_14\_1\_3.sas                # Laboratory Shift Table from baseline to end of treatment table

│   ├── T\_14\_1\_4.sas                # Concomitant Medications by preferred term table



|── 05\_Outputs/                    # Generated SAS Transport (.xpt) and Report Files (.rtf)

│   ├── ADaM\_Datasets/              # Validated ADaM v1.3 .xpt analysis files

│   ├── SDTM\_Datasets/              # Validated SDTM v3.4 .xpt domain files

│   └── Reports\_TFL/                # CSR-Compliant, high-fidelity report outputs



|── 06\_Submission\_Package/         # Standardized Regulatory Submission Components

├── ADaM\_Define/                    # Metadata package for ADaM (define.xml)

└── Reviewer\_Guide.pdf              # Comprehensive Study Reviewer's Guide (cDRG style)

├── SDTM\_Define/                    # Metadata package for SDTM (define.xml)

#### 

#### Technical Specifications \& Implementation Logic



##### 1\. SDTM Programming (Raw to SDTM Mapping)



Compliant with CDISC SDTMIG v3.4.

* Core Domains developed: Mapped raw clinical study data to DM (436 records), AE (7915 records), EX (4515 records), DS (1303 records), LB (91411 records), VS (3052 records), and CM (11944 records).
* Supplemental Qualifiers (SUPPAE): Developed using the SUPPQUAL structure to map non-standard clinical variables, ensuring proper population of RDOMAIN, QNAM, QLABEL, and QVAL conventions to capture multi-drug tracking specific to oncology trials.
* Special Advanced Logic: Handled complex raw drug splitting for combination therapies (Capecitabine and Cisplatin) by mapping multi-column source indicators safely into standard single-variable targets (AEREL and AEACN).



##### 2\. ADaM Programming (SDTM to ADaM Derivation)



Compliant with CDISC ADaMIG v1.3, prioritizing full traceabilities, window definitions, and audit trails back to parent SDTM sources.

* ADSL (Subject-Level Analysis): Programmed key baseline parameters, derived population flags (SAFFL - Safety, FASFL - Full Analysis Set, PPROTFL - Per-Protocol), derived treatment variables (TRT01P, TRT01A, TRT01PN), and treatment windows (TRTSDT, TRTEDT).
* ADAE (Adverse Events Analysis): Programmed using OCCDS frameworks. Derived the Treatment-Emergent flag (TRTEMFL) utilizing precise conditional date windows (ASTDT >= TRTSDT and ASTDT <= TRTEDT), along with ADURN (Analysis Duration), PREFL (Pre-existing Flag), and analysis selection flags (ANL01FL).
* ADLB (Laboratory Analysis): Derived BDS structural parameters including actual values (AVAL), baseline evaluations (BASE), change from baseline (CHG), percent change (PCHG), and normality shift indicators (ANRIND, BNRIND, SHIFT1 tracking baseline-to-post-baseline shifts).
* ADCM (Concomitant Medications Analysis): Captured timing classifications (ONTRTFL, PREFL, ANL01FL).



##### 3\. TFL Programming (Tables \& Data Listings)



Generated industry-standard outputs using advanced Base SAS reporting procedures (PROC REPORT, PROC FREQ, PROC MEANS) and Output Delivery System (ODS RTF) routing frameworks formatted to ICH E3 Section 14 and Section 16 rules.



1. Section 14 Statistical Tables:
* T\_14\_1\_1: Summary of Demographic and Baseline Characteristics
* T\_14\_1\_2: Treatment-Emergent Adverse Events (TEAEs) by System Organ Class (SOC) and Preferred Term (PT)
* T\_14\_1\_3: Laboratory Shift Table from baseline to end of treatment table
* T\_14\_1\_4: Concomitant Medications by Preferred Term



2\. Section 16 Patient Listings:

* L\_16\_2\_1: All Adverse Events Listing
* L\_16\_2\_2: SAEs Leading to Death Listing
* L\_16\_2\_3: Serious Adverse Events Listing



#### Quality Control \& Validation Workflow



This portfolio mirrors professional regulatory submission-ready checks by applying a multi-stage validation lifecycle:SAS Log Triage:

1. Executed 100% review of compiling execution logs to isolate, evaluate, and completely eliminate unintended notes, warnings, or error keywords (such as automatic data conversions, uninitialized variables, or overwriting loops).
2. Pinnacle 21 Community Validation: Ran formal compliance checks against CDISC rules.
* Remediated Issues: Resolved correctable mapping errors including duplicate exposures via PROC SORT NODUPKEY , Controlled Terminology mismatches, structural metadata inconsistencies, and flag tracking discrepancies.
* Justified Limitations: Systematically triaged and documented unavoidable validation alerts (e.g., missing Site IDs, missing country information, or date-shifting imbalances) inside the Reviewer's Guide using rule ID mappings to reflect anonymized clinical data constraints.  Define-XML Package: Created fully compliant Define.xml v2.1 structural code blocks using ODM standard criteria to encapsulate metadata specifications.

3\. Define-XML Package: Generated a fully compliant Define.xml v2.1 package using the Pinnacle 21 Community Edition to automatically encapsulate all dataset metadata and variables.



##### Core Technical Skills Demonstrated



* SAS Programming: Base SAS, Macro Language, PROC SQL, Data Step Logic, FIRST./LAST. programming, PROC TRANSPOSE, Advanced Reporting (PROC REPORT, ODS RTF).
* CDISC Data Standards: SDTM v3.4, ADaM v1.3, Define-XML v2.1, CDASH, CDISC Controlled Terminology.  Medical Dictionaries:
* Regulatory Frameworks: ICH E3 (Clinical Study Reports), ICH E6 R2 (GCP), FDA 21 CFR Part 11, eCTD submission structures.





