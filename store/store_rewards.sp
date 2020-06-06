#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#include <colorlib>

#include <generics>
#include <clwo_store_credits>
#include <clwo_store_messages>

#define ITEMDRAW_SPACER_NOSLOT ((1<<1)|(1<<3)) //SPACER WITH NO SLOT

public Plugin myinfo =
{
    name = "CLWO Store - Rewards",
    author = "c0rp3n",
    description = "Example plugin for the clwo store plugin.",
    version = "1.0.0",
    url = ""
};

ConVar g_cCrReward = null;
ConVar g_cRewardActiveTime = null;
ConVar g_cRewardAfkTime = null;

Handle g_hRewardActiveTimer = INVALID_HANDLE;
Handle g_hRewardAfkTimer = INVALID_HANDLE;

int g_iClientRewards[MAXPLAYERS + 1];
int g_iClientRewardMissed[MAXPLAYERS + 1];
bool g_bClientHasAdvertisingOn[MAXPLAYERS + 1];

public void OnPluginStart()
{
    g_cCrReward = CreateConVar("clwo_store_reward", "1", "The maximum reward a player can get.");
    g_cRewardActiveTime = CreateConVar("clwo_store_active_reward_time", "1", "The delta in time between rewards in minutes 0 = Disabled.");
    g_cRewardAfkTime = CreateConVar("clwo_store_afk_reward_time", "5", "The delta in time between rewards in minutes 0 = Disabled.");

    AutoExecConfig(true, "store_rewards", "clwo");

    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end",   Event_RoundEnd,   EventHookMode_PostNoCopy);

    PrintToServer("[RWD] Loaded succcessfully");
}

public void OnConfigsExecuted()
{
    g_hRewardActiveTimer = CreateTimer(g_cRewardActiveTime.FloatValue * 60.0, Timer_RewardActive, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    g_hRewardAfkTimer = CreateTimer(g_cRewardAfkTime.FloatValue * 60.0, Timer_RewardAfk, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientPutInServer(int client)
{
    SetClientAdvertisingState(client, false);
}

public void OnClientPostAdminCheck(int client)
{
    CheckClientAdvertisingState(client);

    CreateTimer(15.0, Timer_ShowRewardPanel, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

////////////////////////////////////////////////////////////////////////////////
// Events
////////////////////////////////////////////////////////////////////////////////

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    RefreshRewardStatus();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    DoRewardPayouts();
}

////////////////////////////////////////////////////////////////////////////////
// Timers
////////////////////////////////////////////////////////////////////////////////

public Action Timer_ShowRewardPanel(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0)
    {
        if (!ClientAllowedToGetReward(client))
        {
            ShowRewardPanel(client);
        }
    }

    return Plugin_Handled;
}

public Action Timer_RewardActive(Handle timer)
{
    int credits = g_cCrReward.IntValue;
    int team;
    LoopValidClients(i)
    {
        team = GetClientTeam(i);
        if (team == CS_TEAM_CT || team == CS_TEAM_T)
        {
            if (ClientAllowedToGetReward(i))
            {
                AddClientReward(i, credits);
            }
            else
            {
                AddClientRewardMissed(i, credits);
            }
        }
    }

    return Plugin_Continue;
}

public Action Timer_RewardAfk(Handle timer)
{
    int credits = g_cCrReward.IntValue;
    int team;
    LoopValidClients(i)
    {
        team = GetClientTeam(i);
        if (team == CS_TEAM_SPECTATOR || team == CS_TEAM_NONE)
        {
            if (ClientAllowedToGetReward(i))
            {
                AddClientReward(i, credits);
            }
            else
            {
                AddClientRewardMissed(i, credits);
            }
        }
    }

    return Plugin_Continue;
}

////////////////////////////////////////////////////////////////////////////////
// Panels
////////////////////////////////////////////////////////////////////////////////

void ShowRewardPanel(int client)
{
    Panel panel = BuildRewardPanel(client);
    panel.Send(client, InfoPanel_Callback, MENU_TIME_FOREVER);
    delete panel;
}

Panel BuildRewardPanel(int client)
{
    Panel panel = new Panel();

    panel.SetTitle("For every minute you are active on this server you will receive 1cR.\n"); //max 8 per menu
    panel.DrawItem("", ITEMDRAW_SPACER_NOSLOT);
    panel.DrawText("Requirements:");

    if(IsCarryingClantag(client))
    {
        panel.DrawText("[v] Wear the CLWO clantag ingame [requirement met]");
    }
    else
    {
        panel.DrawText("[x] Wear the CLWO clantag ingame [requirement not met]");
    }

    if(GetClientAdvertisingState(client))
    {
        panel.DrawText("[v] have 'cl_join_advertise' set to '2' [requirement met]");
    }
    else
    {
        panel.DrawText("[x] have 'cl_join_advertise' set to '2' [requirement not met]");
    }

    panel.DrawItem("", ITEMDRAW_SPACER_NOSLOT);
    panel.DrawText("[tip: just joining the server will reward you with 1cR every 5 minutes.");
    panel.DrawText("Yes, this means firing up csgo, joining the server, alt tabbing out is a viable way to farm them]");

    panel.DrawItem("Exit", ITEMDRAW_CONTROL);

    return panel;
}

public int InfoPanel_Callback(Menu menu, MenuAction action, int param1, int param2)
{
    switch(action)
    {
        case MenuAction_End:
        {
            delete menu;
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
// ConVar Query
////////////////////////////////////////////////////////////////////////////////

public void CheckClientConVar(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
    if(StrEqual(cvarName, "cl_join_advertise"))
    {
        if(StringToInt(cvarValue) == 2)
        {
            SetClientAdvertisingState(client, true);
        }
        else
        {
            SetClientAdvertisingState(client, false);
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
// Stocks
////////////////////////////////////////////////////////////////////////////////

void RefreshRewardStatus()
{
    LoopValidClients(i)
    {
        CheckClientAdvertisingState(i);
    }
}

void DoRewardPayouts()
{
    LoopValidClients(i)
    {
        CheckClientAdvertisingState(i);
        if (ClientAllowedToGetReward(i))
        {
            int reward = GetClientReward(i);
            if (reward > 0)
            {
                int cr = Store_AddClientCredits(i, reward);
                CPrintToChat(i, " [Store] You earned {orange}%dcR {default}(total: {orange}%icR{default}).", reward, cr);
            }
        }
        else
        {
            int missed = GetClientRewardMissed(i);
            if (missed > 0)
            {
                CPrintToChat(i, " [Store] Bummer! you missed out on {orange}%dcR.", missed);
            }
        }

        ResetClientRewards(i);
    }
}

void AddClientReward(int client, int credits)
{
    g_iClientRewards[client] += credits;
}

void AddClientRewardMissed(int client, int credits)
{
    g_iClientRewardMissed[client] += credits;
}

int GetClientReward(int client)
{
    return g_iClientRewards[client];
}

int GetClientRewardMissed(int client)
{
    return g_iClientRewardMissed[client];
}

void ResetClientRewards(int client)
{
    g_iClientRewards[client] = 0;
    g_iClientRewardMissed[client] = 0;
}

bool ClientAllowedToGetReward(int client)
{
    if(!IsCarryingClantag(client))
        return false;
    if(!GetClientAdvertisingState(client)) //must be true.
        return false;
    return true;
}

void CheckClientAdvertisingState(int client)
{
    QueryClientConVar(client, "cl_join_advertise", CheckClientConVar, client);
}

void SetClientAdvertisingState(int client, bool state)
{
    g_bClientHasAdvertisingOn[client] = state;
}

bool GetClientAdvertisingState(int client)
{
    return g_bClientHasAdvertisingOn[client];
}

bool IsCarryingClantag(int client)
{
    char cCl_clanid[64];
    GetClientInfo(client, "cl_clanid", cCl_clanid, sizeof(cCl_clanid));
    if(StrEqual(cCl_clanid,"5157979", true))//5157979 == clwo.eu
    {
        return true;
    }
    else
    {
        return false;
    }
}
