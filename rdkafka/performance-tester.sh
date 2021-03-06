#!/bin/bash

FROM=${FROM:-"end"}
TOPIC=${TOPIC:-"test"}
GROUP=${GROUP:="rdkafkatestconsumer"}
BROKER=${BROKER:-""}
SASL_USER=${SASL_USER:-""}
SASL_PASS=${SASL_PASS:-""}
MECHANISM=${MECHANISM:-""}
PARTITION=${PARTITION:-"0"}
SECURITY_PROTOCOL=${SECURITY_PROTOCOL:=""}
MESSAGE_COUNT=${MESSAGE_COUNT:=""}
MESSAGE_SIZE=${MESSAGE_SIZE:=""}
MESSAGE_RATE=${MESSAGE_RATE:=$MESSAGE_COUNT}
CONSUMER_WAIT=${CONSUMER_WAIT:="60"}

_terminate() {
    echo "=========================="
    echo "Finishing performance test"
    echo "=========================="
    # TODO: Consumer may not finish consuming (meet message count number), killing after period for now
    echo "Waiting for consumer to finish consuming"
    sleep ${CONSUMER_WAIT}
    kill -TERM $CONSUMER_PID
    wait $CONSUMER_PID
    echo "Consumer Output:"
    cat consumer_output.log
	exit 0
}

trap _terminate 0

# Start up a consumer so that rdkafka_performance can measure latency as well 
rdkafka_performance -C \
    -l \
    -t $TOPIC \
    -p $PARTITION \
    -b $BROKER \
    -o $FROM \
    -c $MESSAGE_COUNT \
    -X "group.id=$GROUP" \
    -X "sasl.mechanisms=$MECHANISM" \
    -X "security.protocol=$SECURITY_PROTOCOL" \
    -X "sasl.username=$SASL_USER" \
    -X "sasl.password=$SASL_PASS" \
    -X "socket.timeout.ms=30000" \
    -X "socket.keepalive.enable=true" \
    -X "log.connection.close=false" \
    -X "reconnect.backoff.jitter.ms=10000" \
    &> consumer_output.log &

CONSUMER_PID=$!

# Start performance client with specified settings
# "receive.message.max.bytes=200000000"
rdkafka_performance -P \
    -t $TOPIC \
    -c $MESSAGE_COUNT \
    -s $MESSAGE_SIZE \
    -l \
    -o $FROM \
    -r $MESSAGE_RATE \
    -b $BROKER \
    -X "group.id=$GROUP" \
    -X "sasl.mechanisms=$MECHANISM" \
    -X "security.protocol=$SECURITY_PROTOCOL" \
    -X "sasl.username=$SASL_USER" \
    -X "sasl.password=$SASL_PASS" \
    -X "socket.timeout.ms=30000" \
    -X "socket.keepalive.enable=true" \
    -X "log.connection.close=false" \
    -X "reconnect.backoff.jitter.ms=10000"

