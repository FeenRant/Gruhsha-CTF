#include "ScoreboardCommon.as";
#include "Accolades.as";
#include "ColoredNameToggleCommon.as";
#include "ApprovedTeams.as";
//#include "RulesCore"

CPlayer@ hoveredPlayer;
Vec2f hoveredPos;

int hovered_accolade = -1;
int hovered_age = -1;
int hovered_tier = -1;
bool draw_age = false;
bool draw_tier = false;

float scoreboardMargin = 52.0f;
float scrollOffset = 0.0f;
float scrollSpeed = 4.0f;
float maxMenuWidth = 700;

bool mouseWasPressed2 = false;
bool mouseWasPressed1 = false;

const string OLD_PLAYER_STATS_CORE = "player stats core";

class OldPlayerStatsCore {
	dictionary stats;
}

class OldPlayerStats {
	s32 kills;
	s32 deaths;
	s32 assists;

	OldPlayerStats() {
		kills   = 0;
		deaths  = 0;
		assists = 0;
	}
}

string[] age_description = {
	"New Player - Welcome them to the game!",
	//first month
	"This player has 1 to 2 weeks of experience",
	"This player has 2 to 3 weeks of experience",
	"This player has 3 to 4 weeks of experience",
	//first year
	"This player has 1 to 2 months of experience",
	"This player has 2 to 3 months of experience",
	"This player has 3 to 6 months of experience",
	"This player has 6 to 9 months of experience",
	"This player has 9 to 12 months of experience",
	//cake day
	"Cake Day - it's this player's KAG Birthday!",
	//(gap in the sheet)
	"", "", "", "", "", "",
	//established player
	"This player has 1 year of experience",
	"This player has 2 years of experience",
	"This player has 3 years of experience",
	"This player has 4 years of experience",
	"This player has 5 years of experience",
	"This player has 6 years of experience",
	"This player has 7 years of experience",
	"This player has 8 years of experience",
	"This player has 9 years of experience",
	"This player has over a decade of experience"
};

string[] tier_description = {
	"", //f2p players, no description
	"This player is a Squire Supporter",
	"This player is a Knight Supporter",
	"This player is a Royal Guard Supporter",
	"This player is a Round Table Supporter"
};

//returns the bottom
float drawScoreboard(CPlayer@ localplayer, CPlayer@[] players, Vec2f topleft, CTeam@ team, Vec2f emblem)
{
	if (players.size() <= 0)
		return topleft.y;

	SColor teamcolor = SColor(255, 200, 200, 200);
	string teamname = "Spectators";

	if (team !is null)
	{
		teamcolor = team.color;
		teamname = team.getName();
	}

	CRules@ rules = getRules();
//	RulesCore@ core;
//	rules.get("core", @core);

	Vec2f orig = topleft; //save for later

	f32 lineheight = 16;
	f32 padheight = 6;
	f32 stepheight = lineheight + padheight;
	Vec2f bottomright(Maths::Min(getScreenWidth() - 100, getScreenWidth()/2 + maxMenuWidth), topleft.y + (players.length + 5.5) * stepheight);
	GUI::DrawPane(topleft, bottomright, teamcolor);

	//offset border
	topleft.x += stepheight;
	bottomright.x -= stepheight;
	topleft.y += stepheight;

	GUI::SetFont("menu");

	//draw team info
	GUI::DrawText(getTranslatedString(teamname), Vec2f(topleft.x, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Players: {PLAYERCOUNT}").replace("{PLAYERCOUNT}", "" + players.length), Vec2f(bottomright.x - 400, topleft.y), SColor(0xffffffff));

	topleft.y += stepheight * 2;

	const int accolades_start = 770;
	const int age_start = accolades_start + 80;

	draw_age = false;
	for(int i = 0; i < players.length; i++) {
		if (players[i].getRegistrationTime() > 0) {
			draw_age = true;
			break;
		}
	}

	draw_tier = false;
	for(int i = 0; i < players.length; i++) {
		if (players[i].getSupportTier() > 0) {
			draw_tier = true;
			break;
		}
	}
	const int tier_start = (draw_age ? age_start : accolades_start) + 70;

	// Waffle: Change header color for old stats
	CControls@ controls = getControls();
	bool old_stats = controls.isKeyPressed(KEY_SHIFT) || controls.isKeyPressed(KEY_LSHIFT) || controls.isKeyPressed(KEY_RSHIFT);
	SColor kdr_color = old_stats ? OLD_STATS_COLOR : SColor(0xffffffff);

	//draw player table header
	GUI::DrawText(getTranslatedString("Player"), Vec2f(topleft.x, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Username"), Vec2f(bottomright.x - 470, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Ping"), Vec2f(bottomright.x - 330, topleft.y), SColor(0xffffffff));
	GUI::DrawText(getTranslatedString("Kills"), Vec2f(bottomright.x - 260, topleft.y), kdr_color);      // Waffle: Change header color for old stats
	GUI::DrawText(getTranslatedString("Deaths"), Vec2f(bottomright.x - 190, topleft.y), kdr_color);     // Waffle: --
	GUI::DrawText(getTranslatedString("Assists"), Vec2f(bottomright.x - 120, topleft.y), kdr_color);    // Waffle: --
	GUI::DrawText(getTranslatedString("KDR"), Vec2f(bottomright.x - 50, topleft.y), kdr_color);         // Waffle: --
	GUI::DrawText(getTranslatedString("Accolades"), Vec2f(bottomright.x - accolades_start, topleft.y), SColor(0xffffffff));
	if(draw_age)
	{
		GUI::DrawText(getTranslatedString("Age"), Vec2f(bottomright.x - age_start, topleft.y), SColor(0xffffffff));
	}
	if(draw_tier)
	{
		GUI::DrawText(getTranslatedString("Tier"), Vec2f(bottomright.x - tier_start, topleft.y), SColor(0xffffffff));
	}

	topleft.y += stepheight * 0.5f;

	Vec2f mousePos = controls.getMouseScreenPos();

	//draw players
	for (u32 i = 0; i < players.length; i++)
	{
		CPlayer@ p = players[i];
		CBlob@ b = p.getBlob(); // REMINDER: this can be null if you're using this down below

		topleft.y += stepheight;
		bottomright.y = topleft.y + lineheight;

		bool playerHover = mousePos.y > topleft.y && mousePos.y < topleft.y + 15;

		if (playerHover)
		{
			if (controls.mousePressed1)
			{
				setSpectatePlayer(p.getUsername());
			}
			if (controls.mousePressed2 && !mouseWasPressed2)
			{
				// reason for this is because this is called multiple per click (since its onRender, and clicking is updated per tick)
				// we don't want to spam anybody using a clipboard history program
				if (getFromClipboard() != p.getUsername())
				{
					CopyToClipboard(p.getUsername());
					rules.set_u16("client_copy_time", getGameTime());
					rules.set_string("client_copy_name", p.getUsername());
					rules.set_Vec2f("client_copy_pos", mousePos + Vec2f(0, -10));
				}
			}
		}

		Vec2f lineoffset = Vec2f(0, -2);

		u32 underlinecolor = 0xff404040;
		u32 playercolour = (p.getBlob() is null || p.getBlob().hasTag("dead")) ? 0xff505050 : 0xff808080;
		if (playerHover)
		{
			playercolour = 0xffcccccc;
			@hoveredPlayer = p;
			hoveredPos = topleft;
			hoveredPos.x = bottomright.x - 150;
		}

		GUI::DrawLine2D(Vec2f(topleft.x, bottomright.y + 1) + lineoffset, Vec2f(bottomright.x, bottomright.y + 1) + lineoffset, SColor(underlinecolor));
		GUI::DrawLine2D(Vec2f(topleft.x, bottomright.y) + lineoffset, bottomright + lineoffset, SColor(playercolour));

		// class icon

		string classTexture = "";
		u16 classIndex = 0;
		Vec2f classIconSize;
		Vec2f classIconOffset = Vec2f(0, 0);
		if (p.isMyPlayer())
		{
			classTexture = "ScoreboardIcons.png";
			classIndex = 4;
			classIconSize = Vec2f(16, 16);
		}
		else
		{
			classTexture = "playercardicons.png";
			classIndex = 0;

			// why are player-scoreboard functions hardcoded
			// after looking into it let's not bother moving it to scripts for now
			classIndex = p.getScoreboardFrame();

			// knight is 3 but should be 0 for this texture
			// fyi it's pure coincidence builder and archer are already a match
			classIndex %= 3;

			classIconSize = Vec2f(16, 16);

			if (b is null && teamname != "Spectators") // player dead
			{
				classIndex += 16;
				classIconSize = Vec2f(8, 8);
				classIconOffset = Vec2f(4, 4);
			}
			else if (teamname == "Spectators")
			{
				classIndex += 20;
				classIconSize = Vec2f(8, 8);
				classIconOffset = Vec2f(4, 4);
			}
		}
		if (classTexture != "")
		{
			GUI::DrawIcon(classTexture, classIndex, classIconSize, topleft + classIconOffset, 0.5f, p.getTeamNum());
		}

		string username = p.getUsername();

		string playername = p.getCharacterName();
		string clantag = p.getClantag();

		if(getSecurity().isPlayerNameHidden(p) && getLocalPlayer() !is p)
		{
			if(isAdmin(getLocalPlayer()))
			{
				playername = username + "(hidden: " + clantag + " " + playername + ")";
				clantag = "";

			}
			else
			{
				playername = username;
				clantag = "";
			}

		}

		// head icon

		string headTexture = "playercardicons.png";
		int headIndex = 3;
		int teamIndex = p.getTeamNum();
		Vec2f headOffset = Vec2f(30, 0);
		float headScale = 0.5f;

		if (b !is null)
		{
			headIndex = b.get_s32("head index");
			headTexture = b.get_string("head texture");
			teamIndex = b.get_s32("head team");
			headOffset += Vec2f(-8, -12);
			headScale = 1.0f;
		}
		if(teamname != "Spectators")
		{
			GUI::DrawIcon(headTexture, headIndex, Vec2f(16, 16), topleft + headOffset, headScale, teamIndex);
		}
		// Mark captain in scoreboard
		if (getRules().get_string("team_"+p.getTeamNum()+"_leader")==p.getUsername())
		{
			if (g_locale == "ru")
				GUI::DrawIcon("CaptainMark_ru.png", 0, Vec2f(42, 16), topleft +Vec2f(-96, -4)*0.5f, 0.5f, 0);
			else if (g_locale == "de")
				GUI::DrawIcon("CaptainMark_de.png", 0, Vec2f(42, 16), topleft +Vec2f(-96, -4)*0.5f, 0.5f, 0);
			else
				GUI::DrawIcon("CaptainMark_en.png", 0, Vec2f(42, 16), topleft +Vec2f(-96, -4)*0.5f, 0.5f, 0);
		}

		// for kussaka: de texture
		if (getRules().get_string("team_"+p.getTeamNum()+"_leader")==p.getUsername())
		{
			if (p.getUsername() == "kusaka79")
				GUI::DrawIcon("CaptainMark_kusaka.png", 0, Vec2f(42, 16), topleft +Vec2f(-96, -4)*0.5f, 0.5f, 0);
		}

		//have to calc this from ticks
		s32 ping_in_ms = s32(p.getPing() * 1000.0f / 30.0f);

		//how much room to leave for names and clantags
		float name_buffer = 56.0f;
		Vec2f clantag_actualsize(0, 0);

		//render the player + stats
		SColor namecolour = getNameColour(p);

		//right align clantag
		if (clantag != "")
		{
			string username = p.getUsername();

			GUI::GetTextDimensions(clantag, clantag_actualsize);
			GUI::DrawText(clantag, topleft + Vec2f(name_buffer, 0), SColor(0xff888888));

			// recolor clantag for TerminalHash
			if (username == "TerminalHash")
				{
				GUI::DrawText(clantag, topleft + Vec2f(name_buffer, 0), SColor(0xffad7fa8));
				}
			//draw name alongside
			GUI::DrawText(playername, topleft + Vec2f(name_buffer + clantag_actualsize.x + 8, 0), namecolour);
		}
		else
		{
			//draw name alone
			GUI::DrawText(playername, topleft + Vec2f(name_buffer, 0), namecolour);
		}

		//draw account age indicator
		if (draw_age)
		{
			int regtime = p.getRegistrationTime();
			if (regtime > 0)
			{
				int reg_month = Time_Month(regtime);
				int reg_day = Time_MonthDate(regtime);
				int reg_year = Time_Year(regtime);

				int days = Time_DaysSince(regtime);

				int age_icon_start = 32;
				int icon = 0;
				bool show_years = false;
				int age = 0;
				//less than a month?
				if (days < 28)
				{
					int week = days / 7;
					icon = week;
				}
				else
				{
					//we use 30 day "months" here
					//for simplicity and consistency of badge allocation
					int months = days / 30;
					if (months < 12)
					{
						switch(months) {
							case 0:
							case 1:
								icon = 0;
								break;
							case 2:
								icon = 1;
								break;
							case 3:
							case 4:
							case 5:
								icon = 2;
								break;
							case 6:
							case 7:
							case 8:
								icon = 3;
								break;
							case 9:
							case 10:
							case 11:
							default:
								icon = 4;
								break;
						}
						icon += 4;
					}
					else
					{
						//figure out birthday
						int month_delta = Time_Month() - reg_month;
						int day_delta = Time_MonthDate() - reg_day;
						int birthday_delta = -1;

						if (month_delta < 0 || month_delta == 0 && day_delta < 0)
						{
							birthday_delta = -1;
						}
						else if (month_delta == 0 && day_delta == 0)
						{
							birthday_delta = 0;
						}
						else
						{
							birthday_delta = 1;
						}

						//check if its cake day
						if (birthday_delta == 0)
						{
							icon = 9;
						}
						else
						{
							//check if we're in the extra "remainder" days from using 30 month days
							if(days < 366)
							{
								//(9 months badge still)
								icon = 8;
							}
							else
							{
								//years delta
								icon = (Time_Year() - reg_year) - 1;
								//before or after birthday?
								if (birthday_delta == -1)
								{
									icon -= 1;
								}
								show_years = true;
								age = icon + 1; // icon frames start from 0
								//ensure sane
								icon = Maths::Clamp(icon, 0, 9);
								//shift line
								icon += 16;
							}
						}
					}
				}

				float x = bottomright.x - age_start + 8;
				float extra = 8;

				if(show_years)
				{
					drawAgeIcon(age, Vec2f(x, topleft.y));
				}
				else
				{
					GUI::DrawIcon("AccoladeBadges", age_icon_start + icon, Vec2f(16, 16), Vec2f(x, topleft.y), 0.5f, p.getTeamNum());
				}

				if (playerHover && mousePos.x > x - extra && mousePos.x < x + 16 + extra)
				{
					hovered_age = icon;
				}
			}

		}

		//draw support tier
		if(draw_tier)
		{
			int tier = p.getSupportTier();

			if(tier > 0)
			{
				int tier_icon_start = 15;
				float x = bottomright.x - tier_start + 8;
				float extra = 8;
				GUI::DrawIcon("AccoladeBadges", tier_icon_start + tier, Vec2f(16, 16), Vec2f(x, topleft.y), 0.5f, p.getTeamNum());

				if (playerHover && mousePos.x > x - extra && mousePos.x < x + 16 + extra)
				{
					hovered_tier = tier;
				}
			}

		}

		//render player accolades
		Accolades@ acc = getPlayerAccolades(username);
		if (acc !is null)
		{
			//(remove crazy amount of duplicate code)
			int[] badges_encode = {
				//count,                icon,  show_text, group

				//misc accolades
				(acc.community_contributor ?
					1 : 0),             4,     0,         0,
				(acc.github_contributor ?
					1 : 0),             5,     0,         0,
				(acc.map_contributor ?
					1 : 0),             6,     0,         0,
				(acc.moderation_contributor && (
						//always show accolade of others if local player is special
						(p !is localplayer && isSpecial(localplayer)) ||
						//always show accolade for ex-admins
						!isSpecial(p) ||
						//show accolade only if colored name is visible
						coloredNameEnabled(getRules(), p)
					) ?
					1 : 0),             7,     0,         0,
				(p.getOldGold() ?
					1 : 0),             8,     0,         0,

				//tourney badges
				acc.gold,               0,     1,         1,
				acc.silver,             1,     1,         1,
				acc.bronze,             2,     1,         1,
				acc.participation,      3,     1,         1,

				//(final dummy)
				0, 0, 0, 0,
			};
			//encoding per-group
			int[] group_encode = {
				//singles
				accolades_start,                 24,
				//medals
				accolades_start - (24 * 5 + 12), 38,
			};

			for(int bi = 0; bi < badges_encode.length; bi += 4)
			{
				int amount    = badges_encode[bi+0];
				int icon      = badges_encode[bi+1];
				int show_text = badges_encode[bi+2];
				int group     = badges_encode[bi+3];

				int group_idx = group * 2;

				if(
					//non-awarded
					amount <= 0
					//erroneous
					|| group_idx < 0
					|| group_idx >= group_encode.length
				) continue;

				int group_x = group_encode[group_idx];
				int group_step = group_encode[group_idx+1];

				float x = bottomright.x - group_x;

				GUI::DrawIcon("AccoladeBadges", icon, Vec2f(16, 16), Vec2f(x, topleft.y), 0.5f, p.getTeamNum());
				if (show_text > 0)
				{
					string label_text = "" + amount;
					int label_center_offset = label_text.size() < 2 ? 4 : 0;
					GUI::DrawText(
						label_text,
						Vec2f(x + 15 + label_center_offset, topleft.y),
						SColor(0xffffffff)
					);
				}

				if (playerHover && mousePos.x > x && mousePos.x < x + 16)
				{
					hovered_accolade = icon;
				}

				//handle repositioning
				group_encode[group_idx] -= group_step;

			}
		}

		// Waffle: Keep old stats
		s32 kills   = p.getKills();
		s32 deaths  = p.getDeaths();
		s32 assists = p.getAssists();

		if (old_stats)
		{
			OldPlayerStatsCore@ old_player_stats_core;
			rules.get(OLD_PLAYER_STATS_CORE, @old_player_stats_core);
			if (old_player_stats_core !is null)
			{
				OldPlayerStats@ old_player_stats;
				if (old_player_stats_core.stats.exists(username))
				{
					old_player_stats_core.stats.get(username, @old_player_stats);
				}
				else
				{
					@old_player_stats = OldPlayerStats();
					old_player_stats_core.stats.set(username, @old_player_stats);
				}
				kills   = old_player_stats.kills;
				deaths  = old_player_stats.deaths;
				assists = old_player_stats.assists;
			}
		}

		GUI::DrawText("" + username, Vec2f(bottomright.x - 470, topleft.y), namecolour);
		GUI::DrawText("" + ping_in_ms, Vec2f(bottomright.x - 330, topleft.y), SColor(0xffffffff));
		GUI::DrawText("" + kills, Vec2f(bottomright.x - 260, topleft.y), kdr_color);
		GUI::DrawText("" + deaths, Vec2f(bottomright.x - 190, topleft.y), kdr_color);
		GUI::DrawText("" + assists, Vec2f(bottomright.x - 120, topleft.y), kdr_color);
		GUI::DrawText("" + formatFloat(kills / Maths::Max(f32(deaths), 1.0f), "", 0, 2), Vec2f(bottomright.x - 50, topleft.y), kdr_color);

		bool local_is_captain = localplayer !is null && localplayer.getUsername()==rules.get_string("team_"+localplayer.getTeamNum()+"_leader");
		bool player_is_our_guy = localplayer !is null && localplayer.getTeamNum()==p.getTeamNum() || localplayer !is null && 200 == p.getTeamNum();
		bool player_isnt_local = localplayer !is null && p !is localplayer;

		if (isAdmin(getLocalPlayer()))
		{
			MakeScoreboardButton(Vec2f(bottomright.x - 330, topleft.y-7), "spec", p.getUsername());
			MakeScoreboardButton(Vec2f(bottomright.x - 400, topleft.y-7), "red", p.getUsername());
			MakeScoreboardButton(Vec2f(bottomright.x - 470, topleft.y-7), "blue", p.getUsername());
		}

		else if (local_is_captain && player_is_our_guy && player_isnt_local)  //&& !isPickingEnded()
		{
			if(p.getTeamNum() != 200) {
				MakeScoreboardButton(Vec2f(bottomright.x - 400, topleft.y-7), "spec", p.getUsername());
			}
			else if (localplayer.getTeamNum() == 0) {
				MakeScoreboardButton(Vec2f(bottomright.x - 400, topleft.y-7), "blue", p.getUsername());
			}
			else if (localplayer.getTeamNum() == 1) {
				MakeScoreboardButton(Vec2f(bottomright.x - 400, topleft.y-7), "red", p.getUsername());
			}
		}
	}

	// username copied text, goes at bottom to overlay above everything else
	uint durationLeft = rules.get_u16("client_copy_time");

	if ((durationLeft + 64) > getGameTime())
	{
		durationLeft = getGameTime() - durationLeft;
		DrawFancyCopiedText(rules.get_string("client_copy_name"), rules.get_Vec2f("client_copy_pos"), durationLeft);
	}

	return topleft.y;

}

void onRenderScoreboard(CRules@ this)
{
	//sort players
	CPlayer@[] blueplayers;
	CPlayer@[] redplayers;
	CPlayer@[] spectators;
	for (u32 i = 0; i < getPlayersCount(); i++)
	{
		CPlayer@ p = getPlayer(i);
		f32 kdr = getKDR(p);
		bool inserted = false;
		if (p.getTeamNum() == this.getSpectatorTeamNum())
		{
			spectators.push_back(p);
			continue;
		}

		int teamNum = p.getTeamNum();
		if (teamNum == 0) //blue team
		{
			for (u32 j = 0; j < blueplayers.length; j++)
			{
				if (getKDR(blueplayers[j]) < kdr)
				{
					blueplayers.insert(j, p);
					inserted = true;
					break;
				}
			}

			if (!inserted)
				blueplayers.push_back(p);

		}
		else //if (teamNum == 1)
		{
			for (u32 j = 0; j < redplayers.length; j++)
			{
				if (getKDR(redplayers[j]) < kdr)
				{
					redplayers.insert(j, p);
					inserted = true;
					break;
				}
			}

			if (!inserted)
				redplayers.push_back(p);

		} /*
		else
		{
			for (u32 j = 0; j < spectators.length; j++)
			{
				if (getKDR(spectators[j]) < kdr)
				{
					spectators.insert(j, p);
					inserted = true;
					break;
				}
			}

			if (!inserted)
				spectators.push_back(p);
		} */
	}

	//draw board

	CPlayer@ localPlayer = getLocalPlayer();
	if (localPlayer is null)
		return;
	int localTeam = localPlayer.getTeamNum();
	if (localTeam != 0 && localTeam != 1)
		localTeam = 0;

	@hoveredPlayer = null;

	Vec2f topleft(Maths::Max( 100, getScreenWidth()/2 -maxMenuWidth), 150);
	drawServerInfo(40);

	// start the scoreboard lower or higher.
	topleft.y -= scrollOffset;

	//(reset)
	hovered_accolade = -1;
	hovered_age = -1;
	hovered_tier = -1;

	//draw the scoreboards
	topleft.y += 10;

	if (localTeam == 0)
		topleft.y = drawScoreboard(localPlayer, blueplayers, topleft, this.getTeam(0), Vec2f(0, 0));
	else
		topleft.y = drawScoreboard(localPlayer, redplayers, topleft, this.getTeam(1), Vec2f(32, 0));

	if (blueplayers.length > 0 || redplayers.length > 0)
		topleft.y += 52;

	if (localTeam == 1)
		topleft.y = drawScoreboard(localPlayer, blueplayers, topleft, this.getTeam(0), Vec2f(0, 0));
	else
		topleft.y = drawScoreboard(localPlayer, redplayers, topleft, this.getTeam(1), Vec2f(32, 0));

	if (blueplayers.length > 0 && redplayers.length > 0)
		topleft.y += 52;

	topleft.y = drawScoreboard(localPlayer, spectators, topleft, this.getTeam(255), Vec2f(32, 0));


	float scoreboardHeight = topleft.y + scrollOffset;
	float screenHeight = getScreenHeight();
	CControls@ controls = getControls();

	if(scoreboardHeight > screenHeight) {
		Vec2f mousePos = controls.getMouseScreenPos();

		float fullOffset = (scoreboardHeight + scoreboardMargin) - screenHeight;

		if(scrollOffset < fullOffset && mousePos.y > screenHeight*0.83f) {
			scrollOffset += scrollSpeed;
		}
		else if(scrollOffset > 0.0f && mousePos.y < screenHeight*0.16f) {
			scrollOffset -= scrollSpeed;
		}

		scrollOffset = Maths::Clamp(scrollOffset, 0.0f, fullOffset);
	}

	drawPlayerCard(hoveredPlayer, hoveredPos);

	drawHoverExplanation(hovered_accolade, hovered_age, hovered_tier, Vec2f(getScreenWidth() * 0.5, topleft.y));

	mouseWasPressed2 = controls.mousePressed2; 
}

void drawHoverExplanation(int hovered_accolade, int hovered_age, int hovered_tier, Vec2f centre_top)
{
	if( //(invalid/"unset" hover)
		(hovered_accolade < 0
		 || hovered_accolade >= accolade_description.length) &&
		(hovered_age < 0
		 || hovered_age >= age_description.length) &&
		(hovered_tier < 0
		 || hovered_tier >= tier_description.length)
	) {
		return;
	}

	string desc = getTranslatedString(
		(hovered_accolade >= 0) ?
			accolade_description[hovered_accolade] :
			hovered_age >= 0 ?
				age_description[hovered_age] :
				tier_description[hovered_tier]
	);

	Vec2f size(0, 0);
	GUI::GetTextDimensions(desc, size);

	Vec2f tl = centre_top - Vec2f(size.x / 2, 0);
	Vec2f br = tl + size;

	//margin
	Vec2f expand(8, 8);
	tl -= expand;
	br += expand;

	GUI::DrawPane(tl, br, SColor(0xffffffff));
	GUI::DrawText(desc, tl + expand, SColor(0xffffffff));
}

void onTick(CRules@ this)
{
	if (this.getCurrentState() == GAME)
	{
		this.add_u32("match_time", 1);

		if (isServer() && this.get_u32("match_time") % (10 * getTicksASecond()) == 0)
		{
			this.Sync("match_time", true);
		}
	}
}

void onInit(CRules@ this)
{
	// Waffle: Keep old stats
	OldPlayerStatsCore@ old_player_stats_core = OldPlayerStatsCore();
	this.set(OLD_PLAYER_STATS_CORE, @old_player_stats_core);
	onRestart(this);
}

void onRestart(CRules@ this)
{
	// Waffle: Reset scoreboard
	OldPlayerStatsCore@ old_player_stats_core;
	this.get(OLD_PLAYER_STATS_CORE, @old_player_stats_core);
	for (u8 i = 0; i < getPlayerCount(); i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null)
		{
			continue;
		}

		// Cache previous game
		if (old_player_stats_core !is null)
		{
			string player_name = player.getUsername();
			OldPlayerStats@ old_player_stats;
			if (old_player_stats_core.stats.exists(player_name))
			{
				old_player_stats_core.stats.get(player_name, @old_player_stats);
			}
			else
			{
				@old_player_stats = OldPlayerStats();
				old_player_stats_core.stats.set(player_name, @old_player_stats);
			}

			old_player_stats.kills    = player.getKills();
			old_player_stats.deaths   = player.getDeaths();
			old_player_stats.assists = player.getAssists();
		}

		// Reset for next game
		player.setKills(0);
		player.setDeaths(0);
		player.setAssists(0);
	}

	if(isServer())
	{
		this.set_u32("match_time", 0);
		this.Sync("match_time", true);
		getMapName(this);
	}
}

void getMapName(CRules@ this)
{
	CMap@ map = getMap();
	if(map !is null)
	{
		string[] name = map.getMapName().split('/');	 //Official server maps seem to show up as
		string mapName = name[name.length() - 1];		 //``Maps/CTF/MapNameHere.png`` while using this instead of just the .png
		mapName = getFilenameWithoutExtension(mapName);  // Remove extension from the filename if it exists

		this.set_string("map_name", mapName);
		this.Sync("map_name",true);
	}
}

void drawAgeIcon(int age, Vec2f position)
{
    int number_gap = 8;
	int years_frame_start = 48;
    if(age >= 10)
    {
        position.x -= number_gap - 4;
        GUI::DrawIcon("AccoladeBadges", years_frame_start + (age / 10), Vec2f(16, 16), position, 0.5f, 0);
        age = age % 10;
        position.x += number_gap;
    }
    GUI::DrawIcon("AccoladeBadges", years_frame_start + age, Vec2f(16, 16), position, 0.5f, 0);
    position.x += 4;
	if(age == 1) position.x -= 1; // fix y letter offset for number 1
    GUI::DrawIcon("AccoladeBadges", 58, Vec2f(16, 16), position, 0.5f, 0); // y letter
}

void DrawFancyCopiedText(string username, Vec2f mousePos, uint duration)
{
	string text = "Username copied: " + username;
	Vec2f pos = mousePos - Vec2f(0, duration);
	int col = (255 - duration * 3);

	GUI::DrawTextCentered(text, pos, SColor((255 - duration * 4), col, col, col));
}

void MakeScoreboardButton(Vec2f pos, const string&in text, const string username)
{
	Vec2f dim;
	GUI::GetTextDimensions(text, dim);

	const f32 width = dim.x + 20;
	const f32 height = dim.y*1.5f;
	const Vec2f tl = Vec2f(getScreenWidth() - 10 - width - pos.x, pos.y);
	const Vec2f br = Vec2f(getScreenWidth() - 10 - pos.x, tl.y + height);

	CControls@ controls = getControls();
	const Vec2f mousePos = controls.getMouseScreenPos();

	const bool hover = (mousePos.x > tl.x && mousePos.x < br.x && mousePos.y > tl.y && mousePos.y < br.y);
	if (hover)
	{
		if (controls.mousePressed1)
		{
			GUI::DrawButtonPressed(tl, br);
			if (!mouseWasPressed1 && text == "spec") {
				//Sound::Play("option");
				//Sound::Play("achievement");

				CRules@ rules = getRules();
				CBitStream params;
				params.write_string(username);
				rules.SendCommand(rules.getCommandID("put to spec"), params);

				mouseWasPressed1 = true;
			}
			else if (!mouseWasPressed1 && text == "blue")
			{
				//Sound::Play("option");
				//Sound::Play("achievement");
				CRules@ rules = getRules();
				CBitStream params;
				params.write_string(username);
				rules.SendCommand(rules.getCommandID("put to blue"), params);

				mouseWasPressed1 = true;
			}
			else if (!mouseWasPressed1 && text == "red")
			{
				//Sound::Play("option");
				//Sound::Play("achievement");

				CRules@ rules = getRules();
				CBitStream params;
				params.write_string(username);
				rules.SendCommand(rules.getCommandID("put to red"), params);

				mouseWasPressed1 = true;
			}
		} else {
			GUI::DrawButtonHover(tl, br);
			mouseWasPressed1 = false;
		}
	}
	else
	{
		GUI::DrawButton(tl, br);
	}

	GUI::DrawTextCentered(text, Vec2f(tl.x + (width * 0.50f), tl.y + (height * 0.50f)), 0xffffffff);
}
