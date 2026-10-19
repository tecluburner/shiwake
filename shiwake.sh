#!/bin/bash
# ifフォルダ内のファイルを、拡張子名のフォルダ(storage/拡張子)へ移動するスクリプト

# このスクリプトがあるフォルダへ移動
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IF_DIR="$SCRIPT_DIR/dock"
DATA_DIR="$SCRIPT_DIR/storage"

# ifフォルダ直下の「ファイルのみ」を処理(フォルダは対象外)
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

    mv -- "$file" "$dest/" && echo "移動: $name -> storage/$ext/"
done
