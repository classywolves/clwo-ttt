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
    CreateNative("ExtCookies_GetCookieBySteamID", Native_GetCookieBySteamID);
    CreateNative("ExtCookies_SetCookieBySteamID", Native_SetCookieBySteamID);

    RegPluginLibrary("ext_cookies");
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

public int Native_GetCookieBySteamID(Handle plugin, int argc)
{
    int cookieID = GetNativeCell(1);
    GetNativeString(2, g_steamID, sizeof(g_steamID));
    Function callback = GetNativeCell(3);
    Db_GetCookieBySteamID(cookieID, g_steamID, plugin, callback);

    return 0;
}

public int Native_SetCookieBySteamID(Handle plugin, int argc)
{
    int cookieID = GetNativeCell(1);
    GetNativeString(2, g_steamID, sizeof(g_steamID));
    GetNativeString(3, g_value, sizeof(g_value));
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

void Db_GetCookieBySteamID(int cookieID, const char[] steamID, Handle plugin, Function callback)
{
    DataPack data = new DataPack();
    g_db.Format(g_query, sizeof(g_query), "SELECT `value` FROM `sm_cookie_cache` WHERE `cookie_id` = '%d' AND `player` REGEXP '^STEAM_[0-9]:%s$' LIMIT 1;", cookieID, steamID);
    g_db.Query(DbCallback_GetCookieBySteamID, g_query, data);

    data.WriteCell(cookieID);
    data.WriteString(steamID);
    data.WriteCell(plugin);
    data.WriteFunction(callback);
    data.Reset();
}

public void DbCallback_GetCookieBySteamID(Database db, DBResultSet results, const char[] error, DataPack data)
{
    if (db != null && strlen(error) != 0)
    {
        SetFailState("Failed to connect to database.");
        return;
    }

    int cookieID = data.ReadCell();
    data.ReadString(g_steamID, sizeof(g_steamID));
    Handle plugin = data.ReadCell();
    Function callback = data.ReadFunction();

    static char value[128];
    if (results.FetchRow())
    {
        results.FetchString(0, value, sizeof(value));
    }
    else
    {
        strcopy(value, sizeof(value), "");
    }

    Call_StartFunction(plugin, callback);
    Call_PushCell(cookieID);
    Call_PushString(g_steamID);
    Call_PushString(value);
    Call_Finish();
}

void Db_SetCookieBySteamID(int cookieID, const char[] steamID, const char[] value)
{
    g_db.Format(g_query, sizeof(g_query), "UPDATE `sm_cookie_cache` SET `value`=\"%s\" WHERE `cookie_id` = '%d' AND `player` REGEXP '^STEAM_[0-9]:%s$' LIMIT 1;", value, cookieID, steamID);
    SQL_FastQuery(g_db, g_query);
}
