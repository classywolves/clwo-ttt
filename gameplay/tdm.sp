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
ConVar cv_CustomGMNR;
bool gb_TDMRound = false;
bool gb_TDMRoundNR = false;
int gi_TDMCountdown = 10;

bool gba_WantsTDM[MAXPLAYERS + 1] = { false, ... }; 
int gi_HowManyWantTDM = 0;

public OnPluginStart()
{
    PrintToChatAll("[TDM] Loaded successfully");

    gi_TDMCountdown = 10;

    g_cvMPTeammatesAreEnemies = FindConVar("mp_teammates_are_enemies");
    cv_CustomGMNR = FindConVar("cv_CustomGMNR");

    RegConsoleCmd("say", Command_Say);

    RegAdminCmd("sm_reloadtdm", Command_ReloadTDM, ADMFLAG_GENERIC, "Reload TDM Plugin");
    RegAdminCmd("sm_tdm", Command_TDM, ADMFLAG_VOTE, "Start a heavy suit team deathmatch");
    RegAdminCmd("sm_teamdeathmatch", Command_TDM, ADMFLAG_VOTE, "Start a heavy suit team deathmatch");
    RegAdminCmd("sm_canceltdm", Command_CancelTDM, ADMFLAG_VOTE, "Cancel heavy suit team deathmatch");
}

public Action Command_Say(int client, int args)
{
    char text[192], command[64];
	GetCmdArgString(text, sizeof(text));
	GetCmdArg(0, command, sizeof(command));

	int startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	if (strcmp(text[startidx], "TDM", false) == 0 || strcmp(text[startidx], "team deathmatch", false) == 0)
	{
        if(gb_TDMRoundNR)
        {
            PrintToChat(client, "[TDM] TDM has already been voted for");
            return Plugin_Continue;
        }
        if(gb_TDMRound)
        {
            PrintToChat(client, "[TDM] TDM has already started");
            return Plugin_Continue;
        }
        if(gba_WantsTDM[client])
        {
            PrintToChat(client, "[TDM] You already voted for TDM");
            return Plugin_Continue;
        }
        if(cv_CustomGMNR.BoolValue)
        {
            PrintToChat(client, "[TDM] A custom gamemode has already been voted for");
            return Plugin_Continue;
        }
        int total = 0;
        int votesNeeded = 0;
        LoopValidClients(i)
        {  
            total++;
        }
        votesNeeded = total - total/3;
        gba_WantsTDM[client] = true;
        gi_HowManyWantTDM++;
        WantsToPlay(client, "TDM", gi_HowManyWantTDM, votesNeeded);
        if(gi_HowManyWantTDM >= votesNeeded)
        {
            CPrintToChatAll("[TDM] Next round will be TDM");
            LoopValidClients(i)
            {
                gba_WantsTDM[i] = false;
                gi_HowManyWantTDM = 0;
            }
            cv_CustomGMNR.SetBool(true, false, true);
            gb_TDMRoundNR = true;
            return Plugin_Continue;
        }
        return Plugin_Continue;
    }
    else 
    {
        return Plugin_Continue;
    }
}

public Action Command_ReloadTDM(int client, int args)
{
    char buffer[256];
    ServerCommandEx(buffer, sizeof(buffer), "sm plugins reload clwo/gameplay/tdm");
    PrintToConsole(client, "%s", buffer);
    return Plugin_Handled;
}

public Action Command_TDM(int client, int args)
{
    if(gb_TDMRoundNR)
    {
        CPrintToChat(client, "[TDM] TDM Round has already been started!");
        return Plugin_Handled;
    }
    else
    {
        CPrintToChatAll("[TDM] Next round will be a Team Deathmatch!");
        gb_TDMRoundNR = true;
        cv_CustomGMNR.SetBool(true, false, true);
        return Plugin_Handled;
    }
}

public Action Command_CancelTDM(int client, int args)
{
    if(gb_TDMRoundNR)
    {
        CPrintToChatAll("[TDM] Team deathmatch cancelled");
        gb_TDMRoundNR = false;
        cv_CustomGMNR.SetBool(false, false, true);
    }

    return Plugin_Handled;
}

public void TTT_OnRoundStart(int innocents, int traitors, int detective)
{
    gi_TDMCountdown = 10;

    if(gb_TDMRoundNR)
    {
        TDMPanel();
        HookDMG();
        CreateTimer(1.0, Timer_TDMCountdown, _ , TIMER_REPEAT);
    }
}

public void TTT_OnRoundEnd(int winner, Handle array)
{
    gi_TDMCountdown = 10;

    if(gb_TDMRound)
    {
        EndTDM();
    }
}

public Action Timer_TDMCountdown(Handle timer)
{
    if(gi_TDMCountdown == 0)
    {
        BeginTDM(client);
        ClearTimer(timer);
        gb_TDMRoundNR = false;
        cv_CustomGMNR.SetBool(false, false, true);
        return Plugin_Stop;
    }

    PrintCenterTextAll("TDM Starting in: %i", gi_TDMCountdown);
    CPrintToChatAll("[TDM] Team deathmatch starting in: %i", gi_TDMCountdown);    
    gi_TDMCountdown--;
    return Plugin_Continue;
}

public void BeginTDM(int client)
{
    g_cvMPTeammatesAreEnemies.SetBool(false, true, true);

    gb_TDMRound = true;

    SetUpTeams(2);
    GiveHeavy(TTT_TEAM_DETECTIVE);
    GiveHeavy(TTT_TEAM_TRAITOR);
    
    UnHookDMG();

    CPrintToChatAll("[TDM] A Team deathmatch has started!");
}

public void EndTDM()
{
    g_cvMPTeammatesAreEnemies.SetBool(true, true, true);
    gb_TDMRound = false;
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
    if(gb_TDMRoundNR)
    {
        damage = 0.0;
        return Plugin_Changed;
    }
    else
    {
        return Plugin_Continue;
    }
}

public void OnClientDisconnect(int client)
{
    if(gba_WantsTDM[client])
    {
        gba_WantsTDM[client] = false;
        gi_HowManyWantTDM--;
    }
    SDKUnhook(client, SDKHook_OnTakeDamage, TDM_TakeDMG);
}