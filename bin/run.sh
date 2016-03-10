es_url=`services/elasticsearch.sh $1 &`
PID1=$!

wait $PID1
echo PID1 has ended.
echo $es_url
wait
echo All background processes have exited.
