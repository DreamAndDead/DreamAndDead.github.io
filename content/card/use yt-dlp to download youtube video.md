---
created: 2024-05-17T22:13
draft: true
tags: 
- card
- tool
---

yt-dlp is a enhanced fork of youtube_dl

# One Line Usage

```bash
yt-dlp --proxy socks5://127.0.0.1:7890 --write-subs --sub-format vtt --sub-langs en -f [video id] -f [audio id] [VIDEO URL]
```

# list downloadable format

```
yt-dlp --proxy socks5://127.0.0.1:7890 -F [video-url]
```

```
ID  EXT   RESOLUTION FPS CH │   FILESIZE   TBR PROTO │ VCODEC          VBR ACODEC      ABR ASR MORE INFO
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────
233 mp4   audio only        │                  m3u8  │ audio only          unknown             Default
234 mp4   audio only        │                  m3u8  │ audio only          unknown             Default
599 m4a   audio only      2 │   32.24MiB   31k https │ audio only          mp4a.40.5   31k 22k ultralow, m4a_dash
600 webm  audio only      2 │   33.32MiB   32k https │ audio only          opus        32k 48k ultralow, webm_dash
..................................................................................................................
302 webm  1280x720    60    │  427.52MiB  408k https │ vp09.00.40.08  408k video only          720p60, webm_dash
312 mp4   1920x1080   60    │ ~  6.55GiB 6251k m3u8  │ avc1.64002A   6251k video only
299 mp4   1920x1080   60    │  628.99MiB  601k https │ avc1.64002A    601k video only          1080p60, mp4_dash
617 mp4   1920x1080   60    │ ~  5.09GiB 4864k m3u8  │ vp09.00.41.08 4864k video only
303 webm  1920x1080   60    │    1.12GiB 1096k https │ vp09.00.41.08 1096k video only          1080p60, webm_dash
```

# list subtitles

```
yt-dlp --proxy socks5://127.0.0.1:7890 --list-subs [video-url]
```

```
Language   Name                                Formats
en                                             vtt
ja                                             vtt
af-en      Afrikaans from English              vtt, ttml, srv3, srv2, srv1, json3
ak-en      Akan from English                   vtt, ttml, srv3, srv2, srv1, json3
sq-en      Albanian from English               vtt, ttml, srv3, srv2, srv1, json3
am-en      Amharic from English                vtt, ttml, srv3, srv2, srv1, json3
ar-en      Arabic from English                 vtt, ttml, srv3, srv2, srv1, json3
.................................................................................
.................................................................................
.................................................................................
.................................................................................
fy-ja      Western Frisian from Japanese       vtt, ttml, srv3, srv2, srv1, json3
xh-ja      Xhosa from Japanese                 vtt, ttml, srv3, srv2, srv1, json3
yi-ja      Yiddish from Japanese               vtt, ttml, srv3, srv2, srv1, json3
yo-ja      Yoruba from Japanese                vtt, ttml, srv3, srv2, srv1, json3
zu-ja      Zulu from Japanese                  vtt, ttml, srv3, srv2, srv1, json3

Language Name     Formats
en       English  vtt, ttml, srv3, srv2, srv1, json3
ja       Japanese vtt, ttml, srv3, srv2, srv1, json3
```
# download subtitle

```
yt-dlp --proxy socks5://127.0.0.1:7890 --write-subs --sub-format vtt --sub-langs en --skip-download [video-url]
```

# troubleshoot

## connection reset by remote

change proxy server in clash and download again

it will resume from the breakpoint

## no sound in video play

download audio separately, then merge with video


