#!/bin/bash -ex
REPOSITORY=''
SVN_USER=''
SVN_PASSWD=''
WORKING_DIRECTORY=''
REVISION_FROM=''
REVISION_TO='HEAD'
FTP_HOST=''
FTP_USER=''
FTP_PASSWD=''
FTP_ROOT_DIR=''
REN_DIRECTORY_CMD=''
REN_FILE_CMD=''
GOT_UPDATED_FILES=0
SVN_STATUS=''


function ParametersPrinter
{
	MessageLogger $REPOSITORY "Repository"
	MessageLogger $FTP_HOST "Ftp Host"
	MessageLogger $FTP_USER "FTP User"
	MessageLogger $FTP_PASSWD "FTP Password"
	MessageLogger $FTP_ROOT_DIR "FTP Root Directory"
}
function MessageLogger
{
	if [[ $2 ]]; then
		echo $(date +%d-%m-%Y_%T) ": $2 : ${FUNCNAME[1]} : $1"
	else
		echo $(date +%d-%m-%Y_%T) ": ${FUNCNAME[1]} : $1"
	fi
}
function DoesDirectoryExists
{
	if [[ -d $1 ]]; then
		MessageLogger "Found directory $1"
		return 0
	else
		MessageLogger "Directory $1 does not exists" "ERROR"
		return 1
	fi
}
function SyncFiles
{
	MessageLogger "Sync Started"
	#; set ftp:list-options -a ; set mirror:use-pget-n 2 ; set ssl:verify-certificate no
	lftp -e "$FTP_ARGS  mirror --verbose=3 --delete --parallel=10 -x .svn/ -x wpcf7_captcha/ --only-newer $FTP_ROOT_DIR/ $WORKING_DIRECTORY ; bye ; " -u$FTP_USER,$FTP_PASSWD $FTP_HOST 
        #if lftp -e "set ssl:verify-certificate no ; set ftp:list-options -a ; mirror --verbose=3 --delete --parallel=10 -x .svn/ -x wpcf7_captcha/ --only-newer $FTP_ROOT_DIR/ $WORKING_DIRECTORY ; bye ; " -u$FTP_USER,$FTP_PASSWD $FTP_HOST ;  ERR=$? ;  then
	#		if [ $ERR -ne 0 ]; then
	#			MessageLogger "Error Occured.. See Log" "Error"
	#		else
	#			MessageLogger "Files Transfered Sucessfully"
	#		fi
	#	fi
	MessageLogger " Sync Finished"
}
function CheckoutSVN
{
	MessageLogger "Checking Out Files from SVN"
	svn checkout --username=$SVN_USER --password=$SVN_PASSWD --non-interactive $REPOSITORY $WORKING_DIRECTORY/
}
function CommitChanges
{
	MessageLogger "Started Commiting"
	svn add * --force
	svn commit --username=$SVN_USER --password=$SVN_PASSWD --non-interactive --message "$COMMIT_MESSAGE :: Auto Sync with Server $(date +%d-%m-%Y_%T)" $WORKING_DIRECTORY/
	MessageLogger " Finished Commiting"
}
function UpdateWorkingCopy
{
	MessageLogger "Updating Working Copy"
	svn update  --username=$SVN_USER --password=$SVN_PASSWD --non-interactive  $WORKING_DIRECTORY/
}
function RevertAllChanges
{
	svn revert $WORKING_DIRECTORY/ -R
}

if  DoesDirectoryExists $WORKING_DIRECTORY ; then
	ParametersPrinter
	if  ! DoesDirectoryExists ".svn"  ; then
		CheckoutSVN
	fi
	RevertAllChanges
	UpdateWorkingCopy
	SyncFiles
	CommitChanges
fi
