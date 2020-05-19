#pragma semicolon 1

#include <sourcemod>
#include <colorlib>

#include <generics>
#include <clwo_store_credits>
#include <clwo_store_messages>
#include <donators>

public Plugin myinfo =
{
    name = "CLWO Store - Daily",
    author = "c0rp3n",
    description = "Allows player to gain a daily reward of cR.",
    version = "1.0.0",
    url = ""
};

Database g_database = null;

ConVar g_cDailyRewardMin = null;
ConVar g_cDailyRewardMax = null;

public void OnPluginStart()
{
    g_cDailyRewardMin = CreateConVar("clwo_store_daily_reward_min", "2", "‬The minimum reward for cR with sm_daily.", _, true, 1.0, false);
    g_cDailyRewardMax = CreateConVar("clwo_store_daily_reward_min", "10", "‬The maximum reward for cR with sm_daily.", _, true, 1.0, false);

    AutoExecConfig(true, "store_daily", "clwo");

    RegConsoleCmd("sm_daily", Command_Daily, "Claims your daily reward.");

    Database.Connect(DbCallback_Connect, "store");

    PrintToServer("[DLY] Loaded succcessfully");
}

public Action Command_Daily(int client, int args)
{
    Db_SelectLastTime(client);

    return Plugin_Handled;
}

public void Db_InsertLastTime(int client)
{
    int accountID = GetSteamAccountID(client);
    int time = GetTime();

    char query[192];
    Format(query, sizeof(query), "INSERT INTO `store_daily` (`account_id`, `last_time`) VALUES ('%d', '%d') ON DUPLICATE KEY UPDATE `last_time` = '%d';", accountID, time, time);
    g_database.Query(DbCallback_InsertLastTime, query);
}

public void Db_SelectLastTime(int client)
{
    int accountID = GetSteamAccountID(client);

    char query[128];
    Format(query, sizeof(query), "SELECT `last_time` FROM `store_daily` WHERE `account_id` = '%d' ORDER BY `last_time` DESC LIMIT 1;", accountID);
    g_database.Query(DbCallback_SelectLastTime, query, GetClientUserId(client));
}

public void DbCallback_Connect(Database db, const char[] error, any data)
{
    if (db == null)
    {
        PrintToServer("DbCallback_Connect: %s", error);
        return;
    }

    g_database = db;
    SQL_FastQuery(g_database, "CREATE TABLE IF NOT EXISTS `store_daily` ( `account_id` INT UNSIGNED NOT NULL, `last_time` INT UNSIGNED NOT NULL, PRIMARY KEY (`account_id`), INDEX (`last_time`)) ENGINE = InnoDB;");
}

public void DbCallback_InsertLastTime(Database db, DBResultSet results, const char[] error, any data)
{
    if (results == null)
    {
        PrintToServer("DbCallback_InsertLastTime: %s", error);
        return;
    }
}

public void DbCallback_SelectLastTime(Database db, DBResultSet results, const char[] error, int userid)
{
    if (results == null)
    {
        PrintToServer("DbCallback_SelectLastTime: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);
    if (results.FetchRow())
    {
        int lastTime = results.FetchInt(0);
        if (lastTime + 86400 >= GetTime())
        {
            CPrintToChat(client, STORE_MESSAGE ... "You have claimed your daily reward.");
            return;
        }
    }

    int reward = GetRandomInt(g_cDailyRewardMin.IntValue, g_cDailyRewardMax.IntValue);
    Store_AddClientCredits(client, reward);
    Db_InsertLastTime(client);
    CPrintToChatAll(STORE_MESSAGE ... "{yellow}%N {default}just claimed {orange}%dcR {default}with /daily.", client, reward);
}
