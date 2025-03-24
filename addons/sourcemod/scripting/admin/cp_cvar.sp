/*
 * CP ConVar Commands by c0rp3n
 *
 * Changelogs:
 * v1.0.0 Initial plugin release, allowed for settings, restoring and protecting
 *        convars from change.
 * v1.1.0 Added support for an allow and deny list of cvars.
 */

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

ConVar g_cvCvarAllowDenyList = null;

StringMap g_smCvarProtected = null;
StringMap g_smCvarDefault   = null;
StringMap g_smCvarList      = null;

char g_sCvarName[64];
char g_sCvarValue[255];

enum VarListMode
{
    VarList_None,
    VarList_Allow,
    VarList_Deny
};

public void OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("plugin.basecommands");

    g_cvCvarAllowDenyList = CreateConVar("cp_convar_list", "0", "Whether to use the allow / deny list of convars (0 off, 1 allow, 2 deny, def. 0).", 0, true, 0.0, true, 2.0);

    g_smCvarProtected = new StringMap();
    g_smCvarDefault   = new StringMap();

    RegServerCmd("sm_protectcvar", ServerCmd_ProtectCvar, "sm_protectcvar <cvar> - Protect a cvar from being changed by sm_setcvar");

    RegAdminCmd("sm_setcvar",    ClientCmd_SetCvar,    ADMFLAG_CONVARS, "sm_setcvar <cvar> [value] - Set the value of a ConVar for until the end of the map");
    RegAdminCmd("sm_revertcvar", ClientCmd_RevertCvar, ADMFLAG_CONVARS, "sm_revertcvar <cvar> - Reset a ConVar back to its original value");
}

public void OnConfigsExecuted()
{
    if (GetVarListMode() == VarList_None)
    {
        return;
    }

    const int mode = FPERM_O_READ | FPERM_O_WRITE | FPERM_O_EXEC;

    static char path[PLATFORM_MAX_PATH];

    BuildPath(Path_SM, path, sizeof(path), "configs/cp");
    if (!DirExists(path))
    {
        CreateDirectory(path, mode);
    }

    BuildPath(Path_SM, path, sizeof(path), "configs/cp/convar_list.txt");
    if (!FileExists(path))
    {
        return;
    }

    File convar_list = OpenFile(path, "r");
    while (convar_list.ReadLine(g_sCvarName, sizeof(g_sCvarName)))
    {
        AddVarToList(g_sCvarName);
    }

    delete convar_list;
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

    LogAction(client, -1, "\"%L\" changed temp cvar (cvar \"%s\") (value \"%s\")", client, g_sCvarName, g_sCvarValue);

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

    LogAction(client, -1, "\"%L\" reset temp cvar (cvar \"%s\") (value \"%s\")", client, g_sCvarName, g_sCvarValue);

    return Plugin_Handled;
}

////////////////////////////////////////////////////////////////////////////////
// Stocks
////////////////////////////////////////////////////////////////////////////////

void ProtectVar(const char[] cvarname)
{
    g_smCvarProtected.SetValue(cvarname, 1);
}

bool IsVarProtected(const char[] cvarname)
{
    int dummy_value;
    return g_smCvarProtected.GetValue(cvarname, dummy_value);
}

bool GetVarDefault(const char[] cvarname, char[] value, int value_size)
{
    return g_smCvarDefault.GetString(cvarname, value, value_size);
}

void SetVarDefault(const char[] cvarname, const char[] value)
{
    g_smCvarDefault.SetString(cvarname, value);
}

bool HasVarBeenChanged(const char[] cvarname)
{
    static char dummy_string[1];
    return g_smCvarDefault.GetString(cvarname, dummy_string, 0);
}

void AddVarToList(const char[] cvarname)
{
    g_smCvarList.SetValue(cvarname, 1);
}

bool IsVarInList(const char[] cvarname)
{
    static char dummy_string[1];
    return g_smCvarList.GetString(cvarname, dummy_string, 0);
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

    if (allowed)
    {
        VarListMode mode = GetVarListMode();
        if (IsVarInList(cvarname))
        {
            // if the var is in the list, but the mode is deny, then this cvar
            // cannot be changed
            if (mode == VarList_Deny)
            {
                allowed = false;
            }
        }
        else if (mode == VarList_Allow)
        {
            // if the cvar is not in the list, but it is in allow mode, then
            // this cvar cannot be changed
            allowed = false;
        }
    }

    return allowed;
}

VarListMode GetVarListMode()
{
    int mode = g_cvCvarAllowDenyList.IntValue;
    if (mode == 0)
    {
        return VarList_None;
    }
    else if (mode == 1)
    {
        return VarList_Allow;
    }
    else if (mode == 2)
    {
        return VarList_Deny;
    }

    return VarList_None;
}
