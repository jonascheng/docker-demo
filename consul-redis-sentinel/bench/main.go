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
	"strconv"
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
	requests  = kingpin.Flag("requests", "Set number of requests.").Default("10000").Uint()
	memLimits = kingpin.Flag("memlimits", "Set redis memory limits in M.").Default("200M").String()
)

const (
	ShellToUse  = "bash"
	DockerImage = "bench"
	RedisPort   = "6379"
	RedisPwd    = "supersecret"
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

func RunBench(ctx context.Context) {
	select {
	case <-ctx.Done():
		log.Println("got the stop channel")
		return
	default:
		// randomize keyspace
		rand.Seed(time.Now().UnixNano())
		max, _ := strconv.Atoi(strings.TrimSuffix(*memLimits, "M"))
		keyspace := 1000 * (1 + rand.Intn(max-1))
		_, _, err := Shellout(fmt.Sprintf("BENCH_REQUESTS=%d BENCH_KEYSPACE=%d ./run_bench.sh", *requests, keyspace))
		if err != nil {
			log.Printf("error: %v\n", err)
		}
	}
}

func ValidateBench() {
	var counters []int
	for _, server := range ServerList {
		command := fmt.Sprintf("docker run -t %s sh -c \"redis-cli --no-auth-warning -u redis://%s@%s:%s/0 DBSIZE\"",
			DockerImage, RedisPwd, server, RedisPort)
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
		intVar, err := strconv.Atoi(strings.Trim(out, "(integr) \r\n"))
		counters = append(counters, intVar)
		if err != nil {
			log.Fatalf("error: %v\n", err)
		}
	}
	if counters[0] == counters[1] && counters[1] == counters[2] {
		if counters[0] > 0 {
			counterPerBench = append(counterPerBench, counters[0])
			// calculate average
			total := 0
			for _, counter := range counterPerBench {
				total += counter
			}
			average := total / len(counterPerBench)
			log.Printf("--- validate pass, and %d tps in average ---\n", average/60)
		}
	} else {
		log.Fatalf("--- validate counters %v failed ---\n", counters)
	}
}

func RandomSelectServer() string {
	// random select server
	s := rand.NewSource(time.Now().Unix())
	r := rand.New(s) // initialize local pseudorandom generator
	return ServerList[r.Intn(len(ServerList))]
}

func RandomSelectCommand() RemoteCommandPair {
	var CommandList = [...]RemoteCommandPair{
		{"docker restart redis", ""},
		{"docker restart redis-sentinel", ""},
		{"docker restart consul-server", ""},
		{"docker stop redis", "docker start redis"},
		{"docker stop redis-sentinel", "docker start redis-sentinel"},
		{"docker stop consul-server", "docker start consul-server"},
		{"cd /vagrant; ./docker-restart.sh", ""},
		{"cd /vagrant; ./docker-stop.sh", fmt.Sprintf("cd /vagrant; REDIS_MEM_LIMITS=%s ./docker-up.sh -d", *memLimits)},
		{"sudo systemctl restart docker", ""},
		{"sudo systemctl stop docker", "sudo systemctl start docker"},
		{"docker exec -t redis sh -c \"stress --cpu 2 --io 2 --vm 2 --vm-bytes 1G --timeout 15s\"", ""},
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
				fmt.Sprintf("cd /vagrant; REDIS_MEM_LIMITS=%s ./docker-up.sh -d", *memLimits))
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
			// pause 10 * requests/10000 seconds for cluster in sync
			sleep := time.Duration(10**requests/10000) * time.Second
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
			// pause 10 * requests/10000 seconds for cluster in sync
			sleep := time.Duration(10**requests/10000) * time.Second
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
		*requests,
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
