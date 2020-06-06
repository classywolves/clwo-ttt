#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <colorvariables>
#include <ttt>
#include <generics>
#include <ttt_messages>
#include <ttt_targeting>

public Plugin myinfo = {
    name = "Random Death Match manager",
    author = "Popey & c0rp3n",
    description = "Random Death Match manager and handler for Trouble in Terrorist Town.",
    version = "1.1.0",
    url = ""
};

Database g_database = null;

int g_currentRound = -1;
int g_lastDeathIndex = -1;

enum CaseChoice
{
    CaseChoice_None,
    CaseChoice_Warn,
    CaseChoice_Slay
};

enum CaseVerdict
{
    CaseVerdict_None,
    CaseVerdict_Innocent,
    CaseVerdict_Guilty
};

enum Role
{
    Role_None,
    Role_Innocent,
    Role_Traitor,
    Role_Detective
}

enum struct PlayerData
{
    int currentCase;
    int currentDeath;
    int lastGunFired;
}

PlayerData g_playerData[MAXPLAYERS + 1];

#include "rdm/database.sp"
#include "rdm/menus.sp"

public OnPluginStart()
{
    RegConsoleCmd("sm_rdm", Command_RDM, "Shows the RDM report window for all recent killers.");
    RegAdminCmd("sm_cases", Command_CaseCount, ADMFLAG_GENERIC, "Shows the current amount of cases to staff.");
    RegAdminCmd("sm_handle", Command_Handle, ADMFLAG_GENERIC, "Handles the next case or a user inputted case.");
    RegAdminCmd("sm_info", Command_Info, ADMFLAG_GENERIC, "Displays all of the information for a given case.");
    RegAdminCmd("sm_verdict", Command_Verdict, ADMFLAG_GENERIC, "Shows a member of staff the availible verdicts for there current case.");
    
    HookEvent("weapon_fire", Event_OnWeaponFire, EventHookMode_Post);

    LoopValidClients(i)
    {
        OnClientPutInServer(i);
    }

    Database.Connect(DbCallback_Connect, "rdm");

    PrintToServer("[RDM] Loaded successfully");
}

public void OnClientPutInServer(int client)
{
    g_playerData[client].currentCase = -1;
    g_playerData[client].currentDeath = -1;
    g_playerData[client].lastGunFired = 0;
}

public void TTT_OnRoundStart(int roundid, int innocents, int traitors, int detective)
{
    g_currentRound = roundid;
}

public void TTT_OnClientDeath(int victim, int attacker)
{
    int victimKarma = TTT_GetClientKarma(victim);
    int attackerKarma = TTT_GetClientKarma(attacker);

    if(BadKill(TTT_GetClientRole(attacker), TTT_GetClientRole(victim)))
    {
        CPrintToChatAdmins("sm_kick", TTT_MESSAGE ... "{default}Bad Action: [{yellow}%N{default}] ({orange}%d{default}) killed [{yellow}%N{default}] ({orange}%d{default})", attacker, attackerKarma, victim, victimKarma);
    }

    Db_InsertDeath(victim, attacker);
}

public Action Command_CaseCount(int client, int args)
{
    Db_SelectCaseCount();

    return Plugin_Handled;
}

public Action Command_Handle(int client, int args)
{
    if (g_playerData[client].currentCase > -1)
    {
        CPrintToChat(client, TTT_ERROR ... "You cannot handle a new case whilst you still have a case awaiting your verdict.");
        return Plugin_Handled;
    }

    Db_SelectNextCase(client);

    return Plugin_Handled;
}

public Action Command_Info(int client, int args)
{
    Db_SelectInfo(client);

    return Plugin_Handled;
}

public Action Command_RDM(int client, int args)
{
    Db_SelectClientDeaths(client);

    return Plugin_Handled;
}

public Action Command_Verdict(int client, int args)
{
    if (g_playerData[client].currentCase < 0)
    {
        CPrintToChat(client, TTT_ERROR ... "You do not currently have a case to cast a verdict upon.");
        return Plugin_Handled;
    }

    if (args < 1)
    {
        Menu verdictMenu = new Menu(MenuHandler_Verdict);
        verdictMenu.AddItem("", "Innocent");
        verdictMenu.AddItem("", "Guilty");
        verdictMenu.Display(client, 240);
    }
    else
    {
        char response[64];
        GetCmdArg(1, response, 64);

        CaseVerdict verdict = CaseVerdict_None;
        if (strcmp(response, "innocent", false) == 0)
        {
            verdict = CaseVerdict_Innocent;
        }
        else if (strcmp(response, "guilty", false) == 0)
        {
            verdict = CaseVerdict_Guilty;
        }

        if (verdict == CaseVerdict_Innocent || verdict == CaseVerdict_Guilty)
        {
            Db_UpdateVerdict(client, g_playerData[client].currentCase, verdict);
        }
        else
        {
            CPrintToChat(client, TTT_ERROR ... "Please pass either Innocent or Guilty.");
        }
    }

    return Plugin_Handled;
}

public void Event_OnWeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    g_playerData[GetClientOfUserId(event.GetInt("userid"))].lastGunFired = GetTime();
}

public void TTT_OnRoundEnd(int winner, Handle array)
{
    Db_SelectCaseCount();
}

public void RoleString(char[] buffer, int maxlength, Role role)
{
    switch (role)
    {
        case Role_Innocent:
        {
            strcopy(buffer, maxlength, "{green}Innocent");
        }
        case Role_Traitor:
        {
            strcopy(buffer, maxlength, "{red}Traitor");
        }
        case Role_Detective:
        {
            strcopy(buffer, maxlength, "{blue}Detective");
        }
    }
}

public void RoleEnum(char[] buffer, int maxlength, int role)
{
    if (role == TTT_TEAM_INNOCENT)
    {
        strcopy(buffer, maxlength, "innocent");
    }
    else if (role == TTT_TEAM_TRAITOR)
    {
        strcopy(buffer, maxlength, "traitor");
    }
    else if (role == TTT_TEAM_DETECTIVE)
    {
        strcopy(buffer, maxlength, "detective");
    }
    else
    {
        strcopy(buffer, maxlength, "none");
    }
}

public bool BadKill(int attackerRole, int victimRole)
{
    if (attackerRole == victimRole) {
        return true;
    }
    //else if (attackerRole == TTT_TEAM_TRAITOR || victimRole == TTT_TEAM_TRAITOR) return false;
    else if (attackerRole == TTT_TEAM_TRAITOR) 
    {
        return false;
    }
    else {
        return true;
    }
}