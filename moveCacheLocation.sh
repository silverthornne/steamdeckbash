#!/bin/bash

################### SCRIPT VERSION: 1.10 - ALMOST FEATURE COMPLETE - STILL DOING QA; ONLY USE AT YOUR OWN RISK!!!  #############################
####################################################################################################################### # moveCacheLocation.sh##
###################                           Code by Antonio Rodriguez Negron   |   silverthornne                               ###############
################### This is a script to move the shadercache and compatdata directories for a specified title to the SD card or back to  #######
################### to the internal storage in a Steam Deck (may work in other SteamOS devices, but I have only tested on Deck!). ##############
################### Important: This script needs the game's Steam ID to work. Do not proceed if you do not have the game's Steam ID. ###########
################### Obtain a game's Steam ID in the game's Properties from Steam and going to the Updates pane. The Steam ID is the App ID.#####
################### Do not confuse the Steam ID with the Build ID. They're not the same thing.                                  ################
###################==============================================================================================================###############
################### Oh YEA! Important stuff:                                                                                    ################
###################                                                                                                             ################
################### This script is provided as-is. No guarantees are written or implied. You may freely use this script but may ################
################### not distribute unless you keep this message in your distribution. Feel free to fork it and modify it for    ################
################### your own use. The reality is that I don't really have the power to stop you from distributing this script   ################
################### and remove this message, but if you do so you will be cursed in such a way that, from the date that you     ################
################### choose to breach this condition, you'll feel an intense craving for Oreo cookies. Every time you sit down   ################
################### to eat them you will get a nice bottle of milk, dunk them in it, and egads!                                 ################
################### NO FILLING ON EVERY THIRD COOKIE! That's your curse! Intense craving for Oreos but every third one will     ################
################### have no filling! You've been warned.                                                                        ################
################### Oh! And I'm not affiliated with Nabisco in any way, shape or form. I just find that curse amusing :)        ################
## moveCacheLocation.sh ########################################################################################################################


cat << "HEREDOCINTRO"

/----------------------------------------------------------------------------------------------------------------------\
| This shell script will move a game's internal compatibility and pre-cached shader data to the microSD card slot or   |
| back to internal storage. Steam will continue to access and update those files as if they were located internally.   |
| Performance may see a slight decline when moving to the microSD card based on card storage access speed limitations. |
| A2 Cards are recommended for best performance.                                                                       |
| Please obtain the game's Steam App ID before running this script. Do not proceed without the game's Steam App ID. It |
| can be obtained from the Updates pane within its Properties window. Do not confuse the App ID with the Build ID;     |
| they're different. The Build ID will NOT work.                                                                       |
| =====================================================================================================================|
| This script works best on games that were directly installed to microSD card. If the game was initially installed to |
| internal storage and moved to microSD card later via Steam's "Move install folder..." option, Valve has already      |
| created a compatibility data directory on the microSD card for it. However, Valve has NOT created a pre-cached shader|
| data directory on the microSD card for it. In that case, the right thing to do is to skip the option to move the     |
| compatibility data files, and only move the pre-cached shader files to the microSD card. This behavior may change in |
| later SteamOS updates, so please keep that in mind.                                                                  |
\----------------------------------------------------------------------------------------------------------------------/

HEREDOCINTRO

##### From my understanding, SteamDecks mount the Micro SD card in the following path. Change it if your MicroSD card has a different mounting point.
sCardPath="/run/media/mmcblk0p1"
##### If the locations of the compatibility data and shader cache change in some future SteamOS update, just update these *Root variables to reflect the new location:
sLocalCompatDataRoot="/home/deck/.local/share/Steam/steamapps/compatdata"
sLocalShaderCacheRoot="/home/deck/.local/share/Steam/steamapps/shadercache"
sCardCompatDataRoot="$sCardPath/steamapps/compatdata"
sCardShaderCacheRoot="$sCardPath/steamapps/shadercache"
#######################################################################################################################
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
echo "===================This script is provided as-is, with no warranties written or implied.==================="; echo
echo "The worst that could happen after running it is that you may have to manually move some files around if it fails."; echo
echo "I have performed numerous tests to make sure that it works as expected, but there may be a critter or two lurking about that I haven't caught."; echo
echo "=========================With all of that out of the way, do you wish to proceed?=========================="; echo

select yn in "Yes" "No"; do
  case $yn in
    Yes )
      echo
      echo "Once more unto the breach, dear friends!"
      echo
      break;;
    No )
      echo
      echo "Goodbye!"
      exit 0
      break;;
  esac
done

## The script proceeds if the Steam ID that's entered is an Integer (non-decimal number).
## The script will enter if any letters or symbols are detected. So typing any letter or symbol will abort it.
echo "----------Please enter the game's Steam ID App ID. The script will exit if you don't enter a Steam App ID.----------"
read -p "-> " nSteamId

sLocalCompatDataPath="$sLocalCompatDataRoot/$nSteamId"
sLocalShaderCachePath="$sLocalShaderCacheRoot/$nSteamId"
sCardCompatDataPath="$sCardCompatDataRoot/$nSteamId"
sCardShaderCachePath="$sCardShaderCacheRoot/$nSteamId"


if ! [[ $nSteamId =~ $sNumberRegEx ]] ; then
  echo; echo "You entered App ID $nSteamId."
  echo "Unable to proceed because the App ID that you entered isn't valid. Please verify the title's App ID and try again."
  exit 1
else
  echo; echo "You entered $nSteamId."
  echo "A valid number that may be a Steam ID for software in this system was entered. Validating directories."
  ## Code that validates whether the internal compatibility data path exists:"
  if [[ -h "$sLocalCompatDataPath" ]]; then
         ###### --------Handling when the data has already been moved to micro SD card.
         echo
         echo "The compatibility data for App ID $nSteamId has already been moved to a micro SD card."
         ############ Code to verify if the files are located in the current micro SD card and to ask to move them to internal storage goes here:
         sleep 1s
         echo "Do you want to move the compatibility data back to internal storage if it is present in the micro SD card currently located in the Micro SD card slot?"
         sleep 1s
         echo
         select yn in "Yes" "No"; do
           case $yn in
             Yes ) ## This path will move the compatibility data directory back to internal storage if it exists: ## Needs a bug check.
               echo
               if [[ -d "$sCardCompatDataPath" ]]; then
                 echo "Verifying size of compatibility data on Micro SD card and available Internal Storage space."
                 nCount=0
                 while [[ $nCount -lt 5 ]]; do
                   printf .
                   sleep 1s
                   ((nCount++))
                 done
                 nInternalFreeAbsolute=$(df | grep "/home" | awk '{print $4}')
                 nCompatDataSize=$(du "$sCardCompatDataPath" -d 0 | cut -f1)
                 if [[ $nInternalFreeAbsolute -gt $nCompatDataSize ]]; then
                   echo
                   echo "Moving compatibility data back from Micro SD to Internal Storage!"
                   echo
                   nCount=0
                   while [[ $nCount -lt 5 ]]; do
                     printf .
                     sleep 1s
                     ((nCount++))
                   done
                   echo
                   cd $sLocalCompatDataRoot
                   /usr/bin/unlink $nSteamId
                   cd $sCardCompatDataRoot
                   /usr/bin/mv $nSteamId "$sLocalCompatDataRoot"
                   echo "Returning the value of the new compatibility data directory below:"
                   cd $sLocalCompatDataRoot
                   sTargetCompatDataPath=$(/usr/bin/pwd)\/$(ls -lrt | grep -Eo "$nSteamId".*)
                   echo "$sTargetCompatDataPath"
                   echo
                   sleep 3s
                   nInternalFreeReadable=$(df -h | grep -n "/home" | awk '{print $4}')
                   echo "Internal storage has $nInternalFreeReadable available after moving the selected compatibility files back to it."
                 else
                   nInternalFreeReadable=$(df -h | grep -n "/home" | awk '{print $4}')
                   nCompatDataSizeReadable=$(du -h "$sCardCompatDataPath" -d 0 | cut -f1)
                   echo
                   echo "Internal storage only has $nInternalFreeReadable space left."
                   echo "The compatibility data directory requires $nCompatDatasizeReadable of space available."
                   echo "That's not enough space to move the selected compatibility data from Micro SD card back to Internal Storage."
                   echo
                 fi
                else
                 echo "Warning: The current MicroSD card does not contain this title's compatibility data. No data to move back."
                 exit 0
               fi
             break;;
            No ) ## This path will not move the compatibility data directory back to internal storage
               echo
               echo "Compatibility data won't be moved to Internal Storage as selected. Moving on."
               sleep 3s
               break;;
           esac
         done
  elif [[ -d "$sLocalCompatDataPath" ]]; then
          echo
          echo "There is an internal storage compatibility data directory for App ID $nSteamId."
          echo "A symbolic link will be created to maintain compatibility after moving the compatibility data directory."
          echo "Do you wish to proceed?"
          sleep 1s
          echo
          select yn in "Yes" "No"; do
              case $yn in
                  Yes ) ## This path will move the compatibility data directory to micro SD card. Checking space on card first.
                  echo;echo "Verifying available space on Micro SD card and size of compatibility data directory."
                  nCount=0
                  while [[ $nCount -lt 5 ]]; do
                    printf .
                    sleep 1s
                    ((nCount++))
                  done
                  nCardFreeAbsolute=$(df | grep "$sCardPath" | awk '{print $4}')
                  nCompatDataSize=$(du "$sLocalCompatDataPath" -d 0 | cut -f1)
                  if [[ $nCardFreeAbsolute -gt $nCompatDataSize ]]; then
                      echo;echo "Moving compatibility data directory to micro SD card, please wait."
                      echo "Do not, under any circumstance, remove the micro SD card while this operation runs."
                      echo
                      nCount=0
                      while [[ $nCount -lt 5 ]]; do
                        printf .
                        sleep 1s
                        ((nCount++))
                      done
                      echo
                      cd "$sLocalCompatDataRoot"
                      /usr/bin/mv $nSteamId "$sCardCompatDataRoot"
                      sCardCompatDataPath="$sCardCompatDataRoot/$nSteamId"
                      /usr/bin/ln -s "$sCardCompatDataPath" $nSteamId
                      cd "$sLocalCompatDataRoot"
                      echo
                      echo "Returning the value of the resulting compatibility data symbolic link below:"
                      echo
                      sTargetCompatDataPath=$(/usr/bin/pwd)\/$(ls -lrt | grep -Eo "$nSteamId".*)
                      echo "$sTargetCompatDataPath"
                      echo
                      sleep 3s
                      nCardFreeReadable=$(df -h | grep -n "$sCardPath" | awk '{print $4}')
                      echo "Micro SD card has $nCardFreeReadable storage space left after moving compatibility data to it."
                  else
                    nCardFreeReadable=$(df -h | grep -n "$sCardPath" | awk '{print $4}')
                    nCompatDataSizeReadable=$(du -h "$sLocalCompatDataPath" -d 0 | cut -f1)
                    echo
                    echo "There is not enough free space on the Micro SD card to move the compatibility data directory to it."
                    echo "The Micro SD card needs $nCompatDataSizeReadable free, but it only has $nCardFreeReadable available."
                    echo
                fi
                 break;;
                  No ) ## This path will not move compatibility files and move on to the shader cache files.
                    echo
                    echo "Compatibility data won't be moved to micro SD card. Moving on."
                    nCount=0
                    while [[ $nCount -lt 5 ]]; do
                      printf .
                      sleep 1s
                      ((nCount++))
                    done
                  break;;
              esac
          done
  else
    echo
    echo "There is no compatibility data directory for App ID $nSteamId."
    echo "Do you wish to create one now on the MicroSD card and create a link for it on the Internal Storage?"
    select yn in "Yes" "No"; do
      case $yn in
         Yes ) ## This path will create the directory in the microSD card and then create the link. No data will be moved (it doesn't exist)
           echo
           echo "Creating compatibility data directory on MicroSD card for AppID $nSteamId."
           nCount=0
           while [[ $nCount -lt 3 ]]; do
            printf .
            sleep 1s
            ((nCount++))
           done
           cd $sCardCompatDataRoot
           /usr/bin/mkdir $nSteamId
           sCardCompatDataPath="$sCardCompatDataRoot/$nSteamId"
           cd $sLocalCompatDataRoot
           echo
           echo "Creating symbolic link for MicroSD card compatibility directory on Internal Storage."
           /usr/bin/ln -s "$sCardCompatDataPath" $nSteamId
           echo
           echo "Returning the value of the resulting compatibility data symbolic link below:"
           echo
           sTargetCompatDataPath=$(/usr/bin/pwd)\/$(ls -lrt | grep -Eo "$nSteamId".*)
           echo "$sTargetCompatDataPath"
           echo
           break;;
         No ) ## This path won't create the link
           echo "Compatibility data directory will not be created on MicroSD card for Steam App ID $nSteamId."
           echo "No symbolic link will be created on internal storage for compatibility data either."
           break;;
      esac
    done
    echo "Moving on to verify for shader cache files."
    sleep 3s
    echo
  fi
  ############ Done with Compatibility Data.
  ############ Shader Cache from this line on.
  ############ Creepy crawlies are sure to be around.
  ############ LET'S DO THEEEEEEZZZZZZ
  if [[ -h "$sLocalShaderCachePath" ]]; then
    ## Code that validates whether the internal shader cache data path exists:"
    echo
    ###### --------Handling when the data has already been moved to micro SD card.
    echo "The shader cache for App ID $nSteamId has already been moved to a micro SD card."
    ############ Code to verify if the files are located in the current micro SD card and to ask to move them to internal storage goes here:
    sleep 1s
    echo "Do you want to move the shader cache back to internal storage if it is present in the micro SD card currently located in the micro SD card slot?"
    select yn in "Yes" "No"; do
      case $yn in
        Yes ) ## This path will move the shader cache directory to internal storage if it is present: ## Needs a bug check.
          if [[ -d "$sCardShaderCachePath" ]]; then
            echo
            echo "Verifying size of shader cache data on Micro SD card and available Internal Storage space."
            nCount=0
            while [[ $nCount -lt 5 ]]; do
              printf .
              sleep 1s
              ((nCount++))
            done
            nInternalFreeAbsolute=$(df | grep "/home" | awk '{print $4}')
            nShaderCacheSize=$(du $sCardShaderCachePath -d 0 | cut -f1)
            if [[ $nInternalFreeAbsolute -gt $nShaderCacheSize ]]; then
              echo
              echo "Moving shader cache data from Micro SD card back to Internal Storage!"
              echo
              nCount=0
              while [[ $nCount -lt 5 ]]; do
                printf .
                sleep 1s
                ((nCount++))
              done
              cd "$sLocalShaderCacheRoot"
              /usr/bin/unlink $nSteamId
              cd "$sCardShaderCacheRoot"
              /usr/bin/mv $nSteamId "$sLocalShaderCacheRoot"
              echo
              echo "Returning the value of the new shader cache directory below:"
              cd "$sLocalShaderCacheRoot"
              sTargetShaderCachePath=$(/usr/bin/pwd)\/$(ls -lrt | grep -Eo "$nSteamId".*)
              echo "$sTargetShaderCachePath"
              echo
              sleep 3s
              nInternalFreeReadable=$(df -h | grep -n "/home" | awk '{print $4}')
              echo "Internal storage has $nInternalFreeReadable available after moving the selected shader cache files back to it."
              exit 0
            else
              nInternalFreeReadable=$(df -h | grep -n "/home" | awk '{print $4}')
              nShaderCacheSizeReadable=$(du -h "$sCardShaderCachePath" -d 0 | cut -f1)
              echo
              echo "Internal storage only has $nInternalFreeReadable space left."
              echo "The shader cache data directory requires $nShaderCacheSizeReadable of space available."
              echo "That's not enough space to move the selected shader cache data from the Micro SD card back to Internal Storage."
              echo
              exit 0
            fi
          else
            echo "Warning: The current MicroSD card does not contain this title's shader pre-cache data. No data to move back."
            exit 1
          fi
          break;;
        No ) ## This path will not move the shader cache directory to internal storage.
          echo
          echo "Shader cache data won't be moved to Internal Storage as selected. Exiting script."
          exit 0
          break;;
      esac
    done
  elif [[ -d "$sLocalShaderCachePath" ]]; then
    echo
    echo "There is an internal storage shader cache directory for App ID $nSteamId."
    echo "A symbolic link will be created to maintain compatibility after moving the shader cache directory."
    echo "Do you wish to proceed?"
    select yn in "Yes" "No"; do
      case $yn in
        Yes ) ## This path will move the shader cache directory to micro SD card:
          #### Need to add check for storage space
          echo
          echo "Verifying available space on Micro SD card and size of shader cache directory."
          nCount=0
          while [[ $nCount -lt 5 ]]; do
            printf .
            sleep 1s
            ((nCount++))
          done
          nCardFreeAbsolute=$(df | grep "$sCardPath" | awk '{print $4}')
          nShaderCacheSize=$(du $sLocalShaderCachePath -d 0 | cut -f1)
          if [[ $nCardFreeAbsolute -gt $nShaderCacheSize ]]; then
            echo
            echo "Moving shader cache directory to micro SD card, please wait."
            echo "Do not, under any circumstance, remove the micro SD card while this operation runs."
            echo
            nCount=0
            while [[ $nCount -lt 5 ]]; do
              printf .
              sleep 1s
              ((nCount++))
            done
            cd "$sLocalShaderCacheRoot"
            /usr/bin/mv $nSteamId "$sCardShaderCacheRoot"
            sCardShaderCachePath="$sCardShaderCacheRoot/$nSteamId"
            /usr/bin/ln -s "$sCardShaderCachePath" $nSteamId
            cd "$sLocalShaderCacheRoot"
            echo "Returning the value of the shader cache symbolic link below:"
            echo
            sTargetShaderCachePath=$(/usr/bin/pwd)\/$(ls -lrt | grep -Eo "$nSteamId".*)
            echo "$sTargetShaderCachePath"
            echo
            sleep 3s
            nCardFreeReadable=$(df -h | grep -n "$sCardPath" | awk '{print $4}')
            echo "Micro SD card has $nCardFreeReadable storage space left after moving shader cache to it."
            exit 0
          else
            nCardFreeReadable=$(df -h | grep -n "$sCardPath" | awk '{print $4}')
            nShaderCacheSizeReadable=$(du -h $sLocalShaderCachePath -d 0 | cut -f1)
            echo
            echo "There is not enough free space on the Micro SD card to move the shader cache directory to it."
            echo "The Micro SD card needs $nShaderCacheSizeReadable free, but it only has $nCardFreeReadable available."
            echo
          fi
          break;;
        No ) ## This path will not move the shader cache files and the script will exit.
          echo
          echo "Shader cache files won't be moved to micro SD card. Exiting script."
          exit 0
          break;;
      esac
    done
  else
    echo
    echo "No shader cache files found on for App ID $nSteamId."
    echo "Do you wish to create one now on the MicroSD card and create a link for it on the Internal Storage?"
    select yn in "Yes" "No"; do
      case $yn in
        Yes ) ## This path will create the directory in the MicroSD card and then create the link. No data will be moved (it doesn't exist)
          echo "Creating pre-cached shader data directory on MicroSD card for AppID $nSteamId."
          nCount=0
          while [[ $nCount -lt 3 ]]; do
            printf .
            sleep 1s
            ((nCount++))
          done
          cd $sCardShaderCacheRoot
          /usr/bin/mkdir $nSteamId
          sCardShaderCachePath="$sCardShaderCacheRoot/$nSteamId"
          cd $sCardShaderCacheRoot
          echo
          echo "Creating symbolic link for MicroSD card pre-cached shader data directory on Internal Storage."
          /usr/bin/ln -s "$sCardShaderCachePath" $nSteamId
          echo
          echo "Returning the value of the resulting pre-cached shader data symbolic link below:"
          echo
          sTargetShaderCachePath=$(/usr/bin/pwd)\/$(ls -lrt | grep -Eo "$nSteamId".*)
          echo "$sTargetShaderCachePath"
          echo
          break;;
        No ) ## This path won't create the link.
          echo "Pre-cached shader directory will not be created on MicroSD card for AppID $nSteamId."
          echo "No symbolic link will be created on internal storage for pre-cached shaders."
          break;;
      esac
    done
   fi
fi
exit 0