# steamdeckbash
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

### A Note on the Menu:

The menu isn't the most elegant one, but it works. It will display the App ID for the game, a dash, and the name of the game with underscores for the spaces. Something like "690790-Dirt_Rally_2"
Fixing it so the items on the menu look better, as in turning the example above into just "Dirt Rally 2" on the menu is on the wish list, but it's very low priority.