#if defined _ttt_ranks_included
    #endinput
#endif
#define _ttt_ranks_included

#include <colorvariables>
#include <generics>

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
    MarkNativeAsOptional("TTT_Ranks_IsStaff");
	MarkNativeAsOptional("GetRankName");
	MarkNativeAsOptional("GetPermission");
    MarkNativeAsOptional("GetPlayerRank");
    MarkNativeAsOptional("GetRankTag");
}
#endif

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

#define LoopStaff(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsValidClient(%1) && TTT_Ranks_IsStaff(i))

native bool TTT_Ranks_IsStaff(int client);

native bool GetPermission(int client, int requiredRank);
native void GetRankName(int rank, char name[32]);
native void GetRankTag(int rank, char tag[16])
native int GetPlayerRank(int client);

stock int GetStaffArray(int staff[32])
{
    int staffCount = 0;
    LoopValidClients(i)
    {
        if (TTT_Ranks_IsStaff(i))
        {
            staff[staffCount] = i;
            staffCount++;
        }
    }

    return staffCount;
}

stock int GetStaffCount()
{
    int staffCount = 0;
    LoopStaff(i)
    {
        staffCount++;
    }

    return staffCount;
}

stock int GetActiveStaffCount()
{
    int staffCount = 0;
    LoopStaff(i)
    {
        int team = GetClientTeam(i);
        if (team == CS_TEAM_T || team == CS_TEAM_CT)
        {
            staffCount++;
        }
    }

    return staffCount;
}

stock void CPrintToChatStaff(const char[] message, any ...)
{
    LoopStaff(i) {
        char buffer[1024];
    	VFormat(buffer, 1024, message, 2);
        CPrintToChat(i, buffer);
    }
}
