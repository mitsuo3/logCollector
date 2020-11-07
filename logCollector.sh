#/bin/bash

while read line
do  
    export IP_ADDRESS=$line
    export HEADER=${IP_ADDRESS:0:1}
    
    if [ $HEADER = "#" ]; then
        echo "# Skipped"
    else
        echo $HEADER
    fi 
done < /etc/hosts



# find /var/log -type f -mtime -1 | xargs -I {} cp -p {} /tmp/20201107_log_manager/
# tar cvfz /tmp/20201107_log_manager.tar.gz /tmp/20201107_log_manager

