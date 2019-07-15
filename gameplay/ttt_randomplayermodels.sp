#pragma semicolon 1

/*
 * Base CS:GO plugin requirements.
 */
#include <sourcemod>
#include <sdktools>
#include <cstrike>

/*
 * Custom include files.
 */
#include <ttt>
#include <colorvariables>
#include <generics>

/*
 * Custom Defines.
 */
 #include <player_models>

public Plugin myinfo =
{
    name = "TTT Random Player Models",
    author = "c0rp3n",
    description = "Random player models for CLWO TTT.",
    version = "1.0.0",
    url = ""
};

int ctRandom = 0;
int tRandom = 0;
int baseIndexCt = 0;
int baseIndexT = 0;

int playerModelIndex[MAXPLAYERS + 1] = { 0, ... };

public OnPluginStart()
{
    HookEvents();

    LoadTranslations("common.phrases");

    PrintToServer("[RPM] Loaded succcessfully");
}

public void HookEvents()
{
    HookEvent("round_start", OnRoundStartPre, EventHookMode_Pre);
    HookEvent("player_spawn", OnPlayerSpawnPost, EventHookMode_Post);
}

public Action OnRoundStartPre(Event event, const char[] name, bool dontBroadcast)
{
    ctRandom = GetRandomInt(0, MAX_PLAYER_TEAMS - 1);
    tRandom = GetRandomInt(0, MAX_PLAYER_TEAMS - 1);
    GetBaseIndex();

    LoopClients(i)
    {
        GetPlayerModel(i, TTT_TEAM_INNOCENT);
    }

    return Plugin_Continue;
}

public Action OnPlayerSpawnPost(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    SetPlayerModel(client, TTT_TEAM_INNOCENT);

    return Plugin_Continue;
}

public void TTT_OnRoundStart(int innocents, int traitors, int detective)
{
	LoopAliveClients(i)
	{
        int role = TTT_GetClientRole(i);
        if (role == TTT_TEAM_DETECTIVE)
        {
            GetPlayerModel(i, role);
        }

        SetPlayerModel(i, role);
	}
}

public void OnMapStart()
{
    PreCacheTeamModels();
}

public void PreCacheTeamModels()
{
    for (int i = 0; i < MAX_CT_PLAYER_MODELS_COUNT; i++)
    {
        PrecacheModel(ctPlayerModels[i], true);
    }

    for (int i = 0; i < MAX_VIEW_MODELS_COUNT; i++)
    {
        PrecacheModel(ctViewModels[i], true);
    }

    for (int i = 0; i < MAX_T_PLAYER_MODELS_COUNT; i++)
    {
        PrecacheModel(tPlayerModels[i], true);
    }

    for (int i = 0; i < MAX_VIEW_MODELS_COUNT; i++)
    {
        PrecacheModel(tViewModels[i], true);
    }
}

public void GetPlayerModel(int client, int role)
{
    switch (role)
    {
        case TTT_TEAM_DETECTIVE:
        {
            switch (ctRandom)
            {
                case 0:
                {
                    playerModelIndex[client] = baseIndexCt;
                    ItterateCtIndex(4);
                }
                case 1:
                {
                    playerModelIndex[client] = 5 + baseIndexCt;
                    ItterateCtIndex(4);
                }
                case 2:
                {
                    playerModelIndex[client] = 10 + baseIndexCt;
                    ItterateCtIndex(4);
                }
                case 3:
                {
                    playerModelIndex[client] = 15 + baseIndexCt;
                    ItterateCtIndex(5);
                }
                case 4:
                {
                    playerModelIndex[client] = 21 + baseIndexCt;
                    ItterateCtIndex(5);
                }
                case 5:
                {
                    playerModelIndex[client] = 27 + baseIndexCt;
                    ItterateCtIndex(4);
                }
                case 6:
                {
                    playerModelIndex[client] = 32 + baseIndexCt;
                    ItterateCtIndex(4);
                }
            }
        }
        case TTT_TEAM_INNOCENT, TTT_TEAM_TRAITOR:
        {
            playerModelIndex[client] = (5 * tRandom) + baseIndexT;
            ItterateTIndex(4);
        }
    }
}

public void ItterateCtIndex(int max)
{
    if (++baseIndexCt > max)
    {
        baseIndexCt = 0;
    }
}

public void ItterateTIndex(int max)
{
    if (++baseIndexT > max)
    {
        baseIndexT = 0;
    }
}

public void GetBaseIndex()
{
    switch (ctRandom)
    {
        case 0:
        {
            baseIndexCt = GetRandomInt(0, 4);
        }
        case 1:
        {
            baseIndexCt = GetRandomInt(0, 4);
        }
        case 2:
        {
            baseIndexCt = GetRandomInt(0, 4);
        }
        case 3:
        {
            baseIndexCt = GetRandomInt(0, 5);
        }
        case 4:
        {
            baseIndexCt = GetRandomInt(0, 5);
        }
        case 5:
        {
            baseIndexCt = GetRandomInt(0, 4);
        }
        case 6:
        {
            baseIndexCt = GetRandomInt(0, 4);
        }
    }

    baseIndexT = GetRandomInt(0, 4);
}

public void SetPlayerModel(int client, int role)
{
    switch (role)
    {
        case TTT_TEAM_DETECTIVE:
        {
            SetEntityModel(client, ctPlayerModels[playerModelIndex[client]]);
            SetPlayerArms(client, ctViewModels[ctRandom]);
        }
        case TTT_TEAM_INNOCENT, TTT_TEAM_TRAITOR:
        {
            SetEntityModel(client, tPlayerModels[playerModelIndex[client]]);
            SetPlayerArms(client, tViewModels[tRandom]);
        }
    }
}

void SetPlayerArms(int client, const char arms_path[PLATFORM_MAX_PATH])
{
    if(!StrEqual(arms_path, ""))
    {
        //Remove player all items and give back them after 0.1 seconds + block weapon pickup
        int weapon_index;
        for (int slot = 0; slot < 7; slot++)
        {
            weapon_index = GetPlayerWeaponSlot(client, slot);
            {
                if(weapon_index != -1)
                {
                    if (IsValidEntity(weapon_index))
                    {
                        RemovePlayerItem(client, weapon_index);

                        DataPack pack;
                        CreateDataTimer(0.1, GiveBackWeapons, pack);
                        pack.WriteCell(client);
                        pack.WriteCell(weapon_index);
                    }
                }
            }
        }

        //Set player arm model
        if(!IsModelPrecached(arms_path))
        {
            PrecacheModel(arms_path);
        }

        SetEntPropString(client, Prop_Send, "m_szArmsModel", "");

        int ent = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
        if(ent == -1)
        {
            SetEntPropString(client, Prop_Send, "m_szArmsModel", arms_path);
        }
    }
}

public Action GiveBackWeapons(Handle tmr, Handle pack)
{
    ResetPack(pack);
    int client = ReadPackCell(pack);
    int weapon_index = ReadPackCell(pack);
    EquipPlayerWeapon(client, weapon_index);
}
