#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#include <colorvariables>
#include <generics>
#include <clwo-store>
#include <ttt_messages>

#define VAMP_ID "vamp"
#define VAMP_NAME "Vampirism"
#define VAMP_DESCRIPTION "You regain health from any damage you do unto another player."
#define VAMP_PRICE 400
#define VAMP_STEP 1.2
#define VAMP_LEVEL 4
#define VAMP_SORT 100

public Plugin myinfo =
{
    name = "Skill Vampirism",
    author = "c0rp3n & Popey & MarsTwix",
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
    g_iSpriteBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
    g_iSpriteHalo = PrecacheModel("materials/sprites/glow.vmt");

    PrintToServer("[SKL] Loaded succcessfully");
}

public void Store_OnRegister()
{
    Store_RegisterSkill(VAMP_ID, VAMP_NAME, VAMP_DESCRIPTION, VAMP_PRICE, VAMP_STEP, VAMP_LEVEL, VAMP_SORT);
}

public void Store_OnReady()
{
    LoopValidClients(i)
    {
        OnClientPutInServer(i);
    }
}

public void OnClientPutInServer(int client)
{
    if (Store_IsReady())
    {
        g_playerData[client].level = Store_GetSkill(client, VAMP_ID);
        if (g_playerData[client].level > 0)
        {
            SDKHook(client, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
        }
    }
}

public void OnClientDisconnect(int client)
{
    g_playerData[client].level = -1;
}

public void Store_OnSkillPurchased(int client, char[] id, int level)
{
    if (StrEqual(id, VAMP_ID, true))
    {
        g_playerData[client].level = level;
        if (g_playerData[client].level > 0)
        {
            SDKHook(client, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
        }
    }
}

public void Hook_OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damageType, int weapon, const float damageForce[3], const float damagePosition[3])
{
    if (!(IsValidClient(victim) || IsValidClient(attacker) || IsPlayerAlive(attacker)))
    {
        return;
    }

    int health = GetClientHealth(attacker);
    if (health >= 100)
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

    CPrintToChat(attacker, TTT_MESSAGE ... "Vampirism!  Set your health too {orange}%d.", newHealth);
}

public int Min(int x, int y)
{
    return x < y ? x : y;
}
