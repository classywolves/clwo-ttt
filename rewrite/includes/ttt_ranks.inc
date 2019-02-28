#if defined _ttt_ranks_included
    #endinput
#endif
#define _ttt_ranks_included

#include <colorvariables>

public SharedPlugin __pl_ttt_ranks =
{
	name = "ttt_ranks",
	file = "ttt_ranks.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_ttt_upgrades_SetNTVOptional()
{
	MarkNativeAsOptional("GetRankName");
	MarkNativeAsOptional("GetPermission");
    MarkNativeAsOptional("GetPlayerRank");
}
#endif

#define MAX_USER_STANDARD_RANKS 8
#define MAX_USER_RANKS 11
#define MAX_USER_TYPES 6

#define RANK_PLEB 			0
#define RANK_VIP 			1
#define RANK_INFORMER 		2
#define RANK_TMOD 		    3
#define RANK_MOD			4
#define RANK_SMOD			5
#define RANK_GUARDIAN		6
#define RANK_ADMIN			7
#define RANK_SADMIN			8
#define RANK_DEV			9
#define RANK_SENATOR		10

#define USER_RANK_COMMAND    0
#define USER_RANK_IS_STAFF   1
#define USER_RANK_NAME       2
#define USER_RANK_SCORE_NAME 3
#define USER_RANK_CHAT_NAME  4
#define USER_RANK_DEV_NAME   5

native bool TTT_Ranks_IsStaff(int client);

native bool GetPermission(int client, int requiredRank);
native void GetRankName(int rank, char name[64], int type);
native int GetPlayerRank(int client);

stock void CPrintToChatStaff(const char[] message, any ...)
{
    for (int iClient = 1; iClient <= MaxClients; iClient++) {
        if (!IsClientInGame(iClient)) {
            continue;
        }

        if (!TTT_Ranks_IsStaff(iClient)) {
            continue;
        }

        char buffer[1024];
    	VFormat(buffer, 1024, message, 2);
        CPrintToChat(iClient, buffer);
    }
}
