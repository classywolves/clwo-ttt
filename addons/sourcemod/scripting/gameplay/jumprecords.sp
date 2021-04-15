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

#define INSERT_QUERY "INSERT INTO `jumprecords_lj` (`account_id`, `time`, `distance`) VALUES ('%d', '%d', '%f');"
#define SELECT_QUERY "SELECT `name`, MAX(`distance`) FROM `v_jumprecords_lj` GROUP BY `account_id` ORDER BY `distance` DESC LIMIT 10;"

#define MINIMUM_LJ_DISTANCE         200.0
#define MINIMUM_BHJ_DISTANCE        200.0
#define MINIMUM_MBHJ_DISTANCE       200.0
#define MINIMUM_LADJ_DISTANCE       125.0
#define MINIMUM_WHJ_DISTANCE        200.0
#define MINIMUM_LDHJ_DISTANCE       200.0
#define MINIMUM_LBHJ_DISTANCE       200.0

bool g_bJumpStatsLoaded = false;

Database g_db         = null;
char     g_query[512] = "";

char g_name[MAX_NAME_LENGTH] = "";

public void OnPluginStart()
{
    RegConsoleCmd("sm_leaderboard", Command_Leadorboard, "sm_leaderboard - Displays the current Long Jump Leadorboard")
    RegConsoleCmd("sm_trackme",     Command_TrackMe,     "sm_trackme - Toggle whether you want to be tracked by Jump Records")

    Database.Connect(DbCallback_Connect, "jumprecrods");
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

////////////////////////////////////////////////////////////////////////////////
// Commands
////////////////////////////////////////////////////////////////////////////////

public Action Command_Leadorboard(int client, int argc)
{
    if (g_db != null)
    {
        dbSelectLongJumpRecords(client);
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
    if (isReady() && isOverThreshold(distance))
    {
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

    g_db = null;
}

void dbInsertLongJump(int client, int time, float distance)
{
    int accountID = GetSteamAccountID(client);
    g_db.Format(g_query, sizeof(g_query), INSERT_QUERY, accountID, time, distance);
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
    g_db.Query(DbCallback_SelectLongJumpRecords, SELECT_QUERY, GetClientUserId(client));
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
        results.FetchString(1, g_name, sizeof(g_name));
        float distance = results.FetchFloat(2);
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

bool isOverThreshold(float distance)
{
    return distance > MINIMUM_LJ_DISTANCE;
}
