# OPTIMIZATION
CREATE TABLE RNA_OPT(
HUGO_GENE VARCHAR(30),
SAMPLE VARCHAR(30),
CANCER VARCHAR(10),
FPKM DOUBLE,
PRIMARY KEY (HUGO_GENE,SAMPLE));

INSERT INTO RNA_OPT (SELECT HUGO,SAMPLE,CANCER,FPKM FROM RNA);

SELECT * FROM RNA_OPT;
###########

CREATE TABLE ONCOKB_DRUGS_OPT(
HUGO_GENE VARCHAR(30),
ALTRATIONS VARCHAR(900),
CANCERTYPES VARCHAR(100),
DRUGS VARCHAR(50));

INSERT INTO ONCOKB_DRUGS_OPT(select * from oncokb_drug);

# SET INDEX
create index DRUGS on ONCOKB_DRUGS_OPT(DRUGS) using btree;
###########

CREATE TABLE ONCO_GENES_OPT(
HUGO_GENE VARCHAR(30),
ONCOKBANNOTATED BOOL,
ISONCOGENE BOOL,
ISTUMORSUPPRESSORGENE BOOL,
PRIMARY KEY (HUGO_GENE));

INSERT INTO ONCO_GENES_OPT(
SELECT HUGO_GENE,ONCOKBANNOTATED,ISONCOGENE,ISTUMORSUPPRESSORGENE FROM ONCO_GENES);

###########
CREATE TABLE thresholds_opt (gene text(10), thsd double); 

INSERT INTO thresholds_opt (
						SELECT hugo_gene, AVG(fpkm) AS thsd 
						FROM rna_opt
						GROUP BY hugo_gene); 

###############################################

#OPTIMIZED QUERY
# 1. 
# Show the number of sample for cancer type that pass the thsd and have the given associated drug
SELECT RNA_O.CANCER, COUNT(DISTINCT RNA_O.SAMPLE) as NUM_SAMPLE
FROM RNA_OPT AS RNA_O JOIN THRESHOLDS_OPT AS TH ON RNA_O.HUGO_GENE=TH.GENE 
WHERE RNA_O.FPKM>TH.THSD 
AND EXISTS (SELECT HUGO_GENE FROM ONCOKB_DRUG WHERE DRUGS='Afatinib')
GROUP BY RNA_O.CANCER; 

#3. 
# Find tumor suppressor genes that are overexpressed in at least [8,30] types of cancer
SELECT COUNT(DISTINCT RNA.CANCER) AS NUM_CANCER, RNA.HUGO_GENE
FROM RNA_OPT AS RNA JOIN THRESHOLDS_OPT AS TH ON RNA.HUGO_GENE=TH.GENE
WHERE RNA.FPKM>TH.THSD 
AND EXISTS (
		SELECT HUGO_GENE 
		FROM ONCO_GENES_OPT 
		WHERE ISTUMORSUPPRESSORGENE = 1) 
GROUP BY RNA.HUGO_GENE
HAVING NUM_CANCER > 8 AND NUM_CANCER < 30
ORDER BY NUM_CANCER;

#7.
# Find the percentage of genes that pass the oncogene filter and are overexpressed given a cancer type
#CREATE A VIEW TO COMPUTE THE AVG OF FPKM OF THE BLCA CANCER TYPE

CREATE VIEW FPKM_BLCA_OPT (GENE,AVG_FPKM) AS
SELECT HUGO_GENE,AVG(RNA.FPKM) AS AVG_FPKM FROM RNA_OPT AS RNA where rna.Cancer = 'BLCA' GROUP BY RNA.HUGO_GENE;

SELECT (
	SELECT COUNT(DISTINCT TH.GENE)
	FROM THRESHOLDS_OPT AS TH JOIN FPKM_BLCA_OPT AS FPKM_BLCA ON TH.GENE=FPKM_BLCA.GENE
	WHERE TH.THSD<FPKM_BLCA.AVG_FPKM
	AND EXISTS (
			SELECT HUGO_GENE FROM ONCO_GENES_OPT WHERE ISONCOGENE = 1))
/ 
(SELECT COUNT(*) FROM THRESHOLDS_OPT) * 100 AS PERCENTAGE; 

#10.
# Given a sample ID, return a list of overexpressed gene and possible type of alterations
SELECT DISTINCT HUGO_GENE, ALTERATIONS
FROM ONCOKB_DRUGS_OPT
WHERE EXISTS ( 
		SELECT RNA.HUGO_GENE
		FROM RNA_OPT AS RNA JOIN THRESHOLDS_OPT AS TH ON RNA.HUGO_GENE = TH.GENE
		WHERE RNA.FPKM>TH.THSD AND RNA.SAMPLE = 'TCGA-2F-A9KO-01A'); 
        
#2.
# SHOW THE DIFFERENT TYPES OF DRUGS GIVEN THAT THE GENE IS A TUMOR SUPPRESSOR AND THE CANCER IS 'OV'
SELECT DISTINCT DR.drugs
FROM oncokb_drugs_opt AS DR JOIN onco_genes_opt AS GN ON DR.HUGO_GENE=GN.HUGO_GENE
WHERE GN.IsTumorSuppressorGene = 1 
AND EXISTS(
		SELECT HUGO_GENE FROM RNA_OPT WHERE CANCER = 'OV');         
  
#6.
# Show the gene whose number of drugs associated is more than 1 or 2 than but are not oncogene
SELECT HUGO_GENE, IsTumorSuppressorGene,isoncogene
FROM oncokb_drugs_opt JOIN onco_genes_opt USING (hugo_gene)
WHERE isoncogene = 0
GROUP BY hugo_gene
HAVING COUNT(drugs)<2
ORDER BY COUNT(drugs) desc; 
        
#8.
# Find hugo_gene id subjected to a specific type of alteration 
SELECT Hugo_gene FROM oncokb_drugs_opt WHERE alterations = 'Fusions'; 
