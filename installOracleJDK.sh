#!/usr/bin/env bash

#+-----------------------------------------------------------------------+
#|               Copyright (C) 2015-2018 George Z. Zachos                |
#+-----------------------------------------------------------------------+
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# Contact Information:
# Name: George Z. Zachos
# Email: gzzachos_at_gmail.com


# Run the script with the following command to
# view the program's exit code:
# 	$ sudo ./installOracleJDK.sh; echo "exit code: $?";


# Print error ${2} and exit with ${1} as an exit code.
perror_exit () {
	echo -e "\n***ERROR***"
	echo -e "${2}"
	echo -e "Script will now exit.\n"
	exit ${1}
}

install_set_alternative () {
	sudo update-alternatives --install "/usr/bin/${1}" "${1}" "/usr/local/java/${JDK_DIR}/bin/${1}" 1
	EC=$?
	if [ ${EC} -ne 0 ]
	then
		echo -e "\n***WARNING***"
		echo -e "Could not install \"${1}\" alternative. Exit code of 'update-alternatives': ${EC}.\n"
		EFLAG=1
	fi

	sudo update-alternatives --set "${1}" "/usr/local/java/${JDK_DIR}/bin/${1}"
	EC=$?
	if [ ${EC} -ne 0 ]
	then
		echo -e "\n***WARNING***"
		echo -e "Could not set \"${1}\" alternative. Exit code of 'update-alternatives': ${EC}."
		echo -e "Use \"update-alternatives --config ${1}\" to manually configure alternatives.\n"
		EFLAG=1
	fi
}

# An initial message is printed to console.
echo "##################################################################################"
echo "#                ***  You are about to install Oracle JDK ***                    #"
echo "#                                                                                #"
echo "# First, download the preferred version of JDK and save the '.tar.gz' file       #"
echo "# inside the 'Downloads' directory of your home directory. Then execute this     #"
echo "# script from any directory you want via the command below:                      #"
echo "#        sudo ./installOracleJDK.sh                                              #"
echo "#                 (Make sure the script exists inside your current directory!)   #"
echo "#                                                                                #"
echo "# In case you started downloading JDK after executing this script,               #"
echo "# wait until download is complete and then provide your username!!!              #"
echo "#                                                                                #"
echo "#         NOTE: You can override the default directory option by providing the   #"
echo "#               (absolute) path of the directory containing the '.tar.gz' file   #"
echo "#               as a command line argument!                                      #"
echo "#                                                                                #"
echo "#               *** For more information refer to README.md ***                  #"
echo "##################################################################################"

# If no command line argument is provided.
if [ -z "${1}" ]
then
	# Prompt user to provide a username.
	# The script is executed as root, so 'whoami' may be invalid.
	echo -en "Enter your username(<username>@`hostname`) and press [ENTER]:\n > "
	read USERNAME

	# Check if $USERNAME is empty.
	if [ -z "${USERNAME}" ]
	then
		perror_exit 1 "Username is empty."
	fi

	# $DIRPATH gets the absolute path of the user's 'Downloads' directory assigned.
	DIRPATH="/home/${USERNAME}/Downloads/"
else
	# $DIRPATH is assigned the absolute path given as a command line argument.
	DIRPATH="${1}"
	# Check if $DIRPATH ends with a forward slash.
	if [ "${DIRPATH:(-1)}" != "/" ]
	then
		perror_exit 2 "${DIRPATH}: Path should end with a '/'."
	fi
fi

# Check if $DIRPATH is a valid directory.
if [ ! -d "${DIRPATH}" ]
then
	perror_exit 3 "${DIRPATH}: Not a valid directory."
fi

# $FILES holds all the filenames inside $DIRPATH directory that begin with 'jdk-' and end with '.tar.gz'.
FILES=$(sudo ls -1 "${DIRPATH}" | grep ^jdk- | grep .tar.gz$ | tr "\n" "\n")

# Check if there are any filenames complying with the previous checks.
if [ -z "${FILES}" ]
then
	perror_exit 4 "There is no '.tar.gz' file associated with Oracle JDK inside ${DIRPATH} directory."
fi

# $FILENUM holds the number of files held in $FILES
FILENUM=$(echo ${FILES} | wc -w)

# If there are more than one files, prompt user to choose one.
if [ ${FILENUM} -gt 1 ]
then
	# The existing files inside $DIRPATH directory are printed one every single line,
	# including a number/index at the beginning of each line.
	echo -e "\nThe following files were found inside \"${DIRPATH}\" directory:"
	INDEX=0
	for file in ${FILES}
	do
		echo "[${INDEX}] ${file}"
		INDEX=$((INDEX+1))
	done

	# Prompt user to enter the number/index of the file to be installed.
	echo -en "\nEnter the number/index of the file you want to be installed (0-$((INDEX-1))) and press [ENTER]:\n > "
	read CHOICE
	# if $CHOICE holds a valid number/index, the related filename is assigned to $FILE.
	if [ ${CHOICE} -lt 0 ] || [ ${CHOICE} -ge ${INDEX} ]
	then
		perror_exit 5 "Invalid choice!"
	fi

	INDEX=0
	for file in ${FILES}
	do
		if [ ${CHOICE} -eq ${INDEX} ]
		then
			FILE=${file}
			break
		fi
		INDEX=$((INDEX+1))
	done
	echo -e "\nChosen file: ${FILE}\n"
	sleep 5
else
	# If $FILES holds only one filename, it's value is assigned to $FILE.
	FILE=${FILES}
fi

# $TYPE holds the type of the file held in $FILE
TYPE="$(file -b ${DIRPATH}${FILE})"

# Check if the type of $FILE matches "gzip".
if  [ "${TYPE:0:4}" != "gzip" ]
then
	perror_exit 6 "There is no '.tar.gz.' file associated with Oracle JDK inside ${DIRPATH} directory."
fi

# If execution reaches this point of the script, it means that there is a valid JDK '.tar.gz'
# file inside $DIRPATH. The following part of the script is the one that conducts the installation.

# The 'java' directory is created inside /usr/local/ directory
if [ ! -d "/usr/local/java" ]
then
	if ! sudo mkdir /usr/local/java
	then
		perror_exit 7 "There was a problem creating \"/usr/local/java/\"."
	fi
fi

# Extract the 'tar.gz' file in the current directory.
if ! sudo tar -zxvf ${DIRPATH}${FILE} -C /usr/local/java
then
	perror_exit 8 "There was a problem exporting \"${DIRPATH}${FILE}\" in \"/usr/local/java/\"."
fi

JDK_VERSION=$(echo ${FILE} | sed 's/jdk-\(.*\)[-_]linux.*/\1/g')
JDK_DIR="jdk-${JDK_VERSION}"
JRE_PROFILE_LINES=""

# Override ${JDK_DIR} and ${JRE_PROFILE_LINES} in case of Java 8
if [ "${JDK_VERSION:0:2}" = "8u" ]
then
	JDK_UPDATE=$(echo ${JDK_VERSION:2})
	JDK_DIR=$(ls -1t /usr/local/java | grep "${JDK_UPDATE}" | head -1)
	JRE_PROFILE_LINES="JRE_HOME=/usr/local/java/$JDK_DIR/jre\nPATH=\$PATH:\$JRE_HOME/bin\nexport JRE_HOME"
fi

# Updating /etc/profile
sudo echo -e \
"######### Oracle JDK #########
JAVA_HOME=/usr/local/java/${JDK_DIR}
PATH=\$PATH:\$JAVA_HOME/bin
${JRE_PROFILE_LINES}
export JAVA_HOME
export PATH" >> /etc/profile

if [ $? -ne 0 ]
then
	perror_exit 9 "Could not update \"/etc/profile\"."
fi

# Updating alternatives
EFLAG=0
install_set_alternative "java"
install_set_alternative "javac"
install_set_alternative "javaws"

# Changing permissions of the /etc/profile
if ! sudo chmod 744 /etc/profile
then
	perror_exit 10 "Problem changing mode of \"/etc/profile\"."
fi

# Executing /etc/profile
if ! sudo /etc/profile
then
	perror_exit 11 "Problem executing \"/etc/profile\"."
fi

# Finally, feedback about the installation status is given to the user according to the value of $EFLAG.
# Note that in UNIX-like systems, the exit code is represented as an 8-bit unsigned(!) char [1-255].
if [ ${EFLAG} -eq 0 ]
then
        echo -e "\n##################################################################################"
        echo     "#                        The installation was successful!                        #"
        echo -e  "##################################################################################\n"
        exit 0
else
        echo -e "\n##################################################################################"
        echo     "#                      The installation was NOT successful!                      #"
        echo     "#           One or more alternatives could not be installed and/or set!          #"
        echo -e  "##################################################################################\n"
        exit 12
fi
