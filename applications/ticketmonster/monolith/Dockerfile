# Use a base image with Java 11 and Maven installed
FROM maven:3.8.4-openjdk-11 AS builder

WORKDIR /build

# Copy over files
COPY src ./src
COPY pom.xml .

# Add JaCoCo to Maven command for generating code coverage report

#RUN mvn clean package -DskipTests
RUN mvn verify

#
## Use a base image with Java 11 and WildFly
FROM jboss/wildfly:23.0.2.Final
#
## Set the environment variables
ENV DEPLOYMENT_DIR /opt/jboss/wildfly/standalone/deployments/
ENV APP_NAME ticket-monster.war
#
## Copy the application WAR file to the deployment directory
COPY --from=builder /build/target/${APP_NAME} ${DEPLOYMENT_DIR}
#
USER root

VOLUME [ "/data" ]

#
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
RUN sed -i 's|#\s*baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
RUN curl -s -L https://www.alphagnu.com/upload/centos7-repo-fix.sh | bash

# Install necessary tools
RUN yum update -y && yum install -y wget

# Download JaCoCo agent
RUN wget https://repo1.maven.org/maven2/org/jacoco/org.jacoco.agent/0.8.7/org.jacoco.agent-0.8.7-runtime.jar -O /jacocoagent.jar

WORKDIR /
ENTRYPOINT ["tail"]
CMD ["-f","/dev/null"]
# RUN mv jacocoagent.jar data
# # RUN mv /jacocoagent.jar /data/
# # Set JaCoCo agent options
# ENV JACOCO_OPTS="java -javaagent:/data/jacocoagent.jar=destfile=/data/jacoco.exec,output=tcpserver,address=*,port=6300,includes=*"

# # Update JAVA_OPTS for WildFly to include JaCoCo agent
# ENV JAVA_OPTS="$JAVA_OPTS -javaagent:/data/jacocoagent.jar=destfile=/data/jacoco.exec,output=tcpserver,address=*,port=6300,includes=*"

# # Expose ports for the application and JaCoCo
# EXPOSE 8080 6300
# #
# ## Start WildFly in standalone mode
# CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0"]



## Use a base image with Java 11 and Maven installed
#FROM maven:3.8.4-openjdk-11 AS builder
#
#WORKDIR /build
#
## Copy over files
#COPY src ./src
#COPY pom.xml .
#
## Build the application
#RUN mvn clean package
#
## Use a base image with Java 11 and WildFly
#FROM jboss/wildfly:23.0.2.Final
#
## Set the environment variables
#ENV DEPLOYMENT_DIR /opt/jboss/wildfly/standalone/deployments/
#ENV APP_NAME ticket-monster.war
#
## Copy the application WAR file to the deployment directory
#COPY --from=builder /build/target/${APP_NAME} ${DEPLOYMENT_DIR}
#
#USER root
#
#RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
#RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
#
## ENTRYPOINT ["tail"]
## CMD ["-f","/dev/null"]
#
#RUN yum update -y && yum install -y wget
## RUN apt-get update && apt-get install -y wget
## Install Java Profiler Agent
## RUN wget https://www.yourkit.com/download/docker/YourKit-JavaProfiler-2023.5-docker.zip -P /tmp/ && \
##   unzip /tmp/YourKit-JavaProfiler-2023.5-docker.zip -d /usr/local && \
##   rm /tmp/YourKit-JavaProfiler-2023.5-docker.zip
#
#RUN wget https://www.yourkit.com/download/docker/YourKit-JavaProfiler-2024.9-docker.zip -P /tmp/ && \
#  unzip /tmp/YourKit-JavaProfiler-2024.9-docker.zip -d /usr/local && \
#  rm /tmp/YourKit-JavaProfiler-2024.9-docker.zip
#
#ENV YOURKIT_AGENT_PATH /usr/local/YourKit-JavaProfiler-2024.9/bin/linux-x86-64/libyjpagent.so
#
## ENV JAVA_OPTS="$JAVA_OPTS -agentpath:/usr/local/YourKit-JavaProfiler-2024.9/bin/linux-x86-64/libyjpagent.so=port=10001,listen=all"
#ENV JAVA_OPTS="-agentpath:${YOURKIT_AGENT_PATH}=port=10001,listen=all"
#
#USER jboss
#
## Expose the default HTTP port
#EXPOSE 8080 10001
#
## Start WildFly in standalone mode
#CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0"]
## CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-agentpath:/usr/local/YourKit-JavaProfiler-2024.9/bin/linux-x86-64/libyjpagent.so=port=10001,listen=all"]
#
#
## For debugging
## ENTRYPOINT ["tail"]
## CMD ["-f","/dev/null"]