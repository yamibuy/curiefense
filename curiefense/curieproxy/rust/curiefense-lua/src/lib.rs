mod lua;

use crate::lua::Luagrasshopper;

use curiefense::interface::Tags;
use curiefense::utils::RequestMeta;
use mlua::prelude::*;
use std::collections::HashMap;

use curiefense::content_filter_check_generic_request_map;
use curiefense::inspect_generic_request_map;
use curiefense::interface::{Decision, Grasshopper};
use curiefense::logs::Logs;
use curiefense::utils::{InspectionResult, RawRequest};

// ******************************************
// Content Filter ONLY CHECKS
// ******************************************

/// Lua interface to the inspection function
///
/// args are
/// * meta (contains keys "method", "path", and optionally "authority")
/// * headers
/// * (opt) body
/// * ip addr
/// * (opt) grasshopper
#[allow(clippy::type_complexity)]
#[allow(clippy::unnecessary_wraps)]
fn lua_inspect_content_filter(
    _lua: &Lua,
    args: (
        HashMap<String, String>, // meta
        HashMap<String, String>, // headers
        Option<LuaString>,       // maybe body
        String,                  // ip
        String,                  // content_filter_id
    ),
) -> LuaResult<(String, Option<String>)> {
    let (meta, headers, lua_body, str_ip, content_filter_id) = args;

    let res = match lua_body {
        None => inspect_content_filter(
            "/cf-config/current/config",
            meta,
            headers,
            None,
            str_ip,
            content_filter_id,
        ),
        Some(body) => inspect_content_filter(
            "/cf-config/current/config",
            meta,
            headers,
            Some(body.as_bytes()),
            str_ip,
            content_filter_id,
        ),
    };

    Ok(match res {
        Err(rr) => (
            Decision::Pass.to_json_raw(serde_json::Value::Null, Logs::default()),
            Some(rr),
        ),
        Ok(ir) => ir.into_json(),
    })
}

/// Rust-native inspection top level function
fn inspect_content_filter(
    configpath: &str,
    meta: HashMap<String, String>,
    headers: HashMap<String, String>,
    mbody: Option<&[u8]>,
    ip: String,
    content_filter_id: String,
) -> Result<InspectionResult, String> {
    let mut logs = Logs::default();
    logs.debug("Inspection init");
    let rmeta: RequestMeta = RequestMeta::from_map(meta)?;

    let raw = RawRequest {
        ipstr: ip,
        meta: rmeta,
        headers,
        mbody,
    };

    let (dec, reqinfo, tags) =
        content_filter_check_generic_request_map(configpath, &raw, &content_filter_id, &mut logs);

    Ok(InspectionResult {
        decision: dec,
        tags: Some(tags),
        logs,
        err: None,
        rinfo: Some(reqinfo),
    })
}

// ******************************************
// FULL CHECKS
// ******************************************

/// Lua interface to the inspection function
///
/// args are
/// * meta (contains keys "method", "path", and optionally "authority")
/// * headers
/// * (opt) body
/// * ip addr
/// * (opt) grasshopper
#[allow(clippy::type_complexity)]
#[allow(clippy::unnecessary_wraps)]
fn lua_inspect_request(
    _lua: &Lua,
    args: (
        HashMap<String, String>, // meta
        HashMap<String, String>, // headers
        Option<LuaString>,       // maybe body
        String,                  // ip
        Option<LuaTable>,        // grasshopper
    ),
) -> LuaResult<(String, Option<String>)> {
    let (meta, headers, lua_body, str_ip, lua_grasshopper) = args;
    let grasshopper = lua_grasshopper.map(Luagrasshopper);
    let res = match lua_body {
        None => inspect_request("/cf-config/current/config", meta, headers, None, str_ip, grasshopper),
        Some(body) => inspect_request(
            "/cf-config/current/config",
            meta,
            headers,
            Some(body.as_bytes()),
            str_ip,
            grasshopper,
        ),
    };

    Ok(match res {
        Err(rr) => (
            Decision::Pass.to_json_raw(serde_json::Value::Null, Logs::default()),
            Some(rr),
        ),
        Ok(ir) => ir.into_json(),
    })
}

struct DummyGrasshopper {
    humanity: bool,
}

impl curiefense::interface::Grasshopper for DummyGrasshopper {
    fn js_app(&self) -> Option<std::string::String> {
        None
    }
    fn js_bio(&self) -> Option<std::string::String> {
        None
    }
    fn parse_rbzid(&self, _: &str, _: &str) -> Option<bool> {
        Some(self.humanity)
    }
    fn gen_new_seed(&self, _: &str) -> Option<std::string::String> {
        None
    }
    fn verify_workproof(&self, _: &str, _: &str) -> Option<std::string::String> {
        Some("ok".into())
    }
}

/// Lua TEST interface to the inspection function
/// allows settings the Grasshopper result!
///
/// args are
/// * meta (contains keys "method", "path", and optionally "authority")
/// * headers
/// * (opt) body
/// * ip addr
/// * (opt) grasshopper
#[allow(clippy::type_complexity)]
#[allow(clippy::unnecessary_wraps)]
fn lua_test_inspect_request(
    _lua: &Lua,
    args: (
        HashMap<String, String>, // meta
        HashMap<String, String>, // headers
        Option<LuaString>,       // maybe body
        String,                  // ip
        bool,                    // humanity
    ),
) -> LuaResult<(String, Option<String>)> {
    let (meta, headers, lua_body, str_ip, humanity) = args;
    let grasshopper = Some(DummyGrasshopper { humanity });

    // TODO: solve the lifetime issue for the &[u8] to reduce duplication
    let res = match lua_body {
        None => inspect_request("/cf-config/current/config", meta, headers, None, str_ip, grasshopper),
        Some(body) => inspect_request(
            "/cf-config/current/config",
            meta,
            headers,
            Some(body.as_bytes()),
            str_ip,
            grasshopper,
        ),
    };

    Ok(match res {
        Err(rr) => (
            Decision::Pass.to_json_raw(serde_json::Value::Null, Logs::default()),
            Some(rr),
        ),
        Ok(ir) => ir.into_json(),
    })
}

/// Rust-native inspection top level function
fn inspect_request<GH: Grasshopper>(
    configpath: &str,
    meta: HashMap<String, String>,
    headers: HashMap<String, String>,
    mbody: Option<&[u8]>,
    ip: String,
    grasshopper: Option<GH>,
) -> Result<InspectionResult, String> {
    let mut logs = Logs::default();
    logs.debug("Inspection init");
    let rmeta: RequestMeta = RequestMeta::from_map(meta)?;

    let raw = RawRequest {
        ipstr: ip,
        meta: rmeta,
        headers,
        mbody,
    };
    let (dec, tags, masked_rinfo) =
        inspect_generic_request_map(configpath, grasshopper, raw, Tags::default(), &mut logs);

    Ok(InspectionResult {
        decision: dec,
        tags: Some(tags),
        logs,
        err: None,
        rinfo: Some(masked_rinfo),
    })
}

#[mlua::lua_module]
fn curiefense(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;

    // end-to-end inspection
    exports.set("inspect_request", lua.create_function(lua_inspect_request)?)?;
    // end-to-end inspection (test)
    exports.set("test_inspect_request", lua.create_function(lua_test_inspect_request)?)?;
    // content filter inspection
    exports.set(
        "inspect_content_filter",
        lua.create_function(lua_inspect_content_filter)?,
    )?;

    Ok(exports)
}

#[cfg(test)]
mod tests {
    use super::*;
    use anyhow::Ok;
    use curiefense::config::with_config;

    #[test]
    fn test_content_filter_by_walon() {
        let mut meta:HashMap<String, String> = HashMap::new();
        meta.insert("authority".to_owned(), "localhost:30081".to_owned());
        meta.insert("method".to_owned(), "get".to_owned());
        meta.insert("path".to_owned(), "/test?bb=111&ddd=rfi?..".to_owned());

        let mut headers:HashMap<String, String> = HashMap::new();
        headers.insert("content-type".to_owned(), "text/plain".to_owned());


        let str_ip :String = String::from("11.22.33.44");
        // let content_filter_id: String = String::from("waylontest");
        let content_filter_id: String = String::from("rl45report3");

        
        inspect_content_filter(
            "/cf-config/current/config",
            meta,
            headers,
            None,
            str_ip,
            content_filter_id,
        );
    }

    #[test]
    fn config_load() {
        let mut logs = Logs::default();
        let cfg = with_config("../../cf-config", &mut logs, |_, c| c.clone());
        if cfg.is_some() {
            match logs.logs.len() {
                1 => {
                    assert!(logs.logs[0].message.to_string().contains("CFGLOAD"));
                }
                11 => {
                    assert!(logs.logs[0]
                        .message
                        .to_string()
                        .contains("../../cf-config: No such file or directory"))
                }
                n => {
                    for r in logs.logs.iter() {
                        println!("{}", r.to_string());
                    }
                    panic!("Invalid amount of logs: {}", n);
                }
            }
        }
    }
}
