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


bool gb_Jugg_Round = false;
bool gb_Jugg_RoundNR = false;
int gi_JuggCountdown = 10;
int gi_Client = 0;

ConVar cv_MPTeammatesAreEnemies;
ConVar cv_HealthBoostPerT = null;
ConVar cv_Ratio = null;


public OnPluginStart()
{
    PrintToChatAll("[JUGG] Loaded successfully");
    
    gi_JuggCountdown = 10;

    cv_MPTeammatesAreEnemies = FindConVar("mp_teammates_are_enemies");

    cv_HealthBoostPerT = CreateConVar("cv_HealthBoostPerT", "50", "Health boost given to CT per T in Juggernaut gamemode", FCVAR_NOTIFY, true, 20.0, true, 500.0);

    cv_Ratio = CreateConVar("cv_Ratio", "6", "How many CT per T", FCVAR_NOTIFY, true, 2.0, true, 10.0);

    RegAdminCmd("sm_jugg", Command_Jugg, ADMFLAG_VOTE, "Start a Juggernaut round");
    RegAdminCmd("sm_canceljugg", Command_CancelJugg, ADMFLAG_VOTE, "Cancel Juggernaut");
    RegAdminCmd("sm_juggernaut", Command_Jugg, ADMFLAG_VOTE, "Start a Juggernaut round");
    RegAdminCmd("sm_chb", Command_CHB, ADMFLAG_VOTE, "Change health boost given to CT");
    RegAdminCmd("sm_ratio", Command_Ratio, ADMFLAG_VOTE, "Change how many CTs per T");
}


public Action Command_Jugg(int client, int args)
{
    if(gb_Jugg_Round || gb_Jugg_RoundNR)
    {
        CPrintToChat(client, "[JUGG] JUGG Round has already been started!");
        return Plugin_Handled;
    }

    if(TTT_IsRoundActive())
    {
        CPrintToChat(client, "[JUGG] A TTT round has already started");
        return Plugin_Handled;
    }

    else
    {
        CPrintToChatAll("[JUGG] Next round will be the Juggernaut gamemode!");
        gi_Client = client;
        gb_Jugg_RoundNR = true;
        return Plugin_Handled;
    }
}

public Action Command_CancelJugg(int client, int args)
{
    if(TTT_IsRoundActive())
    {
        TTT_Error(client, "Can't cancel mid round!");
        return Plugin_Handled;
    }
    if(gb_Jugg_RoundNR)
    {
        gb_Jugg_RoundNR = false;
        CPrintToChatAll("[JUGG] Juggernaut cancelled");
    }

    return Plugin_Handled;
}

public Action Command_CHB(int client, int args)
{
    if(args < 1)
    {
        CPrintToChat(client, "[JUGG] cv_HealthBoostPerT = %i", cv_HealthBoostPerT.IntValue);
        TTT_Usage(client, "sm_chb [healthboost]");
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
        TTT_Usage(client, "sm_ratio [amount]");
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

    if(gb_Jugg_RoundNR)
    {
        JuggPanel();
        HookDMG();
        CreateTimer(1.0, Timer_JuggCountdown, gi_Client, TIMER_REPEAT);
    }
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

public Action Timer_JuggCountdown(Handle timer, int client)
{
    if(gi_JuggCountdown == 0)
    {
        UnHookDMG();
        BeginJugg(client);
        ClearTimer(timer);
        gb_Jugg_RoundNR = false;
        return Plugin_Stop;
    }

    PrintCenterTextAll("Juggernaut Starting in: %i", gi_JuggCountdown);
    CPrintToChatAll("[JUGG] Juggernaut starting in: %i", gi_JuggCountdown);    
    gi_JuggCountdown--;
    return Plugin_Continue;
}

public void TTT_OnRoundEnd(int winner, Handle array)
{
    gi_JuggCountdown = 10;

    if(gb_Jugg_Round)
    {
        EndJugg();
    }
}

public void BeginJugg(int client)
{
    cv_MPTeammatesAreEnemies.SetBool(false, true, true);
    
    if(!gb_Jugg_Round)
    {
        gb_Jugg_Round = true;
    }

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

    CPrintToChatAll("[JUGG] Juggernaut has started!");
}

public void EndJugg()
{
    cv_MPTeammatesAreEnemies.SetBool(true, true, true);
    gb_Jugg_Round = false;
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
    if(gb_Jugg_Round && damagetype != DMG_FALL)
    {
        damage = 0.0;
        return Plugin_Changed;
    }
    else
    {
        return Plugin_Continue;
    }
}