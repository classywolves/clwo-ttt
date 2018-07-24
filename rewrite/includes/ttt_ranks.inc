#if defined _ttt_ranks_included
  #endinput
#endif
#define _ttt_ranks_included

#define MAX_USER_RANKS 10
#define MAX_USER_TYPES 6

#define USER_RANK_COMMAND    0
#define USER_RANK_IS_STAFF   1
#define USER_RANK_NAME       2
#define USER_RANK_SCORE_NAME 3
#define USER_RANK_CHAT_NAME  4
#define USER_RANK_DEV_NAME   5

native bool HasPermission(int client, char rank[64]);
native void GetRankName(int rank, char name[64], int type);
native int GetRankLevel(char name[64], int type);
native int GetPlayerRank(int client);
