# GitHub 仓库设置指南

## 自动推送（推荐）

由于你的系统没有安装 GitHub CLI，请按照以下步骤手动设置：

### 步骤 1：在 GitHub 上创建仓库

1. 访问 https://github.com/new
2. 仓库名称：`openaiR`
3. 描述：`Complete R implementation of OpenAI Python SDK`
4. 选择 **Public**（公开）
5. **不要** 勾选 "Add a README file"
6. **不要** 勾选 ".gitignore"
7. **不要** 选择许可证
8. 点击 "Create repository"

### 步骤 2：推送代码到 GitHub

创建仓库后，GitHub 会显示推送命令。运行以下命令：

```bash
# 添加远程仓库（将 YOUR-TOKEN 替换为你的 GitHub token）
git remote add origin https://xiaoluolorn:YOUR-TOKEN@github.com/xiaoluolorn/openaiR.git

# 推送到 GitHub
git branch -M main
git push -u origin main
```

### 获取 GitHub Token

1. 访问 https://github.com/settings/tokens
2. 点击 "Generate new token (classic)"
3. 勾选以下权限：
   - `repo` (Full control of private repositories)
   - `workflow` (Update GitHub Action workflows)
4. 生成 token 后，复制并保存到安全位置
5. 在上面的命令中替换 `YOUR-TOKEN`

### 步骤 3：验证推送

推送成功后，访问 https://github.com/xiaoluolorn/openaiR 查看你的代码。

---

## 手动推送（使用 GitHub Desktop）

如果你更喜欢图形界面：

1. 下载并安装 GitHub Desktop: https://desktop.github.com/
2. 登录你的 GitHub 账号
3. 点击 "Add" > "Add Existing Repository"
4. 选择此目录：`C:\Users\luoch\OneDrive\工作\数技经所\1-科研材料\大语言模型与经济学\OpenAI`
5. 点击 "Publish repository"
6. 输入仓库名称 `openaiR`
7. 点击 "Publish"

---

## 后续步骤

### 1. 添加 GitHub Actions CI

创建 `.github/workflows/R-CMD-check.yaml`：

```yaml
on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

name: R-CMD-check

jobs:
  R-CMD-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: r-lib/actions/setup-r@v2
        with:
          r-version: 'release'
      
      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: any::rcmdcheck
          needs: check
      
      - uses: r-lib/actions/check-r-package@v2
```

### 2. 添加 pkgdown 文档网站

```r
# 在 R 中运行
install.packages("pkgdown")
pkgdown::init_github_pages()
pkgdown::build_site()
```

### 3. 提交到 CRAN

在推送并测试完成后，可以准备提交到 CRAN：

```r
# 运行检查
devtools::check()

# 构建
devtools::build()

# 提交到 CRAN
# 访问 https://cran.r-project.org/submit.html
```

---

## 常见问题

### Q: 推送时要求密码怎么办？

A: 使用 Personal Access Token 代替密码：
1. 生成 token（见上文）
2. 密码提示时粘贴 token

### Q: 如何验证 package 可以安装？

A: 推送后，其他人可以通过以下命令安装：

```r
install.packages("remotes")
remotes::install_github("xiaoluolorn/openaiR")
```

### Q: 如何添加贡献者？

A: 在 GitHub 仓库页面：
1. Settings > Collaborators
2. 添加 GitHub 用户名
3. 贡献者将自动出现在 README 中

---

## 联系支持

如有问题，请访问：
- GitHub Docs: https://docs.github.com/
- R Packages: https://r-pkgs.org/
