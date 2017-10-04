methodmap Player {
	public Player(int client) {
		return view_as<Player>(client);
	}

	property bool beacon {
		public get() { return player_beacon[this]; }
		public set(bool enable) { player_beacon[this] = enable; }
	}

	property bool valid_client {
		public get() {
			if(this <= 0) { return false; }
			if(this > MaxClients) { return false; }
			if (!IsClientConnected(this)) { return false; } 
			if(!IsClientInGame(this)) { return false; }
			if(IsFakeClient(this)) { return false; }
			return true;
		}
	}

	public bool set_beacon(bool enable) {
		player_beacon[this] = enable;
	}

	public bool toggle_beacon() {
		player_beacon[this] = !player_beacon[this]
	}

}