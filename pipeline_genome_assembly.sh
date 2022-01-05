#!/bin/bash

ls *.fastq -1 > sample
sed -i 's/.fastq//g' sample

############################################## genome analysis ##########################################################
### check statistic and plot for QC of raw reads
echo #####################################
echo ########## Quality control ##########
echo #####################################
for i in $(cat sample); do mkdir QC; done
for i in $(cat sample); do NanoStat --outdir QC --name "$i".raw.stat  --fastq "$i".fastq; done
for i in $(cat sample); do NanoPlot -t 8 -o QC -p "$i".raw.plot --readtype 1D -f png --N50 --dpi 300 --fastq "$i".fastq; done

# filter loq quality and short reads
#for i in $(cat sample); do NanoFilt -l 500 -q 7 --headcrop 10 --tailcrop 10 --readtype 1D "$i"/"$i".fastq > "$i"/"$i".filtered.fastq; done
#for i in $(cat sample); do NanoStat --outdir "$i"/QC --name "$i".filtered.stat  --fastq "$i"/"$i".filtered.fastq; done

##### Assembly
echo ##############################
echo ########## Assembly ##########
echo ##############################
### Asssssembly with flye
mkdir assembly_flye
for i in $(cat sample); do flye --nano-raw "$i".fastq --threads 8 --iterations 4 -o assembly_flye --scaffold; done


echo ###############################
echo ########## Polishing ##########
echo ###############################
### Polishing draft assembly with medaka consensus
# create working directory
mkdir medaka_consensus

# run medaka_consensus for flye draft assembly
for i in $(cat sample); do medaka_consensus -i "$i".fastq -d assembly_flye/assembly.fasta -o medaka_consensus/ -t 8 -f -m r941_min_high_g360; done


## copy all consensus to consensus parent folder, add prefix to existing fasta header, combine to gyrinops fasta
# raven polished assembly
for i in $(cat sample); do mv medaka_consensus/consensus.fasta medaka_consensus/"$i".flye.consensus.fasta; done 
for i in $(cat sample); do rename.sh in=medaka_consensus/consensus.fasta out=medaka_consensus/flye.medaka.fasta prefix=flye addprefix=t fastawrap; done


echo ########################################
echo ########## Assembly statistic ##########
echo ########################################
### compute polished draft assembly statistic with QUAST
mkdir quast_stat
mkdir quast_stat/medaka

# run quast 
quast.py -t 8 -o quast_stat/medaka/  -e -f medaka_consensus/consensus.fasta  



