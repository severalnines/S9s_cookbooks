#!/bin/bash
# Data bag builder for ClusterControl cookbook

echo "=============================================="
echo "Helper script for ClusterControl Chef cookbook"
echo "=============================================="

cmon_mysql_password="cmon"
mysql_root_password="password"
ssh_key="id_rsa"

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
echo "ClusterControl will install a MySQL server and setup the MySQL root user."
read -p "Enter the password for MySQL root user [password] : " x
[ ! -z "$x" ] && mysql_root_password=$x

echo ""
echo "ClusterControl will create a MySQL user called 'cmon' for automation tasks."
read -p "Enter the password for user cmon [cmon] : " x
[ ! -z "$x" ] && cmon_mysql_password=$x

do_rsa_keygen
api_token=$(python -c 'import uuid; print uuid.uuid4()' | sha1sum | cut -f1 -d' ')

echo ""
echo 'Generating config.json..'
echo '{' > $OUTPUT
echo '    "id" : "config",' >> $OUTPUT
[ "$mysql_root_password" != "password" ] && echo "    \"mysql_root_password\" : \"$mysql_root_password\"," >> $OUTPUT
[ "$cmon_mysql_password" != "cmon" ] && echo "    \"cmon_password\" : \"$cmon_mysql_password\"," >> $OUTPUT
echo "    \"clustercontrol_api_token\" : \"$api_token\"" >> $OUTPUT
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
