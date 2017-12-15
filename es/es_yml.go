package main

import (
	//	"fmt"
	"flag"
	"log"
	"os"
	"strings"

	. "es_click_once/modules/es_install"

	"gopkg.in/yaml.v2"
)

const (
	CLUSTER_NAME = "es_cluster"
	NODE_MASTER  = true
	NODE_DATA    = true
	PATH_DATA    = "/home/elasticsearch-5.2.2/data_logs/data"
	PATH_LOGS    = "/home/elasticsearch-5.2.2/data_logs/logs"
	HTTP_PORT    = 9200
	TTP          = 9300
	HCE          = true
	HCAO         = "*"
	DZMMN        = 2
	ADRN         = true
	BSCF         = false
	AACI         = false
)

type EsYml struct {
	ClusterName string   `yaml:"cluster.name"`
	NodeName    string   `yaml:"node.name"`
	NodeMaster  bool     `yaml:"node.master"`
	NodeData    bool     `yaml:"node.data"`
	PathData    string   `yaml:"path.data"`
	PathLogs    string   `yaml:"path.logs"`
	NetworkHost string   `yaml:"network.host"`
	HttpPort    int      `yaml:"http.port"`
	TTP         int      `yaml:"transport.tcp.port"`
	HCE         bool     `yaml:"http.cors.enabled"`
	HCAO        string   `yaml:"http.cors.allow-origin"`
	DZPUH       []string `yaml:"discovery.zen.ping.unicast.hosts"`
	DZMMN       int      `yaml:"discovery.zen.minimum_master_nodes"`
	ADRN        bool     `yaml:"action.destructive_requires_name"`
	BSCF        bool     `yaml:"bootstrap.system_call_filter"`
	AACI        bool     `yaml:"action.auto_create_index"`
}

type Yml string

func host(s string) []string {
	return strings.Split(s, ",")
}

func networkHost() string {
	return os.Getenv("THIS_HOST")
}

func yml(allNodes []string, hostNode string) Yml {
	var esYml = EsYml{
		ClusterName: CLUSTER_NAME,
		NodeName:    hostNode,
		NodeMaster:  NODE_MASTER,
		NodeData:    NODE_DATA,
		PathData:    PATH_DATA,
		PathLogs:    PATH_LOGS,
		NetworkHost: hostNode,
		HttpPort:    HTTP_PORT,
		TTP:         TTP,
		HCE:         HCE,
		HCAO:        HCAO,
		DZPUH:       allNodes,
		DZMMN:       DZMMN,
		ADRN:        ADRN,
		BSCF:        BSCF,
		AACI:        AACI,
	}

	bytes, err := yaml.Marshal(esYml)
	if err != nil {
		log.Fatalf("error: %v", err)
	}

	return Yml(bytes)
}

func main() {
	hostNode := flag.String("hostNode", "", "localhost")
	allNodes := flag.String("AllNodes", "", "all es nodes")

	host := host(*allNodes)
	yml := yml(host, *hostNode)

	Wr("elasticsearch.yml", []byte(yml))
}
