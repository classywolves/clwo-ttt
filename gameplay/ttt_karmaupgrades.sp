//Base CS:GO Plugin Requirements
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

//Custom includes
#include <ttt>
#include <ttt_shop>
#include <ttt_messages>
#include <generics>
#include <colorvariables>

public Plugin myinfo = 
{
    name = "TTT Karma Upgrades",
    author = "D0G :3",
    description = "Player upgrades rewarded based on Karma",
    version = "0.0.1",
    url = ""
};

bool g_clientDamagedHooked[MAXPLAYERS + 1] = { false, ... };

public OnPluginStart()
{
    PrintToServer("[KRM] Loaded succcessfully");
}

public void OnClientPutInServer(int client)
{
    g_clientDamagedHooked[client] = false;
}

public void TTT_OnRoundStart()
{
    int hpKarmaReward = 10;
    int creditKarmaReward = 400;
    
    LoopValidClients(i)
    {   
        int clientKarma = TTT_GetClientKarma(i);
        int team = GetClientTeam(i);
        if (clientKarma >= 5000 && (team == CS_TEAM_CT || team == CS_TEAM_T))
        {
            SetEntityHealth(i, 100 + hpKarmaReward);
            TTT_AddClientCredits(i, creditKarmaReward);
            CPrintToChat(i, TTT_MESSAGE ... "Due to your high karma, you recieved some extra health and credits! (+{orange}%i {default}HP and +{orange}%i {default}credits!)", hpKarmaReward, creditKarmaReward);
            
            if (!g_clientDamagedHooked[i])
            {
                g_clientDamagedHooked[i] = true;
                SDKHook(i, SDKHook_OnTakeDamageAlive, HookOnTakeDamage);
            }
        }
    }
}

public Action HookOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, const float damageForce[3], const float damagePosition[3], int damagecustom)
{
    if (!(damagetype & DMG_FALL))
    {
        return Plugin_Continue; 
    }

    float fallDamageReduction = 0.2;
    float oldDamage = damage;

    damage -= damage * fallDamageReduction;

    CPrintToChat(victim, TTT_MESSAGE ... "Due to your high karma, your fall damage was reduced from {orange}%.0f {default}to {orange}%.0f", oldDamage, damage);
    return Plugin_Changed;
}

public void TTT_OnRoundEnd()
{   
    LoopValidClients(i)
    {
        if (TTT_GetClientKarma(i) <= 5000 && g_clientDamagedHooked[i])
        {
            SDKUnhook(i, SDKHook_OnTakeDamageAlive, HookOnTakeDamage);
        }
    }
}