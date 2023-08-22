#!/opt/homebrew/bin/bash

# 0 | 1
dev_mode=${1:-1}
target_dir=mic-frontend-project

git_url=https://e.coding.net/vite-man/we-project/$target_dir.git
port=3000
projects=(index mysql opengauss)
projects_len=${#projects[*]}
workdir=$(pwd)/qiankun-boot

declare -A port_map
rm -rf ./$target_dir

# https://blog.logrocket.com/build-monorepo-next-js/
# 测试版本
node_version=$(node -v)
yarn_version=$(yarn -v)
lerna_version=$(lerna -v)

echo "              当前版本 测试版本"
echo node version: $node_version v18.16.0
echo yarn version: $yarn_version 3.6.1
echo lerna version: $lerna_version 7.1.0

# https://www.yarnpkg.cn/getting-started/install
# 使用最新node
nvm use v19.1.0

# corepack enable

# corepack prepare yarn@stable --activate

# 初始化项目
if [ $dev_mode == '1' ]
then
  mkdir $target_dir
else
  git clone $git_url
fi

cd $target_dir

# 使用最新 yarn
# yarn init -2

lerna init --independent
git add .
git ci -m "lerna init"

# 公共配置项目
lerna create config -y
# cd packages/config && app_util && cd -

lerna create shared -y
# cd packages/shared && app_util && cd -

git add .
git ci -m "lerna create **"

# 推送到远端分支
if [ $dev_mode == '0' ]
then
  git push --set-upstream origin master
fi

# add apps to workspaces
new_package=$(cat ./package.json | jq 'setpath(["workspaces"]; [.workspaces[], "apps/*"])')
echo $new_package |jq > ./package.json

# # 新增 workspaces
mkdir apps

cd apps

common_app_util(){
  project_name=$1
  port=`expr $port + 1`;
  echo "PORT = "$port > .env
  # new_package=$(cat ./package.json | jq 'setpath(["scripts", "start"]; .scripts.start + " -p '$port'")')
  # echo $new_package |jq > ./package.json
  port_map[$project_name]=$port
  new_package=$(
    cat ./package.json |
    jq 'setpath(["scripts", "start"]; "react-app-rewired start")' |
    jq 'setpath(["scripts", "build"]; "react-app-rewired build")' |
    jq 'setpath(["scripts", "test"]; "react-app-rewired test")' |
    jq 'setpath(["scripts", "eject"]; "react-app-rewired eject")'
  )
  echo $new_package |jq > ./package.json
}

main_app_util(){
  project_name=$1

  config_overrides="
  module.exports = function override(config, env) {\n
    //do stuff with the webpack config...\n
    return config;\n
  }\n
  "
  echo -e $config_overrides > config-overrides.js

  cp -f $workdir/template/entry/index.tsx ./src/
  cp -f $workdir/template/entry/App.tsx ./src/
}

sub_app_util(){
  project_name=$1

  cp -f $workdir/template/sub/index.tsx ./src/
  cp -f $workdir/template/sub/App.tsx ./src/
  cp -f $workdir/template/sub/public-path.js ./src/
  cp -f $workdir/template/sub/config-overrides.js ./
}

app_util(){
  project_name=$1
  is_entry=${2:-0}

  cd $project_name
  common_app_util $project_name

  if (($is_entry == 0))
  then
    main_app_util $project_name
  else
    sub_app_util $project_name
  fi

  gsed -i '1i\@import "~antd/dist/antd.css";' ./src/App.css

  cd -
}

int=0
while(( $int<projects_len ))
do
    project=${projects[$int]}
    echo $project
    echo $(pwd)
    yarn create react-app $project --template typescript
    yarn workspace $project add react-app-rewired react-router-dom antd@^4.24.13
    yarn workspace $project add @babel/plugin-proposal-private-property-in-object -D
    app_util $project $int

    let "int++"
done

yarn workspace ${projects[0]} add qiankun

cd ../
# yarn workspaces list

# 平行启动项目
new_package=$(
  cat ./package.json \
  | jq 'setpath(["scripts", "start"]; "lerna run start --parallel")'\
  | jq 'setpath(["scripts", "build"]; "lerna run build --parallel")'\
  | jq 'setpath(["scripts", "postbuild"]; "rm -rf ./build && mv apps/index/build ./ && mkdir -p ./build/child && mv apps/code-mysql/build ./build/child/code-mysql && mv apps/code-opengauss/build ./build/child/code-opengauss")'\
  | jq 'setpath(["scripts", "nginx:start"]; "$(which nginx) -c $(pwd)/nginx.conf")'\
  | jq 'setpath(["scripts", "nginx:stop"]; "$(which nginx) -s stop")'
)

echo $new_package |jq > ./package.json

gsed -i '1i\build/' ./.gitignore
cp $workdir/template/nginx.conf ./
cp $workdir/template/mime.types ./

git add .
git ci -m "init project"


index=1
mirco_index=11
nginx_index=48
while(( $index<projects_len ))
do
  project=${projects[$index]}

  gsed -i $nginx_index'a\
        location /child/'${project}' {\
            root   html;\
            index  index.html index.htm;\
            try_files $uri $uri/ /child/'${project}'/index.html;\
        }
  ' ./nginx.conf

  gsed -i $mirco_index'a\
  {\
    name: '"'${project}'"',\
    entry: isPro ? '"'/child/${project}/'"' : '"'//localhost:${port_map[${project}]}'"',\
    container: '"'#container'"',\
    activeRule: '"'/${project}'"',\
  },
  ' ./apps/index/src/index.tsx

  let "index++"
  let "mirco_index=mirco_index+6"
  let "nginx_index=nginx_index+6"
done

git add .
git commit -m "qiankun & nginx configuration"