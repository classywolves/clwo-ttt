#if defined _generics_included
	#endinput
#endif
#define _generics_included

/*
 * Includes for generics.
 */
#include <player_methodmap>

/*
 * Definitions.
 */
#if !defined LoopValidClients
	#define LoopValidClients(%1) 	for(int %1 = 1; %1 <= MaxClients; %1++) if(Player(%1).ValidClient)
#endif

#define LoopAliveClients(%1) 		for(int %1 = 1; %1 <= MaxClients; %1++) if(Player(%1).ValidClient && Player(%1).Alive)
#define LoopStaff(%1) 				for(int %1 = 1; %1 <= MaxClients; %1++) if(Player(%1).ValidClient && Player(%1).Staff)
#define LoopClients(%1) 			for(int %1 = 1; %1 <= MaxClients; %1++) if(Player(%1).ValidClient)

/*
 * Stock functions.
 */
stock int GetStaffArray(int staff[32] = {}) {
	int staffCount = 0;

	LoopValidClients(i) {
		if (Player(i).Staff) {
			staff[staffCount] = i;
			staffCount++;
		}
	}

	return staffCount;
}

stock int GetStaffCount() {
	int staffCount = 0;
	
	LoopStaff(i) {
		staffCount++;
	}

	return staffCount;
}

stock int GetActiveStaffCount() {
	int staffCount = 0;

	LoopStaff(client) {
		Player player = Player(client)
		if (player.CounterTerrorist || player.Terrorist) {
			staffCount++;
		}
	}

	return staffCount
}