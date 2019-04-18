# 关于protobuf和记录在Android中使用Protobuf过程



## 关于protobuf

Github：https://github.com/protocolbuffers/protobuf

官网：https://developers.google.com/protocol-buffers/  (需翻墙)

### 什么是protobuf?

```
Protocol buffers are Google's language-neutral, platform-neutral, extensible mechanism for serializing structured data – think XML, but smaller, faster, and simpler. You define how you want your data to be structured once, then you can use special generated source code to easily write and read your structured data to and from a variety of data streams and using a variety of languages.
```

译：protocal buffers 是谷歌一款跨语言，跨平台，用于序列化结构数据的可扩展机制。类似于xml，但protobuf更小，更快，更简单。 使用者可以定义数据结构，然后使用特殊生成的源代码轻松地将结构化数据写入和读取各种数据流，并支持使用各种语言。

**Protocol buffers 很适合做数据存储或 RPC 数据交换格式。可用于通讯协议、数据存储等领域的语言无关、平台无关、可扩展的序列化结构数据格式**。

------

### 应用场景：

- 数据通信：使用protobuf序列化数据后，经过其压缩之后数据变得更小，有利于加快数据传输和节省流量，特别是在大数据量的情况下。且支持多语言，在各种服务器与应用的交互中都可以使用。
- 数据存储：同样是由于其出色的序列化速度和数据压缩能力，可将protobuf用于可持续数据存储，例如将数据存储在磁盘中。

### protobuf性能分析

关于protobuf的性能分析，这篇文章概述得很详细：[Protobuf 有没有比 JSON 快 5 倍？](https://www.infoq.cn/article/json-is-5-times-faster-than-protobuf)

这篇文章统计了目前市面上最常用的几种序列化数据结构的库，从源码角度通过对比整数、浮点数、字符串，来得出序列化和反序列化的效率对比。这篇文章主要强调一个关键字，就是速度。但是在速度的基础上，还要考虑一个就是空间使用率即内存使用率，protobuf利用varint 原理压缩数据之后，二进制数据会非常紧凑，所以其体积会更小，但是并没有做到极限压缩。总结一句话：protobuf效率总体来说较快，序列化后数据变得更小，并且其实跨平台，跨语言，无歧义IDL。

理性对比protobuf序列化速度，因为protobuf的优势远远不止于此。

### protobuf原理

[Protocol Buffer 序列化原理大揭秘 - 为什么Protocol Buffer性能这么好？](https://blog.csdn.net/carson_ho/article/details/70568606)

### protobuf优缺点

protocol buffers 在序列化方面，与 XML 相比，有诸多优点：

- 更加简单
- 数据体积小 3 - 10 倍
- 更快的反序列化速度，提高 20 - 100 倍
- 可以自动化生成更易于编码方式使用的数据访问类

缺点：可读性，xml和json都是可读的，但是protobuf以二进制方式储存，除非有定义的.proto文件，否则无法从直接读取protobuf文件，这里不包括破解情况。

## Gradle插件

Google提供了Android Studio可使用的插件：https://github.com/google/protobuf-gradle-plugin

在android项目下的build.gradle文件添加如下内容：

```java
buildscript {
    repositories {
        mavenCentral()
    }
    dependencies {
        classpath 'com.google.protobuf:protobuf-gradle-plugin:0.8.8'
    }
}
```

要求最低的Gradle版本为3.0，jdk为1.8。

### 创建.proto文件
在app module下创建protobufs目录：

![snap_protobuf_dir](https://github.com/samlss/Summary/blob/master/protobuf/snap_protobuf_dir.png)

在protobufs目录下创建一个文件addressbook.proto(官方java例子)：

```protobuf
//指定用哪个版本的语法，不指明的话是v2
//目前proto有两个版本，分别是v2，v3
//这里暂不展开两个版本的差异性
//后面放两个版本的链接Language Guide (proto2/3)需翻墙
syntax = "proto2"; 

//防止不同项目之间命名冲突，在android中，若指定package
//而不指定java_package = "com.example.tutorial"的话，
//则只会生成包tutorial
//若同时指定了java_package = "com.example.tutorial"的话，
//则以java_package定义的为准
package tutorial; 

option java_package = "com.example.tutorial";  //指定java类详细包名
option java_outer_classname = "AddressBookProtos"; //指定java类的类名

//message用于定义一个数据结构，类似于C/C++中struct关键字
//每个结构体是一个message，message之间可以互相引用
message Person {
    required string name = 1;
    required int32 id = 2; 
    optional string email = 3; 
	
    enum PhoneType {
        MOBILE = 0;
        HOME = 1;
        WORK = 2;
    }

    message PhoneNumber {
        required string number = 1; 
        optional PhoneType type = 2 [default = HOME]; 
    }

    repeated PhoneNumber phones = 4;
}

message AddressBook {
    repeated Person people = 1;
}
```

proto两个语法版本链接(需翻墙)：

- [Language Guide (proto2)](https://developers.google.com/protocol-buffers/docs/proto)
- [Language Guide (proto3)](https://developers.google.com/protocol-buffers/docs/proto3)



修饰符说明：

```protobuf
required：必须初始化该字段，否则该消息将被视为“未初始化”。尝试构建未初始化的消息将抛出RuntimeException,解析未初始化的消息将抛出IOException。

optional：可初始化字段，如果未初始化字段，则使用默认值。 对于简单类型，您可以指定自己的默认值，就像上面PhoneNumber数据体一样，默认为1。 否则，使用系统默认值：数字类型为0，字符串为空字符串，bools为false。 对于嵌入式message，默认值始终是message的“默认实例”或“原型”.

repeated：在java对应list，size可为0，即可不初始化。
```



我们看到上面每个结构体的字段都有一个值，例如 = 1、2、3、4等等，其意思是会将该值作为字段的唯一标识号(tag) ，用于匹配每个字段。

例如如下例子：

```protobuf
 message Datum {
  optional int32 channels = 1;
  optional int32 height = 2;
  optional int32 width = 3;
  optional bytes data = 4;
  optional int32 label = 5;
  repeated float float_data = 6;
}

message BlobProto {
  optional int32 num = 1 [default = 0];
  optional int32 channels = 2 [default = 0];
  optional int32 height = 3 [default = 0];
  optional int32 width = 4 [default = 0];
}
```

每个字段都相差1。

更详细可参考：[protobuf为什么那么快](https://www.jianshu.com/p/72108f0aefca)




### 插件配置
指定插件路径后我们需要在对应的module中使用插件，例如在app下的build.gradle文件添加如下内容：

```java
apply plugin: 'com.android.application'  // 或者 'com.android.library'
apply plugin: 'com.google.protobuf' //指定应用protobuf插件

dependencies {
    //提供给Android用的protobuf库
    implementation 'com.google.protobuf:protobuf-lite:3.0.0'
}

android {
    //指定那些源文件要被编译
    sourceSets {
        main {
            //首先是java文件，在src/main/java目录下的所有java文件都要被编译
            java {
                srcDirs 'src/main/java'
            }
		   
            //然后是要编译的.proto文件，例如app/protobufs目录
            proto {
                srcDirs 'protobufs/'
            }
        }
    }
}

protobuf {
    //配置protoc编译器，对应平台的可执行文件
    protoc {
        //从仓库下载
        artifact = 'com.google.protobuf:protoc:3.0.0'

        //也可以指定本地的命令路径
        //path = '/usr/local/bin/protoc'
    }

    //使用的插件
    plugins {
        //生成java文件的插件javalite
        //推荐使用JavaLite版本，根据官方文档，JavaLite生成的文件小，并且对混淆的支持更好
        javalite {
            artifact = 'com.google.protobuf:protoc-gen-javalite:3.0.0'
        }
    }

    //生成proto相关java文件的gradle任务
    generateProtoTasks {
        all().each { task ->
            task.builtins {
                remove java
            }
            //使用javalite插件生成.proto定义的java文件
            task.plugins {
                javalite { }
            }
        }
    }
}

```

然后再build一下或者make，会自动生成以下文件：

![snap_protobuf_generate_java](https://github.com/samlss/Summary/blob/master/protobuf/snap_protobuf_generate_java.png)



### 使用代码

#### wirte

```java
AddressBookProtos.Person.PhoneNumber phoneNumber = AddressBookProtos.Person.PhoneNumber.newBuilder()
                .setType(AddressBookProtos.Person.PhoneType.MOBILE)
                .setNumber("138888888")
                .build();

AddressBookProtos.Person person = AddressBookProtos.Person.newBuilder()
		.setId(1)
		.addPhones(phoneNumber)
		.setName("张三")
		.build();

AddressBookProtos.AddressBook addressBook = AddressBookProtos.AddressBook.newBuilder()
		.addPeople(person)
		.build();

try {
	File file = new File(getFilesDir().getPath(), "proto");
	FileUtils.createDirIfNotExists(file.getParent());
	IoUtils.writeFileFromBytesByChannel(file, addressBook.toByteArray(), true);
}catch (Exception e){
	e.printStackTrace();
}
```



用Notepad查看文件：

![snap_write_protobuf_into_file](https://github.com/samlss/Summary/blob/master/protobuf/snap_write_protobuf_into_file.png)

可以看到能看到部分内容，但是可读性很差。



read

```java
FileInputStream fileInputStream = null;
try {
	//read
	File file = new File(getFilesDir().getPath(), "proto");
	fileInputStream = new FileInputStream(file);
	AddressBookProtos.AddressBook addressBook = AddressBookProtos.AddressBook.parseFrom(fileInputStream);
	AddressBookProtos.Person person = addressBook.getPeople(0);
	Log.e("proto", "person id: "+person.getId());
	Log.e("proto", "person name: "+person.getName());

	AddressBookProtos.Person.PhoneNumber phoneNumber = person.getPhones(0);
	Log.e("proto", "phone number: "+phoneNumber.getNumber());
	Log.e("proto", "phone type: "+phoneNumber.getType());
}catch (Exception e){
	e.printStackTrace();
}finally {
	if (fileInputStream != null){
		try {
			fileInputStream.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
}
```

打印内容：

![snap_read_proto_result](https://github.com/samlss/Summary/blob/master/protobuf/snap_read_proto_result.png)