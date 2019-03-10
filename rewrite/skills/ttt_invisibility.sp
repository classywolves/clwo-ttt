#pragma semicolon 1

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#include <ttt>
#include <ttt_taser>
#include <colorvariables>
#include <generics>
#include <ttt_skills>

#define INVISIBILITY_MAX_LEVEL 3

public Plugin myinfo =
{
    name = "TTT Invisibility",
    author = "Popey & c0rp3n",
    description = "TTT Traitor Taser Invisibility.",
    version = "1.0.0",
    url = ""
};

int errorTimeout[MAXPLAYERS + 1];

bool playerInvisible[MAXPLAYERS + 1] = { false, ... };

Handle invisibilityTimers[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

public OnPluginStart()
{
    LoopValidClients(client)
    {
        SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
    }

    PrintToServer("[TSR] Loaded successfully");
}

public OnAllPluginsLoaded()
{
    Skills_RegisterSkill(Skill_Invisibility, "Taser Invisibility", "As a traitor the player shall turn invisible upon being tasered.", INVISIBILITY_MAX_LEVEL);
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}

public OnClientDisconnect(int client)
{
    ClearTimer(invisibilityTimers[client]);
}

public void TTT_OnRoundStart(int innocents, int traitors, int detective)
{
    LoopClients(i)
    {
        CallTimer(invisibilityTimers[i]);
    }
}

public void TTT_OnRoundEnd(int winner)
{
    LoopClients(i)
    {
        CallTimer(invisibilityTimers[i]);
    }
}

// Block players from shooting if they're not allowed to shoot.
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if (buttons & IN_ATTACK || buttons & IN_ATTACK2)
    {
        if (playerInvisible[client]) {
            if (ErrorTimeout(client, 2)) {
                CPrintToChat(client, "{purple}[TTT] {orchid}You are not allowed to shoot whilst invulnerable!");
            }
            buttons &= ~IN_ATTACK;
            buttons &= ~IN_ATTACK2;
        }
    }

    return Plugin_Continue;
}

public Action OnTraceAttack(int iVictim, int &iAttacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
    if (TTT_IsWorldDamage(iAttacker, damagetype))
    {
        return Plugin_Continue;
    }

    if (TTT_GetClientRole(iVictim) != TTT_TEAM_TRAITOR)
    {
        return Plugin_Continue;
    }

    if (playerInvisible[iVictim])
    {
        // This player cannot take damage.
        if (!ErrorTimeout(iAttacker, 2))
        {
            CPrintToChat(iAttacker, "{purple}[TTT] {orchid}This person is invulnerable!");
        }

        damage = 0.0;

        return Plugin_Changed;
    }

    return Plugin_Continue;
}

public Action TTT_OnTased(int attacker, int victim)
{
    if (TTT_GetClientRole(victim) == TTT_TEAM_TRAITOR)
    {
        ActivateInvisibility(victim);
    }
}

public void ActivateInvisibility(int client)
{
    int upgradeLevel = Skills_GetSkill(client, Skill_Invisibility, 0, INVISIBILITY_MAX_LEVEL);
    if (upgradeLevel)
    {
        CPrintToChat(client, "{purple}[TTT] {yellow}Your invisibility has {green}activated!");
        playerInvisible[client] = true;

        invisibilityTimers[client] = CreateTimer(2.5 * upgradeLevel, DisableInvisibility, GetClientUserId(client));

        for (float i = 0.0; i < 2.5 * upgradeLevel; i += 0.1)
        {
            DataPack pack;
            CreateDataTimer(i, InvisibilityCountdown, pack);
            pack.WriteCell(client);
            pack.WriteFloat(i / (2.5 * upgradeLevel));
            pack.Reset();
        }
    }
}

public Action InvisibilityCountdown(Handle timer, DataPack pack)
{
    int client = pack.ReadCell();
    float percent = pack.ReadFloat();

    char bar[80], progress[255];
    GetProgressBar(percent, bar);
    Format(progress, sizeof(progress), "Remaining Invisibility: [%s]", bar);

    Handle hHudText = CreateHudSynchronizer();
    SetHudTextParams(0.01, 0.01, 0.2, 255, 128, 0, 255, 0, 0.0, 0.0, 0.0);
    ShowSyncHudText(client, hHudText, progress);
    CloseHandle(hHudText);

    return Plugin_Handled;
}

public void GetProgressBar(float percent, char bar[80])
{
    int bars = 20;
    int squares = RoundFloat(bars * percent);

    for (int i = 0; i < bars - squares; i++)
    {
        StrCat(bar, 80, "▰"); // Full Bar
    }

    for (int i = 0; i < squares; i++)
    {
        StrCat(bar, 80, "▱"); // Empty Bar
    }
}

public Action DisableInvisibility(Handle time, int userid)
{
    int client = GetClientOfUserId(userid);

    CPrintToChat(client, "{purple}[TTT] {yellow}Your invisibility has {red}deactivated!");
    playerInvisible[client] = false;

    return Plugin_Handled;
}

public bool ErrorTimeout(int client, int timeout)
{
    int currentTime = GetTime();
    if (currentTime - errorTimeout[client] < timeout)
    {
        return true;
    }

    errorTimeout[client] = currentTime;
    return false;
}
