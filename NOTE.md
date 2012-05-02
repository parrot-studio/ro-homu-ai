いろいろなメモ書き
===============

設計方針
---------------
- できるだけLuaのオブジェクト的な記述をおこなう
- 宣言的なコードにより、継承を容易にする
- あまり複雑な仕組みは入れず、いじりやすくする
- できるだけ他の人がいじりやすいようにコメントは入れたい・・・が・・・

Loadmap
---------------
#### ver0.1β
- （済）デフォルトAIをオブジェクト指向的に書き直し
- （済）旧AIで実装済みだった要素の再実装
 - 横殴り防止
 - 非先攻をデフォルト
 - 何もしてないときに主人のところへ戻る
 - 一定距離離れると強制で主人のところへ戻る

#### ver0.2β
- （済）手動スイッチの再実装
 - 先攻/非先攻
 - スキルの使用有無
- （済）汎用的な設定ファイルの読み書き
 - reloadのたびにスイッチを入れるのは面倒なので、設定ファイルに状態保存したい
- （済）デバッグの出力を共通処理に切り出す
- （済）スイッチ処理の一般化
 - 条件とカウンタの部分を抽象化できないか・・・？

#### ver0.3β
- （済）追尾効率化
- （済）詠唱の判定、というより攻撃モーション以外の判定
 - 実装はしたが、索敵条件は「攻撃モーション」のまま
 - でないと、支援スキルを使うPCまで敵認定してしまう
 - これだと対人等には使えないが、対人対応する気もないので
- （済）座り中はIDLEでも遠距離から帰還しない

#### ver0.4β
- （バグ）切り替えスイッチが正しく保存されなかった問題を修正
 - 再読み込み時に反映されていなかった可能性
- （バグ）「対象がいないこと」の判断条件がおかしかったのを修正
 - GetVは0を返していたが、nilで判断していた
- （済）グローバルコンフィグの仕組み
- （済）非移動モンスター設定
 - モンスターNPCを除外しようとすると、動かない敵も除外される
 - グローバルコンフィグで切り替え可能に
- （済）主人との距離感や索敵範囲を設定可能に
- （済）デバッグログの変更
- （済）TraceAIへの吐き出しスイッチ

#### ver0.5β
- （済）オートムーンライトのLvランダム（フィーリル）
- （済）フリットムーブ自動（フィーリル）
- （済）HPを基準にした積極的/消極的モード
 - 一定%よりHPが残ってないと先制しない
 - 一定%よりHPが減っていると自分から敵を探さない
  - コマンドの実行は受け付ける
 - 現状の実装は美しくない
 - ActionModeの概念実装時に状態遷移図を切り直す
- （済）ホムと主人の優先度切り替え
- （済）固定モード
 - ALT+Tを待機ではなく固定と解釈させる設定を追加

#### ver0.9β -> 1.0
- コンパイル対応
- ActionModeの概念追加

#### 1.0以降
- 特定の攻撃対象に対して手加減する
 - あまり複雑になりすぎないレベルで
- 移動時のスタック回避
 - 壁際を移動指定すると固まる
 - 主人と距離が開けば戻ってはくるが・・・

#### 未定（実装自体が未定）
- フィーリル以外の実装
 - 実際に作らないとわからない
- 壁モード
 - 個人的にはあまり必要ではないけど、ActionModeがあればすぐいける？
- 待機中のダンス等
 - インジケーターとして使われている？

やらないこと（コストが高すぎること）
---------------
- Gv対応
 - 興味がない
- 敵のデータ一式が必要な機能
 - データの更新が面倒なため
- 学習系機能
 - とりあえずはやらない方に入れる
 - アイデアはあるけど速度とのバランスが・・・
- 友達系/他者支援系/主人の入れ替え
 - 自分で使うことがたぶんない

Luaにおけるオブジェクトと継承
---------------
Luaのオブジェクトはプロトタイプベースっぽく見えるが、ちょっと違う。
文法でそれっぽく見せているだけで、実際にはtableという仕組みしかない。
全体にJavaScriptやRubyっぽくみえるので、そのあたりの仕組みを知っていれば理解が早いかも。

```Lua
Homu = {} -- ある種のクラス名
Homu.new = function(id) -- コンストラクタに相当
  local this = {} -- オブジェクトの本体
  this.hp = 100   -- プロパティ

  -- メソッドの定義
  -- thisにfunctionオブジェクトを格納する、という書き方
  -- 第一引数にselfを書くのがポイント
  this.cureHp = function(self, point)
    -- この「self」はインスタンス自身を指している
    self.hp = self.hp + point
  end

  this.useHealSkill = function(self)
    -- この呼び出し方がポイント
    -- Luaのシンタックスシュガーにより、それっぽいコードを実現している部分
    self:cureHp(100)

    -- 「self:cureHp(100)」という書き方は、第一引数にレシーバ自身を暗黙的に渡している
    -- 実際には「self.cureHp(self, 100)」の意味
  end

  -- selfを引数に取らないメソッド
  this.printDebug = function(str)
    -- インスタンスを参照しない＝クラスメソッド的な扱い
  end

  return this -- newの最後にメソッドやプロパティを構築したオブジェクトを返す
end

homuId = 10000
homu = Hoge.new(homuId) -- インスタンス生成

-- これも「homu.useHealSkill(homu)」に等しい
homu:useHealSkill()

-- printDebugはselfを取らないので、「.」で呼び出さないとおかしなことに
homu.printDebug("回復したよ")

-- 個人的な感覚では、selfを取るメソッドはインスタンスメソッド、取らないのはクラスメソッド扱い
-- 使い分けが面倒なら全部self渡しでいい気がするけど、乱暴すぎるだろうか
-- 元々「OOPっぽい書き方」だしね・・・
-- そもそもプロパティアクセスは「homu.hp」の形式なわけで
-- メソッド名で判断できるように、ルールを決めるとか必要かも


-- 継承
Yakitori = {} -- Homuを継承するつもりのオブジェクト
Yakitori.new = function(id)
  local this = Homu.new(id) -- Homeのインスタンスをthisに入れる

  -- override
  -- Homuが持つメソッドの中で、必要なもののみ上書きで再定義している
  this.useHealSkill = function(self)
    self:cureHp(200) -- このcureHpはHomuで定義されたものが呼ばれる
  end

  return this -- 継承したオブジェクトを返す
end

tori = Yakitori.new(homuId) -- 継承したオブジェクト
tori:useHealSkill() -- 200回復する
tori.hp -- 300を返す


-- super

-- 上記のコードは親クラスのメソッドを上書きしてしまう
-- superを実行したい場合の方法について検討

A = {} -- 親クラス（的なオブジェクト）
A.new = function()
  local this = {}

  this.hello = function(self, str)
    print("HELLO "..str)
  end

  return this
end

B = {} -- 子クラス（的なオブジェクト）
B.new = function()
  local this = A.new() -- 親クラスを継承

  this._hello = this.hello -- 親クラスのfunctionを別名で参照
  this.hello = function(self, str) -- 上書き
    self:_hello(str) -- 親クラスのhello
    print("hello "..str..'!!') -- 子クラスの実装
  end

  return this
end

a = A.new()
b = B.new()
a:hello('parrot') --> HELLO parrot
b:hello('parrot') --> HELLO parrot\nhello parrot!!
b:_hello('parrot') --> HELLO parrot

-- ただし、このやり方はBをさらに継承したCでどうするか、という問題がある
-- 連鎖的な呼び出しをうまく作れるか？
-- 手動でやろうとするとCがAの実装について知らないといけない

-- では、ルールでの回避はどうか
-- 例えば、「メソッド名に_を使わない」「overrideしたら 親クラス名_元メソッド名」とする
-- 直接の親クラスの名前は知っていていい・・・というか、知らないと継承不能であって

-- ということでやり直してみる

B = {} -- 子クラス（的なオブジェクト）
B.new = function()
  local this = A.new() -- 親クラスを継承

  this.A_hello = this.hello -- 親クラスのfunctionを別名で参照
  this.hello = function(self, str) -- 上書き
    self:A_hello(str) -- 親クラスのhello
    print("hello "..str..'!!') -- 子クラスの実装
  end

  return this
end

C = {} -- 孫クラス（的なオブジェクト）
C.new = function()
  local this = B.new() -- BはAの子クラスだが、Aの存在をCは知らない

  this.B_hello = this.hello -- あくまでBのhelloを保存している
  this.hello = function(self, str)
    self:B_hello(str) -- Bのhelloを呼んだつもり（内部的にAも呼ばれているのだが）
    print("Good Bye "..str) -- 孫クラスの実装
  end

  return this
end

c = C.new()
c:hello('parrot') --> HELLO parrot\nhello parrot!!\nGood Bye parrot

-- ｷﾀｺﾚ（ ﾟдﾟ）o彡ﾟ
```
