#!/bin/bash

################### SCRIPT VERSION: 0.70 - NOT READY YET; JUST COMMITTING TO HAVE IT BACKED UP TO GITHUB - DO NOT USE YET ######################
####################################################################################################################### # moveCacheLocation.sh##
###################                           Code by Antonio Rodriguez Negron   |   silverthornne                               ###############
################### This is a script to move the shadercache and compatdata directories for a specified title to the SD card or back to  #######
################### to the internal storage in a Steam Deck (may work in other SteamOS devices, but I have only tested on Deck!). ##############
################### Important: This script needs the game's Steam ID to work. Do not proceed if you do not have the game's Steam ID. ###########
################### Obtain a game's Steam ID in the game's Properties from Steam and going to the Updates pane. The Steam ID is the App ID.#####
################### Do not confuse the Steam ID with the Build ID. They're not the same thing.                                  ################
## moveCacheLocation.sh ########################################################################################################################


cat << "HEREDOCINTRO"

/---------------------------------------------------------------------------------\
| This shell script will move a game's internal compatibility and shader data     |
| to the micro SD card slot or back to internal storage. Steam will continue to   |
| access and update those files as if they were located internally. Performance   |
| may see a slight hit when moving to the micro SD card based on SD card storage  |
| access speed limitations. Please obtain the game's Steam App ID before running  |
| this script. Do not proceed without the game's Steam App ID. It can be obtained |
| from the Updates pane within its Properties window. Do not confuse the App ID   |
| with the Build ID; they're different. The Build ID will NOT work.               |
\---------------------------------------------------------------------------------/

HEREDOCINTRO

##### From my understanding, SteamDecks mount the Micro SD card in the following path. Change it if your MicroSD card has a different mounting point.
sCardPath="/run/media/mmcblk0p1"
##### If the locations of the compatibility data and shader cache change in some future SteamOS update, just update these *Root variables to reflect the new location:
sLocalCompatDataRoot="/home/deck/.local/share/Steam/steamapps/compatdata/"
sLocalShaderCacheRoot="/home/deck/.local/share/Steam/steamapps/shadercache/"
sCardCompatDataRoot="$sCardPath/steamapps/compatdata/"
sCardShaderCacheRoot="$sCardPath/steamapps/shadercache/"
#######################################################################################################################
sLocalCompatDataPath="$sLocalCompatDataRoot/$nSteamId/"
sLocalShaderCachePath="$sLocalShaderCacheRoot/$nSteamId/"
sCardCompatDataPath=/"$sCardCompatDataRoot/$nSteamId"
sCardShaderCachePath="$sCardCompatDataRoot/$nSteamId"
nInternalFreeAbsolute=$(df | grep "/home" | awk '{print $4}')
nInternalFreeReadable=$(df -h | grep -n "/home" | awk '{print $4}')
nCardFreeAbsolute=$(df | grep "$sCardPath" | awk '{print $4}')
nCardFreeReadable=$(df -h | grep -n "$sCardPath" | awk '{print $4}')
nLine=0
nCompatDataSize=0
nCompatDataSizeReadable=0
nShaderCacheSize=0
nShaderCacheSizeReadable=0
sNumberRegEx='^[0-9]+$'


echo;
## The script proceeds if the Steam ID that's entered is an Integer (non-decimal number).
## The script will enter if any letters or symbols are detected. So typing any letter or symbol will abort it.
echo "----------Please enter the game's Steam ID App ID. The script will exit if you don't enter a Steam App ID.----------"
read -p "-> " nSteamId

if ! [[ $nSteamId =~ $sNumberRegEx ]] ; then
  echo; echo "You entered App ID $nSteamId."
  echo "Unable to proceed because the App ID that you entered isn't valid. Please verify the title's App ID and try again."
  exit 1
else
  echo; echo "You entered $nSteamId."
  echo "A valid number that may be a Steam ID for software in this system was entered. Validating directories."
  ## Code that validates whether the internal compatibility data path exists:"
  if [[ -d "$sLocalCompatDataPath" ]]; then
    echo "There is an internal storage compatibility data directory for App ID $nSteamId."
    echo "A symbolic link will be created to maintain compatibility after moving the compatibility data directory."
    echo "Do you wish to proceed?"
    sleep 1s
    echo
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) ## This path will move the compatibility data directory to micro SD card. Checking space on card first.
            echo "Verifying available space on Micro SD card and size of compatibility data directory."
            nCount=0
              while [[ $nCount -lt 10 ]]; do
              printf .
              sleep 1s
              ((nCount++))
            done
            nCardFreeAbsolute=$(df | grep "$sCardPath" | awk '{print $4}')
            nCompatDataSize=$(du $sLocalCompatDataPath -d 0 | cut -f1)
            if [[ $nCardFreeAbsolute -gt $nCompatDataSize ]]; then
                echo "Moving compatibility data directory to micro SD card, please wait."
                echo "Do not, under any circumstance, remove the micro SD card while running this script."
                echo
                nCount=0
                while [[ $nCount -lt 10 ]]; do
                  printf .
                  sleep 1s
                  ((nCount++))
                done
                echo
                cd "$sLocalCompatDataRoot"
                mv $nSteamId $sCardCompatDataRoot
                ln -s "$sCardCompatDataPath" $nSteamId
                cd "$sLocalCompatDataRoot"
                echo "Returning the value of the resulting compatibility data symbolic link below:"
                echo
                sTargetCompatDataPath=$(pwd)\/$(ls -lrt | grep -Eo "$nSteamId".*)
                echo $sTargetCompatDataPath
                echo
                sleep 3s
                nCardFreeReadable=$(df -h | grep -n "$sCardPath" | awk '{print $4}')
                echo "Micro SD card has $nCardFreeReadable storage space left after moving compatibility data to it."
            else
              nCardFreeReadable=$(df -h | grep -n "$sCardPath" | awk '{print $4}')
              nCompatDataSizeReadable=$(du -h $sLocalCompatDataPath -d 0 | cut -f1)
              echo "There is not enough free space on the Micro SD card to move the compatibility data directory to it."
              echo "The Micro SD card needs $nCompatDataSizeReadable free, but it only has $nCardFreeReadable available."
              echo
          fi
           break;;
            No ) ## This path will not move compatibility files and move on to the shader cache files.
              echo "Compatibility data won't be moved to micro SD card. Moving on."
              sleep 3s
            break;;
        esac
    done
  elif [[ -L "$sLocalCompatDataPath" ]]; then
    ###### --------Handling when the data has already been moved to micro SD card.
    echo "The compatibility data for App ID $nSteamId has already been moved to a micro SD card."
    ############ Code to verify if the files are located in the current micro SD card and to ask to move them to internal storage goes here:
    sleep 1s
    echo "Do you want to move the compatibility data back to internal storage if it is present in the micro SD card currently located in the Micro SD card slot?"
    sleep 1s
    echo
    select yn in "Yes" "No"; do
      case $yn in
        Yes ) ## This path will move the compatibility data directory back to internal storage if it exists: ## Needs a bug check.
          if [[ -d "sCardCompatDataPath" ]]; then
            echo "Verifying size of compatibility data on Micro SD card and available Internal Storage space."
            nCount=0
            while [[ $nCount -lt 10 ]]; do
              printf .
              sleep 1s
              ((nCount++))
            done
            nInternalFreeAbsolute=$(df | grep "/home" | awk '{print $4}')
            nCompatDataSize=$(du $sCardCompatDataPath -d 0 | cut -f1)
            if [[ $nInternalFreeAbsolute -gt $nCompatDataSize ]]; then
              echo "Moving compatibility data from Micro SD to Internal Storage!"
              echo
              nCount=0
              while [[ $nCount -lt 10 ]]; do
                printf .
                sleep 1s
                ((nCount++))
              done
              echo
              cd $sLocalCompatDataRoot
              rm $nSteamId
              cd $sCardCompatDataRoot
              mv $nSteamId $sLocalCompatDataRoot
              echo "Returning the value of the new compatibility data directory below:"
              cd $sLocalCompatDataRoot
              sTargetCompatDataPath=$(pwd)\/$(ls -lrt | grep -Eo "$nSteamId".*)
              echo $sTargetCompatDataPath
              echo
              sleep 3s
              nInternalFreeReadable=$(df -h | grep -n "/home" | awk '{print $4}')
              echo "Internal storage has $nInternalFreeReadable available after moving the selected compatibility files."
            else
              nInternalFreeReadable=$(df -h | grep -n "/home" | awk '{print $4}')
              nCompatDataSizeReadable=$(du -h "$sCardCompatDataPath" -d 0 | cut -f1)
              echo "Internal storage only has $nInternalFreeReadable storage left."
              echo "The compatibility data directory requires $nCompatDatasizeReadable available."
              echo "That's not enough space to move the selected compatibility data from Micro SD card to Internal Storage."
              echo
            fi
          fi
        break;;
       No ) ## This path will not move the compatibility data directory back to internal storage
          echo "Compatibility data won't be moved to Internal Storage as selected. Moving on."
          sleep 3s
          break;;
      esac
    done
  else
    echo "There is no compatibility data directory for App ID $nSteamId."
    echo "Moving on to verify for shader cache files."
    sleep 3s
    echo
  fi
  ############ Done with Compatibility Data.
  ############ Shader Cache from this line on.
  ############ Creepy crawlies are sure to be around.
  ############ LET'S DO THEEEEEEZZZZZZ
  if [[ -d "$sLocalShaderCachePath" ]]; then
    ## Code that validates whether the internal shader cache data path exists:"
    echo "There is an internal storage shader cache directory for App ID $nSteamId."
    echo "A symbolic link will be created to maintain compatibility after moving the shader cache directory."
    echo "Do you wish to proceed?"
    select yn in "Yes" "No"; do
      case $yn in
        Yes ) ## This path will move the shader cache directory to micro SD card:
          #### Need to add check for storage space
          nLine=$(df | grep -n "$sCardPath" | grep -Eo '[0-9].*:'| grep -Eo [0-9].)
          nCardFreeAbsolute=$(df | grep "$sCardPath" | awk '{print $4}')
          nShaderCacheSize=$(du $sLocalShaderCachePath -d 0 | cut -f1)
          if [[ $nCardFreeAbsolute -gt $nShaderCacheSize ]]; then
            echo "Moving shader cache directory to micro SD card!"
            echo
            nCount=0
            while [[ $ncount -lt 10 ]]; do
              printf .
              sleep 1s
              ((nCount++))
            done
            echo
            cd "$sLocalShaderCacheRoot"
            mv $nSteamId $sCardShaderCacheRoot
            ln -s "$sCardShaderCachePath" $nSteamId
            cd "$sLocalShaderCacheRoot"
            echo "Returning the value of the shader cache symbolic link below:"
            echo
            sTargetShaderCachePath=$(pwd)\/$(ls -lrt | grep -Eo "$nSteamId".*)
            echo $sTargetShaderCachePath
            echo
            sleep 3s
            nCardFreeReadable=$(df -h | grep -n "$sCardPath" | cut -d " " -f7)
            echo "Micro SD card has $nCardFreeReadable storage space left."
        else
           nCardFreeReadable=$(df | awk 'NR=='"$nLine"' {print $4}')
           nShaderCacheSizeReadable=$(du -h $sLocalShaderCachePath -d 0 | cut -f1)
           echo "There is not enough free space on the Micro SD card to move the compatibility data directory to it."
           echo "The Micro SD card needs $nShaderCacheSizeReadable free, but it only has $nCardFreeReadable available."
           echo
        fi
          break;;
        No ) ## This path will not move the shader cache files and the script will exit.
          echo "Shader cache files won't be moved to micro SD card. Exiting script."
          sleep 3s
          break;;
      esac
    done
  elif [[ -L "$sLocalShaderCachePath" ]]; then
    ###### --------Handling when the data has already been moved to micro SD card.
    echo "The shader cache for App ID $nSteamId has already been moved to a micro SD card."
    ############ Code to verify if the files are located in the current micro SD card and to ask to move them to internal storage goes here:
    sleep 1s
    echo "Do you want to move the shader cache back to internal storage if it is present in the micro SD card currently located in the micro SD card slot?"
    select yn in "Yes" "No"; do
      case $yn in
        Yes ) ## This path will move the shader cache directory to internal storage if it is present: ## Needs a bug check.






        break;;
        No ) ## This path will not move the shader cache directory to internal storage.






     esac
   done
  else
    echo "No shader cache files found on for App ID $nSteamId. Nothing to do."
    exit 0
  fi
fi

exit 0