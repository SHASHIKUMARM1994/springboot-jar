# file: Dockerfile (place this in repo root)
FROM eclipse-temurin:17-jre
VOLUME /appdata
COPY target/demo-0.0.1-SNAPSHOT.jar /app/app.jar
WORKDIR /app
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]
