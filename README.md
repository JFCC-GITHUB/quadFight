# TetrisFight

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

## 本機開發
用 Godot 4.7 開啟專案資料夾，按 F5。

## 部署到 GitHub Pages（iOS 試玩）
1. 合併到 `main`（workflow 只在 main 觸發，也可在 Actions 頁手動 Run workflow）
2. Repo → Settings → Pages → Source 選 **GitHub Actions**
3. 網址：`https://<帳號>.github.io/tetrisFight/`
4. iOS Safari 開啟後「分享 → 加入主畫面」可全螢幕遊玩，排行榜存在瀏覽器儲存空間。

## 結構
- `scripts/game.gd` 遊戲核心（SRS 旋轉、7-bag、hold、ghost、DAS/ARR、鎖定延遲）
- `scripts/pieces.gd` 方塊與踢牆資料
- `scripts/scores.gd` 排行榜（autoload）
- `scripts/title.gd` / `leaderboard.gd` / `main.gd` 畫面與輸入設定
