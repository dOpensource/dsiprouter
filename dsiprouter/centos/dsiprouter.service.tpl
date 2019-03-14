[Unit]
Description=dSIPRouter Service
After=multi-user.target

[Service]
Type=idle
ExecStart=PYTHON_CMD DSIP_KAMAILIO_CONF_DIR/gui/dsiprouter.py runserver

[Install]
WantedBy=multi-user.target
