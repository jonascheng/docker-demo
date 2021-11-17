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

	"golang.org/x/crypto/ssh"
	// A Go (golang) command line and flag parser
	"gopkg.in/alecthomas/kingpin.v2"
)

var (
	duration = kingpin.Flag("duration", "Set duration in seconds.").Default("300").Short('d').Uint()
)

const (
	ShellToUse  = "bash"
	DockerImage = "pgbench"
	DbPort      = "5432"
	DbUser      = "postgres"
	DbPwd       = "supersecret"
	DbBench     = "pgbench"
)

type RemoteCommandPair struct {
	force   string
	recover string
}

var ServerList = [...]string{"10.1.0.10", "10.1.0.20", "10.1.0.30"}

var CommandList = [...]RemoteCommandPair{
	{"docker restart patroni", ""},
	{"docker restart consul-server", ""},
	{"docker stop patroni", "docker start patroni"},
	{"docker stop consul-server", "docker start consul-server"},
	{"cd /vagrant; ./docker-restart.sh", ""},
	{"cd /vagrant; ./docker-stop.sh", "cd /vagrant; ./docker-up.sh -d"},
	{"sudo systemctl restart docker", ""},
	{"sudo systemctl stop docker", "sudo systemctl start docker"},
}

func Shellout(command string) (string, string, error) {
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	cmd := exec.Command(ShellToUse, "-c", command)
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
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
	if err := session.Run(command); err != nil {
		log.Fatalf("Failed to run %s on %s: %v\n", command, server, err)
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

func RunBench(ctx context.Context) {
	select {
	case <-ctx.Done():
		log.Println("got the stop channel")
		return
	default:
		_, _, err := Shellout("./run_bench.sh")
		if err != nil {
			log.Printf("error: %v\n", err)
		}
	}
}

func ValidateBench() {
	var counters []int
	for _, server := range ServerList {
		command := fmt.Sprintf("docker run -t %s sh -c \"psql postgresql://%s:%s@%s:%s/%s -t -c 'select count(*) from pgbench_history;'\"",
			DockerImage, DbUser, DbPwd, server, DbPort, DbBench)
		out, _, err := Shellout(command)
		if err != nil {
			log.Fatalf("error: %v\n", err)
		}
		intVar, err := strconv.Atoi(strings.Trim(out, " \r\n"))
		counters = append(counters, intVar)
		if err != nil {
			log.Fatalf("error: %v\n", err)
		}
	}
	if counters[0] == counters[1] && counters[1] == counters[2] {
		log.Println("--- validate pass ---")
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
		log.Fatalf("error: %v\n", err)
	}

	// pause 10 seconds
	time.Sleep(10 * time.Second)

	if command.recover != "" {
		log.Printf("Server %s selected to execute recover command '%s'\n", server, command.recover)
		_, _, err := RemoteShellout(server, command.recover)
		if err != nil {
			log.Fatalf("error: %v\n", err)
		}

		// pause another 10 seconds to recovery
		time.Sleep(10 * time.Second)
	}
}

func StartCluster() {
	log.Println("start cluster...")
	var wg sync.WaitGroup
	wg.Add(3)
	for _, server := range ServerList {
		go func(server string) {
			defer wg.Done()
			_, _, err := RemoteShellout(server, "cd /vagrant; ./docker-up.sh -d")
			if err != nil {
				log.Fatalf("error: %v\n", err)
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

	ctxChild, cancel := context.WithCancel(ctx)
	var wg sync.WaitGroup

	for {
		select {
		case <-ctx.Done():
			log.Println("got the stop channel")
			// cancel child goroutine and wait them
			cancel()
			wg.Wait()
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
				rand.Seed(time.Now().UnixNano())
				n := rand.Intn(30) // n will be between 0 and 30
				log.Printf("Sleeping %d seconds...\n", n)
				time.Sleep(time.Duration(n) * time.Second)
				RandomVictim()
			}()
			wg.Wait()
			// pause 5 seconds for cluster in sync
			log.Println("pause 10 seconds for cluster in sync")
			time.Sleep(10 * time.Second)
		}
	}
}

func main() {
	kingpin.Version("1.0.0")
	kingpin.Parse()

	// log to custom file
	logFilename := fmt.Sprintf("/tmp/pgbench-%d.log", time.Now().Unix())
	// open log file
	logFile, err := os.OpenFile(logFilename, os.O_APPEND|os.O_RDWR|os.O_CREATE, 0644)
	if err != nil {
		log.Fatalf("error: %v\n", err)
	}
	defer logFile.Close()

	// Set log out put
	log.Printf("log out put to %s\n", logFilename)
	log.SetOutput(logFile)

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
