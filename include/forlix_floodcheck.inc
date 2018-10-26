// Forlix FloodCheck
// http://forlix.org/, df@forlix.org
//
// Copyright (c) 2008-2013 Dominik Friedrichs

public SharedPlugin:__pl_forlix_fc =
{
	name = "forlix_floodcheck",
	file = "forlix_floodcheck.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_forlix_fc_SetNTVOptional()
{
  MarkNativeAsOptional("IsClientFlooding");
}
