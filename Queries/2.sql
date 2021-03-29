# Drugs associated to cancer type

#CREATE A VIEW TO COMPUTE THE AVG OF FPKM OF THE OV CANCER TYPE
CREATE VIEW FPKM_OV (GENE,AVG_FPKM) AS
SELECT GENE,AVG(RNA.FPKM) AS AVG_FPKM FROM RNA AS RNA where rna.Cancer = 'OV' GROUP BY RNA.GENE;

SELECT distinct Drugs
from oncokb_drug
where exists ( 
SELECT Hugo_gene 
from converter
where (EnsemblgeneID) in (
SELECT TH.GENE
FROM thresholds AS TH JOIN FPKM_OV AS FPKM_OV ON TH.GENE=FPKM_OV.GENE
WHERE TH.thsd<FPKM_OV.AVG_FPKM));


# OPPURE SHOW THE DIFFERENT TYPES OF ALTERATIONS GIVEN THAT THE GENE IS A TUMOR SUPPRESSOR AND THE CANCER IS OV
SELECT DISTINCT DR.Alterations
FROM oncokb_drug AS DR JOIN onco_genes AS GN ON DR.HUGO_GENE=GN.HUGO_GENE
WHERE GN.IsTumorSuppressorGene = 'YES' AND EXISTS(
SELECT Hugo_gene 
from converter
where (EnsemblgeneID) in (
SELECT GENE FROM RNA WHERE CANCER = 'OV'));
