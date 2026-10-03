
IP=192.168.1.38
USER=admin66
USER=root

ssh-keygen -R $IP

BEFORE=$SECONDS

CMD="ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=accept-new ${USER}@$IP uptime"
echo "-- $CMD"
while true; do
    let TOOK=SECONDS-BEFORE
    echo -n "[ $TOOK secs ] ... "
    $CMD && break
    #ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=accept-new ${USER}@$IP uptime && break;
sleep 2; done

AFTER=$SECONDS
let TOOK=AFTER-BEFORE
echo "Took $TOOK seconds"
set -x
ssh ${USER}@$IP

