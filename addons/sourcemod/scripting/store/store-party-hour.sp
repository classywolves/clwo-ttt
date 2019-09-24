#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <colorlib>
#include <generics>
#include <clwo_store>
#include <clwo_store_messages>
#include <donators>

public Plugin myinfo =
{
    name = "CLWO Store Party Hour",
    author = "c0rp3n",
    description = "Allows donators to throw a party hour where all players gain double cR.",
    version = "1.0.0",
    url = ""
};

Database g_database = null;

bool g_isPartyHour = false;

ConVar g_cPartyDayCooldown = null;

public OnPluginStart()
{
    g_cPartyDayCooldown = CreateConVar("clwo_store_party_day_cooldown", "604800‬", "The time in seconds the player will have to wait to call in a party hour. 604800 - Default (1 week).‬");

    RegConsoleCmd("sm_partyhour", Command_PartyHour, "Hosts a party hour on the server.");

    AutoExecConfig(true, "store-party-hour", "clwo");

    Database.Connect(DbCallback_Connect, "store");

    PrintToServer("[RFL] Loaded succcessfully");
}

public Action Store_OnClientGainCredits(int client, int& credits)
{
    if (g_isPartyHour)
    {
        if (credits > 0)
        {
            CPrintToChat(client, STORE_MESSAGE ... "You gained an extra {orange}%dcR {default}as it is a party hour.", credits);
            credits += credits;

            return Plugin_Changed;
        }
    }

    return Plugin_Continue;
}

public Action Command_PartyHour(int client, int args)
{
    if (!Donator_IsDonator(client))
    {
        CPrintToChat(client, STORE_ERROR ... "You must be a donator to use this command.");
        return Plugin_Handled;
    }

    if (g_isPartyHour)
    {
        CPrintToChat(client, STORE_ERROR ... "A party hour is already running.");
        return Plugin_Handled;
    }

    Db_SelectLastTime(client);

    return Plugin_Handled;
}

public void Db_InsertLastTime(int client)
{
    int accountID = GetSteamAccountID(client);
    int time = GetTime();

    char query[192];
    Format(query, sizeof(query), "INSERT INTO `store_party_hour` (`account_id`, `last_time`) VALUES ('%d', '%d') ON DUPLICATE KEY UPDATE `last_time` = '%d';", accountID, time, time);
    g_database.Query(DbCallback_InsertLastTime, query);
}

public void Db_SelectLastTime(int client)
{
    int accountID = GetSteamAccountID(client);

    char query[128];
    Format(query, sizeof(query), "SELECT `last_time` FROM `store_party_hour` WHERE `account_id` = '%d' ORDER BY `last_time` DESC LIMIT 1;", accountID);
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
    SQL_FastQuery(g_database, "CREATE TABLE IF NOT EXISTS `store_party_hour` ( `account_id` INT UNSIGNED NOT NULL, `last_time` INT UNSIGNED NOT NULL, PRIMARY KEY (`account_id`), INDEX (`last_time`) ) ENGINE = InnoDB;");
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
        if (lastTime + g_cPartyDayCooldown.IntValue > GetTime())
        {
            CPrintToChat(client, STORE_MESSAGE ... "You have already used your party hour for this week.");
            return;
        }
    }

    PartyHour_Start(client);
}

public void PartyHour_Start(int client)
{
    g_isPartyHour = true;
    CPrintToChatAll(STORE_MESSAGE ... "%N has just called for a party hour, therefor there shall be double cR for everyone for one hour.");

    Db_InsertLastTime(client);
    CreateTimer(3600.0, Timer_PartyHourEnd);
}

public Action Timer_PartyHourEnd(Handle timer)
{
    g_isPartyHour = false;
    CPrintToChatAll(STORE_MESSAGE ... "Unfortuanately the party hour is now over.");

    return Plugin_Stop;
}