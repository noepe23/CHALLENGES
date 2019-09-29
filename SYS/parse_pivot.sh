#!/bin/sh

OUTFILE="out.dat"
> $OUTFILE

PREVIOUS_NODE=""
CHILD=""

FIRST_LINE=$(head -1 $1)
PARENT_LEVEL=$(echo $FIRST_LINE | grep -o ' ' | wc -l )
FIRST_NODE=$(echo $FIRST_LINE | rev | cut -d" " -f2 | rev)
CURRENT_LEVEL=0
PREVIOUS_LEVEL=$PARENT_LEVEL
PREVIOUS_LEVEL_DATA=""
LEVEL_DATA=""

while IFS="\n" read line
do
	#Get current line
	NODE_VALUE=$(echo $line | rev | cut -d" " -f1,2 | rev)
	CURRENT_NODE=$(echo $NODE_VALUE | cut -d" " -f1)
	CURRENT_LEVEL=$(echo $line | grep -o ' ' | wc -l)
	
	if [ $CURRENT_LEVEL -gt $PREVIOUS_LEVEL ]
	then
		#When increase level, there is a new first node (possible repeated); store the previous level data to repeat with this new level records
		FIRST_NODE=$(echo $NODE_VALUE | cut -d" " -f1)
		PREVIOUS_LEVEL_DATA=$LEVEL_DATA
		LEVEL_DATA=$PREVIOUS_LEVEL_DATA$NODE_VALUE"\n"
		PREVIOUS_LEVEL=$CURRENT_LEVEL
	elif [ $CURRENT_LEVEL -lt $PREVIOUS_LEVEL ]
	then
		#if the level decreases, its starting a new data block. FLush the prevous block and restart vars
		FIRST_NODE=$(echo $NODE_VALUE | cut -d" " -f1)
		echo -n $LEVEL_DATA >> $OUTFILE
		PREVIOUS_LEVEL_DATA=""
		LEVEL_DATA=$NODE_VALUE"\n"
		PREVIOUS_LEVEL=$CURRENT_LEVEL
	else
		#On same data level, just write; if a first (repeatable) node, write the previous level data
		
		if [ $CURRENT_NODE = $FIRST_NODE ]
		then 
			LEVEL_DATA=$LEVEL_DATA$PREVIOUS_LEVEL_DATA
		fi
		LEVEL_DATA=$LEVEL_DATA$NODE_VALUE"\n"
	fi
		

done < "$1"

echo -n $LEVEL_DATA >> $OUTFILE


##PIVOT result
PIVOTFILE="pivot.dat"
echo "" > $PIVOTFILE

FIRST_COL=""
COL=""
PREV_COL=""
HEADER=0

FIRST_COL=$(head -1 $OUTFILE | cut -d" " -f1)

PREV_VAL=""
while IFS="\n" read line
do
	COL=$(echo $line | cut -d" " -f1)
	VAL=$(echo $line | cut -d" " -f2)
	
	if [ "$COL" = "$FIRST_COL" ]
	then
		HEADER=$(expr $HEADER + 1)			
		echo $PREV_VAL >> $PIVOTFILE
	else		
		echo -n $PREV_VAL" " >> $PIVOTFILE	
	fi
	
	if [ $HEADER -eq 1 ]
	then
		sed -i '1 s_$_'"$COL"' _' $PIVOTFILE
	fi
	
	PREV_COL=$COL
	PREV_VAL=$VAL

done < "$OUTFILE"
sed -i '2d' $PIVOTFILE
sed -i '1 s/ $//' $PIVOTFILE

echo $PREV_VAL >> $PIVOTFILE

