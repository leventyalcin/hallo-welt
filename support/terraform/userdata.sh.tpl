#!/bin/bash

cat > /etc/systemd/system/${service_name}.service <<EOF
[Unit]
Description=${service_name}
Requires=docker.service
After=docker.service

[Service]
Restart=always

TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker stop ${service_name}
ExecStartPre=-/usr/bin/docker rm -f ${service_name}
ExecStartPre=/usr/bin/docker pull ${dockerhub_account}/${service_name}:${service_version}

ExecStart=/bin/bash -c "                            \
  docker run                                        \
    --name ${service_name}                          \
    -p ${service_port}:${service_port}              \
    ${dockerhub_account}/${service_name}:${service_version}"

ExecStop=/usr/bin/docker stop ${service_name}

[Install]
WantedBy=default.target
EOF

systemctl daemon-reload
systemctl start ${service_name}
