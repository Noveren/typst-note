#import "../typst-note/template.typ": *
#show: conf

#context {
  let is-main-file = state("is-main-file", false).get()
  if not is-main-file {
    outline()
    pagebreak()
  }
}

#link("https://www.jenkins.io/zh/")[Jenkins] 是一个开源的、提供友好操
作界面的持续集成 CI 工具，主要用于持续、自动的构建/测试软件项目、监控外部
任务的运行

= 服务搭建

```bash
$ podman pull docker.io/jenkins/jenkins:lts
$ podman images | grep jenkins
# 8080 Web; 50000 Agent
$ podman run -d --name my-jenkins -p 8080:8080 -p 50000:50000 docker.io/jenkins/jenkins:lts
$ podman volume create jenkins-data
$ podman run -d --name jenkins -p 8080:8080 -p 50000:50000 -v jenkins-data:/var/jenkins_home:Z --restart=unless-stopped docker.io/jenkins/jenkins:lts
$ podman exec my-jenkins cat /var/jenkins_home/secrets/initialAdminPassword
# 访问 http://127.0.0.1:8080/restart 进行强制安全重启
$ podman restart jenkins
$ podman exec -it -u root jenkins bash
```

#list(
  [
    *备注*：若使用公司 Linux 工作机部署（通过 VPN 访问），则可能因 VPN 限
    制而无法远程访问，此时可使用 SSH 本地端口转发 
    `ssh -L <local_port>:127.0.0.1:<remote_port> <name>@<ip>`，
    保持 SSH 会话不关闭，即可
    在本地使用 `http://127.0.0.1:<local_port>` 进行访问
  ],
  [
    *备注*：安装 Pipeline 提供 Jenkinsfile 支持，安装 JUnit 提供
    测试 XML 报告解析支持，安装 Git 提供远程仓库获取能力；插件安装后需要
    重启生效
  ],
  [
    *备注*：TODO 基于官方镜像，定制有运行环境如 python 的镜像；
    TODO 在流水线中使用 Docker Agent 
  ],
)

#table(align: center + horizon, columns: (1fr, 1fr),
  [*插件*], [*说明*],
  [`Pipleine`], [
  ],
  [`JUnit`], [
  ],
  [`Git`], [
  ],
  [`SSH Agent`], [
  ],
)

```dockerfile
FROM jenkins/jenkins:lts
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
USER jenkins
```

== 流水线

```jenkinsfile

```

指令 `agent` 用于指定流水线的执行环境

=== SSH Agent Plugin

*前提条件*：安装 `SSH Agent` 插件，远程目标可使用 `ssh-agent` 命令，配置
远程目标登录凭据

```jenkinsfile
pipeline {
  agent any
  stages {
    stage("hello") {
      steps {
        sshagent(credentials: ['ee213']) {
          sh '''
            ssh -o StrictHostKeyChecking=no name@ip 'echo Hello'
          '''
        }
      }
    }
  }
}
```


