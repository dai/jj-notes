#let emph-color = rgb("#177")
#let command-color = rgb("#911")

#set page(
  "us-letter",
  margin: 0.5in,
  columns: 2,
)

#set text(
  size: 9pt,
  font: "IBM Plex Sans"
)
#show heading.where(level: 1): set align(center)

#show raw: it => text(font: "IBM Plex Mono", weight: "semibold", fill: command-color, it)
#show emph: it => text(fill: emph-color, weight: "semibold", it)


= JJ リファレンス

// これはJujutsuバージョン管理システムのための_リファレンス_です。基本を理解した後、Jujutsuの詳細を学び、覚えるのに役立ちます。

== モデル

Jujutsuリポジトリは、ノードが_変更_と呼ばれるDAG（有向非巡回グラフ）です。各変更には以下が含まれます：

- リポジトリディレクトリ内のファイルシステムの状態。各変更がディレクトリとその中のすべてのファイルの完全なコピーを保存していると想像できますが、`jj`はこれよりも効率的です。
- ファイル_コンフリクト_。変更の一部のファイルには、さまざまなソースからのコンフリクトが含まれている場合があります。これらのコンフリクトは変更にローカルです（`git`とは異なり、`jj`の使用を妨げることはありません）。
- 1つ以上の_親_変更。ただし、親がいないルート変更があり、常に空のディレクトリを持っています。
- 変更のテキスト_説明_、すなわちコミットメッセージ。これは常に存在しますが、デフォルトでは空の文字列です。

DAGには追加の情報が添付されています：

- 正確に1つの変更が_作業中の変更_であり、`@`と書かれます。ドキュメントではこれを「作業コピーリビジョン」と呼びます（これは`git`の`HEAD`に相当します）。
- いくつかの_ブックマーク_があり、変更に一意の文字列ラベルを付けることができます（`git`とインターフェースする場合、これらのブックマークはブランチ名として機能します）。
- リポジトリは_リモートリポジトリ_（例：Github）にリンクされている場合があります。その場合、`push`および`fetch`時に、`jj`は各リモートブックマークの_最後に知られている位置_を記録します。これは`BOOKMARK@REMOTE`（例：`feat-ui@origin`）と書かれます。

ほとんどの`jj`コマンドは、何らかの方法でローカルリポジトリDAGを変更します。いくつかの一般的なルールは、変更に対する応答を予測するのに役立ちます：

- `@`を変更にポイントすると、リポジトリディレクトリがその変更のファイルに一致するように更新されます。
- `@`が指している変更を削除すると、`@`はその親から新しい空の変更に移動します。
- 変更にファイルの変更や説明がなく、`@`やブックマークによって参照されていない場合、それは静かに消え去ります。
- 変更は差分を表します。変更を移動すると、その差分を新しい親に適用しようとします。これによりマージコンフリクトが発生する可能性があります。
- 多くのコマンドはデフォルトで`@`に対して動作します。ほとんどすべてのコマンドは、`-r/--revision`引数を取って別の変更に対して動作することができます。
  //（Cheat Sheetに表示されている`@`を示すコマンドのうち、`jj bookmark move`と`jj restore`を除いて、すべてのコマンドは`-r`を使用して別の変更に適用できます。これらは代わりに`--from`および`--to`引数を取ります。）

=== ファイルコンフリクト

作業中の変更（`@`）に_ファイルコンフリクト_がある場合、それを解決するのは、ファイルを編集してコンフリクトマーカー（`<<<<<<<`、`=======`など）がなくなるようにするだけです。バイナリファイルの場合、ファイルを希望するバージョンに置き換えます。この目的のために`jj restore`が役立つかもしれません（`git`とは異なり、ファイルコンフリクトはあなたを妨げません）。

=== jj git push

`jj git push`は、ローカルリポジトリからリモートリポジトリに変更をコピーします。ローカル変更が最後にプッシュされてから変更された場合、それはリモートリポジトリで新しい変更になります（`git`での強制プッシュが古いコミットを新しいコミットに置き換えるのと同じように）。`main`に対してこれを誤って行わないようにするために、`jj git push`はプライマリブランチのすべてのプッシュされた変更を不変にします。まだ編集することはできますが、`--ignore-immutable`フラグを渡す必要があります。

すべてのローカルブックマークも同様にリモートリポジトリにコピーされます。ブックマークがローカルとリモートの両方に存在する場合、`jj`はその（ローカルに記録された）_最後に見た位置_がリモートリポジトリでの現在の位置と一致するかどうかを確認します。一致する場合、リモートリポジトリでのブックマークの位置が更新されます。一致しない場合、このコマンドは失敗し、最初に`jj git fetch`を実行するように指示します（これは、他の誰かが最後にプッシュしてからブックマークを更新したことを意味します）。

=== jj git fetch

`jj git fetch`は、リモートリポジトリからローカルリポジトリに変更をコピーします。リモートリポジトリで変更が行われた場合、それはローカルで新しい変更に変わります。ただし、ほとんどの場合、新しい変更をフェッチするだけです。

ローカルブックマークは、リモートリポジトリでの変更に一致するように進められます。ただし、リモートでの変更がローカルでの変更の子孫でない場合、`jj git fetch`はそのブックマークの2番目のコピーを作成します。これは_ブックマークコンフリクト_と呼ばれます。これは、ブックマーク名が一意であるという不変条件を破るためです（これは`git pull`がマージコンフリクトを生成するのと同様です）。この「ブックマークコンフリクト」を解決する方法はあなた次第です。利用可能なオプションのいくつか：

- 2つの変更をマージしたい場合、`jj new CHANGE-ID-1 CHANGE-ID-2`と言い、ファイルコンフリクトを解決し、次に`jj bookmark move BOOKMARK-NAME`でブックマークを更新します。
  （変更IDは`jj bookmark list BOOKMARK-NAME`を実行して取得できます。）
- 2つの変更のうち1つを破棄し、もう1つだけを使用したい場合、保持したい変更に対して`jj bookmark move BOOKMARK-NAME -r CHANGE-ID`と言います。
- 1つの変更を他の変更の後にリベースしたい場合、`jj rebase -b CHANGE-ID-2 -d CHANGE-ID-1`と言い、次に`jj bookmark move BOOKMARK-NAME -r CHANGE-ID-2`と言います。
  これにより、2番目の変更自体だけでなく、最初の変更から分岐した後のすべての変更がリベースされます。

== コマンド

=== グローバル設定コマンド

```
jj config set --user user.name  MY_NAME
jj config set --user user.email MY_EMAIL
jj config set --user ui.editor  MY_EDITOR

jj config edit --user  // 設定ファイルを手動で編集
```

`--user`の代わりに`--repo`を渡して、リポジトリ固有の設定を変更することができます。これが優先されます。

=== リポジトリコマンド

- `jj git init`、または`jj git clone URL [DESTINATION]`。gitバックのリポジトリを作成またはクローンします。
- `jj git init --colocate`。既存の`git`リポジトリを`jj`リポジトリとしても機能させます。

=== ローカルリポジトリの編集

添付のJJ Cheat Sheetは、`jj`リポジトリを編集するための最も一般的で基本的なコマンドを視覚的に説明しています。

また、他の`jj`コマンドの組み合わせと考えるのが最適な「エイリアス」コマンドもいくつかあります：

- `jj commit`。`jj describe; jj new`の省略形。
- `jj bookmark set BOOKMARK`。有効な場合、ブックマークを`create`または`move`します。

// ## コマンド
// 
// - `jj abandon REVISION`：REVISIONはデフォルトで`@`です。変更を削除します（グラフ内のノードを削除します）。その子は今やその親にポイントします。これによりコンフリクトが発生する可能性があります。`@`が`REVISION`と同じ場合、`@`を親の上に新しい空の変更にします。
// - `jj backout -r REVISION_r -d REVISION_d`：新しい変更（新しいノード）を作成します。その親は`REVISION_d`です。その変更は`REVISION_r`の変更の反対です。その説明は`Back out "THE DESCRIPTION OF REVISION_r"`です。
// - `jj bookmark create BOOKMARK -r REVISION`。REVISIONはデフォルトで`@`です。BOOKMARKという名前のブックマークでREVISIONをラベル付けします（リモートに伝播します）。
// - `jj bookmark delete BOOKMARK`。BOOKMARKという名前のブックマークラベルを削除します（リモートに伝播します）。
// - `jj bookmark list`。すべてのブックマークとそれらが指している変更をリストします。
// - `jj bookmark rename BOOKMARK_OLD BOOKMARK_NEW`。ブックマークの名前を変更します（質問：これは削除してから作成するのと同じですか？プッシュとどのように相互作用しますか？名前を変更してプッシュすると、リモートで古いブランチが削除されますか？）これはローカルのみです！
// - `jj bookmark move BOOKMARK --to REVISION`。ブックマークラベルをREVISIONに移動します。REVISIONはデフォルトで`@`です。
// - `jj describe`。エディタを開い��現在の変更の説明を設定します。または、`jj describe -m "COMMIT MESSAGE"`と言ってコマンドラインで指定します。
// - `jj show`。`@`の説明を印刷します。
// - `jj diff PATHS...`。このリビジョン（`@`）とその親（`@-`）の間のPATHSのファイルの差分を表示します。`--from REVISION`および`--to REVISION`を渡して、任意の変更間の差分を表示できます。TODO：`jj interdiff`と比較します。
// - `jj interdiff PATHS...`。TODO。これは高度ですか？
// - `jj edit REVISION`。`@`（「作業コピーリビジョン」）をREVISIONに移動します。
// - `jj file track/untrack`。
// - `jj log PATHS...`。PATHSを変更したノードに限定してDAGを印刷します。質問：いつ`jj log -r ..`を実行する必要がありますか？
// - `jj new`。`@`の上に新しい空のコミットを作成し、それを編集します（`@`をそれに移動します）。`-m "MESSAGE"`はさらにその説明を設定します。`jj new REVISIONS...`は新しいコミットの親を指定します。複数の親がいる場合、マージコミットを作成しています。
// - `jj status`（エイリアス：`jj st`）。リポジトリに関する基本情報を印刷します。
// - `jj restore --from REVISION PATHS...`。このコミットのファイルをREVISIONのものと一致させます。
// - `jj undo`。最後に行ったことを元に戻します。
// - `jj squash`。このリビジョンからその親へのすべての変更を移動します。
// - `jj rebase`。TODO。
// - `jj resolve!!`。TODO。
// 
// ## 高度なコマンド
// 
// - `jj bookmark forget BOOKMARK`。BOOKMARKという名前のブックマークラベルを削除しますが、それがリモートに存在することを「忘れます」。再度プルすると再作成されます！
// - `jj bookmark track BOOKMARK@REMOTE`。TODO
// - `jj bookmark untrack BOOKMARK@REMOTE`。TODO
// - `jj duplicate`。TODO
// - `jj new --insert-before REVISION`および`jj new --insert-after REVISION`。TODO。
// - `jj prev`および`jj next`？
// - `jj simplify-parents`。DAGを無損失で簡略化します（A -> B、A -> C、B ->+ CはA -> B、B ->+ Cになります）。
// - `jj workspace`。TODO。
// - `jj undo OPERATION`。TODO。
// - `jj split`。コミットを2つに分割し、エディタで編集します。
// - `jj parallelize`。TODO。
