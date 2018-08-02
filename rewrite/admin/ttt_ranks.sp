#include <ttt_ranks>
#include <player_methodmap>

char userRanks[MAX_USER_RANKS][MAX_USER_TYPES][64] = {
  //  "command",          "is staff", "name",             "score name", "chat name", "dev name"
  {   "rank_normal",      "0",        "Normal",           "",           "",          "pleb"     },
  {   "rank_vip",         "0",        "VIP",              "VIP",        "♥",         "vip"      },
  {   "rank_informer",    "1",        "Informer",         "+",          "+",         "informer" },
  {   "rank_trialmod",    "1",        "Trial Moderator",  "Trial Mod",  "ζ",         "tmod"     },
  {   "rank_moderator",   "1",        "Moderator",        "Moderator",  "ε",         "mod"      },
  {   "rank_seniormod",   "1",        "Senior Moderator", "Sen. Mod",   "δ",         "smod"     },
  {   "rank_guardian",    "1",        "Guardian",         "Guarian",    "Ω",         "guardian" },
  {   "rank_admin",       "1",        "Admin",            "Admin",      "γ",         "admin"    },
  {   "rank_senioradmin", "1",        "Senior Admin",     "Sen. Admin", "β",         "sadmin"   },
  {   "rank_senator",     "1",        "Senator",          "Senator",    "α",         "senator"  }
};

StringMap ranks;

public OnPluginStart() {
  // Initialise Trie
  ranks = new StringMap();
  ranks.SetValue("STEAM_1:1:182504457", 8); // Corpen
  ranks.SetValue("STEAM_1:1:75162869", 8); // Dog
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
   CreateNative("HasPermission", Native_HasPermission);
   CreateNative("GetRankName", Native_GetRankName);
   CreateNative("GetRankLevel", Native_GetRankLevel);
   CreateNative("GetPlayerRank", Native_GetPlayerRank);
   return APLRes_Success;
}

public int Native_HasPermission(Handle plugin, int numParams) {
  int client = GetNativeCell(1);
  char rank[64];
  GetNativeString(2, rank, sizeof(rank));

  return view_as<int>(Internal_HasPermission(client, rank));
}

public int Native_GetRankName(Handle plugin, int numParams) {
  int rank = GetNativeCell(1);
  char name[64];
  GetNativeString(2, name, sizeof(name));
  int type = GetNativeCell(3);

  Internal_GetRankName(rank, name, type);
}

public int Native_GetRankLevel(Handle plugin, int numParams) {
  char name[64];
  GetNativeString(2, name, sizeof(name));
  int type = GetNativeCell(2);

  return Internal_GetRankLevel(name, type);
}

public int Native_GetPlayerRank(Handle plugin, int numParams) {
  int client = GetNativeCell(1);

  return Internal_GetPlayerRank(client);
}

public int Internal_HasPermission(int client, char rank[64]) {
  return Internal_GetPlayerRank(client) >=  Internal_GetRankLevel(rank, USER_RANK_DEV_NAME);
}

public Internal_GetRankName(int rank, char name[64], int type) {
  SetNativeString(2, userRanks[rank][type], 64, false);
}

public int Internal_GetRankLevel(char name[64], int type) {
  for (int rank = 0; rank < MAX_USER_RANKS; rank++) {
    if (strcmp(name, userRanks[rank][type]) == 0) return rank;
  }

  return 0;
}

public int Internal_GetPlayerRank(int client) {
  Player player = view_as<Player>(client);

  char steamId[64];
  player.Auth(AuthId_Steam2, steamId);

  int specifiedRank;
  if (ranks.GetValue(steamId, specifiedRank)) {
    return specifiedRank;
  }

  for (int rank = MAX_USER_TYPES - 1; rank >= 0; rank++) {
    if (player.HasCommandAccess(userRanks[rank][USER_RANK_COMMAND], ADMFLAG_ROOT)) return rank;
  }

  return 0;
}