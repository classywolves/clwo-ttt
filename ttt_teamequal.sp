#include <general>
#include <ttt_helpers>
#include <player_methodmap>
#include <logger>

public OnPluginStart() {
	setLogSource("teamEqual");
	database_ttt = ConnectDatabase("ttt", "ttt");
}

public void TTT_OnRoundStart(int innocents, int traitors, int detective) {
	if (innocents + traitors > 12) {
		int to_swap = innocents + traitors - 12
		int innocent_clients[MAXPLAYERS + 1][2];
		int index = 0;

		LoopValidClients(client) {
			Player player = Player(client)
			if (player.team == CS_TEAM_T) {
				innocent_clients[index][0] = player.karma;
				innocent_clients[index][1] = client;
				log(Info, "%d %d", innocent_clients[index][0], innocent_clients[index][1])
				index++;
			}
		}

		SortCustom2D(innocent_clients, MAXPLAYERS + 1, SortPlayerItems);

		for (int i = 0; i < to_swap; i++) {
				Player player = Player(innocent_clients[to_swap][1]);
				ChangeClientTeam(client, CS_TEAM_CT)
				player.team = CS_TEAM_CT;
		}
	}
}

public SortPlayerItems(int[] a, int[] b, const int[][] array, Handle hndl) {
	if (b[0] == a[0]) return 0;
	if (b[0] > a[0]) return 1;
	return -1;
}