# Twitch Extension for [PotPlayer](http://potplayer.daum.net)
PotPlayer is a multimedia software player developed for the Microsoft Windows operating system.

PotPlayer plays Youtube videos quite native with title, description, subtitles and with the choice of quality.
In May 2018 developers released first stable version with extensions support (written in AngelScript).
So I wrote extensions for native playing Twitch streams, VODs and clips.

# Credentials

Upd: if you want use the Twitch Extension without your own account, just leave a `useOwnCredentials` field in `config.ini` with `0` value.

Since [11 May 2020](https://discuss.dev.twitch.tv/t/23916) Twitch begins to permanently require an authorization for all Twitch API endpoints. So I added an experimental own proxy endpoint to this extension.
If you do not trust proxy, you can enter your credentials to the `config.ini`.

#### How to fill `config.ini`:
- Login [dev.twitch.tv](https://dev.twitch.tv/).
- [Create a new app](https://dev.twitch.tv/dashboard/apps/create).
- [Register your own app](https://dev.twitch.tv/docs/authentication/#registration).
- Copy your client id and paste it to the `config.ini`.
- Copy your client secret and paste it to the `config.ini`.
- Launch PotPlayer and test it.

# Installation
- Just download this repository.
- Unzip it.
- Copy `Media` folder to `c:\Program Files\DAUM\PotPlayer\Extension\` or `{PotPlayer_Folder}\Extension\`.

# Twitch
## /Media/PlayParse/MediaPlayParse - Twitch.as
This extension lets you open all twitch links, like:
- https://twitch.tv/lirik
- https://www.twitch.tv/videos/267745128
- https://clips.twitch.tv/RudeViscousGiraffeAMPTropPunch

After opening link you will see something like this.

![image](https://user-images.githubusercontent.com/4051126/41672554-ddb5afa0-74c2-11e8-9f0b-244ba6e95fb5.png)
- Stream title is displayed in the player header.
- In description you can see "{Title} | {Game} | {Channel}".
- Video resolution can be changed in the quality menu in the right bottom corner.

The file `config.ini` adds a few display settings.
- `showBitrate=1` — shows bitrate in context menu (H). Valid values: 1 or 0.
- `showFPS=1` — shows fps in context menu (H). Valid values: 1 or 0.
- `gameInTitle=0` — shows game in title. Valid values: 1 or 0.
- `gameInContent=1` — shows game in content. Valid values: 1 or 0.
- `clientID=` — takes clientID for API calls to the Twitch. It is highly recommended to get your own clientID on the Twitch and insert it here. If the value is empty, the default value is taken. If you insert an invalid value, the extension will not work.
- `oauthToken=` — OAuth Token is needed when you want to watch "Subscriber-only" VODs and you are subscribed to this channel. Leave this field blank if you don't need this feature. Valid values: `oauth:fboyX2pnceTQJdUaLqNMFceBPUi9TS`. You can generate your own token from [OAuth Password Generator](https://twitchapps.com/tmi/).

## /Media/UrlList/MediaUrlList - Twitch.as
This extension lets you see in `File URL List` all online channels that you follow.
Unfortunately PotPlayer has no interface to login in Twitch yet.
So you need to put your username in `Media/UrlList/config.ini`.
After this open PotPlayer and press `Ctrl + U`, you will see following window.

![image](https://user-images.githubusercontent.com/4051126/41672965-0ed9f11c-74c4-11e8-8643-efe8622cca91.png)

