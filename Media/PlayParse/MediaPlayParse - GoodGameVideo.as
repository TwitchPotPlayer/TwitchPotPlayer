/*
	YouTube media parse
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
	return "YouTube";
}

string GetVersion()
{
	return "1";
}

string GetDesc()
{
	return "https://www.youtube.com/";
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

int GetYouTubeQuality(int iTag)
{
	for (int i = 0, len = youtubeProfiles.size(); i < len; i++)
	{
		if (iTag == youtubeProfiles[i].iTag) return youtubeProfiles[i].quality;
	}

	for (int i = 0, len = youtubeProfilesExt.size(); i < len; i++)
	{
		if (iTag == youtubeProfilesExt[i].iTag) return youtubeProfilesExt[i].quality;
	}

	return 0;
}

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

bool SelectBestProfile(int &itag_final, string &ext_final, int itag_current, YOUTUBE_PROFILES sets)
{
	YOUTUBE_PROFILES current = getProfile(itag_current);

	if (current.iTag <= 0 || current.type != sets.type || current.quality > sets.quality)
	{
		return false;
	}

	if (itag_final != 0)
	{
		YOUTUBE_PROFILES fin = getProfile(itag_final);

		if (current.quality < fin.quality) return false;
	}

	itag_final = current.iTag;
	ext_final = "." + current.ext;

	return true;
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

void AppendQualityList(array<dictionary> &QualityList, QualityListItem &item, string url)
{
	YOUTUBE_PROFILES pPro = getProfile(item.itag, true);

	if (pPro.iTag > 0)
	{
		bool Detail = false;

		if (Is60Frame(item.itag) && item.fps < 1) item.fps = 60.0;
		item.url = url;
		if (item.format.empty()) item.format = pPro.ext;
		if (item.quality.empty())
		{
			if (pPro.type == y_dash_mp4_audio || pPro.type == y_webm_audio)
			{
				string quality = formatInt(pPro.quality) + "K";
				if (item.bitrate.empty()) item.quality = quality;
				else item.quality = item.bitrate;
			}
			else
			{
				Detail = true;
				if (!item.bitrate.empty())
				{
					if (!item.resolution.empty())
					{
						int p = item.resolution.find("x");

						if (p > 0)
						{
							item.quality = item.resolution.substr(p + 1);
							item.quality += "P";
						}
					}
				}
			}
		}
		
		if (Detail && !item.bitrate.empty()) item.quality = item.bitrate + ", " + item.quality;

		item.qualityDetail = item.quality;
		if (Detail)
		{
			if (item.resolution.empty()) item.qualityDetail = formatInt(pPro.quality) + "P";
			else item.qualityDetail = item.resolution;
			if (!item.bitrate.empty()) item.qualityDetail = item.bitrate + ", " + item.qualityDetail;
		}
		QualityList.insertLast(item.toDictionary());
	}
	else
	{
		HostPrintUTF8("  *unknown itag: " + formatInt(item.itag) + "\n");
	}
}

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

string PlayerYouTubeSearchJS(string data)
{
	string find1 = "html5player.js";
	int s = data.find(find1);

	if (s >= 0)
	{
		int e = s + find1.size();
		bool found = false;

		while (s > 0)
		{
			if (data.substr(s, 1) == "\"")
			{
				s++;
				found = true;
				break;
			}
			s--;
		}
		if (found)
		{
			string ret = data.substr(s, e - s);

			return ret;
		}
	}

	s = data.find(MATCH_JS_START);
	if (s >= 0)
	{
		s += 6;
		int e = data.find(".js", s);

		if (e > s)
		{
			string ret = data.substr(s, e + 3 - s);

			ret.Trim();
			ret.Trim("\"");
			return ret;
		}
	}

	s = data.find("/jsbin/player-");
	if (s >= 0)
	{
		s += 6;
		int e = data.find(".js", s);

		while (s > 0)
		{
			if (data.substr(s, 1) == "\"") break;
			else s--;
		}
		if (e > s)
		{
			string ret = data.substr(s, e + 3 - s);

			ret.Trim();
			ret.Trim("\"");
			return ret;
		}
	}

	return "";
}

enum youtubeFuncType
{
	funcNONE = -1,
	funcDELETE,
	funcREVERSE,
	funcSWAP
};

void Delete(string &a, int b)
{
	a.erase(0, b);
}

void Swap(string &a, int b)
{
	uint8 c = a[0];

	b %= a.size();
	a[0] = a[b];
	a[b] = c;
};

void Reverse(string &a)
{
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

string GetFunction(string str)
{
	string ret = HostRegExpParse(str, "\"signature\",([a-zA-Z0-9]+)\\(");
	if (!ret.empty()) return ret;

	string r, sig = "\"signature\"";
	int p = 0;

	while (true)
	{
		int e = str.find(sig, p);

		if (e < 0) break;
		int s1 = str.find("(", e);
		int s2 = str.find(")", e);
		if (s1 > s2)
		{
			p = e + 10;
			continue;
		}
		p = e + sig.size() + 1;
		r = str.substr(p, s1 - p);
		break;
	}
	r.Trim(",");
	r.Trim();
	r.Trim(",");
	r.Trim();
	return r;
}

string SignatureDecode(string url, string signature, string append, string data, string js_data, array<youtubeFuncType> &JSFuncs, array<int> &JSFuncArgs)
{
	string FunctionName;
	
	if (JSFuncs.size() == 0 && !js_data.empty())
	{
		string funcName = GetFunction(js_data);

		if (!funcName.empty())
		{
			string funcRegExp = funcName + "=function\\(a\\)\\{([^\\n]+)\\};";
			string funcBody = HostRegExpParse(data, funcRegExp);

			if (funcBody.empty())
			{
				string varfunc = funcName + "=function(a){";

				funcBody = GetEntry(js_data, varfunc, "};");
			}
			if (!funcBody.empty())
			{
				string funcGroup;
				array<string> funcList;
				array<string> funcCodeList;

				array<string> code = funcBody.split(";");
				for (int i = 0, len = code.size(); i < len; i++)
				{
					string line = code[i];
					
					if (!line.empty())
					{
						if (line.find("split") >= 0 || line.find("return") >= 0) continue;
						funcList.insertLast(line);
						if (funcGroup.empty())
						{
							int k = line.find(".");

							if (k > 0) funcGroup = line.Left(k);
						}
					}
				}

				if (!funcGroup.empty())
				{
					string tmp = GetEntry(js_data, "var " + funcGroup + "={", "};");

					if (!tmp.empty())
					{
						tmp.replace("\n", "");
						funcCodeList = tmp.split("},");
					}
				}

				if (!funcList.empty() && !funcCodeList.empty())
				{
					funcGroup += ".";

					for (int j = 0, len = funcList.size(); j < len; j++)
					{
						string func = funcList[j];
						
						if (!func.empty())
						{
							int funcArg = 0;
							string funcArgs = GetEntry(func, "(", ")");
							array<string> args = funcArgs.split(",");
							
							if (args.size() >= 1)
							{
								string arg = args[args.size() - 1];

								funcArg = parseInt(arg);
							}

							string funcName = GetEntry(func, funcGroup, "(");
							funcName += ":function";

							youtubeFuncType funcType = youtubeFuncType::funcNONE;
							for (int k = 0, len = funcCodeList.size(); k < len; k++)
							{
								string funcCode = funcCodeList[k];
								
								if (funcCode.find(funcName) >= 0)
								{
									if (funcCode.find("splice") > 0) funcType = youtubeFuncType::funcDELETE;
									else if (funcCode.find("reverse") > 0) funcType = youtubeFuncType::funcREVERSE;
									else if (funcCode.find(".length]") > 0) funcType = youtubeFuncType::funcSWAP;
									break;
								}
							}
							if (funcType != youtubeFuncType::funcNONE)
							{
								JSFuncs.insertLast(funcType);
								JSFuncArgs.insertLast(funcArg);
							}
						}
					}
				}
			}
		}
	}

	if (!JSFuncs.empty() && JSFuncs.size() == JSFuncArgs.size())
	{
		for (int i = 0, len = JSFuncs.size(); i < len; i++)
		{
			youtubeFuncType func = JSFuncs[i];
			int arg = JSFuncArgs[i];

			switch (func)
			{
			case youtubeFuncType::funcDELETE:
				Delete(signature, arg);
				break;
			case youtubeFuncType::funcSWAP:
				Swap(signature, arg);
				break;
			case youtubeFuncType::funcREVERSE:
				Reverse(signature);
				break;
			}
		}
		url = url + append + signature;
	}
	
	return url;
}

 bool PlayerYouTubeCheck(string url)
{
	url.MakeLower();
	if (url.find(YOUTUBE_MP_URL) >= 0 && (url.find("watch?") < 0 || url.find("playlist?") >= 0 || url.find("&list=") >= 0))
	{
		if (url.find(YOUTUBE_URL) >= 0) return true;
		if (url.find(YOUTUBE_URL2) >= 0) return true;
		if (url.find(YOUTUBE_URL3) >= 0) return true;
		if (url.find(YOUTUBE_URL4) >= 0) return true;
		return false;
	}
	if (url.find(YOUTUBE_URL) >= 0 || url.find(YOUTU_BE_URL1) >= 0 || url.find(YOUTU_BE_URL2) >= 0 || url.find(YOUTU_BE_URL3) >= 0 || url.find(YOUTU_BE_URL4) >= 0)
	{
		return true;
	}
	return false;
}

bool PlayitemCheck(const string &in path)
{
	if (PlayerYouTubeCheck(path))
	{
		string url = RepleaceYouTubeUrl(path);
		url = MakeYouTubeUrl(url);

		string videoId = HostRegExpParse(url, "v=([-a-zA-Z0-9_]+)");
		if (videoId.empty()) videoId = HostRegExpParse(url, "video_ids=([-a-zA-Z0-9_]+)");
		return !videoId.empty();
	}
	return false;
}

string TrimFloatString(string str)
{
	str.TrimRight("0");
	str.TrimRight(".");
	return str;
}

string GetBitrateString(int64 val)
{
	string ret;

	if (val >= 1000 * 1000)
	{
		val = val / 1000;
		ret = formatFloat(val / 1000.0, "", 0, 1);
		ret = TrimFloatString(ret);
		ret += "M";
	}
	else if (val >= 1000)
	{
		ret = formatFloat(val / 1000.0, "", 0, 1);
		ret = TrimFloatString(ret);
		ret += "K";
	}
	else ret = formatInt(val);
	return ret;
}

string XMLAttrValue(XMLElement Element, string name)
{
	string ret;
	XMLAttribute Attr = Element.FindAttribute(name);

	if (Attr.isValid()) ret = Attr.asString();
	return ret;
}

string PlayitemParse(const string &in path, dictionary &MetaData, array<dictionary> &QualityList)
{
// HostOpenConsole();

	if (PlayitemCheck(path))
	{
		string fn = path;
		string tmp_fn = fn;
		array<youtubeFuncType> JSFuncs;
		array<int> JSFuncArgs;
		
		tmp_fn.MakeLower();
		if (tmp_fn.find(YOUTUBE_URL2) >= 0 || tmp_fn.find(YOUTUBE_URL3) >= 0)
		{
			int p = fn.rfind("/");

			if (p >= 0)
			{
				string id = fn.substr(p + 1);

				fn = "http" + YOUTUBE_URL + "v=" + id;
			}
		}

		int iYoutubeTag = 22;
		YOUTUBE_PROFILES youtubeSets = getProfile(iYoutubeTag);
		if (youtubeSets.iTag == 0) youtubeSets = getProfile(22);		

		string linkWeb = RepleaceYouTubeUrl(fn);
		linkWeb = MakeYouTubeUrl(linkWeb);

		string videoId = HostRegExpParse(linkWeb, "v=([-a-zA-Z0-9_]+)");
		if (videoId.empty()) videoId = HostRegExpParse(linkWeb, "video_ids=([-a-zA-Z0-9_]+)");
		linkWeb.replace("http://", "https://");
		
		if (@MetaData !is null) MetaData["vid"] = videoId;
		
		string linkApi = "https://www.youtube.com/get_video_info?video_id=" + videoId + "&eurl=https://youtube.googleapis.com/v/" + videoId; // info, embedded, detailpage, vevo
		string WebData, ApiData;
		string js_data;
		
		WebData = HostUrlGetString(linkWeb, "Googlebot", "", "", true);
		
		// Load js
		if (js_data.empty() && (@QualityList !is null) && !WebData.empty())
		{
			string jsUrl = PlayerYouTubeSearchJS(WebData);

			jsUrl.replace("\\/", "/");
			if (!jsUrl.empty())
			{
				if (jsUrl.find("//") == 0)
				{
					int p = fn.find("//");

					if (p > 0) jsUrl = fn.substr(0, p) + jsUrl;
				}
				if (jsUrl.find("://") < 0) jsUrl = "https://s.ytimg.com" + jsUrl;
			}
			if (jsUrl.empty()) jsUrl = "https://s.ytimg.com/yts/jsbin/player-ko_KR-vflHE7FfV/base.js";

			js_data = HostUrlGetString(jsUrl, "Googlebot", "", "", true);
			if (!js_data.empty() && !linkApi.empty())
			{
				string sts = HostRegExpParse(js_data, "\"sts\"\\s*:\\s*(\\d+)");

				if (sts.empty())
				{
					int p = 0;

					while (true)
					{
						p = js_data.find(",sts:", p);
						if (p > 0)
						{
							string str = js_data.substr(p + 5);
							int s = parseInt(str);

							if (s > 0)
							{
								sts = formatInt(s);
								break;
							}
							p += 5;
						}
						else break;
					}
				}
				if (sts.empty())
				{
					int p = 0;

					while (true)
					{
						p = js_data.find("sts:", p);
						if (p > 0)
						{
							string str = js_data.substr(p + 4);
							int s = parseInt(str);

							if (s > 0)
							{
								sts = formatInt(s);
								break;
							}
							p += 4;
						}
						else break;
					}
				}
				if (!sts.empty()) linkApi = linkApi + "&sts=" + sts;
			}
		}
		
		ApiData = HostUrlGetString(linkApi, "Googlebot", "", "", true);
		
		for (int z = 0; z < 2; z++)
		{
			string strData;
			bool isAPI = false;
			
			if (!ApiData.empty())
			{
				strData = ApiData;
				isAPI = true;
				ApiData = "";
			}
			else strData = WebData;
			if (strData.empty()) break;

			int stream_map_start = -1;
			int stream_map_len = 0;

			int adaptive_fmts_start = -1;
			int adaptive_fmts_len = 0;

			int hlsvp_start = -1;
			int hlsvp_len = 0;

			int dashmpd_start = -1;
			int dashmpd_len = 0;
			string DashMPD;
			
			if (isAPI)
			{
				// url_encoded_fmt_stream_map
				if (stream_map_start <= 0 && (stream_map_start = strData.find(MATCH_STREAM_MAP_START2)) >= 0)
				{
					stream_map_start += MATCH_STREAM_MAP_START2.size();
					stream_map_len = strData.find(MATCH_END2, stream_map_start + 10);
					if (stream_map_len > 0) stream_map_len += 10;
					else stream_map_len = strData.size();
					stream_map_len -= stream_map_start;
				}

				// adaptive_fmts
				if (adaptive_fmts_start <= 0 && (adaptive_fmts_start = strData.find(MATCH_ADAPTIVE_FMTS_START2)) >= 0)
				{
					adaptive_fmts_start += MATCH_ADAPTIVE_FMTS_START2.size();
					adaptive_fmts_len = strData.find(MATCH_END2, adaptive_fmts_start + 10);
					if (adaptive_fmts_len > 0) adaptive_fmts_len += 10;
					else adaptive_fmts_len = strData.size();
					adaptive_fmts_len -= adaptive_fmts_start;
				}

				// dash mpd
				if (dashmpd_start <= 0 && (dashmpd_start = strData.find(MATCH_DASHMPD_START2)) >= 0)
				{
					dashmpd_start += MATCH_DASHMPD_START2.size();
					dashmpd_len = strData.find(MATCH_END2, dashmpd_start);
					if (dashmpd_len < 0) dashmpd_len = strData.size();
					dashmpd_len -= dashmpd_start;
				}

				// "hlspv" - live streaming
				if (hlsvp_start <= 0 && (hlsvp_start = strData.find(MATCH_HLSVP_START2)) >= 0)
				{
					hlsvp_start += MATCH_HLSVP_START2.size();
					hlsvp_len = strData.find(MATCH_END2, hlsvp_start);
					if (hlsvp_len < 0) hlsvp_len = strData.size();
					hlsvp_len -= hlsvp_start;
				}
			}
			else
			{
				// url_encoded_fmt_stream_map
				if (stream_map_start <= 0 && (stream_map_start = strData.find(MATCH_STREAM_MAP_START)) >= 0)
				{
					stream_map_start += MATCH_STREAM_MAP_START.size() + 2;
					stream_map_len = strData.find(MATCH_END, stream_map_start + 10);
					if (stream_map_len > 0) stream_map_len += 10;
					else stream_map_len = strData.size();
					stream_map_len -= stream_map_start;
				}

				// adaptive_fmts
				if (adaptive_fmts_start <= 0 && (adaptive_fmts_start = strData.find(MATCH_ADAPTIVE_FMTS_START)) >= 0)
				{
					adaptive_fmts_start += MATCH_ADAPTIVE_FMTS_START.size() + 2;
					adaptive_fmts_len = strData.find(MATCH_END, adaptive_fmts_start + 10);
					if (adaptive_fmts_len > 0) adaptive_fmts_len += 10;
					else adaptive_fmts_len = strData.size();
					adaptive_fmts_len -= adaptive_fmts_start;
				}

				// dash mpd
				if (dashmpd_start <= 0 && (dashmpd_start = strData.find(MATCH_DASHMPD_START)) >= 0)
				{
					if (!ApiData.empty()) // web에서 dash mpd는 동작이 않된다.. ㄷㄷㄷ
					{
						int start = ApiData.find(MATCH_DASHMPD_START2);
						
						if (start > 0)
						{
							start += MATCH_DASHMPD_START2.size();
							int len = ApiData.find(MATCH_END2, start);

							if (len > start) DashMPD = ApiData.substr(start, len - start);
						}
					}
					if (DashMPD.empty())
					{
						dashmpd_start += MATCH_DASHMPD_START.size() + 2;
						dashmpd_len = strData.find(MATCH_END, dashmpd_start + 10);
						if (dashmpd_len > 0) dashmpd_len--;
						dashmpd_len -= dashmpd_start;
					}
				}

				// "hlspv" - live streaming
				if (hlsvp_start <= 0 && (hlsvp_start = strData.find(MATCH_HLSVP_START)) >= 0)
				{
					hlsvp_start += MATCH_HLSVP_START.size() + 2;
				}
				if (hlsvp_start > 0 && hlsvp_len <= 0)
				{
					hlsvp_len = strData.find(MATCH_END, hlsvp_start + 10);
					if (hlsvp_len > 0) hlsvp_len += 10;
					hlsvp_len -= hlsvp_start;
				}
			}

			if (stream_map_len < 0 && hlsvp_len <= 0)
			{
				if (isAPI && !WebData.empty())
				{
					ApiData = "";
					continue;
				}
				break;
			}
			
			if (@MetaData !is null)
			{
				string title, thumb;
				
				MetaData["webUrl"] = "http://www.youtube.com/watch?v=" + videoId;
				if (isAPI)
				{
					string search = "thumbnail_url=";
					int first = strData.find(search);

					if (first >= 0)
					{
						first += search.size();
						int next = strData.find("&", first);
						if (next > first)
						{
							thumb = strData.substr(first, next - first);
							thumb.Trim("\"");
							thumb = HostUrlDecode(thumb);
						}
					}

					search = "title=";
					first = strData.find(search);
					if (first >= 0)
					{
						first += search.size();
						int next = strData.find("&", first);
						if (next > first)
						{
							title = strData.substr(first, next - first);
							title = HostUrlDecode(title);
						}
					}

					search = "view_count=";
					first = strData.find(search);
					if (first >= 0)
					{
						first += search.size();
						int next = strData.find("&", first);
						if (next > first)
						{
							string view_count = strData.substr(first, next - first);

							MetaData["viewCount"] = HostUrlDecode(view_count);
						}
					}
				}
				else
				{
					string search1 = "<meta property=\"og:image\" content=";
					int first = strData.find(search1);

					if (first >= 0) first += search1.size();
					else
					{
						string search2 = "<meta name=\"twitter:image\" content=";
						first = strData.find(search2);
						if (first >= 0) first += search2.size();
					}
					if (first >= 0)
					{
						int next = strData.find(">");
						
						if (next >= 0)
						{
							thumb = strData.substr(first, next - first);
							thumb.Trim("\"");
						}
					}

					title = FixHtmlSymbols(GetEntry(strData, "<title>", "</title>"));
				}
				
				if (!thumb.empty()) MetaData["thumbnail"] = thumb;
				MetaData["title"] = title;

				int type3D = 0;
				string threed = GetEntry(strData, "threed_layout", ",");
				threed.Trim();
				threed.Trim("\"");
				threed.Trim(":");
				threed.Trim("\"");
				threed.Trim();
				if (threed == "1") type3D = 1; // SBS Half
				else if (threed == "2") type3D = 2; // SBS Full
				else if (threed == "3") type3D = 3; // T&B Half
				else if (threed == "4") type3D = 4; // T&B Full
				if (type3D > 0) MetaData["type3D"] = type3D;

				if (title.find("360°") >= 0 || title.find("360VR") >= 0) MetaData["is360"] = 1;
			}

			string final_url;
			string final_ext;

			if (hlsvp_len > 0)
			{
				string str = strData.substr(hlsvp_start, hlsvp_len);					

				string url = HostUrlDecode(HostUrlDecode(str));
				url.replace("\\/", "/");

				final_url = url;
				final_ext = "mp4";

//				if (@MetaData !is null) MetaData["chatUrl"] = "https://www.youtube.com/live_chat?v=" + videoId;
			}
			else
			{
				string FunctionName;

				if (DashMPD.empty() && adaptive_fmts_start <= 0 && dashmpd_len > 0) // dash 포멧 이라면.. ㄷㄷㄷ
				{
					DashMPD = strData.substr(dashmpd_start, dashmpd_len);
				}

				string str;
				if (stream_map_len > 0) str = strData.substr(stream_map_start, stream_map_len);
				if (adaptive_fmts_len > 0)
				{
					if (!str.empty()) str = str + ",";
					str += strData.substr(adaptive_fmts_start, adaptive_fmts_len);
				}
				if (isAPI) str = HostUrlDecode(str);
				else str.replace("\\u0026", "&");

				int final_itag = 0;

				array<string> lines = str.split(",");
				for (int i = 0, len = lines.size(); i < len; i++)
				{
					string line = lines[i];

					line.Trim(":");
					line.Trim("\"");
					line.Trim("\'");
					line.Trim(",");

					int itag = 0;
					string url, signature, sig;
					QualityListItem item;

					array<string> params = line.split("&");
					for (int j = 0, len = params.size(); j < len; j++)
					{
						string param = params[j];
						int k = param.find("=");

						if (k > 0)
						{
							string paramHeader = param.Left(k);
							string paramValue = param.substr(k + 1);
							
							// "quality", "fallback_host", "url", "itag", "type"
							if (paramHeader == "url")
							{
								url = HostUrlDecode(HostUrlDecode(paramValue));
								url.replace("http://", "https://");
							}
							else if (paramHeader == "itag")
							{
								itag = parseInt(paramValue);
								item.itag = itag;
							}
							else if (paramHeader == "sig")
							{
								sig = paramValue;
								sig.Trim();
								signature = "";
							}
							else if (paramHeader == "s")
							{
								signature = paramValue;
								signature.Trim();
								sig = "";
							}
							else if (paramHeader == "quality")
							{
								item.quality = paramValue;
							}
							else if (paramHeader == "size")
							{
								item.resolution = paramValue;
							}
							else if (paramHeader == "bitrate")
							{
								int64 bit = parseInt(paramValue);

								item.bitrate = GetBitrateString(bit);
							}
							else if (paramHeader == "projection_type")
							{
								int type = parseInt(paramValue);

								if (type == 2)
								{
									MetaData["type3D"] = 0;
									MetaData["is360"] = 1; // 360 VR
								}
								else if (type == 3)
								{
									MetaData["type3D"] = 3; 	// T&B Half
									MetaData["is360"] = 1; // 360 VR
								}
								else if (type == 4)
								{
								}
								int type3D;
								if (MetaData.get("type3D", type3D)) item.type3D = type3D;

								int is360;
								if (MetaData.get("is360", is360)) item.is360 = is360 == 1;
							}
							else if (paramHeader == "type")
							{
								item.format = GetCodecName(HostUrlDecode(paramValue));
							}
							else if (paramHeader == "fps")
							{
								double fps = parseFloat(paramValue);

								if (fps > 0) item.fps = fps;
							}								
						}
					}
					if (url.find("xtags=vproj=mesh") > 0) MetaData["is360"] = 1;

					if (!sig.empty()) url = url + "&signature=" + sig;
					else if (!signature.empty() && !js_data.empty())
					{
						url = SignatureDecode(url, signature, "&signature=", strData, js_data, JSFuncs, JSFuncArgs);
					}

					if (videoId == "jj9RZODDDZs" && url.find("clen=") < 0) continue; // 특수한 경우 ㄷㄷㄷ
					if (itag > 0)
					{
						if (@QualityList !is null) AppendQualityList(QualityList, item, url);
						if (SelectBestProfile(final_itag, final_ext, itag, youtubeSets)) final_url = url;
					}
				}

				if (!DashMPD.empty())
				{
					DashMPD = HostUrlDecode(HostUrlDecode(DashMPD));
					DashMPD.replace("\\/", "/");
					if (DashMPD.find("/s/") > 0)
					{
						string tmp = DashMPD;
						string signature = HostRegExpParse(tmp, "/s/([0-9A-Z]+.[0-9A-Z]+)");

						if (!signature.empty()) DashMPD = SignatureDecode(tmp, signature, "/signature/", strData, js_data, JSFuncs, JSFuncArgs);
					}
					string xml = HostUrlGetString(DashMPD);
					XMLDocument dxml;
					if (dxml.Parse(xml))
					{
						XMLElement Root = dxml.RootElement();

						if (Root.isValid() && Root.Name() == "MPD")
						{
							XMLElement Period = Root.FirstChildElement("Period");
							
							if (Period.isValid())
							{
								XMLElement AdaptationSet = Period.FirstChildElement("AdaptationSet");

								while (AdaptationSet.isValid())
								{
									string mimeType = XMLAttrValue(AdaptationSet, "mimeType");
									XMLElement Representation = AdaptationSet.FirstChildElement("Representation");

									while (Representation.isValid())
									{
										bool Skip = false;
										XMLElement SegmentList = Representation.FirstChildElement("SegmentList");

										if (SegmentList.isValid())
										{
											XMLElement Initialization = SegmentList.FirstChildElement("Initialization");
											
											if (Initialization.isValid())
											{
												string sourceURL = XMLAttrValue(Initialization, "sourceURL");

												if (sourceURL == "sq/0") Skip = true; // 이건 지원이 않된다..
											}
										}
										if (!Skip)
										{
											XMLElement BaseURL = Representation.FirstChildElement("BaseURL");

											if (BaseURL.isValid())
											{
												string url = BaseURL.asString();

												if (!url.empty())
												{
													QualityListItem item;
													string codecs = XMLAttrValue(Representation, "codecs");
													string width = XMLAttrValue(Representation, "width");
													string height = XMLAttrValue(Representation, "height");
													string frameRate = XMLAttrValue(Representation, "frameRate");
													string bandwidth = XMLAttrValue(Representation, "bandwidth");
													int itag = parseInt(XMLAttrValue(Representation, "id"));

													item.itag = itag;
													if (item.itag > 0)
													{
														string format = mimeType + "/" + codecs;

														item.format = GetCodecName(format);
														if (!width.empty() && !height.empty())
														{
															int w = parseInt(width);
															int h = parseInt(height);

															if (w > 0 && h > 0) item.resolution = width + "x" + height;
														}
														if (!frameRate.empty())
														{
															double fps = parseFloat(frameRate);

															if (fps > 0) item.fps = fps;
														}
														if (!bandwidth.empty())
														{
															int bit = parseInt(bandwidth);

															item.bitrate = GetBitrateString(bit);
														}
														if (@QualityList !is null) AppendQualityList(QualityList, item, url);
														if (SelectBestProfile(final_itag, final_ext, itag, youtubeSets)) final_url = url;
													}
												}
											}
										}
										Representation = Representation.NextSiblingElement();
									}
									AdaptationSet = AdaptationSet.NextSiblingElement();									
								}
							}
						}
					}
				}
			}
			
			if (!final_url.empty())
			{
				final_url.replace("http://", "https://");
				if (!videoId.empty() && (@MetaData !is null))
				{
					string api = "https://www.googleapis.com/youtube/v3/videos?id=" + videoId + "&part=snippet&fields=items/snippet/title,items/snippet/publishedAt,items/snippet/channelTitle,items/snippet/description";
					string json = HostUrlGetStringGoogle(api);
					JsonReader Reader;
					JsonValue Root;

					if (Reader.parse(json, Root) && Root.isObject())
					{
						JsonValue items = Root["items"];

						if (items.isArray())
						{
							JsonValue item = items[0];

							if (item.isObject())
							{
								JsonValue snippet = item["snippet"];

								if (snippet.isObject())
								{
									JsonValue title = snippet["title"];
									if (title.isString())
									{
										string sTitle = title.asString();

										if (!sTitle.empty()) MetaData["title"] = FixHtmlSymbols(sTitle);
									}

									JsonValue channelTitle = snippet["channelTitle"];
									if (channelTitle.isString())
									{
										string sAuthor = channelTitle.asString();

										if (!sAuthor.empty()) MetaData["author"] = sAuthor;
									}

									JsonValue description = snippet["description"];
									if (description.isString())
									{
										string sDesc = description.asString();

										if (!sDesc.empty()) MetaData["content"] = FixHtmlSymbols(sDesc);
									}
								}
							}
						}
					}

					if (@QualityList !is null)
					{
						// langCode: http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
						// http://video.google.com/timedtext?lang=en&v=R9Fu6Leb_aE&fmt=vtt
						// &fmt=srt		&fmt=vtt
						string api = "http://www.youtube.com/api/timedtext?v=" + videoId + "&expire=1&type=list";
						string xml = HostUrlGetString(api);
						
						XMLDocument dxml;
						if (dxml.Parse(xml))
						{
							XMLElement Root = dxml.RootElement();

							if (Root.isValid() && Root.Name() == "transcript_list")
							{
								XMLElement track = Root.FirstChildElement("track");
								array<dictionary> subtitle;

								while (track.isValid())
								{
									XMLAttribute lang_code = track.FindAttribute("lang_code");
									
									if (lang_code.isValid())
									{
										XMLAttribute name = track.FindAttribute("name");
										XMLAttribute lang_translated = track.FindAttribute("lang_translated");
										XMLAttribute lang_original = track.FindAttribute("lang_original");
										string s1 = name.isValid() ? name.Value() : "";
										string s2 = lang_translated.isValid() ? lang_translated.Value() : "";
										string s3 = lang_original.isValid() ? lang_original.Value() : "";
										string s4 = lang_code.isValid() ? lang_code.Value() : "";
										string s5 = "http://www.youtube.com/api/timedtext?v=" + videoId + "&lang=" + s4;
										dictionary item;

										item["name"] = s1;
										item["langTranslated"] = s2;
										item["langOriginal"] = s3;
										item["langCode"] = s4;
										item["url"] = s5;
										subtitle.insertLast(item);									
									}									
									track = track.NextSiblingElement();
								}
								if (subtitle.size() > 0) MetaData["subtitle"] = subtitle;
							}
						}
					}
				}

				if (@MetaData !is null) MetaData["fileExt"] = final_ext;
				return final_url;
			}
		}
	}	
	return "";
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

void ParserPlaylistItem(string html, int start, int len, array<dictionary> &pls)
{
	string block = html.substr(start, len);
	string szEnd = block;
	array<dictionary> match;
	string data_video_id;
	string data_video_username;
	string data_video_title;
	string data_thumbnail_url;
	
	while (HostRegExpParse(szEnd, "([a-z-]+)=\"([^\"]+)\"", match))
	{
		if (match.size() == 3)
		{
			string propHeader;
			string propValue;
			
			 match[1].get("first", propHeader);
			 match[2].get("first", propValue);
			 propHeader.Trim();
			 propValue.Trim();

			// data-video-id, data-video-clip-end, data-index, data-video-username, data-video-title, data-video-clip-start.
			if (propHeader == "data-video-id") data_video_id = propValue;
			else if (propHeader == "data-video-username") data_video_username = FixHtmlSymbols(propValue);
			else if (propHeader == "data-video-title" || propHeader == "data-title") data_video_title = FixHtmlSymbols(propValue);
			else if (propHeader == "data-thumbnail-url") data_thumbnail_url = propValue;
		}

		match[0].get("second", szEnd);
	}
	
	if (!data_video_id.empty())
	{
		dictionary item;
		
		item["url"] = "http://www.youtube.com/watch?v=" + data_video_id;
		item["title"] = data_video_title;
		if (data_thumbnail_url.empty())
		{
			int p = html.find("yt-thumb-clip", start);
			
			if (p >= 0)
			{
				int img = html.find(data_video_id, p);
				
				if (img > p)
				{
					while (img > p)
					{
						string ch = html.substr(img, 1);
						
						if (ch == "\"" || ch == "=") break;
						else img--;
					}

					int end = html.find(".jpg", img);
					if (end > img)
					{
						string thumb = html.substr(img, end + 4 - img);

						thumb.Trim();
						thumb.Trim("\"");
						thumb.Trim("=");
						if (thumb.find("://") < 0)
						{
							if (thumb.find("//") == 0) thumb = "http:" + thumb;
							else thumb = "http://" + thumb;
						}
						data_thumbnail_url = thumb;
					}
				}
			}
		}
		if (!data_thumbnail_url.empty()) item["thumbnail"] = data_thumbnail_url;
		
		if (block.find("currently-playing") >= 0) item["current"] = "1";
		pls.insertLast(item);
	}
}

string MATCH_PLAYLIST_ITEM_START	= "<li class=\"yt-uix-scroller-scroll-unit ";
string MATCH_PLAYLIST_ITEM_START2	= "<tr class=\"pl-video yt-uix-tile ";

array<dictionary> PlaylistParse(const string &in path)
{
	array<dictionary> ret;
	
	if (PlaylistCheck(path))
	{
		ret = PlayerYouTubePlaylistByAPI(path);
		if (ret.size() > 0) return ret;

		string html = HostUrlGetString(RepleaceYouTubeUrl(path));
		int p = html.find(MATCH_PLAYLIST_ITEM_START);		
		if (p >= 0)
		{
			while (p >= 0)
			{
				p += MATCH_PLAYLIST_ITEM_START.size();

				int end = html.find(">", p);
				if (end > p) ParserPlaylistItem(html, p, end - p, ret);
				
				p = html.find(MATCH_PLAYLIST_ITEM_START, p);
			}
		}
		else
		{
			p = html.find(MATCH_PLAYLIST_ITEM_START2);

			if (p >= 0)
			{
				while (p >= 0)
				{
					p += MATCH_PLAYLIST_ITEM_START2.size();

					int end = html.find(">", p);
					if (end > p) ParserPlaylistItem(html, p, end - p, ret);
					
					p = html.find(MATCH_PLAYLIST_ITEM_START2, p);
				}
			}
		}
	}
	
	return ret;
}
