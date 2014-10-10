#!/bin/bash
# Download Script for ISI-MIP2.1 simulation results from DKRZ Server
# written by Matthias Büchner <buechner@pik-potsdam.de>
# This script can also be pulled from Github with
# git clone git@github.com:ISI-MIP/ISI-MIP2.1_Download.git
# Pull updates from github with
# git pull origin master

# Your DKRZ Account
VRE1_ACC=b324025

# Basic Variables
VRE1_BASE_PATH=/gpfs_750/projects/ISI_MIP/data/upload_area_ISI-MIP2.1
RSYNC_CMD="rsync -ucdlv --delete"

echo "### WELCOME TO THE DOWNLOADER FOR ISI-MIP2.1 RESULTS ###";echo
echo -n "get latest stats file..."
scp -q $VRE1_ACC@vre1.dkrz.de:$VRE1_BASE_PATH/_upload_stats/.last.uploadedFiles.list .LAST_UL_LIST && echo " done" || exit

echo -n "get latest list of uploaded files..."
LAST_LIST=$(cat .LAST_UL_LIST)
scp -q $VRE1_ACC@vre1.dkrz.de:$VRE1_BASE_PATH/_upload_stats/$LAST_LIST .LAST_LIST && echo " done" || exit

# select sector from list
SECTORS[1]="agriculture"
SECTORS[2]="agro-eco"
SECTORS[3]="biodiversity"
SECTORS[4]="biomes-forestry"
SECTORS[5]="cge"
SECTORS[6]="energy"
SECTORS[7]="health"
SECTORS[8]="infrastructure"
SECTORS[9]="marine-fishery"
SECTORS[10]="permafrost"
SECTORS[11]="water"

DEFAULT_SECTOR="11"
echo;echo "Select Sector:"
for SECTOR_ID in $(seq 1 ${#SECTORS[@]});do
    echo $SECTOR_ID")" ${SECTORS[$SECTOR_ID]}
done
SECTOR_ID=$((${#SECTORS[@]} + 1))
while [ $SECTOR_ID -le 0 -o $SECTOR_ID -gt ${#SECTORS[@]} ];do
    read -e -p "option $(echo [$DEFAULT_SECTOR)] : " SECTOR_ID
    [ -z $SECTOR_ID ] && SECTOR_ID=$DEFAULT_SECTOR
done
SECTOR=${SECTORS[$SECTOR_ID]}

#extract models for sector
MODELS=$(grep $SECTOR .LAST_LIST | cut -d" " -f3 | cut -d"/" -f2 | sort | uniq)
[[ $MODELS == "" ]] && echo "No Data available. exiting..." && exit
echo;echo "Select Model(s):"
MODEL_ARRAY=( $MODELS )
MODEL_LEN=$((${#MODEL_ARRAY[@]} - 1))
echo "0) ALL"
for MODEL_ID in $(seq 0 $MODEL_LEN);do
    echo $(($MODEL_ID + 1))")" ${MODEL_ARRAY[$MODEL_ID]}
done
MODEL_ID=-1
while [ $MODEL_ID -lt 0 -o $MODEL_ID -gt $(($MODEL_LEN + 1)) ];do
    read -e -p "option : " MODEL_ID
done
[ $MODEL_ID = 0 ] && MODEL="ALL" || MODEL=${MODEL_ARRAY[$(($MODEL_ID - 1))]}

#extract input type for sector and model combination
[ $MODEL_ID = 0 ] && GREP_VAL_MODEL="/" || GREP_VAL_MODEL=$MODEL
INPUT_TYPES=$(grep $SECTOR .LAST_LIST | grep $GREP_VAL_MODEL | cut -d" " -f3 | cut -d"/" -f3 | sort | uniq)
echo;echo "Select Input Data Type:"
INPUT_TYPE_ARRAY=( $INPUT_TYPES )
INPUT_TYPE_LEN=$((${#INPUT_TYPE_ARRAY[@]} - 1))
echo "0) ALL"
for INPUT_TYPE_ID in $(seq 0 $INPUT_TYPE_LEN);do
    echo $(($INPUT_TYPE_ID + 1))")" ${INPUT_TYPE_ARRAY[$INPUT_TYPE_ID]}
done
INPUT_TYPE_ID=-1
while [ $INPUT_TYPE_ID -lt 0 -o $INPUT_TYPE_ID -gt $(($INPUT_TYPE_LEN + 1)) ];do
    read -e -p "option : " INPUT_TYPE_ID
done
[ $INPUT_TYPE_ID = 0 ] && INPUT_TYPE="ALL" || INPUT_TYPE=${INPUT_TYPE_ARRAY[$(($INPUT_TYPE_ID - 1))]}

#extract input type for sector and model combination
[ $INPUT_TYPE_ID = 0 ] && GREP_VAL_INPUT_TYPE="/" || GREP_VAL_INPUT_TYPE=$INPUT_TYPE
INPUT_DSETS=$(grep $SECTOR .LAST_LIST | grep $GREP_VAL_MODEL | grep $GREP_VAL_INPUT_TYPE |cut -d" " -f3 | cut -d"/" -f4 | sort | uniq)
echo;echo "Select Input Data Type:"
INPUT_DSET_ARRAY=( $INPUT_DSETS )
INPUT_DSET_LEN=$((${#INPUT_DSET_ARRAY[@]} - 1))
echo "0) ALL"
for INPUT_DSET_ID in $(seq 0 $INPUT_DSET_LEN);do
    echo $(($INPUT_DSET_ID + 1))")" ${INPUT_DSET_ARRAY[$INPUT_DSET_ID]}
done
INPUT_DSET_ID=-1
while [ $INPUT_DSET_ID -lt 0 -o $INPUT_DSET_ID -gt $(($INPUT_DSET_LEN + 1)) ];do
    read -e -p "option : " INPUT_DSET_ID
done
[ $INPUT_DSET_ID = 0 ] && INPUT_DSET="ALL" || INPUT_DSET=${INPUT_DSET_ARRAY[$(($INPUT_DSET_ID - 1))]}
[ $INPUT_DSET_ID = 0 ] && GREP_VAL_INPUT_DSET="/" || GREP_VAL_INPUT_DSET=$INPUT_DSET

echo

#create list of directories to download files from
cut -d" " -f3 .LAST_LIST |grep $SECTOR | grep $GREP_VAL_MODEL | grep $GREP_VAL_INPUT_TYPE | grep $GREP_VAL_INPUT_DSET |cut -d "/" -f1-4 |sort |uniq > .DIR_LIST

#loop over directories to get list of available variables
rm -f .VAR_LIST
for DIR in $(cat .DIR_LIST|uniq);do
    for FILE in $(awk '{print $3}' .LAST_LIST|grep $DIR);do
        FILE=$(basename $FILE)
        VAR=$(echo $FILE |rev| cut -d"_" -f5|rev)
        case $VAR in
            whe|mai|soy|ric|sor|mil|rap|sug|sgb|bar|rye|oat|mgr|sun|cas|nut|pea|ben|cot)
                VAR=$(echo $FILE |rev| cut -d"_" -f6|rev)_$VAR;;
        esac
        echo $VAR >> .VAR_LIST_TEMP
    done
done
sort .VAR_LIST_TEMP |uniq > .VAR_LIST && rm .VAR_LIST_TEMP

# Select Variable
echo "Select Variable:"
VAR_ARRAY=( $(cat .VAR_LIST) )
VAR_LEN=$((${#VAR_ARRAY[@]} - 1))
echo "0) ALL"
for VAR_ID in $(seq 0 $VAR_LEN);do
    echo $(($VAR_ID + 1))")" ${VAR_ARRAY[$VAR_ID]}
done
VAR_ID=-1
while [ $VAR_ID -lt 0 -o $VAR_ID -gt $(($VAR_LEN + 1)) ];do
    read -e -p "option : " VAR_ID
done
[ $VAR_ID = 0 ] && VAR="ALL" || VAR=${VAR_ARRAY[$(($VAR_ID - 1))]}
[ $VAR_ID = 0 ] && GREP_VAL_VAR="/" || GREP_VAL_VAR=$VAR

# generate list of files to download

rm -f .FILE_LIST
for DIR in $(cat .DIR_LIST|uniq);do
    case $VAR in
        ALL)
            grep $DIR .LAST_LIST |cut -d" " -f3 >> .FILE_LIST_TEMP;;
        *)
            grep $DIR .LAST_LIST | grep $VAR |cut -d" " -f3 >> .FILE_LIST_TEMP;;
    esac
done
sort .FILE_LIST_TEMP |uniq > .FILE_LIST && rm .FILE_LIST_TEMP

# Watch list of files to download?
DEFAULT_WATCH__LIST="y";echo
while [[ "$WATCH__LIST" != "y" && "$WATCH__LIST" != "n" ]];do
    read -e -p "Watch list of files to download? [y/n] : "  -i "n" WATCH__LIST
done
[ $WATCH__LIST == "y" ] && less .FILE_LIST

# DOWNLOAD!
for DIR in $(cat .DIR_LIST);do
    echo;echo "Downloading from $DIR/ :"
    mkdir -p $DIR
    case $VAR in
        ALL)
            $RSYNC_CMD vre1.dkrz.de:$VRE1_BASE_PATH/$DIR/ $DIR |grep nc4;;
        *)
            $RSYNC_CMD --include=*_"$VAR"_* --exclude=* vre1.dkrz.de:$VRE1_BASE_PATH/$DIR/ $DIR |grep nc4;;
    esac
done

rm .*_LIST
echo ;echo " ...done"
