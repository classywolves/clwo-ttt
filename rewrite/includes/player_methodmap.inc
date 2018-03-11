#if defined _player_methodmap_included
	#endinput
#endif
#define _player_methodmap_included

/* User Type */
enum UserType {
	USER_TYPE_COMMAND = 0,
	USER_TYPE_IS_STAFF,
	USER_TYPE_BROADCAST,
	USER_TYPE_GROUPNAME,
	USER_TYPE_FULLNAME,
	USER_TYPE_SCORENAME,
	USER_TYPE_CHATNAME,
	USER_TYPE_MULTI_TARGET
}

/* Upgrade Names */
#define UPGRADE_INVISIBILITY 	2

#define MAX_MESSAGE_LENGTH 		1024

#define that view_as<int>(this)

#define INNOCENT 1
#define TRAITOR 2
#define DETECTIVE 3

/*
 * Base CS:GO plugin requirements.
 */
#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <cstrike>

/*
 * Custom include files.
 */
#include <colorvariables>
#include <upgrades>
#include <helpers>
#include <imod>

native int TTT_GetClientRole(int client);

methodmap Player {
	public Player(int client) {
		return view_as<Player>(client);
	}

	public void RankName(char name[64]) {
		iMod_GetUserTypeString(iMod_GetUserType(that), USER_TYPE_FULLNAME, name, sizeof(name));
	}

	public void Auth(AuthIdType idType, char auth[64]) {
		GetClientAuthId(that, idType, auth, sizeof(auth));
	}

	public int Upgrade(int upgrade, int min, int max) {
		return Upgrade_Limit(Upgrade_GetPoints(that, upgrade), min, max);
	}

	public void Name(char name[64]) {
		GetClientName(that, name, sizeof(name))
	}

	public void Weapon(char weapon[64]) {
		GetClientWeapon(that, weapon, sizeof(weapon));
	}

	//public void Invisible(bool invisible) {
	//	if (invisible) {
	//		SetEntityRenderMode(that, RENDER_NONE); // RENDER_NONE
	//	} else {
	//		SetEntityRenderMode(that, RENDER_NORMAL); // RENDER_NORMAL
	//	}
	//}

	public void Msg(const char[] msg, any ...) {
		char buffer[MAX_MESSAGE_LENGTH];
		VFormat(buffer, sizeof(buffer), msg, 2);
		CPrintToChat(that, "{purple}[TTT] %s", msg);
	}

	public void Give(char weapon[64]) {
		GivePlayerItem(that, weapon);
	}

	property int Client {
		public get() {
			return that;
		}
	}

	property int Role {
		public get() {
			return TTT_GetClientRole(that);
		}
	}

	property bool Traitor {
		public get() {
			return this.Role == TRAITOR;
		}
	}

	property bool Innocent {
		public get() {
			return this.Role == INNOCENT;
		}
	}

	property bool Detective {
		public get() {
			return this.Role == DETECTIVE;
		}
	}

	property bool InformerBlock {
		public get() {
			return !!GetStaffArray()
		}
	}

	property bool Staff {
		public get() {
			return iMod_IsStaff(that);
		}
	}

	property bool ValidClient {
		public get() {
			if(!IsValidClient(that))
				return false;

			if(!IsPlayerAlive(that))
				return false;

			return true;
		}
	}
}