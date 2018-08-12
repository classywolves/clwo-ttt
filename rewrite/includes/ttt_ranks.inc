#if defined _ttt_ranks_included
  #endinput
#endif
#define _ttt_ranks_included

#define MAX_USER_STANDARD_RANKS 9
#define MAX_USER_RANKS 11
#define MAX_USER_TYPES 6

#define RANK_PLEB 			0
#define RANK_VIP 			1
#define RANK_INFORMER 		2
#define RANK_TMOD 		3
#define RANK_MOD			4
#define RANK_SMOD			5
#define RANK_GUARDIAN		6
#define RANK_ADMIN			7
#define RANK_SENATOR		8
#define RANK_SADMIN			9
#define RANK_DEV			10

#define USER_RANK_COMMAND    0
#define USER_RANK_IS_STAFF   1
#define USER_RANK_NAME       2
#define USER_RANK_SCORE_NAME 3
#define USER_RANK_CHAT_NAME  4
#define USER_RANK_DEV_NAME   5

native bool GetPermission(int client, int requiredRank);
native void GetRankName(int rank, char name[64], int type);
native int GetPlayerRank(int client);
