import Foundation

/// 奖励资源目录：所有奖励统一由 asset 名字驱动。
/// - 图片名字 = asset 本身（Assets.xcassets 里同名 imageset）
/// - 标题 / 介绍文案按 asset 和语言查 `RewardData.info`
/// - 顺序与 `RewardCollectionStore.all` 保持一致（29 条）
enum RewardData {
    /// 一条奖励的三语文案。
    struct Info {
        let zhTitle: String
        let zhDesc: String
        let enTitle: String
        let enDesc: String
        let jaTitle: String
        let jaDesc: String
    }

    /// 全量奖励池，按收藏页摆放顺序。
    static let allAssets: [String] = [
        "san1", "san2", "san3", "san4", "san5", "san6",
        "cake1", "cake2", "cake3", "cake4", "cake5", "cake6",
        "hg1", "hg2", "hg3", "hg4", "hg5", "hg6",
        "rice1", "rice2", "rice3", "rice4", "rice5", "rice6",
        "ch1", "ch2", "ch3", "ch4", "ch5",
    ]

    static var totalCount: Int { allAssets.count }

    /// asset → 图片名（与 Assets.xcassets 里 imageset 同名）
    static func imageName(for asset: String) -> String { asset }

    /// 找不到文案时的兜底
    private static let fallbackAsset = "san1"

    // MARK: - 咖啡（午睡挑战奖励）
    /// 午睡挑战奖励：不进入早餐收藏池，只在奖励页与首页桌面展示。
    static let coffeePlaceholderAsset = "latte"

    /// 判断这个 asset 是否属于咖啡类（目前只有占位一款，将来扩展时在此判断前缀/集合）
    static func isCoffee(_ asset: String) -> Bool {
        asset == "latte" || asset.hasPrefix("coffee")
    }

    /// 所有奖励的三语介绍；新增奖励时在这里补一条即可。
    static let info: [String: Info] = [
        // ───────── 三明治 san1–san6 ─────────
        "san1": Info(
            zhTitle: "经典生菜番茄三明治",
            zhDesc: "嫩生菜 + 阳光番茄\n一口就是清清爽爽的早晨。",
            enTitle: "Classic Lettuce & Tomato Sandwich",
            enDesc: "Crisp lettuce + sun-ripe tomato.\nA fresh bite of morning!",
            jaTitle: "定番レタス＆トマトサンド",
            jaDesc: "シャキッとレタスと完熟トマト。\nさわやかな朝のひとくち。"
        ),
        "san2": Info(
            zhTitle: "彩虹夹心三明治",
            zhDesc: "四层颜色堆出好心情，\n今天也要一口吃进小确幸。",
            enTitle: "Rainbow Layered Sandwich",
            enDesc: "Four happy layers stacked tall —\none bite, one small joy.",
            jaTitle: "レインボーサンド",
            jaDesc: "四色の小さなしあわせを\nまるごと頬張ろう。"
        ),
        "san3": Info(
            zhTitle: "培根番茄 BLT",
            zhDesc: "香脆培根 + 多汁番茄\n一口起飞的经典风味。",
            enTitle: "Bacon Tomato BLT",
            enDesc: "Crispy bacon + juicy tomato.\nThe classic pick-me-up.",
            jaTitle: "ベーコントマト BLT",
            jaDesc: "カリカリベーコン＆ジューシートマト。\n定番の目覚まし味。"
        ),
        "san4": Info(
            zhTitle: "鸡肉牛油果三明治",
            zhDesc: "嫩鸡胸配上牛油果的丝滑，\n今天一整天都是柔软的。",
            enTitle: "Chicken Avocado Sandwich",
            enDesc: "Tender chicken meets creamy avocado.\nA gentle start to a long day.",
            jaTitle: "チキンアボカドサンド",
            jaDesc: "やわらかチキンにとろけるアボカド。\n今日もやさしい一日を。"
        ),
        "san5": Info(
            zhTitle: "黄油鸡蛋三明治",
            zhDesc: "金黄蛋黄咕嘟一下，\n是记忆里妈妈的做法。",
            enTitle: "Buttery Egg Sandwich",
            enDesc: "Sunny yolk, gentle butter —\nthe way mom used to make.",
            jaTitle: "バターエッグサンド",
            jaDesc: "黄金のたまごにほんのりバター。\nおかあさんの味だね。"
        ),
        "san6": Info(
            zhTitle: "蔬菜清爽三明治",
            zhDesc: "番茄 + 黄瓜 + 青生菜，\n像去公园散了个步。",
            enTitle: "Garden Fresh Sandwich",
            enDesc: "Tomato + cucumber + greens —\na walk in the park, in a sandwich.",
            jaTitle: "ガーデンベジサンド",
            jaDesc: "トマト＋きゅうり＋レタスで、\n公園を散歩した気分。"
        ),

        // ───────── 蛋糕 cake1–cake6 ─────────
        "cake1": Info(
            zhTitle: "双重巧克力蛋糕",
            zhDesc: "可可慕斯叠着黑巧克力顶，\n今天的你值得甜一下。",
            enTitle: "Double Chocolate Cake",
            enDesc: "Cocoa mousse with a dark chocolate peak.\nYou earned this sweetness.",
            jaTitle: "ダブルチョコレートケーキ",
            jaDesc: "ココアムースにダークチョコの頂上。\n今日のごほうび。"
        ),
        "cake2": Info(
            zhTitle: "草莓奶油蛋糕",
            zhDesc: "一口咬下去粉粉的、甜甜的，\n像今早的好心情。",
            enTitle: "Strawberry Cream Cake",
            enDesc: "Pink, creamy, sweet —\njust like this morning's mood.",
            jaTitle: "ストロベリークリームケーキ",
            jaDesc: "ふんわりピンクのあまい気分は\n今朝のきもちと同じ。"
        ),
        "cake3": Info(
            zhTitle: "柠檬草莓双拼蛋糕",
            zhDesc: "柠檬的清爽配上草莓的酸甜，\n醒来的舌头会跳舞。",
            enTitle: "Lemon Strawberry Cake",
            enDesc: "Zesty lemon meets strawberry sweetness.\nYour tongue will wake up dancing.",
            jaTitle: "レモン＆ストロベリーケーキ",
            jaDesc: "レモンの爽やかさといちごの甘酸っぱさ。\n舌が踊りだすよ。"
        ),
        "cake4": Info(
            zhTitle: "宇治抹茶慕斯",
            zhDesc: "微苦的抹茶一层层化开，\n让人想起春天的茶田。",
            enTitle: "Uji Matcha Mousse",
            enDesc: "Layers of bittersweet matcha\nwhisper of spring tea fields.",
            jaTitle: "宇治抹茶ムース",
            jaDesc: "ほろ苦い抹茶が層をなして、\n春のお茶畑をそっと思い出す。"
        ),
        "cake5": Info(
            zhTitle: "焦糖栗子巧克力蛋糕",
            zhDesc: "焦糖色的温柔层层叠叠，\n秋天的早晨来了一份。",
            enTitle: "Caramel Chestnut Chocolate",
            enDesc: "Warm caramel layers stacked up —\nan autumn morning on a plate.",
            jaTitle: "キャラメル栗チョコ",
            jaDesc: "キャラメル色のやさしさが重なる、\n秋の朝のひとさら。"
        ),
        "cake6": Info(
            zhTitle: "蓝莓夜空慕斯",
            zhDesc: "蓝紫渐变像清晨的夜空，\n醒得早的人才能看见。",
            enTitle: "Blueberry Night-Sky Mousse",
            enDesc: "Blue-purple gradient like pre-dawn sky —\nseen only by early risers.",
            jaTitle: "ブルーベリー夜空ムース",
            jaDesc: "青から紫へのグラデーションは\n早起きした人だけの空。"
        ),

        // ───────── 热狗 hg1–hg6 ─────────
        "hg1": Info(
            zhTitle: "经典辣酱热狗",
            zhDesc: "番茄碎配黄芥末酱，\n从咬第一口就充满活力。",
            enTitle: "Classic Chili Hot Dog",
            enDesc: "Chunky tomato + yellow mustard —\nenergy from the first bite.",
            jaTitle: "定番チリホットドッグ",
            jaDesc: "トマトとマスタードで、\nひとくち目からエネルギー全開。"
        ),
        "hg2": Info(
            zhTitle: "黄瓜莎莎热狗",
            zhDesc: "脆脆黄瓜配番茄粒，\n是清爽版的夏日早晨。",
            enTitle: "Cucumber Salsa Dog",
            enDesc: "Crisp cucumber + tomato salsa —\na fresh summer morning bun.",
            jaTitle: "きゅうりサルサドッグ",
            jaDesc: "シャキシャキきゅうりとトマトで、\n夏の朝みたいにさわやか。"
        ),
        "hg3": Info(
            zhTitle: "芝士玉米热狗",
            zhDesc: "融化的芝士 + 甜玉米粒，\n这是周末才敢吃的早餐。",
            enTitle: "Cheese & Corn Dog",
            enDesc: "Melty cheese + sweet corn —\na weekend kind of breakfast.",
            jaTitle: "チーズコーンドッグ",
            jaDesc: "とろけるチーズと甘いコーン、\n週末気分の朝ごはん。"
        ),
        "hg4": Info(
            zhTitle: "番茄芥末双酱热狗",
            zhDesc: "红酱与黄酱齐上阵，\n标准的球场味道。",
            enTitle: "Ketchup-Mustard Double",
            enDesc: "Ketchup and mustard, side by side.\nStadium classic.",
            jaTitle: "ケチャ＆マスタード ドッグ",
            jaDesc: "赤と黄色がきれいに並ぶ、\nスタジアム定番の味。"
        ),
        "hg5": Info(
            zhTitle: "双色能量热狗",
            zhDesc: "青酱 + 芥末黄 + 番茄红，\n红绿灯都给你开绿灯。",
            enTitle: "Traffic-Light Energy Dog",
            enDesc: "Green + yellow + red stripes —\nevery light turns green today.",
            jaTitle: "信号機エナジードッグ",
            jaDesc: "緑・黄・赤の三本ライン。\n今日は全部青信号！"
        ),
        "hg6": Info(
            zhTitle: "纯芥末原味热狗",
            zhDesc: "一条面包、一根香肠、\n再画一道黄色的弧线就够了。",
            enTitle: "Plain Mustard Dog",
            enDesc: "One bun, one sausage,\nand a single yellow curve. Done.",
            jaTitle: "シンプルマスタードドッグ",
            jaDesc: "パン・ソーセージ・\n黄色いひとすじあれば十分。"
        ),

        // ───────── 饭团 rice1–rice6 ─────────
        "rice1": Info(
            zhTitle: "三文鱼粒饭团",
            zhDesc: "橙红色的三文鱼块闪闪发光，\n像今天的你一样元气。",
            enTitle: "Salmon Cube Onigiri",
            enDesc: "Glowing orange salmon cubes —\nas lively as you are today.",
            jaTitle: "サーモン角切りおにぎり",
            jaDesc: "きらきらオレンジのサーモン、\n今日のきみみたいに元気。"
        ),
        "rice2": Info(
            zhTitle: "梅子饭团",
            zhDesc: "一粒酸梅藏在白米里，\n提醒你早晨也可以很清醒。",
            enTitle: "Umeboshi Onigiri",
            enDesc: "A single sour plum in white rice —\na gentle nudge for a clear morning.",
            jaTitle: "梅干しおにぎり",
            jaDesc: "ごはんの真ん中に梅ひとつ。\nしゃっきり目が覚めるよ。"
        ),
        "rice3": Info(
            zhTitle: "黄金玉米饭团",
            zhDesc: "金黄玉米粒顶在饭团头上，\n好像在给你发一枚小太阳。",
            enTitle: "Golden Corn Onigiri",
            enDesc: "Golden corn crowning the rice —\na tiny sun just for you.",
            jaTitle: "黄金コーンおにぎり",
            jaDesc: "黄金のコーンがちょこんと乗って、\n小さな太陽をひとつあげる。"
        ),
        "rice4": Info(
            zhTitle: "照烧鸡粒饭团",
            zhDesc: "酱香鸡粒配青葱，\n是便利店冷柜里的温柔。",
            enTitle: "Teriyaki Chicken Onigiri",
            enDesc: "Savory chicken bits with scallion —\nthe convenience-store kind of cozy.",
            jaTitle: "照り焼きチキンおにぎり",
            jaDesc: "こんがり鶏と青ねぎで、\nコンビニのやさしさをひとつ。"
        ),
        "rice5": Info(
            zhTitle: "炸虾天妇罗饭团",
            zhDesc: "一条大虾从饭团里探出头，\n好像在跟你打招呼。",
            enTitle: "Shrimp Tempura Onigiri",
            enDesc: "A big prawn peeking out —\nit waves hi on its way in.",
            jaTitle: "えび天むす",
            jaDesc: "おにぎりから大きなえびが顔を出す。\n「おはよう」って言ってる。"
        ),
        "rice6": Info(
            zhTitle: "炸鸡葱香饭团",
            zhDesc: "酥脆炸鸡配上一点葱花，\n让胃和心一起暖起来。",
            enTitle: "Fried Chicken & Scallion",
            enDesc: "Crispy chicken topped with scallion.\nWarms both stomach and heart.",
            jaTitle: "唐揚げネギおにぎり",
            jaDesc: "サクサク唐揚げにねぎパラリ。\nおなかも気持ちもぽかぽか。"
        ),

        // ───────── 中式早点 ch1–ch5 ─────────
        "ch1": Info(
            zhTitle: "小笼汤包",
            zhDesc: "蒸笼揭开的那一刻，\n是江南早晨的样子。",
            enTitle: "Xiaolongbao",
            enDesc: "The moment the lid lifts —\nthat's a Jiangnan morning.",
            jaTitle: "小籠包",
            jaDesc: "せいろの蓋を開けた瞬間、\n江南の朝が立ちのぼる。"
        ),
        "ch2": Info(
            zhTitle: "生煎鲜肉包",
            zhDesc: "底部煎得金黄酥脆，\n上面撒了一撮青葱。",
            enTitle: "Pan-Fried Pork Bun",
            enDesc: "Crispy golden bottom,\na pinch of scallion on top.",
            jaTitle: "焼き小籠包（生煎包）",
            jaDesc: "底はカリッと黄金色、\n青ねぎをぱらりとひとつまみ。"
        ),
        "ch3": Info(
            zhTitle: "金黄油条",
            zhDesc: "外酥里空心，\n配豆浆最合拍。",
            enTitle: "Chinese Youtiao",
            enDesc: "Crispy outside, airy inside —\nsoy milk's best friend.",
            jaTitle: "揚げパン（油条）",
            jaDesc: "外はサク、中はふんわり。\n豆乳と一番の相棒。"
        ),
        "ch4": Info(
            zhTitle: "芝麻酱葱香烧饼",
            zhDesc: "芝麻和葱花一起下锅，\n楼下早点摊的老熟味道。",
            enTitle: "Sesame & Scallion Shaobing",
            enDesc: "Sesame + scallion, pan-warmed —\nthe neighborhood breakfast classic.",
            jaTitle: "ごまねぎ焼餅",
            jaDesc: "ごまと青ねぎをいっしょに焼いて、\n街角の朝ごはんの味。"
        ),
        "ch5": Info(
            zhTitle: "鲜虾烧麦",
            zhDesc: "顶着一粒胡萝卜的帽子，\n像穿着小裙子的早餐。",
            enTitle: "Shrimp Shumai",
            enDesc: "Crowned with a bright carrot dot —\nbreakfast in a tiny skirt.",
            jaTitle: "えびシュウマイ",
            jaDesc: "にんじんの小さな帽子をかぶって、\nスカートのようにかわいい朝ごはん。"
        ),

        // ───────── 拿铁（午睡挑战奖励，不进早餐收藏） ─────────
        "latte": Info(
            zhTitle: "拿铁",
            zhDesc: "拿铁慢慢的喝，\n开启高效率的下午啦！",
            enTitle: "Latte",
            enDesc: "Sip your latte slowly,\nand start an efficient afternoon!",
            jaTitle: "ラテ",
            jaDesc: "ラテをゆっくり飲んで、\n効率のいい午後を始めよう！"
        ),
    ]

    // MARK: - 语言辅助（业务代码只用这两个方法就够）

    static func title(for asset: String, lang: String) -> String {
        let key = info[asset] == nil ? fallbackAsset : asset
        let i = info[key] ?? info[fallbackAsset]!
        switch lang {
        case "en": return i.enTitle
        case "ja": return i.jaTitle
        default:   return i.zhTitle
        }
    }

    static func desc(for asset: String, lang: String) -> String {
        let key = info[asset] == nil ? fallbackAsset : asset
        let i = info[key] ?? info[fallbackAsset]!
        switch lang {
        case "en": return i.enDesc
        case "ja": return i.jaDesc
        default:   return i.zhDesc
        }
    }
}
