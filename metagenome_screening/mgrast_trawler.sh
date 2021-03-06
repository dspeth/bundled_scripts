#! /bin/bash

#### mgrast_screen ####
#
# A script to systematically download a predefined set of metagenomes and search them for the presence of a marker gene of interest.
# A list of metagenomes from MG-RAST can be downloaded from metagenomics.anl.gov 
# go to 'browse metagenomes' and click 'export table data' at the bottom of the page
# add ID's to the table before downloading, and make a list of IDs using e.g. awk
#
# uses wget, DIAMOND and a custom perl script (www.github.com/dspeth)
# requires making a DIAMOND database prior to running script
# 
# output for each dataset searched: diamond files (.daa & tab delim) and a read fasta file containing the reads of interest
#
# Daan Speth, 2016
#
####################

#### parameter check
if [ $# -lt 3 ]
then
echo "Usage: $0 MG-RAST_accession-list DIAMOND-db processed-accession-list"
exit 1
fi

MG_RAST="$1"
DMND_DB="$2"
PROCESSED="$3"

# make directories for output
mkdir dmnd_out fasta_files

# read through file with MG-RAST accessions and download/process each file in succession 
while read ACCESSION 
do 
	echo "processing $ACCESSION" >> log.txt
	
	# Check if Accession number has already been processes
	if grep -Fxq $ACCESSION $PROCESSED
	then
		echo "$ACCESSION already processed - Skipping" >> log.txt
		continue	
	fi

	# download dataset
	wget http://api.metagenomics.anl.gov/1/download/"$ACCESSION"\?file\=050.1 
	
	# convert the odd filename
	mv "$ACCESSION"\?file\=050.1 "$ACCESSION" 

	# MGRAST is a mixed bag of fastq, fasta, assembled contigs etc
	# diamond should be able to churn through all except really long assembled contigs...
	diamond blastx -q "$ACCESSION" -d $DMND_DB -k 1 -a hits_"$ACCESSION" --seg no -t /export/data1/tmp/

        # convert DIAMOND outfile to tab delimited format
        diamond view -a hits_"$ACCESSION" -o tab_"$ACCESSION"

	# retrieve matching reads
	blast_based_read_lookup.pl tab_"$ACCESSION" "$ACCESSION" seqs_"$ACCESSION".fasta	
	rm "$ACCESSION"

	#
        echo "$ACCESSION" >> $PROCESSED

        mv hits_"$ACCESSION".daa tab_"$ACCESSION" dmnd_out/
        mv seqs_"$ACCESSION".fasta fasta_files/

done < $MG_RAST
