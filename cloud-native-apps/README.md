# Demo Cloud Native Apps with Java

## Slides para introdução ao tema...
 * [OpenShift - Technical Overview (very low level)](https://docs.google.com/presentation/d/1nwojcNFjOXiRkBRDIiHyWKxB5nyAk0_BWLhHJK2wc0w/edit#slide=id.gb6f3e2d2d_2_213)

 * [Inove na velocidade do seu negócio com Openshift e uma estratégia DevOps](https://docs.google.com/presentation/d/1LzDT0TK7PJOsLNPipRNlQcjm0ecikLD6FKXF5lXinEs/edit#slide=id.g17cadb6f71_1_0)

### Slides específicos para Docker e Kubernetes
 * [Docker for Java Developers](http://redhat.slides.com/rbenevid/docker4devs#/)

 * [Tuning JVM for Linux Containers](https://docs.google.com/presentation/d/1SSf5BX22TwAMwCgGtjKdACvvztXlXEW9XG3OttNsfGg/edit#slide=id.g1e56d4b0f2_0_260)

 * [Kubernetes for Developers](https://docs.google.com/presentation/d/1A1_3BqWnDu6gFi7JYuCpMeYVzShnPrQZmGiamKcBz84/edit#slide=id.g12c8aac1e6_0_0)

## Pre-req

* CodeReady Containers (former CDK, minishift) ou acesso à um Cluster na nuvem
* OpenJDK 8
* Maven >= 3.6
   > make sure your `~/.m2/settings.xml` have a **active profile** with `https://repo.maven.apache.org/maven2/` repository declared!!!
* VSCode (with Red Hat Java plugin)
* Docker engine ou Podman
* [GraalVM](https://www.graalvm.org/)
  * You need to set `GRAALVM_HOME` before executing this demo
* Package zlib-devel
  * sudo dnf install zlib-devel

> Try to run this demo at least once so maven can save all dependencies necessary in its local repository.

## 1) [Quarkus](quarkus.io)

> Guia oficial: https://quarkus.io/guides/getting-started-guide

> Live DevNation demo: https://www.youtube.com/watch?v=7G_r1iyrn2c

### 1.1) Bootstrap a new project using Quarkus Maven archetype

```bash
# Create dirs
mkdir -p tmp/dev/demos/quarkus/getting-started && \
cd /tmp/dev/demos/quarkus/getting-started

# Create app
mvn io.quarkus:quarkus-maven-plugin:0.14.0:create \
    -DprojectGroupId=org.acme \
    -DprojectArtifactId=getting-started \
    -DclassName="org.acme.quickstart.GreetingResource" \
    -Dpath="/hello" \
    -Dextensions="resteasy-jsonb"

# open with VSCode
code .
```

### 1.2) Start your app in dev mode (live reload!!!)

Open your IDE terminal console (``Ctrl + ` `` in VSCode) and execute:

```bash
./mvnw clean compile quarkus:dev
```

Open your browser at [http://localhost:8080/hello](http://localhost:8080/hello)

Change the value returned from hello method to show hot reload:

```java
  @GET
  @Produces(MediaType.TEXT_PLAIN)
  public String hello() {
      return "hello customer";
  }
```

Create a new endpoint:

```java
  @GET
  @Produces(MediaType.TEXT_PLAIN)
  @Path("/serverinfo")
  public String serverInfo(@Context HttpServletRequest req) {
      return "hello from quarkus running at: "
          + req.getServerName() + " - " +  req.getLocalAddr();
  }
```

Now, open your browser at [http://localhost:8080/hello/serverinfo](http://localhost:8080/hello/serverinfo)

### 1.3) Injection

Create `GreetingService.java`

```bash
touch src/main/java/org/acme/quickstart/GreetingService.java
```

Paste the following code:

```java
package org.acme.quickstart;

import javax.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class GreetingService {

    public String greeting(String name) {
        return "hello " + name;
    }
}
```

Update `GreetingResource` endpoint:

```java
...

@Path("/hello")
public class GreetingResource {

    @Inject
    GreetingService greetingService;

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public String hello() {
        return this.greetingService.greeting("customer");
    }

    @GET
    @Produces(MediaType.TEXT_PLAIN)
    @Path("/serverinfo")
    public String serverInfo(@Context HttpServletRequest req) {
        return "hello from quarkus running at: " + req.getServerName() + " - " + req.getLocalAddr();
    }
}
```

### 1.4) Unit Testing

Update `GreetingResourceTest` so it can pass in the test. To open, in VSCode, press `Crtl + p` and then write `GreetingResourceTest`

Now update it as follow:

```java
    @Test
    public void testHelloEndpoint() {
        given()
          .when().get("/hello")
          .then()
             .statusCode(200)
             .body(is("hello customer"));
    }
```

Save the file and execute the test clicking on `Run Test` right above the method signature.

### 1.5) List and install extensions

#### List all extensions available

```bash
mvn quarkus:list-extensions
# or
gradle list-extensions
```

#### Install OpenAPI extension

```bash
./mvnw quarkus:add-extension -Dextensions="smallrye-openapi"

curl http://localhost:8080/openapi
```

Open [http://localhost:8080/swagger-ui](http://localhost:8080/swagger-ui)

#### Install health check extension

```bash
./mvnw quarkus:add-extension -Dextensions="smallrye-health"
```

Open [http://localhost:8080/health](http://localhost:8080/health)

> [Official extension page](https://quarkus.io/extensions/)

### 1.6) Application Build (Java version)

#### Maven build

```bash
./mvnw package -DskipTests
ls -lah target/
```

#### Local execution

```bash
java -jar target/getting-started-1.0-SNAPSHOT-runner.jar
```

> Notice the startup time

Get java PID:

```bash
JAVA_DEMO_PID=$(ps aux | grep getting-started | awk '{ print $2}' | head -1)
```

Now check how much resource is been used by this java process:

```bash
ps -o pid,rss,cmd -p $JAVA_DEMO_PID
```

#### Docker container

Now let's create our container image:

> Before running these commands, make sure quarkus is *not* running

```bash
docker build -f src/main/docker/Dockerfile.jvm -t quarkus/getting-started-jvm .
docker run -i --rm -p 8080:8080 quarkus/getting-started-jvm
docker stats
```

#### Deploying on Openshift/Kubernetes

##### Binary build
  
```bash
oc new-project quarkus-demo

oc new-build --name=quarkus-jvm-demo \
   --image-stream=redhat-openjdk18-openshift:1.4 \
   --env="JAVA_APP_JAR=getting-started-1.0-SNAPSHOT-runner.jar"
   --binary=true -n quarkus-demo

oc start-build quarkus-jvm-demo --from-dir=./target/ocp-build-input/ -n quarkus-demo
oc new-app quarkus-jvm-demo -n quarkus-demo
oc expose svc/quarkus-jvm-demo -n quarkus-demo
```

##### Source to Image (S2I)

Create a new github repo

```bash
git init
git add . --all
git commit -m "first commit"
git remote add origin https://github.com/<user>/quarkus-demo.git
git push -u origin master

```

Java OpenJDK 8 Image Builder
> **NOT WORKING (https://github.com/quarkusio/quarkus-images/issues/13#)!**
* From Catalog -> Java OpenJDK 8 Builder
* Habilitar incremental build

```yaml
strategy:
  sourceStrategy:
    incremental: true
    from:
    ...
```

### 1.7) Native packaging

```bash
./mvnw package -Pnative -DskipTests
ls -lah target/
file target/getting-started-1.0-SNAPSHOT-runner
./target/getting-started-1.0-SNAPSHOT-runner
```

> Notice the startup time!!! **COMPARE WITH JAVA VERSION**

Get native PID:

```bash
JAVA_DEMO_PID=$(ps aux | grep getting-started | awk '{ print $2}' | head -1)
```

Now check how much resource is been used by this java process:

```bash
ps -o pid,rss,cmd -p $JAVA_DEMO_PID
```

#### Native Docker container

Now let's create our container image:

> Before running these commands, make sure quarkus is *not* running

```bash
./mvnw package -Pnative -Dnative-image.container-runtime=docker

docker build -f src/main/docker/Dockerfile.native -t quarkus/getting-started .
docker run -i --rm -p 8080:8080 quarkus/getting-started
docker stats
```

#### Native build on Openshift/Kubernetes

```bash
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