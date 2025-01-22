# Use a base image with Java 11 and Maven installed
FROM maven:3.8.4-openjdk-11 AS build

WORKDIR /build
COPY src ./src
COPY pom.xml .

RUN mvn verify


# RUN wget https://repo1.maven.org/maven2/org/jacoco/org.jacoco.agent/0.8.7/org.jacoco.agent-0.8.7-runtime.jar -O jacocoagent.jar
RUN wget https://repo1.maven.org/maven2/org/jacoco/org.jacoco.agent/0.8.7/org.jacoco.agent-0.8.7-runtime.jar -O jacocoagent.jar
RUN wget https://repo1.maven.org/maven2/org/jacoco/org.jacoco.cli/0.8.7/org.jacoco.cli-0.8.7.jar -O jacococli.jar
# RUN wget https://repo1.maven.org/maven2/org/kohsuke/args4j/args4j/2.33/args4j-2.33.jar -O args4j.jar
RUN wget https://repo1.maven.org/maven2/args4j/args4j/2.33/args4j-2.33.jar -O args4j.jar
# Use a base image with Java 11 and WildFly
FROM jboss/wildfly:23.0.2.Final AS runtime

# Set deployment directory
ENV DEPLOYMENT_DIR=/opt/jboss/wildfly/standalone/deployments/
ENV APP_NAME=ticket-monster.war

USER root

# RUN echo '#!/bin/bash\n\
# cp -r /build /data/build\n\
# /opt/jboss/wildfly/bin/standalone.sh -b 0.0.0.0' > /start.sh && \
# chmod +x /start.sh

RUN mkdir -p /data && chmod -R 777 /data
# COPY the target and src directories from build
COPY --from=build /build/target /build/target
COPY --from=build /build/src /build/src

COPY --from=build /build/target/${APP_NAME} ${DEPLOYMENT_DIR}
COPY --from=build /build/jacocoagent.jar /jacocoagent.jar
COPY --from=build /build/jacococli.jar /jacococli.jar
COPY --from=build /build/args4j.jar /args4j.jar

VOLUME ["/data"]

RUN echo 'JAVA_OPTS="$JAVA_OPTS -javaagent:/jacocoagent.jar=destfile=/jacoco.exec,output=tcpserver,address=*,port=6300"' >> /opt/jboss/wildfly/bin/standalone.conf

EXPOSE 8080 6300

CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0"]

# CMD ["/start.sh"]
# ENTRYPOINT ["tail"]
# CMD ["-f","/dev/null"]


