# QuadFight v1.0.1 – 發行說明 🇹🇼

[English](RELEASE_NOTES.md) · **繁體中文**

_發行日期：2026-11-28 · 首次完整多平台發行_

> **授權變更：** 自 v1.0.1 起，QuadFight 採用 **PolyForm Noncommercial License 1.0.0**（任何非商業用途免費；商業使用需取得作者許可）。v1.0.0 以 MIT 發行，仍可依 MIT 使用。遊戲內容無變動。

QuadFight 是免費、非營利的落塊益智遊戲：電腦對手像真人一樣遊玩、12 位角色各有絕招，並支援本機雙人對戰。
v1.0.1 是第一個可下載的版本，涵蓋 **Windows、macOS、Linux 與網頁**。

## 重點
- **四個平台：** Windows 10/11（x64）、macOS 11 以上（Universal：Apple 晶片＋Intel）、Linux（x86-64）與網頁版（含 iOS Safari）。全新應用程式圖示。
- **VS CPU，Lv 1–20：** 電腦只靠「按鍵」操作，有輸入延遲、思考時間、按鍵連發、暫存（Lv 4 起）、預看下一塊（Lv 11 起）與擬真的失誤。
- **12 位角色各有絕招：** 以正確的消行組合累積能量發動（英雄與動物角色，像素風肖像與特效，每人一首主題曲）。
- **LADDER、TOURNAMENT、PRACTICE：** 天梯逐一挑戰對手；錦標賽連打 5 位對手，最後面對你自己的「黑暗版」魔王，有續關與打車獎勵關；也可無紀錄練習。
- **2 PLAYERS：** 同一台電腦（鍵盤／兩支手把）或平板（兩組觸控按鈕）的本機雙人對戰。
- **實力估計：** 依你的速度、堆疊與反應換算成 CPU 等級，於對戰與遊戲結束後顯示。
- **對戰統計：** 每場與錦標賽總結（送出／承受／抵銷的攻擊、最高連擊、四行消除、絕招、時間）。
- **各處皆可操作：** 鍵盤（可自訂，每個動作 3 組）、手把、觸控版型（Classic / Thumbs / 手把風格）；手機橫向版面與全螢幕按鈕。
- **選項：** 方塊配色 4 種、背景 3 種、音效風格 2 種、原創音樂風格 7 種、落點預覽與連發速度。
- **全部原創：** 美術、音樂與音效皆由儲存庫中的 Python 工具生成，不含第三方美術或音訊。

## 下載
| 平台 | 檔案 |
|---|---|
| Windows 10/11 x64 | `QuadFight-v1.0.1-windows-x64.zip` |
| macOS 11 以上（Universal） | `QuadFight-v1.0.1-macos-universal.zip` |
| Linux x86-64 | `QuadFight-v1.0.1-linux-x86_64.tar.gz` |
| 網頁版 | `QuadFight-v1.0.1-web.zip` · 線上：<https://jfcc-github.github.io/quadFight/> |
| 校驗碼 | `SHA256SUMS.txt` |

## 安裝未簽章的版本
- **Windows：** SmartScreen → **其他資訊** → **仍要執行**。
- **macOS：** 對 App 按右鍵 →「打開」；若顯示「已損毀」，執行 `xattr -dr com.apple.quarantine /Applications/QuadFight.app`。
- **Linux：** `tar xzf QuadFight-v1.0.1-linux-x86_64.tar.gz && ./QuadFight.x86_64`（必要時先 `chmod +x`）。
- 以 `sha256sum -c SHA256SUMS.txt` 驗證下載檔（macOS：`shasum -a 256 -c`）。

## 已知限制
- Windows 與 macOS 版本**未經程式碼簽章與公證**（沒有付費憑證），首次開啟時系統會顯示警告。
- 作者主要在 Linux 與瀏覽器（以 iOS Safari 為主要網頁目標）上建置與測試；Windows 與 macOS 版由 CI 產生，實機測試較少，若遇到問題請回報。
- 2 PLAYERS 只提供給電腦與平板（手機不提供）。
- Linux 需要支援 OpenGL 3.3 的顯示卡與驅動程式。尚無 Windows／Linux 的 ARM 版本。

## 法律
PolyForm Noncommercial License 1.0.0（見 `LICENSE`）；Godot 引擎與字型依各自授權（見 `THIRD_PARTY_NOTICES.zh-TW.md` 與 `licenses/`）。
不蒐集任何資料（見 `PRIVACY.zh-TW.md`）。「Tetris」為其權利人的商標；QuadFight 為獨立、免費、非營利的專案，與其無關聯。

回報問題：<https://github.com/JFCC-GITHUB/quadFight/issues>

---
Made in Taiwan 🇹🇼 · 台灣製作 🇹🇼
