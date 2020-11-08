#!/bin/bash

function usage() {
cat <<_EOT_
Usage:
  $0 [-a] [-b] [-f filename] arg1 ...

Description:
  Log Collect to Hadoop ALL Server 

Options:
  $1    [copy] or [transfer]
  $2    collect target [YYYYMMDD] or [null] (null : today)
  -f    ffffffffff

_EOT_
exit 1
}

function create_directory () {
    local ip=$1
    local date=$2
    local host=$3
    ssh -n ${ip} mkdir /tmp/${date}_log_${host}
}

function find_and_copy_log () {
    local ip=$1
    local date=$2
    local host=$3
    # echo nohup ssh -n ${ip} 'find /var/log -type f -mtime -1 | xargs -I {} cp -p {} /tmp/${date}_log_${host}' && sleep 30 && ssh -n ${ip} touch /tmp/${date}_log_${host}/copy_complete 
    echo 'ssh -n ${ip} find /var/log -type f -mtime -1 | xargs -I {} cp -p {} /tmp/${date}_log_${host} '
    ssh -n ${ip} find /var/log -type f -mtime -1 | xargs -I {} cp -p {} /tmp/${date}_log_${host} 
    # && sleep 30 && ssh -n ${ip} touch /tmp/${date}_log_${host}/copy_complete &
    # sleep 30
    # ssh -n ${ip} touch /tmp/${date}_log_${host}/copy_complete
}

function archive_log () {
    local ip=$1
    local date=$2
    local host=$3
    ssh -n ${ip} tar cvfz /tmp/${date}_log_${host}.tar.gz /tmp/${date}_log_${host}
}

function transfer_log () {
    local ip=$1
    local date=$2
    local host=$3

    scp ${ip}:/tmp/${date}_log_${host}.tar.gz /tmp/logCollect_${date}   
    
    ### これはやらない方が良いかもしれない
    ssh -n ${ip} rm -rf /tmp/${date}_log_${host}
    ssh -n ${ip} rm -f /tmp/${date}_log_${host}.tar.gz
}



# GET COLLECT DATE

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
    export IP_ADDRESS=$line
    export HEADER=${IP_ADDRESS:0:1}
    echo "# Comment `date +%Y%m%d_%H%M%S`// READ LINE = " $IP_ADDRESS
    if [ $HEADER = "#" ]; then
        echo "# Skipped becouse Comment Out"
    else
        echo "# Comment `date +%Y%m%d_%H%M%S` // TARGET IP = " $IP_ADDRESS
        export HOST_NAME=`cat /repository/git/logCollector/hosts | grep ${IP_ADDRESS} | awk -F ' ' '{print $2}'`
            
        case ${JOB_KIND} in
        "copy" )
            echo "# Comment `date +%Y%m%d_%H%M%S` // CREATE DIRECTORY START"
            # ssh -n $IP_ADDRESS mkdir /tmp/${GET_DATE}_log_${HOST_NAME}
            create_directory ${IP_ADDRESS} ${GET_DATE} ${HOST_NAME}

            echo "# Comment `date +%Y%m%d_%H%M%S` // FIND & COPY START"
            # ssh -n $IP_ADDRESS find /var/log -type f -mtime -1 | xargs -I {} cp -p {} /tmp/${GET_DATE}_log_${HOST_NAME}
            find_and_copy_log ${IP_ADDRESS} ${GET_DATE} ${HOST_NAME}
            
            ;;
        
        "archive" )
            echo "# Comment `date +%Y%m%d_%H%M%S` // TAR START"
            # ssh -n $IP_ADDRESS tar cvfz /tmp/${GET_DATE}_log_${HOST_NAME}.tar.gz /tmp/${GET_DATE}_log_${HOST_NAME}
            archive_log ${IP_ADDRESS} ${GET_DATE} ${HOST_NAME}

            ;;

        "transfer" )
            echo "# Comment `date +%Y%m%d_%H%M%S` // SCP START"
            # scp $IP_ADDRESS:/tmp/${GET_DATE}_log_${HOST_NAME}.tar.gz /tmp/logCollect_${GET_DATE}   
            transfer_log ${IP_ADDRESS} ${GET_DATE} ${HOST_NAME}

            ;;
        
        * )
            usage
        esac
    fi 
done < host_list

echo "# Comment `date +%Y%m%d_%H%M%S` // SHELL END"


