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
#include <sourcecomms>
#include <upgrades>
#include <generics>
#include <imod>
#include <ttt>

#define MAX_MESSAGE_LENGTH			1024
#define ERROR_TIMEOUT						2

#define UPGRADE_INVISIBILITY		2

#define INNOCENT 								1
#define TRAITOR 								2
#define DETECTIVE 							3

#define that view_as<int>(this)

bool g_invisible[MAXPLAYERS + 1];
bool g_invulnerable[MAXPLAYERS + 1];
bool g_blockShoot[MAXPLAYERS + 1];

int g_traitorKills[MAXPLAYERS + 1];
int g_errorTimeout[MAXPLAYERS + 1];

Handle cookieInnocentWins;
Handle cookieDetectiveWins;
Handle cookieTraitorWins;
Handle cookieInnocentLosses;
Handle cookieDetectiveLosses;
Handle cookieTraitorLosses;

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
		GetClientName(that, name, sizeof(name));
	}

	public void Msg(const char[] msg, any ...) {
			char buffer[MAX_MESSAGE_LENGTH], formatted[MAX_MESSAGE_LENGTH];
			VFormat(buffer, sizeof(buffer), msg, 2);

			StrCat(formatted, sizeof(formatted), "{purple}[TTT]");
			StrCat(formatted, sizeof(formatted), buffer);

			CPrintToChat(that, formatted);
	}

	public bool ErrorTimeout(int timeout) {
		int currentTime = GetTime();

		if (currentTime - g_errorTimeout[that] < timeout) {
			return true;
		}

		g_errorTimeout[that] = currentTime;
		return false;
	}

	public void Error(const char[] msg, any ...) {
		if (!this.ErrorTimeout(ERROR_TIMEOUT)) {
			char buffer[MAX_MESSAGE_LENGTH], formatted[MAX_MESSAGE_LENGTH];
			VFormat(buffer, sizeof(buffer), msg, 2);

			StrCat(formatted, sizeof(formatted), "{purple}[TTT] {red}");
			StrCat(formatted, sizeof(formatted), buffer);

			CPrintToChat(that, formatted);
		}
	}

	public int GetCookieInt(Handle cookie, int defaultValue) {
		char cookieValue[128];
		GetClientCookie(that, cookie, cookieValue, sizeof(cookieValue));
		if (cookieValue[0] == '\0') return defaultValue;
		return StringToInt(cookieValue);
	}

	public int SetCookieInt(Handle cookie, int value) {
		char cookieValue[128];
		IntToString(value, cookieValue, sizeof(cookieValue));
		SetClientCookie(that, cookie, cookieValue);
	}

	property int TraitorWins {
		public get() { return this.GetCookieInt(cookieTraitorWins, 0); }
		public set(int wins) { this.SetCookieInt(cookieTraitorWins, wins); }
	}

	property int InnocentWins {
		public get() { return this.GetCookieInt(cookieInnocentWins, 0); }
		public set(int wins) { this.SetCookieInt(cookieInnocentWins, wins); }
	}

	property int DetectiveWins {
		public get() { return this.GetCookieInt(cookieDetectiveWins, 0); }
		public set(int wins) { this.SetCookieInt(cookieDetectiveWins, wins); }
	}

	property int TraitorLosses {
		public get() { return this.GetCookieInt(cookieTraitorLosses, 0); }
		public set(int losses) { this.SetCookieInt(cookieTraitorLosses, losses); }
	}

	property int InnocentLosses {
		public get() { return this.GetCookieInt(cookieInnocentLosses, 0); }
		public set(int losses) { this.SetCookieInt(cookieInnocentLosses, losses); }
	}

	property int DetectiveLosses {
		public get() { return this.GetCookieInt(cookieDetectiveLosses, 0); }
		public set(int losses) { this.SetCookieInt(cookieDetectiveLosses, losses); }
	}

	public int Target(char target[128], int targets[MAXPLAYERS], char target_name[128], bool alive, bool immunity) {
		int filter = (alive ? COMMAND_FILTER_ALIVE : 0) | (immunity ? 0 : COMMAND_FILTER_NO_IMMUNITY);
		bool translation;

		int response = ProcessTargetString(target, that, targets, sizeof(targets), filter, target_name, sizeof(target_name), translation);

		if (response == 0 || response == -5) {
			this.Error("No targets were found.");
			return 0;
		} else if (response == -7) {
			this.Error("Partial name had too many targets.");
			return 0;
		}

		return response;
	}

	public void Pos(float pos[3]) {
		GetClientEyePosition(that, pos);
	}

	public Player TargetOne(char target[128], bool respond = false, bool immunity = true) {
		int targetIndex = FindTarget(that, target, true, immunity);

		if (respond && targetIndex == -1) {
			this.Error("No targets were found.");
		}

		return Player(targetIndex);
	}

	public void SetName(char name[64]) {
		// Currently, this does not work in CS:GO.  So we're being awkward
		// and using the command version.
		//SetClientName(that, name);

		char command[128];
		Format(command, sizeof(command), "sm_rename #%i %s", GetClientUserId(that), name);
		ServerCommand(command);
	}

	public void Weapon(char weapon[64]) {
		GetClientWeapon(that, weapon, sizeof(weapon));
	}

	// This command returns true when only informers are on a non-spectator team.
	public bool ActiveInformer(bool response = true) {
		// A good addition to this function would be some way for staff to specify that they want
		// the informers help for a command.  A similar system to "adopt" on JB.
		char rankName[64];
		this.RankName(rankName);

		if (StrEqual(rankName, "informer") && GetActiveStaffCount()) {
			return true;
		}

		return false;
	}

	public bool Access(char[] rank, bool response = false) {
		bool access = iMod_HigherThenString(that, rank, true)

		if (!access && response) {
			this.Msg("{red}You do not have access to this command!")
		}

		return access;
	}

	// Is this expected usage for natives within methodmaps?
	// native void AddSpeed(float speed, float maxSpeed);

	public void Give(char weapon[64]) {
		GivePlayerItem(that, weapon);
	}

	public void Mute(int time, const char[] reason) {
		SourceComms_SetClientMute(that, true, time, true, reason);
	}

	public void Gag(int time, const char[] reason) {
		SourceComms_SetClientGag(that, true, time, true, reason);
	}

	public void Kick(const char[] reason) {
		KickClient(that, reason);
	}

	property bool Alive {
		public get() {
			return IsPlayerAlive(that);			
		}
	}

	property int TraitorKills {
		public get() {
			return g_traitorKills[that];
		}
		public set(int kills) {
			g_traitorKills[that] = kills;
		}
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

	property bool Muted {
		public get() {
			return SourceComms_GetClientMuteType(that) != bNot
		}
	}

	property bool Gagged {
		public get() {
			return SourceComms_GetClientGagType(that) != bNot
		}
	}

	property int Team {
		public get() {
			return GetClientTeam(that);
		}
	}

	property bool CounterTerrorist {
		public get() {
			return this.Team == CS_TEAM_CT;
		}
	}

	property bool Terrorist {
		public get() {
			return this.Team == CS_TEAM_T;
		}
	}

	property bool Spectator {
		public get() {
			return this.Team == CS_TEAM_SPECTATOR;
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