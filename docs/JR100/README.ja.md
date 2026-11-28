# National JR-100 for MiSTer（日本語）

松下電器（ナショナル）JR-100（1981年）の [MiSTer FPGA](https://github.com/MiSTer-devel/Main_MiSTer/wiki) 用コアです。

*English version: [README.md](README.md)*

## 特徴

- MB8861H CPU（MC6800互換 + NIM/OIM/XIM/TMM/ADX拡張命令）。参照エミュレータ [pyjr100emu](https://github.com/zabaglione/pyjr100emu) との命令境界ロックステップでサイクル数まで検証済み
- R6522 VIA（タイマ、シフトレジスタ、PB7サウンド、キーボード行列走査）をサイクル単位で参照実装と照合
- 32×24文字表示（256×192モノクロ）。ユーザー定義文字は実機のVRAM共有参照（0xA0-0xFF）まで実装
- 実機準拠のビデオタイミング: ドットクロック7.15909MHz、水平15.980kHz／垂直62.4Hz（JR-100独自のNTSC規格外フォーマット）。MiSTerスケーラが処理
- 表示色選択（OSD）: White／Green（純正オプションのグリーンディスプレイTR-120MIC相当）／Amber／Cyan／Orange／Blue／Paper／Mint
- PS/2キーボード（9×5行列全キー）、ジョイスティック（`$CC02`、active-high）
- BEEP音声（出力帯域制御つき。VIA内部動作は帯域制御の影響を受けません）
- OSDからのPROGコンテナ（`.prg` v1/v2）と BASICテキスト（`.bas`）のロード（オートスタート対応）、マウントしたファイルへのBASICプログラム保存
- 仮想テープデッキ: マウントした `.cmt` テープに対してROMの本物の `SAVE`/`LOAD` コマンドが動作（実機同様のVIA経由600ボーFSK）
- 拡張RAM 16KiB（`4000-7FFF`、OSD選択・リセット時反映）

SuperStation One で動作確認済み（キーボード: ELECOM TK-FCM077PBK、コントローラ: Xbox One）。

## ROMについて

本リポジトリに**ROMは含まれません**。お手持ちの正規なJR-100 BASIC ROMを、8KiB生イメージ（先頭1KiBが文字ROM、`0400` 以降がBASIC）として次の場所へ配置してください:

```
/media/fat/games/JR100/boot.rom
```

PROGコンテナ形式（`jr100rom.prg`）の場合は一度だけ変換します:

```bash
python3 tools/prog2rom.py jr100rom.prg boot.rom
```

コア起動時に `boot.rom` が自動ロードされます（OSDの「Load BASIC ROM」から手動選択も可能）。ROMイメージは絶対にコミットしないでください（`./scripts/setup-hooks.sh` で混入ガードを有効化できます）。

## SuperStation OneのConsole Mode

SuperStation One FW 1.2とConsole Mode 1.1.1では、MGLを使って`Load Game`からJR-100コア、プログラム転送、オートスタートを連続実行できることを確認しています。
SS1では実際のゲームルートがUSBストレージ側になる場合があるため、通常のMiSTer手順と分けて[SS1 FW 1.2とConsole Modeの設定手順](docs/SS1_FW12_CONSOLE_MODE.md)にまとめています。
機械語のみのSTAR FIREと、BASICのみのプログラムをそれぞれ起動するMGL例も掲載しています。

## プログラムのロード

- `.prg`（PROG v1/v2コンテナ）: OSD →「Load PRG」。バイナリセクションは指定アドレスへ、BASICセクションは `0246` へロードされワークポインタも設定済み（そのまま `LIST`/`RUN` 可能）
- `.bas`（BASICテキスト）: OSD →「Load BAS」。各行を ASCII テキストのまま（大文字化、`\xx` 16進エスケープ対応）`0246` へロードし、ワークポインタも設定済み（そのまま `LIST`/`RUN` 可能）。オフライン変換用の `tools/bas2prg.py` も引き続き利用可能
- BASIC＋機械語のハイブリッド: `python3 tools/bas2prg.py game.bas game.prg --bin 1000:routine.bin`（`--bin ADDR:FILE` は複数指定可）で1つのPROG v2にまとめ、「Load PRG」でロード後 `USR($1000)` で呼び出せます
- オートスタート（OSDオプション・既定OFF）: 「Autostart loaded program」をONにすると、BASICロード後に `RUN`、コンテナにヒントがあれば `A=USR($hhhh)` を自動打鍵します。PROG形式自体にはエントリポイント情報がないため、v2コメント内の `USR=$hhhh` マーカーを規約として使います: `bas2prg.py --autostart 1000` で付与、既存の `.prg` には `python3 tools/prg_autostart.py game.prg game_auto.prg 300`（v1→v2変換も実施）。ヒントもBASICセクションもないファイルには何もしません

## プログラムの保存

カセットの `SAVE` コマンドの代わりに、OSDから現在のBASICプログラムをファイルへ保存できます。

1. 空のセーブファイルを一度作成: `python3 tools/make_save_file.py mywork.prg`（16KiB。512の倍数なら任意サイズ可）→ `games/JR100/` に配置
2. OSD →「Mount Save File」でマウント
3. 保存したいタイミングで OSD →「Save BASIC to file」。ファイルは通常のPROG v2コンテナになるので、「Load PRG」（やエミュレータ）でそのまま再ロードできます

## カセットテープ（本物のSAVE/LOADコマンド）

実機と同じVIA配線（出力=CB2、入力=CA1+CB1）の仮想テープデッキを搭載しており、ROMの `SAVE`/`LOAD`/`MSAVE`/`MLOAD`/`VERIFY` コマンドが実機同様の600ボーで動作します。

1. 空テープを一度作成: `python3 tools/make_tape.py mytape.cmt` → `games/JR100/` に配置 → OSD →「Mount Tape」
2. BASICで `SAVE` と打つだけで録音されます（デッキは常時録音待機。テープは毎回先頭から書き直し。リーダ音込みで小プログラム約20秒＝実機どおり）
3. ロードは `LOAD` と打ってから OSD →「Tape Play」。デッキがリーダとFSK波形を再生成し、復調はROM自身が行います

`.cmt` ファイルはテープ上のバイト列そのもの（33バイトヘッダ+データ+チェックサム）で、FSK変調とリーダはデッキが生成します。

## ビルド

正式ビルドは GitHub Actions（`.github/workflows/build-core.yml`、コンテナ内Quartus 17.0）です。同一手順のローカル実行:

```bash
CONTAINER_RUNTIME=docker tools/compile_rbf.sh JR100
```

（OCIランタイムなら何でも動作します。Apple SiliconではRosetta経由でツールは起動しますが実用外の速度のため、CIを推奨）

## 開発・検証

[Template_MiSTer](https://github.com/MiSTer-devel/Template_MiSTer) を基礎とし、`sys/` フレームワークは無改変です。互換性基準は pyjr100emu（同階層 `../jr100emu` にチェックアウト想定）。

- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) — 開発計画・環境・検証スイート
- [docs/TRACE_FORMAT.md](docs/TRACE_FORMAT.md) — ロックステップトレース形式
- [docs/BOOT_LOCKSTEP.md](docs/BOOT_LOCKSTEP.md) — ブート比較規約とM1判定結果
- [AGENTS.md](AGENTS.md) — 要件定義書

Verilatorシミュレーションで、CPUロックステップ・VIAサイクル単位ベクタ・READY到達ブート・フレーム描画・ジョイスティック/PRG/音声の受入試験を網羅しています（`tools/run_*` 参照）。

## ライセンス

GPL-2.0（[LICENSE](LICENSE)、MiSTerフレームワークに準拠）。本コア向けの新規HDLは GPL-2.0-or-later。MITライセンスの pyjr100emu / [jr100-emulator-v2](https://github.com/kemusiro/jr100-emulator-v2) 由来の移植部分は各ファイルヘッダに帰属を記載しています。
