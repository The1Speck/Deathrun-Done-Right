# Deathrun-DoneRight
A more complete solution for deathrun servers. With flexibility and simplicity in mind.


##Features (Current)

* Blocking Radio Commands
* Tracking of how many rounds since a player was T
* Queue System which prioritizes random selection. Viewable from a menu.
* Disable plugin if its not a deathrun map (Ability to disable this feature included)
* Full blocking of changing to T team manually.
* Disable autoswitching based on players on server.

####Commands

* **sm_queue** Opens up main Queue menu.

####Convars

*	**deathrundr_enable** Enable or disable the Deathrun Done Right; 0 - disabled, 1 - enabled
*	**deathrundr_check_maps** Enable or disable the checking of whether or not the map is deathrun. 0 disabled, 1 - enabled
*	**deathrundr_rounds_as_t** How many consecutive rounds can you play as T?
*	**deathrundr_block_radio** Should radio commands be blocked? 0 disabled, 1 - enabled.
*	**deathrundr_enable_queue** Enable or disable the T-queue implementation. 0 disabled, 1 - enabled.


##Features (Planned)

* ~~Queue system~~  _Added in v1.0_
* Priority System
* ~~Prevention of consecutive Ting~~  _Added in v1.0_
* Integrated timed respawns
* Optional 1v1 finish
* Rankings
* Rewarding the CT who kills the T (letting them be T next round).

###Credits
[bobbobagan's original Deathrun Plugin](https://forums.alliedmods.net/showthread.php?t=129907) and [databomb's CTBans Plugin](https://forums.alliedmods.net/showthread.php?t=166080). As well as the entire AlliedMods [forum](https://forums.alliedmods.net/index.php).
