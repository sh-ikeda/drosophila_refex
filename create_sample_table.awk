### 

BEGIN {
    OFS = "\t"
    FS = "\t"
    if(!sample_table_file)
        sample_table_file = "droso2017_refextable_sample.tsv"
    if(!eachsample_table_file)
        eachsample_table_file = "droso2017_refextable_eachsample.tsv"

    if(!sample_id_num)
        sample_id_num = 1
    if(!sample_id_prefix)
        sample_id_prefix = "RES"

    print "RefEx_Sample_ID", "Description", "Category" > sample_table_file
    print "RefEx_Sample_ID", "BioSample_ID", "Project_Sample_ID" > eachsample_table_file
    category = "tissues"
}

FNR==NR {
    bs_id[$2] = $1
    next
}

$4=="Drosophila melanogaster" {
    sample_name = gensub("_r[0-9]$", "","g", $2)
    if(!sample_id[sample_name]) {
        sample_id[sample_name] = sprintf("%s%08d", sample_id_prefix, sample_id_num)
        sample_id_num++
        strain = gensub("_.*", "", "g", $2)
        tissue = $3
        if(gensub(".*_", "", "g", sample_name)=="f")
            sex = "female"
        else
            sex = "male"
        desc = strain ", " tissue ", " sex
        print sample_id[sample_name], desc, category > sample_table_file
    }
    project_id = $1
    print sample_id[sample_name], bs_id[$1], project_id > eachsample_table_file
}
