#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo =
{
    name = "Big Brother",
    author = "Popey & c0rp3n",
    description = "George Orwells worse nightmare!",
    version = "1.0.0",
    url = ""
};

Database g_database = null;

char g_cQuery[512];
char g_cText[256];

public void OnPluginStart()
{
    HookEvent("player_say", Event_PlayerSay, EventHookMode_Post);

    Database.Connect(Database_Connect, "msg");
}

public void Event_PlayerSay(Event event, const char[] name, bool dontBroadcast)
{
    if (g_database == null)
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0)
    {
        int accountID = GetSteamAccountID(client);
        event.GetString("text", g_cText, sizeof(g_cText));
        Format(g_cQuery, sizeof(g_cQuery), "INSERT INTO `big_brother` (`time`, `account_id`, `message`) VALUES (UTC_TIMESTAMP(), '%d', '%s');", accountID, g_cText);
        SQL_FastQuery(g_database, g_cQuery);
    }
}

public void Database_Connect(Database db, const char[] error, any data)
{
    if (db != null)
    {
        g_database = db;
        SQL_FastQuery(g_database, "CREATE TABLE IF NOT EXISTS `big_brother` (`id` INT UNSIGNED AUTO_INCREMENT, `time` INT UNSIGNED NOT NULL, `account_id` INT UNSIGNED NOT NULL, `message` VARCHAR(256), PRIMARY KEY(`id`), INDEX(`time`), INDEX(`account_id`)) ENGINE = InnoDB;");
    }
}
