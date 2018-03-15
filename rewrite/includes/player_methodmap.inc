#if !defined _player_methodmap_include
#define _player_methodmap_include

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
#include <generics>
#include <imod>
#include <ttt>

#define MAX_MESSAGE_LENGTH			1024

#define UPGRADE_INVISIBILITY	2

#define INNOCENT 1
#define TRAITOR 2
#define DETECTIVE 3

#define that view_as<int>(this)

bool g_invisible[MAXPLAYERS + 1];
bool g_invulnerable[MAXPLAYERS + 1];
bool g_blockShoot[MAXPLAYERS + 1];

int g_errorTimeout[MAXPLAYERS + 1];

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

	public void Msg(const char[] msg, any ...) {
		char buffer[MAX_MESSAGE_LENGTH];
		VFormat(buffer, sizeof(buffer), msg, 2);
		CPrintToChat(that, "{purple}[TTT] %s", msg);
	}

	public bool Access(char[] rank, bool response = false) {
		bool access = iMod_HigherThenString(that, rank, true)

		if (!access) {
			this.Msg("{red}You do not have access to this command!")
		}

		return access;
	}

	public void Give(char weapon[64]) {
		GivePlayerItem(that, weapon);
	}

	public bool ErrorTimeout(int timeout) {
		int currentTime = GetTime();

		if (currentTime - g_errorTimeout[that] < timeout) {
			return true;
		}

		g_errorTimeout[that] = currentTime;
		return false;
	}

	property bool Invisible {
		public get() {
			return g_invisible[that];
		}

		public set(bool invisible) {
			if (invisible) {
				SetEntityRenderMode(that, RENDER_NONE); // RENDER_NONE
			} else {
				SetEntityRenderMode(that, RENDER_NORMAL); // RENDER_NORMAL
			}

			g_invisible[that] = invisible;
		}
	}

	// This also needs a handler within the plugin calling it to block damage.
	// It only stores whether a player is invulnerable or not.
	property bool Invulnerable {
		public get() {
			return g_invulnerable[that];
		}

		public set(bool invulnerable) {
			g_invulnerable[that] = invulnerable;
		}
	}

	// This also needs a handler within the plugin calling it to block shooting.
	// It only stores whether a player can shoot or not.
	property bool BlockShoot {
		public get() {
			return g_blockShoot[that];
		}

		public set(bool blockShoot) {
			g_blockShoot[that] = blockShoot;
		}
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
			// 
			return !!GetStaffCount()
		}
	}

	property bool Staff {
		public get() {
			// Returns true, even for blocked informers.
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

#endif