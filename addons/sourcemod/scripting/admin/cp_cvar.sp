#pragma semicolon 1

#include <sourcemod>

public Plugin myinfo =
{
    name = "CP ConVar Commands",
    author = "c0rp3n",
    description = "",
    version = "0.1.0",
    url = ""
};

StringMap g_smCvarProtected = null;
StringMap g_smCvarDefault   = null;

char g_sCvarName[64];
char g_sCvarValue[255];

public void OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("plugin.basecommands");

    g_smCvarProtected = new StringMap();
    g_smCvarDefault   = new StringMap();

    RegServerCmd("sm_protectcvar", ServerCmd_ProtectCvar, "sm_protectcvar <cvar> - Protect a cvar from being changed by sm_setcvar");

    RegAdminCmd("sm_setcvar",    ClientCmd_SetCvar,    ADMFLAG_CONVARS, "sm_setcvar <cvar> [value] - Set the value of a ConVar for until the end of the map");
    RegAdminCmd("sm_revertcvar", ClientCmd_RevertCvar, ADMFLAG_CONVARS, "sm_revertcvar <cvar> - Reset a ConVar back to its original value");
}

public void OnMapEnd()
{
    StringMapSnapshot smpCvars = g_smCvarDefault.Snapshot();
    int size = smpCvars.Length;
    for (int i = 0; i < size; ++i)
    {
        smpCvars.GetKey(i, g_sCvarName, sizeof(g_sCvarName));

        ConVar hndl = FindConVar(g_sCvarName);
        if (hndl == null)
        {
            continue;
        }

        g_smCvarDefault.GetString(g_sCvarName, g_sCvarValue, sizeof(g_sCvarValue));

        hndl.SetString(g_sCvarValue, true);
    }

    g_smCvarDefault.Clear();

    delete smpCvars;
}

////////////////////////////////////////////////////////////////////////////////
// Server Commands
////////////////////////////////////////////////////////////////////////////////

public Action ServerCmd_ProtectCvar(int argc)
{
    if (argc < 2)
    {
        PrintToServer("[SM] Usage: sm_cvar <protect> <cvar>");

        return Plugin_Handled;
    }

    GetCmdArg(1, g_sCvarName, sizeof(g_sCvarName));
    ProtectVar(g_sCvarName);
    PrintToServer("[SM] %t", "Cvar is now protected", g_sCvarName);

    return Plugin_Handled;
}

////////////////////////////////////////////////////////////////////////////////
// Client Commands
////////////////////////////////////////////////////////////////////////////////

public Action ClientCmd_SetCvar(int client, int argc)
{
    if (argc < 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_setcvar <cvar> [value]");

        return Plugin_Handled;
    }

    GetCmdArg(1, g_sCvarName, sizeof(g_sCvarName));

    ConVar hndl = FindConVar(g_sCvarName);
    if (hndl == null)
    {
        ReplyToCommand(client, "[SM] %t", "Unable to find cvar", g_sCvarName);
        return Plugin_Handled;
    }

    if (!IsClientAllowedToChangeCvar(client, g_sCvarName))
    {
        ReplyToCommand(client, "[SM] %t", "No access to cvar");
        return Plugin_Handled;
    }

    if (argc < 2)
    {
        hndl.GetString(g_sCvarValue, sizeof(g_sCvarValue));

        ReplyToCommand(client, "[SM] %t", "Value of cvar", g_sCvarName, g_sCvarValue);
        return Plugin_Handled;
    }

    if (!HasVarBeenChanged(g_sCvarName))
    {
        hndl.GetString(g_sCvarValue, sizeof(g_sCvarValue));
        SetVarDefault(g_sCvarName, g_sCvarValue);
    }

    GetCmdArg(2, g_sCvarValue, sizeof(g_sCvarValue));
    
    // The server passes the values of these directly into ServerCommand, following exec. Sanitize.
    if (StrEqual(g_sCvarName, "servercfgfile", false) || StrEqual(g_sCvarName, "lservercfgfile", false))
    {
        int pos = StrContains(g_sCvarValue, ";", true);
        if (pos != -1)
        {
            g_sCvarValue[pos] = '\0';
        }
    }

    if ((hndl.Flags & FCVAR_PROTECTED) != FCVAR_PROTECTED)
    {
        ShowActivity2(client, "[SM] ", "%t", "Cvar changed", g_sCvarName, g_sCvarValue);
    }
    else
    {
        ReplyToCommand(client, "[SM] %t", "Cvar changed", g_sCvarName, g_sCvarValue);
    }

    LogAction(client, -1, "\"%L\" changed cvar (cvar \"%s\") (value \"%s\")", client, g_sCvarName, g_sCvarValue);

    hndl.SetString(g_sCvarValue, true);

    return Plugin_Handled;
}

public Action ClientCmd_RevertCvar(int client, int argc)
{
    if (argc < 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_revertcvar <cvar>");

        return Plugin_Handled;
    }

    GetCmdArg(1, g_sCvarName, sizeof(g_sCvarName));

    ConVar hndl = FindConVar(g_sCvarName);
    if (hndl == null)
    {
        ReplyToCommand(client, "[SM] %t", "Unable to find cvar", g_sCvarName);
        return Plugin_Handled;
    }

    if (!IsClientAllowedToChangeCvar(client, g_sCvarName))
    {
        ReplyToCommand(client, "[SM] %t", "No access to cvar");
        return Plugin_Handled;
    }

    if (GetVarDefault(g_sCvarName, g_sCvarValue, sizeof(g_sCvarValue)))
    {
        if ((hndl.Flags & FCVAR_PROTECTED) != FCVAR_PROTECTED)
        {
            ShowActivity2(client, "[SM] ", "%t", "Cvar changed", g_sCvarName, g_sCvarValue);
        }
        else
        {
            ReplyToCommand(client, "[SM] %t", "Cvar changed", g_sCvarName, g_sCvarValue);
        }

        hndl.SetString(g_sCvarValue, true);
    }

    return Plugin_Handled;
}

////////////////////////////////////////////////////////////////////////////////
// Stocks
////////////////////////////////////////////////////////////////////////////////

void ProtectVar(const char[] cvar)
{
    g_smCvarProtected.SetValue(cvar, 1);
}

bool IsVarProtected(const char[] cvar)
{
    int dummy_value;
    return g_smCvarProtected.GetValue(cvar, dummy_value);
}

bool GetVarDefault(const char[] cvar, char[] value, int value_size)
{
    return g_smCvarDefault.GetString(cvar, value, value_size);
}

void SetVarDefault(const char[] cvar, const char[] value)
{
    g_smCvarDefault.SetString(cvar, value);
}

bool HasVarBeenChanged(const char[] cvar)
{
    static char dummy_string[1];
    return g_smCvarDefault.GetString(cvar, dummy_string, 0);
}

bool IsClientAllowedToChangeCvar(int client, const char[] cvarname)
{
    ConVar hndl = FindConVar(cvarname);

    bool allowed = false;
    int client_flags = client == 0 ? ADMFLAG_ROOT : GetUserFlagBits(client);
    
    if (client_flags & ADMFLAG_ROOT)
    {
        allowed = true;
    }
    else
    {
        if (hndl.Flags & FCVAR_PROTECTED)
        {
            allowed = ((client_flags & ADMFLAG_PASSWORD) == ADMFLAG_PASSWORD);
        }
        else if (StrEqual(cvarname, "sv_cheats"))
        {
            allowed = ((client_flags & ADMFLAG_CHEATS) == ADMFLAG_CHEATS);
        }
        else if (!IsVarProtected(cvarname))
        {
            allowed = true;
        }
    }

    return allowed;
}
