PYTHON ?= python3
IVERILOG ?= iverilog
VVP ?= vvp
LIBRELANE ?= librelane
PDK ?= ihp-sg13g2
PDK_ROOT ?=
SKIP_DRC ?= 0

RTL := rtl/tenon_tier0_padframe.sv rtl/tenon_tier0_reference.sv rtl/tenon_tier0_variants.sv
PDK_IO_MODEL = $(PDK_ROOT)/$(PDK)/libs.ref/sg13g2_io/verilog/sg13g2_io.v
BUILD_DIR := build

.DEFAULT_GOAL := help

ifneq ($(filter 1 true TRUE yes YES,$(SKIP_DRC)),)
DRC_OVERRIDES := --override-config RUN_MAGIC_DRC=false --override-config RUN_KLAYOUT_DRC=false
endif

.PHONY: help generate check-generated check-pdk lint lint-qfn32 lint-qfn64 lint-qfn88 lint-qfn128 test harden-all harden-qfn32 harden-qfn64 harden-qfn88 harden-qfn128

help:
	@echo "Usage: make <target> PDK_ROOT=/path/to/IHP-Open-PDK"
	@echo ""
	@echo "  generate          Regenerate pin manifests and LibreLane configs"
	@echo "  check-generated   Verify generated files are current"
	@echo "  lint              Compile all fixed Tier0 package tops"
	@echo "  test              Run SystemVerilog pad behavior tests"
	@echo "  harden-qfn32      Run LibreLane for one package profile"
	@echo "  harden-qfn64"
	@echo "  harden-qfn88"
	@echo "  harden-qfn128"
	@echo "  harden-all        Run all hardening targets sequentially"
	@echo "  SKIP_DRC=1        Skip Magic and KLayout DRC only (off by default)"

generate:
	$(PYTHON) tools/generate_tier0.py

check-generated:
	$(PYTHON) tools/generate_tier0.py --check

check-pdk:
	@test -n "$(PDK_ROOT)" || (echo "PDK_ROOT must point to an existing IHP Open PDK root" && exit 2)
	@test -d "$(PDK_ROOT)/$(PDK)" || (echo "Missing $(PDK_ROOT)/$(PDK)" && exit 2)

lint: check-pdk lint-qfn32 lint-qfn64 lint-qfn88 lint-qfn128

lint-qfn32:
	$(IVERILOG) -g2012 -tnull -s tenon_tier0_qfn32 $(PDK_IO_MODEL) $(RTL)

lint-qfn64:
	$(IVERILOG) -g2012 -tnull -s tenon_tier0_qfn64 $(PDK_IO_MODEL) $(RTL)

lint-qfn88:
	$(IVERILOG) -g2012 -tnull -s tenon_tier0_qfn88 $(PDK_IO_MODEL) $(RTL)

lint-qfn128:
	$(IVERILOG) -g2012 -tnull -s tenon_tier0_qfn128 $(PDK_IO_MODEL) $(RTL)

test: check-pdk
	@mkdir -p $(BUILD_DIR)/tests
	$(IVERILOG) -g2012 -s tenon_tier0_tb -o $(BUILD_DIR)/tests/tenon_tier0_tb.vvp $(PDK_IO_MODEL) $(RTL) tb/tenon_tier0_tb.sv
	$(VVP) $(BUILD_DIR)/tests/tenon_tier0_tb.vvp

harden-qfn32: generate check-pdk
	$(LIBRELANE) --manual-pdk --pdk $(PDK) --pdk-root $(PDK_ROOT) $(DRC_OVERRIDES) --run-tag tenon-qfn32 --overwrite --save-views-to $(BUILD_DIR)/qfn32/final flow/qfn32.yaml

harden-qfn64: generate check-pdk
	$(LIBRELANE) --manual-pdk --pdk $(PDK) --pdk-root $(PDK_ROOT) $(DRC_OVERRIDES) --run-tag tenon-qfn64 --overwrite --save-views-to $(BUILD_DIR)/qfn64/final flow/qfn64.yaml

harden-qfn88: generate check-pdk
	$(LIBRELANE) --manual-pdk --pdk $(PDK) --pdk-root $(PDK_ROOT) $(DRC_OVERRIDES) --run-tag tenon-qfn88 --overwrite --save-views-to $(BUILD_DIR)/qfn88/final flow/qfn88.yaml

harden-qfn128: generate check-pdk
	$(LIBRELANE) --manual-pdk --pdk $(PDK) --pdk-root $(PDK_ROOT) $(DRC_OVERRIDES) --run-tag tenon-qfn128 --overwrite --save-views-to $(BUILD_DIR)/qfn128/final flow/qfn128.yaml

harden-all:
	$(MAKE) harden-qfn32 PDK_ROOT="$(PDK_ROOT)" SKIP_DRC="$(SKIP_DRC)"
	$(MAKE) harden-qfn64 PDK_ROOT="$(PDK_ROOT)" SKIP_DRC="$(SKIP_DRC)"
	$(MAKE) harden-qfn88 PDK_ROOT="$(PDK_ROOT)" SKIP_DRC="$(SKIP_DRC)"
	$(MAKE) harden-qfn128 PDK_ROOT="$(PDK_ROOT)" SKIP_DRC="$(SKIP_DRC)"
