# [PotPlayer](http://potplayer.daum.net) Extentions
PotPlayer is a multimedia software player developed for the Microsoft Windows operating system.

PotPlayer plays Youtube videos quite native with title, description, subtitles and with the choice of quality.
In May 2018 developers released first stable version with extensions support (written in AngelScript).
So I wrote extensions for native playing Twitch streams, VODs and clips.

# Installation
- Just download this repository.
- Unzip it.
- Copy `Media` folder to `c:\Program Files\DAUM\PotPlayer\Extention\` or `{PotPlayer_Folder}\Extention\`.

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

## /Media/UrlList/MediaUrlList - Twitch.as
This extension lets you see in `File URL List` all online channels that you follow.
Unfortunately PotPlayer has no interfrace to login in Twitch yet.
So you need to put your username in `Media/UrlList/TwitchLogin.txt`.
After this open PotPlayer and press `Ctrl + U`, you will see following window.

![image](https://user-images.githubusercontent.com/4051126/41672965-0ed9f11c-74c4-11e8-8643-efe8622cca91.png)

# GoodGame.ru
GoodGame.ru is a russian live streaming video platform. So information below will be useless for non-russian users.

## /Media/PlayParse/MediaPlayParse - Goodgame.as
Это расширение позволяет проигрывать в плеере стримы с goodgame, например https://goodgame.ru/channel/miker.
Как и с твитчом, здесь также отображается в заголовке название стрима и можно выбрать качество.
Выбор качества реализован двумя типами: с новым API и с устаревшим API. К сожалению новый по каким-то причинам отрабатывает плохо.

## Media/PlayParse/MediaPlayParse - GoodGameVideo.as
Данное расширение позволяет проигрывать в плеере goodgame воды и клипы. 
Так как эта функция менее популярна, она выведена в отдельный файл.
Здесь уже выбора качества нету, так как он не предусмотрен самой площадкой.
