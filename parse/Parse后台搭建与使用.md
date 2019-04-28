# Parse后台搭建与使用

## 什么是Parse？

官网：https://docs.parseplatform.org/

Github：https://github.com/parse-community

- Parse是一个移动后端，最初由提供商Parse Inc开发。该公司于2013年被Facebook收购，并于2017年1月关闭。继2016年宣布即将关闭后，该平台随后开源。 由于托管服务被关闭，Parse Platform已经发展成为一个开源社区，拥有自己的博客，文档和社区论坛。

- Parse是一个基于云端的后端管理平台。对于开发者而言，Parse提供后端的一站式和一揽子服务：服务器配置、数据库管理、API、影音文件存储，实时消息推送、客户数据分析统计、等等。这样，开发者只需要处理好前端/客户端/手机端的开发，将后端放心的交给Parse即可。目前Parse支持超过50万个App。[摘自浅谈 Parse](https://www.jianshu.com/p/d92c5b2380ea)
- Parse可以让一个作为Android/IOS开发的你，不用后台开发人员配合就可以处理后台数据，并且其有专门的用户系统，消息推送功功能等等，而且API简单易用，虽然坑还是有，但是还是一个很值得Android开发者入手的一个框架。

Parse目前支持以下平台语言：

![snap_parse_support](https://github.com/samlss/Summary/blob/master/parse/snap_parse_support.png)



## 服务器搭建

### 环境

- 本人服务器为阿里云CentOs7.4系统服务器
- XShell6

这篇文章仅记录Parse后台搭建与在Android中的使用，更详细的使用介绍如果后面有时间还会总结

**首先在root下创建parse目录，然后进入到parse目录**

## 安装nodejs

```shell
wget https://npm.taobao.org/mirrors/node/v12.0.0/node-v12.0.0-linux-x64.tar.xz
```

版本看你需要什么版本，建议8.0.0以上，Parse后台需要Node4.3以上版本

下载完成后可以看到：

![snap_wget_node](https://github.com/samlss/Summary/blob/master/parse/snap_wget_node.png)

解压

```shell
tar -xvf node-v12.0.0-linux-x64.tar.xz
```

解压后可以看到：

![snap_unzip_node](https://github.com/samlss/Summary/blob/master/parse/snap_unzip_node.png)

将原本压缩文件删除

```shell
rm node-v12.0.0-linux-x64.tar.xz  -f
```

将node-v12.0.0-linux-x64文件夹重新命名为node:

```shell
mv node-v12.0.0-linux-x64/ node
```

现在该目录下为：

![snap_rename_node](https://github.com/samlss/Summary/blob/master/parse/snap_rename_node.png)

进入到node的bin目录，执行以下命令将node和npm设置为全局命令:

```shell
ln -s /root/parse/node/bin/node  /usr/local/bin/node
ln -s /root/parse/node/bin/npm  /usr/local/bin/npm
```

我们 查看 /usr/locl/bin目录可以看到已经成功了：

![snap_node_ln](https://github.com/samlss/Summary/blob/master/parse/snap_node_ln.png)

接着我们可以在终端任何地方通过npm命令下载相关的内容了

## 安装MongoDB

parse服务器后台需要搭配MongoDB，且版本要求为2.6.X，3.0.X，3.2.X

**我们安装3.2.4版本**

首先在parse目录下创建mongodb目录，现在/root/parse目录就有两个目录了：

![snap_parse_dirs](https://github.com/samlss/Summary/blob/master/parse/snap_parse_dirs.png)

进入mongodb目录，输入下载命令下载压缩包：

```shell
wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel70-3.2.4.tgz
```

下载完成后解压：

```
tar -xvf mongodb-linux-x86_64-rhel70-3.2.4.tgz
```

解压完成后删除压缩包：

```shell
rm mongodb-linux-x86_64-rhel70-3.2.4.tgz -f
```



现在目录为：

![snap_mongodb_dir](https://github.com/samlss/Summary/blob/master/parse/snap_mongodb_dir.png)

再执行命令将mongodb-linux-x86_64-rhel70-3.2.4目录所有东西剪切到mongodb目录：

```shell
mv mongodb-linux-x86_64-rhel70-3.2.4/* ./
rm mongodb-linux-x86_64-rhel70-3.2.4/ -rf
```

最后mongodb目录下为：

![snap_mv_mogodb_dir](https://github.com/samlss/Summary/blob/master/parse/snap_mv_mogodb_dir.png)

在mongodb目录创建一个目录data：

```shell
mkdir data
cd data  //进入data目录

//创建两个目录
mkdir db //存放数据文件
mkdir logs //存放日志文件
```

再进入到mongodb的bin目录，可以看到该目录下有以下命令文件：

![snap_mongodb_bin](https://github.com/samlss/Summary/blob/master/parse/snap_mongodb_bin.png)

进入到parse-server/bin目录，执行以下命令将mongo设置为全局命令：

```
ln -s /root/parse/mongodb/bin/mongo /usr/local/bin/mongo
```

在这里我们需要创建一个mongodb的配置文件(怎么创建文件不用说了吧😉):

```shell
dbpath = /root/parse/mongodb/data/db
logpath = /root/parse/mongodb/data/logs/mongodb.log
port = 27017
fork = true
logappend=true
```

- dbpath：设置数据文件存放目录
- logpath：设置日志文件的存放目录及其日志文件名 
- port：设置端口号（默认为27017）
- fork：设置为以守护进程的方式运行，即在后台运行 
- logappend：开启日志追加添加日志

启动mongodb

```shell
./mongod --config mongodb.conf 

//下面为成功后的返回
[root@izj6c0bdyow5dsyv3ptlfez bin]# ./mongod --config mongodb.conf 
about to fork child process, waiting until server is ready for connections.
forked process: 1696
child process started successfully, parent exiting
```

输入命令查看端口：

```shell
netstat -tunpl
```

可以看到mongodb已经启动且在监听27017端口：

![snap_mongodb_start](https://github.com/samlss/Summary/blob/master/parse/snap_mongodb_start.png)

最后在浏览器输入：

```js
http://{你的服务器ip}:27017/
```



可以看到以下信息：

![snap_mongodb_connect](https://github.com/samlss/Summary/blob/master/parse/snap_mongodb_connect.png)

**注意：**如果你用的服务器需要配置网络安全组的话，请到添加一个27017端口的网络安全组，否则该端口没有访问权限。且测试完之后最好关闭该端口的外网访问权限，否则端口有可能被攻击。曾经本人团队由于服务器开启了27017端口的外网访问权限，导致数据库被黑，要给黑客钱才能拿回旧数据，所幸当时处于测试阶段，造成不了什么损失。

## 安装Parse后台

可在任何目录下执行安装parse-server命令：

```shell
npm install -g parse-server
```

最后会下载在/root/parse/node/lib/node_modules目录下：

![snap_parse_server_install](https://github.com/samlss/Summary/blob/master/parse/snap_parse_server_install.png)

进入到parse-server/bin目录，执行以下命令将parse-server设置为全局命令：

```shell
ln -s /root/parse/node/lib/node_modules/parse-server/bin/parse-server /usr/local/bin/parse-server
```

然后启动parse后台服务：

```shell
parse-server --appId APPLICATION_ID --masterKey MASTER_KEY --databaseURI mongodb://localhost/parse &
```

- mongodb://localhost/parse 配置在mongodb的parse数据库下
- & 代表让parse-server在后台运行，不阻塞当前终端

执行成功后可以看到以下信息：

![snap_parse_server_start_success](https://github.com/samlss/Summary/blob/master/parse/snap_parse_server_start_success.png)

我们可以执行mongo命令查看数据库：

```
mongo
> show dbs
```



![snap_mongodb_parse_db](https://github.com/samlss/Summary/blob/master/parse/snap_mongodb_parse_db.png)



## 安装Parse管理面板

执行以下命令安装管理面板

```shell
npm install -g parse-dashboard
```

会下载在/root/parse/node/lib/node_modules目录下：

![snap_parse_dashboard_download](https://github.com/samlss/Summary/blob/master/parse/snap_parse_dashboard_download.png)

进入到parse-dashboard/bin目录，创建配置文件parse-dashboard.conf(可随便命名)：

```shell
{
  "apps": [
    {
      "serverURL": "http://localhost:1337/parse",
      "appId": "myappid",
      "masterKey": "myappkey",
      "appName": "MyApp"
    }
  ],
  "users": [
    {
      "user":"admin",
      "pass":"admin"
    }
  ]
}
```

- serverURL：parse服务器地址
- appid：你的应用id
- masterKey：你的应用的masterKey
- appName：应用名称
- users：管理面板的登录账号

关于配置文件，目前上面例子只是一个最简单的单个app管理面板，更多相关配置可以看：https://github.com/parse-community/parse-dashboard

启动parse-dashboard服务：

```
./parse-dashboard --config parse-dashboard.conf --allowInsecureHTTP &
```

- allowInsecureHTTP：允许远程访问http协议的管理面板
- & 后台启动，不阻塞当前终端进程

成功后会提示：

```shell
ln -s /root/parse/node/lib/node_modules/parse-dashboard/bin/parse-dashboard /usr/local/bin/parse-dashboard
```

![snap_parse_dashboard_start_success](https://github.com/samlss/Summary/blob/master/parse/snap_parse_dashboard_start_success.png)

阿里云这边需要开启安全组允许外网4040端口：

![snap_safety_port](https://github.com/samlss/Summary/blob/master/parse/snap_safety_port.png)



最后，在浏览器输入

```javascript
http://{你的服务器ip}:4040/
```



可以看到以下内容证明配置成功：

![snap_parse_dashboard_login](https://github.com/samlss/Summary/blob/master/parse/snap_parse_dashboard_login.png)

![snap_parse_dash_board_details](https://github.com/samlss/Summary/blob/master/parse/snap_parse_dash_board_details.png)

## 安装总结

主要需要四步:

1. 安装nodejs
2. 安装mongodb
3. 安装parse-server
4. 安装pase-dashboard



## 使用问题

我们在终端调用命令：

```shell
parse-server ... //启动parse服务
parse-dashboard ... //启动管理面板服务
```

启动parse服务和管理面板服务后，一旦关闭终端，我这里是关闭XShell6，再输入管理面板的ip+端口会发现无法访问，重新连接XShell会发现parse-server进程和parse-dashboard进程都被杀掉了。后面发现，仅仅通过&无法保证在终端中创建的进程不被杀掉，可以通过&+()方式，或者setsid将命令提交后不受本地终端关闭影响。

[Linux 技巧：让进程在后台可靠运行的几种方法](https://www.ibm.com/developerworks/cn/linux/l-cn-nohup/)

## Android端代码

在root build.gradle文件添加：

```java
allprojects {
	repositories {
		...
		maven { url "https://jitpack.io" }
	}
}
```

在你项目例如app下的build.gradle添加：

```java
dependencies {
    implementation "com.github.parse-community.Parse-SDK-Android:parse:1.20.0"
}
```

创建一个用户类：

```java
@ParseClassName("user")
public class UserObject extends ParseObject {
    public static String USER_ID = "user_id";
    public static String USER_NAME = "user_name";

    public void setUserId(String userId){
        if (userId != null){
            put(USER_ID, userId);
        }
    }

    public String getUserId() {
        return getString(USER_ID);
    }

    public void setUserName(String userName) {
        if (userName != null){
            put(USER_NAME, userName);
        }
    }

    public String getUserName() {
        return getString(USER_NAME);
    }
}
```

- ParseClassName注释：类似于数据库中的表名，数据库中会有一个类与当前类匹配

初始化：

```java
ParseObject.registerSubclass(UserObject.class);
Parse.initialize(new Parse.Configuration.Builder(this)
      .applicationId("YOUR_APP_ID")
      // if defined
      .clientKey("YOUR_CLIENT_KEY")
      .server("http://{YOUR_SERVER_IP}:1337/parse/")
      .build()
    );
```

- ParseObject.registerSubclass：该类只有经过注册了才能使用，会联系parse数据库的user类

插入数据：

```java
UserObject userObject = new UserObject();
userObject.setUserId("10000");
userObject.setUserName("SamLeung");
userObject.saveInBackground(new SaveCallback() {
    @Override
    public void done(ParseException e) {
        Log.e("TAG", "save user done: " + e != null ? "success" : e.getMessage());
    }
});
```

- e为null则代表无异常，保存成功
- e不为null则代表异常，保存失败

执行后可以在DashBoard中看到保存的内容：

![snap_android_sdk_save_success](https://github.com/samlss/Summary/blob/master/parse/snap_android_sdk_save_success.png)



更多Android端API可参考：https://docs.parseplatform.org/android/guide/