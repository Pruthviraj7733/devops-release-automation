#Base Image :- Apache Tomcat10.1 with Java 21
FROM tomcat:10.1-jdk21-temurin

#Set working directory
WORKDIR /opt/myapp

#Remove default tomcat web applications 
RUN rm -rf /usr/local/tomcat/webapps/*

#Copy JSP application from Github repository
COPY app/index.jsp .

#Package JSP application into WAR
# c = Create archive
# v = Verbose (display detailed output)
# f = File (specify output archive filename)
RUN java -cvf java-application.war index.jsp

#Deploy WAR File to apache tomcat
RUN mv java-application.war /usr/local/tomcat/webapps/

#Application Port
EXPOSE 8080

#Start apache tomcat in foreground
CMD ["catalina.sh","run"]
