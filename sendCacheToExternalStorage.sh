#!/bin/bash

########################################## SCRIPT VERSION: 0.90 - DO NOT UES YET - WIP!!!! #####################################################
################################################################################################################ sendCacheToExternalStorage.sh##
###################                                                                                                              ###############
###################----------------------------------------------WORK IN PROGRESS------------------------------------------------###############
###################-------------------------------------------NOT READY FOR PRIME TIME-------------------------------------------###############
###################                                                                                                              ###############
###################                           Code by Antonio Rodriguez Negron   |   silverthornne                               ###############
################### This is a script to move the shadercache and compatdata directories for a specified title to any external storage  #########
################### from the internal storage in a Steam Deck (may work in other SteamOS devices, but I have only tested on Deck!).   ##########
################### Unlike the moveCacheLocation script, you don't need the game's Steam ID for it to work.                       ##############
################### This script may also replace the transferCacheToSDCard script as you can choose the SD card from it. It does ###############
################### add that extra step of choosing though. If you don't use an external storage such as a USB drive, it will be ###############
################### easier to use the transferCacheToSDCard script as you won't have to make a selection at first.               ###############
###################=============================================================================================================################
###################                                                                                                             ################
###################                                       IMPORTANT DISCLAIMER!!!                                               ################
###################                                                                                                             ################
################### Personally, I don't use external storage with my Deck, and I don't own one of those docks that allow the    ################
################### use of an M2 drive. That means that I am not able to actually test this script on that kind of product.     ################
################### I am hoping that this script can be tested with community help through Github so that I can confidently     ################
################### upgrade it to a "1.0" version. All I can do is test the SD card implementation after all.                   ################
###################                                                                                                             ################
###################=============================================================================================================################
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
## sendCacheToExternalStorage.sh ###############################################################################################################


cat << "HEREDOCINTRO"

/----------------------------------------------------------------------------------------------------------------------\
|                                                                                                                      |
| !!!!!!!!!!!!!!!!!!!!!!!!!!!! STOP AND CTRL-C OUT OF THIS SCRIPT RIGHT NOW !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! |
|                                                                                                                      |
| This shell script will move a game's internal compatibility and pre-cached shader data to the chosen mounted store   |
| or back to internal storage. Steam will access and update those files as if they were on internal storage.           |
| Performance may see a slight decline, depending on the storage specs, its access speed, and other limitations.       |
|======================================================================================================================|
| This script can be used in lieu of the transferCacheToSDCard script if you choose the mount location of the SD card  |
| from the menu list. If you only mean to transfer to SD card and don't use external storage at all, you should stick  |
| to the transferCacheToSDCard script though. Less steps, and less confusing if you don't use external storage.        |
|                                                                                                                      |
| !!!!!!!!!!!!!!!!!!!!!!!!!! PLEASE CHECK THE README.MD FILE OUT FOR MORE INFO !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! |
|                                                                                                                      |
\----------------------------------------------------------------------------------------------------------------------/

HEREDOCINTRO

##### From my understanding, SteamDecks mount the Micro SD card in the following path. Change it if your MicroSD card has a different mounting point.
sCardPath="/run/media/mmcblk0p1"
##### If the locations of the compatibility data and shader cache change in some future SteamOS update, just update these *Root variables to reflect the new location:
sLocalCompatDataRoot="/home/deck/.local/share/Steam/steamapps/compatdata"
sLocalShaderCacheRoot="/home/deck/.local/share/Steam/steamapps/shadercache"

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
echo "Also, whether you're working with an SD Card, SSD, or any other storage, any storage that's not the default internal storage will be called External Storage by this script."
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

tTimeout=30

timeout_monitor() {
   sleep "$tTimeout"
   echo "Timing out; couldn't find Steam games in $sCardPath"
   echo "You may want to try another mount point."
   echo "Yes, you may see a weird grep error if you repeat last command. Working on how to fix that; shouldn't be a serious issue."
   kill "$1"
   exit 1
}

build_transfer_menu () {
#### Setting the paths for the operation:
  sLocalCompatDataRoot="/home/deck/.local/share/Steam/steamapps/compatdata"
  sLocalShaderCacheRoot="/home/deck/.local/share/Steam/steamapps/shadercache"
  if [[ $sLibraryType == "gamingMode" ]]; then
    sLocalCompatDataPath="$sLocalCompatDataRoot/$nSteamId"
    sLocalShaderCachePath="$sLocalShaderCacheRoot/$nSteamId"
    sCardCompatDataRoot="$sCardPath/steamapps/compatdata"
    sCardShaderCacheRoot="$sCardPath/steamapps/shadercache"
    sCardCompatDataPath="$sCardCompatDataRoot/$nSteamId"
    sCardShaderCachePath="$sCardShaderCacheRoot/$nSteamId"
  elif [[ $sLibraryType == "desktopMode" ]]; then
    ## Need to verify these paths to make sure that they work in Steam Deck just like they do on PC Desktop mode.
    echo
    echo "A note on external libraries since you chose one:"
    echo "I don't use my Steam Deck with USB drives."
    echo "Thus, I am assuming that the Steam Desktop Client was used to install in such a drive."
    echo "That means that the games should be in a directory called SteamLibrary located in the mount point selected."
    echo "If that's the case, this script should work. It found games in it, so you've gotten this far. That's good!"
    echo "So, knowing the information above, do you still wish to proceed?"
    sLocalCompatDataPath="$sLocalCompatDataRoot/$nSteamId"
    sLocalShaderCachePath="$sLocalShaderCacheRoot/$nSteamId"
    sCardCompatDataRoot="$sCardPath/SteamLibrary/compatdata"
    sCardShaderCacheRoot="$sCardPath/SteamLibrary/shadercache"
    sCardCompatDataPath="$sCardCompatDataRoot/$nSteamId"
    sCardShaderCachePath="$sCardShaderCacheRoot/$nSteamId"
  fi
  select nGame; do
    # Check the selected menu item number
    if [ 1 -le "$REPLY" ] && [ "$REPLY" -le $# ]; then
      sSelectedGame=$(echo "$nGame" | grep -oP '(?<=-).*' | sed -e 's/\_/\ /g')
      nSteamId=$(echo "$nGame" | egrep -o '^[^-]+')
      echo "-------------------------------------------------------------------------------------------------------------"
      echo "The selected game from this Steam Deck is $sSelectedGame."; echo
      echo "The App ID for the selected game is $nSteamId."; echo
      echo "Do you wish to proceed with the selection of $sSelectedGame, a game with an App ID of $nSteamId?"; echo
      select yn in "Yes" "No"; do
        case $yn in
          Yes )
            echo
            echo "Proceeding! Let's go!"
            nCount=0
            while [[ $nCount -lt 15 ]]; do
              printf \>
              sleep 0.05s
              ((nCount++))
            done
            echo
            sleep 1s
            if [[ -h "$sLocalCompatDataPath" ]]; then
              ###### --------Handling when the data has already been moved to micro SD card.
              echo
              echo "The compatibility data for $sSelectedGame has already been moved to a micro SD card."
              echo
              ############ Code to verify if the files are located in the current micro SD card and to ask to move them to internal storage goes here:
              sleep 1s
              echo "Do you want to move $sSelectedGame's compatibility data back to internal storage if it is present in the External Storage selected above?"
              sleep 1s
              echo
              select yn in "Yes" "No"; do
                case $yn in
                  Yes ) ## This path will move the compatibility data directory back to internal storage if it exists: ## Needs a bug check.
                    echo
                    if [[ -d "$sCardCompatDataPath" ]]; then
                      echo "Verifying size of compatibility data on External Storage and available Internal Storage space."
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
                        echo "Moving compatibility data back from External Storage to Internal Storage!"
                        echo
                        nCount=0
                        while [[ $nCount -lt 5 ]]; do
                          printf .
                          sleep 1s
                          ((nCount++))
                        done
                        cd $sLocalCompatDataRoot
                        /usr/bin/unlink $nSteamId
                        cd $sCardCompatDataRoot
                        /usr/bin/mv $nSteamId "$sLocalCompatDataRoot"
                        echo
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
                        echo "That's not enough space to move the selected compatibility data from External Storage back to Internal Storage."
                        echo
                      fi
                    else
                      echo "Warning: The selected External Storage location does not contain this title's compatibility data. No data to move back."
                      echo "The script will now exit."
                      echo ">>>>>Goodbye!<<<<<"; echo
                      exit 0
                    fi
                    break;;
                  No ) ## This path will not move the compatibility data directory back to internal storage
                    echo
                    echo "The compatibility data won't be moved to Internal Storage. Moving on to verify for pre-cached shader data."
                    sleep 3s
                    break;;
                esac
              done
            elif [[ -d "$sLocalCompatDataPath" && -d "$sCardCompatDataPath" ]]; then
              echo
              echo "=================================================================================================================================="
              echo "WARNING: We have found compatibility data directories for $sSelectedGame in both Internal and External Storage."
              echo "This script will prioritize the compatibility data path in the external storage as its aim is to save internal storage space."
              echo "To achieve this, the internal storage compatibility data path will be DELETED."
              echo "A symbolic link will be created in internal storage pointing to the compatibility data path in the selected External Storage."
              echo "Do you really wish to proceed?"
              echo
              select yn in "Yes" "No"; do
                case $yn in
                  Yes )
                    echo "Removing the Internal storage compatibility data directory for $sSelectedGame, as requested."
                    nCount=0
                    while [[ $nCount -lt 3 ]]; do
                      printf .
                      sleep 1s
                      ((nCount++))
                    done
                    #### Commands to delete the existing compatibility data directory in internal storage and create new symbolic link.
                    cd $sLocalCompatDataRoot
                    /usr/bin/rm -rf $nSteamId
                    /usr/bin/ln -s "$sCardCompatDataPath" $nSteamId
                    echo
                    echo "Returning the value of the resulting compatibility data symbolic link below:"
                    echo
                    sTargetCompatDataPath=$(/usr/bin/pwd)\/$(ls -lrt | grep -Eo "$nSteamId".*)
                    echo "$sTargetCompatDataPath"
                    echo
                    sleep 3s
                    nCardFreeReadable=$(df -h | grep -n "$sCardPath" | awk '{print $4}')
                    echo "External Storage has $nCardFreeReadable storage space left after moving compatibility data to it."
                    echo
                    break;;
                  No )
                    echo "You have chosen to keep both internal and External Storage compatibility data directories."
                    echo "$sSelectedGame's data has not been transferred anywhere."
                    echo "The script will now exit."
                    echo ">>>>>Goodbye!<<<<<"; echo
                    exit 0
                esac
              done
            elif [[ -d "$sLocalCompatDataPath" && ! -h "$sLocalCompatDataPath" ]]; then
              echo
              echo "There is an internal storage compatibility data directory for App ID $nSteamId."
              echo "A symbolic link will be created to maintain compatibility after moving the compatibility data directory."
              echo "Do you wish to proceed?"
              sleep 1s
              echo
              select yn in "Yes" "No"; do
                case $yn in
                  Yes ) ## This path will move the compatibility data directory to micro SD card. Checking space on card first.
                    echo;echo "Verifying available space on External Storage and size of compatibility data directory."
                    nCount=0
                    while [[ $nCount -lt 5 ]]; do
                      printf .
                      sleep 1s
                      ((nCount++))
                    done
                    nCardFreeAbsolute=$(df | grep "$sCardPath" | awk '{print $4}')
                    nCompatDataSize=$(du "$sLocalCompatDataPath" -d 0 | cut -f1)
                    if [[ $nCardFreeAbsolute -gt $nCompatDataSize ]]; then
                      echo;echo "Moving compatibility data directory to External Storage, please wait."
                      echo "Do not, under any circumstance, tamper with the External Storage while this operation runs."
                      echo
                      nCount=0
                      while [[ $nCount -lt 5 ]]; do
                        printf .
                        sleep 1s
                        ((nCount++))
                      done
                      cd $sLocalCompatDataRoot
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
              echo; echo "Moving on to verify for shader cache files."
              sleep 3s
              echo
            else
              echo
              echo "There is no compatibility data for $sSelectedGame. Moving on to shader pre-cache data."
            fi
          ############ Done with Compatibility Data.
              ############ Shader Cache from this line on.
              ############ Creepy crawlies are sure to be around.
              ############ LET'S DO THEEEEEEZZZZZZ
          if [[ -h "$sLocalShaderCachePath" ]]; then
            ## Code that validates whether the internal shader cache data path exists:"
            echo
            ###### --------Handling when the data has already been moved to micro SD card.
            echo "The shader cache for $sSelectedGame has already been moved to a micro SD card."; echo
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
                      echo "Great success! The script will now exit."
                      echo ">>>>>Goodbye!<<<<<"; echo
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
                      echo "The script will now exit."
                      echo ">>>>>Goodbye!<<<<<"; echo
                      exit 1
                  fi
                  break;;
                No ) ## This path will not move the shader cache directory to internal storage.
                  echo
                  echo "Shader cache data won't be moved to Internal Storage as selected."
                  echo "The script will now exit."
                  echo ">>>>>Goodbye!<<<<<"; echo
                  exit 0
              esac
            done
          elif [[ -d "$sLocalShaderCachePath" && -d "$sCardShaderCachePath" ]]; then
            ## The script will choose to do this if there is shader pre-cache data in both the internal storage and the MicroSD card.
            ## I am not sure that this scenario will actually happen, as I haven't seen it happen myself, but nonetheless, I am handling it.
            echo
            echo "=================================================================================================================================="
            echo "WARNING: We have found shader pre-cache data directories for $sSelectedGame in both Internal Storage and the MicroSD card."
            echo "This script will prioritize the shader pre-cache data path in the external storage as its aim is to save internal storage space."
            echo "To achieve this, the internal storage shader pre-cache data path will be DELETED."
            echo "A symbolic link will be created in internal storage pointing to the shader pre-cache data path in the MicroSD card."
            echo "Do you really wish to proceed?"
            echo
            select yn in "Yes" "No"; do
              case $yn in
                Yes )
                  echo "Removing the Internal shader pre-cache data directory for $sSelectedGame, as requested."
                  nCount=0
                  while [[ $nCount -lt 3 ]]; do
                    printf .
                    sleep 1s
                    ((nCount++))
                  done
                  #### Commands to delete the existing shader cache data directory in internal storage and create new symbolic link.
                  cd $sLocalShaderCacheRoot
                  /usr/bin/rm -rf $nSteamId
                  /usr/bin/ln -s "$sCardShaderCachePath" $nSteamId
                  echo
                  echo "Returning the value of the resulting compatibility data symbolic link below:"
                  echo
                  sTargetShaderCachePath=$(/usr/bin/pwd)\/$(ls -lrt | grep -Eo "$nSteamId".*)
                  echo "$sTargetShaderCachePath"
                  echo
                  sleep 3s
                  nCardFreeReadable=$(df -h | grep -n "$sCardPath" | awk '{print $4}')
                  echo "Micro SD card has $nCardFreeReadable storage space left after moving shader pre-cache data to it."
                  echo
                  exit 0
                  break ;;
                No )
                  echo "You have chosen to keep both internal and MicroSD card shader pre-cache data directories."
                  echo "$sSelectedGame's shader pre-cache data has not been transferred anywhere."
                  echo "The script will now exit."
                  echo ">>>>>Goodbye!<<<<<"; echo
                  exit 0
              esac
            done
          elif [[ -d "$sLocalShaderCachePath" && ! -h "$sLocalShaderCachePath" ]]; then
            echo
            echo "There is an internal storage shader cache directory for $sSelectedGame."
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
                    echo "Great success! The script will now exit."
                    echo ">>>>>Goodbye!<<<<<"; echo
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
                  sleep 3s
                  exit 0
              esac
            done
            else
              echo
              echo "There is no shader pre-cache data for $sSelectedGame. Exiting script."
              echo "The script will now exit."
              echo ">>>>>Goodbye!<<<<<"; echo
              exit 0
            fi
            break;;
#########################################################################################################################
          No )
            echo
            echo "Got it. Feel free to retry with another title."
            echo "Goodbye!"
            exit 0
            break;;
        esac
      done
    else
      echo "Wrong selection: Select any number from 1-$#"
      echo
    fi
  done
}
#########################################################################################################################
#########################################################################################################################
## Let's build a menu list with the storage partitions on the device:

build_storage_menu () {
  echo "First, let's establish the storage location where we will search for games."
  echo
  select nStorage; do
    #We are checking the selected menu item number.
    if [ 1 -le "$REPLY" ] && [ "$REPLY" -le $# ]; then
      nSelectedStorage=$(echo "$nStorage")
      echo
      echo "The selected storage is the one located at $nStorage"
      echo "Is that correct?"
      select yn in "Yes" "No"; do
        case $yn in
          Yes )
            echo
            echo "Proceeding. Let's go!"
            nCount=0
            while [[ $nCount -lt 15 ]]; do
              printf \>
              sleep 0.05s
              ((nCount++))
            done
            sCardPath="$nSelectedStorage"
            timeout_monitor "$$" &
            Timeout_monitor_pid=$!
            if [[ $sCardPath == "/run/media/mmcblk0p1" ]]; then
              echo
              echo "Scanning for Steam games on your MicroSD card path, please wait."
              sLibraryType="gamingMode"
              aGameList=($(/usr/bin/grep -e name $(find "$sCardPath" -maxdepth 1 -name steamapps -printf "%h/%f/*appmanifest* ") | grep -v ".acf.*.tmp.*" | sed -e 's/^.*_//;s/name//;s/.acf://;s/"//g;s/\ /_/g;s/\t\{1,3\}/-/g'))
            else
              echo
              echo "Scanning for Steam games on what seems to be a Steam desktop client library, please wait."
              sLibraryType="desktopMode"
              aGameList=($(/usr/bin/grep -e name $(find "$sCardPath" -maxdepth 1 -name SteamLibrary -printf "%h/%f/*appmanifest* ") | grep -v ".acf.*.tmp.*" | sed -e 's/^.*_//;s/name//;s/.acf://;s/"//g;s/\ /_/g;s/\t\{1,3\}/-/g'))
            fi
            kill "$Timeout_monitor_pid"
            migrate_game_caches "${aGameList[@]}"
            break;;
          No )
            echo "Got it. Feel free to try again with another selection later on!"
            echo "Goodbye."
            exit 0
            break;;
        esac
      done
    fi
  done
}

aStorageList=($(df -h | awk 'FNR >1 {print $6}' | grep -v 'etc\|var\|dev\|tmp'))
build_storage_menu "${aStorageList[@]}"



