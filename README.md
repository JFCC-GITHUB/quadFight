# QuadFight

Godot 4.7 單人俄羅斯方塊。起始畫面、分數、本機排行榜，支援鍵盤／手把／觸控。

## 操作
| | 鍵盤 | 手把 | 觸控 |
|---|---|---|---|
| 左右移動 | ← → / A D | 十字鍵／左搖桿 | `<` `>` |
| 軟降 | ↓ / S | 十字鍵下 | `v` |
| 旋轉 | ↑ X / Z | A / B | ROTATE |
| 硬降 | Space | 十字鍵上 / Y | DROP |
| 暫存 | C / Shift | X | HOLD |
| 暫停 | P / Esc | Start | 右上角 ⏸ |

## 選項（標題畫面或暫停選單 → OPTIONS）
- **COLORS**：方塊配色 4 種（Candy / Neon / Pastel / Colorblind）、背景 3 種（Nebula / Midnight / Sunset）
- **SOUND**：音效、音樂各自的開關與音量
- **CONTROLS**：觸控版型（Classic / Thumbs，後者多一顆逆時針旋轉）、移動按鈕放左手或右手、長按移動速度、落點預覽開關，附即時預覽
- 設定會存在瀏覽器儲存空間，下次開啟自動套用

## 美術素材
- `tools/gen_assets.py` 用 Python（Pillow + numpy）生成方塊材質、背景、Logo、按鈕圖示，輸出到 `assets/`。改顏色或形狀後重跑：`python3 tools/gen_assets.py`
- 字型：Russo One、Rajdhani（Google Fonts，SIL Open Font License，授權檔在 `assets/fonts/`）
- 介面配色與繪圖輔助集中在 `scripts/style.gd`

## 本機開發
用 Godot 4.7 開啟專案資料夾，按 F5。

## 部署到 GitHub Pages（iOS 試玩）
1. 合併到 `main`（workflow 只在 main 觸發，也可在 Actions 頁手動 Run workflow）
2. Repo → Settings → Pages → Source 選 **GitHub Actions**
3. 網址：`https://<帳號>.github.io/quadfight/`
4. iOS Safari 開啟後「分享 → 加入主畫面」可全螢幕遊玩，排行榜存在瀏覽器儲存空間。

## 結構
- `scripts/game.gd` 遊戲核心（SRS 旋轉、7-bag、hold、ghost、DAS/ARR、鎖定延遲）
- `scripts/pieces.gd` 方塊與踢牆資料
- `scripts/scores.gd` 排行榜（autoload）
- `scripts/title.gd` / `leaderboard.gd` / `main.gd` 畫面與輸入設定

## 授權
- 程式碼與自製美術：MIT License，見 `LICENSE`
- 第三方（Godot、字型等）：見 `THIRD_PARTY_NOTICES.md`
- 「Tetris」為其權利人的註冊商標；本專案為獨立作品，與其無關聯
