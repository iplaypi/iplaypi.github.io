---
title: 使用 Java 代码迁移微博图床到 GitHub 图床
id: 2019050201
date: 2019-05-02 02:12:24
updated: 2019-05-03 02:12:24
categories: 建站
tags: [weibo,GitHub,image]
keywords: weibo,GitHub,image
---


由于微博图床开启了防盗链，导致我的博客里面的图片全部不可见，因此要切换图床。当然，一开始我使用的是极其简单的方法，直接设置博客页面的 **referer** 属性即可【设置为 noreferrer】，这样微博图床就检测不到引用来源，也就不会拒绝访问了。但是后续又遇到了其它问题，这些内容我在前几天的博客里面都记录了：[解决微博图床防盗链的问题](https://www.playpi.org/2019042701.html) 。后来我实在找不到更为恰当的解决方案，于是决定直接迁移图床。本来一开始准备使用 PicGo 这个工具，但是发现有问题，在我比较着急的情况下，决定自己写一写代码，完成迁移操作。本文就记录这些代码的逻辑。


<!-- more -->


# 依赖构件


为了减少代码量，精简代码，需要引入几个第三方 jar 包，当然不引入也行，如果不引入有一些繁琐而又简单的业务逻辑需要自己实现，有点浪费时间了。

主要要依赖几个 jar 包：处理文件的 io 包、处理网络请求的 httpclient 包、处理 git 的 jgit 包，pom.xml 配置文件内容如下：

```
<dependency>
    <groupId>org.apache.commons</groupId>
    <artifactId>commons-io</artifactId>
    <version>1.3.2</version>
</dependency>
<dependency>
    <groupId>org.apache.httpcomponents</groupId>
    <artifactId>httpclient</artifactId>
    <version>4.5.6</version>
</dependency>
<dependency>
    <groupId>org.eclipse.jgit</groupId>
    <artifactId>org.eclipse.jgit</artifactId>
    <version>4.8.0.201706111038-r</version>
</dependency>
```


# 代码结构


写代码也比较简单，主要有四个步骤：读取 markdown 文件内容并利用正则抽取微博图床的图片链接、下载所有图片并上传至 GitHub、替换内容中抽取出的所有图片链接为 GitHub 的图片链接、内容写回新文件。

使用 Java 处理不需要多少代码，大概有不到200行代码，真正的业务逻辑代码更少，当然，关于网络请求的部分还是不够精简，目前我觉得能用就行。代码放在 GitHub 上面，仅供参考：[https://github.com/iplaypi/startcore.git](https://github.com/iplaypi/startcore.git) ，搜索 **MigratePic** 类即可。

代码主体调用

```
public static void main(String[] args) {
    //        String dir = "e:\baktest";
    //        String outDir = "e:\baktest-out";
    String dir = "e:\bak";
    String outDir = "e:\bak-out";
    Set<File> fileSet = getAllFiles(dir);
    LOGGER.info("====文件个数:" + fileSet.size());
    for (File file : fileSet) {
        try {
            // 1-读取文件,抽取微博图床的链接与图片名称
            String content = FileUtils.readFileToString(file, "utf-8");
            Map<String, String> imgMap = extractImg(content);
            // 2-下载图片并上传至 GitHub
            Map<String, String> urlMap = uploadGithub(imgMap);
            // 3-替换所有链接
            content = replaceUrl(content, urlMap);
            // 4-内容写回新文件
            String outFile = outDir + File.separator + file.getName();
            FileUtils.writeStringToFile(new File(outFile), content, "utf-8");
            LOGGER.info("====处理文件完成:{},获取新浪图床链接个数:{},上传 GitHub 个数:{}", file.getAbsolutePath(), imgMap.size(), urlMap.size());
        }
        catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

需要指定输入、输出目录。

截图如下
![代码主体调用](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190504004133.png "代码主体调用")

其中，**getAllFiles** 方法是获取指定目录的所有文件：

```
/**
     * 获取指定文件夹内的所有文件
     *
     * @param dir
     * @return
     */
private static Set<File> getAllFiles(String dir) {
    Set<File> fileSet = new HashSet<>();
    File file = new File(dir + File.separator);
    for (File textFile : file.listFiles()) {
        fileSet.add(textFile.getAbsoluteFile());
    }
    return fileSet;
}
```

在代码的细节中，可以看到我是每个文件单独处理的，比较耗时间的就是下载图片、上传到 GitHub 这两个过程，而且由于我是文件分开处理，所以总的时间更长了。如果想节约点时间，可以一次性把所有的图片全部下载完成，最后一次提交到 GitHub 即可，这样就节约了多次频繁地与 GitHub 建立连接、断开连接所消耗的时间，如果是几次提交无所谓，但是几十次提交就多消耗很多时间了。例如按照我这个量，78个文件，500-600张图片，运行程序消耗了十几分钟，但是我估计如果一次性处理完成，时间应该在5分钟以内。

接下来分别描述四个步骤。

## 读取文件抽取图片链接

markdown 文件其实也就是普通的文本文件，没有特殊的格式，这就给程序处理带来了极大方便，直接使用工具包读取就行。此外，抽取微博图床的图片链接需要使用正则表达式，代码内容如下：

```
private static Pattern PATTERN = Pattern.compile("https://[0-9a-zA-Z]{3}\.sinaimg\.cn/large/[0-9a-zA-Z]{8,50}\.jpg");
/**
     * 抽取微博图床的图片链接与图片文件名
     *
     * @param string
     * @return
     */
private static Map<String, String> extractImg(String string) {
    Map<String, String> imgMap = new HashMap<>();
    Matcher matcher = PATTERN.matcher(string);
    while (matcher.find()) {
        String oldUrl = matcher.group();
        int index = oldUrl.lastIndexOf("/");
        if (0 < index) {
            String imgName = oldUrl.substring(index + 1);
            imgMap.put(oldUrl, imgName);
        }
    }
    return imgMap;
}
```

这里列举一个图片链接的例子：
https://ws1.sinaimg.cn/large/b7f2e3a3gy1g2hlkwnfm9j214a0hr75v.jpg 。

## 下载图片并上传新图床

这是一个很重要的步骤，需要把上一个步骤完成后获取到的图片下载下来，并且提交到 GitHub 上面去【提交可以不使用代码，直接手动提交也行】，然后获取新图片链接。

为了完成这个步骤，需要先在 GitHub 上面新建一个项目，专门用来存放图片，然后把这个项目 clone 到本地，用来存放下载的图片，最后直接提交即可。

下载图片并提交到 GitHub：

```
private static String githubUrl = "https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/";
/**
     * 提交本地的图片到 GitHub,并拼接新的图片链接
     *
     * @param imgMap
     * @return
     */
private static Map<String, String> uploadGithub(Map<String, String> imgMap) {
    String imgDir = "E:\img\img-playpi\img\old\";
        Map<String, String> urlMap = new HashMap<>();
        for (Map.Entry<String, String> entry : imgMap.entrySet()) {
            String oldUrl = entry.getKey();
            String imgName = entry.getValue();
            boolean isSuc = downloadImg(oldUrl, imgDir, imgName);
            if (isSuc) {
                String newUrl = githubUrl + imgName;
                urlMap.put(oldUrl, newUrl);
            }
        }
        LOGGER.info("====开始上传文件到 GitHub, size: {}", urlMap.size());
        // 统一上传到 GitHub,这一步骤可以省略,留到最后手动提交即可
        boolean gitSuc = JGitUtil.commitAndPush("add and commit by Java client,img size: " + urlMap.size());
        if (!gitSuc) {
            urlMap.clear();
        }
        return urlMap;
    }
```

注意下载图片需要指定本地项目的路径，方便提交到 GitHub，例如我这里是 **E:\img\img-playpi\img\old\\**，拼接 GitHub 的图片链接时需要指定固定的域名部分、用户名、分支名、子目录，例如我这里是：
**https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/ **。

这里列举一个 GitHub 图片链接的例子：
https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/20190502183444.png 。

下载图片的详细逻辑：

```
/**
     * 下载图片到指定的文件目录
     */
public static Boolean downloadImg(String url, String dir, String fileName) {
    Boolean isSuc = false;
    HttpClient httpclient = null;
    int retry = 5;
    while (0 < retry--) {
        try {
            httpclient = new DefaultHttpClient();
            HttpGet httpget = new HttpGet(url);
            httpget.setHeader("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.1 (KHTML, like Gecko) Chrome/21.0.1180.79 Safari/537.1");
            httpget.setHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8");
            HttpResponse resp = httpclient.execute(httpget);
            if (HttpStatus.SC_OK == resp.getStatusLine().getStatusCode()) {
                HttpEntity entity = resp.getEntity();
                InputStream in = entity.getContent();
                isSuc = savePicToDisk(in, dir, fileName);
                return isSuc;
            }
        }
        catch (Exception e) {
            e.printStackTrace();
            LOGGER.error("!!!!下载失败,重试一次");
        }
        finally {
            httpclient.getConnectionManager().shutdown();
        }
    }
    return isSuc;
}

/**
     * 根据输入流,保存内容到指定的目录文件
     *
     * @param in
     * @param dirPath
     * @param filePath
     */
private static Boolean savePicToDisk(InputStream in, String dirPath, String filePath) {
    try {
        File dir = new File(dirPath);
        if (dir == null || !dir.exists()) {
            dir.mkdirs();
        }
        // 拼接文件完整路径
        String realPath = dirPath.concat(filePath);
        File file = new File(realPath);
        if (file == null || !file.exists()) {
            file.createNewFile();
        }
        FileOutputStream fos = new FileOutputStream(file);
        byte[] buf = new byte[1024];
        int len = 0;
        while ((len = in.read(buf)) != -1) {
            fos.write(buf, 0, len);
        }
        fos.flush();
        fos.close();
        return true;
    }
    catch (IOException e) {
        e.printStackTrace();
        LOGGER.error("!!!!写入文件失败");
    }
    finally {
        try {
            in.close();
        }
        catch (IOException e) {
            e.printStackTrace();
        }
    }
    return false;
}
```

提交图片到 GitHub 的代码：

```
    /**
     * 提交并推送代码至远程服务器
     *
     * @param desc 提交描述
     * @return
     */
    public static boolean commitAndPush(String desc) {
        boolean commitAndPushFlag = false;
        try (Git git = Git.open(new File(LOCAL_REPOGIT_CONFIG))) {
            UsernamePasswordCredentialsProvider provider = new UsernamePasswordCredentialsProvider(GIT_USERNAME, GIT_PASSWORD);
            git.add().addFilepattern(".").call();
            // 提交
            git.commit().setMessage(desc).call();
            // 推送到远程,不报错默认为成功
            git.push().setCredentialsProvider(provider).call();
            commitAndPushFlag = true;
        } catch (Exception e) {
            e.printStackTrace();
            LOGGER.error("Commit And Push error!" + e.getMessage());
        }
        return commitAndPushFlag;
    }
```

注意这里需要指定本地项目的配置文件路径，例如我的是 **E:\img\img-playpi\\.git**，与前面的下载路径是在同一个父目录，另外还需要指定用户名密码。


## 使用新链接替换旧链接

如果前面的步骤完成，就说明图片已经被成功迁移到 GitHub 上面，并且获取到了新的图片链接，接着直接替换掉旧链接即可。

代码逻辑如下：

```
    /**
     * 替换所有的图片链接
     *
     * @param string
     * @param urlMap
     * @return
     */
    private static String replaceUrl(String string, Map<String, String> urlMap) {
        for (Map.Entry<String, String> entry : urlMap.entrySet()) {
            String oldUrl = entry.getKey();
            String newUrl = entry.getValue();
            string = string.replaceAll(oldUrl, newUrl);
        }
        return string;
    }
```

## 替换后内容写回新文件

写入新文件是很简单的，直接调用 io 包即可完成，但是为了安全起见，文件放在新的目录中，不要直接替换掉原来的文件，否则程序出现意外就麻烦了。


# 迁移结果


随意打开一篇博客，使用文件对比工具查看替换前后的区别，可以看到除了图片链接被替换掉，其它内容没有任何变化。
![替换文件对比](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190504004204.png "替换文件对比")

在本地仓库查看，图片已经全部下载。
![在本地仓库查看](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190504004224.png "在本地仓库查看")

在 GitHub 的仓库中查看，图片全部推送。
![在 GitHub 的仓库中查看](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190504004216.png "在 GitHub 的仓库中查看")

任意打开一篇博客，里面的图片已经可以全部正常显示，只不过有一些太大的图片【超过1MB的】加载速度有点慢，还可以接受。

