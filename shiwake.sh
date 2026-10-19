#!/bin/bash
# IF_DIR内のファイルを、拡張子名のフォルダ(DATA_DIR/拡張子)へ移動するスクリプト

# このスクリプトがあるフォルダ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="$SCRIPT_DIR/shiwake.conf"

# 既定値(設定ファイルがない、または記載がない場合)
IF_DIR="dock"
DATA_DIR="storage"

# 設定ファイルから値を読み込む(コマンドは実行せず、値だけを取り出す)
if [[ -f "$CONF_FILE" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%$'\r'}"                          # Windows形式の改行対策
        [[ "$line" =~ ^[[:space:]]*# ]] && continue   # コメント行は無視
        if [[ "$line" =~ ^[[:space:]]*(IF_DIR|DATA_DIR)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            value="${value%"${value##*[![:space:]]}"}"   # 末尾の空白を除去
            value="${value%\"}"; value="${value#\"}"     # ダブルクォートを除去
            value="${value%\'}"; value="${value#\'}"     # シングルクォートを除去
            [[ -z "$value" ]] && continue                # 空なら既定値のまま
            case "$key" in
                IF_DIR)   IF_DIR="$value" ;;
                DATA_DIR) DATA_DIR="$value" ;;
            esac
        fi
    done < "$CONF_FILE"
else
    echo "設定ファイルが見つからないため既定値を使用します: $CONF_FILE"
fi

# 相対パスなら、スクリプトのあるフォルダを基準にする
[[ "$IF_DIR" != /* ]]   && IF_DIR="$SCRIPT_DIR/$IF_DIR"
[[ "$DATA_DIR" != /* ]] && DATA_DIR="$SCRIPT_DIR/$DATA_DIR"

# IF_DIRが存在しなければエラー終了
if [[ ! -d "$IF_DIR" ]]; then
    echo "IF_DIRが存在しません: $IF_DIR" >&2
    exit 1
fi

# DATA_DIRがなければ作成
mkdir -p "$DATA_DIR" || { echo "DATA_DIRを作成できません: $DATA_DIR" >&2; exit 1; }

# IF_DIR直下の「ファイルのみ」を処理(フォルダは対象外)
find "$IF_DIR" -mindepth 1 -maxdepth 1 -type f -print0 | while IFS= read -r -d '' file; do
    name="$(basename "$file")"

    # 拡張子の取得(最後のドットより後ろ)
    if [[ "$name" == *.* && "${name%.*}" != "" ]]; then
        ext="${name##*.}"
    else
        # 拡張子がないファイル、または「.gitignore」のような隠しファイルはスキップ
        echo "スキップ(拡張子なし): $name"
        continue
    fi

    dest="$DATA_DIR/$ext"

    # 移動先フォルダがなければ作成
    mkdir -p "$dest"

    # 同名ファイルが既に存在する場合は上書きしない
    if [[ -e "$dest/$name" ]]; then
        echo "スキップ(同名ファイルが存在): $name"
        continue
    fi

    mv -- "$file" "$dest/" && echo "移動: $name -> $dest/"
done
