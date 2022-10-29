# steamdeckbash
# Overview

This is simply meant to be a collection of a few bash scripts created to add functionality to or to make the Steam Deck (or other Steam OS devices I suppose) a little more convenient to use.

## moveCacheLocation.sh

This is probably the reason that you are visiting this page. It's a script to move the compatibility and shader pre-cache files from the internal storage to the MicroSD card or back to internal storage. It will then create a symbolic link in internal storage if the files were moved there so that functionality is not negatively impacted from that operation.

More information in the following locations:

[Detailed explanation at Medium](https://arodznegron.medium.com/steam-deck-save-internal-space-with-this-script-f45e31f10830)

[YouTube Video Overview and Explanation](https://youtu.be/g-Ymn8YA8zg)

[Rumble Video Overview and Explanation](https://rumble.com/v1qe7qv-use-a-bash-script-to-save-internal-storage-space-on-your-steam-deck.html?mref=1j31yr&mc=3pdme)

### Final word on moveCacheLocation script

I consider this script to be feature complete at this point, even if there is a scenario that it's not handling at this time:

If a user used the Move install location feature from Steam to move a game's data from internal storage to the MicroSD card, SteamOS created the compatibility directory on the MicroSD card on its own. However, there's still a compatibility directory on internal storage. I haven't spent enough time verifying how this behaviour works, so the script does not support this scenario. I plan to expand it later on to handle this kind of situation, but the current version does not.
