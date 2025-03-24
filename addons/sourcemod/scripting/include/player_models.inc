#if defined _player_models_included
	#endinput
#endif
#define _player_models_included

#define MAX_PLAYER_TEAMS 7
#define MAX_CT_PLAYER_MODELS_COUNT 37
#define MAX_T_PLAYER_MODELS_COUNT 35
#define MAX_VIEW_MODELS_COUNT 7

public char ctPlayerModels[MAX_CT_PLAYER_MODELS_COUNT][PLATFORM_MAX_PATH] =
{
	// fbi
	"models/player/custom_player/legacy/ctm_fbi.mdl",
	"models/player/custom_player/legacy/ctm_fbi_varianta.mdl",
	"models/player/custom_player/legacy/ctm_fbi_variantb.mdl",
	"models/player/custom_player/legacy/ctm_fbi_variantc.mdl",
	"models/player/custom_player/legacy/ctm_fbi_variantd.mdl",
	// gign
	"models/player/custom_player/legacy/ctm_gign.mdl",
	"models/player/custom_player/legacy/ctm_gign_varianta.mdl",
	"models/player/custom_player/legacy/ctm_gign_variantb.mdl",
	"models/player/custom_player/legacy/ctm_gign_variantc.mdl",
	"models/player/custom_player/legacy/ctm_gign_variantd.mdl",
	// gsg9
	"models/player/custom_player/legacy/ctm_gsg9.mdl",
	"models/player/custom_player/legacy/ctm_gsg9_varianta.mdl",
	"models/player/custom_player/legacy/ctm_gsg9_variantb.mdl",
	"models/player/custom_player/legacy/ctm_gsg9_variantc.mdl",
	"models/player/custom_player/legacy/ctm_gsg9_variantd.mdl",
	// idf
	"models/player/custom_player/legacy/ctm_idf.mdl",
	"models/player/custom_player/legacy/ctm_idf_variantb.mdl",
	"models/player/custom_player/legacy/ctm_idf_variantc.mdl",
	"models/player/custom_player/legacy/ctm_idf_variantd.mdl",
	"models/player/custom_player/legacy/ctm_idf_variante.mdl",
	"models/player/custom_player/legacy/ctm_idf_variantf.mdl",
	// sas
	"models/player/custom_player/legacy/ctm_sas.mdl",
	"models/player/custom_player/legacy/ctm_sas_varianta.mdl",
	"models/player/custom_player/legacy/ctm_sas_variantb.mdl",
	"models/player/custom_player/legacy/ctm_sas_variantc.mdl",
	"models/player/custom_player/legacy/ctm_sas_variantd.mdl",
	"models/player/custom_player/legacy/ctm_sas_variante.mdl",
	// st6
	"models/player/custom_player/legacy/ctm_st6.mdl",
	"models/player/custom_player/legacy/ctm_st6_varianta.mdl",
	"models/player/custom_player/legacy/ctm_st6_variantb.mdl",
	"models/player/custom_player/legacy/ctm_st6_variantc.mdl",
	"models/player/custom_player/legacy/ctm_st6_variantd.mdl",
	// swat
	"models/player/custom_player/legacy/ctm_swat.mdl",
	"models/player/custom_player/legacy/ctm_swat_varianta.mdl",
	"models/player/custom_player/legacy/ctm_swat_variantb.mdl",
	"models/player/custom_player/legacy/ctm_swat_variantc.mdl",
	"models/player/custom_player/legacy/ctm_swat_variantd.mdl"
};

public char ctViewModels[MAX_VIEW_MODELS_COUNT][PLATFORM_MAX_PATH] =
{
	"models/weapons/ct_arms_fbi.mdl",
	"models/weapons/ct_arms_gign.mdl",
	"models/weapons/ct_arms_gsg9.mdl",
	"models/weapons/ct_arms_idf.mdl",
	"models/weapons/ct_arms_sas.mdl",
	"models/weapons/ct_arms_st6.mdl",
	"models/weapons/ct_arms_swat.mdl"
};

public char tPlayerModels[MAX_T_PLAYER_MODELS_COUNT][PLATFORM_MAX_PATH] =
{
	// anarachist
	"models/player/custom_player/legacy/tm_anarchist.mdl",
	"models/player/custom_player/legacy/tm_anarchist_varianta.mdl",
	"models/player/custom_player/legacy/tm_anarchist_variantb.mdl",
	"models/player/custom_player/legacy/tm_anarchist_variantc.mdl",
	"models/player/custom_player/legacy/tm_anarchist_variantd.mdl",
	// balkan
	"models/player/custom_player/legacy/tm_balkan_varianta.mdl",
	"models/player/custom_player/legacy/tm_balkan_variantb.mdl",
	"models/player/custom_player/legacy/tm_balkan_variantc.mdl",
	"models/player/custom_player/legacy/tm_balkan_variantd.mdl",
	"models/player/custom_player/legacy/tm_balkan_variante.mdl",
	// leet
	"models/player/custom_player/legacy/tm_leet_varianta.mdl",
	"models/player/custom_player/legacy/tm_leet_variantb.mdl",
	"models/player/custom_player/legacy/tm_leet_variantc.mdl",
	"models/player/custom_player/legacy/tm_leet_variantd.mdl",
	"models/player/custom_player/legacy/tm_leet_variante.mdl",
	// phoenix
	"models/player/custom_player/legacy/tm_phoenix.mdl",
	"models/player/custom_player/legacy/tm_phoenix_varianta.mdl",
	"models/player/custom_player/legacy/tm_phoenix_variantb.mdl",
	"models/player/custom_player/legacy/tm_phoenix_variantc.mdl",
	"models/player/custom_player/legacy/tm_phoenix_variantd.mdl",
	// pirate
	"models/player/custom_player/legacy/tm_pirate.mdl",
	"models/player/custom_player/legacy/tm_pirate_varianta.mdl",
	"models/player/custom_player/legacy/tm_pirate_variantb.mdl",
	"models/player/custom_player/legacy/tm_pirate_variantc.mdl",
	"models/player/custom_player/legacy/tm_pirate_variantd.mdl",
	// professional
	"models/player/custom_player/legacy/tm_professional.mdl",
	"models/player/custom_player/legacy/tm_professional_var1.mdl",
	"models/player/custom_player/legacy/tm_professional_var2.mdl",
	"models/player/custom_player/legacy/tm_professional_var3.mdl",
	"models/player/custom_player/legacy/tm_professional_var4.mdl",
	// seperatist
	"models/player/custom_player/legacy/tm_separatist.mdl",
	"models/player/custom_player/legacy/tm_separatist_varianta.mdl",
	"models/player/custom_player/legacy/tm_separatist_variantb.mdl",
	"models/player/custom_player/legacy/tm_separatist_variantc.mdl",
	"models/player/custom_player/legacy/tm_separatist_variantd.mdl"
};

public char tViewModels[MAX_VIEW_MODELS_COUNT][PLATFORM_MAX_PATH] =
{
	"models/weapons/t_arms_anarchist.mdl",
	"models/weapons/t_arms_balkan.mdl",
	"models/weapons/t_arms_leet.mdl",
	"models/weapons/t_arms_phoenix.mdl",
	"models/weapons/t_arms_pirate.mdl",
	"models/weapons/t_arms_professional.mdl",
	"models/weapons/t_arms_separatist.mdl"
};
