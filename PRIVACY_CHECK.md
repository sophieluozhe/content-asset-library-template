# 发布前隐私检查

开源版采用白名单复制，不从私有工作库整体复制后再删除内容。

每次提交前：

1. 先运行 `git add -A`，再执行 `pwsh -NoProfile -File scripts/check_release.ps1 -RepositoryPath .`。
2. 确认检查命令返回 `0`。
3. 运行 `git status --short`，确认没有原始材料、附件或 Obsidian 配置。
4. 运行 `git diff --cached`，逐文件人工检查：没有真实姓名、机构、账号、联系方式、发布链接、日期、反馈或业务数据。
5. 再进行提交或推送。

自动检查不能代替人工复核。任何拿不准是否可公开的内容，都不要提交。

检查器只读取 Git 暂存区：白名单为空、出现未白名单文件、`.obsidian`、软链接、子模块、含 NUL 字节文件，或缺少“虚构演示”标记的演示 Markdown，都会拒绝通过。
