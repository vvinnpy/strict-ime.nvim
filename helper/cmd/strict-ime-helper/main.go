package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"sync"
	"time"

	"github.com/godbus/dbus/v5"
)

const (
	busName    = "org.fcitx.Fcitx5"
	objectPath = dbus.ObjectPath("/controller")
	iface      = "org.fcitx.Fcitx.Controller1"
)

type request struct {
	Cmd   string          `json:"cmd"`
	Value json.RawMessage `json:"value"`
}

type response struct {
	OK    bool   `json:"ok"`
	Error string `json:"error,omitempty"`
}

type inputState struct {
	Imname string `json:"imname"`
	Active bool   `json:"active"`
}

type manager struct {
	mu       sync.Mutex
	conn     *dbus.Conn
	object   dbus.BusObject
	strict   bool
	interval time.Duration
}

func (m *manager) connectLocked() error {
	if m.object != nil {
		return nil
	}

	conn, err := dbus.SessionBus()
	if err != nil {
		return err
	}
	m.conn = conn
	m.object = conn.Object(busName, objectPath)
	return nil
}

func (m *manager) resetLocked() {
	if m.conn != nil {
		_ = m.conn.Close()
	}
	m.conn = nil
	m.object = nil
}

func (m *manager) ensureEnglishLocked() error {
	if err := m.connectLocked(); err != nil {
		return err
	}

	call := m.object.Call(iface+".State", 0)
	if call.Err != nil {
		m.resetLocked()
		return call.Err
	}

	var state int32
	if err := call.Store(&state); err != nil {
		return err
	}
	if state == 1 {
		return nil
	}

	if call := m.object.Call(iface+".Deactivate", 0); call.Err != nil {
		m.resetLocked()
		return call.Err
	}
	return nil
}

func (m *manager) setInput(state inputState) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if err := m.connectLocked(); err != nil {
		return err
	}
	if call := m.object.Call(iface+".SetCurrentIM", 0, state.Imname); call.Err != nil {
		m.resetLocked()
		return call.Err
	}

	method := iface + ".Activate"
	if !state.Active {
		method = iface + ".Deactivate"
	}
	if call := m.object.Call(method, 0); call.Err != nil {
		m.resetLocked()
		return call.Err
	}
	return nil
}

func (m *manager) setStrict(strict bool) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.strict = strict
	if strict {
		return m.ensureEnglishLocked()
	}
	return nil
}

func (m *manager) watch() {
	ticker := time.NewTicker(m.interval)
	defer ticker.Stop()

	for range ticker.C {
		m.mu.Lock()
		if m.strict {
			if err := m.ensureEnglishLocked(); err != nil {
				fmt.Fprintln(os.Stderr, "strict-ime-helper:", err)
			}
		}
		m.mu.Unlock()
	}
}

func writeResponse(ok bool, err error) {
	payload := response{OK: ok}
	if err != nil {
		payload.Error = err.Error()
	}
	encoded, _ := json.Marshal(payload)
	fmt.Println(string(encoded))
}

func main() {
	intervalMs := flag.Int("interval", 200, "D-Bus state polling interval in milliseconds")
	flag.Parse()

	if *intervalMs < 50 {
		*intervalMs = 50
	}
	m := &manager{interval: time.Duration(*intervalMs) * time.Millisecond}
	if err := m.connectLocked(); err != nil {
		fmt.Fprintln(os.Stderr, "strict-ime-helper: cannot connect to session D-Bus:", err)
		os.Exit(1)
	}
	go m.watch()

	scanner := bufio.NewScanner(os.Stdin)
	for scanner.Scan() {
		var req request
		if err := json.Unmarshal(scanner.Bytes(), &req); err != nil {
			writeResponse(false, err)
			continue
		}

		switch req.Cmd {
		case "set_strict":
			var strict bool
			if err := json.Unmarshal(req.Value, &strict); err != nil {
				writeResponse(false, err)
				continue
			}
			writeResponse(true, m.setStrict(strict))
		case "set_im":
			var imname string
			if err := json.Unmarshal(req.Value, &imname); err != nil {
				writeResponse(false, err)
				continue
			}
			writeResponse(true, m.setInput(inputState{Imname: imname, Active: true}))
		case "set_state":
			var state inputState
			if err := json.Unmarshal(req.Value, &state); err != nil {
				writeResponse(false, err)
				continue
			}
			writeResponse(true, m.setInput(state))
		case "quit":
			return
		default:
			writeResponse(false, fmt.Errorf("unknown command %q", req.Cmd))
		}
	}
	if err := scanner.Err(); err != nil {
		fmt.Fprintln(os.Stderr, "strict-ime-helper:", err)
	}
}
