# Demo Cloud Native Apps with Java

## Slides para introdução ao tema...
 * **[OpenShift - Technical Overview (very low level)](https://docs.google.com/presentation/d/1nwojcNFjOXiRkBRDIiHyWKxB5nyAk0_BWLhHJK2wc0w/edit#slide=id.gb6f3e2d2d_2_213)**

 * **[Inove na velocidade do seu negócio com Openshift e uma estratégia DevOps](https://docs.google.com/presentation/d/1LzDT0TK7PJOsLNPipRNlQcjm0ecikLD6FKXF5lXinEs/edit#slide=id.g17cadb6f71_1_0)**

### Slides específicos para Docker e Kubernetes
 * **[Docker for Java Developers](http://redhat.slides.com/rbenevid/docker4devs#/)**

 * **[Tuning JVM for Linux Containers](https://docs.google.com/presentation/d/1SSf5BX22TwAMwCgGtjKdACvvztXlXEW9XG3OttNsfGg/edit#slide=id.g1e56d4b0f2_0_260)**

 * **[Kubernetes for Developers](https://docs.google.com/presentation/d/1A1_3BqWnDu6gFi7JYuCpMeYVzShnPrQZmGiamKcBz84/edit#slide=id.g12c8aac1e6_0_0)**

## Pre-reqs para essa demo

 * CodeReady Containers (former CDK, minishift) ou acesso à um Cluster na núvem
 * OpenJDK 8
 * Maven >= 3.6
   > make sure your `~/.m2/settings.xml` have a **active profile** with `https://repo.maven.apache.org/maven2/` repository declared!!!
 * VSCode (with Red Hat Java plugin)
 * Docker engine ou Podman

## 1) [Quarkus](quarkus.io)

> Guia oficial: https://quarkus.io/guides/getting-started-guide
> 
> Live DevNation demo: https://www.youtube.com/watch?v=7G_r1iyrn2c

 * bootstrap a new project using Quarkus Maven archetype

```
mkdir -p ~/dev/demos/quarkus/getting-started && \
 cd ~/dev/demos/quarkus/getting-started

mvn io.quarkus:quarkus-maven-plugin:0.13.2:create \
    -DprojectGroupId=org.acme \
    -DprojectArtifactId=getting-started \
    -DclassName="org.acme.quickstart.GreetingResource" \
    -Dpath="/hello"

# open with VSCode
code .
```

### start your app in dev mode (live reload!!!)

 * open your IDE terminal console (``Ctrl + ` `` in VSCode)

```
./mvnw clean compile quarkus:dev
```

 * open your browser at [http://localhost:8080/hello](http://localhost:8080/hello)
 * evoluir a app demonstrando:
   * **Live reload**
   > Criar novo endpoint `/servername`
   ```java
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public String hello(@Context HttpServletRequest req) {
        return "hello from quarkus running at: " 
            + req.getServerName() + " - " +  req.getLocalAddr();
    }   
   ``` 
   * **Injection**
   > criar `GreetingService` com `@Inject`
   * **Unit Testing**
   * **JSON**
   ```
   io.quarkus:quarkus-resteasy-jsonb
   mvn quarkus:add-extension -Dextension="io.quarkus:quarkus-resteasy-jsonb"
   ```
   > criar um POJO
   > criar um novo endpoint GET
   ```java
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Path("/demo")
    public Demo demo() { 
        return new Demo("Quarkus Demo", "Quarkus", "Recife", "EMPREL");
    }   
   ```
   > reiniciar em modo dev `./mvnw clean compile quarkus:dev`
   * **Reactive Streams**
     * _Publisher/Sbriscriber model_ using [RxJava](https://github.com/ReactiveX/RxJava) operators
   ```
   io.quarkus:quarkus-resteasy-jsonb
   mvn quarkus:add-extension -Dextension="io.quarkus:quarkus-smallrye-reactive-streams-operators"
   ```
   > Criar `StreamBean` e injetar `@Inject`
   ```java
    @ApplicationScoped
    public class StreamCounter {
        AtomicInteger counter = new AtomicInteger();
        public Publisher<String> counter() {
            return Flowable.interval(1000, TimeUnit.MILLISECONDS)
                .map(i -> counter.incrementAndGet())
                .map(i -> i.toString());
        }
    }
   ``` 
   > Criar um novo endpoint do tipo `Publisher` produzindo `SSI` type 
   ```java
    @GET
    @Produces(MediaType.SERVER_SENT_EVENTS)
    @Path("/counter")
    public Publisher<String> counter() {
        return streamCounter.counter();
    }  
   ``` 
   > reiniciar em modo dev `./mvnw clean compile quarkus:dev`

### Build da aplicação (Java version)

 * maven build
  ```
  ./mvnw package -DskipTests
  ls -lah target/
  ```
 * Executando local
  ```
  java -jar target/getting-started-1.0-SNAPSHOT-runner.jar
  ```
  > observe o startup time!!!

 * Docker container
  ```
  docker build -f src/main/docker/Dockerfile.jvm -t quarkus/getting-started-jvm .
  docker run -i --rm -p 8080:8080 quarkus/getting-started-jvm
  docker ps
  docker stats
  ps -o pid,rss,command -p $PID
  ```

 * Container rodando no Openshift/Kubernetes
   * Binary build 
  ```
  oc new-build --name=quarkus-jvm-demo \
   --image-stream=redhat-openjdk18-openshift:1.4 \
   --env="JAVA_APP_JAR=getting-started-1.0-SNAPSHOT-runner.jar"
   --binary=true

  oc start-build quarkus-jvm-demo --from-dir=./target/ocp-build-input/

  oc new-app quarkus-jvm-demo

  oc expose svc/quarkus-jvm-demo
  ```
    * S2i
      * https://github.com/new
      ```
      git init
      git add . --all
      git commit -m "first commit"
      git remote add origin https://github.com/<user>/quarkus-demo.git
      git push -u origin master

      ``` 
      * From Catalog -> Java OpenJDK 8 Builder
      * Habilitar incremental build
      ```yaml
      strategy:
        sourceStrategy:
          incremental: true 
          from:
          ...
      ```

### Native packaging
 * Native build
   * [GraalVM](https://www.graalvm.org/) 
  ```
  ./mvnw package -Pnative -DskipTests
  ls -lah target/
  file target/getting-started-1.0-SNAPSHOT-runner
  ./target/getting-started-1.0-SNAPSHOT-runner
  ```
  > observe o startup time!!! **COMPARE COM A VERSÃO JAVA**

 * Container rodando no Openshift/Kubernetes
  ```
  ./mvnw package -Pnative -Dnative-image.container-runtime=docker

  oc new-build quay.io/redhat/ubi-quarkus-native-runner \
    --binary \
    --name=quarkus-native-demo

  oc start-build quarkus-native-demo \
    --from-file=./target/getting-started-1.0-SNAPSHOT-runner \
    --follow

  oc new-app quarkus-native-demo

  oc expose svc/quarkus-native-demo
 ```

## 2) Spring Boot


## 3) Side by Side

