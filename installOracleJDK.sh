#!/bin/sh

#+-----------------------------------------------------------------------+
#|               Copyright (C) 2015-2016 George Z. Zachos                |
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
	echo -n "Enter your username(<username>@<host>) and press [ENTER]:\n > "
	read USERNAME

	# Check if $USERNAME is empty.
	if [ -z "${USERNAME}" ]
	then
		echo  "\n***ERROR***\nUsername is empty.\nScript will now exit.\n"
		exit 1
	fi

	# $DIRPATH gets the absolute path of the user's 'Downloads' directory assigned.
	DIRPATH="/home/${USERNAME}/Downloads/"
else
	# $DIRPATH is assigned the absolute path given as a command line argument.
	DIRPATH=${1}
	# Check if $DIRPATH ends with a forward slash.
	last_char=$(echo ${DIRPATH} | tail -c 2)
	if [ "${last_char}" != "/" ]
	then
		echo "\n***ERROR***\n${DIRPATH}: Path should end with a '/'.\nScript will now exit.\n"
		exit 2
	fi
fi

# Check if $DIRPATH is a valid directory.
if [ ! -d "${DIRPATH}" ]
then
	echo "\n***ERROR***\n${DIRPATH}: Not a valid directory.\nScript will now exit.\n"
	exit 3
fi

# $FILES holds all the filenames inside $DIRPATH directory that begin with 'jdk-' and end with '.tar.gz'.
FILES=$(sudo ls -1 ${DIRPATH} | grep ^jdk- | grep .tar.gz$ | tr "\n" "\n")

# Check if there are any filenames complying with the previous checks.
if [ -z "${FILES}" ]
then
	echo  "\n***ERROR***\nThere is no '.tar.gz' file associated with Oracle JDK inside ${DIRPATH} directory.\nScript will now exit.\n"
	exit 4
fi

# $FILENUM holds the number of files held in $FILES
FILENUM=$(echo $FILES | wc -w)

# If there are more than one files, prompt user to choose one.
if [ ${FILENUM} -gt 1 ]
then
	# The existing files inside $DIRPATH directory are printed one every single line,
	# including a number/index at the beginning of each line.
	echo "\nThe following files were found inside \"${DIRPATH}\" directory:"
	INDEX=0
	for file in ${FILES}
	do
		echo "[${INDEX}] ${file}"
		INDEX=$((INDEX+1))
	done
	# Prompt user to enter the number/index of the file to be installed.
	echo -n "\nEnter the number/index of the file you want to be installed (0-$((INDEX-1))) and press [ENTER]:\n > "
	read CHOICE
	# if $CHOICE holds a valid number/index, the related filename is assigned to $FILE.
	if [ ${CHOICE} -lt 0 ] || [ ${CHOICE} -ge ${INDEX} ]
	then
		echo  "\n***ERROR***\nInvalid choice!\nScript will now exit.\n"
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
	echo "\nChosen file: ${file}\n"
	sleep 3
else
	# If $FILES holds only one filename, it's value is assigned to $FILE.
	FILE=${FILES}
fi

# $TYPE holds the type of the file held in $FILE
TYPE="$(file -b ${DIRPATH}${FILE} | awk '{print $1}')"

# Check if the type of $FILE matches "gzip".
if  [ "${TYPE}" != "gzip" ]
then
	echo "\n***ERROR***\nThere is no '.tar.gz.' file associated with Oracle JDK inside ${DIRPATH} directory.\nScript will now exit.\n"
	exit 6
fi

# If execution reaches this point of the script, it means that there is a valid JDK '.tar.gz'
# file inside $DIRPATH. The following part of the script is the one that conducts the installation.

# Extract the 'tar.gz' file in the current directory.
tar -zxvf ${DIRPATH}${FILE}
X1="$?"

# The 'java' directory is created inside /usr/local/ directory
sudo mkdir /usr/local/java
X2="$?"

# Move the 'java' directory created from the extraction above to /usr/local/java/
sudo mv ./jdk[0-9].[0-9].* /usr/local/java
X3="$?"

# $DIRNAME holds the name of the directory created by extracting the JDK ".tar.gz" file
DIRNAME=$(ls -1 /usr/local/java | tr -d '\n')
X4="$?"

# Updating /etc/profile
sudo echo -e "######### Oracle JDK #########\nJAVA_HOME=/usr/local/java/$DIRNAME\nPATH=\$PATH:\$HOME/bin:\$JAVA_HOME/bin\nJRE_HOME=/usr/local/java/$DIRNAME/jre\nPATH=\$PATH:\$HOME/bin:\$JRE_HOME/bin\nexport JAVA_HOME\nexport JRE_HOME\nexport PATH" >> /etc/profile
X5="$?"

# Updating alternatives
sudo update-alternatives --install "/usr/bin/java" "java" "/usr/local/java/$DIRNAME/jre/bin/java" 1
X6="$?"
sudo update-alternatives --install "/usr/bin/javac" "javac" "/usr/local/java/$DIRNAME/bin/javac" 1
X7="$?"
sudo update-alternatives --install "/usr/bin/javaws" "javaws" "/usr/local/java/$DIRNAME/bin/javaws" 1
X8="$?"
sudo update-alternatives --set java /usr/local/java/$DIRNAME/jre/bin/java
X9="$?"
sudo update-alternatives --set javac /usr/local/java/$DIRNAME/bin/javac
X10="$?"
sudo update-alternatives --set javaws /usr/local/java/$DIRNAME/bin/javaws
X11="$?"

# Changing permissions of the /etc/profile
sudo chmod 744 /etc/profile
X12="$?"

# Executing /etc/profile
sudo /etc/profile
X13="$?"

# The exit code of each substantial command is held at the variables from $X1 to $X13.
# If there are no errors, each exit code equals to "0". The sum of all exit codes is held on $SUM.
SUM=$((X1+X2+X3+X4+X5+X6+X7+X8+X9+X10+X11+X12+X13))

# Finally, feedback about the installation status is given to the user according to the value of $SUM.
# Note that in UNIX-like systems, the exit code is represented as an 8-bit unsigned(!) char [1-255].
if [ "${SUM}" -eq "0" ]
then
        echo "\n##################################################################################"
        echo   "#                        The installation was successful!                        #"
        echo   "##################################################################################\n"
        exit 0
else
        echo "\n##################################################################################"
        echo   "#                      The installation was NOT successful!                      #"
        echo   "##################################################################################\n"
        exit 7
fi
