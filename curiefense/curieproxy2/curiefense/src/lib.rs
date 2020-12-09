use log::{info,trace};
use proxy_wasm as wasm;

#[no_mangle]
pub fn _start() {
    proxy_wasm::set_log_level(wasm::types::LogLevel::Trace);
    proxy_wasm::set_http_context(
        |context_id, _root_context_id| -> Box<dyn wasm::traits::HttpContext> {
            Box::new(Curiefense::new(context_id))
        },
    )
}


struct Curiefense {
    context_id: u32,
}


impl Curiefense {
    pub fn new(context_id: u32) -> Curiefense {
        Curiefense {
            context_id: context_id
        }
    }
}


impl wasm::traits::Context for Curiefense {}

impl wasm::traits::HttpContext for Curiefense {
    fn on_http_request_headers(&mut self, num_headers: usize) -> wasm::types::Action {
        trace!("Got {} HTTP headers in #{}.", num_headers, self.context_id);
        wasm::types::Action::Continue
    }
}
