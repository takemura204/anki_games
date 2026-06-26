class Quote {
  const Quote({required this.text, required this.author});
  final String text;
  final String author;
}

// ignore: avoid_classes_with_only_static_members
abstract final class MotivationQuotes {
  static const _quotes = [
    Quote(text: '達成するまでは、\nいつも不可能に見える。', author: 'ネルソン・マンデラ'),
    Quote(text: 'どんな専門家も、\nかつては初心者だった。', author: 'ヘレン・ヘイズ'),
    Quote(text: '成功は、毎日繰り返す\n小さな努力の積み重ねだ。', author: 'ロバート・コリアー'),
    Quote(text: '学ぶことの素晴らしさは、\n誰にも奪えないことだ。', author: 'B.B. キング'),
    Quote(text: '先に進む秘訣は、\n始めることだ。', author: 'マーク・トウェイン'),
    Quote(text: '学ぶことで、\n心が疲れることはない。', author: 'レオナルド・ダ・ヴィンチ'),
    Quote(text: '最大の栄光は転ばないことではない。\n転ぶたびに起き上がることだ。', author: '孔子'),
    Quote(text: '未来は、\n今日何をするかにかかっている。', author: 'マハトマ・ガンジー'),
    Quote(text: '天才とは、\n1%の才能と99%の努力だ。', author: 'トーマス・エジソン'),
    Quote(text: '知識への投資は、\n最高の利息をもたらす。', author: 'ベンジャミン・フランクリン'),
    Quote(text: '何かを始めるのに、\n遅すぎることはない。', author: 'ビル・ゲイツ'),
    Quote(text: '常にベストを尽くせば、\n結果はついてくる。', author: 'コービー・ブライアント'),
    Quote(text: '変わることを恐れるな。\nそれは成長の一部だ。', author: 'イーロン・マスク'),
    Quote(text: '不安や懸念に打ち勝った時、\n初めて自分の力に気付く。', author: 'セリーナ・ウィリアムズ'),
    Quote(text: '成功するためには、ただ一つの方法しかない。\nそれは決して諦めないことだ。', author: 'ジェフ・ベゾス'),
    Quote(text: '目の前の障害はチャンスだ。\n困難に直面することで成長できる。', author: 'ケビン・デュラント'),
    Quote(text: '集中すれば、\nどんな壁も乗り越えられる。', author: 'ウォーレン・バフェット'),
    Quote(text: '挑戦することは、\n成長することだ。', author: 'レブロン・ジェームズ'),
    Quote(text: '自分を信じれば、\n限界は存在しない。', author: 'クリスティアーノ・ロナウド'),
    Quote(text: '挑戦し続ける限り、\n失敗は存在しない。', author: 'マーク・ザッカーバーグ'),
    Quote(text: '問題を解決するには、\n問題から逃げないことだ。', author: 'ジャック・ドーシー'),
    Quote(text: '今すぐできることを、\n明日まで待つな。', author: 'マーゴット・ロビー'),
    Quote(text: '自分のペースで進んでいい。\n他人と比べる必要はない。', author: 'タイラー・ザ・クリエイター'),
    Quote(text: 'どれだけの努力をしたかが、\n結果を決める。', author: 'マイケル・ジョーダン'),
    Quote(text: '知識は武器だ。\nそれをどう使うかが問題だ。', author: 'エミネム'),
    Quote(text: '継続は力なり。', author: '日本のことわざ'),
    Quote(text: '千里の道も一歩から。', author: '老子'),
    Quote(text: '学問に王道なし。', author: '日本のことわざ'),
    Quote(text: '為せば成る、\n為さねば成らぬ何事も。', author: '上杉鷹山'),
    Quote(text: '知は力なり。', author: 'フランシス・ベーコン'),
    Quote(text: '小さいことを重ねることが、\nとんでもないところに行くただひとつの道。', author: 'イチロー'),
    Quote(text: '真剣だからこそ、\nぶつかる壁がある。', author: '松岡修造'),
    Quote(text: '今日の成果は過去の努力の結果。\n未来はこれからの努力で決まる。', author: '稲盛和夫'),
    Quote(text: '努力は必ず報われる。\nまだ報われないなら、それはまだ努力と呼べない。', author: '王貞治'),
    Quote(
      text: '成功があがりでもなければ、\n失敗が終わりでもない。\n肝心なのは続ける勇気だ。',
      author: 'ウィンストン・チャーチル',
    ),
    Quote(text: '才能とは何かと問われれば\n「続けること」と私は答える。\nこれが最も難しいのです。', author: '羽生善治'),
    Quote(text: '努力すれば報われる？そうじゃない。\n報われるまで努力するんだ。', author: 'リオネル・メッシ'),
    Quote(text: '学ぶことで才能は開花する。\n志がなければ、学問の完成はない。', author: '諸葛孔明'),
    Quote(text: '昨日の自分は決して\n今日の自分を裏切らない。', author: '浅田真央'),
    Quote(text: 'やる気があるときなら誰でもできる。\n本当の成功者は、やる気がないときでもやる。', author: 'フィル・マグロー'),
    Quote(text: '後ろを振り向く必要はない。\nあなたの前にはいくらでも道があるのだから。', author: '魯迅'),
    Quote(text: '人間は元々そんなに賢くありません。\n勉強して修行して、やっとまともになるのです。', author: '瀬戸内寂聴'),
    Quote(text: '環境より\n学ぶ意志があればいい。', author: '津田梅子'),
    Quote(text: '誰よりも三倍、四倍、五倍勉強する者、\nそれが天才だ。', author: '野口英世'),
    Quote(text: 'やる気があるから動くのではない。\n動くからやる気が出るのだ。', author: 'ウィリアム・ジェームズ'),
    Quote(text: '困難の中にこそ、\n機会がある。', author: 'アルバート・アインシュタイン'),
    Quote(text: 'チャンスは\n準備された心を好む。', author: 'ルイ・パスツール'),
    Quote(text: '千日の稽古を鍛とし、\n万日の稽古を錬とする。', author: '宮本武蔵'),
    Quote(text: '夢見ることができれば、\n実現することができる。', author: 'ウォルト・ディズニー'),
    Quote(
      text: 'やってみせ、言って聞かせて、させてみせ、\nほめてやらねば人は動かじ。',
      author: '山本五十六',
    ),
    Quote(
      text: '夢なき者に理想なし。\n理想なき者に計画なし。',
      author: '吉田松陰',
    ),
    Quote(
      text: '時間は有限だ。\n他の誰かの人生を生きることで\n消費するな。',
      author: 'スティーブ・ジョブズ',
    ),
    Quote(text: '自分の無知を知ることが、\n知恵の始まりだ。', author: 'ソクラテス'),
    Quote(
      text: '世の人は我を何とも言わば言え。\n我がなすことは我のみぞ知る。',
      author: '坂本龍馬',
    ),
    Quote(
      text: '優秀さとは行為ではなく、\n習慣から生まれるものだ。',
      author: 'アリストテレス',
    ),
    Quote(text: '諦めない心が、\n不可能を可能にする。', author: 'マーティン・ルーサー・キング'),
    Quote(text: '石の上にも三年。', author: '日本のことわざ'),
    Quote(
      text: '偉大なことは、\n小さなことの積み重ねから生まれる。',
      author: 'ヴィンセント・ファン・ゴッホ',
    ),
    Quote(
      text: '夢はそれを実現できると\n信じた瞬間から始まる。',
      author: 'ナポレオン・ヒル',
    ),
    Quote(
      text: '自分の能力を信じろ。\n君はそれ以上のことができる。',
      author: 'ジョン・F・ケネディ',
    ),
    Quote(
      text: '一日一生。\n今日という日を\n精いっぱい生きよ。',
      author: '相田みつを',
    ),
  ];

  static Quote pick(DateTime seed) {
    final index =
        (seed.year * 366 + seed.month * 31 + seed.day) % _quotes.length;
    return _quotes[index];
  }
}
