echo "# Comment `date +%Y%m%d_%H%M%S` // logCollector copy Start"
./logCollector.sh copy 2>> copy.log 1>> copy.log
echo "# Comment `date +%Y%m%d_%H%M%S` // logCollector copy End"

echo "# Comment `date +%Y%m%d_%H%M%S` // logCollector archive Start"
./logCollector.sh archive 2>> archive.log 1>> archive.log
echo "# Comment `date +%Y%m%d_%H%M%S` // logCollector archive End"

echo "# Comment `date +%Y%m%d_%H%M%S` // logCollector transfer Start"
./logCollector.sh transfer 2>> transfer.log 1>> transfer.log
echo "# Comment `date +%Y%m%d_%H%M%S` // logCollector transfer End"

