/*
* Base CS:GO plugin requirements.
*/
#include <sourcemod>
#include <sdktools>
#include <cstrike>

/*
* Custom include files.
*/
#include <generics>
#include <datapack>

/*
* Custom methodmaps.
*/
#include <player_methodmap>

public Plugin myinfo = {
    name = "TTT Ranks",
    author = "Popey & iNilo & c0rp3n",
    description = "TTT Custom rank and access system.",
    version = "1.0.1",
    url = ""
};

Database sourcebansDb;

/*
enum struct Rank
{
    char command[32];
    bool isStaff;
    char name[32];
    char chatTag[16];
};

Rank ranks[MAX_USER_RANKS] =
{
    {   "rank_normal",      false,       "Normal",           "",        },
    {   "rank_vip",         false,       "VIP",              "♥",       },
    {   "rank_informer",    true,        "Informer",         "+",       },
    {   "rank_trialmod",    true,        "Trial Moderator",  "T.Mod",   },
    {   "rank_moderator",   true,        "Moderator",        "M",       },
    {   "rank_seniormod",   true,        "Senior Moderator", "S.Mod",   },
    {   "rank_guardian",    true,        "Guardian",         "G",       },
    {   "rank_admin",       true,        "Admin",            "A",       },
    // SteamID Ranks.
    {   "rank_senioradmin", true,        "Senior Admin",     "S. Admin" },
    {   "rank_developer",   true,        "Developer",        "Δ"        },
    {   "rank_senator",     true,        "Senator",          "S"        }
};
*/

char userRanks[MAX_USER_RANKS][MAX_USER_TYPES][64] = {
    //  "command",          "is staff", "name",             "score name", "chat name", "dev name"
    {   "rank_normal",      "0",        "Normal",           "",           "",          "pleb"     },
    {   "rank_vip",         "0",        "VIP",              "VIP",        "♥",         "vip"      },
    {   "rank_informer",    "1",        "Informer",         "+",          "+",         "informer" },
    {   "rank_trialmod",    "1",        "Trial Moderator",  "Trial Mod",  "T.Mod",     "tmod"     },
    {   "rank_moderator",   "1",        "Moderator",        "Moderator",  "M",         "mod"      },
    {   "rank_seniormod",   "1",        "Senior Moderator", "Sen. Mod",   "S.Mod",     "smod"     },
    {   "rank_guardian",    "1",        "Guardian",         "Guarian",    "G",         "guardian" },
    {   "rank_admin",       "1",        "Admin",            "Admin",      "A",         "admin"    },
    // SteamID Ranks.
    {   "rank_senioradmin", "1",        "Senior Admin",     "Sen. Admin", "S. Admin",  "sadmin"   },
    {   "rank_developer",   "1",        "Developer",        "Dev",        "Δ",         "dev"      },
    {   "rank_senator",     "1",        "Senator",          "Senator",    "S",         "senator"  }
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

    CreateNative("TTT_Ranks_IsStaff", Native_IsStaff)
    CreateNative("GetRankName", Native_GetRankName);
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
        Player player = view_as<Player>(i);
        if (player.ValidClient)
        {
            playerRanks[i] = Internal_GetPlayerRank(i);
        }
        else
        {
            playerRanks[i] = 0;
        }
    }
}

public void RegisterCmds()
{
    RegConsoleCmd("sm_refreshranks", Command_RefreshRanks, "Refreshes the custom ranks from the config file.");
    RegConsoleCmd("sm_rankcheck", Command_Rank, "Outputs a users current rank.");
}

public void OnMapLoad()
{
    LoopClients(i)
    {
        Player player = view_as<Player>(i);
        if (player.ValidClient)
        {
            playerRanks[i] = Internal_GetPlayerRank(i);
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
    playerRanks[client] = Internal_GetPlayerRank(client);
}

public Action Command_RefreshRanks(int client, int args)
{
    if (playerRanks[client] < RANK_ADMIN)
    {
        CPrintToChatAll("{purple}[TTT] {red}You do not have access to this command!");
        return Plugin_Handled;
    }

    LoopClients(i)
    {
        Player player = view_as<Player>(i);
        if (player.ValidClient)
        {
            playerRanks[i] = Internal_GetPlayerRank(i);
        }
    }

    return Plugin_Handled;
}

public Action Command_Rank(int client, int args)
{
    Player player = view_as<Player>(client);
    char steamId[64];
    player.Auth(AuthId_Steam2, steamId);

    CPrintToChatAll("{purple}[TTT] {blue}%N {default}(%s) {yellow}has the rank: {green}%i", client, steamId, playerRanks[client]);

    return Plugin_Handled;
}

public int Native_IsStaff(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    return playerRanks[client] >= RANK_INFORMER;
}

public int Native_GetRankName(Handle plugin, int numParams)
{
    int rank = GetNativeCell(1);
    int type = GetNativeCell(3);

    SetNativeString(2, userRanks[rank][type], 64, false);
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

public int Internal_GetPlayerRank(int client)
{
    Player player = view_as<Player>(client);

    char steamId[64];
    player.Auth(AuthId_Steam2, steamId);

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
            playerRanks[client] = RANK_PLEB;
        }

        for (int rank = 1; rank < MAX_USER_RANKS; rank++)
        {
            if (strcmp(rankName, userRanks[rank][USER_RANK_NAME], true) == 0)
            {
                playerRanks[client] = rank;
            }
        }
    }
    else
    {
        playerRanks[client] = RANK_PLEB;
    }
}
