package main

import (
	//	"fmt"
	"flag"
	"io/ioutil"
	"log"
	"os"
	"strings"

	"gopkg.in/yaml.v2"
)

const (
	CLUSTER_NAME = "es_cluster"
	NODE_MASTER  = true
	NODE_DATA    = true
	HTTP_PORT    = 9200
	TTP          = 9300
	HCE          = true
	HCAO         = "*"
	DZMMN        = 2
	ADRN         = true
	BSCF         = false
	AACI         = false
)

var pathData string
var pathLog string

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
		PathData:    pathData,
		PathLogs:    pathLog,
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

func Rd(path string) []byte {
	fi, err := os.Open(path)
	if err != nil {
		panic(err)
	}
	defer fi.Close()
	fd, err := ioutil.ReadAll(fi)

	return fd
}

func Wr(file string, b []byte) error {
	return ioutil.WriteFile(file, b, 0644)
}

func WrAppend(file string, b []byte) error {
	f, err := os.OpenFile(file, os.O_WRONLY|os.O_APPEND|os.O_CREATE, 0666)
	_, err = f.Write(b)
	defer f.Close()

	return err
}

func main() {
	esHome := flag.String("esHome", "", "es home")
	hostNode := flag.String("hostNode", "", "localhost")
	allNodes := flag.String("allNodes", "", "all es nodes")

	flag.Parse()

	pathData = *esHome + "/data_logs/data"
	pathLog = *esHome + "/data_logs/log"

	host := host(*allNodes)
	yml := yml(host, *hostNode)

	Wr("elasticsearch.yml", []byte(yml))
}
