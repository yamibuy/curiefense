all: curiefense.wasm

curiefense.wasm: src/lib.rs
	cargo build --target wasm32-unknown-unknown --release
	cp target/wasm32-unknown-unknown/release/curiefense.wasm $@


.PHONY: all
