#if defined _round_methodmap_included
	#endinput
#endif
#define _round_methodmap_included

int roundStart;

methodmap Round {
	public static void Start() {
		roundStart = GetTime();
	}

	public static int Time() {
		return GetTime() - roundStart;
	}

	public static int AfterTime(int time) {
		return Round.Time() - time > 0;
	}
}