#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#include <colorlib>
#include <generics>
#include <ttt_messages>
#undef REQUIRE_PLUGIN
#include <clwo_store>
#define REQUIRE_PLUGIN

#include "skill_common.sp"

#define VAMP_ID "vamp"
#define VAMP_NAME "Vampirism"
#define VAMP_DESCRIPTION "You regain health from damage you do to another player, when they are in close proximity to you."
#define VAMP_PRICE 1200
#define VAMP_STEP 2.0
#define VAMP_LEVEL 2
#define VAMP_SORT 100
#define VAMP_DISTANCE 65536

public Plugin myinfo =
{
    name = "CLWO Store - Skill: Vampirism",
    author = "c0rp3n & Popey",
    description = "A skill that allows the player to regain health from the damage that they do unto others.",
    version = "0.1.0",
    url = ""
};

int g_iSpriteBeam = -1;
int g_iSpriteHalo = -1;

enum struct PlayerData
{
    int level;
}

PlayerData g_playerData[MAXPLAYERS + 1];

public void OnPluginStart()
{
    LoopValidClients(i)
    {
        OnClientPutInServer(i);
    }

    PrintToServer("[SKL] Loaded succcessfully");
}

public void OnPluginEnd()
{
    Store_UnRegisterSkill(VAMP_ID);
}

public void OnMapStart()
{
    g_iSpriteBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
    g_iSpriteHalo = PrecacheModel("materials/sprites/glow.vmt");
}

public void Store_OnRegister()
{
    Store_RegisterSkill(VAMP_ID, VAMP_NAME, VAMP_DESCRIPTION, VAMP_PRICE, VAMP_STEP, VAMP_LEVEL, Store_OnSkillUpdate, VAMP_SORT);
}

public void OnClientPutInServer(int client)
{
    g_playerData[client].level = -1;
    SDKHook(client, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
}

public void OnClientDisconnect(int client)
{
    g_playerData[client].level = -1;
    SDKUnhook(client, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
}

public void Store_OnSkillUpdate(int client, int level)
{
    g_playerData[client].level = level;
}

public void Hook_OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damageType, int weapon, const float damageForce[3], const float damagePosition[3])
{
    if (!IsValidClient(attacker) || !IsPlayerAlive(attacker) || g_playerData[attacker].level < 1)
    {
        return;
    }

    int health = GetClientHealth(attacker);
    if (health >= 100)
    {
        return;
    }

    float vpos[3];
    GetClientEyePosition(victim, vpos);
    float apos[3];
    GetClientEyePosition(attacker, apos);
    if (GetVectorDistance(vpos, apos, true) > VAMP_DISTANCE)
    {
        return;
    }

    int healthGain = RoundFloat(damage * 0.0375 * g_playerData[attacker].level);

    int newHealth = Min(health + healthGain, 100);
    SetEntityHealth(attacker, newHealth);

    if (GetRandomInt(0, 100) > (100 - (6 * g_playerData[attacker].level)))
    {
        float attackerOrigin[3], victimOrigin[3];
        GetClientEyePosition(attacker, attackerOrigin);
        GetClientEyePosition(victim, victimOrigin);
        attackerOrigin[2] -= 10.0;
        victimOrigin[2] -= 10.0;

        TE_SetupBeamPoints(attackerOrigin, victimOrigin, g_iSpriteBeam, g_iSpriteHalo, 0, 66, 0.2, 1.0, 20.0, 1, 0.0, {255, 0, 0, 255}, 5);
        TE_SendToAll();
    }

    CPrintToChat(attacker, TTT_MESSAGE ... "Vampirism! Set your health to {orange}%d.", newHealth);
}

public int Min(int x, int y)
{
    return x < y ? x : y;
}
