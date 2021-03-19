#!/bin/bash

# plast (https://plast.inria.fr/) wrapper
# Last modified: fre mar 19, 2021  06:14
# Sign: JN

echo "start"
if [[ "$1" == "" ]]
then
	echo "########################################"
	echo "arguments"
	echo "\$1 folder with fastas - query"
	echo "\$2 path to database or folder with dbs - target"
	echo "\$3 threshold evalue"
	echo "\$4 method: tplastx, tplastn, plastn"
	echo "\$5 cpu: 4"
	echo "\$6 cluster: y / n"
	echo "\$7 list (for multiple dbs)"
	echo "########################################"
else 
	if [[ "$6" == y ]]
	then
		echo "loading modules"
		module load ncbi-blast
        module load plast
	else
		echo "not loading modules"
	fi
    prog="$4"
	echo "erasing the content of the blast output file..."
	rm ./*.blast
	if [ -z "$7" ]
	then
	    echo "single db plast option selected"
	    echo "plasting queries:"
		declare -i CT2
		CT2=0
		declare -i TOTAL
		TOTAL=$(find "$1" -type f -name '*.fas' | wc -l)
        while IFS= read -r -d '' f
		do
			COUNT=0
			zo=$(( CT2*100 / TOTAL ))
			echo -ne "                                                    \r"
			echo -ne $zo"%    reading... \r"
			while read -r LINE
			do
				if [[ "$LINE" =~ ">" ]] && [[ "$COUNT" == 0 ]]
				then
					echo \>"$f" > fasextr.blast
					COUNT=1
					continue
				elif [[ "$COUNT" == 1 ]]
				then
					if [[ "$LINE" =~ ">" ]]
					then
						break
					else
						echo "$LINE" >> fasextr.blast
					fi
				fi
			done < "$f"
            name=$(basename "$f")
			CT2=$CT2+1
			echo -ne "                                                                          \r"
			echo -ne $zo"% blast $name against $2...\r"
			touch output.blast
			#"$prog" -d "$2" -i fasextr.blast -o output.blast -outfmt 1 -a "$5" -e "$3"
			plast -p "$prog" -d "$2" -i fasextr.blast -o output.blast -outfmt 1 -a "$5" -e "$3"
            blname=$(basename "$2")
			sort -k1,1 -k2,2 -k11,11g -k12,12nr output.blast >> "$blname".blast
        done < <(find "$1" -type f -name '*.fas' -print0)
	else
		echo "multiple db blast option selected, number of dbs: $(wc -l < "$7")"
		echo "plasting queries:"
		declare -i CT2
		CT2=0
		declare -i TOTAL
		TOTAL="$(find "$1" -type f -name '*.fas' | wc -l)*$(wc -l < "$7")"
		zo=$(( CT2*100 / TOTAL ))
        while IFS= read -r -d '' f
		do
			COUNT=0
			echo -ne "                                                    \r"
			echo -ne $zo"%    reading... \r"
			while IFS= read -r LINE
			do
				if [[ "$LINE" =~ ">" ]] && [[ "$COUNT" == 0 ]]
				then
					echo \>"$f" > fasextr.blast
					COUNT=1
					continue
				elif [[ "$COUNT" == 1 ]]
				then
					if [[ "$LINE" =~ ">" ]]
					then
						break
					else
						echo "$LINE" >> fasextr.blast
			 		fi
			 	fi
			done < "$f"
            name=$(basename "$f")
			while IFS= read -r fdb
			do
				CT2="$CT2"+1
				echo -ne "                                                                          \r"
				echo -ne $zo"% plast $name against $fdb...\r"
				zo=$(( CT2*100 / TOTAL ))
				touch output.blast
			    plast -p "$prog" -d "$2"/"$fdb" -i fasextr.blast -o output.blast -outfmt 1 -a "$5" -e "$3"
			    #"$prog" -d "$2"/"$fdb" -i fasextr.blast -o output.blast -outfmt 1 -a "$5" -e "$3"
				sort -k1,1 -k2,2 -k11,11g -k12,12nr output.blast >> "$fdb".blast
			done < "$7"
		done < <(find "$1" -type f -name '*.fas' -print0)
	fi
	echo ""
	rm output.blast fasextr.blast
fi
echo "done"
