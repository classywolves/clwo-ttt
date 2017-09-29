#if defined _ttt_helpers_included
	#endinput
#endif
#define _ttt_helpers_included

#include <sourcemod> 		// Default Sourcemod Includes
#include <sdktools>			// ┫
#include <clientprefs>		// ┛
#include <imod>				// iNilo Staff Functionality
#include <general>			// General Definitions
#include <colorvariables>	// Pretty Printing
#include <ttt>				// Interact with TTT

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