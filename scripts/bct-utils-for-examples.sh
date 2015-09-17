#!/bin/sh

trap ctrl_c INT

computeAndServeExample() {

   INSTANCE_NAME=$1
   DATA_FILE=$2

   rm -rf "instances/$INSTANCE_NAME"
   mkdir -p "instances/$INSTANCE_NAME/00000/inbound"
   cp $DATA_FILE "instances/$INSTANCE_NAME/00000/inbound/"

   #Start computation layer
   kill_proc_by_tcpport 8091
   java -Dconfig.file=$INSTANCE_NAME.conf -jar computation/target/oryx-computation-1.0.2-SNAPSHOT.jar &

   while [ ! -f "instances/$INSTANCE_NAME/00000/computation.conf" ];
   do
     sleep 1
   done

   firefox http://localhost:8091 2> /dev/null &

   #Wait while computation ends
   while [ ! -f "instances/$INSTANCE_NAME/00000/_SUCCESS" ];
   do
     sleep 1
   done

   #Start serving layer
   kill_proc_by_tcpport 8092
   java -Dconfig.file=$INSTANCE_NAME.conf -jar serving/target/oryx-serving-1.0.2-SNAPSHOT.jar &
   sleep 2
   firefox http://localhost:8092 2> /dev/null &
}

ctrl_c() {
   kill_proc_by_tcpport 8091
   kill_proc_by_tcpport 8092
   exit
}

kill_proc_by_tcpport() {
   tcpPort=$1
   pid=$(netstat -natlp 2> /dev/null | grep $tcpPort | grep LISTEN | sed 's/.*LISTEN.* \([0-9]\+\)\/java/\1/')
   if [ $pid ] ; then
      echo "The process \"$pid\" listen on $tcpPort TCP port. It will be killed."
      kill -9 $pid
   fi
}
