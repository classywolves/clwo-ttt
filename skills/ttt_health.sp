#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <ttt>
#include <colorvariables>
#include <generics>
#include <ttt_skills>

#define HEALTH_MAX_LEVEL 4

public Plugin myinfo =
{
    name = "TTT Health",
    author = "Popey & c0rp3n",
    description = "TTT Health Skill",
    version = "1.0.0",
    url = ""
};

Handle healthTimers[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

public OnPluginStart()
{
    LoadTranslations("common.phrases");

    PrintToServer("[HPR] Loaded successfully");
}

public OnAllPluginsLoaded()
{
    Skills_RegisterSkill(Skill_Health, "Health Regen", "The player slowly regains health over time.", HEALTH_MAX_LEVEL);
}

public OnClientDisconnect(int client)
{
    ClearTimer(healthTimers[client]);
}

public void TTT_OnRoundStart(int innocents, int traitors, int detectives) {
    LoopAliveClients(i)
    {
        int upgradeLevel = Skills_GetSkill(i, Skill_Health, 0, HEALTH_MAX_LEVEL);
        if (upgradeLevel == 0)
        {
            continue;
        }

        healthTimers[i] = CreateTimer(10.0 - (upgradeLevel * 2.0), HealthRegen, GetClientUserId(i), TIMER_REPEAT);
    }
}

public void TTT_OnRoundEnd(int winner)
{
    LoopClients(i)
    {
        ClearTimer(healthTimers[i]);
    }
}

public Action HealthRegen(Handle timer, int serial) {
    int client = GetClientOfUserId(serial);
    if (!IsPlayerAlive(client))
    {
        ClearTimer(healthTimers[client]);
        return Plugin_Stop;
    }

    int health = GetClientHealth(client);
    if (health < 100)
    {
        SetEntityHealth(client, ++health);
    }

    return Plugin_Continue;
}
