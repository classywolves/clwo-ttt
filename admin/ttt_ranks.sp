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
#include <colorvariables>
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

const int rankCount = 11;

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
    "S"
};
bool rankStaff[rankCount] =
{
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

    CreateNative("TTT_Ranks_IsStaff", Native_IsStaff);
    CreateNative("GetRankName", Native_GetRankName);
    CreateNative("GetRankTag", Native_GetRankTag);
    CreateNative("GetPermission", Native_GetPermission);
    CreateNative("GetPlayerRank", Native_GetPlayerRank);

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
        if (IsValidClient(i))
        {
            playerRanks[i] = Db_GetPlayerRank(i);
        }
        else
        {
            playerRanks[i] = 0;
        }
    }
}

public void RegisterCmds()
{
    RegAdminCmd("admin_refreshranks", Command_RefreshRanks, ADMFLAG_RCON, "Refreshes the custom ranks from the config file.");
    RegConsoleCmd("sm_rankcheck", Command_Rank, "Outputs a users current rank.");
}

public void OnMapLoad()
{
    LoopClients(i)
    {
        if (IsValidClient(i))
        {
            playerRanks[i] = Db_GetPlayerRank(i);
        }
        else
        {
            playerRanks[i] = 0;
        }
    }
}

public void OnClientPutInServer(int client)
{
    playerRanks[client] = 0;
}

public void OnClientPostAdminCheck(int client)
{
    playerRanks[client] = Db_GetPlayerRank(client);
}

public Action Command_RefreshRanks(int client, int args)
{
    LoopClients(i)
    {
        if (IsValidClient(i))
        {
            playerRanks[i] = Db_GetPlayerRank(i);
        }
    }

    return Plugin_Handled;
}

public Action Command_Rank(int client, int args)
{
    TTT_Message(client, "{yellow}%N {default}has the rank: {lime}%s", client, rankNames[playerRanks[client]]);

    return Plugin_Handled;
}

public Action Command_DebugRank(int client, int args)
{
    char steamId[64];
    GetClientAuthId(client, AuthId_Steam2, steamId, 64);

    TTT_Message(client, "{yellow}%N {default}(%s) {default}has the rank: {lime}%i", client, steamId, rankNames[playerRanks[client]]);
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

public int Native_GetPlayerRank(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    return playerRanks[client];
}

public int Db_GetPlayerRank(int client)
{
    char steamId[64];
    GetClientAuthId(client, AuthId_Steam2, steamId, 64);

    char query[768];
    sourcebansDb.Format(query, sizeof(query), "SELECT `sb_admins`.`srv_group` as `rank` FROM `sb_admins` WHERE `sb_admins`.`authid` REGEXP '^STEAM_[0-9]:%s$' LIMIT 1;", steamId[8]);
    sourcebansDb.Query(DbCallback_GetPlayerRank, query, client);
}

public void DbCallback_GetPlayerRank(Database db, DBResultSet results, const char[] error, int client)
{
    if (results == null)
    {
        LogError("GetPlayerRankCallback: %s", error);
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
