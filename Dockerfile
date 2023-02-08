# Template to customise msc based image
#

FROM staillansag/webmethods-microservicesruntime:10.15.0.1-jk


# define exposed ports

EXPOSE 5555
EXPOSE 5543
EXPOSE 9999


# user to be used when running scripts
USER sagadmin


# files to be added to based image (includes configuration and package)

ADD --chown=sagadmin . /opt/softwareag/IntegrationServer/packages/DecPurchaseOrder
ADD --chown=sagadmin ./resources/integrationlive /opt/softwareag/IntegrationServer/config/integrationlive