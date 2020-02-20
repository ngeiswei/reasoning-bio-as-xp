# atomese import of GTEx RNAseq tissue expression dataset

## Overview

The GTEx data set consists of RNAseq whole transcriptome TPM levels in up to 54 tissue types 
from a cohort of 948 fresh cadavers aged 20-80 years, 84% white, 15% black, and 1% other 
from the U.S.  
It is hoped that including this data in the human biology atomspace with the correct semantics 
will provide grounding knowledge for generating a morphism between inference procedures in the 
atomspace and algebra on vectorspace embeddings of this knowledge hypergraph.  

## notation

for subject Sp, p [1...l]; tissue Tq, q = [1...m]; gene Gr, r = [1...n];  
Spq is a sample of tissue Tq from subject Sp (subjects have at most 1 sample per tissue);  
normalized expression level for Gr in Tq in Spq = Epqr  
with sums represented by category count subscript,  
e.g. subject count = Sl, tissue count = Tm, total samples of tissue Tq = Slq  
For expression level E with 2 transcripts, the value is the median over all samples,  
e.g. the the median across all samples of the expression levels for gene Gr in tissue Tq = Eqr,  
and the sum of the median of all gene expression levels across all samples in tissue Tq = Eqn  

# semantic model

ContextLink < Epqr / Elmn, Epqr / (Epqr + 800) >
  ConceptNode "GTEx dataset"
  AndLink
    ConceptNode "human Sp" < 1 / Sl, Sl / (Sl + 800) > (this could be weighted by the number of tissue samples for Sp ?)
    EvaluationLink < Eqr / Emn, Eqr / (Eqr + 800) >
      PredicateNode "is transcribed in" < sum(Gr where Eqr > 0) / Gn, sum(Gr where Eqr > 0) / (sum(Gr where Eqr > 0) + 800) >
	ListLink 
	  ConceptNode "tissue Tq" < Slq / Slm, Slq / (Slq + 800) > (ie fraction of Tq in all samples)
	  GeneNode "gene Gr" < 1 / Gn, Gn / (Gn + 800) > (this could be weighted by Emr / Emn ?)

# discussion

The intent with these semantics is that for the initial demonstration of PLN, only the 
EvaluationLinks need to be included atomspace, with the context of individual subjects 
implied by the truth values.  
Extending the knowledge base to include individuals with particular gene variants will 
be possible by explicitly including the experimental context and subject specific knowledge.  

