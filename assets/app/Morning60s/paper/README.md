# Morning60s — C&C 2026 Poster paper

本目录包含提交 ACM Creativity & Cognition 2026（Posters Track）用的两份稿件，已**匿名**、控制在 **3000 字**以内。

## 文件

- `main.tex` — ACM 官方模板（`acmart.cls`，`sigconf` + `anonymous` + `review`）可直接编译的单栏 LaTeX。
- `morning60s.md` — 同内容 Markdown，方便复制到 Word 模板。
- `README.md` — 本说明。

## 怎样编译 LaTeX（最省事的一种）

1. 去 ACM 拿模板：<https://www.acm.org/publications/proceedings-template>
2. 解压后把 `main.tex` 放到与 `acmart.cls` **同级**的目录。
3. 按顺序跑：

```
pdflatex main.tex
bibtex   main
pdflatex main.tex
pdflatex main.tex
```

4. 生成 `main.pdf`。本文件在 document class 里写的是

```
\documentclass[sigconf,anonymous,review]{acmart}
```

- `anonymous` 会隐去作者信息（满足 C&C Posters 的匿名要求）。
- `review` 打开行号，便于审稿。**camera-ready 时**把它去掉。

## 怎样用 Word 版

1. 打开 ACM Word 模板。
2. 把 `morning60s.md` 里的章节粘进去即可；模板会把单栏排版做好。
3. 交前记得：① 匿名；② 去掉本仓库相关链接；③ 总材料（含海报草稿等）≤ 100 MB。

## 截稿信息（网页上公示的）

- Final submission due: 16 April 2026
- Notifications: 7 May 2026
- Camera-ready: 21 May 2026
- Submission system: PCS — Society **SIGCHI** → 会议 **Creativity & Cognition 2024** 条目下对应的 Posters track（见官网说明）。
