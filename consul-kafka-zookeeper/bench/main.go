package main

import (
	"bytes"
	"context"
	"fmt"
	"io/ioutil"
	"log"
	"math/rand"
	"os"
	"os/exec"
	"strings"
	"sync"
	"time"

	"github.com/avast/retry-go/v3"
	"golang.org/x/crypto/ssh"

	// A Go (golang) command line and flag parser
	"gopkg.in/alecthomas/kingpin.v2"
)

var (
	duration  = kingpin.Flag("duration", "Set duration in seconds.").Default("300").Short('d').Uint()
	logToFile = kingpin.Flag("logfile", "Set duration in seconds.").Bool()
	records   = kingpin.Flag("records", "Set number of records.").Default("100000").Uint()
	memLimits = kingpin.Flag("memlimits", "Set redis memory limits in M.").Default("200M").String()
)

const (
	ShellToUse  = "bash"
	DockerImage = "docker.io/bitnami/kafka:2.5.0-debian-10-r112"
	KafkaPort   = "9092"
)

type RemoteCommandPair struct {
	force   string
	recover string
}

var ServerList = [...]string{"10.1.0.10", "10.1.0.20", "10.1.0.30"}

var counterPerBench []int

func Shellout(command string) (string, string, error) {
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	cmd := exec.Command(ShellToUse, "-c", command)
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	log.Printf("--- executing command of %s ---\n", command)
	err := cmd.Run()

	out := stdout.String()
	errout := stderr.String()
	log.Printf("--- stdout of %s ---\n", command)
	log.Println(out)
	log.Printf("--- stderr of %s ---\n", command)
	log.Println(errout)

	return out, errout, err
}

func RemoteShellout(server string, command string) (string, string, error) {
	var stdout bytes.Buffer
	var stderr bytes.Buffer

	// read private key file
	key, err := ioutil.ReadFile("/home/vagrant/.ssh/id_rsa")
	if err != nil {
		log.Fatalf("Reading private key file failed: %v\n", err)
	}

	// create signer
	signer, err := ssh.ParsePrivateKey(key)
	if err != nil {
		log.Fatalf("Parse private key file failed: %v\n", err)
	}

	// create ssh client
	client, err := ssh.Dial("tcp", server+":22", &ssh.ClientConfig{
		User: "vagrant",
		Auth: []ssh.AuthMethod{
			ssh.PublicKeys(signer),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	})
	if err != nil {
		log.Fatalf("SSH dial error toward %s: %v\n", server, err)
	}

	// create session
	session, err := client.NewSession()
	if err != nil {
		log.Fatalf("new session error toward %s: %v\n", server, err)
	}

	defer session.Close()

	session.Stdout = &stdout
	session.Stderr = &stderr
	log.Printf("--- executing command of %s on %s---\n", command, server)
	if err := session.Run(command); err != nil {
		log.Printf("Failed to run %s on %s: %v\n", command, server, err)
	}

	out := stdout.String()
	errout := stderr.String()
	log.Printf("--- stdout of %s from %s ---\n", command, server)
	log.Println(out)
	log.Printf("--- stderr of %s from %s ---\n", command, server)
	log.Println(errout)

	return out, errout, err
}

func InitBench() {
	log.Println("initial pgbench...")
	_, _, err := Shellout("./create_bench.sh")
	if err != nil {
		log.Fatalf("error: %v\n", err)
	}
}

func RunProducer() {
	_, _, err := Shellout(fmt.Sprintf("BENCH_RECORDS=%d ./run_producer.sh", *records))
	if err != nil {
		log.Printf("error: %v\n", err)
	}
}

func RunConsumer() {
	_, _, err := Shellout(fmt.Sprintf("BENCH_RECORDS=%d ./run_consumer.sh", *records))
	if err != nil {
		log.Printf("error: %v\n", err)
	}
}

func RunBench(ctx context.Context) {
	select {
	case <-ctx.Done():
		log.Println("got the stop channel")
		return
	default:
		// producer
		RunProducer()
		// consumer
		RunConsumer()
	}
}

func ValidateReplicas() {
	for _, server := range ServerList {
		command := fmt.Sprintf("docker run -v /vagrant/:/opt/bitnami/kafka/conf -t %s sh -c \"kafka-topics.sh --describe --bootstrap-server %s:%s --topic my-topic --command-config /opt/bitnami/kafka/conf/kafka-client/client.properties\"",
			DockerImage, server, KafkaPort)
		var out string
		err := retry.Do(
			func() error {
				var errout string
				var err error
				out, errout, err = Shellout(command)
				if err != nil && len(errout) > 0 {
					err = fmt.Errorf(errout)
				}
				return err
			},
			retry.DelayType(func(n uint, err error, config *retry.Config) time.Duration {
				//default is backoffdelay
				return retry.BackOffDelay(n, err, config)
			}),
			retry.OnRetry(func(n uint, err error) {
				log.Printf("OnRetry '%s' #%d: %s\n", command, n, err)
			}),
		)

		if err != nil {
			log.Fatalf("error: %v\n", err)
		}

		lines := strings.Split(out, "\n")
		for _, str := range lines {
			if strings.Contains(str, "Topic: my-topic") && !strings.Contains(str, "ReplicationFactor") {
				columns := strings.Fields(str)
				log.Print(columns)
				replicas := columns[7]
				isr := columns[9]
				if len(strings.Split(replicas, ",")) != len(strings.Split(isr, ",")) {
					log.Fatalf("--- validate replicas/isr (%s, %s) failed ---\n", replicas, isr)
				}
			}
		}
	}
	log.Printf("--- validate pass ---\n")
}

func ValidateMsgCount() {
	for _, server := range ServerList {
		command := fmt.Sprintf("docker run -v /vagrant/:/opt/bitnami/kafka/conf -t %s sh -c \"kafka-run-class.sh kafka.admin.ConsumerGroupCommand --describe --all-groups --bootstrap-server %s:%s --command-config /opt/bitnami/kafka/conf/kafka-client/client.properties\"",
			DockerImage, server, KafkaPort)
		var out string
		err := retry.Do(
			func() error {
				var errout string
				var err error
				out, errout, err = Shellout(command)
				if err != nil && len(errout) > 0 {
					err = fmt.Errorf(errout)
				}
				return err
			},
			retry.DelayType(func(n uint, err error, config *retry.Config) time.Duration {
				//default is backoffdelay
				return retry.BackOffDelay(n, err, config)
			}),
			retry.OnRetry(func(n uint, err error) {
				log.Printf("OnRetry '%s' #%d: %s\n", command, n, err)
			}),
		)

		if err != nil {
			log.Fatalf("error: %v\n", err)
		}

		lines := strings.Split(out, "\n")
		for _, str := range lines {
			if strings.Contains(str, "perf-consumer-52325 my-topic") {
				columns := strings.Fields(str)
				log.Print(columns)
				currentOffset := columns[3]
				logEndOffset := columns[4]
				if currentOffset != logEndOffset {
					log.Fatalf("--- validate CURRENT-OFFSET/LOG-END-OFFSET (%s, %s) failed ---\n", currentOffset, logEndOffset)
				}
			}
		}
	}
	log.Printf("--- validate pass ---\n")
}

func ValidateBench() {
	ValidateReplicas()
	ValidateMsgCount()
}

func RandomSelectServer() string {
	// random select server
	s := rand.NewSource(time.Now().Unix())
	r := rand.New(s) // initialize local pseudorandom generator
	return ServerList[r.Intn(len(ServerList))]
}

func RandomSelectCommand() RemoteCommandPair {
	var CommandList = [...]RemoteCommandPair{
		{"docker restart kafka", ""},
		{"docker restart zookeeper", ""},
		{"docker restart consul-server", ""},
		{"docker stop kafka", "docker start kafka"},
		{"docker stop zookeeper", "docker start zookeeper"},
		{"docker stop consul-server", "docker start consul-server"},
		{"cd /vagrant; ./docker-restart.sh", ""},
		{"cd /vagrant; ./docker-stop.sh", fmt.Sprintf("cd /vagrant; KAFKA_MEM_LIMITS=%s ./docker-up.sh -d", *memLimits)},
		{"sudo systemctl restart docker", ""},
		{"sudo systemctl stop docker", "sudo systemctl start docker"},
		{"docker exec -t kafka sh -c \"stress --cpu 2 --io 2 --vm 2 --vm-bytes 1G --timeout 15s\"", ""},
	}

	// random select server
	s := rand.NewSource(time.Now().Unix())
	r := rand.New(s) // initialize local pseudorandom generator
	return CommandList[r.Intn(len(CommandList))]
}

func RandomVictim() {
	server := RandomSelectServer()
	command := RandomSelectCommand()
	log.Printf("Server %s selected to execute force command '%s'\n", server, command.force)
	_, _, err := RemoteShellout(server, command.force)
	if err != nil {
		log.Printf("error: %v\n", err)
	}

	// pause 15 seconds
	time.Sleep(15 * time.Second)

	if command.recover != "" {
		log.Printf("Server %s selected to execute recover command '%s'\n", server, command.recover)
		_, _, err := RemoteShellout(server, command.recover)
		if err != nil {
			log.Fatalf("error: %v\n", err)
		}

		// pause another 15 seconds to recovery
		time.Sleep(15 * time.Second)
	}
}

func StartCluster() {
	log.Println("start cluster...")
	var wg sync.WaitGroup
	wg.Add(3)
	for _, server := range ServerList {
		go func(server string) {
			defer wg.Done()
			_, _, err := RemoteShellout(
				server,
				fmt.Sprintf("cd /vagrant; ./docker-cleanup.sh"))
			// pause 15 seconds
			time.Sleep(15 * time.Second)
			if err != nil {
				log.Printf("error: %v\n", err)
			}
			_, _, err = RemoteShellout(
				server,
				fmt.Sprintf("cd /vagrant; KAFKA_MEM_LIMITS=%s ./docker-up.sh -d", *memLimits))
			if err != nil {
				log.Printf("error: %v\n", err)
			}
		}(server)
	}
	log.Println("wait cluster start...")
	wg.Wait()
	// pause 30 seconds for entire cluster to start up
	log.Println("pause 30 seconds for entire cluster to start up")
	time.Sleep(30 * time.Second)
}

func StartBench(ctx context.Context) {
	log.Println("start bench...")

	rand.Seed(time.Now().UnixNano())

	ctxChild, cancel := context.WithCancel(ctx)
	var wg sync.WaitGroup

	for {
		select {
		case <-ctx.Done():
			log.Println("got the stop channel")
			// cancel child goroutine and wait them
			cancel()
			wg.Wait()
			// pause 30 * records/100000 seconds for cluster in sync
			sleep := time.Duration(30**records/100000) * time.Second
			log.Printf("pause %v seconds for cluster in sync\n", sleep)
			time.Sleep(sleep)
			// validate after bench
			ValidateBench()
			return
		default:
			// validate before bench
			ValidateBench()

			// run bench
			wg.Add(2)
			go func() {
				defer wg.Done()
				RunBench(ctxChild)
			}()
			// run victim
			go func() {
				defer wg.Done()
				// sleep random time within 30 seconds
				n := rand.Intn(30) // n will be between 0 and 30
				log.Printf("Sleeping %d seconds...\n", n)
				time.Sleep(time.Duration(n) * time.Second)
				RandomVictim()
			}()
			wg.Wait()
			// run consumer to catch up message counts
			RunConsumer()
			// pause 30 * records/100000 seconds for cluster in sync
			sleep := time.Duration(30**records/100000) * time.Second
			log.Printf("pause %v seconds for cluster in sync\n", sleep)
			time.Sleep(sleep)
		}
	}
}

func main() {
	kingpin.Version("1.0.0")
	kingpin.Parse()

	// log to custom file
	logFilename := fmt.Sprintf(
		"/tmp/bench-duration%d-req%d-mem%s-%d.log",
		*duration,
		*records,
		*memLimits,
		time.Now().Unix())
	// open log file
	logFile, err := os.OpenFile(logFilename, os.O_APPEND|os.O_RDWR|os.O_CREATE, 0644)
	if err != nil {
		log.Fatalf("error: %v\n", err)
	}
	defer logFile.Close()

	// Set log out put
	if *logToFile {
		log.Printf("log out put to %s\n", logFilename)
		log.SetOutput(logFile)
	}

	// optional: log date-time, filename, and line number
	log.SetFlags(log.Lshortfile | log.LstdFlags)

	// preparation for bench playground
	StartCluster()
	InitBench()

	// create context with timeout in seconds
	timeout := time.Duration(*duration) * time.Second
	ctx, _ := context.WithTimeout(context.Background(), timeout)
	var wg sync.WaitGroup
	wg.Add(1)
	go func() {
		defer wg.Done()
		StartBench(ctx)
	}()

	wg.Wait()
}
