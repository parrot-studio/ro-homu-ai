それっぽいAI（仮） - RO Homunculus AI 
===============

Description
---------------
ROにおけるホムンクルスのAIです。

デフォルトのAIが設計はともかくコードが美しくないので、
後々のメンテナンス性を考えて書き直したものです。
（少なくとも、現時点では）

Luaにおけるオブジェクト的な記述を用いて、
宣言的かつ継承等が可能なコードに書き換えています。
基本的な動作は一部を除いてそのままです。
（少なくとも、現時点では）

個人的な学習用のコードですので、
私以外の方が実際に使用することはお勧めできません。
高機能で実用的なAIは以下のサイトから探してください。

http://www.ragfun.net/alchemist/index.php?%A5%DB%A5%E0%A5%F3%A5%AF%A5%EB%A5%B9%2FLua%2FAI

Installation
---------------
どうしても使いたい方向けの手順です。
基本的に他所で配布されている実績があるAIをおすすめします。
暴走によりトラブルに巻き込まれたり、ホムを失ったとしても、こちらでは責任が持てません。

「src/USER\_AI/」以下のファイルを、クライアントの「AI/USER\_AI」以下に置いてください。
その後、RO内でホムを召還し、「/hoai」コマンドを実行してください。
（他のAI等が配置済みの場合は、バックアップしてから置き換えてください）

このAIはソースコードを一から書き直している都合上、
予想外のエラーにより、主人も含めてコントロール不能になる可能性があります。
試す際は街の中等、安全な場所でおこなってください。
また、ある程度満腹度が高い状態をおすすめします。

エラーにより暴走した場合、以下の手順で復旧してください。

- ALT+F4でクライアントを終了させる
- USER\_AI/以下を全て削除
- AI/AI.lua Const.lua Util.luaをUSER\_AI以下にコピー

Changed from Default AI
---------------
#### ver0.2β
- Settingを追加
 - 設定情報を管理するオブジェクト
 - 暗黙的にファイルに書き込みをおこなう
 - これを通すことで、reloadされても状態を維持できる
- 先制/非先制を判定・設定する仕組みを追加
- 先制/非先制スイッチ追加
 - とりあえずFilirに実装
 - 主人に対して右 -> 左 -> 右と移動命令でスイッチを反転させる
 - 反転させたスイッチはreloadしても保持するので注意
- Idle状態ですることがない場合、主人のそばに戻るように

#### ver0.1β
- 全体的なコード書き換え
 - 状態遷移モデル設計はそのままに、OOP+宣言的コーディング
- 必ず非先攻
 - AI\_old.luaで実装したスイッチ機能は未実装（今後実装予定）
- 敵がターゲットをもつ場合は攻撃対象にしない（横殴り防止）
- 一定以上主人と離れた場合、強制的に主人の元に戻る
 - 攻撃中でも、待機中でも

License
---------------
#### for src/USER_AI/ and README

The MIT License

see LICENSE file for detail

#### Copyright for Default AI & Client

"RAGNAROK ONLINE"

Gravity Corp. & Lee Myoungjin(studio DTDS). All Rights Reserved.

GungHo Online Entertainment, Inc. All Rights Reserved 

Author
---------------
ぱろっと(@parrot_studio / parrot.studio.dev at gmail.com)
