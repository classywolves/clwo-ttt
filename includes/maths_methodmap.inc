#if defined _maths_methodmap_included
	#endinput
#endif
#define _maths_methodmap_included

#define that view_as<int>(this)

methodmap Maths {
	public Maths() {
		return view_as<Maths>(0);
	}

	public int min(int a, int b) {
		return a > b ? b : a;
	}

	public int max(int a, int b) {
		return a > b ? a : b;
	}
}