# 安装NodeJS
```bash
nvm install v6
nvm use v6
```
# Python 2.7
# 安装依赖
- MacOS
```
CXXFLAGS="-mmacosx-version-min=10.9" LDFLAGS="-mmacosx-version-min=10.9" npm install
```
- Linux
```
npm install
```
# 打包
```
npm run webpack
```
# 启动
```bash
COCO_PORT=3001 COCO_MONGO_HOST=9.134.230.19 COCO_MONGO_ANALYTICS_HOST=9.134.230.19 npm run nodemon
```