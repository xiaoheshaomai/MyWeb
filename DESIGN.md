# 小和烧麦 / Rico Zhang — Visual Design Spec

## Identity

| 中文名 | 英文名 | 平台 |
|--------|--------|------|
| 小和烧麦 | Rico Zhang | 小红书：[主页链接](https://xhslink.com/m/7DvOXgtpAI3) |

---

## Color Palette

| Token | Hex | 用途 |
|-------|-----|------|
| `--blue` | `#2138f9` | 全站主背景色、品牌主色 |
| `--green` | `#00ff2a` | 强调色：标题、数字、按钮边框、CTA |
| `--white` | `#ffffff` | 正文、标题 |
| `--ink` | `#0f0f0f` | 深色备用背景（暂未主用） |
| `--blue-dark` | `#1830e8` | hover 状态、轻微加深蓝 |

### 透明度规范（白色叠蓝底）

| 用途 | rgba |
|------|------|
| 主正文 | `rgba(255,255,255,1.0)` |
| 次要正文 / 描述文字 | `rgba(255,255,255,0.82–0.85)` |
| 辅助文字 / 标签 | `rgba(255,255,255,0.65–0.72)` |
| 边框 / 分割线 | `rgba(255,255,255,0.18–0.22)` |
| 卡片背景（正面） | `rgba(255,255,255,0.06)` |
| 卡片背景（翻牌背面） | `rgba(0,0,0,0.28)` |
| Footer 背景 | `rgba(0,0,0,0.15)` 叠在 `--blue` 上 |

---

## Typography

### 字体栈
```
"Helvetica Neue", Arial, "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", sans-serif
```

### 层级

| 层级 | 尺寸 | weight | 颜色 | 用途 |
|------|------|--------|------|------|
| Hero Title | `clamp(60px, 9vw, 120px)` | 900 | `--green` | 首页名字 |
| Section H2 | `clamp(38px, 6vw, 80px)` | 900 | white | 各 section 标题 |
| Stats Number | `clamp(36px, 5vw, 56px)` | 900 | `--green` | 数据大字 |
| Card Title | `20px` | 800 | white | 卡片标题 |
| Body | `16–17px` | 400 | `rgba(white, 0.82)` | 正文描述 |
| Eyebrow / Label | `11–12px` | 700–800 | `--green` or `rgba(white,0.65)` | 分类标签 |
| Small / Tag | `11–13px` | 600 | `rgba(white,0.7)` | pill 标签 |

### Letter Spacing
- Eyebrow / 全大写标签：`0.18–0.22em`
- 正文：默认
- Hero Title：`-0.04em`（紧排）

---

## Spacing & Layout

| 名称 | 值 |
|------|----|
| 页面左右 padding | `clamp(20px, 5vw, 60px)` |
| Section 上下 padding | `clamp(80px, 12vw, 140px)` |
| 最大内容宽度 | `1100px` |
| 卡片圆角 | `14px` |
| 按钮 / pill 圆角 | `999px` |
| 卡片 gap | `16–20px` |

### Hero 网格
- 桌面：`grid-template-columns: 1fr 1fr`（左视频 / 右文字）
- 移动：单列，视频在上（高度 60vw）

### Work Grid
- 桌面：4 列，`aspect-ratio: 3/4`（竖屏封面比例）
- 移动：2 列

---

## Components

### Flip Card
- 正面：渐变色占位图 + 底部渐变遮罩 + 播放量 + 标题（叠加在封面上）
- 背面：`rgba(0,0,0,0.28)` 深色卡，绿色大标题 + 描述 + 跳转按钮
- 翻转动画：`0.65s cubic-bezier(0.4, 0.2, 0.2, 1)` rotateY
- 封面比例：`3:4`（匹配竖屏视频封面）

### Buttons / CTA
- Primary：`border: 1.5px solid --green`，文字 `--green`，hover 填充绿底黑字
- Secondary pill（nav/footer）：`border: 1px solid rgba(white,0.25)`，hover 白底黑字

### Language Toggle（中 / EN）
- 胶囊形，当前语言高亮：`background: --green; color: --ink`
- 非激活：`color: rgba(white, 0.4)`

### Cloud Decorations
- 图片：`assets/cloud.png`
- 6 个，`position: absolute` 散布在 hero section
- 尺寸：75px – 160px
- 动画：`cloud-float` 5–7s ease-in-out infinite，各有独立 `animation-delay`

---

## Video Specs

| 规格 | 值 |
|------|----|
| 视频封面比例 | `3:4` |
| 视频本身比例 | `9:16` |
| 首页 hero 视频 | `assets/final1.mp4`，autoplay / muted / loop / playsinline |
| 背景蓝色（与视频背景一致）| `#2138f9` |
| video object-fit | `cover`，`object-position: center top` |

---

## Bilingual System

- 默认语言：中文（`<html class="zh">`）
- 切换方式：点击「中 / EN」胶囊
- 实现：`html.zh .en { display:none }` / `html.en .zh { display:none }`
- 数字格式：中文用万（71.9万），英文用 K（719K）

---

## Social Stats（截至 2025 年底）

| 指标 | 数值（中） | 数值（英） |
|------|-----------|-----------|
| 赞与收藏 | 71.9万 | 719K |
| 粉丝 | 5.1万 | 51K |
| 单视频最高播放 | 77万+ | 770K+ |

---

## CV Data

### Education
| 时间 | 学校 | 学位/专业 |
|------|------|----------|
| 2025.09 – 至今 | UAL · Creative Computing Institute | MSc Data Science & AI |
| 2018.09 – 2022.06 | 上海大学 Shanghai University | 金融学本科 BSc Finance |

### Work
| 时间 | 公司 | 职位 |
|------|------|------|
| 2024.01 – 2025.08 | 自媒体博主 Independent Creator | 小红书 3D 动画内容创作 |
| 2022.12 – 2023.12 | 上海麦肯光明 McCann Shanghai | Creative |

---

## File Structure

```
website/
├── index.html       # 单页网站主文件
├── DESIGN.md        # 本视觉规范文档
└── assets/
    ├── final1.mp4   # 首页 hero 视频（挥手小人，竖屏）
    └── cloud.png    # 3D 云朵装饰图
```
