# 第三方聲明 🇹🇼

[English](THIRD_PARTY_NOTICES.md) · **繁體中文**

QuadFight 自己的程式碼與生成的美術、音樂採用 PolyForm Noncommercial 1.0.0（非商業）授權（見 [`LICENSE`](LICENSE)、中文參考譯本 [`LICENSE.zh-TW.md`](LICENSE.zh-TW.md)）。
下列第三方元件依其各自的授權內含或使用。（若中英文有歧異，以英文版為準。）

## Godot 引擎（MIT）
本遊戲使用 Godot 引擎製作，且每個匯出版本（桌面版與網頁版）都內嵌該引擎，<https://godotengine.org>。

Copyright (c) 2014-present Godot Engine contributors.
Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.
採用 MIT 授權，授權全文見 [`licenses/godot/LICENSE.txt`](licenses/godot/LICENSE.txt)。

引擎本身另內含其他第三方函式庫（例如 FreeType、zlib、libogg/libvorbis、ENet、mbed TLS、ICU 等），各依其寬鬆授權。
它們的著作權聲明與授權全文原封不動收錄於 [`licenses/godot/COPYRIGHT.txt`](licenses/godot/COPYRIGHT.txt)（取自 Godot 4.7.2 原始碼）；
也可在編輯器的「說明 → 關於 Godot → 第三方授權」或 <https://godotengine.org/license/> 查閱。所有發行壓縮檔都附有 `licenses/` 資料夾。

## 字型（SIL Open Font License 1.1）
來自 Google Fonts 的未修改字型，連同授權文件放在 `assets/fonts/`：
- **Russo One** – Copyright (c) 2011-2012, Jovanny Lemonad (jovanny.ru)，保留字型名稱「Russo」。（`OFL-RussoOne.txt`）
- **Rajdhani** – Copyright (c) 2014, Indian Type Foundry (info@indiantypefoundry.com)。（`OFL-Rajdhani.txt`）

字型以未修改狀態內嵌於遊戲中，且不單獨販售。OFL 1.1：<https://openfontlicense.org>

## 音樂與音效
所有音樂皆為本專案原創，由 `tools/gen_music.py` 與 `tools/gen_themes.py` 作曲並合成
（風格：Super Robot、Chiptune、Synthwave、Chill、Lo-fi Cafe、Bossa Breeze、Music Box，以及每位角色各一首主題曲），並涵蓋於專案的授權。
Super Robot 風格是向 70–80 年代日本「超級機器人」動畫主題曲的整體氛圍致敬（熱血小調銅管、搖滾鼓組），沒有重現任何現有歌曲。
音效由程式碼生成（`scripts/sfx.gd`）。不含任何第三方音訊。

## 圖像
所有圖像（方塊、背景、Logo、圖示、角色肖像、特效、獎勵關的車、應用程式圖示）皆由 `tools/` 內的 Python 腳本生成，
涵蓋於專案的授權。不含任何第三方圖片、素材庫或下載的素材。

## 檢視紀錄（v1.0.1）
發行前已檢查：程式碼、介面文字與素材中是否有第三方商標或產品名稱（除下方聲明外沒有）；是否內含第三方音訊／圖像（沒有）；
字型授權檔是否齊全（齊全）。角色名稱與設計皆為原創。

## 商標與目的
QuadFight 是免費、非營利的個人興趣專案，為了好玩與作者自己遊玩而做。沒有廣告、沒有內購、沒有贊助，作者不從中獲利。

「Tetris」為其權利人的註冊商標。QuadFight 為獨立作品，與 The Tetris Company、Tetris Holding 或任何其他遊戲發行商
均無關聯，也未獲其背書或贊助。其他產品名稱（例如 Godot、Windows、macOS、Linux、iOS、Safari）屬各自權利人所有，僅用於說明相容性。

---
Made in Taiwan 🇹🇼 · 台灣製作 🇹🇼
