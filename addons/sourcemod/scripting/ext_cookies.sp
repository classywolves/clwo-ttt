/*
 * Cookies Extension by c0rp3n
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo =
{
    name = "Cookies Extension",
    author = "c0rp3n",
    description = "",
    version = "1.0.0",
    url = ""
};

typedef ExtCookies_GetCookieCallback = function void (int cookieID, const char[] steamID, const char[] value);

Database g_db = null;

char g_query[512];
char g_cookie[64];
char g_steamID[64];
char g_value[64];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("ExtCookies_GetCookieID", Native_GetCookieID);
    CreateNative("ExtCookies_SetCookieBySteamID", Native_SetCookieBySteamID);
}

public void OnPluginStart()
{
    Database.Connect(DbCallback_Connect, "clientprefs");
}

////////////////////////////////////////////////////////////////////////////////
// Natives
////////////////////////////////////////////////////////////////////////////////

public int Native_GetCookieID(Handle plugin, int argc)
{
    GetNativeString(1, g_cookie, sizeof(g_cookie));

    return Db_GetCookieID(g_cookie);
}

public int Native_SetCookieBySteamID(Handle plugin, int argc)
{
    int cookieID = GetNativeCell(1);
    GetNativeString(1, g_steamID, sizeof(g_steamID));
    GetNativeString(1, g_value, sizeof(g_value));
    Db_SetCookieBySteamID(cookieID, g_steamID, g_value);

    return 0;
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

int Db_GetCookieID(const char[] cookie)
{
    g_db.Format(g_query, sizeof(g_query), "SELECT `id` FROM `sm_cookies` WHERE `name` = \"%s\" LIMIT 1;", cookie);
    DBResultSet results = SQL_Query(g_db, g_query);
    if (results == null)
    {
        return 0;
    }

    if (results.FetchRow())
    {
        return results.FetchInt(0);
    }

    return 0;
}

/*
void Db_GetCookieBySteamID(int cookieID, const char[] steamID)
{
    g_db.Format(g_query, sizeof(g_query), "SELECT `value` FROM `sm_cookie_cache` WHERE `cookie_id` = '%d' AND `player` REGEXP '^STEAM_[0-9]:%s$' LIMIT 1;", cookieID, steamID);
    g_db.Query(DbCallback_DoNothing, g_query);
}
*/

void Db_SetCookieBySteamID(int cookieID, const char[] steamID, const char[] value)
{
    g_db.Format(g_query, sizeof(g_query), "UPDATE `sm_cookie_cache` SET `value`=\"%s\" WHERE `cookie_id` = '%d' AND `player` REGEXP '^STEAM_[0-9]:%s$' LIMIT 1;", value, cookieID, steamID);
    SQL_FastQuery(g_db, g_query);
}
