find . -name U*.fastq.gz | sed -e 'p;s/.gz/.gz.undetermined/' | xargs -n2 mv
