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

ConVar g_cvMPTeammatesAreEnemies;
bool g_TDM_Round = false;
int g_Countdown = 3;
int g_Client = 0;



public OnPluginStart()
{
    g_Countdown = 3;

    g_cvMPTeammatesAreEnemies = FindConVar("mp_teammates_are_enemies");

    RegAdminCmd("sm_tdm", Command_TDM, ADMFLAG_BAN, "Start a heavy suit team deathmatch");
    RegAdminCmd("sm_canceltdm", Command_CancelTDM, ADMFLAG_BAN, "Cancel heavy suit team deathmatch");
    RegAdminCmd("sm_teamdeathmatch", Command_TDM, ADMFLAG_BAN, "Start a heavy suit team deathmatch");
    RegAdminCmd("sm_role", Command_Role, ADMFLAG_BAN, "Gib role");
    RegAdminCmd("sm_hvy", Command_Heavy, ADMFLAG_ROOT, "Gib heavy");
    RegAdminCmd("sm_heavy", Command_Heavy, ADMFLAG_ROOT, "Gib heavy");
    RegAdminCmd("sm_random", Command_Random, ADMFLAG_BAN, "Random player");
}

public void TTT_OnRoundStart(int innocents, int traitors, int detective)
{
    g_Countdown = 3;

    if(g_TDM_Round)
    {
        TDMPanel();
        HookDMG();
        CreateTimer(1.0, Timer_TDMCountdown, g_Client, TIMER_REPEAT);
    }
}

public void TTT_OnRoundEnd(int winner, Handle array)
{
    g_Countdown = 3;

    if(g_TDM_Round)
    {
        EndTDM();
    }
}

public Action Command_TDM(int client, int args)
{
    if(g_TDM_Round)
    {
        CPrintToChat(client, "[TDM] TDM Round has already been started!")
        return Plugin_Handled;
    }

    if(TTT_IsRoundActive())
    {
        BeginTDM(client);
        return Plugin_Handled;
    }

    else
    {
        CPrintToChatAll("[TDM] Next round will be a Team Deathmatch!");
        g_Client = client;
        g_TDM_Round = true;
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

    if(g_TDM_Round)
    {
        g_TDM_Round = false;
    }

    CPrintToChatAll("[TDM] Team deathmatch cancelled");
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

public Action Command_Random(int client, int args)
{
    int player = RandomClient(0, false);
    CPrintToChat(client, "Random Player: %i", player);
}

public void BeginTDM(int client)
{
    g_cvMPTeammatesAreEnemies.SetBool(false, true, true);
    
    if(!g_TDM_Round)
    {
        g_TDM_Round = true;
    }

    SetUpTeams(client);

    CPrintToChatAll("[TDM] A Team deathmatch has started!");
}

public void SetUpTeams(int client)
{
    PrintToConsole(client, "[TDM] Teams are being set up");

    ArrayList tList = new ArrayList(1, 0);
    ArrayList dList = new ArrayList(1, 0);

    int counter = 0;

    LoopValidClients(i)
    {
        if(!IsAliveClient(i))
        {
            PrintToConsole(client, "[TDM] %N is dead, skipping", i);
            continue;
        }
        if(TTT_GetClientRole(i) == 8)
        {
            dList.Push(i);
            PrintToConsole(client, "[TDM] %N is on the Detective team", i);
            counter++;
            continue;
        }
        if(TTT_GetClientRole(i) == 4)
        {
            tList.Push(i);
            PrintToConsole(client, "[TDM] %N is on the Traitor team", i);
            counter++;
            continue;
        }
        else if(counter%2 == 0)
        {
            tList.Push(i);
            PrintToConsole(client, "[TDM] %N is on the Traitor team", i);
            counter++;
            continue;
        }
        else
        {
            dList.Push(i);
            PrintToConsole(client, "[TDM] %N is on the Detective team", i);
            counter++;
            continue;
        }
    }

    if(dList.Length - tList.Length > 1)
    {
        PrintToConsole(client, "[TDM] Detective team advantaged, balancing");
        Balancer(dList.Length - tList.Length, tList, dList, 8, client);
    }
    if(tList.Length - dList.Length > 1)
    {
        PrintToConsole(client, "[TDM] Traitor team advantaged, balancing");
        Balancer(tList.Length - dList.Length, tList, dList, 4, client);
    }
    else
    {
        PrintToConsole(client, "[TDM] Teams are balanced, creating teams");
        CreateTeams(tList, dList, client);
    }
}

public void Balancer(int difference, ArrayList traitorTeam, ArrayList detectiveTeam, int advantagedTeam, int client)
{
    PrintToConsole(client, "[TDM] Balancing beginning");
    PrintToConsole(client, "[TDM] Traitor team size: %i", traitorTeam.Length);
    PrintToConsole(client, "[TDM] Detective team size: %i", detectiveTeam.Length);


    if(advantagedTeam == 8)
    {
        for(int i = 0; i < difference/2; i++)
        {
            int index = Math_GetRandomInt(0, detectiveTeam.Length);
            int random = detectiveTeam.Get(index, 0);
            detectiveTeam.Erase(index);
            traitorTeam.Push(random);
            PrintToConsole(client, "[TDM] %N moved to Traitor team", random);
        }
    }
    if(advantagedTeam == 4)
    {
        for(int i = 0; i < difference/2; i++)
        {
            int index = Math_GetRandomInt(0, traitorTeam.Length);
            int random = traitorTeam.Get(index, 0);
            traitorTeam.Erase(index);
            detectiveTeam.Push(random);
            PrintToConsole(client, "[TDM] %N moved to Detective team", random);
        }
    }

    CreateTeams(traitorTeam, detectiveTeam, client);
}

public void CreateTeams(ArrayList traitorTeam, ArrayList detectiveTeam, int client)
{
    PrintToConsole(client, "[TDM] Creating teams");
    PrintToConsole(client, "[TDM] Traitor team size: %i", traitorTeam.Length);    
    PrintToConsole(client, "[TDM] Detective team size: %i", detectiveTeam.Length);

    
    for(int t = 0; t <= traitorTeam.Length - 1; t++)
    {
        int player = traitorTeam.Get(t, 0);
        if(TTT_GetClientRole(player) != 4)
        {    
            TTT_SetClientRole(player, 4);
        }
        PrintToConsole(client, "[TDM] %N is on the Traitor team", player);
    }
    PrintToConsole(client, "[TDM] Traitor team created successfully");
    
    for(int d = 0; d <= detectiveTeam.Length - 1; d++)
    {
        int player = detectiveTeam.Get(d, 0);
        if(TTT_GetClientRole(player) != 8)
        {
            TTT_SetClientRole(player, 8);
        }
        PrintToConsole(client, "[TDM] %N is on the Detective team", player);
    }
    PrintToConsole(client, "[TDM] Detective team created successfully");

    PrintToConsole(client, "[TDM] Teams created successfully!");

    GiveHeavyAll(client);
}

public void GiveHeavyAll(int client)
{
    PrintToConsole(client, "[TDM] Giving all players heavy suit");
    LoopValidClients(i)
    {
        if(IsAliveClient(i))
        {
            PrintToConsole(client, "[TDM] %N given heavy suit", i);
            GivePlayerItem(i, "item_heavyassaultsuit");
        }
    }
}

public void EndTDM()
{
    g_cvMPTeammatesAreEnemies.SetBool(true, true, true);
    g_TDM_Round = false;
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
        panel.Send(i, HandlerDoNothing, 10);
    }

    delete panel;    
}

public Action Timer_TDMCountdown(Handle timer, int client)
{
    if(g_Countdown <= 0)
    {
        UnHookDMG();
        BeginTDM(client);
        return Plugin_Stop;
    }

    PrintCenterTextAll("TDM Starting in: %i", g_Countdown);
    CPrintToChatAll("[TDM] Team deathmatch starting in: %i", g_Countdown);    
    g_Countdown--;
    return Plugin_Continue;
}

public int RandomClient(int role, bool alive)
{
    ArrayList clients = new ArrayList(1, 0);
    LoopValidClients(i)
    {
        if (TTT_GetClientRole(i) & role || role == 0)
        {
            if (alive)
            {
                if (!IsAliveClient(i))
                {
                    continue;
                }
            }

            clients.Push(i);
        }
    }

    int client = -1;
    if (clients.Length > 0)
    {
        client = clients.Get(GetRandomInt(0, clients.Length - 1));
    }

    clients.Clear();
    delete clients;

    return client;
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
        SDKUnhook(i, SDKHook_OnTakeDamage, TDM_TakeDMG)
    }
}

public Action TDM_TakeDMG(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(g_TDM_Round && damagetype != DMG_FALL)
    {
        damage = 0.0;
        return Plugin_Changed;
    }
    else
    {
        return Plugin_Continue;
    }
}