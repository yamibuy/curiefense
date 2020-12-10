use log::{info,error,trace};
use proxy_wasm as wasm;
use std::time::Duration;

pub mod config;
use config::Config;

// pub mod avltree;
// use avltree::AVLTreeMap;
// pub mod sigset;
// use sigset::{SigSet,SigSetError};


#[no_mangle]
pub fn _start() {
    wasm::set_log_level(wasm::types::LogLevel::Info);
    wasm::set_http_context(
        |context_id, _root_context_id| -> Box<dyn wasm::traits::HttpContext> {
            info!("XXXXXXXXXXXXX STARTING CURIEFENSE WASM [id {}] XXXXXXXXXXXXXXXXXX", context_id);
            Box::new(Curiefense::new(context_id))
        },
    )
}


struct Curiefense {
    context_id: u32,
    config: Option<Config>,
}


impl Curiefense {
    pub fn new(context_id: u32) -> Curiefense {
        let conf = match Config::from_file("/config/json/urlmap.json") {
            Ok(x) => Some(x),
            Err(x) => {
                error!("Got ERROR: {:?}",x); 
                None
            },
        };
        Curiefense {
            context_id: context_id,
            config: conf,
        }
    }
}


impl wasm::traits::Context for Curiefense {}

impl wasm::traits::HttpContext for Curiefense {
    fn on_http_request_headers(&mut self, num_headers: usize) -> wasm::types::Action {
        info!("Got {} HTTP headers in #{}.", num_headers, self.context_id);
        info!("XXX conf {:?}", self.config);
        wasm::types::Action::Continue
    }
}



impl wasm::traits::RootContext for Curiefense {
    fn on_vm_start(&mut self, _: usize) -> bool {
        info!("XYXYXYXYXYXYXYXYX Hello, World!");
        self.set_tick_period(Duration::from_secs(5));
        true
    }

    fn on_tick(&mut self) {
        info!("---------------------> Tick!!");
    }
}
