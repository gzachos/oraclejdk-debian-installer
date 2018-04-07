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
	echo -en "Enter your username(<username>@<host>) and press [ENTER]:\n > "
	read USERNAME

	# Check if $USERNAME is empty.
	if [ -z "${USERNAME}" ]
	then
		echo -e "\n***ERROR***\nUsername is empty.\nScript will now exit.\n"
		exit 1
	fi

	# $DIRPATH gets the absolute path of the user's 'Downloads' directory assigned.
	DIRPATH="/home/${USERNAME}/Downloads/"
else
	# $DIRPATH is assigned the absolute path given as a command line argument.
	DIRPATH="${1}"
	# Check if $DIRPATH ends with a forward slash.
	if [ "${DIRPATH:(-1)}" != "/" ]
	then
		echo -e "\n***ERROR***\n${DIRPATH}: Path should end with a '/'.\nScript will now exit.\n"
		exit 2
	fi
fi

# Check if $DIRPATH is a valid directory.
if [ ! -d "${DIRPATH}" ]
then
	echo -e "\n***ERROR***\n${DIRPATH}: Not a valid directory.\nScript will now exit.\n"
	exit 3
fi

# $FILES holds all the filenames inside $DIRPATH directory that begin with 'jdk-' and end with '.tar.gz'.
FILES=$(sudo ls -1 "${DIRPATH}" | grep ^jdk- | grep .tar.gz$ | tr "\n" "\n")

# Check if there are any filenames complying with the previous checks.
if [ -z "${FILES}" ]
then
	echo -e "\n***ERROR***\nThere is no '.tar.gz' file associated with Oracle JDK inside ${DIRPATH} directory.\nScript will now exit.\n"
	exit 4
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
		echo -e "\n***ERROR***\nInvalid choice!\nScript will now exit.\n"
		exit 5
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
	echo -e "\nChosen file: ${file}\n"
	sleep 3
else
	# If $FILES holds only one filename, it's value is assigned to $FILE.
	FILE=${FILES}
fi

# $TYPE holds the type of the file held in $FILE
TYPE="$(file -b ${DIRPATH}${FILE})"

# Check if the type of $FILE matches "gzip".
if  [ "${TYPE:0:4}" != "gzip" ]
then
	echo -e "\n***ERROR***\nThere is no '.tar.gz.' file associated with Oracle JDK inside ${DIRPATH} directory.\nScript will now exit.\n"
	exit 6
fi

# If execution reaches this point of the script, it means that there is a valid JDK '.tar.gz'
# file inside $DIRPATH. The following part of the script is the one that conducts the installation.

# The 'java' directory is created inside /usr/local/ directory
X1=0
if [ ! -d "/usr/local/java" ]
then
	sudo mkdir /usr/local/java
	X1="$?"
fi

# Extract the 'tar.gz' file in the current directory.
sudo tar -zxvf ${DIRPATH}${FILE} -C /usr/local/java
X2="$?"

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
X3="$?"

# Updating alternatives
sudo update-alternatives --install "/usr/bin/java" "java" "/usr/local/java/${JDK_DIR}/bin/java" 1
X4="$?"
sudo update-alternatives --install "/usr/bin/javac" "javac" "/usr/local/java/${JDK_DIR}/bin/javac" 1
X5="$?"
sudo update-alternatives --install "/usr/bin/javaws" "javaws" "/usr/local/java/${JDK_DIR}/bin/javaws" 1
X6="$?"
sudo update-alternatives --set java "/usr/local/java/${JDK_DIR}/bin/java"
X7="$?"
sudo update-alternatives --set javac "/usr/local/java/${JDK_DIR}/bin/javac"
X8="$?"
sudo update-alternatives --set javaws "/usr/local/java/${JDK_DIR}/bin/javaws"
X9="$?"

# Changing permissions of the /etc/profile
sudo chmod 744 /etc/profile
X10="$?"

# Executing /etc/profile
sudo /etc/profile
X11="$?"

# The exit code of each substantial command is held at the variables from $X1 to $X11.
# If there are no errors, each exit code equals to "0". The sum of all exit codes is held on $SUM.
SUM=$((X1+X2+X3+X4+X5+X6+X7+X8+X9+X10+X11))

# Finally, feedback about the installation status is given to the user according to the value of $SUM.
# Note that in UNIX-like systems, the exit code is represented as an 8-bit unsigned(!) char [1-255].
if [ "${SUM}" -eq "0" ]
then
        echo -e "\n##################################################################################"
        echo     "#                        The installation was successful!                        #"
        echo -e  "##################################################################################\n"
        exit 0
else
        echo -e "\n##################################################################################"
        echo     "#                      The installation was NOT successful!                      #"
        echo -e  "##################################################################################\n"
        exit 7
fi
