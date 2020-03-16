#!/bin/bash
# Data bag builder for ClusterControl cookbook

echo "=============================================="
echo "Helper script for ClusterControl Chef cookbook"
echo "=============================================="

default_password="s3cr3tcc"
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
read -p "Enter the password for MySQL root user [default: '$default_password'] : " x
[ ! -z "$x" ] && mysql_root_password=$x

echo ""
echo "ClusterControl will create a MySQL user called 'cmon' for automation tasks."
read -p "Enter the password for user cmon [default: '$default_password'] : " x
[ ! -z "$x" ] && cmon_mysql_password=$x

echo ""
echo "ClusterControl will need a sudo user (from ClusterControl to all managed nodes) to perform automation tasks via SSH."
read -p "Enter the SSH user [default: root] : " x
[ ! -z "$x" ] && cmon_ssh_user=$x

do_rsa_keygen
api_token=$(python -c 'import uuid; print uuid.uuid4()' | sha1sum | cut -f1 -d' ')

echo ""
echo 'Generating config.json..'
echo '{' > $OUTPUT
echo '    "id" : "config",' >> $OUTPUT
if [ "$mysql_root_password" != $default_password ] && [ ! -z "$mysql_root_password" ]; then
	echo "    \"mysql_root_password\" : \"$mysql_root_password\"," >> $OUTPUT
else
	echo "    \"mysql_root_password\" : \"$default_password\"," >> $OUTPUT
fi
if [ "$cmon_mysql_password" != $default_password ] && [ ! -z "$cmon_mysql_password" ]; then
	echo "    \"cmon_password\" : \"$cmon_mysql_password\"," >> $OUTPUT
else
	echo "    \"cmon_password\" : \"$default_password\"," >> $OUTPUT
fi
if [ "$cmon_ssh_user" != "root" ] && [ ! -z "$cmon_ssh_user" ]; then
	echo "    \"cmon_ssh_user\" : \"$cmon_ssh_user\"," >> $OUTPUT
else
	echo "    \"cmon_ssh_user\" : \"root\",">> $OUTPUT
fi
if [ "$cmon_ssh_user" != "root" ] && [ ! -z "$cmon_ssh_user" ]; then
	echo "    \"cmon_user_home\" : \"/home/$cmon_ssh_user\"," >> $OUTPUT
else
	echo "    \"cmon_user_home\" : \"/root\"," >> $OUTPUT
fi
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
