# Goal

Process Drosophila melanogaster RNA-seq data of https://www.ncbi.nlm.nih.gov/bioproject/PRJNA388952 into RefEx RDF format.

# Downloads

- [Drosophila melanogaster reference genome](https://bit.ly/2yGCakv)  
  Used `dmel-all-chromosome-r6.28.fasta.gz`
- [Drosophila melanogaster genome annotation](https://bit.ly/2OH4Sg4)  
  Used `dmel-all-filtered-r6.28.gff.gz`
- [SraRunTable](https://www.ncbi.nlm.nih.gov/Traces/study/?acc=PRJNA388952&go=go)  
  Check `flybase species id` and filter with `fbsp00000001`. Check all the 256 runs and download the RunInfo Table. It is downloaded as `SraRunTable.txt`.  
- [Sample annotation of the project](https://bit.ly/2KhUjvH)  
  `GSE99574_All_samples_with_title.txt.gz`
- Programs  
  `hisat2_index.cwl` and `hisat2-stringtie_wf_se.cwl` of [Pitagora-cwl](https://github.com/sh-ikeda/pitagora-cwl)  
  [rdfize_refex_cwl](https://github.com/sh-ikeda/rdfize_refex_cwl)
# Procedures  
Build a HISAT2 index
```
$ cwltool /path/to/pitagora-cwl/tools/hisat2/index/hisat2_index.cwl --reference_fasta genome/dmel-all-chromosome-r6.28.fasta --index_basename dmel_index
```

Extract FlyBase annotations from the genome annotation.
```
$ awk -F "\t" '$2=="FlyBase"&&/FB/{print}' dmel-all-filtered-r6.28.gff > dmel-all-filtered-r6.28.fb.gff
```

Each sample has 2 runs.  
Sort SraRunTable by BioSample ID and output in the format like: `BioSample_ID	GEO_Sample_ID	SRR,SRR`  
```
$ sort -k 1,1 SraRunTable.txt | awk -F "\t" 'FNR%2==0{printf $1 "\t" $10 "\t" $8 ","} FNR%2==1&&FNR!=1{print $8}' > sampleid_run_pairs.txt
```
Generate lots of yml files for each sample. There should be a better method.  
```
$ awk -F "\t" '{print "run_ids: [" $3 "]\ngene_tpm_output_filename: stringtie_gene_" $1 ".tsv\noutput_filename: stringtie_out_" $1 ".tsv" > $1 ".yml"}' sampleid_run_pairs.tsv
```

Calculate TPM values for each gene and output as stringtie_gene_SAMN*.tsv.
```
$ for f in SAMN*yml; do cat hisat2-stringtie_wf_se_common.yml $f > cat_$f; cwltool --singularity /path/to/hisat2-stringtie_wf_se.cwl cat_$f; rm $f cat_$f; done
```

hisat2-stringtie_wf_se.cwl might fail at the fastq-dump step, because of a network problem or sth.  
Ensure that all the expected files were successfully output before proceeding.

Extract TPM values from the stringtie outputs and output to a single table file.
```
$ awk -f merge_tpm.awk stringtie_gene_SAMN*.tsv > tpm.tsv
```

Group samples according to the sample annotation file and make tables.
```
$ awk -f create_sample_table.awk -v eachsample_table_file=droso2017_refextable_eachsample.tsv -v sample_table_file=droso2017_refextable_sample.tsv sampleid_run_pairs.txt GSE99574_All_samples_with_title.txt
```

Then output the turtle files.
```
$ cwltool --singularity rdfize_refex_entry_wf.cwl rdfize_refex_entry_wf.yml
$ cwltool --singularity rdfize_refex_sample_wf.cwl rdfize_refex_sample_wf.yml
```
