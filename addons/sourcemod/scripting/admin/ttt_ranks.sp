#pragma semicolon 1

/*
* Base CS:GO plugin requirements.
*/
#include <sourcemod>
#include <sdktools>
#include <cstrike>

/*
* Custom include files.
*/
#include <colorlib>
#include <generics>
#include <ttt_messages>

public Plugin myinfo = {
    name = "TTT Ranks",
    author = "Popey & iNilo & c0rp3n",
    description = "TTT Custom rank and access system.",
    version = "1.0.1",
    url = ""
};

Database sourcebansDb;

const int rankCount = 12;

char rankNames[rankCount][32] =
{   "Normal",
    "VIP",
    "Informer",
    "Trial Moderator",
    "Moderator",
    "Senior Moderator",
    "Guardian",
    "Admin",
    "Senior Admin",
    "Developer",
    "Board",
    "Senator"
};
char chatTags[rankCount][16] =
{
    "",
    "♥",
    "+",
    "T.MOD",
    "M",
    "S.MOD",
    "G",
    "A",
    "SA",
    "Δ",
    "B",
    "S"
};
bool rankStaff[rankCount] =
{
    false,
    false,
    false,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true
};

int playerRanks[MAXPLAYERS + 1] = { 0, ... };

public OnPluginStart()
{
    LoadTranslations("common.phrases");

    RegisterCmds();
    DbInit();

    PrintToServer("[RNK] Loaded successfully");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("ttt_ranks");

    CreateNative("Ranks_IsStaff", Native_IsStaff);
    CreateNative("Ranks_GetRankName", Native_GetRankName);
    CreateNative("Ranks_GetRankTag", Native_GetRankTag);
    CreateNative("Ranks_GetPermission", Native_GetPermission);
    CreateNative("Ranks_GetClientRank", Native_GetClientRank);

    return APLRes_Success;
}

public void DbInit()
{
    Database.Connect(DbInitCallback, "sourcebans");
}

public void DbInitCallback(Database db, const char[] error, any data)
{
    if (db == null)
    {
        LogError("DbInitCallback: %s", error);
        return;
    }

    sourcebansDb = db;
    sourcebansDb.SetCharset("utf8");

    LoopClients(i)
    {
        playerRanks[i] = 0;
        if (IsValidClient(i))
        {
            Db_GetClientRank(i);
        }
    }
}

public void RegisterCmds()
{
    RegAdminCmd("sm_refreshranks", Command_RefreshRanks, ADMFLAG_RCON, "sm_refreshranks - Refetches the ranks from the database.");
    RegConsoleCmd("sm_rankcheck", Command_Rank, "sm_rankcheck - Outputs a users current rank.");
}

public void OnMapLoad()
{
    LoopClients(i)
    {
        playerRanks[i] = 0;
        if (IsValidClient(i))
        {
            Db_GetClientRank(i);
        }
    }
}

public void OnClientPutInServer(int client)
{
    playerRanks[client] = 0;
}

public void OnClientPostAdminCheck(int client)
{
    Db_GetClientRank(client);
}

public Action Command_RefreshRanks(int client, int args)
{
    LoopClients(i)
    {
        if (IsValidClient(i))
        {
            Db_GetClientRank(i);
        }
    }

    return Plugin_Handled;
}

public Action Command_Rank(int client, int args)
{
    CPrintToChat(client, TTT_MESSAGE ... "{yellow}%N {default}has the rank: {lime}%s", client, rankNames[playerRanks[client]]);

    return Plugin_Handled;
}

public Action Command_DebugRank(int client, int args)
{
    char steamId[64];
    GetClientAuthId(client, AuthId_Steam2, steamId, 64);

    CPrintToChat(client, TTT_MESSAGE ... "{yellow}%N {default}(%s) {default}has the rank: {lime}%i", client, steamId, rankNames[playerRanks[client]]);
}

public int Native_IsStaff(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    return rankStaff[playerRanks[client]];
}

public int Native_GetRankName(Handle plugin, int numParams)
{
    int rank = GetNativeCell(1);

    SetNativeString(2, rankNames[rank], 32, false);

    return 0;
}

public int Native_GetRankTag(Handle plugin, int numParams)
{
    int rank = GetNativeCell(1);

    SetNativeString(2, chatTags[rank], 16, false);

    return 0;
}

public int Native_GetPermission(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int rank = GetNativeCell(2);

    return playerRanks[client] >=  rank;
}

public int Native_GetClientRank(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    return playerRanks[client];
}

public void Db_GetClientRank(int client)
{
    char steamId[64];
    GetClientAuthId(client, AuthId_Steam2, steamId, 64);

    char query[768];
    sourcebansDb.Format(query, sizeof(query), "SELECT `sb_admins`.`srv_group` as `rank` FROM `sb_admins` WHERE `sb_admins`.`authid` REGEXP '^STEAM_[0-9]:%s$' LIMIT 1;", steamId[8]);
    sourcebansDb.Query(DbCallback_GetClientRank, query, client);
}

public void DbCallback_GetClientRank(Database db, DBResultSet results, const char[] error, int client)
{
    if (results == null)
    {
        LogError("GetClientRankCallback: %s", error);
        return;
    }

    if (results.FetchRow())
    {
        char rankName[64];
        results.FetchString(0, rankName, 64);
        if (rankName[0] == 0)
        {
            playerRanks[client] = 0;
        }

        for (int rank = 1; rank < 11; rank++)
        {
            if (strcmp(rankName, rankNames[rank], true) == 0)
            {
                playerRanks[client] = rank;
                return;
            }
        }
    }

    playerRanks[client] = 0;
}
