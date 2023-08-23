# https://blog.logrocket.com/build-monorepo-next-js/
# 测试版本
node_version=$(node -v)
yarn_version=$(yarn -v)
lerna_version=$(lerna -v)

echo "              当前版本 测试版本"
echo node version: $node_version v18.16.0
echo yarn version: $yarn_version v3.6.1
echo lerna version: $lerna_version v7.1.0

nvm use v19.1.0