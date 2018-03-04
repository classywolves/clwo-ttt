#if defined _helpers_included
	#endinput
#endif
#define _helpers_included 1

#if !defined(LoopValidClients)
	#define LoopValidClients(%1) 	for(int %1 = 1; %1 <= MaxClients; %1++) if(Player(%1).ValidClient)
#endif

#define LoopAliveClients(%1) 		for(int %1 = 1; %1 <= MaxClients; %1++) if(Player(%1).ValidClient && Player(%1).Alive)
#define LoopStaff(%1) 				for(int %1 = 1; %1 <= MaxClients; %1++) if(Player(%1).Staff)
#define LoopClients(%1) 			for(int %1 = 1; %1 <= MaxClients; %1++)

#include <player_methodmap>

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