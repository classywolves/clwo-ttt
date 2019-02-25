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
 * Custom methodmap includes.
 */
#include <math_methodmap>
#include <player_methodmap>

#define SCAVENGER_MAX_LEVEL 2

int offsetAmmo = -1;
int offsetPrimaryAmmoType = -1;

public Plugin myinfo =
{
    name = "TTT Scavenger",
    author = "c0rp3n",
    description = "TTT Scavenger Skill",
    version = "0.0.1",
    url = ""
};

public OnPluginStart()
{
    //RegisterCmds();
    HookEvents();
    //InitDBs();

    LoadTranslations("common.phrases");

    PrintToServer("[SCV] Loaded successfully");
}

/*
public void RegisterCmds() {

}
*/

public void HookEvents()
{
    HookEvent("player_death", OnPlayerDeath);
}

/*
public void InitDBs()
{

}
*/

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker", victim));

    Player playerAttacker = Player(attacker);

    int upgradeLevel = playerAttacker.Skill(Skill_Scavenger, 0, SCAVENGER_MAX_LEVEL);
    if (attacker == victim || !playerAttacker.ValidClient || upgradeLevel == 0)	{ return Plugin_Continue; }

    int entityIndex = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");

    char weaponName[64];
    GetEventString(event, "weapon", weaponName, sizeof(weaponName));
    int ammo[2];
    GetAmmoValues(weaponName, ammo);

    if (ammo[0] == 0 || ammo[1] == 0) { return Plugin_Continue; }

    int ammoGained = RoundFloat(ammo[0] * 0.25 * (float(ammo[0]) / ammo[1]) * upgradeLevel);
    if (IsValidEdict(entityIndex))
    {
        int ammoType = GetEntData(entityIndex, offsetPrimaryAmmoType);
        // Replenish Ammo Stock (not active clip) if empty
        if (ammoType > 0)
        {
            SetEntProp(attacker, Prop_Send, "m_iAmmo", Math().Min(GetEntProp(attacker, Prop_Send, "m_iAmmo", _, ammoType) + ammoGained, ammo[1]), _, ammoType);
        }
    }

    CPrintToChat(attacker, "{purple}[TTT] {yellow}You Scavenged {blue}%n {yellow}bullets.", ammoGained);

    return Plugin_Continue;
}

// returns {clip, reserve}
public void GetAmmoValues(char[] item, int ammoOut[2])
{
    // Convert first 4 characters of item into an integer for fast comparison (big endian byte ordering)
    // sizeof(item) must be >= 4
    int gun = (item[0] << 24) + (item[1] << 16) + (item[2] << 8) + (item[3]);
    switch (gun)
    {
        // pistols
        case 0x676C6F63:		// glock
        {
            ammoOut = {20, 120};
        }
        case 0x75737000:		// usp
        {
            ammoOut = {12, 24};
        }
        case 0x686B7032:		// hkp2000
        {
            ammoOut = {13, 62};
        }
        case 0x70323530:		// p250
        {
            ammoOut = {13, 26};
        }
        case 0x66697665:		// fiveseven
        {
            ammoOut = {20, 100};
        }
        case 0x74656339:		// tec9
        {
            ammoOut = {18, 90};
        }
        case 0x637A3735:		// cz75a
        {
            ammoOut = {12, 12};
        }
        case 0x656C6974:		// elite (dualies)
        {
            ammoOut = {30, 120};
        }
        case 0x64656167:		// deagle
        {
            ammoOut = {7, 35};
        }
        case 0x72380000:		// r8
        {
            ammoOut = {8, 8};
        }

        // smgs
        case 0x6D616331:		// mac10
        {
            ammoOut = {30, 100};
        }
        case 0x6D703900:		// mp9
        {
            ammoOut = {30, 120};
        }
        case 0x62697A6F:		// bizon
        {
            ammoOut = {64, 120};
        }
        case 0x6D703700:		// mp7
        {
            ammoOut = {30, 120};
        }
        case 0x756D7034:		// ump45
        {
            ammoOut = {25, 100};
        }
        case 0x70393000:		// p90
        {
            ammoOut = {50, 100};
        }

        // rifles
        case 0x67616C69:		// galil
        {
            ammoOut = {35, 90};
        }
        case 0x66616D61:		// famas
        {
            ammoOut = {25, 90};
        }
        case 0x616B3437:		// ak47
        {
            ammoOut = {30, 90};
        }
        case 0x73673535:		// sg553
        {
            ammoOut = {30, 90};
        }
        case 0x6D346131:		// m4a1 and m4a1_silencer
        {
            if (item[4] == '_')
            ammoOut = {20, 60};
            ammoOut = {30, 90};
        }
        case 0x61756700:		// aug
        {
            ammoOut = {30, 90};
        }
        case 0x73736730:		// ssg08
        {
            ammoOut = {10, 90};
        }
        case 0x61777000:		// awp
        {
            ammoOut = {10, 30};
        }
        case 0x67337367:		// g3sg1
        {
            ammoOut = {20, 90};
        }
        case 0x73636172:		// scar20
        {
            ammoOut = {20, 90};
        }

        // heavy
        case 0x6E6F7661: 		//nova
        {
            ammoOut = {8, 32};
        }
        case 0x73617765: 		//sawedoff
        {
            ammoOut = {7, 32};
        }
        case 0x6D616737:		// mag7
        {
            ammoOut = {5, 32};
        }
        case 0x786D3130: 		// xm1014
        {
            ammoOut = {7, 32};
        }
        case 0x6D323439:		// m249
        {
            ammoOut = {100, 200};
        }
        case 0x6E656765:		// negev
        {
            ammoOut = {150, 200};
        }

        default:
        {
            ammoOut = {0, 0};
        }
    }
}
