#pragma semicolon 1

#include <sourcemod>

#include <generics>

public Plugin myinfo =
{
    name = "Player Info",
    author = "c0rp3n",
    description = "Player Info Database handler for inserting and updating player info.",
    version = "1.0.0",
    url = ""
};

Database g_database;

public OnPluginStart()
{
    Database.Connect(DbCallback_Connect, "ttt");

    PrintToServer("[PDB] Loaded succcessfully");
}

public void OnClientAuthorized(int client, const char[] auth)
{
    int accountId = GetSteamAccountID(client);
    char name[64];
    GetClientName(client, name, sizeof(name));

    Db_InsertPlayerInfo(client, accountId, name, auth);
    Db_InsertPlayerName(client, accountId, name);
}

public void Db_InsertPlayerInfo(int client, int accountId, const char[] name, const char[] auth)
{
    char communityId[64];
    GetClientAuthId(client, AuthId_SteamID64, communityId, sizeof(communityId));

    char query[256];
    Format(query, sizeof(query), "INSERT INTO `player_info` (`account_id`, `name`, `auth_id`, `community_id`) VALUES ('%d', '%s', '%s', '%s') ON DUPLICATE KEY UPDATE `name` = '%s';", accountId, name, auth, communityId, name);

    g_database.Query(DbCallback_InsertPlayerInfo, query, GetClientUserId(client));
}

public void Db_InsertPlayerName(int client, int accountId, const char[] name)
{
    char query[256];
    Format(query, sizeof(query), "INSERT INTO `player_names` (`account_id`, `name`) VALUES ('%d', '%s') ON DUPLICATE KEY UPDATE `account_id`=`account_id`;", accountId, name);

    g_database.Query(DbCallback_InsertPlayerName, query, GetClientUserId(client));
}

public void DbCallback_Connect(Database db, const char[] error, any data)
{
    if (db == null)
    {
        PrintToServer("DbCallback_Connect: %s", error);
        return;
    }

    g_database = db;
    SQL_FastQuery(g_database, "CREATE TABLE IF NOT EXISTS `player_info` ( `account_id` INT UNSIGNED NOT NULL, `name` VARCHAR(64) NOT NULL, `auth_id` VARCHAR(32) NOT NULL, `community_id` VARCHAR(64) NOT NULL, PRIMARY KEY (`account_id`), UNIQUE `auth_index` (`auth_id`), UNIQUE `community_index` (`community_id`) ) ENGINE = InnoDB;");
    SQL_FastQuery(g_database, "CREATE TABLE IF NOT EXISTS `player_names` ( `id` INT UNSIGNED NOT NULL AUTO_INCREMENT, `account_id` INT UNSIGNED NOT NULL, `name` VARCHAR(64) NOT NULL, PRIMARY KEY (`id`), UNIQUE `account_name` (`account_id`, `name`) ) ENGINE = InnoDB;");

    LoopValidClients(i)
    {
        char auth[16];
        GetClientAuthId(i, AuthId_Steam2, auth, sizeof(auth));

        OnClientAuthorized(i, auth);
    }
}

public void DbCallback_InsertPlayerInfo(Database db, DBResultSet results, const char[] error, int userid)
{
    if (results == null)
    {
        PrintToServer("DbCallback_InsertPlayerInfo: %s", error);
        return;
    }
}

public void DbCallback_InsertPlayerName(Database db, DBResultSet results, const char[] error, int userid)
{
    if (results == null)
    {
        PrintToServer("DbCallback_InsertPlayerName: %s", error);
        return;
    }
}