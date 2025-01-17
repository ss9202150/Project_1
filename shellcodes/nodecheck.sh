#!/bin/bash

#自動檢查叢集服務運作狀態

# Copyright (c) IIIedu BDSE.
# BDSE12 Project <contactus@iii.org.tw>
# 指導老師：楊禎文老師


B='\033[1;34m'
G='\033[0;32m'
N='\033[0m'
R='\033[0;31m'
echo -e "${B}Checking the environment...${N}"
hadoop_home="/usr/local/hadoop/etc/hadoop/"
awk2='awk NR=="2"'
grep1='grep -A 1'
cut1="cut -d "." -f1"
cat ${hadoop_home}core-site.xml &>/dev/null
[[ "$?" == "1" ]] && echo -e "${R}Can't find out core-site.xml,make sure your hadoop path: "${hadoop_home}" " \
&& echo -e "Terminate program...!${N}" && exit 1
haCheck=$(cat ${hadoop_home}core-site.xml  | ${grep1} "fs.defaultFS" | ${awk2}| grep 'cluster' )
[[ -n ${haCheck} ]] && echo -e "${B}Your cluster : HA cluster${N}" || echo "${B}Your cluster : Normal cluster${N}"
if [[ -n ${haCheck} ]]

	then
		#HA叢集
		#自動檢查檢查XML各服務主機
			nna="dfs.namenode.rpc-address.nncluster.nn"
			rma="yarn.resourcemanager.hostname.rm"
			hadoop=$(cat ${hadoop_home}hdfs-site.xml | ${grep1} "${nna}1" | ${awk2} )
			nn1=$(echo ${hadoop#*value>} | ${cut1} )
			hadoop=$(cat ${hadoop_home}hdfs-site.xml | ${grep1} "${nna}2" | ${awk2} )
			nn2=$(echo ${hadoop#*value>} | ${cut1} )
			hadoop=$(cat ${hadoop_home}yarn-site.xml | ${grep1} "${rma}1" | ${awk2} )
			rm1=$(echo ${hadoop#*value>} | ${cut1} )	
			hadoop=$(cat ${hadoop_home}yarn-site.xml | ${grep1} "${rma}2" | ${awk2} )
			rm2=$(echo ${hadoop#*value>} | ${cut1} )
			hadoop=$(cat ${hadoop_home}mapred-site.xml | ${grep1} "mapreduce.jobhistory.address" | ${awk2} )
			jhs=$(echo ${hadoop#*value>} | ${cut1} )
			hadoop=$(cat ${hadoop_home}yarn-site.xml | ${grep1} "yarn.resourcemanager.zk-address" | ${awk2} )
			zk1=$(echo ${hadoop#*value>} | ${cut1} )
			zk2=$(echo ${hadoop#*value>} | cut -d "," -f2 | ${cut1} )
			zk3=$(echo ${hadoop#*value>} | cut -d "," -f3 | ${cut1} )
			hadoop=$(cat ${hadoop_home}hdfs-site.xml | ${grep1} "dfs.namenode.shared.edits.dir" | ${awk2} )
			jn1=$(echo ${hadoop#*://} | ${cut1} )
			jn2=$(echo ${hadoop#*://} | cut -d ";" -f2 | ${cut1} )
			jn3=$(echo ${hadoop#*://} | cut -d ";" -f3 | ${cut1} )
		#check NameNode 1,2
			n=1
			for nn in ${nn1} ${nn2}			
			do
				ssh ${nn} jps &> /tmp/out
				cat /tmp/out | grep 'NameNode' &>/dev/null
				[[ "$?" == "0" ]] && echo -e "${G}NameNode nn${n} started${N}"   \
				|| echo -e "${R}NameNode nn${n} exited${N}" 
				cat /tmp/out | grep 'NameNode' &>/dev/null
				[[ "$?" == "0" ]] && State=$(hdfs haadmin -getServiceState nn${n}) \
				&& echo "${nn}.example.org State: "$State" "
				cat /tmp/out | grep 'NameNode' &>/dev/null
				[[ "$?" == "1" ]] && ${nn}=$(echo "d")
				n=$((n+1))
			done
		#check ResourceManager 1, 2
			n=1
			for rm in ${rm1} ${rm2} 
			do
				ssh ${rm} jps &> /tmp/out
				cat /tmp/out | grep 'ResourceManager' &>/dev/null
				[[ "$?" == "0" ]] && echo -e "${G}ResourceManager rm${n} started${N}"   \
				|| echo -e "${R}ResourceManager rm${n} exited${N}" 
				cat /tmp/out | grep 'ResourceManager' &>/dev/null
				[[ "$?" == "0" ]] && State=$(yarn rmadmin -getServiceState rm${n}) \
				&& echo "${rm}.example.org State: "$State" "
				cat /tmp/out | grep 'ResourceManager' &>/dev/null
				[[ "$?" == "1" ]] && ${rm}=$(echo "d")
				n=$((n+1))
			done
		#check JobHistoryServer
			ssh ${jhs} jps &> /tmp/out
			cat /tmp/out | grep 'JobHistoryServer' &>/dev/null
			[[ "$?" == "0" ]] && echo -e "${G}JobHistoryServer started${N}" && echo "${jhs}.example.org" \
			|| echo -e "${R}JobHistoryServer exited${N}"  
		#check ZooKeeper 1,2,3
			n=1
			for zk in ${zk1} ${zk2} ${zk3}
			do
				ssh ${zk} jps &> /tmp/out
				cat /tmp/out | grep 'QuorumPeerMain' &>/dev/null
				[[ "$?" == "0" ]] && echo -e "${G}ZooKeeper zk${n} started${N}"  && echo "${zk}.example.org" \
				|| echo -e "${R}ZooKeeper zk${n} exited${N}" 
				n=$((n+1))
			done
		#check JournalNode 1,2,3
			n=1
			for jn in ${jn1} ${jn2} ${jn3}
			do
				ssh ${jn} jps &> /tmp/out
				cat /tmp/out | grep 'JournalNode' &>/dev/null
				[[ "$?" == "0" ]] && echo -e "${G}JournalNode JN${n} started${N}"  && echo "${jn}.example.org" \
				|| echo -e "${R}JournalNode JN${n} exited${N}" 
				n=$((n+1))
			done
		#check DataNodes
			[[ $nn1 == "d" && $nn2 == "d" ]] && exit 1
			hdfs dfsadmin -report &> /tmp/out
			total=$(cat /tmp/out | grep 'Name: ' | cut -d " " -f3 | wc -l)
			echo -e "${G}Live DataNodes: $total ${N}" 
			cat /tmp/out | grep 'Name: ' | cut -d " " -f3 | cut -d "(" -f2 | cut -d ")" -f1
		#check NodeManager
			[[ $rm1 == "d" && $rm2 == "d" ]] && exit 1
			yarn node -list &> /tmp/out
			total=$(cat /tmp/out | grep 'Nodes' | cut -d ":" -f2) 
			echo -e "${G}Live NodeManager: $total ${N}"
			cat /tmp/out | grep 'RUNNING' | cut -d " " -f1 | cut -d ":" -f1
	else
		#一般叢集
		#自動檢查檢查XML各服務主機
			hadoop=$(cat ${hadoop_home}core-site.xml  | ${grep1} "fs.defaultFS" | ${awk2} )
			nna=$(echo ${hadoop#*://} | ${cut1} )
			hadoop=$(cat ${hadoop_home}yarn-site.xml | ${grep1} "yarn.resourcemanager.hostname" | ${awk2} )
			rma=$(echo ${hadoop#*value>} | ${cut1} )
			hadoop=$(cat ${hadoop_home}apred-site.xml | ${grep1} "mapreduce.jobhistory.address" | ${awk2} )
			jhs=$(echo ${hadoop#*value>} | ${cut1} )
		#check NameNode
			ssh ${nna} jps &> /tmp/out
			echo ""
			cat /tmp/out | grep 'NameNode' &>/dev/null
			[[ "$?" == "0" ]] && echo -e "${G}NameNode started${N}"  && echo "${nna}.example.org" \
			|| echo -e "${R}NameNode exited${N}" 
			cat /tmp/out | grep 'NameNode' &>/dev/null 
			[[ "$?" == "1" ]] && nna=$(echo "d")
			echo ""
		#check ResourceManager
			ssh ${rma} jps &> /tmp/out
			cat /tmp/out | grep 'ResourceManager' &>/dev/null
			[[ "$?" == "0" ]] && echo -e "${G}ResourceManager started${N}" && echo "${rma}.example.org" \
			|| echo -e "${R}ResourceManager exited${N}" 
			cat /tmp/out | grep 'ResourceManager' &>/dev/null 
			[[ "$?" == "1" ]] && rma=$(echo "d")
			echo ""
		#check JobHistoryServer
			ssh ${jhs} jps &> /tmp/out
			cat /tmp/out | grep 'JobHistoryServer' &>/dev/null
			[[ "$?" == "0" ]] && echo -e "${G}JobHistoryServer started${N}" && echo "${jhs}.example.org" \
			|| echo -e "${R}JobHistoryServer exited${N}"  
			echo ""
		#check DataNodes
			[[ $nna == "d" ]] && exit 1
			hdfs dfsadmin -report &> /tmp/out
			total=$(cat /tmp/out | grep 'Name: ' | cut -d " " -f3 | wc -l)
			echo -e "${G}Live DataNodes: $total ${N}" 
			cat /tmp/out | grep 'Name: ' | cut -d " " -f3
			echo ""
		#check NodeManager
			[[ $rma == "d" ]] && exit 1
			yarn node -list &> /tmp/out
			total=$(cat /tmp/out | grep 'Nodes' | cut -d ":" -f2) 
			echo  -e "${G}Live NodeManager: $total ${N}"
			cat /tmp/out | grep 'RUNNING' | cut -d " " -f1 | cut -d ":" -f1
			echo ""
fi

