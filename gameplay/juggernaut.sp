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
#include <colorlib>
#include <smlib/math>


bool gb_JuggRound = false;
bool gb_JuggRoundNR = false;
int gi_JuggCountdown = 10;

bool gba_WantsJugg[MAXPLAYERS + 1] = { false, ... }; 
int gi_HowManyWantJugg = 0;

ConVar cv_MPTeammatesAreEnemies;
ConVar cv_CustomGMNR;
ConVar cv_HealthBoostPerT = null;
ConVar cv_Ratio = null;


public OnPluginStart()
{
    PrintToChatAll("[JUGG] Loaded successfully");
    
    gi_JuggCountdown = 10;

    cv_MPTeammatesAreEnemies = FindConVar("mp_teammates_are_enemies");
    cv_CustomGMNR = FindConVar("cv_CustomGMNR");

    cv_HealthBoostPerT = CreateConVar("cv_HealthBoostPerT", "50", "Health boost given to CT per T in Juggernaut gamemode", FCVAR_NOTIFY, true, 20.0, true, 500.0);

    cv_Ratio = CreateConVar("cv_Ratio", "6", "How many CT per T", FCVAR_NOTIFY, true, 2.0, true, 10.0);

    RegConsoleCmd("say", Command_Say);

    RegAdminCmd("sm_reloadjugg", Command_ReloadJugg, ADMFLAG_GENERIC, "Reload Jugg Plugin");
    RegAdminCmd("sm_jugg", Command_Jugg, ADMFLAG_VOTE, "Start a Juggernaut round");
    RegAdminCmd("sm_canceljugg", Command_CancelJugg, ADMFLAG_VOTE, "Cancel Juggernaut");
    RegAdminCmd("sm_juggernaut", Command_Jugg, ADMFLAG_VOTE, "Start a Juggernaut round");
    RegAdminCmd("sm_chb", Command_CHB, ADMFLAG_VOTE, "Change health boost given to CT");
    RegAdminCmd("sm_ratio", Command_Ratio, ADMFLAG_VOTE, "Change how many CTs per T");
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

	if (strcmp(text[startidx], "Jugg", false) == 0)
	{
        if(gb_JuggRoundNR)
        {
            PrintToChat(client, "[JUGG] Jugg has already been voted for");
            return Plugin_Continue;
        }
        if(gb_JuggRound)
        {
            PrintToChat(client, "[JUGG] Jugg has already started");
            return Plugin_Continue;
        }
        if(gba_WantsJugg[client])
        {
            PrintToChat(client, "[JUGG] You already voted for Jugg");
            return Plugin_Continue;
        }
        if(cv_CustomGMNR.BoolValue)
        {
            PrintToChat(client, "[JUGG] A custom gamemode has already been voted for");
            return Plugin_Continue;
        }
        int total = 0;
        int votesNeeded = 0;
        LoopValidClients(i)
        {  
            total++;
        }
        votesNeeded = total - total/3;
        gba_WantsJugg[client] = true;
        gi_HowManyWantJugg++;
        WantsToPlay(client, "Jugg", gi_HowManyWantJugg, votesNeeded);
        if(gi_HowManyWantJugg >= votesNeeded)
        {
            CPrintToChatAll("[JUGG] Next round will be Jugg");
            LoopValidClients(i)
            {
                gba_WantsJugg[i] = false;
                gi_HowManyWantJugg = 0;
            }
            cv_CustomGMNR.SetBool(true, false, true);
            gb_JuggRoundNR = true;
            return Plugin_Continue;
        }
        return Plugin_Continue;
    }
    else 
    {
        return Plugin_Continue;
    }
}

public Action Command_ReloadJugg(int client, int args)
{
    char buffer[256];
    ServerCommandEx(buffer, sizeof(buffer), "sm plugins reload clwo/gameplay/juggernaut");
    PrintToConsole(client, "%s", buffer);
    return Plugin_Handled;
}

public Action Command_Jugg(int client, int args)
{
    if(gb_JuggRoundNR)
    {
        CPrintToChat(client, "[JUGG] JUGG Round has already been started!");
        return Plugin_Handled;
    }
    else
    {
        CPrintToChatAll("[JUGG] Next round will be the Juggernaut gamemode!");
        gb_JuggRoundNR = true;
        cv_CustomGMNR.SetBool(true, false, true);
        return Plugin_Handled;
    }
}

public Action Command_CancelJugg(int client, int args)
{
    if(gb_JuggRoundNR)
    {
        gb_JuggRoundNR = false;
        CPrintToChatAll("[JUGG] Juggernaut cancelled");
        cv_CustomGMNR.SetBool(false, false, true);
    }

    return Plugin_Handled;
}

public Action Command_CHB(int client, int args)
{
    if(args < 1)
    {
        CPrintToChat(client, "[JUGG] cv_HealthBoostPerT = %i", cv_HealthBoostPerT.IntValue);
        CPrintToChat(client, TTT_USAGE ... "sm_chb [healthboost]");
        return Plugin_Handled;
    }

    char buffer[256];
    GetCmdArg(1, buffer, sizeof(buffer));

    cv_HealthBoostPerT.SetInt(StringToInt(buffer), false, true);
    return Plugin_Handled;
}

public Action Command_Ratio(int client, int args)
{
    if(args < 1)
    {
        CPrintToChat(client, "[JUGG] cv_Ratio = %i", cv_Ratio.IntValue);
        CPrintToChat(client, TTT_USAGE ... "sm_ratio [amount]");
        return Plugin_Handled;
    }

    char buffer[256];
    GetCmdArg(1, buffer, sizeof(buffer));

    cv_Ratio.SetInt(StringToInt(buffer), false, true);
    return Plugin_Handled;
}

public void TTT_OnRoundStart(int innocents, int traitors, int detective)
{
    gi_JuggCountdown = 10;

    if(gb_JuggRoundNR)
    {
        JuggPanel();
        HookDMG();
        CreateTimer(1.0, Timer_JuggCountdown, _ , TIMER_REPEAT);
    }
}

public void TTT_OnRoundEnd(int winner, Handle array)
{
    gi_JuggCountdown = 10;

    if(gb_JuggRound)
    {
        EndJugg();
    }
}

public Action Timer_JuggCountdown(Handle timer, int client)
{
    if(gi_JuggCountdown == 0)
    {
        BeginJugg(client);
        ClearTimer(timer);
        gb_JuggRoundNR = false;
        cv_CustomGMNR.SetBool(false, false, true);
        return Plugin_Stop;
    }

    PrintCenterTextAll("Juggernaut Starting in: %i", gi_JuggCountdown);
    CPrintToChatAll("[JUGG] Juggernaut starting in: %i", gi_JuggCountdown);    
    gi_JuggCountdown--;
    return Plugin_Continue;
}


public void BeginJugg(int client)
{
    cv_MPTeammatesAreEnemies.SetBool(false, true, true);
    
    gb_JuggRound = true;

    SetUpTeams(cv_Ratio.IntValue, TTT_TEAM_TRAITOR, TTT_TEAM_DETECTIVE);
    
    int numOfT = 0;

    LoopValidClients(i)
    {
        if(TTT_GetClientRole(i) == TTT_TEAM_TRAITOR)
        {
            numOfT++;
        }
    }

    SetHealth(cv_HealthBoostPerT.IntValue*numOfT);
    GiveHeavy(TTT_TEAM_DETECTIVE);

    UnHookDMG();
    CPrintToChatAll("[JUGG] Juggernaut has started!");
}

public void EndJugg()
{
    cv_MPTeammatesAreEnemies.SetBool(true, true, true);
    gb_JuggRound = false;
}

public void JuggPanel()
{
    Panel panel = new Panel();
    panel.SetTitle("JUGGERNAUT");
    panel.DrawItem("", ITEMDRAW_SPACER);
    panel.DrawText("This is the Juggernaut gamemode");
    panel.DrawItem("", ITEMDRAW_SPACER);
    panel.DrawText("There are some Detectives with heavy suit, everyone else is traitor");
    panel.DrawText("Detective health is also boosted");
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
        SDKHook(i, SDKHook_OnTakeDamage, Jugg_TakeDMG);
    }
}

public void UnHookDMG()
{
    LoopValidClients(i)
    {
        SDKUnhook(i, SDKHook_OnTakeDamage, Jugg_TakeDMG);
    }
}

public Action Jugg_TakeDMG(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(gb_JuggRoundNR && damagetype != DMG_FALL)
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
    if(gba_WantsJugg[client])
    {
        gba_WantsJugg[client] = false;
        gi_HowManyWantJugg--;
    }
    SDKUnhook(client, SDKHook_OnTakeDamage, Jugg_TakeDMG);
}