#! /bin/zsh

# a path where webapp jar is stored
webapp_home="/home/deoxys/Workspace/scripts/tomcat-webapp"
webapp_jar="tomcat-webapp-0.1.jar"

# a path to a directory in eclipse workspace were all web applications are stored
from="/home/deoxys/Workspace/eclipse-workspaces/workspace-01/web-applications"
# a path to a tomcat webapps directory
to="/usr/share/tomcat7/webapps"
# a directory in eclipse web project were all web resources are stored (such as WEB-INF directory, jsp, html files)
resources="WebContent"
# a directory in the web project hierarchy were compiled resources (classes) are stored: might be a 'build/classes' or a 'target/classes' (for a Maven project)
build="target/classes"

maven_repository="/home/deoxys/.m2/repository"
maven_resources="target/m2e-wtp/web-resources"

# counters for verifying if webapp exist or is already deployed
eclipse_webapp_count="0"
tomcat_webapp_count="0"

# colors
green="\e[32m"
orange="\e[33m"
blue="\e[34m"
red="\e[37m"

missing_attribute() {
	echo "$red\nError: wrong attributes, look for one from the list below:"
}

# check if there is such a webapp in eclipse-workspace/webapps directory
eclipse_webapp_count() {
	cd $from
	for directory in *
	do
		if [ $2 = $directory ]
		then
			eclipse_webapp_count="1"
		fi
	done
}

# check if webapp was deployed before
tomcat_webapp_count() {
	cd $to
	for linked_directory in *
	do
		if [ $2 = $linked_directory ]
		then
			tomcat_webapp_count="1"
		fi
	done
}

all() {
	echo "${green}\nECLIPSE WEBAPPS:$blue"
	cd $from

	for directory in */
	do
		echo "${directory%?}"
	done
	echo "${green}\nTOMCAT WEBAPPS:$blue"
	cd $to

	for directory in */
	do
		echo "${directory%?}"
	done
}

help() {
	echo "$blue--all     -a  -- displaying all webapps, whether they are or not deployed"
	echo "${orange}  example: webapp (--all | -a)"
	echo "$blue--deploy  -d  -- deploying your webapps in tomcat7/webapps directory"
	echo "${orange}  example: webapp (--deploy | -d) webapp_name"
 	echo "$blue--help    -h  -- help in managing with webapp"
	echo "${orange}  example: webapp (--help | -h)"
        echo "$blue--remove  -r  -- removing already deployed webapps from tomcat7/webapp"
	echo "${orange}  example: webapp (--remove | -r) webapp_name"
	echo "$blue--update  -u  -- updating deployed in tomcat7/webapps directory"
	echo "${orange}  example: webapp (--update | -u) webapp_name"
}

deploy() {
	eclipse_webapp_count $1 $2 && tomcat_webapp_count $1 $2
	# deploy webapp if there is such, or exit with message if there are no
	if [ $eclipse_webapp_count = "1" ]
	then
		# deploy webapp according to if it was deployed before, or not
		if [ $tomcat_webapp_count = "1" ]
		then
			echo "${red}Error: Requested webapp is already deployed. Try to update it with '--update', '-u' options."
		else
			sudo mkdir $2
			cd $from/$2/$resources

			echo "${green}Process: Deploying a new webapp: copying resources."
			for file in *
			do
				sudo cp -r $file $to/$2/

			# making links to all files from $resources except WEB-INF directory
			# for excluding the neccessity of creating the new files in it
			#	if [ $file = "WEB-INF" ]
			#	then	
			#		sudo cp -r $file $to/$2/
			#		echo "Done: WEB-INF directory was copied."
			#	else
			#		sudo ln -s $file $to/$2/
			#	fi
			done
			echo "Done: All required resources were copied."
			
			sudo cp -r $from/$2/$maven_resources/* $to/$2/
			
			cd $webapp_home
			echo "${green}Process: copying the Maven Dependencies."
			for jar in $(java -jar $webapp_jar $from/$2/pom.xml)
			do
				sudo cp $jar $to/$2/WEB-INF/lib/
			done

			sudo mkdir $to/$2/WEB-INF/classes
			if [ "$(ls -A $from/$2/$build)" ]
			then
				sudo cp -r $from/$2/$build/* $to/$2/WEB-INF/classes/
				echo "Done: All resources were copied to '$2/WEB-INF/classes' directory."
			else
				echo "${orange}Note: Nothing to copy: there are no resources in 'eclipse-webapps/$2/$build' directory."
			fi
			echo "${green}Done: A new webapp was successfully deployed to 'tomcat7/webapps' directory."
		fi
	else
		echo "${red}Error: There are no '$2' webapp in 'eclipse-workspace/webapps' directory!"
	fi
}

update() {
	eclipse_webapp_count $1 $2 && tomcat_webapp_count $1 $2
	# deploy webapp if there is such, or exit with message if there are no
	if [ $eclipse_webapp_count = "1" ]
	then
		# update webapp if it's deployed, or exit with message if not
		if [ $tomcat_webapp_count = "1" ]
		then
			echo "${green}Process: Updating 'WEB-INF' directory."
			cd $2 && sudo rm -r WEB-INF
			sudo cp -r $from/$2/$resources/WEB-INF ./
			echo "Done: '$2/WEB-INF' directory was updated."
			if [ "$(ls -A $from/$2/$build/classes)" ]
			then	
				sudo mkdir ./WEB-INF/classes
				sudo cp -r $from/$2/$build/classes/* WEB-INF/classes/
				echo "Done: All compiled resources in '$2/WEB-INF/classes' directory were updated."
			else
				echo "${orange}Note: Nothing to copy: there are no compiled resources in 'eclipse-webapps/$2/$build' directory."
			fi
			echo "${green}Done: Webapp was successfully updated."
		else
			echo "${red}Error: Requested webapp is not deployed. Try to deploy it first with '-deploy', '-d' options."
		fi
	else
		echo "${red}Error: There are no '$2' webapp in 'eclipse-workspace/webapps' directory!"	
	fi
}

remove() {
	tomcat_webapp_count $1 $2
	# delete webapp according to if it was found in tomcat7/webapps directory, or not
	if [ $tomcat_webapp_count = "1" ]
	then
		echo "${green}Success: Requested webapp was found in 'tomcat7/webapps' directory."
		sudo rm -r $2
		echo "Done: Requested webapp was successfully removed from 'tomcat7/webapps' directory."
	else
		echo "${red}Error: There are no '$2' webapp in 'tomcat7/webapps' directory!"
	fi
}

if [ ! -z "$1" ] 
then
	if [ ! -z "$2" ]
	then
		case "$1" in
			--deploy|-d) deploy $1 $2;;
			--update|-u) update $1 $2;;
			--remove|-r) remove $1 $2;;
			*) missing_attribute && help;;
		esac
	else
		case "$1" in
			--all|-a) all;;
			--help|-h) echo "${green}\nWEBAPP MANUAL:" && help;;
			*) missing_attribute && help;;
		esac
	fi
else
	missing_attribute && help
fi
