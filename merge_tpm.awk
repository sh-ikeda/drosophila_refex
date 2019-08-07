#! /usr/bin/awk -f
### usage: merge_tpm -v prefix=PREFIX file1 file2 ...

BEGIN {
    FS = "\t"
    OFS = "\t"
    n = 1
    if(!prefix) {
        print "WARNING: Prefix of the target files should be specified by '-v prefix=PREFIX'." > "/dev/stderr"
    }
}

FNR==1 {
    fn[n] = FILENAME
    n++
}

FNR>=2 {
    # $1 is a gene ID
    tpm[$1, FILENAME] = $9
    if(!id[$1]) {
        id[$1] = 1
    }
}

END {
    for(i=1; i<n; i++) {
        sample_name = gensub(/.*\//, "", "g", fn[i])
        sample_name = gensub(prefix, "", "g", sample_name)
        sample_name = gensub(/\..*/, "", "g", sample_name)
        printf "\t" sample_name
    }
    printf "\n"
    for(j in id) {
        printf j
        for(i=1; i<n; i++)
            printf "\t" tpm[j, fn[i]]
        printf "\n"
    }
}
