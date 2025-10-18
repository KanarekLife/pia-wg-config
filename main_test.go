package main

import (
	"os"
	"testing"
)

func TestWriteServerNameFile(t *testing.T) {
	outfile := "test-wg.conf"
	defer os.Remove(outfile)
	defer os.Remove(outfile + ".servername")

	serverName := "us_california-lax.pia.privateinternetaccess.com"

	if err := writeServerNameFile(outfile, serverName); err != nil {
		t.Fatalf("writeServerNameFile returned error: %v", err)
	}

	// Read back the file
	data, err := os.ReadFile(outfile + ".servername")
	if err != nil {
		t.Fatalf("failed to read servername file: %v", err)
	}

	if string(data) != serverName {
		t.Fatalf("unexpected servername content: got %q want %q", string(data), serverName)
	}

	// Check permissions are 0600-ish: owner readable/writable
	fi, err := os.Stat(outfile + ".servername")
	if err != nil {
		t.Fatalf("stat failed: %v", err)
	}
	mode := fi.Mode().Perm()
	if mode&0o700 == 0 { // ensure owner has at least one of rwx
		t.Fatalf("unexpected permissions for servername file: %v", mode)
	}
}
