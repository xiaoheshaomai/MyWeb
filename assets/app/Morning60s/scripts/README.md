# 10 款奖励图：切图 + 白底

把你画的两张「多款美食」网格图变成 10 张单图并去灰底，写入 App 的 Assets。

## 步骤

1. **装依赖**（只需一次）  
   ```bash
   pip install Pillow
   ```

2. **准备两张图**  
   - 第一张：6 款（例如蛋糕），排成 **2 列 × 3 行**。  
   - 第二张：6 款（例如三明治），同样 **2 列 × 3 行**。  
   - 放到 `scripts/reward_sources/` 下，命名为：  
     - `01_cakes.png`  
     - `02_sandwiches.png`  
   - 或任意路径，用命令行参数传入（见下）。

3. **运行脚本**（在项目根目录）  
   ```bash
   python scripts/split_reward_images.py
   ```  
   或指定路径：  
   ```bash
   python scripts/split_reward_images.py path/to/图1.png path/to/图2.png
   ```

4. **效果**  
   - 浅灰/浅蓝灰底会变成纯白底。  
   - 每张图被切成 6 块，共 12 块，取前 10 块写入 `Morning60s/Assets.xcassets/Reward01.imageset` … `Reward10.imageset`。  
   - 重新编译运行 App 即可在收藏页和奖励页看到你的图。

若你的网格是 **3 列 × 2 行**，在脚本里把 `ROWS, COLS = 3, 2` 改成 `ROWS, COLS = 2, 3`。
