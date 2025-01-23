# Use a base image with Java 11 and Maven installed
FROM maven:3.8.4-openjdk-11 AS build

WORKDIR /build
COPY src ./src
COPY pom.xml .

RUN mvn verify

RUN wget https://repo1.maven.org/maven2/org/jacoco/org.jacoco.agent/0.8.7/org.jacoco.agent-0.8.7-runtime.jar -O jacocoagent.jar

# Use a base image with Java 11 and WildFly
FROM jboss/wildfly:23.0.2.Final AS runtime

# Set deployment directory
ENV DEPLOYMENT_DIR=/opt/jboss/wildfly/standalone/deployments/

USER root

RUN mkdir -p /target && chmod -R 777 /target

COPY --from=build /build/target /build/target
COPY --from=build /build/target/${APP_NAME} ${DEPLOYMENT_DIR}
COPY --from=build /build/jacocoagent.jar /jacocoagent.jar

VOLUME ["/target"]

RUN echo 'JAVA_OPTS="$JAVA_OPTS -javaagent:/jacocoagent.jar=destfile=/jacoco.exec,output=tcpserver,address=*,port=6300"' >> /opt/jboss/wildfly/bin/standalone.conf

EXPOSE 8080 6300

RUN cp -r /build/target/* /target

CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0"]

# For debugging
# ENTRYPOINT ["tail"]
# CMD ["-f","/dev/null"]


