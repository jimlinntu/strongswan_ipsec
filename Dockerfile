FROM ubuntu:18.04
RUN apt update
RUN apt install -y vim kmod strongswan strongswan-pki kmod iproute2
RUN apt install -y iptables
RUN apt install -y iputils-ping
RUN apt install -y ssh
