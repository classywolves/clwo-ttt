#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#include <colorlib>

#undef REQUIRE_PLUGIN
#include <ttt>
#define REQUIRE_PLUGIN
#include <generics>
#undef REQUIRE_PLUGIN
#include <clwo_store>
#define REQUIRE_PLUGIN

#define SCAV_ID "scav"
#define SCAV_NAME "Scavenger"
#define SCAV_DESCRIPTION "Allows the player to gain ammo after identifying a body."
#define SCAV_PRICE 800
#define SCAV_STEP 1.5
#define SCAV_LEVEL 2
#define SCAV_SORT 0

public Plugin myinfo =
{
    name = "CLWO Store - Skill: Scavenger",
    author = "Popey & c0rp3n",
    description = "A skill that allows the player to gain ammo by identifying bodies.",
    version = "1.0.0",
    url = ""
};

enum struct PlayerData
{
    int level;
}

PlayerData g_playerData[MAXPLAYERS + 1];

public OnPluginStart()
{
    LoopValidClients(i)
    {
        OnClientPutInServer(i);
    }

    if (Store_IsReady())
    {
        Store_OnRegister();
    }

    PrintToServer("[SCV] Loaded successfully");
}

public void OnPluginEnd()
{
    Store_UnRegisterSkill(SCAV_ID);
}

public void OnClientPutInServer(int client)
{
    g_playerData[client].level = -1;
}

public void OnClientDisconnect(int client)
{
    g_playerData[client].level = -1;
}

public void Store_OnRegister()
{
    Store_RegisterSkill(SCAV_ID, SCAV_NAME, SCAV_DESCRIPTION, SCAV_PRICE, SCAV_STEP, SCAV_LEVEL, Store_OnSkillUpdate, SCAV_SORT);
}

public void Store_OnSkillUpdate(int client, int level)
{
    g_playerData[client].level = level;
}

public void TTT_OnBodyFound(int client, int victim, int entityref, bool silentID)
{
    if (g_playerData[client].level > 0)
    {
        int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        if (IsValidEdict(weapon))
        {
            char weaponName[32];
            GetClientWeapon(client, weaponName, sizeof(weaponName));
            int capacity = GetWeaponMagCapacity(weaponName[7]);

            // int scavenged = (capacity / 4) * g_playerData[client].Level;
            int scavenged = (capacity >> 2) << (g_playerData[client].level - 1);

            int reserve = GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
            SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", reserve + scavenged);

            CPrintToChat(client, "{default}[TTT] > You found {orange}%d {default}rounds on {yellow}%N's {default}body.", scavenged, victim);
        }
    }
}

public int GetWeaponMagCapacity(char[] item)
{
    // Convert first 4 characters of item into an integer for fast comparison
    // (big endian byte ordering)
    // sizeof(item) must be >= 4
    int gun = (item[0] << 24) + (item[1] << 16) + (item[2] << 8) + (item[3]);
    switch (gun)
    {
        // pistols
        case 0x676C6F63: // glock
        {
            return 20;
        }
        case 0x75737000: // usp
        {
            return 12;
        }
        case 0x686B7032: // hkp2000
        {
            return 13;
        }
        case 0x70323530: // p250
        {
            return 13;
        }
        case 0x66697665: // fiveseven
        {
            return 20;
        }
        case 0x74656339: // tec9
        {
            return 18;
        }
        case 0x637A3735: // cz75a
        {
            return 12;
        }
        case 0x656C6974: // elite (dualies)
        {
            return 30;
        }
        case 0x64656167: // deagle
        {
            return 7;
        }
        case 0x72380000: // r8
        {
            return 8;
        }

        // smgs
        case 0x6D616331: // mac10
        {
            return 30;
        }
        case 0x6D703900: // mp9
        {
            return 30;
        }
        case 0x62697A6F: // bizon
        {
            return 64;
        }
        case 0x6D703700: // mp7
        {
            return 30;
        }
        case 0x756D7034: // ump45
        {
            return 25;
        }
        case 0x70393000: // p90
        {
            return 50;
        }

        // rifles
        case 0x67616C69: // galil
        {
            return 35;
        }
        case 0x66616D61: // famas
        {
            return 25;
        }
        case 0x616B3437: // ak47
        {
            return 30;
        }
        case 0x73673535: // sg553
        {
            return 30;
        }
        case 0x6D346131: // m4a1 and m4a1_silencer
        {
            if (item[4] == '_')
            {
                return 20;
            }
            else
            {
                return 30;
            } 
        }
        case 0x61756700: // aug
        {
            return 30;
        }
        case 0x73736730: // ssg08
        {
            return 10;
        }
        case 0x61777000: // awp
        {
            return 10;
        }
        case 0x67337367: // g3sg1
        {
            return 20;
        }
        case 0x73636172: // scar20
        {
            return 20;
        }

        // heavy
        case 0x6E6F7661: //nova
        {
            return 8;
        }
        case 0x73617765: //sawedoff
        {
            return 7;
        }
        case 0x6D616737: // mag7
        {
            return 5;
        }
        case 0x786D3130: // xm1014
        {
            return 7;
        }
        case 0x6D323439: // m249
        {
            return 100;
        }
        case 0x6E656765:    // negev
        {
            return 150;
        }
    }

    return 0;
}