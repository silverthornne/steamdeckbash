#!/bin/bash


############################################################################################################################# moveCacheToSd.sh##
###################                           Code by Antonio Rodrguez Negrn   |   silverthornne                                ################
################### This is a simple script to move the shadercashe and compatdata directories for a specified title from internal storage #####
################### to the micro SD card slot.                                                                                  ################
################### Important: This script needs the game's Steam ID to work. Do not proceed if you do not have the game's Steam ID. ###########
################### Obtain a game's Steam ID in the game's Properties from Steam and going to the Updates pane. The Steam ID is the App ID.#####
################### Do not confuse the Steam ID with the Build ID. They're not the same thing.                                  #################
################### SCRIPT NOT READY FOR PRIME TIME!!!!! STILL NEED TO HANDLE WHEN THE ENTERED ID IS AN EXISTING LINK           ################
## moveCacheToSd.sh ############################################################################################################################


cat << "HEREDOCINTRO"

/---------------------------------------------------------------------------------\
| This shell script will move a game's internal compatibility and shader data to  |
| the micro SD card slot. Steam will continue to access and update those files as |
| if they were located internally. Performance may see a slight hit, but that's   |
| to be expected. Please obtain the game's Steam App ID before proceeding. Do not |
| proceed without the game's Steam App ID. It can be obtained from its properties |
| within the Updates pane. This script does NOT use the Build ID. Use the App ID. |
\---------------------------------------------------------------------------------/

HEREDOCINTRO

## If the locations of the compatibility data and shader cache change in some future update, just update the next two variables to reflect the new location:
sCompatDataPath="/home/deck/.local/share/Steam/steamapps/compatdata/$nSteamId/"
sShaderCachePath="/home/deck/.local/share/Steam/steamapps/shadercache/$nSteamId/"
sNumberRegEx='^[0-9]+$'
bCompatData=0
bShaderCache=0



echo;
## The script proceeds if the Steam ID that's entered is an Integer (non-decimal number).
## The script will enter if any letters or symbols are detected. So typing any letter or symbol will abort it.
echo "----------Please enter the game's Steam ID. The script will exit if you don't enter an Integer.----------"
read -p "-> " nSteamId

if ! [[ $nSteamId =~ $sNumberRegEx ]] ; then
  echo; echo "You entered $nSteamId."
  echo "Error: The Steam ID that you entered isn't valid."
  exit 1
else
  echo; echo "You entered $nSteamId."
  echo "A valid number was entered. Validating directories."
  ## Code that validates whether the paths exist:"
  if [[ -d "$sCompatDataPath" ]]; then
    echo "Directory $sCompatDataPath exists. This title has a compatibility data directory."
    bCompatData=1
  else
    echo "Directory $sCompatDataPath does not exist. This title does not have a compatibility data directory."
  fi
  if [[ -d "$sShaderCachePath" ]]; then
     echo "Directory $sShaderCachePath exists. This title has a shader cache directory."
     bShaderCache=1
  else
    echo "Directory $sShaderCachePath does not exist. This title does not have a shader cache directory."
  fi
fi

echo
echo "======================================================================================================"
echo "------------------------------------------------------------------------------------------------------"
echo "======================================================================================================"
echo

if [[ $bCompatData == 1 && $bShaderCache == 1 ]]; then
  echo "|-This title has compatibility data and shader cache. Both directories will be moved to the microSD card."
  cd "$sCompatDataPath"
  cd ..
  mv $nSteamId /run/media/mmcblk0p1/steamapps/compatdata/
  ln -s /run/media/mmcblk0p1/steamapps/compatdata/$nSteamId $nSteamId
  cd /home/deck/.local/share/Steam/steamapps/compatdata
  echo "Returning the value of the compatibility data symbolic link below:"
  echo
  sTargetCompatDataPath=$(pwd)\/$(ls -lrt | grep -Eo "$nSteamId".*);echo $sTargetCompatDataPath
  echo
  ############
  cd "$sShaderCachePath"
  cd ..
  mv $nSteamId /run/media/mmcblk0p1/steamapps/shadercache/
  ln -s /run/media/mmcblk0p1/steamapps/shadercache/$nSteamId $nSteamId
  cd /home/deck/.local/share/Steam/steamapps/shadercache
  echo "|-Returning the value of the shader cache symbolic link below:"
  echo
  sTargetShaderCachePath=$(pwd)\/$(ls -lrt | grep -Eo "$nSteamId".*);echo $sTargetShaderCachePath
  echo
  exit 0
fi

if [[ $bCompatData == 1 && $bShaderCache == 0 ]]; then
  echo "|-This title has compatibility data but no shader cache. The compatibility data directory will be moved to the microSD card."
  echo
  cd "$sCompatDataPath"
  cd ..
  mv $nSteamId /run/media/mmcblk0p1/steamapps/compatdata/
  ln -s /run/media/mmcblk0p1/steamapps/compatdata/$nSteamId $nSteamId
  cd /home/deck/.local/share/Steam/steamapps/compatdata
  echo "|-Returning the value of the compatibility data symbolic link below:"
  echo
  sTargetCompatDataPath=$(pwd)\/$(ls -lrt | grep -Eo "$nSteamId".*);echo $sTargetCompatDataPath
  echo
  exit 0
fi

if [[ $bCompatData == 0 && $bShaderCache == 1 ]]; then
  echo "|-This title has a shader cache but no compatibility data. The shader cache directory will be moved to the microSD card."
  echo
  cd "$sShaderCachePath"
  cd ..
  mv $nSteamId /run/media/mmcblk0p1/steamapps/shadercache/
  ln -s /run/media/mmcblk0p1/steamapps/shadercache/$nSteamId $nSteamId
  cd /home/deck/.local/share/Steam/steamapps/shadercache
  echo "|-Returning the value of the shader cache symbolic link for below:"
  echo
  sTargetShaderCachePath=$(pwd)\/$(ls -lrt | grep -Eo "$nSteamId".*);echo $sTargetShaderCachePath
  echo
  exit 0
fi
