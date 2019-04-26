# Parse后台搭建与使用

## 什么是Parse？

官网：https://docs.parseplatform.org/

Github：https://github.com/parse-community

Parse是一个移动后端，最初由提供商Parse Inc开发。该公司于2013年被Facebook收购，并于2017年1月关闭。继2016年宣布即将关闭后，该平台随后开源。 由于托管服务被关闭，Parse Platform已经发展成为一个开源社区，拥有自己的博客，文档和社区论坛。

Parse是一个基于云端的后端管理平台。对于开发者而言，Parse提供后端的一站式和一揽子服务：服务器配置、数据库管理、API、影音文件存储，实时消息推送、客户数据分析统计、等等。这样，开发者只需要处理好前端/客户端/手机端的开发，将后端放心的交给Parse即可。目前Parse支持超过50万个App。[浅谈 Parse](https://www.jianshu.com/p/d92c5b2380ea

Parse目前支持以下平台语言：

![snap_parse_support](C:\Users\Administrator\Desktop\parse\snap_parse_support.png)



## 服务器配置

**本人服务器为阿里云CentOs7.4系统服务器**

这篇文章仅记录parse后台搭建与在Android中的使用，更详细的使用如果后面有时间还会总结

首先在root下创建parse目录，然后进入到parse目录

## 安装nodejs

```shell
wget https://npm.taobao.org/mirrors/node/v12.0.0/node-v12.0.0-linux-x64.tar.xz
```

版本看你需要什么版本，建议8.0.0以上，parse后台需要Node4.3以上版本

下载完成后可以看到：

![snap_wget_node](C:\Users\Administrator\Desktop\parse\snap_wget_node.png)

解压

```shell
tar -xvf node-v12.0.0-linux-x64.tar.xz
```

解压后可以看到：

![snap_unzip_node](C:\Users\Administrator\Desktop\parse\snap_unzip_node.png)

将原本压缩文件删除

```shell
rm node-v12.0.0-linux-x64.tar.xz  -f
```

将node-v12.0.0-linux-x64文件夹重新命名为node:

```shell
mv node-v12.0.0-linux-x64/ node
```

现在该目录下为：

![snap_rename_node](C:\Users\Administrator\Desktop\parse\snap_rename_node.png)

进入到node的bin目录，执行以下命令将node和npm设置为全局命令:

```shell
ln -s /root/parse/node/bin/node  /usr/local/bin/node
ln -s /root/parse/node/bin/npm  /usr/local/bin/npm
```

我们 查看 /usr/locl/bin目录可以看到已经成功了：

![snap_node_ln](C:\Users\Administrator\Desktop\parse\snap_node_ln.png)

接着我们可以通过npm命令下载相关的内容了

## 安装MongoDB

parse服务器后台需要搭配MongoDB，且版本要求为2.6.X，3.0.X，3.2.X

**这里我们取3.2.4**

首先在parse目录下创建mongodb目录，现在/root/parse目录就有两个目录了：

![snap_parse_dirs](C:\Users\Administrator\Desktop\parse\snap_parse_dirs.png)

进入mongodb目录，输入下载命令：

```shell
wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel70-3.2.4.tgz
```



解压

```
tar -xvf mongodb-linux-x86_64-rhel70-3.2.4.tgz
```



删除压缩包

```shell
rm mongodb-linux-x86_64-rhel70-3.2.4.tgz -f
```



现在目录为：

![snap_mongodb_dir](C:\Users\Administrator\Desktop\parse\snap_mongodb_dir.png)

再执行命令将mongodb-linux-x86_64-rhel70-3.2.4目录所有东西剪切到mongodb目录：

```shell
mv mongodb-linux-x86_64-rhel70-3.2.4/* ./
rm mongodb-linux-x86_64-rhel70-3.2.4/ -rf
```

最后为：

![snap_mv_mogodb_dir](C:\Users\Administrator\Desktop\parse\snap_mv_mogodb_dir.png)

在mongodb目录创建一个目录data：

```shell
mkdir data
cd data  //进入data目录

//创建两个目录
mkdir db //存放数据文件
mkdir logs //存放日志文件
```



再进入到mongodb的bin目录，可以看到该目录下有以下命令文件：

![snap_mongodb_bin](C:\Users\Administrator\Desktop\parse\snap_mongodb_bin.png)



在这里我们需要创建一个mongodb的配置文件:

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
- auth=true：启用验证  

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



进入到parse-server/bin目录，执行以下命令将mongo设置为全局命令：

```shell
ln -s /root/parse/mongodb/bin/mongo /usr/local/bin/mongo
```



可以看到mongodb已经启动：

![snap_mongodb_start](C:\Users\Administrator\Desktop\parse\snap_mongodb_start.png)

最后在浏览器输入：

```js
http://{你的服务器ip}:27017/
```



可以看到以下信息：

![snap_mongodb_connect](C:\Users\Administrator\Desktop\parse\snap_mongodb_connect.png)

注意，如果你用的服务器需要配置网络安全组的话，请到添加一个27017端口的网络安全组，否则该端口没有访问权限。



## 安装parse后台

可在任何目录下执行安装parse-server命令：

```shell
npm install -g parse-server
```

会下载在/root/parse/node/lib/node_modules目录下：

![snap_parse_server_install](C:\Users\Administrator\Desktop\parse\snap_parse_server_install.png)

进入到parse-server/bin目录，执行以下命令将parse-server设置为全局命令：

```shell
ln -s /root/parse/node/lib/node_modules/parse-server/bin/parse-server /usr/local/bin/parse-server
```



然后开启parse后台服务：

```shell
parse-server --appId APPLICATION_ID --masterKey MASTER_KEY --databaseURI mongodb://localhost/parse &
```

- mongodb://localhost/parse 配置在mongodb的parse数据库下
- & 代表让parse-server在后台运行，不阻塞当前终端

执行成功后可以看到以下信息：

![snap_parse_server_start_success](C:\Users\Administrator\Desktop\parse\snap_parse_server_start_success.png)



我们可以执行mongo命令查看数据库：

```
mongo
> show dbs
```



![snap_mongodb_parse_db](C:\Users\Administrator\Desktop\parse\snap_mongodb_parse_db.png)



## 安装Parse管理面板

执行以下命令安装管理面板

```shell
npm install -g parse-dashboard
```

会下载在/root/parse/node/lib/node_modules目录下：

![snap_parse_dashboard_download](C:\Users\Administrator\Desktop\parse\snap_parse_dashboard_download.png)

进入到parse-dashboard/bin目录，创建配置文件parse-dashboard.conf：

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

启动parse-dashboard：

```
./parse-dashboard --config parse-dashboard.conf --allowInsecureHTTP &
```

- allowInsecureHTTP：允许远程访问http协议的管理面板

成功后会提示：

```shell
ln -s /root/parse/node/lib/node_modules/parse-dashboard/bin/parse-dashboard /usr/local/bin/parse-dashboard
```



然后启动管理面板：

parse-server --appId APPLICATION_ID --masterKey MASTER_KEY --databaseURI mongodb://localhost/parse &

![snap_parse_dashboard_start_success](C:\Users\Administrator\Desktop\parse\snap_parse_dashboard_start_success.png)



阿里云这边需要开启安全组允许外网4040端口：

![snap_safety_port](C:\Users\Administrator\Desktop\parse\snap_safety_port.png)



最后，在浏览器输入

```javascript
http://{你的服务器ip}:4040/
```



可以看到以下内容证明配置成功：

![snap_parse_dashboard_login](C:\Users\Administrator\Desktop\parse\snap_parse_dashboard_login.png)

![snap_parse_dash_board_details](C:\Users\Administrator\Desktop\parse\snap_parse_dash_board_details.png)

## 安装总结

主要需要四步:

1. 安装nodejs
2. 安装mongodb
3. 安装parse-server
4. 安装pase-dashboard

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

![snap_android_sdk_save_success](C:\Users\Administrator\Desktop\parse\snap_android_sdk_save_success.png)



更多Android端API可参考：https://docs.parseplatform.org/android/guide/