/*
	GoodGame media parse
*/	

//	string GetTitle() 									-> get title for UI
//	string GetVersion									-> get version for manage
//	string GetDesc()									-> get detail information
//	string GetLoginTitle()								-> get title for login dialog
//	string GetLoginDesc()								-> get desc for login dialog
//	string ServerCheck(string User, string Pass) 		-> server check
//	string ServerLogin(string User, string Pass) 		-> login
//	void ServerLogout() 								-> logout
// 	bool PlayitemCheck(const string &in)				-> check playitem
//	array<dictionary> PlayitemParse(const string &in)	-> parse playitem
// 	bool PlaylistCheck(const string &in)				-> check playlist
//	array<dictionary> PlaylistParse(const string &in)	-> parse playlist

string GetTitle()
{
	return "GoodGame";
}

string GetVersion()
{
	return "1";
}

string GetDesc()
{
	return "https://goodgame.ru/";
}

string YOUTUBE_MP_URL	="://www.youtube.com/";
string YOUTUBE_PL_URL	= "://www.youtube.com/playlist?";
string YOUTUBE_URL		= "://www.youtube.com/watch?";
string YOUTUBE_URL2		= "://www.youtube.com/v/";
string YOUTUBE_URL3		= "://www.youtube.com/embed/";
string YOUTUBE_URL4		= "://www.youtube.com/attribution_link?a=";
string YOUTU_BE_URL1	= "://youtu.be/";
string YOUTU_BE_URL2	= "://youtube.com/";
string YOUTU_BE_URL3	= "://m.youtube.com/";
string YOUTU_BE_URL4	= "://gaming.youtube.com/";
string VIMEO_URL		= "://vimeo.com/";

string MATCH_STREAM_MAP_START		= "\"url_encoded_fmt_stream_map\"";
string MATCH_STREAM_MAP_START2		= "url_encoded_fmt_stream_map=";
string MATCH_ADAPTIVE_FMTS_START	= "\"adaptive_fmts\"";
string MATCH_ADAPTIVE_FMTS_START2	= "adaptive_fmts=";
string MATCH_HLSVP_START			= "\"hlsvp\"";
string MATCH_HLSVP_START2			= "hlsvp=";
string MATCH_WIDTH_START			= "meta property=\"og:video:width\" content=\"";
string MATCH_JS_START				= "\"js\":";
string MATCH_DASHMPD_START			= "\"dashmpd\"";
string MATCH_DASHMPD_START2			= "dashmpd=";
string MATCH_END					= "\"";
string MATCH_END2					= "&";

bool Is60Frame(int iTag)
{
	return iTag >= 298 && iTag <= 299;
}

bool IsHdr(int iTag)
{
	return iTag == 334 || iTag == 335 || iTag == 336 || iTag == 337;
}

bool IsTag3D(int iTag)
{
	return (iTag >= 82 && iTag <= 85) || (iTag >= 100 && iTag <= 102);
}

enum ytype
{
	y_unknown,
	y_mp4,
	y_webm,
	y_flv,
	y_3gp,
	y_3d_mp4,
	y_3d_webm,
	y_apple_live,
	y_dash_mp4_video,
	y_dash_mp4_audio,
	y_webm_video,
	y_webm_audio,
};

class YOUTUBE_PROFILES
{
	int iTag;
	ytype type;
	int quality;
	string ext;
	
	YOUTUBE_PROFILES(int _iTag, ytype _type, int _quality, string _ext)
	{
		iTag = _iTag;
		type = _type;
		quality = _quality;
		ext = _ext;
	}
	YOUTUBE_PROFILES()
	{
	}
};

array<YOUTUBE_PROFILES> youtubeProfiles = 
{
	YOUTUBE_PROFILES(22, y_mp4, 720, "mp4"),
	YOUTUBE_PROFILES(37, y_mp4, 1080, "mp4"),
	YOUTUBE_PROFILES(38, y_mp4, 3072, "mp4"),
	YOUTUBE_PROFILES(18, y_mp4, 360, "mp4"),

	YOUTUBE_PROFILES(45, y_webm, 720, "webm"),
	YOUTUBE_PROFILES(46, y_webm, 1080, "webm"),
	YOUTUBE_PROFILES(44, y_webm, 480, "webm"),
	YOUTUBE_PROFILES(43, y_webm, 360, "webm"),

	YOUTUBE_PROFILES(120, y_flv, 720, "flv"),
	YOUTUBE_PROFILES(35, y_flv, 480, "flv"),
	YOUTUBE_PROFILES(34, y_flv, 360, "flv"),
	YOUTUBE_PROFILES(6, y_flv, 270, "flv"),
	YOUTUBE_PROFILES(5, y_flv, 240, "flv"),

	YOUTUBE_PROFILES(36, y_3gp, 240, "3gp"),
	YOUTUBE_PROFILES(13, y_3gp, 144, "3gp"),
	YOUTUBE_PROFILES(17, y_3gp, 144, "3gp"),
};

array<YOUTUBE_PROFILES> youtubeProfilesExt =
{
	YOUTUBE_PROFILES(84, y_3d_mp4, 720, "mp4"),
	YOUTUBE_PROFILES(85, y_3d_mp4, 520, "mp4"),
	YOUTUBE_PROFILES(83, y_3d_mp4, 480, "mp4"),
	YOUTUBE_PROFILES(82, y_3d_mp4, 360, "mp4"),

	YOUTUBE_PROFILES(102, y_3d_webm, 720, "webm"),
	YOUTUBE_PROFILES(100, y_3d_webm, 360, "webm"),
	YOUTUBE_PROFILES(101, y_3d_webm, 360, "webm"),

	YOUTUBE_PROFILES(267, y_3d_mp4,  2160, "mp4"),
	YOUTUBE_PROFILES(265, y_3d_mp4,  1440, "mp4"),
	YOUTUBE_PROFILES(301, y_3d_mp4, 1080, "mp4"),
	YOUTUBE_PROFILES(300, y_3d_mp4,  720, "mp4"),
	YOUTUBE_PROFILES(96, y_3d_mp4, 1080, "mp4"),
	YOUTUBE_PROFILES(95, y_3d_mp4,  720, "mp4"),
	YOUTUBE_PROFILES(94, y_3d_mp4,  480, "mp4"),
	YOUTUBE_PROFILES(93, y_3d_mp4,  360, "mp4"),
	YOUTUBE_PROFILES(92, y_3d_mp4,  240, "mp4"),
	
	YOUTUBE_PROFILES(266, y_dash_mp4_video, 2160, "mp4"),
	YOUTUBE_PROFILES(138, y_dash_mp4_video, 2160, "mp4"), // 8K도 이걸로 될 수 있다.. ㄷㄷ
	YOUTUBE_PROFILES(264, y_dash_mp4_video, 1440, "mp4"),
	YOUTUBE_PROFILES(137, y_dash_mp4_video, 1080, "mp4"),
	YOUTUBE_PROFILES(136, y_dash_mp4_video, 720, "mp4"),
	YOUTUBE_PROFILES(135, y_dash_mp4_video, 480, "mp4"),
	YOUTUBE_PROFILES(134, y_dash_mp4_video, 360, "mp4"),
	YOUTUBE_PROFILES(133, y_dash_mp4_video, 240, "mp4"),
	YOUTUBE_PROFILES(160, y_dash_mp4_video, 144, "mp4"),
	YOUTUBE_PROFILES(139, y_dash_mp4_audio, 64, "m4a"),
	YOUTUBE_PROFILES(140, y_dash_mp4_audio, 128, "m4a"),
	YOUTUBE_PROFILES(141, y_dash_mp4_audio, 256, "m4a"),
	YOUTUBE_PROFILES(327, y_dash_mp4_audio, 320, "m4a"),

	YOUTUBE_PROFILES(272, y_webm_video, 2160, "webm"),
	YOUTUBE_PROFILES(271, y_webm_video, 1440, "webm"),
	YOUTUBE_PROFILES(248, y_webm_video, 1080, "webm"),
	YOUTUBE_PROFILES(247, y_webm_video, 720, "webm"),
	YOUTUBE_PROFILES(244, y_webm_video, 480, "webm"),
	YOUTUBE_PROFILES(243, y_webm_video, 360, "webm"),
	YOUTUBE_PROFILES(242, y_webm_video, 240, "webm"),
	YOUTUBE_PROFILES(278, y_webm_video, 144, "webm"),

	YOUTUBE_PROFILES(171, y_webm_audio, 128, "webm"),
	YOUTUBE_PROFILES(172, y_webm_audio, 192, "webm"),
	YOUTUBE_PROFILES(338, y_webm_audio, 256, "webm"),
	YOUTUBE_PROFILES(339, y_webm_audio, 320, "webm"),

	YOUTUBE_PROFILES(249, y_webm_audio, 48,  "webm"), // opus
	YOUTUBE_PROFILES(250, y_webm_audio, 64, "webm"), // opus
	YOUTUBE_PROFILES(251, y_webm_audio, 256, "webm"), // opus
	YOUTUBE_PROFILES(338, y_webm_audio, 128, "webm"), // opus
	
	YOUTUBE_PROFILES(313, y_webm_video, 2160, "webm"),
	YOUTUBE_PROFILES(314, y_webm_video, 2160, "webm"),
	YOUTUBE_PROFILES(302, y_webm_video, 720, "webm"),

	// 60p
	YOUTUBE_PROFILES(315, y_webm_video, 2160, "webm"),
	YOUTUBE_PROFILES(308, y_webm_video, 1440, "webm"),
	YOUTUBE_PROFILES(303, y_webm_video, 1080, "webm"),

	// 60P
	YOUTUBE_PROFILES(298, y_dash_mp4_video, 720, "mp4"),
	YOUTUBE_PROFILES(299, y_dash_mp4_video, 1080, "mp4"),
	YOUTUBE_PROFILES(304, y_dash_mp4_video, 1440, "mp4"),
};

YOUTUBE_PROFILES getProfile(int iTag, bool ext = false)
{
	for (int i = 0, len = youtubeProfiles.size(); i < len; i++)
	{
		if (iTag == youtubeProfiles[i].iTag) return youtubeProfiles[i];
	}

	if (ext)
	{
		for (int i = 0, len = youtubeProfilesExt.size(); i < len; i++)
		{
			if (iTag == youtubeProfilesExt[i].iTag) return youtubeProfilesExt[i];
		}		
	}

	YOUTUBE_PROFILES youtubeProfileEmpty(0, y_unknown, 0, "");
	return youtubeProfileEmpty;
}

class QualityListItem
{
	string url;
	string quality;
	string qualityDetail;
	string resolution;
	string bitrate;
	string format;
	int itag = 0;
	double fps = 0.0;
	int type3D = 0; // 1:sbs, 2:t&b
	bool is360 = false;

	dictionary toDictionary()
	{
		dictionary ret;
		
		ret["url"] = url;
		ret["quality"] = quality;
		ret["qualityDetail"] = qualityDetail;
		ret["resolution"] = resolution;
		ret["bitrate"] = bitrate;
		ret["format"] = format;
		ret["itag"] = itag;
		ret["fps"] = fps;
		ret["type3D"] = type3D;
		ret["is360"] = is360;
		return ret;
	}	
};

string GetEntry(string &pszBuff, string pszMatchStart, string pszMatchEnd)
{
	int Start = pszBuff.find(pszMatchStart);

	if (Start >= 0)
	{
		Start += pszMatchStart.size();
		int End = pszBuff.find(pszMatchEnd, Start);
		if (End > Start) return pszBuff.substr(Start, End - Start);
	}

	return "";
}

string RepleaceYouTubeUrl(string url)
{
	if (url.find(YOUTU_BE_URL1) >= 0) url.replace(YOUTU_BE_URL1, YOUTUBE_MP_URL);
	if (url.find(YOUTU_BE_URL2) >= 0) url.replace(YOUTU_BE_URL2, YOUTUBE_MP_URL);
	if (url.find(YOUTU_BE_URL3) >= 0) url.replace(YOUTU_BE_URL3, YOUTUBE_MP_URL);
	if (url.find(YOUTU_BE_URL4) >= 0) url.replace(YOUTU_BE_URL4, YOUTUBE_MP_URL);
	return url;
}

string MakeYouTubeUrl(string url)
{
	if (url.find("watch?v=") < 0 && url.find("&v=") < 0)
	{
		url.replace("watch?", "watch?v=");
		if (url.find("watch?v=") < 0)
		{
			int p = url.rfind("/");
			
			if (p > 0) url.insert(p + 1, "watch?v=");
		}
	}
	return url;
}

enum youtubeFuncType {
	funcNONE = -1,
	funcDELETE,
	funcREVERSE,
	funcSWAP
};

void Delete(string &a, int b) {
	a.erase(0, b);
}

void Swap(string &a, int b) {
	uint8 c = a[0];

	b %= a.size();
	a[0] = a[b];
	a[b] = c;
};

void Reverse(string &a) {
	int len = a.size();

	for (int i = 0; i < len / 2; ++i)
	{
		uint8 c = a[i];
		
		a[i] = a[len - i - 1];
		a[len - i - 1] = c;
	}
}

string ReplaceCodecName(string name, string id)
{
	int s = name.find(id);

	if (s > 0)
	{
		int e = name.find(")", s);

		if (e < 0) e = name.find(",", s);
		if (e < 0) e = name.find("/", s);
		if (e < 0) e = name.size();
		s += id.size();
		name.erase(s, e - s);
	}
	return name;
}

string GetCodecName(string type)
{
	type.replace(",+", "/");
	type.replace(";+", " ");
	type.replace("video/", "");
	type.replace("audio/", "");
	type.replace(" codecs=", ", ");
	type.replace("\"", "");
	type.replace("x-flv", "flv");
	type = ReplaceCodecName(type, "avc");
	type = ReplaceCodecName(type, "mp4v");
	type = ReplaceCodecName(type, "mp4a");
	
	return type;
}

 bool PlayerYouTubeCheck(string url)
{
	url.MakeLower();
	url.replace("#", "!");
	HostPrintUTF8(url);
	if (url.find("://goodgame.ru") >= 0) {
		return true;
	}

	// if (url.find(YOUTUBE_MP_URL) >= 0 && (url.find("watch?") < 0 || url.find("playlist?") >= 0 || url.find("&list=") >= 0))
	// {
	// 	if (url.find(YOUTUBE_URL) >= 0) return true;
	// 	if (url.find(YOUTUBE_URL2) >= 0) return true;
	// 	if (url.find(YOUTUBE_URL3) >= 0) return true;
	// 	if (url.find(YOUTUBE_URL4) >= 0) return true;
	// 	return false;
	// }
	// if (url.find(YOUTUBE_URL) >= 0 || url.find(YOUTU_BE_URL1) >= 0 || url.find(YOUTU_BE_URL2) >= 0 || url.find(YOUTU_BE_URL3) >= 0 || url.find(YOUTU_BE_URL4) >= 0)
	// {
	// 	return true;
	// }
	return false;
}

bool PlayitemCheck(const string &in path)
{
	HostPrintUTF8("TAKS!");
	if (path.find("://goodgame.ru") >= 0) {
		return true;
	}
	// if (PlayerYouTubeCheck(path))
	// {
	// 	string url = RepleaceYouTubeUrl(path);
	// 	url = MakeYouTubeUrl(url);

	// 	string videoId = HostRegExpParse(url, "v=([-a-zA-Z0-9_]+)");
	// 	if (videoId.empty()) videoId = HostRegExpParse(url, "video_ids=([-a-zA-Z0-9_]+)");
	// 	return !videoId.empty();
	// }
	return false;
}

string TrimFloatString(string str)
{
	str.TrimRight("0");
	str.TrimRight(".");
	return str;
}

string PlayitemParse(const string &in path, dictionary &MetaData, array<dictionary> &QualityList) {
	HostOpenConsole();
	HostPrintUTF8("HEH.");

	//Some vars for quality adding.
	array<string> qualities = {"", "_720", "_480", "_240"};
	array<string> qualitiesStr = {"Source", "720p", "480p", "240p"};
	string oldApi = "http://hls.goodgame.ru/hls/";
	string newApi = "https://cdnnow.goodgame.ru/hls/";
	bool isOldApi = false;

	string nickname = HostRegExpParse(path, "https://goodgame.ru/channel/([-a-zA-Z0-9_]+)");
	HostPrintUTF8(nickname);

	string statusApi = "https://goodgame.ru/api/getchannelstatus?fmt=json&id=" + nickname;
	string jsonStatus = HostUrlGetString(statusApi, "", "");

	string titleChannel;
	string channelId;
	string playerSrc;

	//Some tricks to remove useless root node.
	jsonStatus.replace("}}", "}");
	jsonStatus = jsonStatus.substr(jsonStatus.find(":{") + 1, 10000);
	// HostPrintUTF8(jsonStatus);

	JsonReader ChannelReader;
	JsonValue ChannelRoot;
	if (ChannelReader.parse(jsonStatus, ChannelRoot) && ChannelRoot.isObject()) {

		titleChannel = ChannelRoot["title"].asString();
		playerSrc = ChannelRoot["embed"].asString();
		channelId = HostRegExpParse(playerSrc, "player\\?([-a-zA-Z0-9_]+)");
		
		HostPrintUTF8(playerSrc);
		HostPrintUTF8(channelId);
	}

	HostPrintUTF8(titleChannel);
	// string m3u8Api = "http://hls.goodgame.ru/hls/" + channelId + ".m3u8";
	string m3u8Api = "https://cdnnow.goodgame.ru/hls/" + channelId + ".m3u8";
	HostPrintUTF8(m3u8Api);
	MetaData["title"] = titleChannel;
	MetaData["content"] = titleChannel;

		
	//Add 4 + 4 qualitites. 
	//New API is pretty fast, but for some reasons is laggy.
	//Old API is pretty slow, but works well. Dunno.
	if (@QualityList !is null) {
		for (int k = 0; k < 4; k++) {
			string currentApi = newApi;
			string currentQuality = qualities[k];
			QualityListItem qualityItem;
			qualityItem.itag = k;
			qualityItem.quality = qualitiesStr[k];
			qualityItem.qualityDetail = qualitiesStr[k];
			if (isOldApi) {
				currentApi = oldApi;
				qualityItem.itag = k + 4;
				qualityItem.qualityDetail += " old API";
			}
			qualityItem.url = currentApi + channelId + currentQuality + ".m3u8";
			QualityList.insertLast(qualityItem.toDictionary());
			if (k == 3 && !isOldApi) {
				k = -1;
				isOldApi = true;
			}
		}
	}

	return m3u8Api;
}

bool PlaylistCheck(const string &in path)
{
	string url = path;
	
	url.MakeLower();
	url = RepleaceYouTubeUrl(url);
	url.replace("https", "");
	url.replace("http", "");	
	
	if (url == YOUTUBE_MP_URL || (url.find(YOUTUBE_MP_URL) >= 0 && url.find("channel/") >= 0)) return false;
	if (url.find(YOUTUBE_PL_URL) >= 0 || (url.find(YOUTUBE_URL) >= 0 && url.find("&list=") >= 0)) return true;
	if (url.find(YOUTUBE_MP_URL) >= 0 && url.find("watch?") < 0)
	{
		int p = url.find(YOUTUBE_MP_URL);

		url.erase(p, YOUTUBE_MP_URL.size());
		if (url.find("/") >= 0 || url.find("?") >= 0 || url.find("&") >= 0) return true;
	}

	return false;
}

array<dictionary> PlayerYouTubePlaylistByAPI(string url)
{
	array<dictionary> ret;
	string pid = HostRegExpParse(url, "list=([-a-zA-Z0-9_]+)");
	
	if (!pid.empty())
	{
		string vid = HostRegExpParse(url, "v=([-a-zA-Z0-9_]+)");
		string nextToken;

		for (int i = 0; i < 200; i++)
		{
			string api = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=" + pid + "&maxResults=50";		
			
			if (!nextToken.empty())
			{
				api = api + "&pageToken=" + nextToken;
				nextToken = "";
			}
			string json = HostUrlGetStringGoogle(api);
			HostIncTimeOut(5000);
			if (json.empty()) break;
			else
			{
				JsonReader Reader;
				JsonValue Root;

				if (Reader.parse(json, Root) && Root.isObject())
				{
					JsonValue nextPageToken = Root["nextPageToken"];					
					if (nextPageToken.isString()) nextToken = nextPageToken.asString();

					JsonValue items = Root["items"];
					if (items.isArray())
					{
						for(int j = 0, len = items.size(); j < len; j++)
						{
							JsonValue item = items[j];

							if (item.isObject())
							{
								JsonValue snippet = item["snippet"];

								if (snippet.isObject())
								{
									JsonValue resourceId = snippet["resourceId"];

									if (resourceId.isObject())
									{
										JsonValue videoId = resourceId["videoId"];
										
										if (videoId.isString())
										{										
											dictionary item;
											bool IsDel = false;

											item["url"] = "http://www.youtube.com/watch?v=" + videoId.asString();

											JsonValue title = snippet["title"];
											if (title.isString())
											{
												string str = title.asString();
												
												item["title"] = str;
												IsDel = "Deleted video" == str;
											}

											JsonValue thumbnails = snippet["thumbnails"];
											if (thumbnails.isObject())
											{
												JsonValue medium = thumbnails["medium"];
												string thumbnail;
												
												if (medium.isObject())
												{
													JsonValue url = medium["url"];

													if (url.isString()) thumbnail = url.asString();
												}
												if (thumbnail.empty())
												{
													JsonValue def = thumbnails["default"];
													
													if (def.isObject())
													{
														JsonValue url = def["url"];

														if (url.isString()) thumbnail = url.asString();
													}
												}
												/*
												JsonValue high = thumbnails["high"];
												if (high.isObject())
												{
													JsonValue url = high["url"];

													if (url.isString()) thumbnail = url.asString();
												}*/
												if (!thumbnail.empty()) item["thumbnail"] = thumbnail;
											}
											else if (IsDel) continue;
											if (vid == videoId.asString()) item["current"] = "1";

											ret.insertLast(item);
										}
									}
								}
							}
						}
					}
				}
			}
			if (nextToken.empty()) break;
		}
	}	

	return ret;
}

string FixHtmlSymbols(string inStr)
{
	inStr.replace("&quot;", "\"");
	inStr.replace("&amp;", "&");
	inStr.replace("&#39;", "'");
	inStr.replace("&#039;", "'");
	inStr.replace("\\n", "\r\n");
	inStr.replace("\n", "\r\n");
	inStr.replace("\\", "");

	inStr.replace(" - YouTube", "");
	inStr.replace(" on Vimeo", "");

	return inStr;
}
