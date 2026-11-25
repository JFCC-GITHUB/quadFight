# QuadFight

> **Free, non-commercial hobby project.** QuadFight is a personal project made for fun and for the author's own play.
> It is free: no ads, no in-app purchases, no donations, nothing is sold, and no money is made from it.
> It is an independent work and is not affiliated with, endorsed by, or sponsored by any other game or company.
>
> **免費、非營利的個人興趣專案。** QuadFight 是作者為了好玩、自己遊玩而做的作品：完全免費，沒有廣告、
> 沒有內購、沒有收款或贊助，也不從中獲利。本專案為獨立作品，與任何其他遊戲或公司沒有關聯，也未獲其背書或贊助。

Godot 4.7 單人落塊益智遊戲。起始畫面、分數、本機排行榜，支援鍵盤／手把／觸控。

## 操作
| | 鍵盤 | 手把 | 觸控 |
|---|---|---|---|
| 左右移動 | ← → / A D | 十字鍵／左搖桿 | `<` `>` |
| 軟降 | ↓ / S | 十字鍵下 | `v` |
| 旋轉 | ↑ X / Z | A / B | ROTATE |
| 硬降 | Space | 十字鍵上 / Y | DROP |
| 暫存 | C / Shift | X | HOLD |
| 暫停 | P / Esc | Start | 右上角 ⏸ |

## 遊戲模式
- **PLAY**：單人無盡模式，有排行榜
- **VS CPU**：與電腦對戰（Lv 1–20，電腦像人一樣有延遲、思考和失誤），先被堆到頂的人輸；12 位角色各有絕招，可打天梯或錦標賽
  - 電腦等級 = 反應速度、移動速度、失誤率（Lv1 約 28% 的方塊會放錯、動作慢；Lv10 幾乎不失誤、約人類高手的速度）
  - 消行會攻擊對手：一次消 1 行約掉 1–2 格、2 行 3–4 格、3 行 5–7 格、4 行 8–10 格（連續消行每多一次再 +1，最多 10 格），灰色方格會隨機落在對手的各欄位
  - 你消行時，會先抵銷你自己還沒落下的待受攻擊方格，剩下的才送給對手
  - 待落下的方格會顯示在「INCOMING」與棋盤左側的紅色警示條；對手下次落地沒有消行時才會掉下來
  - 每個等級會記錄你的勝敗

## 選項（標題畫面或暫停選單 → OPTIONS）
- **COLORS**：方塊配色 4 種（Candy / Neon / Pastel / Colorblind）、背景 3 種（Nebula / Midnight / Sunset）
- **SOUND**：音效、音樂各自的開關與音量；音效風格 2 種（Arcade / Soft & Relaxed 柔和）；音樂風格 7 種（Super Robot 熱血機器人動畫風〔預設〕/ Chiptune / Synthwave / Chill / Lo-fi Cafe / Bossa Breeze / Music Box），按箭頭即可試聽
- **CONTROLS**：觸控版型（Classic / Thumbs，後者多一顆逆時針旋轉）、移動按鈕放左手或右手、長按移動速度、落點預覽開關，附即時預覽
- 設定會存在瀏覽器儲存空間，下次開啟自動套用

## 美術素材
- `tools/gen_assets.py` 用 Python（Pillow + numpy）生成方塊材質、背景、Logo、按鈕圖示，輸出到 `assets/`。改顏色或形狀後重跑：`python3 tools/gen_assets.py`
- 字型：Russo One、Rajdhani（Google Fonts，SIL Open Font License，授權檔在 `assets/fonts/`）
- 介面配色與繪圖輔助集中在 `scripts/style.gd`

## 音樂
音樂全部是原創曲，由 `tools/gen_music.py` 用 Python（numpy + soundfile）合成並輸出成可無縫循環的 OGG 到 `assets/music/`。
想改曲或加新風格：編輯該腳本裡的樂譜／風格函式，執行 `python3 tools/gen_music.py`。
Super Robot 風格只是參考 70–80 年代日本超級機器人動畫主題曲的整體氛圍（熱血銅管、搖滾鼓組），沒有重現任何現有歌曲。

## 本機開發
用 Godot 4.7 開啟專案資料夾，按 F5。

## 部署到 GitHub Pages（iOS 試玩）
1. 合併到 `main`（workflow 只在 main 觸發，也可在 Actions 頁手動 Run workflow）
2. Repo → Settings → Pages → Source 選 **GitHub Actions**
3. 網址：`https://<帳號>.github.io/quadFight/`
4. iOS Safari 開啟後「分享 → 加入主畫面」可全螢幕遊玩，排行榜存在瀏覽器儲存空間。

## 結構
- `scripts/game.gd` 遊戲核心（SRS 旋轉、7-bag、hold、ghost、DAS/ARR、鎖定延遲）
- `scripts/pieces.gd` 方塊與踢牆資料
- `scripts/scores.gd` 排行榜（autoload）
- `scripts/title.gd` / `leaderboard.gd` / `main.gd` 畫面與輸入設定

## 授權
- 程式碼與自製美術：MIT License，見 `LICENSE`
- 第三方（Godot、字型等）：見 `THIRD_PARTY_NOTICES.md`
- 「Tetris」為其權利人的註冊商標；本專案為獨立作品，與其無關聯。本專案為免費的個人興趣專案，不營利
