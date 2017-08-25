# /=======================================================================
# /=
# /=  Create_Password_File.ps1
# /=
# /=  AUTHOR: Jake Bentz
# /=  DATE:	08/25/2017
# /=
# /=  REQUIREMENTS: N/A
# /=
# /=  DESCRIPTION: This script creates an encrypted password file
# /=  Twitter: @TripDeezil
# /=
# /=  REVISION HISTORY
# /=   VER  DATE        AUTHOR/EDITOR   COMMENT
# /=   1.0  08/25/2017  Jake Bentz      Created script
# /=
# /=======================================================================#
#
#Set variable for password file
$passwordFile = ".\OSPwd.txt"
#
# First time create password file
Read-Host "Enter password" -AsSecureString | convertfrom-securestring | out-file $passwordFile
