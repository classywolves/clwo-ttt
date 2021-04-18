/*
 * Goals:
 *
 * - Players can toggle this feature on and off
 *
 * - Only works when there's less than 5 players on, maybe have some
 *   functionality with Nilo's warmup plugin, so warmup is autoactivated and
 *   this feature is on
 *
 * - Tracks stats of a jump, maybe a few different types of LJ (multibhop,
 *   single bhop, ladder etc), this is all done by an exisiting jump stats
 *   plugin.
 *
 * - Saves the jumps to a db if they're impressive enough, and players can
 *   access a leaderboard of all jumps
 *
 * - Top 10 players get a special tag in chat, but 1st, 2nd and 3rd place either
 *   get their own special tags or different colours
 */

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <jumpstats.inc>
#define REQUIRE_PLUGIN

public Plugin myinfo =
{
    name        = "CLWO TTT - Jump Records",
    author      = "c0rp3n",
    description = "",
    version     = "1.0.0",
    url         = "clwo.eu"
};

#define SELECT_PB_QUERY  "SELECT `distance` FROM `jumprecords_lj` WHERE `account_id` = '%d' LIMIT 1;"
#define INSERT_QUERY     "INSERT INTO `jumprecords_lj` (`account_id`, `time`, `distance`) VALUES ('%d', '%d', '%f') ON DUPLICATE KEY UPDATE `time`='%d', `distance`='%f';"
#define SELECT_LED_QUERY "SELECT `name`, `distance` FROM `v_jumprecords_lj` ORDER BY `distance` DESC LIMIT 10;"

#define MINIMUM_LJ_DISTANCE         200.0
#define MINIMUM_BHJ_DISTANCE        200.0
#define MINIMUM_MBHJ_DISTANCE       200.0
#define MINIMUM_LADJ_DISTANCE       125.0
#define MINIMUM_WHJ_DISTANCE        200.0
#define MINIMUM_LDHJ_DISTANCE       200.0
#define MINIMUM_LBHJ_DISTANCE       200.0

bool  g_bJumpStatsLoaded               = false;
bool  g_bClientLoaded[MAXPLAYERS + 1]  = { false, ... };
float g_fClientRecords[MAXPLAYERS + 1] = { 0.0, ... };

Database g_db         = null;
char     g_query[512] = "";

char g_name[MAX_NAME_LENGTH] = "";

public void OnPluginStart()
{
    RegConsoleCmd("sm_leaderboard", Command_Leadorboard, "sm_leaderboard - Displays the current Long Jump Leadorboard");
    RegConsoleCmd("sm_trackme",     Command_TrackMe,     "sm_trackme - Toggle whether you want to be tracked by Jump Records");

    g_bJumpStatsLoaded = LibraryExists("jumpstats");

    Database.Connect(DbCallback_Connect, "ttt");
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "jumpstats"))
    {
        g_bJumpStatsLoaded = true;
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "jumpstats"))
    {
        g_bJumpStatsLoaded = false;
    }
}

public void OnClientPutInServer(int client)
{
    g_bClientLoaded[client] = false;
}

public void OnClientAuthorized(int client, const char[] auth)
{
    if (g_db != null)
    {
        dbSelectPersonalBest(client);
    }
}

////////////////////////////////////////////////////////////////////////////////
// Commands
////////////////////////////////////////////////////////////////////////////////

public Action Command_Leadorboard(int client, int argc)
{
    if (g_db != null)
    {
        dbSelectLongJumpRecords(client);
    }
    else
    {
        ReplyToCommand(client, "[SM] Long Jump records is not ready yet.");
    }

    return Plugin_Handled;
}

public Action Command_TrackMe(int client, int argc)
{
    if (g_bJumpStatsLoaded)
    {
        if (JumpStats_ClientIsTracked(client))
        {
            JumpStats_ClientTrack(client);
        }
        else
        {
            JumpStats_ClientUntrack(client);
        }
    }

    return Plugin_Handled;
}

////////////////////////////////////////////////////////////////////////////////
// Jump Stats
////////////////////////////////////////////////////////////////////////////////

public void JumpStats_OnJump(int client, JumpType type, float distance)
{
    if (hasClientLoaded(client) == false)
    {
        return; // do nothing as we not yet know the clients current max lj
    }

    //PrintToConsole(client, "[DEBUG] hasClientBeatenRecord: %d", hasClientBeatenRecord(client, distance));
    if (isReady() && (type == Jump_LJ) && hasClientBeatenRecord(client, distance))
    {
        g_fClientRecords[client] = distance;
        dbInsertLongJump(client, GetTime(), distance);
    }
}

////////////////////////////////////////////////////////////////////////////////
// Database
////////////////////////////////////////////////////////////////////////////////

public void DbCallback_Connect(Database db, const char[] error, any data)
{
    if (db != null && strlen(error) != 0)
    {
        SetFailState("Failed to connect to database.");
        return;
    }

    g_db = db;

    for (int i = 1; i < MaxClients; ++i)
    {
        g_bClientLoaded[i] = false;

        if (IsClientConnected(i) && IsClientAuthorized(i))
        {
            dbSelectPersonalBest(i);
        }
    }
}

void dbSelectPersonalBest(int client)
{
    int accountID = GetSteamAccountID(client);
    g_db.Format(g_query, sizeof(g_query), SELECT_PB_QUERY, accountID);
    g_db.Query(DbCallback_SelectPersonalBest, g_query, GetClientUserId(client));
}

public void DbCallback_SelectPersonalBest(Database db, DBResultSet results, const char[] error, int userID)
{
    if (error[0] != '\0')
    {
        LogError("DbCallback_SelectPersonalBest: %s", error);
        return;
    }

    int client = GetClientOfUserId(userID);
    if (!client) { return; }

    if (results.FetchRow())
    {
        g_fClientRecords[client] = results.FetchFloat(0);
        g_bClientLoaded[client]  = true;
    }
}

void dbInsertLongJump(int client, int time, float distance)
{
    int accountID = GetSteamAccountID(client);
    g_db.Format(g_query, sizeof(g_query), INSERT_QUERY, accountID, time, distance, time, distance);
    g_db.Query(DbCallback_InsertLongJump, g_query);
}

public void DbCallback_InsertLongJump(Database db, DBResultSet results, const char[] error, any data)
{
    if (error[0] != '\0')
    {
        LogError("DbCallback_InsertLongJump: %s", error);
    }
}

void dbSelectLongJumpRecords(int client)
{
    g_db.Query(DbCallback_SelectLongJumpRecords, SELECT_LED_QUERY, GetClientUserId(client));
}

public void DbCallback_SelectLongJumpRecords(Database db, DBResultSet results, const char[] error, int userID)
{
    if (error[0] != '\0')
    {
        LogError("DbCallback_SelectLongJumpRecords: %s", error);
        return;
    }

    int client = GetClientOfUserId(userID);
    if (!client) { return; }

    PrintToConsole(client, "Long Jump Leadorboard:");
    int count = 0;
    while (results.FetchRow())
    {
        results.FetchString(0, g_name, sizeof(g_name));
        float distance = results.FetchFloat(1);
        PrintToConsole(client, "%d. %s - %fu", count, g_name, distance);
        ++count;
    }
}

////////////////////////////////////////////////////////////////////////////////
// Stocks
////////////////////////////////////////////////////////////////////////////////

bool isReady()
{
    return g_bJumpStatsLoaded && (g_db != null);
}

bool hasClientLoaded(int client)
{
    return g_bClientLoaded[client];
}

bool hasClientBeatenRecord(int client, float distance)
{
    if (distance > g_fClientRecords[client])
    {
        return true;
    }

    return false;
}
