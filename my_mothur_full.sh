#! /bin/bash
# 23/01/2018
# Mothur
echo "ARGS" 
echo "$@"
mothur="$HOME/data/tools/mothur_1.39.5/mothur"
cd $(dirname $0)
echo "path is" $(pwd)
# Step counter init
stepus=1
n_threadus=8

################################################################################
################################# Make groups ##################################
################################################################################
read_dir="../data/reads/"
prefixus="predires"
echo "STEP : $stepus"
if [ "$1" == 1 ]; then
	startus=$(date +%s)
	echo "Make the reads group file"
	$mothur "#make.file(
	            inputdir=${read_dir}, 
	            type=gz, 
		    	numcols = 2,
	            prefix=${prefixus})"
	# Adding the sample name as the first col in predires.files 
	# and changing - to _ in order to please the mothur gods
	sed -r -i 's:(^.*/(.*)_S.*_L0.*fastq.gz):\2 \1:g' \
	    "${read_dir}/predires.files"
	sed -i 's/-/_/' "${read_dir}/predires.files"
	endus=$(date +%s)
	elapsus=$((endus - startus))
	echo "Time elapsed in s"
	echo "$elapsus"
else
	echo "NO Make the reads group file"
fi
((stepus++))


################################################################################
################################ Make contigs ##################################
################################################################################
contigs_dir="../data/contigs"
echo "STEP : $stepus"
if [ "$1" == 1 ]; then
	startus=$(date +%s)
	echo "Make contigs"
	if [ ! -d $contigs_dir ]; then mkdir $contigs_dir ; fi
	# V4 region amplified (<300pb) so trimoverlap = T 
	$mothur "#set.dir(output=${contigs_dir});
	        make.contigs(
	            file=${read_dir}/${prefixus}.files,
	            trimoverlap=T,
	            processors=${n_threadus});
	        summary.seqs()"
	endus=$(date +%s)
	elapsus=$((endus - startus))
	echo "Time elapsed in s"
	echo "$elapsus"
else
	echo "NO Make contigs"
fi
((stepus++))

#		Start	End	NBases	Ambigs	Polymer	NumSeqs
#Minimum:	1	1	1	0	1	1
#2.5%-tile:	1	289	289	0	3	954373
#25%-tile:	1	292	292	0	4	9543729
#Median: 	1	292	292	0	4	19087458
#75%-tile:	1	292	292	0	5	28631187
#97.5%-tile:	1	292	292	10	6	37220543
#Maximum:	1	314	314	129	40	38174915
#Mean:	1	289.163	289.163	0.918779	4.36678
## of Seqs:	38174915

################################################################################
############################# Make first screen ################################
################################################################################
echo "STEP : $stepus"
if [ "$1" == 1 ]; then
	startus=$(date +%s)
	echo "Make screening for size and ambiguous positions"
	$mothur "#screen.seqs(
	            fasta=${contigs_dir}/${prefixus}.trim.contigs.fasta,
	            group=${contigs_dir}/${prefixus}.contigs.groups,
	            summary=${contigs_dir}/${prefixus}.trim.contigs.summary,
	            maxambig=0,
	            minlength=289,
	            maxlength=292,
		    	processors=${n_threadus});
	            summary.seqs()"
	endus=$(date +%s)
	elapsus=$((endus - startus))
	echo "Time elapsed in s"
	echo "$elapsus"
else
	echo "NO Make screening for size and ambiguous positions"
fi
((stepus++))

#		Start	End	NBases	Ambigs	Polymer	NumSeqs
#Minimum:	1	289	289	0	3	1
#2.5%-tile:	1	291	291	0	3	744818
#25%-tile:	1	292	292	0	4	7448177
#Median: 	1	292	292	0	4	14896353
#75%-tile:	1	292	292	0	5	22344529
#97.5%-tile:	1	292	292	0	6	29047888
#Maximum:	1	292	292	0	9	29792705
#Mean:	1	291.801	291.801	0	4.38294
## of Seqs:	29792705

################################################################################
############################## Make unique #####################################
################################################################################
	echo "STEP : $stepus"
if [ "$1" == 1 ]; then
	startus=$(date +%s)
	echo "Make the sequences unique and generate count file"
	$mothur "#unique.seqs(
	            fasta=${contigs_dir}/${prefixus}.trim.contigs.good.fasta);
	        count.seqs(
	            name=${contigs_dir}/${prefixus}.trim.contigs.good.names,
	            group=${contigs_dir}/${prefixus}.contigs.good.groups,
	            processors=${n_threadus});
	        summary.seqs(count=${contigs_dir}/${prefixus}.trim.contigs.good.count_table)"
	endus=$(date +%s)   
	elapsus=$((endus - startus))
	echo "Time elapsed in s"
	echo "$elapsus"
else	
	echo "NO Make the sequences unique and generate count file"
fi
((stepus++))

#                Start   End     NBases  Ambigs  Polymer NumSeqs
#Minimum:        1       289     289     0       3       1
#2.5%-tile:      1       291     291     0       3       744818
#25%-tile:       1       292     292     0       4       7448177
#Median:         1       292     292     0       4       14896353
#75%-tile:       1       292     292     0       5       22344529
#97.5%-tile:     1       292     292     0       6       29047888
#Maximum:        1       292     292     0       9       29792705
#Mean:   1       291.801 291.801 0       4.38294
## of unique seqs:       3152756
#total # of seqs:        29792705

################################################################################
######################### Make Silva customization #############################
################################################################################
silva_dir="../data/silva_db"
echo "STEP : $stepus"
if [ "$1" == 1 ]; then
	silva_db="silva.nr_v132.align"
	echo "Make the DB processing (virtual PCR or trim)"
	# Start and end can be determind by running the alignement first on the full db
	$mothur "#set.dir(output=${silva_dir});
		summary.seqs(fasta=${silva_dir}/${silva_db}, processors=${n_threadus});
	        pcr.seqs(
	            fasta=${silva_dir}/${silva_db}, 
	            start=11895,
	            end=25318,
	            keepdots=F, 
	            processors=${n_threadus});
	        summary.seqs(processors=${n_threadus})"
else
	echo "NO Make the DB processing (virtual PCR)"
fi
((stepus++))


#Start   End     NBases  Ambigs  Polymer NumSeqs
#Minimum:        1       9875    217     0       3       1
#2.5%-tile:      2       13423   290     0       4       5328
#25%-tile:       2       13423   291     0       4       53280
#Median:         2       13423   291     0       5       106560
#75%-tile:       2       13423   291     0       5       159840
#97.5%-tile:     2       13423   457     1       6       207792
#Maximum:        4224    13423   1519    5       16      213119
#Mean:   2.36589 13422.8 306.989 0.044379        4.75828
## of Seqs:      213119

######################### Make alignment to Silva ##############################
################################################################################
align_dir="../data/align"
echo "STEP : $stepus"
if [ "$1" == 1 ]; then
	startus=$(date +%s)
	silva_db="silva.nr_v132.pcr.align"
	echo "Making the alignments to the db"
	if [ ! -d $align_dir ]; then mkdir $contigs_dir ; fi
	$mothur "#set.dir(output=${align_dir});
	        align.seqs(
	            fasta=${contigs_dir}/${prefixus}.trim.contigs.good.unique.fasta,
	            reference=${silva_dir}/${silva_db},
	            processors=${n_threadus});
	        summary.seqs(count=${contigs_dir}/${prefixus}.trim.contigs.good.count_table, 
	        	processors = ${n_threadus})"
	endus=$(date +%s)
	elapsus=$((endus - startus))
	echo "Time elapsed in s"
	echo "$elapsus"
else
	echo "NO Making the alignments to the db"
fi
((stepus++))


#		Start   End     NBases  Ambigs  Polymer NumSeqs
#Minimum:        0       0       0       0       1       1
#2.5%-tile:      2       13423   290     0       3       744818
#25%-tile:       2       13423   291     0       4       7448177
#Median:         2       13423   291     0       4       14896353
#75%-tile:       2       13423   291     0       5       22344529
#97.5%-tile:     2       13423   291     0       6       29047888
#Maximum:        13423   13423   292     0       9       29792705
#Mean:   24.8875 13413.8 290.469 0       4.38045
## of unique seqs:       3152756
#total # of seqs:        29792705

################################################################################
########################## Make alignment clean ################################
################################################################################
if [ "$1" == 1 ]; then
	echo "STEP : $stepus"
	echo "Make the alignments clean"
	$mothur "#screen.seqs(
	            fasta=${align_dir}/${prefixus}.trim.contigs.good.unique.align,
	            count=${contigs_dir}/${prefixus}.trim.contigs.good.count_table,
	            summary=${align_dir}/${prefixus}.trim.contigs.good.unique.summary,
	            start=2,
	            end=13423,
	            maxambig=0,
	            maxhomop=5,
	            processors=${n_threadus});
	        filter.seqs(fasta=${align_dir}/${prefixus}.trim.contigs.good.unique.good.align,
	            vertical=T, 
	            trump=.,
	            processors = ${n_threadus});
	        summary.seqs(
	            fasta=${align_dir}/${prefixus}.trim.contigs.good.unique.good.filter.fasta,
	            count=${align_dir}/${prefixus}.trim.contigs.good.good.count_table,
	            processors = ${n_threadus}
	            )"
else
	echo "STEP : $stepus"
	echo "NO Make the alignments clean"
fi
((stepus++))


#                Start   End     NBases  Ambigs  Polymer NumSeqs
#Minimum:        1       607     287     0       3       1
#2.5%-tile:      1       607     290     0       3       702835
#25%-tile:       1       607     291     0       4       7028348
#Median:         1       607     291     0       4       14056696
#75%-tile:       1       607     291     0       5       21085044
#97.5%-tile:     1       607     291     0       5       27410557
#Maximum:        1       607     292     0       5       28113391
#Mean:   1       607     290.849 0       4.31708
## of unique seqs:       2863173
#total # of seqs:        28113391

################################################################################
#################### Make pre-cluster and chimera slaying ######################
################################################################################
pre_clust_dir="../data/pre_clust"
echo "STEP : $stepus"
if [ "$1" == 1 ]; then
	startus=$(date +%s)
	if [ ! -d $pre_clust_dir ]; then mkdir $pre_clust_dir ; fi
	echo "Making the pre-clustering and chimera slaying"
	# diffs=4 means 8 dist max within the pre-cluster meaning 8*100/291(align size)=2.75% diff within the pre-cluster 
	#this value is < to our 3% threshold for OTU clustering.
	$mothur "#set.dir(output=${pre_clust_dir});
	        pre.cluster(
	            fasta=${align_dir}/${prefixus}.trim.contigs.good.unique.good.filter.fasta,
	            count=${align_dir}/${prefixus}.trim.contigs.good.good.count_table,
	            diffs=4,
	            processors=${n_threadus});
	        summary.seqs(count=${pre_clust_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.count_table,
	        	processors=${n_threadus});
	        chimera.vsearch(
	            fasta=${pre_clust_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.fasta,
	            count=${pre_clust_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.count_table,
	            dereplicate=t,
	            processors=${n_threadus});
	        remove.seqs(
	            fasta=${pre_clust_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.fasta,
	            count=${pre_clust_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.denovo.vsearch.pick.count_table,
	            accnos=${pre_clust_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.denovo.vsearch.accnos);
	        summary.seqs(count=${pre_clust_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.denovo.vsearch.pick.pick.count_table,
	        	processors=${n_threadus})"
	endus=$(date +%s)   
	elapsus=$((endus - startus))
	echo "Time elapsed in s"
	echo "$elapsus"
else
	echo "NO Making the pre-clustering and chimera slaying"
fi
((stepus++))


#		Start	End	NBases	Ambigs	Polymer	NumSeqs
#Minimum:	1	607	287	0	3	1
#2.5%-tile:	1	607	290	0	3	682652
#25%-tile:	1	607	291	0	4	6826512
#Median: 	1	607	291	0	4	13653023
#75%-tile:	1	607	291	0	5	20479534
#97.5%-tile:	1	607	291	0	5	26623393
#Maximum:	1	607	292	0	5	27306044
#Mean:	1	607	290.883	0	4.36498
## of unique seqs:	208965
#total # of seqs:	27306044

################################################################################
########################### Make classification ################################
################################################################################
# Shall we also remove the non-bacterial lineage?
class_dir="../data/classification"
silva_fasta="../data/silva_db/silva.nr_v132.align"
silva_tax="../data/silva_db/silva.nr_v132.tax"
echo "STEP : $stepus"
if [ "$1" == 1 ]; then
	startus=$(date +%s)
	if [ ! -d $class_dir ]; then mkdir $class_dir ; fi
	echo "Make classification"
	$mothur "#set.dir(output=${class_dir});
			classify.seqs(
				fasta=${pre_clust_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.fasta,
				count=${pre_clust_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.denovo.vsearch.pick.count_table,
				reference=${silva_fasta},
				taxonomy=${silva_tax},
				cutoff=80,
				processors=${n_threadus})"
	endus=$(date +%s)   
	elapsus=$((endus - startus))
	echo "Time elapsed in s"
	echo "$elapsus"
else	
	echo "NO Make classification"
fi
((stepus++))


################################################################################
###################### Make Matrix OTU cluster and count #######################
################################################################################
echo "STEP : $stepus"
mat_otu_dir="../data/mat_cluster_otu"
if [ "$1" == 1 ]; then
    startus=$(date +%s)
	if [ ! -d $mat_otu_dir ]; then mkdir $mat_otu_dir ; fi
	echo "Make matrix OTU clustering and count"
	# cutoff for dist seq allows not to store too much info
	# the dist file can be big and has to fit in ram once per processor used... careful!
	$mothur "#set.dir(output=${mat_otu_dir});
	        dist.seqs(
	            fasta=${pre_clust_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.fasta,
	            cutoff=0.03,
	            processors=${n_threadus});        
	        cluster(
	            column=${mat_otu_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.dist,
	            count=${pre_clust_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.denovo.vsearch.pick.count_table,
	            cutoff=0.03);
	        make.shared(
	            list=.${mat_otu_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.opti_mcc.list,
	            count=${pre_clust_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.denovo.vsearch.pick.count_table,
	            label=0.03)"
    endus=$(date +%s)
    elapsus=$((endus - startus))
    echo "Time elapsed in s"
    echo "$elapsus"
else
	echo "NO Make matrix OTU clustering and count"	
fi
((stepus++))


################################################################################
###################### Make taxonomic OTU cluster and count ####################
################################################################################
tax_otu_dir="../data/tax_cluster_otu"
echo "STEP : $stepus"
if [ "$1" == 1 ]; then
	startus=$(date +%s)
	if [ ! -d $tax_otu_dir ]; then mkdir $tax_otu_dir ; fi
	echo "Make taxonomic OTU clustering and count"
	$mothur "#set.dir(output=${tax_otu_dir});
			cluster.split(
				fasta=${pre_clust_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.fasta,
				count=${pre_clust_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.denovo.vsearch.pick.count_table,
				splitmethod=classify,
				taxonomy=${class_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.nr_v132.wang.taxonomy,
				taxlevel=6,
				cutoff=0.03,
				processors=${n_threadus});
			make.shared(
		            list=.${tax_otu_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.opti_mcc.unique_list.list,
		            count=${pre_clust_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.denovo.vsearch.pick.count_table,
		            label=0.03)"
	endus=$(date +%s)
	elapsus=$((endus - startus))
	echo "Time elapsed in s"
	echo "$elapsus"
else	
	echo "NO Make taxonomic OTU clustering and count"
fi
((stepus++))



################################################################################
########################## Make shared file clean ##################################
################################################################################
# In this step, we are going to clean the shared file by removing some samples and some OTU
# using the filter.shared() and remove.groups() commands.
clean_dir="../data/clean_shared"
echo "STEP : $stepus"
if [ "$1" == 1 ]; then
    startus=$(date +%s)
    if [ ! -d $clean_dir ]; then mkdir $clean_dir ; fi
    echo "Make shared file clean"
    $mothur "#set.dir(output=${clean_dir});
            remove.groups(
            	shared=${tax_otu_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.opti_mcc.unique_list.shared,
            	count=${pre_clust_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.denovo.vsearch.pick.count_table,
            	column=${mat_otu_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.dist,
            	list=${mat_otu_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.opti_mcc.list,
            	accnos=${clean_dir}/bad_groups.accnosgroups);
            filter.shared(
            	shared=${clean_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.opti_mcc.unique_list.0.03.pick.shared,
            	mintotal=3)"
    endus=$(date +%s)
    elapsus=$((endus - startus))
    echo "Time elapsed in s"
    echo "$elapsus"
else    
    echo "NO Make shared file clean"
fi
((stepus++))

################################################################################
############################ Make alpha div ####################################
################################################################################
alpha_dir="../data/alpha"
echo "STEP : $stepus"
if [[ "$@" =~ "--alpha" ]]; then
    startus=$(date +%s)
    if [ ! -d $alpha_dir ]; then mkdir $alpha_dir ; fi
    echo "Make alpha diversity calculations"
    $mothur "#set.dir(output=${alpha_dir});
            rarefaction.single(
                shared=${clean_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.opti_mcc.unique_list.0.03.pick.0.03.filter.shared,
                calc=sobs-chao-ace-shannon-coverage-nseqs,
                iters=1000,
                freq=1000,
                processors=${n_threadus}
            )"
    endus=$(date +%s)
    elapsus=$((endus - startus))
    echo "Time elapsed in s"
    echo "$elapsus"
else    
    echo "NO Make alpha diversity calculations"
fi
((stepus++))



################################################################################
#########################     Make a tree     ##################################
################################################################################
# The command tree.shared() makes a tree of samples with distances being calculated by BC or TYC
# in our case we need a tree with OTUs as tips to feed to the Unifrac algorithm, we'll try the clearcut command.
# We'll start with get.oturep()
tree_dir="../data/tree"
echo "STEP : $stepus"
if [ "$1" == 1 ]; then
    startus=$(date +%s)
    if [ ! -d $clean_dir ]; then mkdir $clean_dir ; fi
    echo "Make a tree"
    $mothur "#set.dir(output=${tree_dir});
  			get.oturep(
				fasta=${pre_clust_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.fasta,
				column=${clean_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.pick.dist,
  				list=${clean_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.opti_mcc.0.03.pick.list,
  				count=${clean_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.denovo.vsearch.pick.pick.count_table);
			clearcut(
				fasta=${tree_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.opti_mcc.0.03.pick.0.03.rep.fasta,
				DNA=T,
				verbose=T)"
    endus=$(date +%s)
    elapsus=$((endus - startus))
    echo "Time elapsed in s"
    echo "$elapsus"
else    
    echo "NO Make a tree"
fi
((stepus++))

################################################################################
############################ Make beta div #####################################
################################################################################
echo $@
beta_dir="../data/beta_1000"
echo "STEP : $stepus"
if [[ "$@" =~ --beta ]]; then
    startus=$(date +%s)
    if [ ! -d $beta_dir ]; then mkdir $beta_dir ; fi
    echo "Make beta diversity calculations"
    $mothur "#set.dir(output=${beta_dir});
            unifrac.weighted(
		tree=${tree_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.opti_mcc.0.03.pick.0.03.rep.tre,
		count=${tree_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.opti_mcc.0.03.pick.0.03.rep.count_table,
		subsample=T,
		iters=1000,
		distance=square,
		processors=${n_threadus});
            unifrac.unweighted(
		tree=${tree_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.opti_mcc.0.03.pick.0.03.rep.tre,
		count=${tree_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.opti_mcc.0.03.pick.0.03.rep.count_table,
		subsample=T,
		iters=1000,
		distance=square,
		processors=${n_threadus});
	    dist.shared(
		shared=${clean_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.opti_mcc.unique_list.0.03.pick.0.03.filter.shared, 
		calc=thetayc-braycurtis,
		output=square,
		subsample=T,
		iters=1000,
		processors=${n_threadus})"
    endus=$(date +%s)
    elapsus=$((endus - startus))
    echo "Time elapsed in s"
    echo "$elapsus"
else    
    echo "NO Make beta diversity calculations"
fi
((stepus++))

################################################################################
###################     Make Taxonimic Assignation    ##########################
################################################################################
assign_dir="../data/assign"
echo "STEP : $stepus"
if [[ "$@" =~ "--assign" ]]; then
    startus=$(date +%s)
    if [ ! -d $assign_dir ]; then mkdir $assign_dir ; fi
    echo "Make Taxonomic Assignation"
    $mothur "#set.dir(output=${assign_dir});
	classify.otu(
	taxonomy=${class_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.nr_v132.wang.taxonomy,
 	list=${clean_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.pick.opti_mcc.0.03.pick.list,
  	count=${clean_dir}/${prefixus}.trim.contigs.good.unique.good.filter.precluster.denovo.vsearch.pick.pick.count_table);
	cutoff=51)"
    endus=$(date +%s)
    elapsus=$((endus - startus))
    echo "Time elapsed in s"
    echo "$elapsus"
else    
    echo "NO Make Taxonomic Assignation"
fi
((stepus++))














