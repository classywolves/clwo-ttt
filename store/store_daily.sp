#pragma semicolon 1

#include <sourcemod>
#include <colorlib>

#include <generics>
#include <clwo_store_credits>
#include <clwo_store_messages>

public Plugin myinfo =
{
    name = "CLWO Store - Daily",
    author = "c0rp3n",
    description = "Allows player to gain a daily reward of cR.",
    version = "1.0.0",
    url = ""
};

Database g_database = null;

ConVar g_cDailyRewardBase = null;
ConVar g_cDailyRewardStep = null;

int g_iRewards[] = {
    1,
    5,
    10,
    15,
    30,
    60
};

public void OnPluginStart()
{
    g_cDailyRewardBase = CreateConVar("clwo_store_daily_reward_base", "50", "‬The minimum reward for cR with sm_daily.", _, true, 1.0, false);
    g_cDailyRewardStep = CreateConVar("clwo_store_daily_reward_step", "10", "‬The maximum reward for cR with sm_daily.", _, true, 1.0, false);

    AutoExecConfig(true, "store_daily", "clwo");

    RegConsoleCmd("sm_daily", Command_Daily, "Claims your daily reward.");

    Database.Connect(DbCallback_Connect, "store");

    PrintToServer("[DLY] Loaded succcessfully");
}

public Action Command_Daily(int client, int args)
{
    Db_SelectDaily(client);

    return Plugin_Handled;
}

public void DbCallback_Connect(Database db, const char[] error, any data)
{
    if (db == null)
    {
        PrintToServer("DbCallback_Connect: %s", error);
        return;
    }

    g_database = db;
    SQL_FastQuery(g_database, "CREATE TABLE IF NOT EXISTS `store_daily` ( `account_id` INT UNSIGNED NOT NULL, `last_day` INT UNSIGNED NOT NULL, `cons_days` INT UNSIGNED NOT NULL, PRIMARY KEY (`account_id`), INDEX (`last_day`)) ENGINE = InnoDB;");
}

public void Db_SelectDaily(int client)
{
    int accountID = GetSteamAccountID(client);

    char query[128];
    Format(query, sizeof(query), "SELECT `last_day`, `cons_days` FROM `store_daily` WHERE `account_id` = '%d' LIMIT 1;", accountID);
    g_database.Query(DbCallback_SelectDaily, query, GetClientUserId(client));
}

public void DbCallback_SelectDaily(Database db, DBResultSet results, const char[] error, int userid)
{
    if (results == null)
    {
        PrintToServer("DbCallback_SelectDaily: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);
    int currDay = GetTime() / 86400;
    int consDays = 0;
    if (results.FetchRow())
    {
        int lastDay = results.FetchInt(0);
        int delta = currDay - lastDay;
        if (delta <= 0)
        {
            CPrintToChat(client, STORE_MESSAGE ... "You have already claimed your daily reward.");
            return;
        }

        if (delta == 1)
        {
            consDays = results.FetchInt(1) + 1;
        }

        Db_UpdateDaily(client, currDay, consDays);
    }
    else
    {
        Db_InsertDaily(client, currDay);
    }

    int reward = g_iRewards[Min(consDays, 5)];
    Store_AddClientCredits(client, reward);

    if (consDays == 0)
    {
        CPrintToChatAll(STORE_MESSAGE ... "{yellow}%N {default}just claimed {orange}%dcR {default}with /daily.", client, reward);
    }
    else
    {
        ++consDays;

        char buffer[3];
        GetDayOfMonthSuffix(consDays, buffer, sizeof(buffer));
        CPrintToChatAll(STORE_MESSAGE ... "{yellow}%N {default}used /daily for the %d%s day running, gaining {orange}%dcR.", client, consDays, buffer, reward);
    }
}

public void Db_InsertDaily(int client, int currDay)
{
    int accountID = GetSteamAccountID(client);

    char query[192];
    Format(query, sizeof(query), "INSERT INTO `store_daily` (`account_id`, `last_day`, `cons_days`) VALUES ('%d', '%d', '0');", accountID, currDay);
    g_database.Query(DbCallback_InsertDaily, query);
}

public void DbCallback_InsertDaily(Database db, DBResultSet results, const char[] error, any data)
{
    if (results == null)
    {
        PrintToServer("DbCallback_InsertDaily: %s", error);
        return;
    }
}

public void Db_UpdateDaily(int client, int currDay, int consDays)
{
    int accountID = GetSteamAccountID(client);

    char query[128];
    Format(query, sizeof(query), "UPDATE `store_daily` SET `last_day` = '%d', `cons_days` = '%d'  WHERE `account_id` = '%d' LIMIT 1;", currDay, consDays, accountID);
    g_database.Query(DbCallback_UpdateDaily, query, GetClientUserId(client));
}

public void DbCallback_UpdateDaily(Database db, DBResultSet results, const char[] error, any data)
{
    if (results == null)
    {
        PrintToServer("DbCallback_UpdateDaily: %s", error);
        return;
    }
}


int Min(int a, int b)
{
    return a < b ? a : b;
}

void GetDayOfMonthSuffix(int n, char[] buffer, int length)
{
    if (n >= 11 && n <= 13)
    {
        strcopy(buffer, length, "th");
        return;
    }
    switch (n % 10)
    {
        case 1:  { strcopy(buffer, length, "st"); return; }
        case 2:  { strcopy(buffer, length, "nd"); return; }
        case 3:  { strcopy(buffer, length, "rd"); return; }
        default: { strcopy(buffer, length, "th"); return; }
    }
}
