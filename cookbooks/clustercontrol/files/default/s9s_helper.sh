#!/bin/bash
# Data bag builder for ClusterControl cookbook

echo "=============================================="
echo "Helper script for ClusterControl Chef cookbook"
echo "=============================================="

cluster_type="galera"
email_address="admin@localhost.xyz"
cmon_mysql_password="cmon"
mysql_root_password="password"
os_user="root"
ssh_port=22
ssh_key="id_rsa"
mongodb_type="replicaset"
vendor="percona"
datadir="/var/lib/mysql"

rel_dir=`dirname "$0"`
root_dir=`cd $rel_dir;pwd`

KEYFILE="${root_dir}/${ssh_key}"
KEYFILE_PUB="${KEYFILE}.pub"
KEYGEN=`command -v ssh-keygen`
OUTPUT="${root_dir}/config.json"
[ -z "$KEYGEN" ] && echo "Error: Unable to locate ssh-keygen binary" && exit 1
flag=0

function value_required ()
{
	echo ''
	echo 'Error: Value is required'
	exit 1
}

function do_rsa_keygen()
{
	if [ ! -f $KEYFILE ]; then
		$KEYGEN -q -t rsa -f $KEYFILE -C '' -N '' >& /dev/null
		chmod 644 $KEYFILE
		chmod 644 $KEYFILE_PUB
		flag=1
	fi
}

echo ""
echo "ClusterControl requires an email address to be configured as super admin user."
read -p "What is your email address? [admin@localhost.xyz]: " x
[ ! -z "$x" ] && email_address=$x

echo ""
read -p "What is the IP address for ClusterControl host?: " x
[ ! -z "$x" ] && clustercontrol_host=$x || value_required

echo ""
echo "ClusterControl will create a MySQL user called 'cmon' for automation tasks."
read -p "Enter the user cmon password [cmon] : " x
[ ! -z "$x" ] && cmon_mysql_password=$x

echo ""
echo "What is your database cluster type? "
read -p "(galera|mysqlcluster|mysql_single|replication|mongodb) [galera]: " x
[ ! -z "$x" ] && [ "$x" != "mysqlcluster" ] && [ "$x" != "replication" ]  && [ "$x" != "galera" ] && [ "$x" != "mongodb" ] && [ "$x" != "mysql_single" ] && echo "Unsupported cluster." && exit 1
[ ! -z "$x" ] && cluster_type=$x
[ "$cluster_type" == "replication" ] && cluster_type="mysql_single"

if [ "$cluster_type" == "galera" ]; then
	echo ""
	echo "What is your Galera provider?"
	read -p "(codership|percona|mariadb) [percona]: " x
	[ ! -z "$x" ] && [ "$x" != "codership" ] && [ "$x" != "percona" ] && [ "$x" != "mariadb" ] && echo "Unsupported vendor." && exit 1
	[ ! -z "$x" ] && vendor=$x
fi

echo ""
echo "ClusterControl requires an OS user for passwordless SSH. If user is not root, the user must be in sudoer list."
read -p "What is the OS user? [root]: " x
[ ! -z "$x" ] && os_user=$x
if [ "$os_user" != "root" ]; then
	read -p 'Please enter the sudo password (if any). Just press enter if you are using sudo without password: ' x
	[ ! -z "$x" ] && sudo_password=$x || sudo_password=
fi

echo ""
read -p "What is your SSH port? [22]: " x
[ ! -z "$x" ] && ssh_port=$x

echo ""
if [ "$cluster_type" != "mongodb" ]; then
	if [ "$cluster_type" == "galera" ] || [ "$cluster_type" == "replication" ] || [ "$cluster_type" == "mysql_single" ]; then
		read -p "List of your MySQL nodes (comma-separated list): " x
		[ ! -z "$x" ] && mysql_server_addresses=$x || value_required
	else
		read -p "SQL nodes' IP addresses (comma-separated list): " x
		[ ! -z "$x" ] && mysql_server_addresses=$x || value_required
		read -p "Data nodes' IP addresses (comma-separated list): " x
		[ ! -z "$x" ] && datanode_addresses=$x || value_required
		read -p "Management nodes' IP addresses (comma-separated list): " x
		[ ! -z "$x" ] && mgmnode_addresses=$x || value_required
		read -p "What is your NDB connectstring? (eg: ip1:1186,ip2:1186..): " x
		[ ! -z "$x" ] && ndb_connectstring=$x || value_required
	fi
	echo ""
	echo "ClusterControl needs to have your database nodes' MySQL root password to perform installation and grant privileges."
	read -p "Enter the MySQL root password on the database nodes [$mysql_root_password]: " x
	[ ! -z "$x" ] && mysql_root_password=$x
	echo "We presume all database nodes are using the same MySQL root password."
	echo ""
else
	echo "What type of MongoDB cluster do you have?"
	read -p "(replicaset|shardedcluster) [replicaset]: " x
	[ ! -z "$x" ] && [ "$x" != "replicaset" ]  && [ "$x" != "shardedcluster" ] && echo "Unsupported cluster." && exit 1
	[ ! -z "$x" ] && mongodb_type=$x
	read -p "MongoDB arbiter instances if any (ip:port - comma-separated list): " x
	[ ! -z "$x" ] && mongoarbiter_server_addresses=$x || mongoarbiter_server_addresses=
	if [ "$mongodb_type" == "shardedcluster" ]; then
		read -p "MongoDB configsvr instances (ip:port - comma-separated list): " x
		[ ! -z "$x" ] && mongocfg_server_addresses=$x || value_required
		read -p "MongoDB mongos instances (ip:port - comma-separated list): " x
		[ ! -z "$x" ] && mongos_server_addresses=$x || value_required
	fi
	read -p "MongoDB shardsvr/replSet instances (ip:port - comma-separated list): " x
	[ ! -z "$x" ] && mongodb_server_addresses=$x || value_required
	datadir=/var/lib/mongodb
fi
read -p "Data directory path [$datadir]: " x
[ ! -z "$x" ] && datadir=$x

do_rsa_keygen
api_token=$(python -c 'import uuid; print uuid.uuid4()' | sha1sum | cut -f1 -d' ')

echo 'Generating config.json..'
echo '{' > $OUTPUT
echo '	"id" : "config",' >> $OUTPUT
echo "	\"cluster_type\" : \"$cluster_type\"," >> $OUTPUT
[ "$cluster_type" == "galera" ] && echo "	\"vendor\" : \"$vendor\"," >> $OUTPUT
echo "	\"email_address\" : \"$email_address\"," >> $OUTPUT
echo "	\"ssh_user\" : \"$os_user\"," >> $OUTPUT
[ ! -z "$sudo_password" ] && echo "	\"sudo_password\" : \"$sudo_password\"," >> $OUTPUT
[ $ssh_port -ne 22 ] && echo "	\"ssh_port\" : \"$ssh_port\"," >> $OUTPUT
[ "$cmon_mysql_password" != "cmon" ] && echo "	\"cmon_password\" : \"$cmon_mysql_password\"," >> $OUTPUT
if [ "$cluster_type" != "mongodb" ]; then
	echo "	\"mysql_root_password\" : \"$mysql_root_password\"," >> $OUTPUT
	echo "	\"mysql_server_addresses\" : \"$mysql_server_addresses\"," >> $OUTPUT
	if [ "$cluster_type" == "mysqlcluster" ]; then
		echo "	\"datanode_addresses\" : \"$datanode_addresses\"," >> $OUTPUT
		echo "	\"mgmnode_addresses\" : \"$mgmnode_addresses\"," >> $OUTPUT
	fi
else
	echo "	\"mongodb_server_addresses\" : \"$mongodb_server_addresses\"," >> $OUTPUT
	if [ "$mongodb_type" == "shardedcluster" ]; then
		echo "	\"mongoarbiter_server_addresses\" : \"$mongoarbiter_server_addresses\"," >> $OUTPUT
		echo "	\"mongocfg_server_addresses\" : \"$mongocfg_server_addresses\"," >> $OUTPUT
		echo "	\"mongos_server_addresses\" : \"$mongos_server_addresses\"," >> $OUTPUT
	fi
fi
echo "  \"datadir\" : \"$datadir\"," >> $OUTPUT
echo "	\"clustercontrol_host\" : \"$clustercontrol_host\"," >> $OUTPUT
echo "	\"clustercontrol_api_token\" : \"$api_token\"" >> $OUTPUT
echo '}' >> $OUTPUT

cat $OUTPUT

echo ""
echo "Data bag file generated at $OUTPUT"
echo "To upload the data bag, you can use following command:"
echo "$ knife data bag create clustercontrol"
echo "$ knife data bag from file clustercontrol $OUTPUT"
echo ""
[ $flag -eq 1 ] && echo -e "Reupload the cookbook since it contains a newly generated SSH key: \n$ knife cookbook upload clustercontrol"
echo "** We highly recommend you to use encrypted data bag since it contains confidential information **"
echo ""
