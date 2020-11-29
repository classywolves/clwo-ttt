#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <clientprefs>
#include <colorlib>

#include <generics>
#undef REQUIRE_PLUGIN
#include <clwo_store>
#define REQUIRE_PLUGIN
#include <error_timeout>

#define SPD_ID "sped"
#define SPD_NAME "Adrenal Enhancements"
#define SPD_DESCRIPTION "Gives the player a surge of adrenaline to get them out of a tricky situation."
#define SPD_PRICE 1000
#define SPD_STEP 1.1
#define SPD_LEVEL 4
#define SPD_SORT 0

#define SPD_TIME 3.0
#define SPD_COOLDOWN_TIME 80

public Plugin myinfo =
{
    name = "CLWO Store - Skill: Adrenal Enhancements (Speed Increase)",
    author = "Popey & c0rp3n",
    description = "A skill that that grants the user a gust of speed.",
    version = "1.0.0",
    url = ""
};

Cookie g_cClientUsesBind = null;

enum struct PlayerData
{
    int level;
    int cooldown;
    int cooldownEnd;
    bool usesCommand;
    bool isUsingSpeed;
    bool useKeyPressed;
    float useKeyLastPressed;
    Handle revokeTimer;
}

PlayerData g_playerData[MAXPLAYERS + 1];

public void OnPluginStart()
{
    RegConsoleCmd("sm_speed", Command_Speed, "sm_speed - Allows for the binding of the speed increase skill.");

    g_cClientUsesBind = new Cookie("skill_speed_uses_bind", "Whether a client uses the speed skill bind.", CookieAccess_Public);
    g_cClientUsesBind.SetPrefabMenu(CookieMenu_OnOff_Int, "Skill - Adrenal Enhancements\nWould you like to use the \"sm_speed\" bind instead of double pressing +use.", CookieMenuHandler_ClientUsesBind);

    if (Store_IsReady())
    {
        Store_OnRegister();
    }

    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);

    for (int i = 1; i < MaxClients; ++i)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && AreClientCookiesCached(i))
        {
            OnClientCookiesCached(i);
        }
    }

    PrintToServer("[SPD] Loaded successfully");
}

public void OnPluginEnd()
{
    Store_UnRegisterSkill(SPD_ID);
}

public void Store_OnRegister()
{
    Store_RegisterSkill(SPD_ID, SPD_NAME, SPD_DESCRIPTION, SPD_PRICE, SPD_STEP, SPD_LEVEL, Store_OnSkillUpdate, SPD_SORT);
}

public void OnClientPutInServer(int client)
{
    ClearClientData(client);
    g_playerData[client].revokeTimer = INVALID_HANDLE;
}

public void OnClientDisconnect(int client)
{
    ClearClientData(client);
    ClearTimer(g_playerData[client].revokeTimer);
}

public void OnClientCookiesCached(int client)
{
    static char buffer[2];
    g_cClientUsesBind.Get(client, buffer, sizeof(buffer));
    g_playerData[client].usesCommand = (buffer[0] == '1');
}

public Action Command_Speed(int client, int argc)
{
    DoClientSpeed(client);

    return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float velocity[3], float angles[3], int &weapon)
{
    if (g_playerData[client].usesCommand ||
        g_playerData[client].level <= 0 ||
        g_playerData[client].isUsingSpeed ||
        !IsPlayerAlive(client)) 
    {
        return Plugin_Continue;
    }

    if (!(buttons & IN_USE))
    {
        g_playerData[client].useKeyPressed = false;

        return Plugin_Continue;
    }

    if (g_playerData[client].useKeyPressed) return Plugin_Continue;

    g_playerData[client].useKeyPressed = true;

    float currentGameTime = GetGameTime();
    if (currentGameTime > g_playerData[client].useKeyLastPressed + 0.2)
    {
        g_playerData[client].useKeyLastPressed = currentGameTime;

        return Plugin_Continue;
    }

    DoClientSpeed(client);

    return Plugin_Continue;
}

public void Store_OnSkillUpdate(int client, int level)
{
    g_playerData[client].level = level;
    if (g_playerData[client].level > 0)
    {
        SDKHook(client, SDKHook_OnTakeDamageAlivePost, Hook_OnTakeDamageAlivePost);
        g_playerData[client].cooldown = SPD_COOLDOWN_TIME / g_playerData[client].level;
    }
}

public void Event_RoundStart(Event event, char[] name, bool dontBroadcast)
{
    int time = GetTime();
    LoopClients(i) // There is probably a neater and faster way of resetting cooldowns at round start,
    {              // however, it is unknown to me. - Dog
                   // Corrected this to use GetTime, this is an integer not a 
                   // float so this will have caused some weirdness.
                   // Also cached the result of GetTime :) - c0rp3n
        g_playerData[i].cooldownEnd = time;
    }
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0)
    {
        CallTimer(g_playerData[client].revokeTimer);
    }
}

public void Hook_OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3], int damagecustom)
{
    if (g_playerData[victim].isUsingSpeed && IsValidClient(attacker))
    {
        CallTimer(g_playerData[victim].revokeTimer);
    }
}

public Action Timer_SpeedIncrease(Handle timer, DataPack pack)
{
    int client = GetClientOfUserId(pack.ReadCell());
    if (client && IsPlayerAlive(client))
    {
        float speed = 1.0 + pack.ReadFloat();
        SetClientSpeed(client, speed);
        SetEntityGravity(client, 1.0 / speed);
    }

    return Plugin_Stop;
}

public Action Timer_SpeedRevoke(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client)
    {
        if (IsPlayerAlive(client))
        {
            CPrintToChat(client, "{default}[TTT] > %s deactivated.", SPD_NAME);
        }

        g_playerData[client].revokeTimer = INVALID_HANDLE;
        g_playerData[client].isUsingSpeed = false;
        SetClientSpeed(client, 1.0);
        SetEntityGravity(client, 1.0);
    }

    return Plugin_Stop;
}

public void CookieMenuHandler_ClientUsesBind(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
    if (action == CookieMenuAction_SelectOption)
    {
        OnClientCookiesCached(client);
    }
}

void ClearClientData(int client)
{
    g_playerData[client].level = -1;
    g_playerData[client].cooldown = 0;
    g_playerData[client].cooldownEnd = 0;
    g_playerData[client].isUsingSpeed = false;
    g_playerData[client].useKeyPressed = false;
    g_playerData[client].useKeyLastPressed = 0.0;
}

void DoClientSpeed(int client)
{
    int currentTime = GetTime();
    if (currentTime < g_playerData[client].cooldownEnd)
    {
        if (ErrorTimeout(client))
        {
            CPrintToChat(client, "[TTT] > You are currently in cooldown for {orange}%d {default}more seconds.", g_playerData[client].cooldownEnd - currentTime);
        }

        return;
    }

    g_playerData[client].cooldownEnd = GetTime() + g_playerData[client].cooldown;

    CPrintToChat(client, "[TTT] > %s activated.", SPD_NAME);

    int userid = GetClientUserId(client);
    for (float i = 0.0; i < 0.5; i += 0.01)
    {
        DataPack pack;
        CreateDataTimer(i, Timer_SpeedIncrease, pack);

        pack.WriteCell(userid);
        pack.WriteFloat(i);
        pack.Reset();

    }

    g_playerData[client].isUsingSpeed = true;
    CreateTimer(SPD_TIME, Timer_SpeedRevoke, userid);
}

void SetClientSpeed(int client, float speed)
{
    SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed);
}
