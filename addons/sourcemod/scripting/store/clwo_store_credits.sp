#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colorlib>

#include <generics>
#include <ttt_targeting>
#include <clwo_store_messages>

public Plugin myinfo =
{
    name = "CLWO Store - Credits",
    author = "c0rp3n",
    description = "Custom credit system for CLWO TTT Store.",
    version = "0.1.0",
    url = ""
};

Database g_database = null;

char g_sQuery[256];

ConVar g_cCredits = null;

int g_iCredits[MAXPLAYERS + 1] = { -1, ... };

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
    CreateNative("Store_GetClientCredits", Native_GetCredits);
    CreateNative("Store_SetClientCredits", Native_SetCredits);
    CreateNative("Store_AddClientCredits", Native_AddCredits);
    CreateNative("Store_SubClientCredits", Native_SubCredits);

    RegPluginLibrary("clwo-store-credits");

    return APLRes_Success;
}

public void OnPluginStart()
{
    g_cCredits = CreateConVar("clwo_store_credits", "0", "The amount of credits a player should start with.");

    AutoExecConfig(true, "store_credits", "clwo");

    RegConsoleCmd("sm_cr", Command_Credits, "sm_cr - Displays the clients credits (cR).");
    //RegConsoleCmd("sm_givecr", Command_GiveCredits, "Give a set amount of credits to a client (cR).");

    Database.Connect(DbCallback_Connect, "store");

    PrintToServer("[STR] Loaded succcessfully");
}

public void OnClientPutInServer(int client)
{
    g_iCredits[client] = -1;
}

public void OnClientPostAdminCheck(int client)
{
    Db_SelectClientCredits(client);
}

public void OnClientDisconnect(int client)
{
    g_iCredits[client] = -1;
}

////////////////////////////////////////////////////////////////////////////////
// Commands
////////////////////////////////////////////////////////////////////////////////

public Action Command_Credits(int client, int args)
{
    if (!CanClientUseCredits(client))
    {
        return Plugin_Handled;
    }

    CPrintToChat(client, STORE_MESSAGE ... "{yellow}%N {default}has {orange}%dcR.", client, g_iCredits[client]);

    return Plugin_Handled;
}

/*
public Action Command_GiveCredits(int client, int args)
{
    if (args < 2)
    {
        CPrintToChat(client, "[SM] Usage: sm_givecr <#userid|name> <amount>");
        return Plugin_Handled;
    }

    if (!CanClientUseCredits(client))
    {
        return Plugin_Handled;
    }

    char buffer[32];
    int target;
    int amount;

    GetCmdArg(1, buffer, sizeof(buffer));
    target = TTT_Target(buffer, client, true, false, false);
    if (target < 1)
    {
        return Plugin_Handled;
    }

    if (!CanClientUseCredits(target))
    {
        return Plugin_Handled;
    }

    GetCmdArg(2, buffer, sizeof(buffer));
    amount = StringToInt(buffer);
    if (amount < 1)
    {
        CPrintToChat(client, STORE_MESSAGE ... "You must send more than 1cR.");
        return Plugin_Handled;
    }

    if (amount > g_iCredits[client])
    {
        CPrintToChat(client, STORE_MESSAGE ... "You do not have enough cR to give {orange}%dcR {default}to {yellow}%N.", amount, target);
        return Plugin_Handled;
    }

    CPrintToChatAll(STORE_MESSAGE ... "{yellow}%N {default}has given {yellow}%N {orange}%dcR.", client, target, amount);
    SubClientCredits(client, amount);
    AddClientCredits(target, amount);

    return Plugin_Handled;
}
*/

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
    SQL_FastQuery(g_database, "CREATE TABLE IF NOT EXISTS `store_players` (`account_id` INT UNSIGNED NOT NULL, `credits` INT UNSIGNED NOT NULL, PRIMARY KEY (`account_id`)) ENGINE = InnoDB;");

    LoopValidClients(i)
    {
        OnClientPutInServer(i);
        OnClientPostAdminCheck(i);
    }
}

public void Db_SelectClientCredits(int client)
{
    int accountID = GetSteamAccountID(client, true);
    if (!CheckClientAccountID(client, accountID))
    {
        return;
    }

    Format(g_sQuery, sizeof(g_sQuery), "SELECT `credits` FROM `store_players` WHERE `account_id` = '%d';", accountID);
    g_database.Query(DbCallback_SelectClientCredits, g_sQuery, GetClientUserId(client));
}

public void DbCallback_SelectClientCredits(Database db, DBResultSet results, const char[] error, int userid)
{
    if (results == null)
    {
        LogError("DbCallback_SelectClientCredits: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);
    if (client)
    {
        if (results.FetchRow())
        {
            g_iCredits[client] = results.FetchInt(0);
        }
        else
        {
            g_iCredits[client] = -1;
            Db_InsertClientCredits(client, g_cCredits.IntValue);
        }
    }
}

public void Db_InsertClientCredits(int client, int credits)
{
    int accountID = GetSteamAccountID(client, true);
    if (!CheckClientAccountID(client, accountID))
    {
        return;
    }

    Format(g_sQuery, sizeof(g_sQuery), "INSERT INTO `store_players` (`account_id`, `credits`) VALUES ('%d', '%d');", accountID, credits);
    g_database.Query(DbCallback_InsertClientCredits, g_sQuery, GetClientUserId(client));
}

public void DbCallback_InsertClientCredits(Database db, DBResultSet results, const char[] error, int userid)
{
    if (results == null)
    {
        LogError("DbCallback_InsertClientCredits: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);
    if (client)
    {
        g_iCredits[client] = g_cCredits.IntValue;
    }
}

public void Db_UpdateClientCredits(int client)
{
    int accountID = GetSteamAccountID(client, true);
    if (!CheckClientAccountID(client, accountID))
    {
        return;
    }

    Format(g_sQuery, sizeof(g_sQuery), "UPDATE `store_players` SET `credits` = '%d' WHERE `account_id` = '%d';", g_iCredits[client], accountID);
    g_database.Query(DbCallback_UpdateClientCredits, g_sQuery, GetClientUserId(client));
}

public void DbCallback_UpdateClientCredits(Database db, DBResultSet results, const char[] error, int userid)
{
    if (results == null)
    {
        LogError("DbCallback_UpdateClientCredits: %s", error);
    }
}

////////////////////////////////////////////////////////////////////////////////
// Natives
////////////////////////////////////////////////////////////////////////////////

public int Native_GetCredits(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    return g_iCredits[client];
}

public int Native_SetCredits(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (!IsClientCreditsValid(client))
    {
        return -1;
    }

    int amount = GetNativeCell(2);
    SetClientCredits(client, amount);

    return g_iCredits[client];
}

public int Native_AddCredits(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (!IsClientCreditsValid(client))
    {
        return -1;
    }

    int amount = GetNativeCell(2);
    AddClientCredits(client, amount);

    return g_iCredits[client];
}

public int Native_SubCredits(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (!IsClientCreditsValid(client))
    {
        return -1;
    }

    int amount = GetNativeCell(2);
    SubClientCredits(client, amount);

    return g_iCredits[client];
}

////////////////////////////////////////////////////////////////////////////////
// Stocks
////////////////////////////////////////////////////////////////////////////////

/*
 * Check that a client cR is valid, makes sure their credits are not reset.
 */
bool IsClientCreditsValid(int client)
{
    return g_iCredits[client] >= 0;
}

/*
 * Sets a clients credits and updates the database.
 */
void SetClientCredits(int client, int credits)
{
    g_iCredits[client] = credits;
    Db_UpdateClientCredits(client);
}

/*
 * Add too a clients credits and updates the database.
 */
void AddClientCredits(int client, int credits)
{
    g_iCredits[client] += credits;
    Db_UpdateClientCredits(client);
}

/*
 * Subtracts from a clients credits and updates the database.
 */
void SubClientCredits(int client, int credits)
{
    g_iCredits[client] -= credits;
    Db_UpdateClientCredits(client);
}

/*
 * Checks if a clients credits are loaded and if not prints a user message
 * saying that it is currently unavailible.
 */
bool CanClientUseCredits(int client)
{
    if (!IsClientCreditsValid(client))
    {
        CPrintToChat(client, STORE_MESSAGE ... "Sorry the Credit Chip system is currently unavailible, please come back later.");
        return false;
    }

    return true;
}

/*
 * Checks if a clients account ID is valid.
 */
bool CheckClientAccountID(int client, int accountID)
{
    if (accountID == 0)
    {
        LogError("invalid steam account ID for client #%d", client);

        return false;
    }

    return true;
}
