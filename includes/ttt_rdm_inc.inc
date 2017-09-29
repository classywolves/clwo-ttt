#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <ttt>
#include <general>


/* Plugin Info */
#define PLUGIN_NAME 			"TTT RDM"
#define PLUGIN_VERSION_M 		"0.0.6"
#define PLUGIN_AUTHOR 			"Popey"
#define PLUGIN_DESCRIPTION		"Handles TTT RDMs."
#define PLUGIN_URL				"https://sinisterheavens.com"

#define should_slay		1
#define should_warn		2

#define StaffClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(Player(%1).is_staff)

Database db;

int max_index = 0;
int max_round = 0;
int round_time = 0;
int current_short_id = 0;

// Lists short_ids for RDMs
int short_ids[500]; // Index = case number, stores death index.
int handled_by[500];
int case_accused[500];
int case_accuser[500];

// Lists clients to slay (1 = slay, 0 = don't slay)
int to_slay[MAXPLAYERS + 1];
int last_handled[MAXPLAYERS + 1]; // Store a staff's last handled case id.
int case_slay[500]; // Store a 1 if case wants the other person slain, 2 if to warn.

char slay_admins[MAXPLAYERS + 1][255];
char _victim_name[500][255];
char _killer_name[500][255];

// Number of times a person has been slain this map.
int slay_count[MAXPLAYERS + 1];

// Prevent spamming of rdm command
int rdm_cooldown[MAXPLAYERS + 1];

// Array of last time players fired guns
int last_gun_fire[MAXPLAYERS + 1];

methodmap Player {
	public Player(int client) {
		return view_as<Player>(client);
	}
	
	property bool valid_client {
		public get() {
			if (this <= 0) { return false; }
			if (this > MaxClients) { return false; }
			if (!IsClientConnected(this)) { return false; }
			if (!IsClientInGame(this)) { return false; }
			if (IsFakeClient(this)) { return false; }
			return true;
		}
	}
	
	property bool is_alive {
		public get() {
			return IsPlayerAlive(this);
		}
	}
	
	property int id {
		public get() {
			return this;
		}
	}
	
	property int slay_count {
		public get() {
			return (slay_count[this]);
		}
		public set(int i) {
			slay_count[this] = i;
		}
	}
	
	property int rdm_cooldown {
		public get() {
			return (rdm_cooldown[this]);
		}
		public set(int i) {
			rdm_cooldown[this] = i;
		}
	}
	
	property int last_gun_fire {
		public get() {
			return (last_gun_fire[this]);
		}
		public set(int i) {
			last_gun_fire[this] = i;
		}
	}
	
	property bool slay {
		public get() {
			return view_as<bool>to_slay[this];
		}
		public set(bool slay) {
			to_slay[this] = view_as<int>slay;
		}
	}
	
	property bool is_staff {
		public get() {
			return CheckCommandAccess(this, "sm_admin", ADMFLAG_GENERIC));
		}
	}
	
	property int last_handled {
		public get() {
			if (!this.staff) {
				return 0;
			}
			return last_handled[this];
		}
		public set(int i) {
			last_handled[this] = i;
		}
	} 
	
	property bool has_handled {
		public get() {
			return (last_handled[this] > 0);
		}
	}
	
	property int ttt_role {
		public get() {
			return TTT_GetClientRole(this);
		}
	}
	
	property int ttt_karma {
		public get() {
			return TTT_GetClientKarma(this);
		}
	}
	
	
	public void set_slain_by(char[] name) {
		slay_admins[this] = name;
	}
	
	public void get_slain_by(char[] output) {
		StrCopy(output, sizeof(output), slay_admins[this]);
	}
	
	public int isKillBadAction(int victim_role) {
		return BadAction(victim_role, this.ttt_role);
	}
	
	public void get_name(char[] output) {
		GetClientName(this, output, sizeof(output));
	}
	
	public void get_auth(int auth_id_type , char[] output) {
		GetClientAuthId(this, auth_id_type, output, sizeof(output));
	}
	
	public void reset_all() {
		this.slay_count = 0;
		this.last_handled = -1;
		this.set_slain_by("");
	}
}

methodmap Case_Victim {
	public Case_Victim(int case_id) {
		return view_as<Case_Victim>(case_id);
	}
	
	property int id {
		public get() {
			return (case_accuser[this]);
		}
		public set(int i) {
			case_accuser[this] = i;
		}
	}
	
	public void set_name(char[] name) {
		_victim_name[this] = name;
	}
	
	public void get_name(char[] output) {
		StrCopy(output, sizeof(output), _victim_name[this]);
	}
	
	public int target_id() { 
		char output[255];
		this.get_name(output);
		this.id = FindTarget(this.id, output, true, false);
		return this.id;
	}
}

methodmap Case_Assailant {
	public Case_Assailant(int case_id) {
		return view_as<Case_Assailant>(case_id);
	}
	
	property int id {
		public get() {
			return (case_accused[this]);
		}
		public set(int i) {
			case_accused[this] = i;
		}
	}
	
	public void set_name(char[] name) {
		_killer_name[this] = name;
	}
	
	public void get_name(char[] output) {
		StrCopy(output, sizeof(output), _killer_name[this]);
	}
	
	public int target_id() { 
		char output[255];
		this.get_name(output);
		this.id = FindTarget(this.id, output, true, false);
		return this.id;
	}
}

methodmap Case {
	
	public Case(int case_id) {
		return view_as<Case>(case_id);
	}
	
	property bool is_valid {
		public get() {
			return (short_ids[this] != 0);
		}
	}
	
	property int id {
		public get() {
			return this;
		}
	}
	
	property bool is_handled {
		public get() {
			return (handled_by[this] != 0);
		}
	}
	
	property int handled_client {
		public get() {
			return handled_by[this];
		}
		public set(int i) {
			handled_by[this] = i;
		}
	}
	
	property int punishment {
		public get() {
			return (case_slay[this]);
		}
		public set(int i) {
			case_slay[this] = i;
		}
	}
	
	property int death_index {
		public get() {
			return short_ids[this];
		} 
		public set(int i) {
			short_ids[this] = i;
		} 
	}
	
	property Case_Victim victim {
		public get() {
			return view_as<Case_Victim>(this);
		}
	}
	
	property Case_Assailant assailant {
		public get() {
			return view_as<Case_Assailant>(this);
		}
	}
	/*
	property int victim_id {
		public get() {
			return (view_as<Case_Victim>(case_id)).id;
		}
		public set(int i) {
			(view_as<Case_Victim>(case_id)).id = i;
		}
	}
	
	property char[] victim_name {
		public get() {
			return (view_as<Case_Victim>(case_id)).name;
		}
		public set(char[] i) {
			(view_as<Case_Victim>(case_id)).name = i;
		}
	}
	
	property int assailant_id {
		public get() {
			return (case_accused[this]);
		}
		public set(int i) {
			case_accused[this] = i;
		}
	}
	
	property char[] assailant_name {
		public get() {
			return (_killer_name[this]);
		}
		public set(char[] i) {
			_killer_name[this] = i;
		}
	}
	*/
	
	public void slay() {
		this.punishment = should_slay;
	}
	
	public void warn() {
		this.punishment = should_warn;
	}
	
	public void reset_all() {
		this.handled_client = 0;
		this.punishment = 0;
		this.death_index = 0;
		this.victim.id = 0;
		this.victim.set_name("");
		this.assailant.id = 0;
		this.assailant.set_name("");
	}
} 

int Count_Staff_New() {
  int counted_mods = 0;
  StaffClients(client) counted_mods++
  return counted_mods;
}
