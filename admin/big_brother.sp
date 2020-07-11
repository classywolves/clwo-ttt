#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define QUERY_CREATE_CHAT "CREATE TABLE IF NOT EXISTS `big_brother_chat` (`id` INT UNSIGNED AUTO_INCREMENT, `time` INT UNSIGNED NOT NULL, `account_id` INT UNSIGNED NOT NULL, `message` VARCHAR(256), PRIMARY KEY(`id`), INDEX(`time`), INDEX(`account_id`)) ENGINE = InnoDB;"
#define QUERY_CREATE_MSG  "CREATE TABLE IF NOT EXISTS `big_brother_msg` (`id` INT UNSIGNED AUTO_INCREMENT, `time` INT UNSIGNED NOT NULL, `sender_id` INT UNSIGNED NOT NULL, `receiver_id` INT UNSIGNED NOT NULL, `message` VARCHAR(256), PRIMARY KEY(`id`), INDEX(`time`), INDEX(`sender_id`), INDEX(`receiver_id`)) ENGINE = InnoDB;"
#define QUERY_INSERT_CHAT "INSERT INTO `big_brother_chat` (`time`, `account_id`, `message`) VALUES (UTC_TIMESTAMP(), '%d', '%s');"
#define QUERY_INSERT_MSG  "INSERT INTO `big_brother_msg` (`time`, `account_id`, `receiver_id`, `message`) VALUES (UTC_TIMESTAMP(), '%d', '%d', '%s');"

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

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("BigBrother_LogMessage", Native_LogMessage);

    RegPluginLibrary("big_brother");
}

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
        Format(g_cQuery, sizeof(g_cQuery), QUERY_INSERT_CHAT, accountID, g_cText);
        SQL_FastQuery(g_database, g_cQuery);
    }
}

public void Database_Connect(Database db, const char[] error, any data)
{
    if (db != null)
    {
        g_database = db;
        SQL_FastQuery(g_database, QUERY_CREATE_CHAT);
        SQL_FastQuery(g_database, QUERY_CREATE_MSG);
    }
}

public int Native_LogMessage(Handle plugin, int argc)
{
    if (g_database == null)
        return;

    int senderID = GetSteamAccountID(GetNativeCell(1));
    int recieverID = GetSteamAccountID(GetNativeCell(2));
    GetNativeString(3, g_cText, sizeof(g_cText));
    Format(g_cQuery, sizeof(g_cQuery), QUERY_INSERT_MSG, senderID, recieverID, g_cText);
    SQL_FastQuery(g_database, g_cQuery);
}
