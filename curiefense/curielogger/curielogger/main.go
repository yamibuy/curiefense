package main

import (
	"encoding/json"
	"fmt"

	"bufio"
	"log"
	"net"
	"os"
	"strings"
	"time"

	"google.golang.org/grpc"

	ald "github.com/envoyproxy/go-control-plane/envoy/data/accesslog/v2"
	als "github.com/envoyproxy/go-control-plane/envoy/service/accesslog/v2"
	"github.com/spf13/pflag"
	"github.com/spf13/viper"

	//	ptypes "github.com/golang/protobuf/ptypes"
	duration "github.com/golang/protobuf/ptypes/duration"
	timestamp "github.com/golang/protobuf/ptypes/timestamp"

	"net/http"

	"github.com/hashicorp/logutils"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"

	"errors"
)

//   ___ ___  __  __ __  __  ___  _  _
//  / __/ _ \|  \/  |  \/  |/ _ \| \| |
// | (_| (_) | |\/| | |\/| | (_) | .` |
//  \___\___/|_|  |_|_|  |_|\___/|_|\_|
// COMMON

type CurieProxyLog struct {
	Headers     map[string]string      `json:"headers"`
	Cookies     map[string]string      `json:"cookies"`
	Geo         map[string]interface{} `json:"geo"`
	Arguments   map[string]string      `json:"arguments"`
	Attributes  map[string]interface{} `json:"attributes"`
	Blocked     bool                   `json:"blocked"`
	BlockReason map[string]interface{} `json:"block_reason"`
	Tags        []string               `json:"tags"`
}

type RXTimer struct {
	FirstUpstreamByte float64 `json:"firstupstreambyte"`
	LastUpstreamByte  float64 `json:"lastupstreambyte"`
	LastByte          float64 `json:"lastbyte"`
}

type TXTimer struct {
	FirstUpstreamByte   float64 `json:"firstupstreambyte"`
	LastUpstreamByte    float64 `json:"lastupstreambyte"`
	FirstDownstreamByte float64 `json:"firstdownstreambyte"`
	LastDownstreamByte  float64 `json:"lastdownstreambyte"`
}

type DownstreamData struct {
	ConnectionTermination   bool   `json:"connectiontermination"`
	DirectRemoteAddress     string `json:"directremoteaddress"`
	DirectRemoteAddressPort uint32 `json:"directremoteaddressport"`
	LocalAddress            string `json:"localaddress"`
	LocalAddressPort        uint32 `json:"localaddressport"`
	ProtocolError           bool   `json:"protocolerror"`
	RemoteAddress           string `json:"remoteaddress"`
	RemoteAddressPort       uint32 `json:"remoteaddressport"`
}

type UpstreamData struct {
	Cluster                string `json:"cluster"`
	ConnectionFailure      bool   `json:"connectionfailure"`
	ConnectionTermination  bool   `json:"connectiontermination"`
	LocalAddress           string `json:"localaddress,omitempty"`
	LocalAddressPort       uint32 `json:"localaddressport,omitempty"`
	Overflow               bool   `json:"overflow"`
	RemoteAddress          string `json:"remoteaddress,omitempty"`
	RemoteAddressPort      uint32 `json:"remoteaddressport,omitempty"`
	RemoteReset            bool   `json:"remotereset"`
	RequestTimeout         bool   `json:"requesttimeout"`
	RetryLimitExceeded     bool   `json:"retrylimitexceeded"`
	TransportFailureReason string `json:"transportfailurereason"`
}

type CertificateData struct {
	Properties         string   `json:"properties"`
	PropertiesAltNames []string `json:"propertiesaltnames"`
}

type TLSData struct {
	LocalCertificate CertificateData `json:"localcertificate"`
	PeerCertificate  CertificateData `json:"peercertificate"`
	CipherSuite      string          `json:"ciphersuite"`
	SessionId        string          `json:"sessionid"`
	SNIHostname      string          `json:"snihostname"`
	Version          string          `json:"version"`
}

type NameValue struct {
	Name  string `json:"name"`
	Value string `json:"value"`
}

type RequestData struct {
	BodyBytes    uint64                 `json:"bodybytes"`
	HeadersBytes uint64                 `json:"headersbytes"`
	OriginalPath string                 `json:"originalpath"`
	Headers      map[string]string      `json:"headers"`
	Cookies      map[string]string      `json:"cookies"`
	Arguments    map[string]string      `json:"arguments"`
	Geo          map[string]interface{} `json:"geo"`
	Attributes   map[string]interface{} `json:"attributes"`
}

type ResponseData struct {
	BodyBytes    uint64            `json:"bodybytes"`
	Code         int               `json:"code"`
	CodeDetails  string            `json:"codedetails"`
	Headers      map[string]string `json:"headers"`
	HeadersBytes uint64            `json:"headersbytes"`
	Trailers     map[string]string `json:"trailers"`
}

type MetadataData struct {
	DelayInjected              bool    `json:"delayinjected"`
	FailedLocalHealthCheck     bool    `json:"failedlocalhealthcheck"`
	FaultInjected              bool    `json:"faultinjected"`
	InvalidEnvoyRequestHeaders bool    `json:"invalidenvoyrequestheaders"`
	LocalReset                 bool    `json:"localreset"`
	NoHealthyUpstream          bool    `json:"nohealthyupstream"`
	NoRouteFound               bool    `json:"noroutefound"`
	RateLimited                bool    `json:"ratelimited"`
	RateLimitServiceError      bool    `json:"ratelimitserviceerror"`
	RouteName                  string  `json:"routename"`
	SampleRate                 float64 `json:"samplerate"`
	StreamIdleTimeout          bool    `json:"streamidletimeout"`
	UnauthorizedDetails        string  `json:"unauthorizeddetails"`
}

type CuriefenseLog struct {
	RequestId string `json:"requestid"`
	Timestamp string `json:"timestamp"`
	Scheme    string `json:"scheme"`
	Authority string `json:"authority"`
	Port      uint32 `json:"port"`
	Method    string `json:"method"`
	Path      string `json:"path"`

	Blocked     bool                   `json:"blocked"`
	BlockReason map[string]interface{} `json:"block_reason"`
	Tags        []string               `json:"tags"`

	RXTimers RXTimer `json:"timers"`
	TXTimers TXTimer `json:"timers"`

	Upstream   UpstreamData   `json:"upstream"`
	Downstream DownstreamData `json:"downstream"`

	TLS      TLSData      `json:"tls"`
	Request  RequestData  `json:"request"`
	Response ResponseData `json:"response"`
	Metadata MetadataData `json:"metadata"`
}

type LogEntry struct {
	fullEntry     *ald.HTTPAccessLogEntry
	cfLog         *CuriefenseLog
	curieProxyLog *CurieProxyLog
}

type Logger interface {
	Configure(channel_capacity int) error
	ConfigureFromEnv(envVar string, channel_capacity int) error
	Start()
	GetLogEntry() LogEntry
	SendEntry(e LogEntry)
	InsertEntry(e LogEntry) bool
}

type logger struct {
	name      string
	channel   chan LogEntry
	url       string
	do_insert func(LogEntry) bool
}

func (l logger) SendEntry(e LogEntry) {
	if len(l.channel) >= cap(l.channel) {
		metric_dropped_log_entry.With(prometheus.Labels{"logger": l.name}).Inc()
		log.Printf("[WARNING] [%s] buffer full (%v/%v). Log entry dropped", l.name, len(l.channel), cap(l.channel))
	} else {
		l.channel <- e
	}
}

func (l *logger) Configure(channel_capacity int) error {
	l.name = "Generic Logger"
	l.channel = make(chan LogEntry, channel_capacity)
	return nil
}

func (l *logger) ConfigureFromEnv(envVar string, channel_capacity int) error {
	url, ok := os.LookupEnv(envVar)
	if !ok {
		return errors.New(fmt.Sprintf("Did not find %s in environment", envVar))
	}
	l.url = url
	return l.Configure(channel_capacity)
}

func (l logger) Start() {
	log.Printf("[INFO] %s logging routine started", l.name)
	for {
		entry := l.GetLogEntry()
		now := time.Now()
		l.do_insert(entry)
		metric_logger_latency.With(prometheus.Labels{"logger": l.name}).Observe(time.Since(now).Seconds())
	}
}

func (l logger) GetLogEntry() LogEntry {
	return <-l.channel
}

func (l logger) InsertEntry(e LogEntry) bool {
	log.Printf("[ERROR] entry insertion not implemented")
	return false
}

type grpcServerParams struct {
	loggers []Logger
}

//   ___ ___ ___  ___     _   ___ ___ ___ ___ ___   _    ___   ___ ___
//  / __| _ \ _ \/ __|   /_\ / __/ __| __/ __/ __| | |  / _ \ / __/ __|
// | (_ |   /  _/ (__   / _ \ (_| (__| _|\__ \__ \ | |_| (_) | (_ \__ \
//  \___|_|_\_|  \___| /_/ \_\___\___|___|___/___/ |____\___/ \___|___/
// GRPC ACCESS LOGS

func DurationToFloat(d *duration.Duration) float64 {
	if d != nil {
		return float64(d.GetSeconds()) + float64(d.GetNanos())*1e-9
	}
	return 0
}

func TimestampToRFC3339(d *timestamp.Timestamp) string {
	var v time.Time
	if d != nil {
		v = time.Unix(int64(d.GetSeconds()), int64(d.GetNanos()))
	} else {
		v = time.Now()
	}
	return v.Format(time.RFC3339Nano)
}

func MapToNameValue(m map[string]string) []NameValue {
	var res []NameValue
	for k, v := range m {
		res = append(res, NameValue{k, v})
	}
	return res
}

func (s grpcServerParams) StreamAccessLogs(x als.AccessLogService_StreamAccessLogsServer) error {
	msg, err := x.Recv()
	if err != nil {
		log.Printf("[ERROR] Error receiving grpc stream message: %v", err)
	} else {
		log.Printf("[DEBUG] ====>[%v]", msg.LogEntries)
		hl := msg.GetHttpLogs()
		http_entries := hl.GetLogEntry()
		for _, entry := range http_entries {

			common := entry.GetCommonProperties()
			// Decode curiefense metadata

			curiefense_meta, got_meta := common.GetMetadata().GetFilterMetadata()["com.reblaze.curiefense"]
			if !got_meta { /* This log line was not generated by curiefense */
				log.Printf("[DEBUG] No curiefense metadata => drop log entry")
				continue
			}

			var curieProxyLog CurieProxyLog

			cfm := curiefense_meta.GetFields()
			if rqinfo_s, ok := cfm["request.info"]; ok {
				curiefense_json_string := rqinfo_s.GetStringValue()
				err := json.Unmarshal([]byte(curiefense_json_string), &curieProxyLog)
				if err != nil {
					log.Printf("[ERROR] Error unmarshalling metadata json string [%v]: %v", curiefense_json_string, err)
					continue
				}
			} else {
				log.Printf("[ERROR] did not find request.info in curiefense medatada")
				continue
			}

			log.Printf("[DEBUG] XXXXXXXX curieproxylog=%v", curieProxyLog)

			// Shortcuts

			req := entry.GetRequest()
			resp := entry.GetResponse()
			respflags := common.GetResponseFlags()
			tls := common.GetTlsProperties()
			lan := []string{}
			for _, san := range tls.GetLocalCertificateProperties().GetSubjectAltName() {
				lan = append(lan, san.String())
			}
			pan := []string{}
			for _, san := range tls.GetPeerCertificateProperties().GetSubjectAltName() {
				pan = append(pan, san.String())
			}

			// Create canonical curiefense log structure

			cflog := CuriefenseLog{
				RequestId:   req.GetRequestId(),
				Timestamp:   TimestampToRFC3339(common.GetStartTime()),
				Scheme:      req.GetScheme(),
				Authority:   req.GetAuthority(),
				Port:        req.GetPort().GetValue(),
				Method:      req.GetRequestMethod().String(),
				Path:        req.GetPath(),
				Blocked:     curieProxyLog.Blocked,
				BlockReason: curieProxyLog.BlockReason,
				Tags:        curieProxyLog.Tags,

				RXTimers: RXTimer{
					FirstUpstreamByte: DurationToFloat(common.GetTimeToFirstUpstreamRxByte()),
					LastUpstreamByte:  DurationToFloat(common.GetTimeToLastUpstreamRxByte()),
					LastByte:          DurationToFloat(common.GetTimeToLastRxByte()),
				},
				TXTimers: TXTimer{
					FirstUpstreamByte:   DurationToFloat(common.GetTimeToFirstUpstreamTxByte()),
					LastUpstreamByte:    DurationToFloat(common.GetTimeToLastUpstreamTxByte()),
					FirstDownstreamByte: DurationToFloat(common.GetTimeToFirstDownstreamTxByte()),
					LastDownstreamByte:  DurationToFloat(common.GetTimeToLastDownstreamTxByte()),
				},
				Downstream: DownstreamData{
					ConnectionTermination:   respflags.GetDownstreamConnectionTermination(),
					DirectRemoteAddress:     common.GetDownstreamDirectRemoteAddress().GetSocketAddress().GetAddress(),
					DirectRemoteAddressPort: common.GetDownstreamDirectRemoteAddress().GetSocketAddress().GetPortValue(),
					LocalAddress:            common.GetDownstreamLocalAddress().GetSocketAddress().GetAddress(),
					LocalAddressPort:        common.GetDownstreamLocalAddress().GetSocketAddress().GetPortValue(),
					ProtocolError:           respflags.GetDownstreamProtocolError(),
					RemoteAddress:           common.GetDownstreamRemoteAddress().GetSocketAddress().GetAddress(),
					RemoteAddressPort:       common.GetDownstreamRemoteAddress().GetSocketAddress().GetPortValue(),
				},
				Upstream: UpstreamData{
					Cluster:                common.GetUpstreamCluster(),
					ConnectionFailure:      respflags.GetUpstreamConnectionFailure(),
					ConnectionTermination:  respflags.GetUpstreamConnectionTermination(),
					LocalAddress:           common.GetUpstreamLocalAddress().GetSocketAddress().GetAddress(),
					LocalAddressPort:       common.GetUpstreamLocalAddress().GetSocketAddress().GetPortValue(),
					Overflow:               respflags.GetUpstreamOverflow(),
					RemoteAddress:          common.GetUpstreamRemoteAddress().GetSocketAddress().GetAddress(),
					RemoteAddressPort:      common.GetUpstreamRemoteAddress().GetSocketAddress().GetPortValue(),
					RemoteReset:            respflags.GetUpstreamRemoteReset(),
					RequestTimeout:         respflags.GetUpstreamRequestTimeout(),
					RetryLimitExceeded:     respflags.GetUpstreamRetryLimitExceeded(),
					TransportFailureReason: common.GetUpstreamTransportFailureReason(),
				},
				TLS: TLSData{
					LocalCertificate: CertificateData{
						Properties:         tls.GetLocalCertificateProperties().GetSubject(),
						PropertiesAltNames: lan,
					},
					PeerCertificate: CertificateData{
						Properties:         tls.GetPeerCertificateProperties().GetSubject(),
						PropertiesAltNames: pan,
					},
					CipherSuite: tls.GetTlsCipherSuite().String(),
					SessionId:   tls.GetTlsSessionId(),
					SNIHostname: tls.GetTlsSniHostname(),
					Version:     tls.GetTlsVersion().String(),
				},
				Request: RequestData{
					BodyBytes:    req.GetRequestBodyBytes(),
					HeadersBytes: req.GetRequestHeadersBytes(),
					OriginalPath: req.GetOriginalPath(),
					Headers:      curieProxyLog.Headers,
					Cookies:      curieProxyLog.Cookies,
					Arguments:    curieProxyLog.Arguments,
					Geo:          curieProxyLog.Geo,
					Attributes:   curieProxyLog.Attributes,
				},
				Response: ResponseData{
					BodyBytes:    resp.GetResponseBodyBytes(),
					Code:         int(resp.GetResponseCode().GetValue()),
					CodeDetails:  resp.GetResponseCodeDetails(),
					Headers:      resp.GetResponseHeaders(),
					HeadersBytes: resp.GetResponseHeadersBytes(),
					Trailers:     resp.GetResponseTrailers(),
				},
				Metadata: MetadataData{
					DelayInjected:              respflags.GetDelayInjected(),
					FailedLocalHealthCheck:     respflags.GetFailedLocalHealthcheck(),
					FaultInjected:              respflags.GetFaultInjected(),
					InvalidEnvoyRequestHeaders: respflags.GetInvalidEnvoyRequestHeaders(),
					LocalReset:                 respflags.GetLocalReset(),
					NoHealthyUpstream:          respflags.GetNoHealthyUpstream(),
					NoRouteFound:               respflags.GetNoRouteFound(),
					RateLimited:                respflags.GetRateLimited(),
					RateLimitServiceError:      respflags.GetRateLimitServiceError(),
					RouteName:                  common.GetRouteName(),
					SampleRate:                 common.GetSampleRate(),
					StreamIdleTimeout:          respflags.GetStreamIdleTimeout(),
					UnauthorizedDetails:        respflags.GetUnauthorizedDetails().GetReason().String(),
				},
			}

			log.Printf("[DEBUG] ---> [ %v:%v %v:%v ] <---", cflog.Downstream.RemoteAddress, cflog.Downstream.RemoteAddressPort,
				cflog.Downstream.LocalAddress, cflog.Downstream.LocalAddressPort)

			log.Printf("[DEBUG] cflog=%v", cflog)

			log_entry := LogEntry{
				fullEntry:     entry,
				cfLog:         &cflog,
				curieProxyLog: &curieProxyLog,
			}

			for _, l := range s.loggers {
				l.SendEntry(log_entry)
			}
		}
	}
	return nil
}

//  __  __   _   ___ _  _
// |  \/  | /_\ |_ _| \| |
// | |\/| |/ _ \ | || .` |
// |_|  |_/_/ \_\___|_|\_|
// MAIN

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

func check_env_flag(env_var string) bool {
	value, ok := os.LookupEnv(env_var)
	return ok && value != "" && value != "0" && strings.ToLower(value) != "false"
}

func readPassword(filename string) string {
	file, err := os.Open(filename)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		return scanner.Text()
	}
	log.Fatal("Could not read password")
	return ""
}

var (
	grpc_addr = getEnv("CURIELOGGER_GRPC_LISTEN", ":9001")
	prom_addr = getEnv("CURIELOGGER_PROMETHEUS_LISTEN", ":2112")
)

func main() {
	log.Print("Starting curielogger v0.3-dev1")

	pflag.String("log_level", "info", "Debug mode")
	pflag.Int("channel_capacity", 65536, "log channel capacity")

	pflag.Parse()
	viper.BindPFlags(pflag.CommandLine)

	config, err := LoadConfig()
	if err != nil {
		log.Fatal("cannot load config:", err)
	}

	// configure log level
	filter := &logutils.LevelFilter{
		Levels:   []logutils.LogLevel{"DEBUG", "INFO", "ERROR"},
		MinLevel: logutils.LogLevel(strings.ToUpper(config.LogLevel)),
		Writer:   os.Stderr,
	}
	log.SetOutput(filter)

	log.Printf("[INFO] Log level set at %v", config.LogLevel)
	log.Printf("[INFO] Channel capacity set at %v", config.ChannelCapacity)

	// set up prometheus server
	http.Handle("/metrics", promhttp.Handler())
	log.Printf("Prometheus exporter listening on %v", prom_addr)
	go http.ListenAndServe(prom_addr, nil)

	////////////////////
	// set up loggers //
	////////////////////

	grpcParams := grpcServerParams{loggers: []Logger{}}

	// Prometheus
	if check_env_flag("CURIELOGGER_METRICS_PROMETHEUS_ENABLED") {
		prom := promLogger{logger{name: "prometheus", channel: make(chan LogEntry, config.ChannelCapacity)}}
		grpcParams.loggers = append(grpcParams.loggers, &prom)
	}

	configRetry := func(params *grpcServerParams, logger Logger) {
		for i := 0; i < 60; i++ {
			err := logger.Configure(config.ChannelCapacity)

			if err == nil {
				grpcParams.loggers = append(params.loggers, logger)
				logger.Start()
				break
			}

			log.Printf("[ERROR]: failed to configure logger (retrying in 5s) %v %v", logger, err)
			time.Sleep(5 * time.Second)
		}
	}

	// ElasticSearch
	if config.Outputs.Elasticsearch.Enabled {
		log.Printf("[DEBUG] Elasticsearch enabled with URL: %s", config.Outputs.Elasticsearch.Url)
		es := ElasticsearchLogger{config: config.Outputs.Elasticsearch}
		go configRetry(&grpcParams, &es)
	}

	// Logstash
	if config.Outputs.Logstash.Enabled {
		log.Printf("[DEBUG] Logstash enabled with URL: %s", config.Outputs.Logstash.Url)
		ls := logstashLogger{config: config.Outputs.Logstash}
		go configRetry(&grpcParams, &ls)
	}

	// Fluentd
	if check_env_flag("CURIELOGGER_USES_FLUENTD") {
		fd := fluentdLogger{}
		fd.ConfigureFromEnv("CURIELOGGER_FLUENTD_URL", config.ChannelCapacity)
		grpcParams.loggers = append(grpcParams.loggers, &fd)
	}

	for _, l := range grpcParams.loggers {
		go l.Start()
	}

	////////////////////////
	// set up GRPC server //
	////////////////////////

	sock, err := net.Listen("tcp", grpc_addr)
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	log.Printf("GRPC server listening on %v", grpc_addr)
	s := grpc.NewServer()

	als.RegisterAccessLogServiceServer(s, &grpcParams)
	if err := s.Serve(sock); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
