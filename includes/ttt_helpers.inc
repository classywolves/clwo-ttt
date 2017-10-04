#if defined _ttt_helpers_included
	#endinput
#endif
#define _ttt_helpers_included

#include <player_methodmap> // Useful Player Related Functions

#if !defined(LoopValidClients)
	#define LoopValidClients(%1) 	for(int %1 = 1; %1 <= MaxClients; %1++) if(Player(%1).valid_client)
#endif

#define LoopAliveClients(%1) 		for(int %1 = 1; %1 <= MaxClients; %1++) if(Player(%1).valid_client && Player(%1).alive)
#define LoopStaff(%1) 				for(int %1 = 1; %1 <= MaxClients; %1++) if(Player(%1).staff)
#define LoopClients(%1) 			for(int %1 = 1; %1 <= MaxClients; %1++)

#define colour_grey 				{128, 128, 128, 255}
#define colour_red 					{255, 0, 0, 255}
#define colour_green 				{0, 255, 0, 255}
#define colour_blue 				{0, 0, 255, 255}
#define colour_cyan 				{0, 255, 255, 255}

stock int count_players() {
	int total_players = 0;
	LoopValidClients(client) {
		Player player = Player(client);
		if (player.team == CS_TEAM_T || player.team == CS_TEAM_CT) {
			total_players++;
		}
	}
	return total_players;
}