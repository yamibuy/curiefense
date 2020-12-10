use log::{info,error,trace};

use serde::{Deserialize, Serialize};

use std::error::Error;
use std::fs::File;
use std::io::BufReader;
//use std::path::Path;

#[derive(Debug, Deserialize, Serialize)]
struct Map {
    #[serde(rename="match")]
    match_: String,
    name: String,
    acl_profile: String,
    waf_profile: String,
    acl_active: bool,
    wav_active: bool,
    limit_ids: Vec<String>,
}

#[derive(Debug, Deserialize, Serialize)]
struct URLMap {
    #[serde(rename="match")]
    match_: String,
    id: String,
    name: String,
    map: Vec<Map>,
}

#[derive(Debug, Deserialize, Serialize)]
struct URLMaps (Vec<URLMap>);

#[derive(Debug)]
pub struct Config {
    urlmaps: URLMaps,
}


impl Config {
    pub fn from_file(path: &str) -> Result<Config,Box<dyn Error>> {
        info!("reading file");
        let fcontent = std::fs::read_to_string(path)?;
        info!("file read");
        
//        let file = File::open(path)?;
//        let reader = BufReader::new(file);
//        let urlmaps:URLMaps = serde_json_wasm::from_reader(reader)?;

        let urlmaps:URLMaps = serde_json_wasm::from_str(&fcontent)?;
// wasm log curiefense curiefense : Got ERROR: Custom { kind: Other, error: "operation not supported on this platform" }

        let conf = Config {
            urlmaps: urlmaps,
        };
        Ok(conf)
    }
}


