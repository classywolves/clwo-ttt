//Base CS:GO Plugin Requirements
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

//Custom includes
#include <ttt>
#include <ttt_messages>
#include <ttt_targeting>
#include <generics>
#include <colorvariables>
#include <smlib/math>


bool gb_Jugg_Round = false;
int gi_Countdown = 3;
int gi_Client = 0;
int gi_TotalNumOfCT = 0;

ConVar cv_MPTeammatesAreEnemies;
ConVar cv_HealthBoostPerT = null;
ConVar cv_Ratio = null;
ConVar cv_Solo = null;


public OnPluginStart()
{
    gi_Countdown = 3;

    cv_MPTeammatesAreEnemies = FindConVar("mp_teammates_are_enemies");

    cv_HealthBoostPerT = CreateConVar("cv_HealthBoostPerT", "50", "Health boost given to CT per T in Juggernaut gamemode", FCVAR_NOTIFY, true, 20.0, true, 500.0);

    cv_Ratio = CreateConVar("cv_Ratio", "6", "How many CT per T", FCVAR_NOTIFY, true, 2.0, true, 10.0);

    cv_Solo = CreateConVar("cv_Solo", "false", "Solo mode", FCVAR_NOTIFY);

    RegAdminCmd("sm_jugg", Command_Jugg, ADMFLAG_BAN, "Start a Juggernaut round");
    RegAdminCmd("sm_canceljugg", Command_CancelJugg, ADMFLAG_BAN, "Cancel Juggernaut");
    RegAdminCmd("sm_juggernaut", Command_Jugg, ADMFLAG_BAN, "Start a Juggernaut round");
    RegAdminCmd("sm_chb", Command_CHB, ADMFLAG_BAN, "Change health boost given to CT");
    RegAdminCmd("sm_ratio", Command_Ratio, ADMFLAG_BAN, "Change how many CTs per T");
    RegAdminCmd("sm_solo", Command_Solo, ADMFLAG_BAN, "Set it to solo mode");
}

public Action Command_Jugg(int client, int args)
{
    if(gb_Jugg_Round)
    {
        CPrintToChat(client, "[JUGG] JUGG Round has already been started!")
        return Plugin_Handled;
    }

    if(TTT_IsRoundActive())
    {
        BeginJugg(client);
        return Plugin_Handled;
    }

    else
    {
        CPrintToChatAll("[JUGG] Next round will be the Juggernaut gamemode!");
        gi_Client = client;
        gb_Jugg_Round = true;
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

    if(gb_Jugg_Round)
    {
        gb_Jugg_Round = false;
    }

    CPrintToChatAll("[JUGG] Juggernaut cancelled");
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

public Action Command_Solo(int client, int args)
{
    if(args > 0)
    {
        if(cv_Solo.BoolValue)
        {
            CPrintToChat(client, "[JUGG] cv_Solo = true");
        }
        if(!cv_Solo.BoolValue)
        {
            CPrintToChat(client, "[JUGG] cv_Solo = false");
        }
        
        return Plugin_Handled;
    }

    if(cv_Solo.BoolValue)
    {
        cv_Solo.SetBool(false, false, true);
    }
    if(!cv_Solo.BoolValue)
    {
        cv_Solo.SetBool(true, false, true);
    }

    return Plugin_Handled;
}

public void TTT_OnRoundStart(int innocents, int traitors, int detective)
{
    gi_Countdown = 3;

    if(gb_Jugg_Round)
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
    if(gi_Countdown <= 0)
    {
        UnHookDMG();
        BeginJugg(client);
        return Plugin_Stop;
    }

    PrintCenterTextAll("Juggernaut Starting in: %i", gi_Countdown);
    CPrintToChatAll("[JUGG] Juggernaut starting in: %i", gi_Countdown);    
    gi_Countdown--;
    return Plugin_Continue;
}

public void TTT_OnRoundEnd(int winner, Handle array)
{
    gi_Countdown = 3;

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

    SetUpTeams(client);

    CPrintToChatAll("[JUGG] Juggernaut has started!");
}

public void SetUpTeams(int client)
{
    PrintToConsole(client, "[JUGG] Teams are being set up");

    ArrayList tList = new ArrayList(1, 0);
    ArrayList dList = new ArrayList(1, 0);

    int totalPlayers = 0;

    LoopValidClients(i)
    {
        if(!IsAliveClient(i))
        {
            PrintToConsole(client, "[JUGG] %N is dead, skipping", i);
            continue;
        }
        if(TTT_GetClientRole(i) == 8)
        {
            dList.Push(i)
            PrintToConsole(client, "[JUGG] %N is a Detective", i);
            totalPlayers++;
            continue;
        }
        tList.Push(i);
        PrintToConsole(client, "[JUGG] %N is a Traitor or Innocent", i);
        totalPlayers++;    
    }

    int numOfCT = totalPlayers/cv_Ratio.IntValue;

    if(numOfCT == 0)
    {
        numOfCT = 1;
    }

    if(!cv_Solo.BoolValue)
    {
        for(int d = dList.Length; d < numOfCT; d++)
        {
            int index = Math_GetRandomInt(0, tList.Length);
            int random = tList.Get(index, 0);
            tList.Erase(index);
            dList.Push(random);
            PrintToConsole(client, "[JUGG] %N moved to Detective team", random);
        }
    }
    else
    {
        CPrintToChatAll("[JUGG] Solo mode!");
        if(dList.Length < 1)
        {
            for(int d = dList.Length; d > 1; d--)
            {
                int index = Math_GetRandomInt(0, dList.Length);
                int random = dList.Get(index, 0);
                dList.Erase(index);
                tList.Push(random);
                PrintToConsole(client, "[JUGG] %N moved to Traitor team", random);
            }
        }
    }

    CreateTeams(tList, dList, client);
}

public void CreateTeams(ArrayList traitorTeam, ArrayList detectiveTeam, int client)
{
    PrintToConsole(client, "[JUGG] Creating teams")

    for(int t = 0; t <= traitorTeam.Length - 1; t++)
    {
        int player = traitorTeam.Get(t, 0);
        if(TTT_GetClientRole(player) != 4)
        {    
            TTT_SetClientRole(player, 4);
        }
        PrintToConsole(client, "[JUGG] %N is on the Traitor team", player);
    }
    PrintToConsole(client, "[JUGG] Traitor team created successfully");
    
    for(int d = 0; d <= detectiveTeam.Length - 1; d++)
    {
        int player = detectiveTeam.Get(d, 0);
        if(TTT_GetClientRole(player) != 8)
        {
            TTT_SetClientRole(player, 8);
        }
        PrintToConsole(client, "[JUGG] %N is on the Detective team", player);
    }
    PrintToConsole(client, "[JUGG] Detective team created successfully");

    PrintToConsole(client, "[JUGG] Teams created successfully!");

    HealthBoost(traitorTeam, detectiveTeam, client);
}

public void HealthBoost(ArrayList traitorTeam, ArrayList detectiveTeam, int client)
{
    int TotalHealthBoost = traitorTeam.Length*cv_HealthBoostPerT.IntValue;

    for(int d = 0; d <= detectiveTeam.Length - 1; d++)
    {
        int player = detectiveTeam.Get(d, 0);
        SetEntityHealth(player, 100 + TotalHealthBoost);
        PrintToConsole(client, "[JUGG] %N health boosted by {orange}%i", player, TotalHealthBoost);
    }
        
    CPrintToChatAll("[JUGG] {darkblue}CT {default}healthboost: {orange}%i", TotalHealthBoost);

    GiveHeavy(detectiveTeam, client);
}

public void GiveHeavy(ArrayList detectiveTeam, int client)
{
    for(int d = 0; d <= detectiveTeam.Length - 1; d++)
    {
        int player = detectiveTeam.Get(d, 0);
        GivePlayerItem(player, "item_heavyassaultsuit");
        PrintToConsole(client, "[JUGG] %N given heavy suit", player);
        gi_TotalNumOfCT++
    }

    CPrintToChatAll("[JUGG] Number of {darkblue}CTs{default}: {orange}%i", gi_TotalNumOfCT);
}

public void EndJugg()
{
    cv_MPTeammatesAreEnemies.SetBool(true, true, true);
    gb_Jugg_Round = false;

    gi_TotalNumOfCT = 0;
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
        SDKUnhook(i, SDKHook_OnTakeDamage, Jugg_TakeDMG)
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