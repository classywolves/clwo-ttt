#pragma semicolon 1

//Base CS:GO Plugin Requirements
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

//Custom includes
#include <ttt>
#include <gamemodes>
#include <ttt_messages>
#include <ttt_targeting>
#include <generics>
#include <colorvariables>
#include <smlib/math>

ConVar g_cvMPTeammatesAreEnemies;
bool gb_TDM_Round = false;
bool gb_TDM_RoundNR = false;
int gi_TDMCountdown = 10;
int g_Client = 0;

public OnPluginStart()
{
    PrintToChatAll("[TDM] Loaded successfully");

    gi_TDMCountdown = 10;

    g_cvMPTeammatesAreEnemies = FindConVar("mp_teammates_are_enemies");

    RegAdminCmd("sm_tdm", Command_TDM, ADMFLAG_VOTE, "Start a heavy suit team deathmatch");
    RegAdminCmd("sm_canceltdm", Command_CancelTDM, ADMFLAG_VOTE, "Cancel heavy suit team deathmatch");
    RegAdminCmd("sm_teamdeathmatch", Command_TDM, ADMFLAG_VOTE, "Start a heavy suit team deathmatch");
    RegAdminCmd("sm_role", Command_Role, ADMFLAG_VOTE, "Gib role");
    RegAdminCmd("sm_hvy", Command_Heavy, ADMFLAG_ROOT, "Gib heavy");
    RegAdminCmd("sm_heavy", Command_Heavy, ADMFLAG_ROOT, "Gib heavy");
}

public void TTT_OnRoundStart(int innocents, int traitors, int detective)
{
    gi_TDMCountdown = 10;

    if(gb_TDM_RoundNR)
    {
        TDMPanel();
        HookDMG();
        CreateTimer(1.0, Timer_TDMCountdown, g_Client, TIMER_REPEAT);
    }
}

public void TTT_OnRoundEnd(int winner, Handle array)
{
    gi_TDMCountdown = 10;

    if(gb_TDM_Round)
    {
        EndTDM();
    }
}

public Action Command_TDM(int client, int args)
{
    if(gb_TDM_Round)
    {
        CPrintToChat(client, "[TDM] TDM Round has already been started!");
        return Plugin_Handled;
    }
    else
    {
        CPrintToChatAll("[TDM] Next round will be a Team Deathmatch!");
        g_Client = client;
        gb_TDM_RoundNR = true;
        return Plugin_Handled;
    }
}

public Action Command_CancelTDM(int client, int args)
{
    if(TTT_IsRoundActive())
    {
        TTT_Error(client, "Can't cancel mid round!");
        return Plugin_Handled;
    }

    if(gb_TDM_RoundNR)
    {
        CPrintToChatAll("[TDM] Team deathmatch cancelled");
        gb_TDM_RoundNR = false;
    }

    return Plugin_Handled;
}

public Action Command_Role(int client, int args)
{
    CPrintToChat(client, "Your role number is %i", TTT_GetClientRole(client));
    return Plugin_Handled;
}

public Action Command_Heavy(int client, int args)
{
    if(args < 1)
    {
        GivePlayerItem(client, "item_heavyassaultsuit");
        return Plugin_Handled;
    }

    char buffer[MAX_NAME_LENGTH];
    GetCmdArg(1, buffer, MAX_NAME_LENGTH);
    int target = TTT_Target(buffer, client, true, false, false);

    if(!IsValidClient(target) || !IsAliveClient(target))
    {
        TTT_Error(client, "Invalid target!");
        return Plugin_Handled;
    }

    GivePlayerItem(target, "item_heavyassaultsuit");
    return Plugin_Handled;
}

public void BeginTDM(int client)
{
    g_cvMPTeammatesAreEnemies.SetBool(false, true, true);
    
    if(!gb_TDM_Round)
    {
        gb_TDM_Round = true;
    }

    SetUpTeams(2);
    GiveHeavy(TTT_TEAM_DETECTIVE);
    GiveHeavy(TTT_TEAM_TRAITOR);

    CPrintToChatAll("[TDM] A Team deathmatch has started!");
}

public void EndTDM()
{
    g_cvMPTeammatesAreEnemies.SetBool(true, true, true);
    gb_TDM_Round = false;
}

public void TDMPanel()
{
    Panel panel = new Panel();
    panel.SetTitle("TEAM DEATHMATCH");
    panel.DrawItem("", ITEMDRAW_SPACER);
    panel.DrawText("This is a Team Deathmatch Round, with everyone in heavy suits!");
    panel.DrawItem("", ITEMDRAW_SPACER);
    panel.DrawText("Kill anyone who isn't on your Team!");
    panel.DrawItem("", ITEMDRAW_SPACER);
    panel.CurrentKey = GetMaxPageItems(panel.Style);
    panel.DrawItem("Exit", ITEMDRAW_CONTROL);

    LoopValidClients(i)
    {
        panel.Send(i, HandlerDoNothing, 30);
    }

    delete panel;    
}

public Action Timer_TDMCountdown(Handle timer, int client)
{
    if(gi_TDMCountdown == 0)
    {
        UnHookDMG();
        BeginTDM(client);
        ClearTimer(timer);
        gb_TDM_RoundNR = false;
        return Plugin_Stop;
    }

    PrintCenterTextAll("TDM Starting in: %i", gi_TDMCountdown);
    CPrintToChatAll("[TDM] Team deathmatch starting in: %i", gi_TDMCountdown);    
    gi_TDMCountdown--;
    return Plugin_Continue;
}
public void HookDMG()
{
    LoopValidClients(i)
    {
        SDKHook(i, SDKHook_OnTakeDamage, TDM_TakeDMG);
    }
}

public void UnHookDMG()
{
    LoopValidClients(i)
    {
        SDKUnhook(i, SDKHook_OnTakeDamage, TDM_TakeDMG);
    }
}

public Action TDM_TakeDMG(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(gb_TDM_RoundNR && damagetype != DMG_FALL)
    {
        damage = 0.0;
        return Plugin_Changed;
    }
    else
    {
        return Plugin_Continue;
    }
}