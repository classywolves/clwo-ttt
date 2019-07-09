#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <colorvariables>
#include <generics>
#include <ttt_messages>
#include <ttt_targeting>

public Plugin myinfo =
{
    name = "TTT Spectator Ban",
    author = "c0rp3n",
    description = "Allows for forcing players to the spectator team.",
    version = "1.0.0",
    url = ""
};

Database g_database;

bool g_specBanned[MAXPLAYERS + 1] = { false, ... };
Handle g_specBanExpireTimer[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

char sql_insertSpecBan[] = "INSERT INTO `spec_bans` (`auth_id`, `name`, `created`, `ends`, `length`, `reason`, `staff_auth`, `staff_name`) VALUES ('%s', '%s', '%d', '%d', '%d', '%s', '%s', '%s');";
char sql_selectSpecBan[] = "SELECT `ends` FROM `spec_bans` WHERE `auth_id` REGEXP '^STEAM_[0-9]:%s$' AND `ends` > '%d' AND `remove_type` IS NULL LIMIT 1;";
char sql_updateUnSpecBan[] = "UPDATE `spec_bans` SET `removed_by` = '%s', `remove_type` = 'U', `removed_on` = '%s', `ureason` = '%s' WHERE `auth_id` REGEXP '^STEAM_[0-9]:%s$' AND `ends` <= '%d' LIMIT 1;";
char sql_updateExpireBans[] = "UPDATE `spec_bans` SET `remove_type` = 'E', `removed_on` = '%d', `ureason` = 'Ban Expired' WHERE `ends` <= '%d' AND `remove_type` IS NULL;";

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("ttt_specBan");

    CreateNative("TTT_SpecBan", Native_SpecBan);

    return APLRes_Success;
}

public OnPluginStart()
{
    Database.Connect(DbCallback_Connect, "ttt");

    RegAdminCmd("sm_specban", Command_SpecBan, ADMFLAG_SLAY, "Locks a player to spectator for the given length of time.");
    RegAdminCmd("sm_unspecban", Command_UnSpecBan, ADMFLAG_SLAY, "Removes a spec ban on a player.");

    // Hook this to block joins when player is banned
    AddCommandListener(Command_BlockTeamChange, "chooseteam");
    AddCommandListener(Command_BlockTeamChange, "jointeam");

    // This is the only sane way to deal with CS:GO auto-assign and plugin conflicts as in CS:GO Team Limit Bypass
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    // This will catch anyone that gets swapped manually
    HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
    HookEvent("jointeam_failed", Event_JoinTeamFailed, EventHookMode_Pre);

    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);

    PrintToServer("[SBN] Loaded successfully");
}

public void OnClientAuthorized(int client, const char[] authid)
{
    char query[768];
    g_database.Format(query, sizeof(query), sql_selectSpecBan, authid[8], GetTime());
    g_database.Query(DbCallback_CheckSpecBan, query, GetClientUserId(client));
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsClientInGame(client) && GetClientTeam(client) != CS_TEAM_SPECTATOR)
	{
		if (GetSpecBanStatus(client))
		{
			#if defined _DEBUG
			LogMessage("%N spawned but is spec banned. Moving to spectator.", client);
			#endif

			EnforceSpecBan(client);
		}
	}

	return Plugin_Continue;
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    int userid = GetEventInt(event, "userid");
    int client = GetClientOfUserId(userid);
    int team = GetEventInt(event, "team");
    bool disconnected = GetEventBool(event, "disconnect");

    if (disconnected || !client || !IsClientInGame(client))
	{
		return Plugin_Continue;
	}

    if (team != CS_TEAM_SPECTATOR && GetSpecBanStatus(client))
    {
        EnforceSpecBan(client);
    }

    return Plugin_Continue;
}

public Action Event_JoinTeamFailed(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client && IsClientInGame(client))
	{
		int reason = GetEventInt(event, "reason");

		if (reason == 0)
		{
			// Check if client is banned and is blocked
			if (GetSpecBanStatus(client))
			{
				#if defined _DEBUG
				LogMessage("%N was unable to join a team due to limit. Forcing to Spectator team.");
				#endif

				ChangeClientTeam(client, CS_TEAM_SPECTATOR);

				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
    ExpireBans();

    return Plugin_Continue;
}

public int Native_SpecBan(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int target = GetNativeCell(2);
    int length = GetNativeCell(3);

    char reason[192];
    GetNativeString(4, reason, sizeof(reason));

    SpecBan(client, target, length, reason);

    return 0;
}

public int Native_UnSpecBan(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int target = GetNativeCell(2);

    char reason[192];
    GetNativeString(3, reason, sizeof(reason));

    UnSpecBan(client, target, reason);

    return 0;
}

public Action Command_SpecBan(int client, int args)
{
    if (args < 2)
    {
        TTT_Error(client, "Invalid Usage: sm_specban <target name> <length> [reason]");
        return Plugin_Handled;
    }

    char buffer[64];
    GetCmdArg(1, buffer, MAX_NAME_LENGTH);
    int target = TTT_Target(buffer, client, true, false, false);

    GetCmdArg(2, buffer, 16);
    int length = StringToInt(buffer);

    char reason[192] = "";
    for (int i = 3; i <= args; i++)
    {
        GetCmdArg(i, buffer, 64);
        Format(reason, 192, "%s %s", reason, buffer);
    }

    SpecBan(client, target, length, reason);

    return Plugin_Handled;
}

public Action Command_UnSpecBan(int client, int args)
{
    if (args < 1)
    {
        TTT_Error(client, "Invalid Usage: sm_specban <target name> [reason]");
        return Plugin_Handled;
    }

    char buffer[64];
    GetCmdArg(1, buffer, sizeof(buffer));
    int target = TTT_Target(buffer, client, true, false, false);

    char reason[192] = "";
    for (int i = 2; i <= args; i++)
    {
        GetCmdArg(i, buffer, sizeof(buffer));
        Format(reason, sizeof(reason), "%s %s", reason, buffer);
    }

    UnSpecBan(client, target, reason);

    return Plugin_Handled;
}

public Action Command_BlockTeamChange(int client, const char[] command, int args)
{
    // Check to see if we should continue (not a listen server, is in game, not a bot, if cookies are cached, and we're enabled)
    if(!IsValidClient(client))
    {
        return Plugin_Continue;
    }

    if (GetSpecBanStatus(client))
    {
        return Plugin_Stop;
    }

    return Plugin_Continue;
}

public void DbCallback_Connect(Database db, const char[] error, any data)
{
    if (db == null)
    {
        LogError("Db_ConnectCallback: %s", error);
        return;
    }

    g_database = db;

    g_database.SetCharset("utf8");

    ExpireBans();
}

public void DbCallback_Expire(Database db, DBResultSet results, const char[] error, any data)
{
    if (results == null)
    {
        LogError("DbCallback_Expire: %s", error);
        return;
    }

    LoopValidClients(i)
    {
        char steamId[32];
        GetClientAuthId(i, AuthId_Steam2, steamId, sizeof(steamId));

        char query[768];
        g_database.Format(query, sizeof(query), sql_selectSpecBan, steamId[8], GetTime());
        g_database.Query(DbCallback_CheckSpecBan, query, GetClientUserId(i));
    }
}

public void DbCallback_CheckSpecBan(Database db, DBResultSet results, const char[] error, int userid)
{
    if (results == null)
    {
        LogError("DbCallback_CheckSpecBan: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);
    if (results.FetchRow())
    {
        int ends = results.FetchInt(0);

        g_specBanned[client] = true;
        g_specBanExpireTimer[client] = CreateTimer(float(ends - GetTime()), Timer_SpecBanExpire, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    }
    else
    {
        g_specBanned[client] = false;
    }
}

public void DbCallback_InsertSpecBan(Database db, DBResultSet results, const char[] error, DataPack data)
{
    if (results == null)
    {
        LogError("DbCallback_InsertSpecBan: %s", error);
        return;
    }

    data.Reset();
    int target = GetClientOfUserId(data.ReadCell());
    int admin = GetClientOfUserId(data.ReadCell());
    int length = data.ReadCell();
    delete data;

    CPrintToChatAdmins(ADMFLAG_GENERIC, "{purple}[TTT] {yellow}%N has been spec banned for %d by %N.", target, length, admin);
    g_specBanned[target] = false;
}

public void DbCallback_UnSpecBan(Database db, DBResultSet results, const char[] error, DataPack data)
{
    if (results == null)
    {
        LogError("DbCallback_UnSpecBan: %s", error);
        return;
    }

    data.Reset();
    int target = GetClientOfUserId(data.ReadCell());
    int admin = GetClientOfUserId(data.ReadCell());
    delete data;

    CPrintToChatAdmins(ADMFLAG_GENERIC, "{purple}[TTT] {yellow}%N has been unspec banned by %N.", target, admin);
    g_specBanned[target] = false;
}

public Action Timer_SpecBanExpire(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (IsValidClient(client))
    {
        CPrintToChatAdmins(ADMFLAG_GENERIC, "{purple}[TTT] {yellow}%N's spec ban has expired.", client);
        g_specBanned[client] = false;
    }

    return Plugin_Handled;
}

void ExpireBans()
{
    int time = GetTime();
    char query[768];
    g_database.Format(query, sizeof(query), sql_updateExpireBans, time, time);
    g_database.Query(DbCallback_Expire, query);
}

void SpecBan(int client, int target, int length, const char[] reason)
{
    char steamId[32];
    char name[64];
    GetClientAuthId(target, AuthId_Steam2, steamId, sizeof(steamId));
    GetClientName(target, name, sizeof(name));

    int created = GetTime();
    int ends = created + length;

    char adminId[32];
    char adminName[64];
    GetClientAuthId(client, AuthId_Steam2, adminId, sizeof(adminId));
    GetClientName(client, adminName, sizeof(adminName));

    DataPack data = new DataPack();
    data.WriteCell(target);
    data.WriteCell(client);
    data.WriteCell(length);

    char query[768];
    g_database.Format(query, sizeof(query), sql_insertSpecBan, steamId, name, created, ends, length, reason, adminId, adminName);
    g_database.Query(DbCallback_InsertSpecBan, query, data);
}

void UnSpecBan(int client, int target, const char[] reason)
{
    char targetId[32];
    GetClientAuthId(target, AuthId_Steam2, targetId, sizeof(targetId));

    char adminId[32];
    GetClientAuthId(client, AuthId_Steam2, adminId, sizeof(adminId));

    int time = GetTime();

    DataPack data = new DataPack();
    data.WriteCell(target);
    data.WriteCell(client);

    char query[768];
    g_database.Format(query, sizeof(query), sql_updateUnSpecBan, adminId, time, reason, targetId[8], time);
    g_database.Query(DbCallback_UnSpecBan, query, data);
}

void EnforceSpecBan(int client)
{
    if (IsPlayerAlive(client))
    {
        StripAllWeapons(client);

        ForcePlayerSuicide(client);
    }

    ChangeClientTeam(client, CS_TEAM_SPECTATOR);

    TTT_Message(client, "You are currently spec banned, you can ask the admins why this is the case by putting an '@' infront of your message.");
}

bool GetSpecBanStatus(int client)
{
    return g_specBanned[client];
}

void StripAllWeapons(int client)
{
    int weaponIndex = -1;
    for (int i = CS_SLOT_PRIMARY; i < CS_SLOT_GRENADE + 1; i++)
    {
        weaponIndex = -1;
        while ((weaponIndex = GetPlayerWeaponSlot(client, i)) != -1)
        {
            RemovePlayerItem(client, weaponIndex);
            AcceptEntityInput(weaponIndex, "Kill");
        }
    }
}
