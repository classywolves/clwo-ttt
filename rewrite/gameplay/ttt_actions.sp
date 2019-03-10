#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <ttt>
#include <generics>

public Plugin myinfo =
{
    name = "TTT Actions",
    author = "c0rp3n",
    description = "TTT Actions logger.",
    version = "1.0.0",
    url = ""
};

Database actionsDb;

int goodActions[MAXPLAYERS + 1] = { 0, ... };
int badActions[MAXPLAYERS + 1] = { 0, ... };

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
    RegPluginLibrary("ttt_actions");

    CreateNative("Actions_GetGoodActions", Native_GetGoodActions);
    CreateNative("Actions_GetBadActions", Native_GetBadActions);
}

public OnPluginStart()
{
    LoadTranslations("common.phrases");

    HookEvent("round_end", Event_OnRoundEnd, EventHookMode_Post);
    Database.Connect(DbCallback, "actions");

    PrintToServer("[ACT] Loaded succcessfully");
}

public void DbCallback(Database db, const char[] error, any data) {
    if (db == null) {
        LogError("DbCallback: %s", error);
        return;
    }

    actionsDb = db;

    actionsDb.SetCharset("utf8");
    LoopValidClients(i)
    {
        char steamId[32];
        GetClientAuthId(i, AuthId_Steam2, steamId, 32);

        char query[768];
        actionsDb.Format(query, sizeof(query), "SELECT `good_actions`, `bad_actions` FROM `actions` WHERE `auth_id` REGEXP '^STEAM_[0-9]:%s$' LIMIT 1;", steamId[8]);
        actionsDb.Query(SelectActionsCallback, query, i);
    }
}

public void OnClientAuthorized(int client, const char[] auth)
{
    char steamId[32];
    GetClientAuthId(client, AuthId_Steam2, steamId, 32);

    char query[768];
    actionsDb.Format(query, sizeof(query), "SELECT `good_actions`, `bad_actions` FROM `actions` WHERE `auth_id` REGEXP '^STEAM_[0-9]:%s$' LIMIT 1;", steamId[8]);
    actionsDb.Query(SelectActionsCallback, query, client);
}

public void TTT_OnClientDeath(int victim, int attacker)
{
    int attackerRole = TTT_GetClientRole(attacker);
    int victimRole = TTT_GetClientRole(victim);
    if (attackerRole == victimRole)
    {
        badActions[attacker]++;
    }
    else if (attackerRole == TTT_TEAM_TRAITOR || victimRole == TTT_TEAM_TRAITOR)
    {
        goodActions[attacker]++;
    }
    else
    {
        badActions[attacker]++;
    }
}

public Action Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    LoopValidClients(i)
    {
        char steamId[32];
        GetClientAuthId(i, AuthId_Steam2, steamId, 32);

        char query[768];
        actionsDb.Format(query, sizeof(query), "UPDATE `actions` SET `good_actions` = '%d', `bad_actions` = '%d' WHERE `auth_id` REGEXP '^STEAM_[0-9]:%s$' LIMIT 1;", goodActions[i], badActions[i], steamId[8]);
        actionsDb.Query(UpdateActionsCallback, query);
    }
}

public void SelectActionsCallback(Database db, DBResultSet results, const char[] error, int client)
{
    if (results == null) {
        LogError("SelectActionsCallback: %s", error);
        return;
    }

    if (results.FetchRow())
    {
        goodActions[client] = results.FetchInt(0);
        badActions[client] = results.FetchInt(1);
    }
    else
    {
        goodActions[client] = 0;
        badActions[client] = 0;

        char steamId[32];
        GetClientAuthId(client, AuthId_Steam2, steamId, 32);

        char query[768];
        actionsDb.Format(query, sizeof(query), "INSERT INTO `actions` (`id`, `auth_id`, `good_actions`, `bad_actions`) VALUES (NULL, '%s', '0', '0');", steamId);
        actionsDb.Query(InsertActionsCallback, query);
    }
}

public void InsertActionsCallback(Database db, DBResultSet results, const char[] error, any data)
{
    if (results == null) {
        LogError("InsertActionsCallback: %s", error);
        return;
    }
}

public void UpdateActionsCallback(Database db, DBResultSet results, const char[] error, any data)
{
    if (results == null) {
        LogError("UpdateActionsCallback: %s", error);
        return;
    }
}

public int Native_GetGoodActions(Handle plugin, int numParams)
{
    if (numParams != 1)
    {
        PrintToServer("Warning, Native_GetGoodActions was not called correctly.");
        return -1;
    }

    int client = GetNativeCell(1);
    return goodActions[client];
}

public int Native_GetBadActions(Handle plugin, int numParams)
{
    if (numParams != 1)
    {
        PrintToServer("Warning, Native_GetBadActions was not called correctly.");
        return -1;
    }

    int client = GetNativeCell(1);
    return badActions[client];
}
