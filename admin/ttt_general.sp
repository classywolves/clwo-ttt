/*
 * Big Brother
 * A plugin for logging user messages to a database for lookup at a later time,
 * essentially George Orwells worst nightmare.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define QUERY_CREATE_CHAT "CREATE TABLE IF NOT EXISTS `bb_chat` (`id` INT UNSIGNED AUTO_INCREMENT, `time` INT UNSIGNED NOT NULL, `account_id` INT UNSIGNED NOT NULL, `message` VARCHAR(256), PRIMARY KEY(`id`), INDEX(`time`), INDEX(`account_id`)) ENGINE = InnoDB;"
#define QUERY_CREATE_MSG  "CREATE TABLE IF NOT EXISTS `bb_msg` (`id` INT UNSIGNED AUTO_INCREMENT, `time` INT UNSIGNED NOT NULL, `sender_id` INT UNSIGNED NOT NULL, `receiver_id` INT UNSIGNED NOT NULL, `message` VARCHAR(256), PRIMARY KEY(`id`), INDEX(`time`), INDEX(`sender_id`), INDEX(`receiver_id`)) ENGINE = InnoDB;"
#define QUERY_CREATE_V_CHAT "CREATE OR REPLACE VIEW `v_bb_chat` AS SELECT `bb_chat`.`id`, `bb_chat`.`time`, `bb_chat`.`account_id`, `player_info`.`name`, `bb_chat`.`message` FROM `bb_chat` LEFT JOIN `player_info` ON `bb_chat`.`account_id` = `player_info`.`account_id` GROUP BY `bb_chat`.`id`;"
#define QUERY_CREATE_V_MSG "CREATE OR REPLACE VIEW `v_bb_msg` AS SELECT `bb_msg`.`id`, `bb_msg`.`time`, `bb_msg`.`sender_id`, `sender_info`.`name` as `sender_name`, `bb_msg`.`receiver_id`, `receiver_info`.`name` as `receiver_name`, `bb_msg`.`message` FROM `bb_msg` LEFT JOIN `player_info` `sender_info` ON `bb_msg`.`sender_id` = `sender_info`.`account_id` LEFT JOIN `player_info` `receiver_info` ON `bb_msg`.`receiver_id` = `receiver_info`.`account_id` GROUP BY `bb_msg`.`id`;"
#define QUERY_INSERT_CHAT "INSERT INTO `bb_chat` (`time`, `account_id`, `message`) VALUES (UNIX_TIMESTAMP(), '%d', '%s');"
#define QUERY_INSERT_MSG  "INSERT INTO `bb_msg` (`time`, `account_id`, `receiver_id`, `message`) VALUES (UNIX_TIMESTAMP(), '%d', '%d', '%s');"

public Plugin myinfo =
{
    name = "TTT General",
    author = "Popey & c0rp3n",
    description = "General commands and utilities for CLWO TTT.",
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
        SQL_FastQuery(g_database, QUERY_CREATE_V_CHAT);
        SQL_FastQuery(g_database, QUERY_CREATE_V_MSG);
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
