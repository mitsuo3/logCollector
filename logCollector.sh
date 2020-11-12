#!/bin/bash

function usage() {
cat <<_EOT_
Usage:
  $0 [-a] [-b] [-f filename] arg1 ...

Description:
  Log Collect to Hadoop ALL Server 

Options:
  $1    [copy] or [archive] or [transfer]
  $2    collect target [YYYYMMDD] or [null] (null : today)
  -f    ffffffffff

_EOT_
exit 1
}

function create_directory () {
    ssh -n ${IP_ADDRESS} mkdir /tmp/${GET_DATE}_log_${HOST_NAME}
}

function find_and_copy_log () {
    ssh -n ${IP_ADDRESS} "find /var/log -type f -mtime -1 | xargs -I {} cp -p {} /tmp/${GET_DATE}_log_${HOST_NAME} && sleep 10" &
    return $!
}

function archive_log () {
    ssh -n ${IP_ADDRESS} "tar cvfz /tmp/${GET_DATE}_log_${HOST_NAME}.tar.gz /tmp/${GET_DATE}_log_${HOST_NAME}/* && sleep 10" &
    return $!
}

function transfer_log () {

    scp ${IP_ADDRESS}:/tmp/${GET_DATE}_log_${HOST_NAME}.tar.gz /tmp/logCollect_${GET_DATE}   
    
    ### これはやらない方が良いかもしれない
    ssh -n ${IP_ADDRESS} rm -rf /tmp/${GET_DATE}_log_${HOST_NAME}
    ssh -n ${IP_ADDRESS} rm -f /tmp/${GET_DATE}_log_${HOST_NAME}.tar.gz
}



# GET COLLECT DATE
if [ -z "$1" ]; then 
    usage
fi
export COUNT=0
export i=0
export JOB_KIND=$1
if [ -z "$2" ]; then 
    export GET_DATE=`date +%Y%m%d`
else
    export GET_DATE=$2
fi



echo "# Comment `date +%Y%m%d_%H%M%S` // SHELL START"
echo "# Comment `date +%Y%m%d_%H%M%S` // JOB KIND = " ${JOB_KIND}
# CREATE WORK DIRECTORY 
mkdir /tmp/logCollect_${GET_DATE}

# READ TARGET SERVER FILE
while read line
do  
    export COUNT=${COUNT}+1
    export IP_ADDRESS=$line
    export HEADER=${IP_ADDRESS:0:1}
    echo "###########################################"
    echo "# Comment `date +%Y%m%d_%H%M%S`// READ LINE = " $IP_ADDRESS
    echo "###########################################"
    # if [ $HEADER = "#" ]; then
    if [ -z "$HEADER" ]; then
        echo "# Skipped becouse Null Line"
    elif [ "$HEADER" = "#" ]; then
        echo "# Skipped becouse Comment Out"
    else
        echo "# Comment `date +%Y%m%d_%H%M%S` // TARGET IP = " $IP_ADDRESS
        export HOST_NAME=`cat /repository/git/logCollector/hosts | grep ${IP_ADDRESS} | awk -F ' ' '{print $2}'`
            
        case ${JOB_KIND} in
        "copy" )
            echo "# Comment `date +%Y%m%d_%H%M%S` // CREATE DIRECTORY START"
            create_directory ${IP_ADDRESS} ${GET_DATE} ${HOST_NAME}

            echo "# Comment `date +%Y%m%d_%H%M%S` // FIND & COPY START"
            find_and_copy_log ${IP_ADDRESS} ${GET_DATE} ${HOST_NAME}
            wait_pid[${COUNT}]=$?
            ;;
        
        "archive" )
            echo "# Comment `date +%Y%m%d_%H%M%S` // TAR START"
            archive_log ${IP_ADDRESS} ${GET_DATE} ${HOST_NAME} ${COUNT}
            wait_pid[${COUNT}]=$?
            ;;

        "transfer" )
            echo "# Comment `date +%Y%m%d_%H%M%S` // SCP START"
            transfer_log ${IP_ADDRESS} ${GET_DATE} ${HOST_NAME}
            ;;
        
        * )
            usage
        esac
    fi 

    echo .
done < host_list

for ((i=1; i<${#wait_pid[@]}; i++)); 
do  
    wait ${wait_pid[${i}]} 1> /dev/null 2> /dev/null
done

# wait ${wait_pid[${i}]} 1> /dev/null 2> /dev/null


echo "# Comment `date +%Y%m%d_%H%M%S` // SHELL END"


