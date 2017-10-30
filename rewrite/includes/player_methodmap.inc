#if defined _player_methodmap_included
	#endinput
#endif
#define _player_methodmap_included

/* User Type */
#define USER_TYPE_COMMAND      0
#define USER_TYPE_IS_STAFF     1
#define USER_TYPE_BROADCAST    2
#define USER_TYPE_GROUPNAME    3
#define USER_TYPE_FULLNAME     4
#define USER_TYPE_SCORENAME    5
#define USER_TYPE_CHATNAME     6
#define USER_TYPE_MULTI_TARGET 7

#define that view_as<int>(this)

#include <sourcemod> 			// Default Sourcemod Includes
#include <sdktools>				// ┫
#include <clientprefs>			// ┛
#include <imod>

methodmap Player {
	public Player(int client) {
		return view_as<Player>(client);
	}

	public void RankName(char name[64]) {
		iMod_GetUserTypeString(iMod_GetUserType(that), USER_TYPE_FULLNAME, name, sizeof(name));
	}

	property bool InformerBlock {
		public get() {
			return !!GetStaffArray()
		}
	}

	property bool Staff {
		public get() {
			char name[64];
			this.RankName(name);

			if (StrEqual(name, "Informer")) return !this.InformerBlock;
			return iMod_IsStaff(that);
		}
	}
}