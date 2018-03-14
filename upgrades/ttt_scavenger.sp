#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <player_methodmap>
#include <maths_methodmap>

#define upgrade_id 11
#define max_level 2

int offsetAmmo = -1;
int offsetPrimaryAmmoType = -1;

public void OnMapStart() {
	offsetAmmo = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	offsetPrimaryAmmoType = FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoType");

	HookEvent("player_death", OnPlayerDeath);
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker", victim));
	
	Player player_attacker = Player(attacker);
	if (attacker == victim || IsValidClient(attacker) == false || player_attacker.has_upgrade(upgrade_id) > 0)	{ return Plugin_Continue; }
	
	int entity_index = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	
	char weaponName[64];
	GetEventString(event, "weapon", weaponName, sizeof(weaponName));
	int ammo[2];
	GetAmmoValues(weaponName, ammo);
	
	if (ammo[0] == 0 || ammo[1] == 0) { return Plugin_Continue; }
	
	int upgrade_level = Maths().min(player_attacker.has_upgrade(upgrade_id), max_level);
	int ammo_gained = RoundFloat(ammo[0] * 0.25 * (float(ammo[0]) / ammo[1]) * upgrade_level);
	if (IsValidEdict(entity_index))
	{
		int ammo_type = GetEntData(entity_index, offsetPrimaryAmmoType);
		// Replenish Ammo Stock (not active clip) if empty
		if (ammo_type > 0)
			SetEntData(attacker, offsetAmmo+(ammo_type<<2), Maths().min(GetEntData(attacker, offsetAmmo+(ammo_type<<2)) + ammo_gained, ammo[1]), 4, true);
	}
	
	CPrintToChat(attacker, "You Scavenged %d bullets.", ammo_gained);
	
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
				ammoOut = {20, 40};
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
			ammoOut = {0, 0}
		}
	}
}