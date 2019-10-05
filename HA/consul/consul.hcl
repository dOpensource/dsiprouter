datacenter = "${CLUSTER_NAME}"
data_dir = "/opt/consul"
node_name = "NODE_NAME"
log_level = "INFO"
bind_addr = "0.0.0.0"
client_addr = "0.0.0.0"
advertise_addr = "EXTERNAL_IP_ADDR"
enable_syslog = true
syslog_facility = "LOCAL3"
encrypt = "${KEY_CIPHER_TEXT_B64}"
retry_join = ${RETRY_JOIN}
performance = {
  raft_multiplier = 1
}