package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHashAPIKey_Deterministic(t *testing.T) {
	h1 := hashAPIKey("mykey")
	h2 := hashAPIKey("mykey")
	if h1 != h2 {
		t.Error("hashAPIKey deve ser determinístico")
	}
}

func TestHashAPIKey_Distinct(t *testing.T) {
	if hashAPIKey("key1") == hashAPIKey("key2") {
		t.Error("chaves diferentes devem produzir hashes distintos")
	}
}

func TestHashAPIKey_Length(t *testing.T) {
	h := hashAPIKey("anykey")
	if len(h) != 64 {
		t.Errorf("hash SHA-256 deve ter 64 caracteres hexadecimais, got %d", len(h))
	}
}

func TestGenerateAPIKey_Prefix(t *testing.T) {
	key, err := generateAPIKey()
	if err != nil {
		t.Fatalf("generateAPIKey retornou erro: %v", err)
	}
	if len(key) < 10 {
		t.Errorf("chave gerada muito curta: %s", key)
	}
	if key[:7] != "tm_key_" {
		t.Errorf("chave deve começar com 'tm_key_', got: %s", key[:7])
	}
}

func TestGenerateAPIKey_Unique(t *testing.T) {
	k1, _ := generateAPIKey()
	k2, _ := generateAPIKey()
	if k1 == k2 {
		t.Error("duas chaves geradas não devem ser iguais")
	}
}

func TestHealthHandler_ReturnsOK(t *testing.T) {
	app := &App{}
	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	w := httptest.NewRecorder()
	app.healthHandler(w, req)
	if w.Code != http.StatusOK {
		t.Errorf("esperado 200, recebido %d", w.Code)
	}
}

func TestValidateKeyHandler_MissingAuth(t *testing.T) {
	app := &App{}
	req := httptest.NewRequest(http.MethodGet, "/validate", nil)
	w := httptest.NewRecorder()
	app.validateKeyHandler(w, req)
	if w.Code != http.StatusUnauthorized {
		t.Errorf("esperado 401 sem header Authorization, recebido %d", w.Code)
	}
}
