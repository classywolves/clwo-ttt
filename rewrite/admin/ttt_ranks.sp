#include <ttt_ranks>
#include <player_methodmap>

public Plugin myinfo =
{
	name = "TTT Ranks",
	author = "Popey & iNilo & Corpen",
	description = "TTT Custom rank and access system.",
	version = "1.0.0",
	url = ""
};

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
  {   "rank_senator",     "1",        "Senator",          "Senator",    "α",         "senator"  },
  // SteamID Ranks.
  {   "rank_senioradmin", "1",        "Senior Admin",     "Sen. Admin", "β",         "sadmin"   },
  {   "rank_developer",   "1",        "Developer",        "Dev",        "Δ",         "dev"      }
};

StringMap ranks;

public OnPluginStart() {
	RegisterCmds();

	LoadTranslations("common.phrases");

	// Initialise Rank Overrides.
	ranks = new StringMap();

	PrintToServer("[RNK] Loaded successfully");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
   CreateNative("GetRankName", Native_GetRankName);
   CreateNative("GetPermission", Native_GetPermission);
   CreateNative("GetPlayerRank", Native_GetPlayerRank);
   return APLRes_Success;
}

public void RegisterCmds()
{
	RegServerCmd("sm_refreshcr", Command_RefreshRanks, "Refreshes the custom ranks from the config file.");
	RegConsoleCmd("sm_rank", Command_Rank, "Outputs a users current rank.");
	RegConsoleCmd("sm_ranktest", Command_RankTest, "Sets a temporary rank on the caller.");

	for (int i = 0; i < MAX_USER_STANDARD_RANKS; i++)
	{
		RegAdminCmd(userRanks[i][USER_RANK_COMMAND], Command_RankCheck, ADMFLAG_ROOT, "");
	}
}

public void OnConfigsExecuted()
{
	CPrintToChatAll("{purple}[TTT] {yellow}Reloading custom ranks");
	ranks.Clear();
	ParseConfig();
}

public void ParseConfig()
{
	KeyValues kv = new KeyValues("TTT_Ranks");
	char config[PLATFORM_MAX_PATH];

	BuildPath(Path_SM, config, sizeof(config), "configs/ttt/ttt_ranks.cfg");
	kv.ImportFromFile(config);
	kv.GotoFirstSubKey();

	char steamId[64];
	int customRank;
	do
	{
		kv.GetString("SteamID", steamId, 64);
		customRank = kv.GetNum("RankIndex", 0);
		ranks.SetValue(steamId, customRank);
		CPrintToChatAll("{purple}[TTT] {yellow}Added new custom rank to {blue}%s{yellow}: {green}%i", steamId, customRank);
	} while (kv.GotoNextKey());

	delete kv;
}

public Action Command_RefreshRanks(int args)
{
	ranks.Clear();
	ParseConfig();

	return Plugin_Handled;
}

public Action Command_Rank(int client, int args)
{
	Player player = view_as<Player>(client);
	char steamId[64];
	player.Auth(AuthId_Steam2, steamId);

	CPrintToChatAll("{purple}[TTT] {blue}%N {default}(%s) {yellow}has the rank: {green}%i", client, steamId, Internal_GetPlayerRank(client));

	return Plugin_Handled;
}

public Action Command_RankTest(int client, int args)
{
	Player player = view_as<Player>(client);
	if (!player.Access(RANK_SENATOR, true)) return Plugin_Handled;

	if (args < 1)
	{
		player.Error("Invalid Command Usage: sm_ranktest <rank>.");
		return Plugin_Handled;
	}

	char buffer[64];
	GetCmdArg(1, buffer, 64);
	int rank = StringToInt(buffer);
	if (rank < 0 || rank >= MAX_USER_RANKS)
	{
		player.Error("Invalid Command Parameter 'rank' expected an integer of the range 0 - 10.");
		return Plugin_Handled;
	}

	player.Auth(AuthId_Steam2, buffer);
	ranks.SetValue(buffer, rank);

	return Plugin_Handled;
}

public Action Command_RankCheck(int client, int args)
{
	return Plugin_Handled;
}

public int Native_GetRankName(Handle plugin, int numParams) {
	int rank = GetNativeCell(1);
	char name[64];
	GetNativeString(2, name, sizeof(name));
	int type = GetNativeCell(3);

	Internal_GetRankName(rank, name, type);
}

public int Native_GetPermission(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int rank = GetNativeCell(2);

	return view_as<int>(Internal_GetPermission(client, rank));
}

public int Native_GetPlayerRank(Handle plugin, int numParams) {
	int client = GetNativeCell(1);

	return Internal_GetPlayerRank(client);
}

public Internal_GetRankName(int rank, char name[64], int type) {
	SetNativeString(2, userRanks[rank][type], 64, false);
}

public int Internal_GetPermission(int client, int rank) {
	return Internal_GetPlayerRank(client) >=  rank;
}

public int Internal_GetPlayerRank(int client) {
	Player player = view_as<Player>(client);

	char steamId[64];
	player.Auth(AuthId_Steam2, steamId);

	int specifiedRank;
	if (ranks.GetValue(steamId, specifiedRank)) {
		return specifiedRank;
	}

	int rank;
	for (rank = 1; rank < MAX_USER_STANDARD_RANKS; rank++) {
	if (!player.HasCommandAccess(userRanks[rank][USER_RANK_COMMAND], ADMFLAG_ROOT)) return rank - 1;
	}

	return rank;
}
