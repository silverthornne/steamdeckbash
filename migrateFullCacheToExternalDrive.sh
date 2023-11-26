#!/bin/bash

########################################## SCRIPT VERSION: 0.70 - Use at your own Risk!!!! #####################################################
########################################################################################################### migrateFullCacheToExternalDrive.sh##
###################                           Code by Antonio Rodriguez Negron   |   silverthornne                              ################
################### This is a script that will check the storage partition that you select for Steam games on a Steam Deck (it  ################
################### may work in other SteamOS devices, but I have only tested on Deck!) and will move all of the compatibility  ################
################### and shader pre-cache data files for the games in that storage partition from internal storage to the game's ################
################### storage partition. What happens is that the Steam Deck creates the compatibility and shader pre-cache data  ################
################### files for its games within its internal storage, even if the game is located on a different drive. After    ################
################### running this script, all of those compatibility and shader pre-cache files will be in the same drive        ################
################### partition as the game itself.                                                                               ################
###################=============================================================================================================################
###################                                                                                                             ################
###################                                      IMPORTANT DISCLAIMERS!!!                                               ################
###################                                      !!!!!!PLEASE READ!!!!!!!                                               ################
###################                                                                                                             ################
###################-------------------------------------------------------------------------------------------------------------################
################### Personally, I don't use external storage with my Deck and I don't own one of those docks that allow the     ################
################### use of an M2 drive. That means that I am not able to actually test this script on that kind of product.     ################
################### I am hoping that this script can be tested with community help through Github so that I can confidently     ################
################### upgrade it to a "1.0" version. All I can do is test the SD card implementation after all.                   ################
###################-------------------------------------------------------------------------------------------------------------################
################### Once the storage is confirmed to have Steam games, this script will return the games that were identified   ################
################### in your device. It will request a confirmation, and it will get to work! Don't interrupt the script, don't  ################
################### let the system go to sleep, and don't remove the storage where it's running. The script will offer feedback ################
################### as it runs, so you won't be on the dark about the process, but it can't be interrupted either.              ################
###################-------------------------------------------------------------------------------------------------------------################
################### The script will:                                                                                            ################
###################                                                                                                             ################
################### 1. MOVE compatibility data for games in the selected storage from internal storage to the storage where the ################
###################    game is located.                                                                                         ################
################### 2. MOVE the shader pre-cache data for games in the selected storage from internal storage to the storage    ################
###################    where the game is located.                                                                               ################
################### 3. If there is compatibility data in both the internal storage and the selected external storage for that   ################
###################    game, the script will DELETE the compatibility data in internal storage and create a symbolic link to    ################
###################    the existing compatibility data in the selected external storage. External data is prioritized.          ################
################### 4. If there is shader pre-cache data in both the internal storage and the selected external storage for     ################
###################    that game, the script will DELETE the compatibility data in internal storage and create a symbolic link  ################
###################    to the existing shader pre-cache data in the selected external storage. External storage is prioritized. ################
################### 5. If the game's compatibility data has already been moved to the external storage drive, the game will be  ################
###################    skipped for compatibility data and the script will check for shader data for that game.                  ################
################### 6. If the game's shader pre-cache data has already been moved to the external storage drive, the game will  ################
###################    be skipped for shader pre-cache data and the script will proceed to the next game until it's done.       ################
###################-------------------------------------------------------------------------------------------------------------################
################### The script will NOT:                                                                                        ################
###################                                                                                                             ################
################### 1. Move compatibility and shader pre-cache data back from the selected external storage drive back to       ################
###################    internal storage. If you need to do that, please use any of the other scripts that can move data both    ################
###################    ways: moveCacheLocation.sh, sendCacheToExternalStorage.sh, or transferCacheToSDCard.sh.                  ################
################### 2. Verify that the compatibility and shader pre-cache data that will be moved to the external storage will  ################
###################    fit in there before moving it. It will just attempt to move it with brute force. It will move on to      ################
###################    the next title if there isn't enough storage space for the current one.                                  ################
###################=============================================================================================================################
################### Oh YEA! Important stuff:                                                                                    ################
###################                                                                                                             ################
################### This script is provided as-is. No guarantees are written or implied. You may freely use this script but may ################
################### not distribute it unless you keep this message in your distribution. Feel free to fork it and modify it for ################
################### your own use. The reality is that I don't really have the power to stop you from distributing this script   ################
################### and remove this message, but if you do so you will be cursed in such a way that, from the date that you     ################
################### choose to breach this condition, you'll feel an intense craving for Oreo cookies. Every time you sit down   ################
################### to eat them you will get a nice bottle of milk, dunk them in it, and egads!                                 ################
################### NO FILLING ON EVERY THIRD COOKIE! That's your curse! Intense craving for Oreos but every third one will     ################
################### have no filling! You've been warned.                                                                        ################
################### Oh! And I'm not affiliated with Nabisco in any way, shape or form. I just find that curse amusing :)        ################
## migrateFulLCacheToExternalDrive.sh ##########################################################################################################

cat << "HEREDOCINTRO"

/----------------------------------------------------------------------------------------------------------------------\
| This shell script will look into a selected storage mounting point and will search for Steam games. If there are     |
| Steam games in that storage, the script will transfer all of the compatibility and shader pre-cache files for those   |
| games to the selected storage. This will free up space on the internal storage drive. Steam will access and update   |
| those files as if they were on internal storage. Performance may see a slight decline, depending on the storage      |
| specs such as its access speed and supported file IOPS.                                                              |
|                                                                                                                      |
| ===========================================THIS IS A BULK OPERATION==================================================|
| It will not stop once the user has confirmed to proceed. Please don't interrupt it until it's done. You will be able |
| able to opt out before it runs. Please read all the instructions in detail before choosing to proceed.               |
|======================================================================================================================|
|                                                                                                                      |
| This script will always prioritize placing data on the external drive to save space on the internal drive and to     |
| extend its life in the process. If you experience reduced performance from a particular game after running this      |
| script and you wish to return to the performance that you had before running it for that particular game, please use |
| the companion scripts such as transferCacheToSDCard.sh to move the compatibility and shader pre-cache data back to   |
| internal storage for that particular game and return its performance to how it was before running the script.        |
\----------------------------------------------------------------------------------------------------------------------/

HEREDOCINTRO
dNow=$(printf '%(%Y%m%d%H%M)T\n')


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

tTimeout=30

timeout_monitor() {
   sleep "$tTimeout"
   echo
   echo "xxxxxXXXXXXXXXXX Timing out; couldn't find Steam games in $sCardPath. XXXXXXXXXXXxxxxx"
   echo "xxxxxxxxxXXXXXXXXXXXXX You may want to try another mount point. XXXXXXXXXXXXXxxxxxxxxx"
   echo
   echo "--Yes, you may see a weird grep error. Working on how to fix that; shouldn't be a serious issue.--"
   kill "$1"
   exit 1
}

nInternalFreeAtStartReadable=$(df -h | grep -n "/home" | awk '{print $4}')
migrate_game_caches () {
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
    sCardCompatDataRoot="$sCardPath/SteamLibrary/steamapps/compatdata"
    sCardShaderCacheRoot="$sCardPath/SteamLibrary/steamapps/shadercache"
    sCardCompatDataPath="$sCardCompatDataRoot/$nSteamId"
    sCardShaderCachePath="$sCardShaderCacheRoot/$nSteamId"
    select yn in "Yes" "No"; do
      case $yn in
        Yes )
          echo
          echo "Excellent, we're moving on!"
          echo
          break;;
        No )
          echo
          echo "Not moving on, got it."
          echo "Goodbye!"
          exit 0
          break;;
      esac
    done
  fi
  echo
  echo "The games that will be migrated will be the following:"
  echo
  /usr/bin/printf "'%s'\n" "${aGameList[@]}"
  echo
  echo "Last chance to back out as you can't cancel once the process starts. Do you wish to do this?"
  select yn in "Yes" "No"; do
    case $yn in
      Yes )
        echo
        echo "Excellent, let's do this!"
        echo
        fLogFile="/home/deck/Migration_Result_$dNow.txt"
        touch $fLogFile
        echo "Important Note: A record of this operation's output will be created as a file named $fLogFile."
        dIterationDay=$(printf '%(%Y-%m-%d)T\n')
        dIterationTime=$(printf '%(%H:%M)T\n')
        echo "Process started on $dIterationDay at $dIterationTime." | tee -a $fLogFile
        echo | /usr/bin/tee -a $fLogFile
        nInternalFreeReadable=$(df -h | grep -n "/home" | awk '{print $4}')
        echo "| Internal Storage Available when the process started = $nInternalFreeAtStartReadable |" | /usr/bin/tee -a $fLogFile
        echo | /usr/bin/tee -a $fLogFile
        echo "Using the following directories as the local storage locations:" >> $fLogFile
        echo "|->$sLocalCompatDataRoot" >> $fLogFile
        echo "|->$sLocalShaderCacheRoot" >> $fLogFile
        echo >> $fLogFile
        echo "Using the following directories as the external storage locations:" >> $fLogFile
        echo "|->$sCardCompatDataRoot" >> $fLogFile
        echo "|->$sCardShaderCacheRoot" >> $fLogFile
        echo >> $fLogFile
        echo "================================================================================" >> $fLogFile
        for sGameFull in "${aGameList[@]}"; do
          #####>>>>>>>>>>>>>>>>>>>>>> Cycling through games in here!
          sSelectedGame=$(echo "$sGameFull" | grep -oP '(?<=-).*' | sed -e 's/\_/\ /g')
          nSteamId=$(echo "$sGameFull" | egrep -o '^[^-]+')
          echo "[$dIterationDay at $dIterationTime] Migrating $sSelectedGame with a Steam App ID of $nSteamId."
          echo
          echo "[$dIterationDay at $dIterationTime] ------------------------------------------------------------------------------" >> $fLogFile
          echo "Migrating $sSelectedGame with a Steam App ID of $nSteamId." >> $fLogFile
          ############################################## SCRIPT INSERT
          sLocalCompatDataPath="$sLocalCompatDataRoot/$nSteamId"
          sLocalShaderCachePath="$sLocalShaderCacheRoot/$nSteamId"
          sCardCompatDataPath="$sCardCompatDataRoot/$nSteamId"
          sCardShaderCachePath="$sCardShaderCacheRoot/$nSteamId"
          if [[ -h "$sLocalCompatDataPath" ]]; then
            ###### --------Handling when the data has already been moved to micro SD card.
            echo
            echo "The compatibility data for $sSelectedGame has already been moved to external storage." | /usr/bin/tee -a $fLogFile
            echo "Moving on to pre-cached shader data." | /usr/bin/tee -a $fLogFile
            echo | /usr/bin/tee -a $fLogFile
          elif [[ -d "$sLocalCompatDataPath" && -d "$sCardCompatDataPath" ]]; then
            echo | /usr/bin/tee -a $fLogFile
            echo "WARNING: We have found compatibility data directories for $sSelectedGame in both Internal Storage and the external storage location." | /usr/bin/tee -a $fLogFile
            echo "This script will prioritize the compatibility data path in the external storage as its aim is to save internal storage space." | /usr/bin/tee -a $fLogFile
            echo "To achieve this, the internal storage compatibility data path will be DELETED." | /usr/bin/tee -a $fLogFile
            echo "A symbolic link will be created in internal storage pointing to the compatibility data path in the external storage." | /usr/bin/tee -a $fLogFile
            echo | /usr/bin/tee -a $fLogFile
            echo "Removing the Internal storage compatibility data directory for $sSelectedGame, as requested." | /usr/bin/tee -a $fLogFile
            #### Commands to delete the existing compatibility data directory in internal storage and create new symbolic link.
            cd $sLocalCompatDataRoot
            /usr/bin/rm -rf $nSteamId
            /usr/bin/ln -s "$sCardCompatDataPath" $nSteamId
            echo "Returning the value of the resulting compatibility data symbolic link below:" | /usr/bin/tee -a $fLogFile
            echo | /usr/bin/tee -a $fLogFile
            sTargetCompatDataPath=$(/usr/bin/pwd)\/$(ls -lrt | grep -Eo "$nSteamId".*)
            echo "$sTargetCompatDataPath" | /usr/bin/tee -a $fLogFile
            echo | /usr/bin/tee -a $fLogFile
            nCardFreeReadable=$(df -h | grep -n "$sCardPath" | awk '{print $4}')
            echo "External Storage has $nCardFreeReadable storage space left after moving $sSelectedGame's compatibility data to it." | /usr/bin/tee -a $fLogFile
            echo | /usr/bin/tee -a $fLogFile
          elif [[ -d "$sLocalCompatDataPath" && ! -h "$sLocalCompatDataPath" ]]; then
            echo | /usr/bin/tee -a $fLogFile
            echo "There is an internal storage compatibility data directory for $sSelectedGame." | /usr/bin/tee -a $fLogFile
            echo "A symbolic link will be created to maintain compatibility after moving the compatibility data directory." | /usr/bin/tee -a $fLogFile
            echo | /usr/bin/tee -a $fLogFile
            echo "Verifying available space on the external storage partition and size of compatibility data directory." | /usr/bin/tee -a $fLogFile
            nCardFreeAbsolute=$(df | grep "$sCardPath" | awk '{print $4}')
            nCompatDataSize=$(du "$sLocalCompatDataPath" -d 0 | cut -f1)
            if [[ $nCardFreeAbsolute -gt $nCompatDataSize ]]; then
              echo | /usr/bin/tee -a $fLogFile
              echo "Moving compatibility data directory to external storage, please wait." | /usr/bin/tee -a $fLogFile
              echo "Do not, under any circumstance, remove the external storage while this operation runs." | /usr/bin/tee -a $fLogFile
              echo | /usr/bin/tee -a $fLogFile
              cd $sLocalCompatDataRoot
              /usr/bin/mv $nSteamId "$sCardCompatDataRoot"
              sCardCompatDataPath="$sCardCompatDataRoot/$nSteamId"
              /usr/bin/ln -s "$sCardCompatDataPath" $nSteamId
              cd "$sLocalCompatDataRoot"
              echo | /usr/bin/tee -a $fLogFile
              echo "Returning the value of the resulting compatibility data symbolic link below:" | /usr/bin/tee -a $fLogFile
              echo | /usr/bin/tee -a $fLogFile
              sTargetCompatDataPath=$(/usr/bin/pwd)\/$(ls -lrt | grep -Eo "$nSteamId".*)
              echo "$sTargetCompatDataPath" | /usr/bin/tee -a $fLogFile
              echo | /usr/bin/tee -a $fLogFile
              nCardFreeReadable=$(df -h | grep -n "$sCardPath" | awk '{print $4}')
              echo "External storage has $nCardFreeReadable storage space left after moving $sSelectedGame's compatibility data to it." | /usr/bin/tee -a $fLogFile
            else
              nCardFreeReadable=$(df -h | grep -n "$sCardPath" | awk '{print $4}')
              nCompatDataSizeReadable=$(du -h "$sLocalCompatDataPath" -d 0 | cut -f1)
              echo | /usr/bin/tee -a $fLogFile
              echo "There is not enough free space on the external storage to move $sSelectedGame's compatibility data directory to it." | /usr/bin/tee -a $fLogFile
              echo "The external storage needs $nCompatDataSizeReadable free, but it only has $nCardFreeReadable available." | /usr/bin/tee -a $fLogFile
              echo | /usr/bin/tee -a $fLogFile
            fi
          echo | /usr/bin/tee -a $fLogFile
          echo "Moving on to verify for shader cache files." | /usr/bin/tee -a $fLogFile
          echo | /usr/bin/tee -a $fLogFile
          else
            echo | /usr/bin/tee -a $fLogFile
            echo "There is no compatibility data for $sSelectedGame. Moving on to shader pre-cache data." | /usr/bin/tee -a $fLogFile
          fi
          cd ~
    ############ Done with Compatibility Data.
    ############ Shader Cache from this line on.
    ############ Creepy crawlies are sure to be around.
    ############ LET'S DO THEEEEEEZZZZZZ
          if [[ -h "$sLocalShaderCachePath" ]]; then
            ## Code that validates whether the internal shader cache data path exists:"
            echo | /usr/bin/tee -a $fLogFile
            ###### --------Handling when the data has already been moved to micro SD card.
            echo "The shader cache for $sSelectedGame has already been moved to the external storage." | /usr/bin/tee -a $fLogFile
            echo "Moving on." | /usr/bin/tee -a $fLogFile
            echo | /usr/bin/tee -a $fLogFile
          elif [[ -d "$sLocalShaderCachePath" && -d "$sCardShaderCachePath" ]]; then
            ## The script will choose to do this if there is shader pre-cache data in both the internal storage and the MicroSD card.
            ## I am not sure that this scenario will actually happen, as I haven't seen it happen myself, but nonetheless, I am handling it.
            echo | /usr/bin/tee -a $fLogFile
            echo "==================================================================================================================================" | /usr/bin/tee -a $fLogFile
            echo "WARNING: We have found shader pre-cache data directories for $sSelectedGame in both Internal Storage and the MicroSD card." | /usr/bin/tee -a $fLogFile
            echo "This script will prioritize the shader pre-cache data path in the external storage as its aim is to save internal storage space." | /usr/bin/tee -a $fLogFile
            echo "To achieve this, the internal storage shader pre-cache data path will be DELETED." | /usr/bin/tee -a $fLogFile
            echo "A symbolic link will be created in internal storage pointing to the shader pre-cache data path in the MicroSD card." | /usr/bin/tee -a $fLogFile
            echo | /usr/bin/tee -a $fLogFile
            #### Commands to delete the existing shader cache data directory in internal storage and create new symbolic link.
            cd $sLocalShaderCacheRoot
            /usr/bin/rm -rf $nSteamId
            /usr/bin/ln -s "$sCardShaderCachePath" $nSteamId
            echo | /usr/bin/tee -a $fLogFile
            echo "Returning the value of the resulting compatibility data symbolic link below:" | /usr/bin/tee -a $fLogFile
            echo | /usr/bin/tee -a $fLogFile
            sTargetShaderCachePath=$(/usr/bin/pwd)\/$(ls -lrt | grep -Eo "$nSteamId".*)
            echo "$sTargetShaderCachePath" | /usr/bin/tee -a $fLogFile
            echo | /usr/bin/tee -a $fLogFile
            nCardFreeReadable=$(df -h | grep -n "$sCardPath" | awk '{print $4}')
            echo "Micro SD card has $nCardFreeReadable storage space left after moving shader pre-cache data to it." | /usr/bin/tee -a $fLogFile
            echo | /usr/bin/tee -a $fLogFile
          elif [[ -d "$sLocalShaderCachePath" && ! -h "$sLocalShaderCachePath" ]]; then
            echo | /usr/bin/tee -a $fLogFile
            echo "There is an internal storage shader cache directory for $sSelectedGame." | /usr/bin/tee -a $fLogFile
            echo "A symbolic link will be created to maintain compatibility after moving the shader cache directory." | /usr/bin/tee -a $fLogFile
            nCardFreeAbsolute=$(df | grep "$sCardPath" | awk '{print $4}')
            nShaderCacheSize=$(du $sLocalShaderCachePath -d 0 | cut -f1)
            if [[ $nCardFreeAbsolute -gt $nShaderCacheSize ]]; then
              echo | /usr/bin/tee -a $fLogFile
              echo "Moving shader cache directory to micro SD card, please wait." | /usr/bin/tee -a $fLogFile
              echo "Do not, under any circumstance, remove the micro SD card while this operation runs." | /usr/bin/tee -a $fLogFile
              echo | /usr/bin/tee -a $fLogFile
              cd "$sLocalShaderCacheRoot"
              /usr/bin/mv $nSteamId "$sCardShaderCacheRoot"
              sCardShaderCachePath="$sCardShaderCacheRoot/$nSteamId"
              /usr/bin/ln -s "$sCardShaderCachePath" $nSteamId
              cd "$sLocalShaderCacheRoot"
              echo "Returning the value of the shader cache symbolic link below:" | /usr/bin/tee -a $fLogFile
              echo | /usr/bin/tee -a $fLogFile
              sTargetShaderCachePath=$(/usr/bin/pwd)\/$(ls -lrt | grep -Eo "$nSteamId".*)
              echo "$sTargetShaderCachePath" | /usr/bin/tee -a $fLogFile
              echo | /usr/bin/tee -a $fLogFile
              nCardFreeReadable=$(df -h | grep -n "$sCardPath" | awk '{print $4}')
              echo "Micro SD card has $nCardFreeReadable storage space left after moving shader cache to it." | /usr/bin/tee -a $fLogFile
              echo "Great success for $sSelectedGame!" | /usr/bin/tee -a $fLogFile
            else
              nCardFreeReadable=$(df -h | grep -n "$sCardPath" | awk '{print $4}')
              nShaderCacheSizeReadable=$(du -h $sLocalShaderCachePath -d 0 | cut -f1)
              echo | /usr/bin/tee -a $fLogFile
              echo "There is not enough free space on the Micro SD card to move the shader cache directory to it." | /usr/bin/tee -a $fLogFile
              echo "The Micro SD card needs $nShaderCacheSizeReadable free, but it only has $nCardFreeReadable available." | /usr/bin/tee -a $fLogFile
              echo | /usr/bin/tee -a $fLogFile
            fi
          else
            echo | /usr/bin/tee -a $fLogFile
            echo "There is no shader pre-cache data for $sSelectedGame. Moving on." | /usr/bin/tee -a $fLogFile
          fi
          cd ~
        done
        nInternalFreeAtEndReadable=$(df -h | grep -n "/home" | awk '{print $4}')
        echo | /usr/bin/tee -a $fLogFile
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" | /usr/bin/tee -a $fLogFile
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" | /usr/bin/tee -a $fLogFile
        echo | /usr/bin/tee -a $fLogFile
        echo "[$dIterationDay at $dIterationTime] ================================================================================" >> $fLogFile
        echo "When we started, the Internal Storage Drive had $nInternalFreeAtStartReadable of storage available." | /usr/bin/tee -a $fLogFile
        echo "The Internal Storage Drive now has $nInternalFreeAtEndReadable of storage available." | /usr/bin/tee -a $fLogFile
        echo "How about that? Woot!" | /usr/bin/tee -a $fLogFile
        echo "Anyway, thanks for using the script and Goodbye!" | /usr/bin/tee -a $fLogFile
        echo "[$dIterationDay at $dIterationTime] ================================================================================" >> $fLogFile
        echo "Migration done!" | /usr/bin/tee -a $fLogFile
        exit 0
        break ;;
      No )
        echo "Ok, canceling operation."
        echo "Have a good day!"
        exit 0
        break ;;
    esac
  done
}

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
              aGameList=($(/usr/bin/grep -e name $(find "$sCardPath" -maxdepth 1 -name steamapps -printf "%h/%f/*appmanifest* ") | grep -v ".acf.*.tmp.*" | sed -e 's/^.*_//;s/name//;s/.acf://;s/"//g;s/\ /_/g;s/\t\{1,3\}/-/g'))
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