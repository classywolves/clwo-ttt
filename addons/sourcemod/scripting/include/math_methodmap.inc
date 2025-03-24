#if defined _math_methodmap_included
	#endinput
#endif
#define _math_methodmap_included

methodmap Math
{
	public Math()
    {
		return view_as<Math>(0);
	}

	public int Min(int a, int b)
    {
		return a > b ? b : a;
	}

	public int Max(int a, int b)
    {
		return a > b ? a : b;
	}
};
