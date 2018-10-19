#if defined _player_methodmap_include
  #endinput
#endif
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
#include <ttt>
#include <upgrades>
#include <generics>
#include <ttt_ranks>
#include <ttt_shop>

#define MAX_MESSAGE_LENGTH			1024
#define MAX_MSAY_LENGTH					255
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

UserMsg g_FadeUserMsgId = INVALID_MESSAGE_ID;

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

			StrCat(formatted, sizeof(formatted), "{purple}[TTT] {yellow}");
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

    public bool RayTrace(float pos[3]) {
        float vOrigin[3], vAngles[3];

        GetClientEyePosition(that, vOrigin);
        GetClientEyeAngles(that, vAngles);

        Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
        if(TR_DidHit(trace)) {
            TR_GetEndPosition(pos, trace);
            CloseHandle(trace);

            return true;
        }

        CloseHandle(trace);
        return false;
    }

	public void GetRankName(char rankName[64], int type) {
		GetRankName(GetPlayerRank(that), rankName, type);
	}

	public void Pos(float pos[3]) {
		GetClientEyePosition(that, pos);
	}

    public void SetPos(float pos[3]) {
		TeleportEntity(that, pos, NULL_VECTOR, NULL_VECTOR);
	}

	public Player TargetOne(char target[128], bool respond = false, bool immunity = true) {
		//int targetIndex = FindTarget(that, target, true, immunity);

		int targets[MAXPLAYERS];

		char targetName[256];
		bool tnIsMl;

		int targetIndex = ProcessTargetString(target, that, targets, sizeof(targets), COMMAND_FILTER_NO_IMMUNITY | COMMAND_FILTER_NO_MULTI, targetName, sizeof(targetName), tnIsMl)

		if (targetIndex == 1) {
			return view_as<Player>(targets[0]);
		}

		if (respond) {
			if (targetIndex == -1) this.Error("No targets were found.");
			if (targetIndex == -2) this.Error("Target is not alive.");
			if (targetIndex == -3) this.Error("Target is not dead.");
			if (targetIndex == -4) this.Error("Target is not in game.");
			if (targetIndex == -5) this.Error("Target is immune.");
			if (targetIndex == -6) this.Error("Target is not human.");
			if (targetIndex == -7) this.Error("Ambiguous target string.");
		}

		return view_as<Player>(targetIndex);
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
		bool activeInformer = GetPlayerRank(that) == RANK_INFORMER;

		if (activeInformer && !GetActiveStaffCount()) {
			return true;
		}

		if (!activeInformer) {
			char msg[255];
			Format(msg, sizeof(msg), "Access denied, not an informer.");
			this.Error(msg);
		}

		if (GetActiveStaffCount()) {
			char msg[255];
			Format(msg, sizeof(msg), "Access denied, %i staff active.", GetActiveStaffCount());
			this.Error(msg);
		}

		return false;
	}

	public bool Access(int rank, bool response = false) {
		bool access = GetPermission(that, rank);

		if (!access && response) {
			this.Msg("{red}You do not have access to this command!");
		}

		return access;
	}

	public void SendPanelMsg(char[] title, char[] message) {
		ReplaceString(message, MAX_MSAY_LENGTH, "\\n", "\n");

		Panel panel = new Panel();
		panel.SetTitle(title);
		panel.DrawItem("", ITEMDRAW_SPACER);
		panel.DrawText(message);
		panel.DrawItem("", ITEMDRAW_SPACER);
		panel.CurrentKey = GetMaxPageItems(panel.Style);
		panel.DrawItem("Exit", ITEMDRAW_CONTROL);

		if(IsValidClient(that)) {
			panel.Send(that, HandlerDoNothing, 10);
		}

		delete panel;
	}

	// Is this expected usage for natives within methodmaps?
	// native void AddSpeed(float speed, float maxSpeed);

	public void Give(char weapon[64]) {
		GivePlayerItem(that, weapon);
	}

	public void Mute(int time, const char[] reason) {
		SourceComms_SetClientMute(that, true, time, true, reason);
	}

	public void CSay(char[] msg) {
		PrintCenterText(that, msg);
	}

	public void Gag(int time, const char[] reason) {
		SourceComms_SetClientGag(that, true, time, true, reason);
	}

	public void Kick(const char[] reason) {
		KickClient(that, reason);
	}

	public void SetScreenColor(int color[4], int duration, int holdTime, int flags)
	{
		if (g_FadeUserMsgId == INVALID_MESSAGE_ID)
		{
			g_FadeUserMsgId = GetUserMessageId("Fade");
		}

		int clients[2];
		clients[0] = that;

		Handle message = StartMessageEx(g_FadeUserMsgId, clients, 1);
		if (GetUserMessageType() == UM_Protobuf)
		{
			PbSetInt(message, "duration", duration);
			PbSetInt(message, "hold_time", holdTime);
			PbSetInt(message, "flags", flags);
			PbSetColor(message, "clr", color);
		}
		else
		{
			BfWriteShort(message, duration);
			BfWriteShort(message, holdTime);
			BfWriteShort(message, flags);
			BfWriteByte(message, color[0]);
			BfWriteByte(message, color[1]);
			BfWriteByte(message, color[2]);
			BfWriteByte(message, color[3]);
		}

		EndMessage();
	}

	property int Rank {
		public get() {
			return GetPlayerRank(that);
		}
	}

	property bool Informer {
		public get() {
			return GetPlayerRank(that) == RANK_INFORMER;
		}
	}

	property bool Found {
		public get() {
			return TTT_GetFoundStatus(that);
		}
		public set(bool found) {
			TTT_SetFoundStatus(that, found);
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

	property bool NightVision {
		public get() {
			return GetEntProp(that, Prop_Send, "m_bNightVisionOn") == 1;
		}

		public set(bool nightVision) {
			if (nightVision) {
				SetEntProp(that, Prop_Send, "m_bNightVisionOn", 1); // Night Vision On
			} else {
				SetEntProp(that, Prop_Send, "m_bNightVisionOn", 0); // Night Vision Off
			}
		}
	}

	property int Armour {
		public get() {
			return GetEntProp(that, Prop_Data, "m_ArmorValue");
		}
		public set(int armour) {
			SetEntProp(that, Prop_Data, "m_ArmorValue", armour, 1);
		}
	}

	property int Health {
		public get() {
			return GetClientHealth(that);
		}
		public set(int health) {
			SetEntityHealth(that, health)
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

	public bool HasCommandAccess (char commandName[64], int defaultFlags) {
		return CheckCommandAccess(that, commandName, defaultFlags);
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
		public set(int team) {
			CS_SwitchTeam(that, team);
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
			return GetPlayerRank(that) >= RANK_INFORMER;
		}
	}

	property bool Alive {
		public get() {
			return IsPlayerAlive(that);
		}
		public set(bool alive) {
			if (alive) {
				ForcePlayerSuicide(that);
				TTT_SetFoundStatus(that, true);
			} else {
				CS_RespawnPlayer(that);
				TTT_SetFoundStatus(that, false);
			}
		}
	}

	property int Credits {
		public get() {
			return TTT_GetClientCredits(that);
		}
		public set(int amount) {
			TTT_SetClientCredits(that, amount);
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

public int HandlerDoNothing(Menu menu, MenuAction action, int param1, int param2) {
	// Do nothing.  It's really exciting.
	return;
}

public bool TraceEntityFilterPlayer(entity, contentsMask)
{
    return entity > MaxClients;
}
