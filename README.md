# steamdeckbash

# BIG UPDATE [November 26, 2023]
Valve pushed an update that changes the default mount location for the MicroSD card. This shouldn't have a negative consequence if you had already used the script to move data around, but unfortunately it won't allow you run the script again.

The transferCacheToExternalStorage.sh, and moveCacheLocation.sh scripts have been updated to reflect this change. I don't use USB storage on my Steam Deck, so I am not sure how to make it work with these changes on the sendCacheToExternalStorage.sh and the migrateFullCacheToExternalDrive.sh scripts.

# Overview

This is simply meant to be a collection of a few bash scripts created to add functionality to or to make the Steam Deck (or other Steam OS devices I suppose) a little more convenient to use.

## moveCacheLocation.sh

This is probably the reason that you are visiting this page. It's a script to move the compatibility and shader pre-cache files from the internal storage to the MicroSD card or back to internal storage. It will then create a symbolic link in internal storage if the files were moved there so that functionality is not negatively impacted from that operation.

More information in the following locations:

[Detailed explanation at Medium](https://arodznegron.medium.com/steam-deck-save-internal-space-with-this-script-f45e31f10830)

[YouTube Video Overview and Explanation](https://youtu.be/g-Ymn8YA8zg)

[Rumble Video Overview and Explanation](https://rumble.com/v1qe7qv-use-a-bash-script-to-save-internal-storage-space-on-your-steam-deck.html?mref=1j31yr&mc=3pdme)

### Final word on moveCacheLocation script:

I consider this script to be feature complete at this point, even if there is a scenario that it's not handling at this time:

If a user used the Move install location feature from Steam to move a game's data from internal storage to the MicroSD card, SteamOS created the compatibility directory on the MicroSD card on its own. However, there's still a compatibility directory on internal storage. I haven't spent enough time verifying how this behaviour works, so the script does not support this scenario. I plan to expand it later on to handle this kind of situation, but the current version does not.

## transferCacheToSDcard.sh

### Building a list of games installed and selecting from them

Based on a suggestion and some help from [/r/SteamDeck](https://www.reddit.com/r/SteamDeck/), user *Z_a_l_g_o*, this new script looks into the app manifest files in the MicroSD card and obtains information from them to display a menu with all games installed in the present MicroSD card.

This should make this script safer as the user won't have to type in the App ID; it will use the App IDs located from the data on the app manifest files. I haven't tested it yet though, so use it at your own risk only! This version also lacks the function to create a symbolic link for a game that isn't present in the MicroSD card. As it works with the games currently present in it and doesn't allow a user to type in the App ID themselves, it can't offer to create a symbolic link for a game whose information isn't present in the app manifest files.

Other than those notes, the end result is the same: if the game has its compatibility and shader pre-cache files on Internal storage, it will move them to MicroSD card and create a symbolic link. If there is already a symbolic link present, it will remove the symbolic link and move the files back from MicroSD card to internal storage. Don't use it on a game that was not directly installed to the MicroSD card; I still haven't worked on the scenario of a game that was moved to MicroSD card via Steam's "Move install location" function.

This script also has logic to handle when the Steam Deck's internal storage and the MicroSD card both have directories for the compatibility and shader pre-cache data. The data on the MicroSD card will be prioritized and the data on internal storage will be deleted.

[Detailed explanation at Medium](https://medium.com/@arodznegron/easy-cache-data-transfer-script-for-steam-deck-4185bd312fb8)

[YouTube Video Overview and Explanation](https://youtu.be/eN2jSfvatJo)

[Rumble Video Overview and Explanation](https://rumble.com/v1wbfdw-an-improved-script-to-save-storage-space-on-steam-deck.html)

### A Note on the Menu List:

The menu isn't the most elegant one, but it works. It will display the App ID for the game, a dash, and the name of the game with underscores for the spaces. Something like "690790-Dirt_Rally_2"
Fixing it so the items on the menu look better, as in turning the example above into just "Dirt Rally 2" on the menu is on the wish list, but it's very low priority.

## sendCacheToExternalStorage.sh

### UPDATE 2022-12-08
This external storage business is more complex than I expected as external storage can be used from within the Steam Deck desktop client and it will use a different directory for the games than the MicroSD card does from the Steam Gaming Mode. This may make the script to locate the games time out because it's looking in the wrong directory when it's an external storage drive. I have taken steps to fix this by changing the directory to follow the same pattern as with the desktop application (SteamLibrary instead of steamapps), but I need community help to test it because I don't use USB storage with my Deck.

This script is meant to handle issue #1. It will ask the user on which storage partition they want the script to look for games to move internal compatibility and shader pre-cache data to. It can be used to replace the transferCacheToSDCard script because the user can choose to run it on the MicroSD card location. This script will timeout when searching for games to handle the possibility that the user may choose a mount point without any Steam games in it. In the case that it times out, it may give a weird grep error precisely because it didn't find any games. 

However, if you just have a MicroSD card and don't use internal storage, you can skip the mount selection step by using the transferCacheToSDCard script, so that will be faster. Up to the user!

## migrateFullCacheToExternalDrive.sh

Script Features:

1. MOVE compatibility data for ALL games with compatibility and pre-cached shader data in the selected storage from internal storage to the storage where the game is located.
2. MOVE the shader pre-cache data for games in the selected storage from internal storage to the storage where the game is located.
3. If there is compatibility data in both the internal storage and the selected external storage for that game, the script will DELETE the compatibility data in internal storage and create a symbolic link to the existing compatibility data in the selected external storage. External data is prioritized.
4. If there is shader pre-cache data in both the internal storage and the selected external storage for that game, the script will DELETE the compatibility data in internal storage and create a symbolic link to the existing shader pre-cache data in the selected external storage. External storage is prioritized.
5. If the game's compatibility data has already been moved to the external storage drive, the game will be skipped for compatibility data and the script will check for shader data for that game.
6. If the game's shader pre-cache data has already been moved to the external storage drive, the game will be skipped for shader pre-cache data and the script will proceed to the next game until it's done.

This script will NOT:

1. Move compatibility and shader pre-cache data back from the selected external storage drive back to internal storage. If you need to do that, please use any of the other scripts that can move data both ways: moveCacheLocation.sh, sendCacheToExternalStorage.sh, or transferCacheToSDCard.sh.
2. Verify that the compatibility and shader pre-cache data that will be moved to the external storage will fit in there before moving it. It will just attempt to move it with brute force. It will move on to the next title if there isn't enough storage space for the current one.
3. Create symbolic links in internal storage for games that don't have their compatibility or pe-cached shader data directories created.

Yes, this works for ALL games on MicroSD card or external storage in one run. This is an all or nothing script. I'm still testing it out, but it seems to be working fine on MicroSD card. I lack USB storage on my Deck, so I can't test it in that scenario. What this script does is that it just moves all compatibility and pre-cached shader data that it finds to the MicroSD card or to the selected storage. It uses the same menu to select the storage target as the sendCacheToExternalStorage.sh script. The MicroSD card is the /run/media/mmcblk0p1 location so choose that for MicroSD card.

Since the script will skip games that it doesn't need to interact with (because it's already moved their data), it's safe to run multiple times if you install more games to the MicroSD card or the external storage later. You can also run transferCacheToSDCard.sh or sendCacheToExternalStorage.sh on a specific game whose compatibility or pre-cached shader data you need to move back to internal storage if performance sees a hit after moving the data out of it.

As usual, I plan to make a video about this script later on, and probably another video explaining the different use cases for each script so users can choose which one will work the best for their needs.


