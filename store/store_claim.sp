#pragma semicolon 1

#include <sourcemod>
#include <colorlib>
#include <mostactive>

#include <generics>
#undef REQUIRE_PLUGIN
#include <clwo_store_credits>
#define REQUIRE_PLUGIN
#include <clwo_store_messages>

public Plugin myinfo =
{
    name = "CLWO Store - Claim",
    author = "c0rp3n",
    description = "Example plugin for the clwo store plugin.",
    version = "1.0.0",
    url = ""
};

Database g_database = null;

int g_iBands[3][2] = {
    { 50,   250 },
    { 150,  500 },
    { 300, 1000 }
};

public void OnPluginStart()
{
    Database.Connect(DbCallback_Connect, "store");

    PrintToServer("[CLM] Loaded succcessfully");
}

public void OnClientPostAdminCheck(int client)
{
    if (IsDatabaseReady())
    {
        // Added a delay to hopefully make sure people notice that they get it.
        CreateTimer(10.0, Timer_ProcessClaim, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action Timer_ProcessClaim(Handle timer, int userID)
{
    Db_SelectClientHasClaimed(GetClientOfUserId(userID));

    return Plugin_Stop;
}

////////////////////////////////////////////////////////////////////////////////
// Database
////////////////////////////////////////////////////////////////////////////////

public void DbCallback_Connect(Database db, const char[] error, any data)
{
    if (db == null)
    {
        PrintToServer("DbCallback_Connect: %s", error);
        return;
    }

    g_database = db;
    SQL_FastQuery(g_database, "CREATE TABLE IF NOT EXISTS `store_claim` (`account_id` INT UNSIGNED NOT NULL, PRIMARY KEY (`account_id`)) ENGINE = InnoDB;");

    LoopValidClients(i)
    {
        OnClientPostAdminCheck(i);
    }
}

void Db_SelectClientHasClaimed(int client)
{
    int accountID = GetSteamAccountID(client);

    char query[128];
    Format(query, sizeof(query), "SELECT `account_id` FROM `store_claim` WHERE `account_id` = '%d';", accountID);
    g_database.Query(DbCallback_SelectClientHasClaimed, query, GetClientUserId(client));
}

public void DbCallback_SelectClientHasClaimed(Database db, DBResultSet results, const char[] error, int userID)
{
    if (results == null)
    {
        PrintToServer("DbCallback_SelectClientHasClaimed: %s", error);
        return;
    }

    // if nothing was returned they have not yet claimed
    if (!results.FetchRow())
    {
        int client = GetClientOfUserId(userID);

        int hours = MostActive_GetPlayTimeTotal(client) / 3600;
        int amount = 0;
        for (int i = 0; i < 3; ++i)
        {
            if (hours < g_iBands[i][0])
            {
                break;
            }
            else // if(hours >= g_iBands[i][0])
            {
                amount = g_iBands[i][1];
            }
        }

        if (amount > 0)
        {
            CPrintToChat(client, "[Store] You have gained {oragne}%dcR {default}for your previous playtime, wellcome back.", amount);
            CPrintToChat(client, "[Store] Use /skills to spend your newly earned cR.", amount);
            Store_AddClientCredits(client, amount);
        }

        Db_InsertClientClaim(client);
    }
}

void Db_InsertClientClaim(int client)
{
    int accountID = GetSteamAccountID(client);

    char query[128];
    Format(query, sizeof(query), "INSERT INTO `store_claim` (`account_id`) VALUES ('%d');", accountID);
    g_database.Query(DbCallback_InsertClientClaim, query);
}

public void DbCallback_InsertClientClaim(Database db, DBResultSet results, const char[] error, any data)
{
    if (results == null)
    {
        PrintToServer("DbCallback_InsertClientClaim: %s", error);
        return;
    }
}

////////////////////////////////////////////////////////////////////////////////
// Stocks
////////////////////////////////////////////////////////////////////////////////

bool IsDatabaseReady()
{
    return g_database != null;
}
