package main

import (
	"fmt"
	"testing"
)

func TestGetDeterministicBucket_Range(t *testing.T) {
	for i := 0; i < 200; i++ {
		b := getDeterministicBucket(fmt.Sprintf("user%d-flag-test", i))
		if b < 0 || b >= 100 {
			t.Errorf("bucket fora do range [0,99]: %d (input user%d)", b, i)
		}
	}
}

func TestGetDeterministicBucket_Deterministic(t *testing.T) {
	b1 := getDeterministicBucket("user42-flag-beta")
	b2 := getDeterministicBucket("user42-flag-beta")
	if b1 != b2 {
		t.Error("getDeterministicBucket deve ser determinístico para a mesma entrada")
	}
}

func TestRunEvaluationLogic_NilFlag(t *testing.T) {
	app := &App{}
	info := &CombinedFlagInfo{}
	if app.runEvaluationLogic(info, "user1") {
		t.Error("flag nil deve retornar false")
	}
}

func TestRunEvaluationLogic_DisabledFlag(t *testing.T) {
	app := &App{}
	info := &CombinedFlagInfo{
		Flag: &Flag{Name: "test-flag", IsEnabled: false},
	}
	if app.runEvaluationLogic(info, "user1") {
		t.Error("flag desabilitada deve retornar false")
	}
}

func TestRunEvaluationLogic_EnabledNoRule(t *testing.T) {
	app := &App{}
	info := &CombinedFlagInfo{
		Flag: &Flag{Name: "test-flag", IsEnabled: true},
	}
	if !app.runEvaluationLogic(info, "user1") {
		t.Error("flag habilitada sem regra deve retornar true para todos os usuários")
	}
}

func TestRunEvaluationLogic_PercentageRule100(t *testing.T) {
	app := &App{}
	info := &CombinedFlagInfo{
		Flag: &Flag{Name: "flag", IsEnabled: true},
		Rule: &TargetingRule{
			IsEnabled: true,
			Rules:     Rule{Type: "PERCENTAGE", Value: float64(100)},
		},
	}
	if !app.runEvaluationLogic(info, "any-user") {
		t.Error("regra 100%% deve retornar true para qualquer usuário")
	}
}

func TestRunEvaluationLogic_PercentageRule0(t *testing.T) {
	app := &App{}
	info := &CombinedFlagInfo{
		Flag: &Flag{Name: "flag", IsEnabled: true},
		Rule: &TargetingRule{
			IsEnabled: true,
			Rules:     Rule{Type: "PERCENTAGE", Value: float64(0)},
		},
	}
	if app.runEvaluationLogic(info, "any-user") {
		t.Error("regra 0%% deve retornar false para qualquer usuário")
	}
}
