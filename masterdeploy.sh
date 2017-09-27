#!/usr/bin/ksh
# Set MW environment
. /home/mqsi/.profile
# name: masterscript.sh
# author: Rama Kodam
# created: 28/08/2012
# Desc: This script is used to deploy bar files on a broker. The i2mp ticket number is provided as a command line parameter.
# eglist.cfg file has the list of interfaces(GAPIDs) deployed in each execution group, arguments used in mqsideploy command - ip, #config manager, port, broker.

deployBars(){

#	EG_LIST=$DEPLOYMENT_DIR/eglist.cfg

	HOST_IP=`grep host_ip $EG_LIST|awk '{print $2}'`
	CFGQMGR_PORT=`grep cfgqmgr_port $EG_LIST|awk '{print $2}'`
	CFG_QMGR=`grep cfg_qmgr $EG_LIST|awk '{print $2}'`
	BROKER=`grep broker $EG_LIST|awk '{print $2}'`

	#HOST_IP=`ifconfig en1|grep inet|awk '{print $2}'`
	#I2MPTicket=$1
	PROPERTIES_FILE=$DEPLOYMENT_DIR/override.properties
	EG_NAME=''
	GAP_ID=''

	#if [ "X$I2MPTicket" = "X" ]
	#then
	#	echo "You have not entered I2MP directory"
	#	exit 1
	#fi

	if [ ! -e $DEPLOYMENT_DIR/$I2MPTicket/bars/*.bar ]
	then
		echo "No bar files found. Please make sure the directory structure $DEPLOYMENT_DIR$I2MPTicket/bars exists and there are bar file(s) in it."
		exit 1
	fi

	#cd $DEPLOYMENT_DIR/$I2MPTicket/bars
	#if [ `ls *.bar 2>&1|wc -l` > 0 ] 
	#then
	#	echo "No bar files in the bars folder"
	#fi

	BAR_FILE_LIST=`ls *.bar`
	for barFile in $BAR_FILE_LIST
	do
		GAP_ID=`echo $barFile|sed 's/_.*//'`
		EG_NAME=`grep $GAP_ID $EG_LIST|awk '{print $1}'`
		if [ "X$EG_NAME" = "X" ]
		then
			echo "Bar file $barFile is incorrect. Please check/rename bar file as per interface to match from the list in $EGLIST."
			exit 1
		fi
		# check if it is 1002 invoices interfaces.
		if [ `echo $barFile|grep '1002.*Invoices'|wc -l` == 1 ]; then
			EG_NAME=default
		fi
		mqsiapplybaroverride -b $barFile -p $PROPERTIES_FILE >> override.log
		mqsideploy -i $HOST_IP -p $CFGQMGR_PORT -q $CFG_QMGR -b $BROKER -e $EG_NAME -a $barFile -w 900 >> deploy.log
	done
}

deployMq(){
	QMGR=`grep brk_qmgr $EG_LIST|awk '{print $2}'`
	if [ ! -e $DEPLOYMENT_DIR/$I2MPTicket/mq/*.mqs ]
		then
			echo "No mq scripts found. Please make sure the directory structure $DEPLOYMENT_DIR$I2MPTicket/mq exists and there are mq scripts in it."
			exit 1
	fi
	output=`sudo su - mqm << '	EOF'
	/home/mqm/bin/saveqmgr
	EOF`
	MQ_SCRIPTS=`ls *.mqs`
	for mqscript in $MQ_SCRIPTS
	do
		runmqsc $QMGR< $mqscript > $mqscript.log
	done
}

deploySql(){
	if [ ! -e $DEPLOYMENT_DIR/$I2MPTicket/sql/*.sql ]
		then
			echo "No sql scripts found. Please make sure the directory structure $DEPLOYMENT_DIR$I2MPTicket/sql exists and there are sql scripts in it."
			exit 1
	fi
	SQL_SCRIPTS=`ls *.sql`
	for sqlscript in $SQL_SCRIPTS
	do
		output=`sqlplus -s ${ENVDBLOGON}@${ENVDB} << EOF
		spool ${sqlscript}.log
		@${sqlscript}
		spool off
		quit
		EOF`
	done	
}

deployBo(){
	if [ ! -e $DEPLOYMENT_DIR/$I2MPTicket/bo/*.tar ]
		then
			echo "No sql scripts found. Please make sure the directory structure $DEPLOYMENT_DIR$I2MPTicket/sql exists and there are sql scripts in it."
			exit 1
	fi
	BO=`ls *.tar`
	for bo in $BO
	do
		conn=`echo $bo | sed 's/\(.\{3\}\).*/\1/'`
		server_add=`grep " $conn " $EG_LIST|awk '{print $1}'`
		cat $bo | ssh mqsi@$server_add 'tar xvf -'
		
	done

}

DEPLOYMENT_DIR=/staging/deployments
EG_LIST=$DEPLOYMENT_DIR/eglist.cfg
HOST_IP=`grep host_ip $EG_LIST|awk '{print $2}'`
I2MPTicket=$1

if [ "X$I2MPTicket" = "X" ]
then
	echo "You have not entered I2MP directory"
	exit 1
fi

cd $DEPLOYMENT_DIR/$I2MPTicket
for d in `ls`
do
	case $d in
		bars) cd $DEPLOYMENT_DIR/$I2MPTicket/bars
		      deployBars
		      ;;
		mq) cd $DEPLOYMENT_DIR/$I2MPTicket/mq
		    deployMq
		    ;;
		bo) cd $DEPLOYMENT_DIR/$I2MPTicket/bo
	    	    deployBo
		    ;;
		sql) cd $DEPLOYMENT_DIR/$I2MPTicket/sql
		     deploySql
		     ;;
		*) echo "Invalid directory $d"
		   ;;
	esac
done