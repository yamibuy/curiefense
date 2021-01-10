package main

import (
	"context"
	"encoding/json"
	"fmt"

	"google.golang.org/grpc"
	"log"
	"net"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"
	"flag"
	"bufio"

	als "github.com/envoyproxy/go-control-plane/envoy/service/accesslog/v2"
	ald "github.com/envoyproxy/go-control-plane/envoy/data/accesslog/v2"
	ptypes "github.com/golang/protobuf/ptypes"
	duration "github.com/golang/protobuf/ptypes/duration"

	"github.com/jackc/pgx/pgtype"
	"github.com/jackc/pgx/v4"

	"net/http"

	"github.com/hashicorp/logutils"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"

	elasticsearch "github.com/elastic/go-elasticsearch/v7"
)



//   ___ ___  __  __ __  __  ___  _  _
//  / __/ _ \|  \/  |  \/  |/ _ \| \| |
// | (_| (_) | |\/| | |\/| | (_) | .` |
//  \___\___/|_|  |_|_|  |_|\___/|_|\_|
// COMMON



type LogEntry struct {
	full_entry *ald.HTTPAccessLogEntry;
	common *ald.AccessLogCommon;
	req *ald.HTTPRequestProperties;
	resp *ald.HTTPResponseProperties;
	method string;
	response_code int;
	curiefense_json_string string;
	curiefense map[string]interface{};
	upstream_remote_addr string;
	upstream_remote_port uint32;
	upstream_local_addr string;
	upstream_local_port uint32;
}


type Logger struct {
	name string
	channel chan LogEntry
}


func (l Logger) log_entry(e LogEntry) {
	if len(l.channel) >= cap(l.channel) {
		metric_dropped_log_entry.With(prometheus.Labels{"logger":l.name}).Inc()
		log.Printf("[WARNING] [%s] buffer full. Log entry dropped", l.name)
	} else {
		l.channel <- e
	}
}

type server struct {
	host string
	loggers []Logger
}



//  ___ ___  ___  __  __ ___ _____ _  _ ___ _   _ ___
// | _ \ _ \/ _ \|  \/  | __|_   _| || | __| | | / __|
// |  _/   / (_) | |\/| | _|  | | | __ | _|| |_| \__ \
// |_| |_|_\\___/|_|  |_|___| |_| |_||_|___|\___/|___/
// PROMETHEUS

const (
	namespace = "curiemetric" // For Prometheus metrics.
)

/** Prometheus metrics **/

var (
	metric_requests = promauto.NewCounter(
		prometheus.CounterOpts{
			Namespace: namespace,
			Name:      "http_request_total",
			Help:      "Total number of HTTP requests",
		},
	)

	metric_session_details = promauto.NewCounterVec(prometheus.CounterOpts{
		Namespace: namespace,
		Name:      "session_details_total",
		Help:      "number of requests per label",
	}, []string{
		"status_code",
		"status_class",
		"origin",
		"origin_status_code",
		"origin_status_class",
		"method",
		"path",
		"blocked",
		"asn",
		"geo",
		"aclid",
		"aclname",
		"wafid",
		"wafname",
		"urlmap",
		"urlmap_entry",
		"container",
	})

	metric_dropped_log_entry = promauto.NewCounterVec(prometheus.CounterOpts{
		Namespace: namespace,
		Name:      "dropped_log_entries",
		Help:      "number of dropped log entries per logger",
	}, []string{"logger"})

	metric_request_bytes = promauto.NewCounter(prometheus.CounterOpts{
		Namespace: namespace,
		Name:      "request_bytes",
		Help:      "The total number of request bytes",
	})
	metric_response_bytes = promauto.NewCounter(prometheus.CounterOpts{
		Namespace: namespace,
		Name:      "response_bytes",
		Help:      "The total number of response bytes",
	})

	m_requests_tags = promauto.NewCounterVec(prometheus.CounterOpts{
		Namespace: namespace,
		Name:      "session_tags_total",
		Help:      "Number of requests per label",
	}, []string{"tag"})


	metric_logger_latency = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Namespace: namespace,
		Name:      "logger_latency",
		Help:      "latency per logger",
	}, []string{"logger"})
)


/**** \\\ auto labeling /// ****/

func isStaticTag(tag string) bool {
	if tag == "all" {
		return true
	}
	parts := strings.Split(tag, ":")
	if len(parts) > 1 {
		prefix := parts[0]
		var static_tags = map[string]bool{
			"ip":           true,
			"asn":          true,
			"geo":          true,
			"aclid":        true,
			"aclname":      true,
			"wafid":        true,
			"wafname":      true,
			"urlmap":       true,
			"urlmap-entry": true,
			"container":    true,
		}
		return static_tags[prefix]
	}
	return false
}

func extractTagByPrefix(prefix string, tags map[string]interface{}) string {

	for name := range tags {
		tagsplit := strings.Split(name, ":")
		if len(tagsplit) == 2 {
			tag_prefix, value := tagsplit[0], tagsplit[1]
			if tag_prefix == prefix {
				return value
			}
		}

	}

	return "N/A"
}

func makeLabels(status_code int, method, path, upstream, blocked string, tags map[string]interface{}) prometheus.Labels {

	// classes and specific response code
	// icode := int(status_code)
	class_label := "status_Nxx"

	switch {
	case status_code < 200:
		class_label = "status_1xx"
	case status_code > 199 && status_code < 300:
		class_label = "status_2xx"
	case status_code > 299 && status_code < 400:
		class_label = "status_3xx"
	case status_code > 399 && status_code < 500:
		class_label = "status_4xx"
	case status_code > 499 && status_code < 600:
		class_label = "status_5xx"
	}

	status_code_str := strconv.Itoa(status_code)

	origin := "N/A"
	origin_status_code := "N/A"
	origin_status_class := "N/A"

	if len(upstream) > 0 {
		origin = upstream
		origin_status_code = fmt.Sprintf("origin_%s", status_code_str)
		origin_status_class = fmt.Sprintf("origin_%s", class_label)
	}

	return prometheus.Labels{
		"status_code":         status_code_str,
		"status_class":        class_label,
		"origin":              origin,
		"origin_status_code":  origin_status_code,
		"origin_status_class": origin_status_class,
		"method":              method,
		"path":                path,
		"blocked":             blocked,
		"asn":                 extractTagByPrefix("asn", tags),
		"geo":                 extractTagByPrefix("geo", tags),
		"aclid":               extractTagByPrefix("aclid", tags),
		"aclname":             extractTagByPrefix("aclname", tags),
		"wafid":               extractTagByPrefix("wafid", tags),
		"wafname":             extractTagByPrefix("wafname", tags),
		"urlmap":              extractTagByPrefix("urlmap", tags),
		"urlmap_entry":        extractTagByPrefix("urlmap-entry", tags),
		"container":           extractTagByPrefix("container", tags),
	}
}


type PromServer struct {
	logger Logger
}


func (s PromServer) start() {
	log.Printf("[INFO]: Prometheus metrics updating routine started")

	for {
		e := <- s.logger.channel

		// **** Update prometheus metrics ****
		metric_requests.Inc()
		metric_request_bytes.Add(float64(e.req.GetRequestHeadersBytes() + e.req.GetRequestBodyBytes()))
		metric_response_bytes.Add(float64(e.resp.GetResponseHeadersBytes() + e.resp.GetResponseBodyBytes()))


		if attrs_i, ok := e.curiefense["attrs"] ; ok {
			if attrs, ok := attrs_i.(map[string]interface{}); ok {
				blocked := "0"
				if _, ok := attrs["blocked"]; ok {
					blocked = "1"
				}
				log.Printf("[DEBUG] ~~~ blocked=[%v]", blocked)
				if tags_i, ok := attrs["tags"]; ok {
					if tags, ok := tags_i.(map[string]interface{}); ok {
						if path_i, ok := attrs["path"]; ok {
							if path, ok := path_i.(string); ok {
								log.Printf("[DEBUG] ~~~ path=[%v]", path)
								log.Printf("[DEBUG] ~~~ tags=[%v]", tags)
								labels := makeLabels(e.response_code, e.method, path, e.upstream_remote_addr, blocked, tags)
								metric_session_details.With(labels).Inc()
								for name := range tags {
									if !isStaticTag(name) {
										m_requests_tags.WithLabelValues(name).Inc()
									}
								}
							} else { log.Printf("[DEBUG]  @ no path cast :(") }
						} else { log.Printf("[DEBUG]  @ no path :(") }
					} else { log.Printf("[DEBUG]  @ no tags cast :( [%v]", tags_i) }
				} else { log.Printf("[DEBUG]  @ no tags :(") }
			} else { log.Printf("[DEBUG]  @ no attr cast :(") }
		} else { log.Printf("[DEBUG]  @ no attrs :(") }
	}
}






//  ___  ___  ___ _____ ___ ___ ___ ___  ___  _
// | _ \/ _ \/ __|_   _/ __| _ \ __/ __|/ _ \| |
// |  _/ (_) \__ \ | || (_ |   / _|\__ \ (_) | |__
// |_|  \___/|___/ |_| \___|_|_\___|___/\__\_\____|
// POSTGRESQL


type PGserver struct {
	host string
	db_url string
	db     *pgx.Conn
	logger Logger
}

func DurationToFloat(d *duration.Duration) float64 {
	if d != nil {
		return float64(d.GetSeconds()) + float64(d.GetNanos())*1e-9
	}
	return 0
}


func (s PGserver) getDB() *pgx.Conn {
	for s.db == nil || s.db.IsClosed() {
		conn, err := pgx.Connect(context.Background(), s.db_url)
		if err == nil {
			s.db = conn
			log.Printf("[DEBUG] Connected to database %v\n", s.host)
			break
		}
		log.Printf("[ERROR] Could not connect to database %v: %v\n", s.host, err)
		time.Sleep(time.Second)
	}
	return s.db
}


func (s PGserver) start() bool {
	log.Printf("[INFO]: Postgres logging routine started")
	db := s.getDB()
	for {
		entry := <-s.logger.channel
		now := time.Now()
		db = s.getDB() // needed to ensure db cnx is not closed and reopen it if needed
		pg_insert_entry(db, entry)
		metric_logger_latency.With(prometheus.Labels{"logger":s.logger.name}).Observe(time.Since(now).Seconds())
	}
}


func pg_insert_entry(db *pgx.Conn, e LogEntry) bool {

	respflags := e.common.GetResponseFlags()

	ts, _ := ptypes.Timestamp(e.common.GetStartTime())

	tls := e.common.GetTlsProperties()

	lan := []string{}
	for _, san := range tls.GetLocalCertificateProperties().GetSubjectAltName() {
		lan = append(lan, san.String())
	}
	jsonb_localaltnames := makejsonb(lan)

	pan := []string{}
	for _, san := range tls.GetPeerCertificateProperties().GetSubjectAltName() {
		pan = append(pan, san.String())
	}
	jsonb_peeraltnames := makejsonb(pan)

	jsonb_reqhdr := makejsonb(e.req.GetRequestHeaders())
	jsonb_resphdr := makejsonb(e.resp.GetResponseHeaders())
	jsonb_resptrail := makejsonb(e.resp.GetResponseTrailers())


	jsonb_curiefense := &pgtype.JSON{Bytes: []byte(e.curiefense_json_string), Status: pgtype.Present}

	_, err := db.Exec(context.Background(), `insert into logs (

            SampleRate, DownstreamRemoteAddress, DownstreamRemoteAddressPort, DownstreamLocalAddress,
            DownstreamLocalAddressPort, StartTime, TimeToLastRxByte, TimeToFirstUpstreamTxByte, TimeToLastUpstreamTxByte,
            TimeToFirstUpstreamRxByte, TimeToLastUpstreamRxByte, TimeToFirstDownstreamTxByte, TimeToLastDownstreamTxByte,
            UpstreamRemoteAddress, UpstreamRemoteAddressPort, UpstreamLocalAddress, UpstreamLocalAddressPort,
            UpstreamCluster, FailedLocalHealthcheck, NoHealthyUpstream, UpstreamRequestTimeout, LocalReset,
            UpstreamRemoteReset, UpstreamConnectionFailure, UpstreamConnectionTermination, UpstreamOverflow, NoRouteFound,
            DelayInjected, FaultInjected, RateLimited, UnauthorizedDetails, RateLimitServiceError,
            DownstreamConnectionTermination, UpstreamRetryLimitExceeded, StreamIdleTimeout, InvalidEnvoyRequestHeaders,
            DownstreamProtocolError, Curiefense, UpstreamTransportFailureReason, RouteName, DownstreamDirectRemoteAddress,
            DownstreamDirectRemoteAddressPort, TlsVersion, TlsCipherSuite, TlsSniHostname, LocalCertificateProperties,
            LocalCertificatePropertiesAltNames, PeerCertificateProperties, PeerCertificatePropertiesAltNames,
            TlsSessionId, RequestMethod, Scheme, Authority, Port, Path, UserAgent, Referer, ForwardedFor, RequestId,
            OriginalPath, RequestHeadersBytes, RequestBodyBytes, RequestHeaders, ResponseCode, ResponseHeadersBytes,
            ResponseBodyBytes, ResponseHeaders, ResponseTrailers, ResponseCodeDetails)

            values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20,
                    $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38,
                    $39, $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $50, $51, $52, $53, $54, $55, $56,
                     $57, $58, $59, $60, $61, $62, $63, $64, $65, $66, $67, $68, $69)`,
		e.common.GetSampleRate(),							/* SampleRate,                          */
		e.common.GetDownstreamRemoteAddress().GetSocketAddress().GetAddress(),		/* DownstreamRemoteAddress,             */
		e.common.GetDownstreamRemoteAddress().GetSocketAddress().GetPortValue(),	/* DownstreamRemoteAddressPort,         */
		e.common.GetDownstreamLocalAddress().GetSocketAddress().GetAddress(),		/* DownstreamLocalAddress,              */
		e.common.GetDownstreamLocalAddress().GetSocketAddress().GetPortValue(),		/* DownstreamLocalAddressPort,          */
		ts,										/* StartTime,                           */
		DurationToFloat(e.common.GetTimeToLastRxByte()),				/* TimeToLastRxByte,                    */
		DurationToFloat(e.common.GetTimeToFirstUpstreamTxByte()),			/* TimeToFirstUpstreamTxByte,           */
		DurationToFloat(e.common.GetTimeToLastUpstreamTxByte()),			/* TimeToLastUpstreamTxByte,            */
		DurationToFloat(e.common.GetTimeToFirstUpstreamRxByte()),			/* TimeToFirstUpstreamRxByte,           */
		DurationToFloat(e.common.GetTimeToLastUpstreamRxByte()),			/* TimeToLastUpstreamRxByte,            */
		DurationToFloat(e.common.GetTimeToFirstDownstreamTxByte()),			/* TimeToFirstDownstreamTxByte,         */
		DurationToFloat(e.common.GetTimeToLastDownstreamTxByte()),			/* TimeToLastDownstreamTxByte,          */
		e.upstream_remote_addr,								/* UpstreamRemoteAddress,               */
		e.upstream_remote_port,								/* UpstreamRemoteAddressPort,           */
		e.upstream_local_addr,								/* UpstreamLocalAddress,                */
		e.upstream_local_port,								/* UpstreamLocalAddressPort,            */
		e.common.GetUpstreamCluster(),							/* UpstreamCluster,                     */
		respflags.GetFailedLocalHealthcheck(),						/* FailedLocalHealthcheck,              */
		respflags.GetNoHealthyUpstream(),						/* NoHealthyUpstream,                   */
		respflags.GetUpstreamRequestTimeout(),						/* UpstreamRequestTimeout,              */
		respflags.GetLocalReset(),							/* LocalReset,                          */
		respflags.GetUpstreamRemoteReset(),						/* UpstreamRemoteReset,                 */
		respflags.GetUpstreamConnectionFailure(),					/* UpstreamConnectionFailure,           */
		respflags.GetUpstreamConnectionTermination(),					/* UpstreamConnectionTermination,       */
		respflags.GetUpstreamOverflow(),						/* UpstreamOverflow,                    */
		respflags.GetNoRouteFound(),							/* NoRouteFound,                        */
		respflags.GetDelayInjected(),							/* DelayInjected,                       */
		respflags.GetFaultInjected(),							/* FaultInjected,                       */
		respflags.GetRateLimited(),							/* RateLimited,                         */
		respflags.GetUnauthorizedDetails().GetReason().String(),			/* UnauthorizedDetails,                 */
		respflags.GetRateLimitServiceError(),						/* RateLimitServiceError,               */
		respflags.GetDownstreamConnectionTermination(),					/* DownstreamConnectionTermination,     */
		respflags.GetUpstreamRetryLimitExceeded(),					/* UpstreamRetryLimitExceeded,          */
		respflags.GetStreamIdleTimeout(),						/* StreamIdleTimeout,                   */
		respflags.GetInvalidEnvoyRequestHeaders(),					/* InvalidEnvoyRequestHeaders,          */
		respflags.GetDownstreamProtocolError(),						/* DownstreamProtocolError,             */
		jsonb_curiefense,								/* Curiefense,                          */
		e.common.GetUpstreamTransportFailureReason(),					/* UpstreamTransportFailureReason,      */
		e.common.GetRouteName(),							/* RouteName,                           */
		e.common.GetDownstreamDirectRemoteAddress().GetSocketAddress().GetAddress(),	/* DownstreamDirectRemoteAddress,       */
		e.common.GetDownstreamDirectRemoteAddress().GetSocketAddress().GetPortValue(),	/* DownstreamDirectRemoteAddressPort,   */
		tls.GetTlsVersion().String(),							/* TlsVersion,                          */
		tls.GetTlsCipherSuite().String(),						/* TlsCipherSuite,                      */
		tls.GetTlsSniHostname(),							/* TlsSniHostname,                      */
		tls.GetLocalCertificateProperties().GetSubject(),				/* LocalCertificateProperties,          */
		jsonb_localaltnames,								/* LocalCertificatePropertiesAltNames,  */
		tls.GetPeerCertificateProperties().GetSubject(),				/* PeerCertificateProperties,           */
		jsonb_peeraltnames,								/* PeerCertificatePropertiesAltNames,   */
		tls.GetTlsSessionId(),								/* TlsSessionId,                        */
		e.method,										/* RequestMethod,                       */
		e.req.GetScheme(),								/* Scheme,                              */
		e.req.GetAuthority(),								/* Authority,                           */
		e.req.GetPort().GetValue(),							/* Port,                                */
		e.req.GetPath(),									/* Path,                                */
		e.req.GetUserAgent(),								/* UserAgent,                           */
		e.req.GetReferer(),								/* Referer,                             */
		e.req.GetForwardedFor(),								/* ForwardedFor,                        */
		e.req.GetRequestId(),								/* RequestId,                           */
		e.req.GetOriginalPath(),								/* OriginalPath,                        */
		e.req.GetRequestHeadersBytes(),							/* RequestHeadersBytes,                 */
		e.req.GetRequestBodyBytes(),							/* RequestBodyBytes,                    */
		jsonb_reqhdr,									/* RequestHeaders,                      */
		e.response_code,									/* ResponseCode,                        */
		e.resp.GetResponseHeadersBytes(),							/* ResponseHeadersBytes,                */
		e.resp.GetResponseBodyBytes(),							/* ResponseBodyBytes                    */
		jsonb_resphdr,									/* ResponseHeaders,                     */
		jsonb_resptrail,								/* ResponseTrailers,                    */
		e.resp.GetResponseCodeDetails(),							/* ResponseCodeDetails                  */
	)
	if err == nil {
		log.Printf("[DEBUG] insert into pg ok")
	} else {
		log.Printf("[ERROR] insert into pg: Error: %v", err)
	}
	return err != nil
}


//  ___ _      _   ___ _____ ___ ___ ___ ___   _   ___  ___ _  _
// | __| |    /_\ / __|_   _|_ _/ __/ __| __| /_\ | _ \/ __| || |
// | _|| |__ / _ \\__ \ | |  | | (__\__ \ _| / _ \|   / (__| __ |
// |___|____/_/ \_\___/ |_| |___\___|___/___/_/ \_\_|_\\___|_||_|
// ELASTICSEARCH

type ESserver struct {
	es_url string
	es     *elasticsearch.Client
	logger Logger
}

func (s ESserver) getES() *elasticsearch.Client {
	for s.es == nil {
		cfg := elasticsearch.Config{
			Addresses: []string{ s.es_url },
		}
		conn, err := elasticsearch.NewClient(cfg)
		if err == nil {
			s.es = conn
			log.Printf("[DEBUG] Connected to elasticsearch %v\n", s.es_url)
			break
		}
		log.Printf("[ERROR] Could not connect to elasticsearch [%v]: %v\n", s.es_url, err)
		time.Sleep(time.Second)
	}
	return s.es
}


func (s ESserver) start() {
	log.Printf("[INFO]: ElasticSearch logging routine started")
	es := s.getES()
	for {
		entry := <-s.logger.channel
		now := time.Now()
		es = s.getES() // needed to ensure ES cnx is not closed and reopen it if needed
		es_insert_entry(es, entry)
		metric_logger_latency.With(prometheus.Labels{"logger":s.logger.name}).Observe(time.Since(now).Seconds())
	}
}


func es_insert_entry(es *elasticsearch.Client, e LogEntry) {
	log.Printf("[DEBUG] ES insertion!")
	j, err := json.Marshal(e.full_entry)
	if err == nil {
		es.Index(
			"log",
			strings.NewReader(string(j)),
			es.Index.WithRefresh("true"),
			es.Index.WithPretty(),
			es.Index.WithFilterPath("result", "_id"),
		)
	} else {
		log.Printf("[ERROR] Could not convert protobuf entry into json for ES insertion.")
	}
	if (e.curiefense_json_string != "") {
		es.Index(
			"log_cf",
			strings.NewReader(e.curiefense_json_string),
			es.Index.WithRefresh("true"),
			es.Index.WithPretty(),
			es.Index.WithFilterPath("result", "_id"),
		)
	}
}





//   ___ ___ ___  ___     _   ___ ___ ___ ___ ___   _    ___   ___ ___
//  / __| _ \ _ \/ __|   /_\ / __/ __| __/ __/ __| | |  / _ \ / __/ __|
// | (_ |   /  _/ (__   / _ \ (_| (__| _|\__ \__ \ | |_| (_) | (_ \__ \
//  \___|_|_\_|  \___| /_/ \_\___\___|___|___/___/ |____\___/ \___|___/
// GRPC ACCESS LOGS



func makejsonb(v interface{}) *pgtype.JSON {
	j, err := json.Marshal(v)
	if err != nil {
		j = []byte("{}")
	}
	return &pgtype.JSON{Bytes: j, Status: pgtype.Present}
}

func (s server) StreamAccessLogs(x als.AccessLogService_StreamAccessLogsServer) error {
	msg, err := x.Recv()
	if err != nil {
		log.Printf("[ERROR] Error receiving grpc stream message: %v", err)
	} else {
		log.Printf("[DEBUG] ====>[%v]", msg.LogEntries)
		hl := msg.GetHttpLogs()
		http_entries := hl.GetLogEntry()
		for _, entry := range http_entries {
			common := entry.GetCommonProperties()
			req := entry.GetRequest()
			resp := entry.GetResponse()
			method := req.GetRequestMethod().String()
			response_code := int(resp.GetResponseCode().GetValue())

			upstream_remote_addr := common.GetUpstreamRemoteAddress().GetSocketAddress().GetAddress()
			upstream_remote_port := common.GetUpstreamRemoteAddress().GetSocketAddress().GetPortValue()
			upstream_local_addr := common.GetUpstreamLocalAddress().GetSocketAddress().GetAddress()
			upstream_local_port := common.GetUpstreamLocalAddress().GetSocketAddress().GetPortValue()
			log.Printf("[DEBUG] ---> [ %v:%v %v:%v ] <---", upstream_remote_addr, upstream_remote_port,
				upstream_local_addr, upstream_local_port)

			// Decode curiefense metadata

			curiefense_meta, got_meta := common.GetMetadata().GetFilterMetadata()["com.reblaze.curiefense"]
			if !got_meta { /* This log line was not generated by curiefense */
				log.Printf("[DEBUG] No curiefense metadata => drop log entry")
				continue
			}

			curiefense := make(map[string]interface{})
			curiefense_json_string := "{}"

			cfm := curiefense_meta.GetFields()
			if rqinfo_s, ok := cfm["request.info"]; ok {
				curiefense_json_string = rqinfo_s.GetStringValue()
				json_cf := []byte(curiefense_json_string)
				err := json.Unmarshal(json_cf, &curiefense)
				if err != nil {
					log.Printf("[ERROR] Error unmarshalling metadata json string [%v]", curiefense_json_string)
				}
			}

			log_entry := LogEntry{
				full_entry:		 entry,
				common:			 common,
				req:			 req,
				resp:			 resp,
				method:			 method,
				response_code:		 response_code,
				curiefense_json_string:	 curiefense_json_string,
				curiefense:		 curiefense,
				upstream_remote_addr:	 upstream_remote_addr,
				upstream_remote_port:	 upstream_remote_port,
				upstream_local_addr:	 upstream_local_addr,
				upstream_local_port:	 upstream_local_port,
			}

			// **** INSERT ****

			for _,l := range s.loggers {
				l.channel <- log_entry
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

	var debug_mode = flag.Bool("d", false, "Debug mode")
	var channel_capacity = flag.Int("b", 65536, "log channel capacity")

	flag.Parse()

	// configure log level
	var min_level string
	if *debug_mode {
		min_level = "DEBUG"
	} else {
		min_level = "ERROR"
	}
	filter := &logutils.LevelFilter{
		Levels: []logutils.LogLevel{"DEBUG", "ERROR"},
		MinLevel: logutils.LogLevel(min_level),
		Writer: os.Stderr,
	}
	log.SetOutput(filter)

	// set up prometheus server
	http.Handle("/metrics", promhttp.Handler())
	log.Printf("Prometheus exporter listening on %v", prom_addr)
	go http.ListenAndServe(prom_addr, nil)


	////////////////////
	// set up loggers //
	////////////////////

	var loggers []Logger

	// Prometheus
	prom_ch := make(chan LogEntry, *channel_capacity)
	l := Logger{name:"prometheus", channel: prom_ch}
	loggers = append(loggers, l)
	prom := PromServer{logger:l}
	go prom.start()

	// PostgreSQL
	if check_env_flag("CURIELOGGER_USES_POSTGRES") {
		db_url, ok := os.LookupEnv("DATABASE_URL")
		var host string
		var password string
		if !ok {
			pwfilename, ok := os.LookupEnv("CURIELOGGER_DBPASSWORD_FILE")
			if ok {
				password = readPassword(pwfilename)
			} else {
				password = os.Getenv("CURIELOGGER_DBPASSWORD")
			}
			host = os.Getenv("CURIELOGGER_DBHOST")
			db_url = fmt.Sprintf(
				"host=%s dbname=curiefense user=%s password=%s",
				host,
				os.Getenv("CURIELOGGER_DBUSER"),
				password,
			)
		} else {
			re := regexp.MustCompile(`host=([^ ]+)`)
			host = re.FindStringSubmatch(db_url)[1]
		}
		pg_ch := make(chan LogEntry, *channel_capacity)
		l := Logger{name:"postgres", channel: pg_ch}
		loggers = append(loggers, l)
		pg := PGserver{host: host, db_url:db_url, logger:l}
		go pg.start()
	}

	// ElasticSearch
	if check_env_flag("CURIELOGGER_USES_ELASTICSEARCH") {
		es_ch := make(chan LogEntry, *channel_capacity)
		l := Logger{name:"elasticsearch", channel: es_ch}
		loggers = append(loggers, l)
		es_url := getEnv("CURIELOGGER_ELASTICSEARCH_URL", "http://localhost:92000")
		es := ESserver{es_url:es_url, logger:l}
		go es.start()
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

	als.RegisterAccessLogServiceServer(s, &server{loggers:loggers})
	if err := s.Serve(sock); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
