# HabitSwap

選んだアプリ（例: Instagram）を開くと制限画面が表示され、決めた習慣（深呼吸など）を実行してから使う、というiOSアプリ。

## しくみ

1. 初期設定でスクリーンタイムの利用を許可し、`FamilyActivityPicker` でアプリを選ぶ
2. アプリごとに置き換える習慣（種類・文言・所要時間）を決める
3. `ManagedSettingsStore` が選んだアプリにシールドを適用する
4. 対象アプリを開くと、`ShieldConfigurationExtension` が習慣の文言を載せた制限画面を表示する
5. 「習慣をはじめる」を押すと `ShieldActionExtension` が `.openParentalControlsApp` を返し、本アプリが開いて習慣画面に遷移する
6. 習慣を終えると対象アプリのシールドを一定時間だけ外し、`DeviceActivityMonitor` の `intervalDidEnd` で再適用する

## 前提と制約

- **deployment target は iOS 26.5**。制限画面から本アプリを開く `ShieldActionResponse.openParentalControlsApp` が `@available(iOS 26.5, *)` のため。
- 制限画面はAppleが用意した固定レイアウト。変更できるのは背景ブラー/背景色/アイコン/タイトル/サブタイトル/ボタンのラベルと色のみで、アニメーションや入力は置けない。習慣の本体UIは本アプリ側にある。
- **実機が必要**。スクリーンタイムのシールドはシミュレータでは動作しない。
- Family Controls entitlement が必要。開発用は capability を有効化すれば使えるが、TestFlight/App Store配布には Apple への申請・承認が必要で、**本体アプリと各App Extensionそれぞれについて申請する**。
- 解除時間の最小値は15分。`DeviceActivitySchedule` が15分未満の区間を受け付けないため。

## ビルド

Xcodeプロジェクトは [XcodeGen](https://github.com/yonaskolb/XcodeGen) で生成する。

```sh
brew install xcodegen
xcodegen generate
open HabitSwap.xcodeproj
```

拡張の `Info.plist`（`NSExtension` の extension point 指定を含む）は `project.yml` から生成されるため、リポジトリには置かない。

Signing はターゲットごとに自分のTeamを設定し、App Group `group.jp.tetris-solution.habitswap` と Family Controls capability を本体アプリと3つの拡張すべてに付与する。

## 構成

| パス | 役割 |
| --- | --- |
| `Shared/` | 設定モデル、App Group共有ストア、シールド制御（全ターゲットで共有） |
| `App/` | 初期設定ウィザード、ホーム、習慣実行画面 |
| `ShieldConfigurationExtension/` | 制限画面の見た目 |
| `ShieldActionExtension/` | 制限画面のボタン処理、本アプリ起動 |
| `DeviceActivityMonitorExtension/` | 解除時間の終了時にシールドを再適用 |
